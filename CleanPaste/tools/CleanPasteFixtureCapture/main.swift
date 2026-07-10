import AppKit
import ClipCore
import Foundation
import WebKit

private enum CaptureError: Error, LocalizedError {
    case confirmationRequired
    case missingSource(URL)
    case copyFailed(String)
    case previewMismatch(String)

    var errorDescription: String? {
        switch self {
        case .confirmationRequired:
            "Pass --confirm-nonsensitive to overwrite raw fixture payloads with live harness captures."
        case .missingSource(let url):
            "Fixture has no source payload: \(url.path)"
        case .copyFailed(let fixture):
            "Source harness produced no supported text for \(fixture)."
        case .previewMismatch(let fixture):
            "Live capture no longer transforms to the manually authored preview for \(fixture)."
        }
    }
}

private enum SourceHarness: String, Codable {
    case webSelection = "webkit_selection"
    case webContenteditable = "webkit_contenteditable"
    case webTextarea = "webkit_textarea"
    case nativePlainText = "appkit_plain_text"
    case nativeRichText = "appkit_rich_text"
    case htmlOnlyEdge = "controlled_html_only_edge"
}

private struct CapturedPasteboard {
    let types: [String]
    let plainText: String?
    let htmlText: String?
    let rtfData: Data?
}

private struct FixtureMetadata: Codable {
    let capturedAt: String
    let captureMode: String
    let sourceHarness: SourceHarness
    let category: String
    let fullCapture: Bool
    let types: [String]
    let hasPlainText: Bool
    let hasHTML: Bool
    let hasRTF: Bool
    let plainTextLength: Int
    let htmlLength: Int
    let rtfLength: Int
    let privacy: String
}

private struct PasteboardItemSnapshot {
    let values: [NSPasteboard.PasteboardType: Data]
}

@main
private struct CleanPasteFixtureCapture {
    @MainActor
    static func main() throws {
        guard CommandLine.arguments.dropFirst().contains("--confirm-nonsensitive") else {
            throw CaptureError.confirmationRequired
        }

        NSApplication.shared.setActivationPolicy(.accessory)
        let packageRoot = locatePackageRoot()
        let fixturesRoot = packageRoot.appendingPathComponent("qa/fixtures")
        let pasteboard = NSPasteboard.general
        let originalItems = snapshotItems(on: pasteboard)

        defer { restore(items: originalItems, to: pasteboard) }

        let fixtureURLs = try fixtureDirectories(in: fixturesRoot)
        for fixtureURL in fixtureURLs {
            let category = fixtureURL.deletingLastPathComponent().lastPathComponent
            let harness = harness(for: category)
            let captured = try capture(fixtureURL: fixtureURL, harness: harness, pasteboard: pasteboard)
            try validate(captured: captured, fixtureURL: fixtureURL)
            try write(captured: captured, harness: harness, category: category, fixtureURL: fixtureURL)
            print("Captured \(category)/\(fixtureURL.lastPathComponent) with \(harness.rawValue)")
        }
    }

    private static func locatePackageRoot() -> URL {
        let current = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        if FileManager.default.fileExists(atPath: current.appendingPathComponent("qa/fixtures").path) {
            return current
        }

        let nested = current.appendingPathComponent("CleanPaste")
        if FileManager.default.fileExists(atPath: nested.appendingPathComponent("qa/fixtures").path) {
            return nested
        }

        return URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private static func fixtureDirectories(in root: URL) throws -> [URL] {
        let categories = try FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey]
        ).filter(\.hasDirectoryPath)

        return try categories.flatMap { category in
            try FileManager.default.contentsOfDirectory(
                at: category,
                includingPropertiesForKeys: [.isDirectoryKey]
            ).filter(\.hasDirectoryPath)
        }.sorted { $0.path < $1.path }
    }

    private static func harness(for category: String) -> SourceHarness {
        switch category {
        case "ai-chat", "browser-selection":
            .webSelection
        case "messaging", "social-editor":
            .webContenteditable
        case "webpage-form":
            .webTextarea
        case "code-editor":
            .nativePlainText
        case "rich-doc":
            .nativeRichText
        case "html-only":
            .htmlOnlyEdge
        default:
            .nativePlainText
        }
    }

    @MainActor
    private static func capture(
        fixtureURL: URL,
        harness: SourceHarness,
        pasteboard: NSPasteboard
    ) throws -> CapturedPasteboard {
        let plainURL = fixtureURL.appendingPathComponent("raw/plain.txt")
        let htmlURL = fixtureURL.appendingPathComponent("raw/source.html")

        switch harness {
        case .htmlOnlyEdge:
            guard FileManager.default.fileExists(atPath: htmlURL.path) else {
                throw CaptureError.missingSource(fixtureURL)
            }
            let html = try String(contentsOf: htmlURL, encoding: .utf8)
            pasteboard.clearContents()
            pasteboard.setString(html, forType: .html)
        case .nativePlainText, .nativeRichText:
            guard FileManager.default.fileExists(atPath: plainURL.path) else {
                throw CaptureError.missingSource(fixtureURL)
            }
            let text = try String(contentsOf: plainURL, encoding: .utf8)
            copyFromTextView(text, richText: harness == .nativeRichText, pasteboard: pasteboard)
        case .webSelection, .webContenteditable, .webTextarea:
            guard FileManager.default.fileExists(atPath: plainURL.path) else {
                throw CaptureError.missingSource(fixtureURL)
            }
            let text = try String(contentsOf: plainURL, encoding: .utf8)
            try copyFromWebKit(text, harness: harness, pasteboard: pasteboard)
        }

        return CapturedPasteboard(
            types: pasteboard.types?.map(\.rawValue).sorted() ?? [],
            plainText: pasteboard.string(forType: .string),
            htmlText: pasteboard.string(forType: .html),
            rtfData: pasteboard.data(forType: .rtf)
        )
    }

    @MainActor
    private static func copyFromTextView(
        _ text: String,
        richText: Bool,
        pasteboard: NSPasteboard
    ) {
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 640, height: 480))
        textView.isRichText = richText
        textView.string = text
        if richText, !text.isEmpty {
            textView.textStorage?.addAttribute(
                .font,
                value: NSFont.systemFont(ofSize: 14),
                range: NSRange(location: 0, length: (text as NSString).length)
            )
        }
        textView.selectAll(nil)
        pasteboard.clearContents()
        textView.copy(nil)
    }

    @MainActor
    private static func copyFromWebKit(
        _ text: String,
        harness: SourceHarness,
        pasteboard: NSPasteboard
    ) throws {
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 640, height: 480))
        let window = NSWindow(
            contentRect: webView.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        let waiter = NavigationWaiter()
        webView.navigationDelegate = waiter
        window.contentView = webView
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(webView)

        let escaped = escapeHTML(text)
        let body: String
        let selectionScript: String
        switch harness {
        case .webTextarea:
            body = "<textarea id='source'>\(escaped)</textarea>"
            selectionScript = "document.getElementById('source').focus(); document.getElementById('source').select();"
        case .webContenteditable:
            body = "<div id='source' contenteditable='true' style='white-space:pre-wrap'>\(escaped)</div>"
            selectionScript = selectElementScript
        default:
            body = "<div id='source' style='white-space:pre-wrap'>\(escaped)</div>"
            selectionScript = selectElementScript
        }

        webView.loadHTMLString("<!doctype html><meta charset='utf-8'><body>\(body)</body>", baseURL: nil)
        wait(until: { waiter.isComplete }, timeout: 5)
        guard waiter.isComplete else {
            window.close()
            throw CaptureError.copyFailed(harness.rawValue)
        }

        _ = evaluate(selectionScript, in: webView, timeout: 2)
        pasteboard.clearContents()
        webView.perform(#selector(NSText.copy(_:)), with: nil)
        wait(duration: 0.2)
        window.close()
    }

    private static let selectElementScript = """
    const node = document.getElementById('source');
    const range = document.createRange();
    range.selectNodeContents(node);
    const selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
    """

    private static func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    @MainActor
    private static func evaluate(_ script: String, in webView: WKWebView, timeout: TimeInterval) -> Any? {
        var result: Any?
        var complete = false
        webView.evaluateJavaScript(script) { value, _ in
            result = value
            complete = true
        }
        wait(until: { complete }, timeout: timeout)
        return result
    }

    @MainActor
    private static func wait(until predicate: () -> Bool, timeout: TimeInterval) {
        let deadline = Date().addingTimeInterval(timeout)
        while !predicate(), Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.02))
        }
    }

    @MainActor
    private static func wait(duration: TimeInterval) {
        let deadline = Date().addingTimeInterval(duration)
        while Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.02))
        }
    }

    private static func validate(captured: CapturedPasteboard, fixtureURL: URL) throws {
        guard captured.plainText != nil || captured.htmlText != nil else {
            throw CaptureError.copyFailed(fixtureURL.lastPathComponent)
        }

        let content = PasteboardContent(
            plainText: captured.plainText,
            htmlText: captured.htmlText,
            availableTypeIdentifiers: captured.types
        )
        let actual = try CleanPasteTransform.previewText(from: content)
        let expected = try String(
            contentsOf: fixtureURL.appendingPathComponent("expected-preview.txt"),
            encoding: .utf8
        ).trimmingCharacters(in: .newlines)

        guard actual == expected else {
            throw CaptureError.previewMismatch(fixtureURL.lastPathComponent)
        }
    }

    private static func write(
        captured: CapturedPasteboard,
        harness: SourceHarness,
        category: String,
        fixtureURL: URL
    ) throws {
        let rawURL = fixtureURL.appendingPathComponent("raw")
        try FileManager.default.createDirectory(at: rawURL, withIntermediateDirectories: true)

        if let plainText = captured.plainText {
            try plainText.write(
                to: rawURL.appendingPathComponent("plain.txt"),
                atomically: true,
                encoding: .utf8
            )
        }
        if let htmlText = captured.htmlText {
            try htmlText.write(
                to: rawURL.appendingPathComponent("source.html"),
                atomically: true,
                encoding: .utf8
            )
        }

        let metadata = FixtureMetadata(
            capturedAt: ISO8601DateFormatter().string(from: Date()),
            captureMode: "controlled-live-harness",
            sourceHarness: harness,
            category: category,
            fullCapture: true,
            types: captured.types,
            hasPlainText: captured.plainText != nil,
            hasHTML: captured.htmlText != nil,
            hasRTF: captured.rtfData != nil,
            plainTextLength: captured.plainText?.count ?? 0,
            htmlLength: captured.htmlText?.count ?? 0,
            rtfLength: captured.rtfData?.count ?? 0,
            privacy: "Full payload captured from checked-in non-sensitive fixture text by explicit confirmation."
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(metadata).write(to: fixtureURL.appendingPathComponent("observed-formats.json"))
    }

    private static func snapshotItems(on pasteboard: NSPasteboard) -> [PasteboardItemSnapshot] {
        (pasteboard.pasteboardItems ?? []).map { item in
            PasteboardItemSnapshot(values: Dictionary(uniqueKeysWithValues: item.types.compactMap { type in
                item.data(forType: type).map { (type, $0) }
            }))
        }
    }

    private static func restore(items: [PasteboardItemSnapshot], to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        let pasteboardItems = items.map { snapshot in
            let item = NSPasteboardItem()
            for (type, data) in snapshot.values {
                item.setData(data, forType: type)
            }
            return item
        }
        if !pasteboardItems.isEmpty {
            pasteboard.writeObjects(pasteboardItems)
        }
    }
}

@MainActor
private final class NavigationWaiter: NSObject, WKNavigationDelegate {
    var isComplete = false

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isComplete = true
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isComplete = true
    }
}

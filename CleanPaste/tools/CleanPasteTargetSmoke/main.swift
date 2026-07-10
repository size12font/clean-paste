import AppKit
import CleanPasteMacCore
import ClipCore
import Foundation
import WebKit

private struct CapabilityResult {
    let fixtureID: String
    let capability: TargetCapability
    let expectedCount: Int
    let actualCount: Int
    let semanticListExpected: Bool
    let semanticListObserved: Bool
    let matches: Bool
}

private struct TargetPasteObservation {
    let text: String
    let html: String?
    let hasSemanticTextList: Bool
}

private struct ListExpectation {
    let hasOrderedList: Bool
    let hasBulletList: Bool
    let itemTexts: [String]

    var hasList: Bool { hasOrderedList || hasBulletList }

    init(_ text: String) {
        var ordered = false
        var bullet = false
        var items: [String] = []

        for line in text.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let markerRange = trimmed.range(
                of: #"^\d+[.)]\s+"#,
                options: .regularExpression
            ) {
                ordered = true
                items.append(String(trimmed[markerRange.upperBound...]))
            } else if let markerRange = trimmed.range(
                of: #"^[-*+•◦‣]\s+"#,
                options: .regularExpression
            ) {
                bullet = true
                items.append(String(trimmed[markerRange.upperBound...]))
            }
        }

        hasOrderedList = ordered
        hasBulletList = bullet
        itemTexts = items
    }
}

private struct PasteboardItemSnapshot {
    let values: [NSPasteboard.PasteboardType: Data]
}

@main
private struct CleanPasteTargetSmoke {
    @MainActor
    static func main() throws {
        NSApplication.shared.setActivationPolicy(.accessory)
        let packageRoot = locatePackageRoot()
        let fixturesRoot = packageRoot.appendingPathComponent("qa/fixtures")
        let reportURL = packageRoot.appendingPathComponent("qa/target-conformance-report.md")
        let pasteboard = NSPasteboard.general
        let originalItems = snapshotItems(on: pasteboard)
        defer { restore(items: originalItems, to: pasteboard) }

        var results: [CapabilityResult] = []
        for fixtureURL in try fixtureDirectories(in: fixturesRoot) {
            let paste = try CleanPasteTransform.clean(try pasteboardContent(for: fixtureURL))
            let fixtureID = fixtureURL.path.replacingOccurrences(of: fixturesRoot.path + "/", with: "")
            let listExpectation = ListExpectation(paste.previewText)

            for capability in TargetCapability.releaseGate {
                try CleanPasteboardWriter().write(paste.previewText)
                let observation = pasteIntoTarget(capability.kind)
                let actual = observation.text.trimmingCharacters(in: .newlines)
                let semanticListObserved = observesSemanticList(
                    observation,
                    expectation: listExpectation,
                    capability: capability.kind
                )
                results.append(CapabilityResult(
                    fixtureID: fixtureID,
                    capability: capability,
                    expectedCount: paste.previewText.count,
                    actualCount: actual.count,
                    semanticListExpected: listExpectation.hasList
                        && capability.kind != .nativeText
                        && capability.kind != .webTextarea,
                    semanticListObserved: semanticListObserved,
                    matches: matches(
                        actual: actual,
                        expected: paste.previewText,
                        expectation: listExpectation,
                        semanticListObserved: semanticListObserved,
                        capability: capability.kind
                    )
                ))
            }
        }

        try writeReport(results, to: reportURL)
        let failures = results.filter { !$0.matches }
        print("Target capability conformance: \(results.count - failures.count)/\(results.count) passed")
        print("Report: \(reportURL.path)")

        if !failures.isEmpty {
            for failure in failures {
                print("FAIL \(failure.fixtureID) -> \(failure.capability.kind.rawValue): expected \(failure.expectedCount), got \(failure.actualCount)")
            }
            exit(1)
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

    private static func pasteboardContent(for fixtureURL: URL) throws -> PasteboardContent {
        let plainURL = fixtureURL.appendingPathComponent("raw/plain.txt")
        let htmlURL = fixtureURL.appendingPathComponent("raw/source.html")
        var representations: [String: String] = [:]

        if FileManager.default.fileExists(atPath: plainURL.path) {
            representations[PasteboardTypeIdentifier.plainText] = try String(contentsOf: plainURL, encoding: .utf8)
        }
        if FileManager.default.fileExists(atPath: htmlURL.path) {
            representations[PasteboardTypeIdentifier.html] = try String(contentsOf: htmlURL, encoding: .utf8)
        }

        return PasteboardContent(textualRepresentations: representations)
    }

    @MainActor
    private static func pasteIntoTarget(_ kind: TargetCapabilityKind) -> TargetPasteObservation {
        switch kind {
        case .nativeText:
            pasteIntoTextView(richText: false)
        case .richComposer:
            pasteIntoTextView(richText: true)
        case .webTextarea, .webContenteditable:
            pasteIntoWebKit(kind)
        }
    }

    @MainActor
    private static func pasteIntoTextView(richText: Bool) -> TargetPasteObservation {
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        textView.isEditable = true
        textView.isRichText = richText
        textView.string = ""
        textView.paste(nil)
        var hasSemanticTextList = false
        let fullRange = NSRange(location: 0, length: textView.string.utf16.count)
        textView.textStorage?.enumerateAttribute(
            .paragraphStyle,
            in: fullRange
        ) { value, _, stop in
            if let style = value as? NSParagraphStyle, !style.textLists.isEmpty {
                hasSemanticTextList = true
                stop.pointee = true
            }
        }
        return TargetPasteObservation(
            text: textView.string,
            html: nil,
            hasSemanticTextList: hasSemanticTextList
        )
    }

    @MainActor
    private static func pasteIntoWebKit(_ kind: TargetCapabilityKind) -> TargetPasteObservation {
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 640, height: 480))
        let window = NSWindow(
            contentRect: webView.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        let navigation = NavigationWaiter()
        webView.navigationDelegate = navigation
        window.contentView = webView
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(webView)

        let element: String
        let readScript: String
        if kind == .webTextarea {
            element = "<textarea id='target' autofocus></textarea>"
            readScript = "document.getElementById('target').value"
        } else {
            element = "<div id='target' contenteditable='true' style='white-space:pre-wrap'></div>"
            readScript = "document.getElementById('target').innerText"
        }

        webView.loadHTMLString("<!doctype html><meta charset='utf-8'><body>\(element)</body>", baseURL: nil)
        wait(until: { navigation.isComplete }, timeout: 5)
        _ = evaluate("document.getElementById('target').focus(); true", in: webView, timeout: 2)
        webView.perform(#selector(NSText.paste(_:)), with: nil)
        wait(duration: 0.2)
        let value = evaluate(readScript, in: webView, timeout: 2) as? String ?? ""
        let html: String?
        if kind == .webContenteditable {
            html = evaluate(
                "document.getElementById('target').innerHTML",
                in: webView,
                timeout: 2
            ) as? String
        } else {
            html = nil
        }
        window.close()
        return TargetPasteObservation(text: value, html: html, hasSemanticTextList: false)
    }

    private static func observesSemanticList(
        _ observation: TargetPasteObservation,
        expectation: ListExpectation,
        capability: TargetCapabilityKind
    ) -> Bool {
        guard expectation.hasList else { return false }

        switch capability {
        case .nativeText, .webTextarea:
            return false
        case .webContenteditable:
            let html = observation.html?.lowercased() ?? ""
            return (!expectation.hasOrderedList || html.contains("<ol"))
                && (!expectation.hasBulletList || html.contains("<ul"))
        case .richComposer:
            return observation.hasSemanticTextList
        }
    }

    private static func matches(
        actual: String,
        expected: String,
        expectation: ListExpectation,
        semanticListObserved: Bool,
        capability: TargetCapabilityKind
    ) -> Bool {
        guard expectation.hasList else { return actual == expected }

        switch capability {
        case .nativeText, .webTextarea:
            return actual == expected
        case .webContenteditable, .richComposer:
            return semanticListObserved
                && expectation.itemTexts.allSatisfy { actual.contains($0) }
        }
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

    private static func writeReport(_ results: [CapabilityResult], to url: URL) throws {
        var lines = [
            "# Target Capability Conformance Report",
            "",
            "Generated: \(ISO8601DateFormatter().string(from: Date()))",
            "",
            "Canonical previews are tested once against each behavioral target class.",
            "",
            "| Fixture | Capability | Expected chars | Actual chars | Semantic list | Result |",
            "|---|---|---:|---:|---|---|"
        ]

        for result in results {
            let semanticMark = result.semanticListExpected
                ? (result.semanticListObserved ? "Pass" : "Fail")
                : "N/A"
            lines.append("| `\(result.fixtureID)` | `\(result.capability.kind.rawValue)` | \(result.expectedCount) | \(result.actualCount) | \(semanticMark) | \(result.matches ? "Pass" : "Fail") |")
        }

        try (lines.joined(separator: "\n") + "\n").write(to: url, atomically: true, encoding: .utf8)
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

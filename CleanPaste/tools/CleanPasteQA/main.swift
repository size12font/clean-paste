import AppKit
import CleanPasteMacCore
import ClipCore
import Foundation

struct FixtureMetadata: Decodable {
    let captureMode: String
    let sourceHarness: String
    let types: [String]
}

struct FixtureResult {
    let id: String
    let sourceFlavor: PasteboardSourceFlavor
    let observedTypeCount: Int
    let transformVersion: String
    let previewMatches: Bool
    let provenanceMatches: Bool
    let clipboardPayloadMatches: Bool

    var passed: Bool {
        previewMatches && provenanceMatches && clipboardPayloadMatches
    }
}

enum QAError: Error, LocalizedError {
    case missingFixtures(URL)
    case incompleteFixture(String)

    var errorDescription: String? {
        switch self {
        case .missingFixtures(let url):
            "No fixtures found at \(url.path)"
        case .incompleteFixture(let id):
            "Fixture is missing live capture evidence or required payloads: \(id)"
        }
    }
}

let packageRoot = locatePackageRoot()
let fixturesRoot = packageRoot.appendingPathComponent("qa/fixtures")
let reportURL = packageRoot.appendingPathComponent("qa/conformance.md")
let fixtureURLs = try fixtureDirectories(in: fixturesRoot)

guard fixtureURLs.count >= 8 else {
    throw QAError.missingFixtures(fixturesRoot)
}

let results = try fixtureURLs.map { try runFixture($0, fixturesRoot: fixturesRoot) }
try writeReport(results, to: reportURL)

let failures = results.filter { !$0.passed }
print("Canonical source conformance: \(results.count - failures.count)/\(results.count) passed")
print("Report: \(reportURL.path)")

if !failures.isEmpty {
    for failure in failures {
        print("FAIL \(failure.id)")
    }
    exit(1)
}

private func locatePackageRoot() -> URL {
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

private func fixtureDirectories(in root: URL) throws -> [URL] {
    guard FileManager.default.fileExists(atPath: root.path) else {
        throw QAError.missingFixtures(root)
    }

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

private func runFixture(_ fixtureURL: URL, fixturesRoot: URL) throws -> FixtureResult {
    let id = fixtureURL.path.replacingOccurrences(of: fixturesRoot.path + "/", with: "")
    let metadataURL = fixtureURL.appendingPathComponent("observed-formats.json")
    let expectedURL = fixtureURL.appendingPathComponent("expected-preview.txt")
    guard
        FileManager.default.fileExists(atPath: metadataURL.path),
        FileManager.default.fileExists(atPath: expectedURL.path)
    else {
        throw QAError.incompleteFixture(id)
    }

    let metadata = try JSONDecoder().decode(FixtureMetadata.self, from: Data(contentsOf: metadataURL))
    let executableCaptureModes = ["controlled-live-harness", "external-full"]
    guard executableCaptureModes.contains(metadata.captureMode), !metadata.sourceHarness.isEmpty else {
        throw QAError.incompleteFixture(id)
    }

    let content = try pasteboardContent(for: fixtureURL, observedTypes: metadata.types)
    let paste = try CleanPasteTransform.clean(content)
    let expected = try fixtureText(at: expectedURL)

    return FixtureResult(
        id: id,
        sourceFlavor: paste.sourceFlavor,
        observedTypeCount: paste.observedTypeIdentifiers.count,
        transformVersion: paste.transformVersion,
        previewMatches: paste.previewText == expected,
        provenanceMatches: paste.observedTypeIdentifiers == metadata.types.sorted()
            && paste.transformVersion == CleanPasteTransform.version,
        clipboardPayloadMatches: try verifyClipboardPayload(paste.previewText)
    )
}

private func pasteboardContent(for fixtureURL: URL, observedTypes: [String]) throws -> PasteboardContent {
    let plainURL = fixtureURL.appendingPathComponent("raw/plain.txt")
    let htmlURL = fixtureURL.appendingPathComponent("raw/source.html")
    var representations: [String: String] = [:]

    if FileManager.default.fileExists(atPath: plainURL.path) {
        representations[PasteboardTypeIdentifier.plainText] = try String(contentsOf: plainURL, encoding: .utf8)
    }
    if FileManager.default.fileExists(atPath: htmlURL.path) {
        representations[PasteboardTypeIdentifier.html] = try String(contentsOf: htmlURL, encoding: .utf8)
    }
    guard !representations.isEmpty else {
        throw QAError.incompleteFixture(fixtureURL.lastPathComponent)
    }

    return PasteboardContent(
        textualRepresentations: representations,
        availableTypeIdentifiers: observedTypes
    )
}

private func fixtureText(at url: URL) throws -> String {
    try String(contentsOf: url, encoding: .utf8).trimmingCharacters(in: .newlines)
}

private func verifyClipboardPayload(_ previewText: String) throws -> Bool {
    let pasteboard = NSPasteboard(name: NSPasteboard.Name("CleanPasteQA.\(UUID().uuidString)"))
    pasteboard.clearContents()
    pasteboard.setString("<b>rich</b>", forType: .html)
    pasteboard.setString("old", forType: .string)
    try CleanPasteboardWriter(pasteboard: pasteboard).write(previewText)

    let types = Set(pasteboard.types?.map(\.rawValue) ?? [])
    let allowedTypes: Set<String> = [
        PasteboardTypeIdentifier.plainText,
        "NSStringPboardType",
        PasteboardTypeIdentifier.html,
        "Apple HTML pasteboard type"
    ]
    let html = pasteboard.string(forType: .html)
    let hasOrderedList = previewText.components(separatedBy: "\n").contains {
        $0.trimmingCharacters(in: .whitespaces).range(
            of: #"^\d+[.)]\s+.+$"#,
            options: .regularExpression
        ) != nil
    }
    let hasBulletList = previewText.components(separatedBy: "\n").contains {
        $0.trimmingCharacters(in: .whitespaces).range(
            of: #"^[-*+•◦‣]\s+.+$"#,
            options: .regularExpression
        ) != nil
    }
    let semanticHTMLMatches = if hasOrderedList || hasBulletList {
        html != nil
            && (!hasOrderedList || html!.contains("<ol"))
            && (!hasBulletList || html!.contains("<ul"))
    } else {
        html == nil
    }

    return pasteboard.string(forType: .string) == previewText
        && semanticHTMLMatches
        && pasteboard.data(forType: .rtf) == nil
        && types.isSubset(of: allowedTypes)
        && types.contains(PasteboardTypeIdentifier.plainText)
}

private func writeReport(_ results: [FixtureResult], to url: URL) throws {
    var lines = [
        "# Canonical Source Conformance",
        "",
        "Generated: \(ISO8601DateFormatter().string(from: Date()))",
        "",
        "Every source fixture is normalized once into `CanonicalPaste`. Target apps are not matrix columns.",
        "",
        "| Fixture | Extractor | Observed types | Transform | Preview | Provenance | Clipboard payload |",
        "|---|---|---:|---|---|---|---|"
    ]

    for result in results {
        lines.append(
            "| `\(result.id)` | `\(result.sourceFlavor.rawValue)` | \(result.observedTypeCount) | `\(result.transformVersion)` | \(mark(result.previewMatches)) | \(mark(result.provenanceMatches)) | \(mark(result.clipboardPayloadMatches)) |"
        )
    }

    try (lines.joined(separator: "\n") + "\n").write(to: url, atomically: true, encoding: .utf8)
}

private func mark(_ value: Bool) -> String {
    value ? "Pass" : "Fail"
}

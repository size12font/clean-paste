import ClipCore
import Foundation

private struct FixtureResult {
    let id: String
    let expectedCount: Int
    let actualCount: Int
    let matches: Bool
}

private enum ShortcutQAError: Error, LocalizedError {
    case canonicalPreviewDrift(String)

    var errorDescription: String? {
        switch self {
        case .canonicalPreviewDrift(let fixtureID):
            "Canonical preview drifted for \(fixtureID)."
        }
    }
}

private let fixtureIDs = [
    "ai-chat/chatgpt-answer",
    "code-editor/xcode-snippet",
    "messaging/slack-message",
    "social-editor/linkedin-post",
    "webpage-form/comment-field"
]

private let packageRoot = locatePackageRoot()
private let fixturesRoot = packageRoot.appendingPathComponent("qa/fixtures")
private let results = try fixtureIDs.map { id -> FixtureResult in
    let fixtureURL = fixturesRoot.appendingPathComponent(id)
    let source = try String(contentsOf: fixtureURL.appendingPathComponent("raw/plain.txt"), encoding: .utf8)
    let documentedPreview = try String(
        contentsOf: fixtureURL.appendingPathComponent("expected-preview.txt"),
        encoding: .utf8
    ).trimmingCharacters(in: .newlines)
    let expected = try CleanPasteTransform.previewText(from: PasteboardContent(plainText: source))
    guard expected == documentedPreview else {
        throw ShortcutQAError.canonicalPreviewDrift(id)
    }
    let actual = shortcutMirror(source)

    return FixtureResult(
        id: id,
        expectedCount: expected.count,
        actualCount: actual.count,
        matches: actual == expected
    )
}

let reportURL = packageRoot.appendingPathComponent("qa/cases/ios-shortcut-fixture-checks.md")
try writeReport(results, to: reportURL)
private let failures = results.filter { !$0.matches }
print("iOS Shortcut rule mirror: \(results.count - failures.count)/\(results.count) passed")
print("Report: \(reportURL.path)")

if !failures.isEmpty {
    for failure in failures {
        print("FAIL \(failure.id): expected \(failure.expectedCount), got \(failure.actualCount)")
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

private func shortcutMirror(_ source: String) -> String {
    var output = normalizeUnicode(source)
    output = output
        .components(separatedBy: "\n")
        .filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return !trimmed.hasPrefix("```") && !trimmed.hasPrefix("~~~")
        }
        .joined(separator: "\n")
    output = replacingRegex(#"\*\*([^*\n]+)\*\*"#, in: output, with: "$1")
    output = replacingRegex(#"`([^`\n]+)`"#, in: output, with: "$1")
    output = replacingRegex(#"(?m)[ \t]+$"#, in: output, with: "")
    output = replacingRegex(#"\n{3,}"#, in: output, with: "\n\n")

    return output
        .trimmingCharacters(in: .newlines)
}

private func normalizeUnicode(_ source: String) -> String {
    var output = String.UnicodeScalarView()
    for scalar in source.unicodeScalars {
        switch scalar.value {
        case 0x00A0, 0x202F, 0x2007, 0x2009, 0x200A:
            output.append(" ")
        case 0x200B, 0x200C, 0x200D, 0x2060, 0xFEFF:
            continue
        default:
            output.append(scalar)
        }
    }
    return String(output)
}

private func replacingRegex(_ pattern: String, in text: String, with template: String) -> String {
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
        return text
    }
    return regex.stringByReplacingMatches(
        in: text,
        range: NSRange(text.startIndex..<text.endIndex, in: text),
        withTemplate: template
    )
}

private func writeReport(_ results: [FixtureResult], to url: URL) throws {
    var lines = [
        "# iOS Shortcut Fixture Checks",
        "",
        "Generated: \(ISO8601DateFormatter().string(from: Date()))",
        "",
        "This executable check mirrors the documented Shortcut replacement chain. It does not claim that an iPhone trigger was automated from macOS.",
        "",
        "| Fixture | ClipCore chars | Shortcut mirror chars | Result |",
        "|---|---:|---:|---|"
    ]

    for result in results {
        lines.append("| `\(result.id)` | \(result.expectedCount) | \(result.actualCount) | \(result.matches ? "Pass" : "Fail") |")
    }

    lines += [
        "",
        "## Documented Limitation",
        "",
        "The Shortcut must still be assembled and triggered on an iPhone to prove Back Tap, Share Sheet, or Action Button wiring. Header removal, Markdown links, tables, and HTML fallback remain ClipCore-only; common drift should trigger a small App Intent rather than more Shortcut regex."
    ]

    try (lines.joined(separator: "\n") + "\n").write(to: url, atomically: true, encoding: .utf8)
}

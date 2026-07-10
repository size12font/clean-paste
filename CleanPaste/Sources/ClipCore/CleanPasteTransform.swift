import Foundation

public enum CleanPasteTransform {
    public static let version = "1"

    public static func clean(
        _ content: PasteboardContent,
        using extractionPipeline: SourceExtractionPipeline = .default
    ) throws -> CanonicalPaste {
        let selection = try extractionPipeline.extract(from: content)
        var text = selection.text

        text = UnicodeCleaner.clean(text)
        text = MarkdownStripper.strip(text)
        text = degradeTablesAndLists(in: text)
        text = NewlineNormalizer.normalize(text)

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CleanPasteTransformError.emptyOutput
        }

        return CanonicalPaste(
            previewText: text,
            sourceFlavor: selection.flavor,
            observedTypeIdentifiers: content.availableTypeIdentifiers,
            transformVersion: version
        )
    }

    public static func previewText(from content: PasteboardContent) throws -> String {
        try clean(content).previewText
    }

    private static func degradeTablesAndLists(in text: String) -> String {
        text
            .components(separatedBy: "\n")
            .compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                if isMarkdownTableSeparator(trimmed) {
                    return nil
                }

                if trimmed.hasPrefix("|"), trimmed.hasSuffix("|") {
                    let cells = trimmed
                        .split(separator: "|", omittingEmptySubsequences: false)
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }

                    if cells.count > 1 {
                        return cells.joined(separator: "\t")
                    }
                }

                return normalizeBullet(line)
            }
            .joined(separator: "\n")
    }

    private static func isMarkdownTableSeparator(_ line: String) -> Bool {
        line.matchesRegex(#"^\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?$"#)
    }

    private static func normalizeBullet(_ line: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let leadingWhitespace = String(line.prefix { $0 == " " || $0 == "\t" })

        if trimmed.matchesRegex(#"^[•‣◦]\s+"#) {
            return leadingWhitespace + "- " + trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
        }

        if trimmed.matchesRegex(#"^\*\s+"#) {
            return leadingWhitespace + "- " + trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
        }

        return line
    }
}

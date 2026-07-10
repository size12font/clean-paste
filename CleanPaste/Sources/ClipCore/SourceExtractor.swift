import Foundation

public struct SourceExtraction: Equatable, Sendable {
    public let text: String
    public let flavor: PasteboardSourceFlavor

    public init(text: String, flavor: PasteboardSourceFlavor) {
        self.text = text
        self.flavor = flavor
    }
}

public protocol SourceExtractor: Sendable {
    func extract(from content: PasteboardContent) -> SourceExtraction?
}

public struct TypeIdentifierSourceExtractor: SourceExtractor {
    public let typeIdentifier: String
    public let sourceFlavor: PasteboardSourceFlavor

    public init(typeIdentifier: String, sourceFlavor: PasteboardSourceFlavor) {
        self.typeIdentifier = typeIdentifier
        self.sourceFlavor = sourceFlavor
    }

    public func extract(from content: PasteboardContent) -> SourceExtraction? {
        guard
            let text = content.text(forTypeIdentifier: typeIdentifier),
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return SourceExtraction(text: text, flavor: sourceFlavor)
    }
}

public struct HTMLSourceExtractor: SourceExtractor {
    public init() {}

    public func extract(from content: PasteboardContent) -> SourceExtraction? {
        guard let html = content.htmlText else {
            return nil
        }

        let text = HTMLBlockExtractor.extract(from: html)
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return SourceExtraction(text: text, flavor: .html)
    }
}

public struct StructureAwareSourceExtractor: SourceExtractor {
    public init() {}

    public func extract(from content: PasteboardContent) -> SourceExtraction? {
        guard
            let plainText = content.plainText,
            !plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            let rawHTML = content.htmlText
        else {
            return nil
        }

        let extractedHTML = HTMLBlockExtractor.extract(from: rawHTML)
        let candidates = [
            extractedHTML,
            removingHTMLOnlyDomains(from: extractedHTML, plainText: plainText)
        ]

        guard let structuredText = candidates.first(where: {
            comparableText(plainText) == comparableText($0)
        }) else {
            return nil
        }

        return SourceExtraction(text: structuredText, flavor: .html)
    }

    private func comparableText(_ text: String) -> String {
        text.replacingRegex(#"(?m)^[ \t]*[•◦‣]\s+"#, with: "- ")
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }

    private func removingHTMLOnlyDomains(
        from structuredText: String,
        plainText: String
    ) -> String {
        guard let domainRegex = try? NSRegularExpression(
            pattern: #"(?i)(?<![\p{L}\p{N}_-])(?:www\.)?[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\.[a-z0-9-]+)*\.[a-z]{2,}(?![\p{L}\p{N}_-])"#
        ) else {
            return structuredText
        }

        let plainDomains = Set(domainLabels(in: plainText, using: domainRegex))
        var output = structuredText
        let matches = domainRegex.matches(
            in: structuredText,
            range: NSRange(structuredText.startIndex..<structuredText.endIndex, in: structuredText)
        )

        for match in matches.reversed() {
            guard let range: Range<String.Index> = Range(match.range, in: output) else {
                continue
            }
            let label = normalizedDomain(String(output[range]))
            if !plainDomains.contains(label) {
                output.removeSubrange(range)
            }
        }

        return output
    }

    private func domainLabels(
        in text: String,
        using regex: NSRegularExpression
    ) -> [String] {
        regex.matches(
            in: text,
            range: NSRange(text.startIndex..<text.endIndex, in: text)
        ).compactMap { match in
            Range(match.range, in: text).map {
                normalizedDomain(String(text[$0]))
            }
        }
    }

    private func normalizedDomain(_ domain: String) -> String {
        domain
            .lowercased()
            .replacingRegex(#"^www\."#, with: "")
    }
}

public struct SourceExtractionPipeline: Sendable {
    private let extractors: [any SourceExtractor]

    public init(extractors: [any SourceExtractor]) {
        self.extractors = extractors
    }

    public static var `default`: Self {
        Self(extractors: [
            StructureAwareSourceExtractor(),
            TypeIdentifierSourceExtractor(
                typeIdentifier: PasteboardTypeIdentifier.plainText,
                sourceFlavor: .plainText
            ),
            HTMLSourceExtractor()
        ])
    }

    public func extract(from content: PasteboardContent) throws -> SourceExtraction {
        for extractor in extractors {
            if let extraction = extractor.extract(from: content) {
                return extraction
            }
        }

        throw CleanPasteTransformError.noSupportedText
    }
}

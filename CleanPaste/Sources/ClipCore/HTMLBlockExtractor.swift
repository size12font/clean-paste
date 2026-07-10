import Foundation

public enum HTMLBlockExtractor {
    public static func extract(from html: String) -> String {
        var text = html

        text = text.replacingRegex(#"(?is)<script\b[^>]*>.*?</script>"#, with: "")
        text = text.replacingRegex(#"(?is)<style\b[^>]*>.*?</style>"#, with: "")
        text = removeHiddenElements(from: text)
        text = replaceLists(in: text)
        text = text.replacingRegex(#"(?i)<\s*br\s*/?\s*>"#, with: "\n")
        text = text.replacingRegex(#"(?i)<\s*li\b[^>]*>"#, with: "- ")
        text = text.replacingRegex(#"(?i)</\s*li\s*>"#, with: "\n")
        text = text.replacingRegex(#"(?i)</\s*(p|div|section|article|header|footer|blockquote|h[1-6])\s*>"#, with: "\n\n")
        text = text.replacingRegex(#"(?i)</\s*(td|th)\s*>"#, with: "\t")
        text = text.replacingRegex(#"(?i)</\s*tr\s*>"#, with: "\n")
        text = text.replacingRegex(#"(?i)</\s*(table|thead|tbody|tfoot|ul|ol)\s*>"#, with: "\n")
        text = text.replacingRegex(#"(?s)<[^>]+>"#, with: "")
        text = decodeEntities(in: text)

        return NewlineNormalizer.normalize(text)
    }

    private static func removeHiddenElements(from html: String) -> String {
        let patterns = [
            #"(?is)<([a-z][a-z0-9:-]*)\b(?=[^>]*\shidden(?:\s|=|>))[^>]*>.*?</\1\s*>"#,
            #"(?is)<([a-z][a-z0-9:-]*)\b(?=[^>]*\saria-hidden\s*=\s*(?:\"true\"|'true'|true))[^>]*>.*?</\1\s*>"#,
            #"(?is)<([a-z][a-z0-9:-]*)\b(?=[^>]*\sstyle\s*=\s*(?:\"[^\"]*(?:display\s*:\s*none|visibility\s*:\s*hidden)[^\"]*\"|'[^']*(?:display\s*:\s*none|visibility\s*:\s*hidden)[^']*'))[^>]*>.*?</\1\s*>"#
        ]

        var output = html
        for pattern in patterns {
            output = output.replacingRegex(pattern, with: "")
        }
        return output
    }

    private static func replaceLists(in html: String) -> String {
        guard
            let listRegex = try? NSRegularExpression(
                pattern: #"(?is)<(ul|ol)\b([^>]*)>(?:(?!<\s*/?\s*(?:ul|ol)\b).)*?</\1\s*>"#
            ),
            let itemRegex = try? NSRegularExpression(pattern: #"(?is)<li\b[^>]*>(.*?)</li\s*>"#)
        else {
            return html
        }

        var output = html
        while true {
            let matches = listRegex.matches(
                in: output,
                range: NSRange(output.startIndex..<output.endIndex, in: output)
            )
            guard let match = matches.last else { break }

            guard
                let listRange = Range(match.range, in: output),
                let kindRange = Range(match.range(at: 1), in: output),
                let attributesRange = Range(match.range(at: 2), in: output),
                let contentsRange = Range(match.range, in: output)
            else { break }

            let listHTML = String(output[contentsRange])
            let contentsStart = listHTML.range(of: ">")?.upperBound ?? listHTML.startIndex
            let contentsEnd = listHTML.range(of: #"</\s*(?:ul|ol)\s*>"#, options: .regularExpression)?.lowerBound ?? listHTML.endIndex
            let contents = String(listHTML[contentsStart..<contentsEnd])
            let items = itemRegex.matches(
                in: contents,
                range: NSRange(contents.startIndex..<contents.endIndex, in: contents)
            ).compactMap { itemMatch -> String? in
                Range(itemMatch.range(at: 1), in: contents).map { String(contents[$0]) }
            }

            guard !items.isEmpty else { break }

            let ordered = String(output[kindRange]).lowercased() == "ol"
            let attributes = String(output[attributesRange])
            let start = ordered ? orderedStart(in: attributes) : nil
            let replacement = items.enumerated().map { offset, itemHTML in
                let itemText = itemHTML.replacingRegex(#"(?is)<[^>]+>"#, with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let number = (start ?? 1) + offset
                let marker = ordered ? "\(number). " : "- "
                let lines = itemText.components(separatedBy: "\n")
                return marker + lines[0] + lines.dropFirst().map { "\n  \($0)" }.joined()
            }.joined(separator: "\n")

            output.replaceSubrange(listRange, with: "\n\(replacement)\n\n")
        }

        return output
    }

    private static func orderedStart(in attributes: String) -> Int? {
        guard let match = attributes.firstMatch(of: /(?i)\bstart\s*=\s*["']?(\d+)/),
              let value = Int(match.1) else {
            return nil
        }
        return value
    }

    private static func decodeEntities(in text: String) -> String {
        var decoded = text
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")

        decoded = decodeNumericEntities(decoded, radix: 16)
        decoded = decodeNumericEntities(decoded, radix: 10)
        return decoded
    }

    private static func decodeNumericEntities(_ text: String, radix: Int) -> String {
        let pattern = radix == 16 ? #"&#x([0-9A-Fa-f]+);"# : #"&#([0-9]+);"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return text
        }

        var output = ""
        var cursor = text.startIndex
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)

        for match in regex.matches(in: text, range: nsRange) {
            guard
                let matchRange = Range(match.range(at: 0), in: text),
                let valueRange = Range(match.range(at: 1), in: text)
            else { continue }

            output += text[cursor..<matchRange.lowerBound]
            if
                let scalarValue = UInt32(text[valueRange], radix: radix),
                let scalar = UnicodeScalar(scalarValue)
            {
                output.append(Character(scalar))
            }
            cursor = matchRange.upperBound
        }

        output += text[cursor..<text.endIndex]
        return output
    }
}

import Foundation

public enum MarkdownStripper {
    public static func strip(_ text: String) -> String {
        var output = removeFenceLines(from: text)

        output = output.replacingRegex(#"(?m)^[ \t]{0,3}#{1,6}[ \t]+"#, with: "")
        output = output.replacingRegex(#"!\[([^\]]*)\]\(([^)]+)\)"#, with: "$1 ($2)")
        output = replaceLinks(in: output)
        output = output.replacingRegex(#"`([^`\n]+)`"#, with: "$1")

        output = output.replacingRegex(#"\*\*([^\n*]+?)\*\*"#, with: "$1")
        output = output.replacingRegex(#"__([^\n_]+?)__"#, with: "$1")
        output = output.replacingRegex(#"(?<!\w)\*([^\n*]+?)\*(?!\w)"#, with: "$1")
        output = output.replacingRegex(#"(?<!\w)_([^\n_]+?)_(?!\w)"#, with: "$1")
        output = output.replacingRegex(#"~~([^\n~]+?)~~"#, with: "$1")

        return output
    }

    private static func replaceLinks(in text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"\[([^\]]+)\]\(([^)]+)\)"#) else {
            return text
        }

        var output = text
        let matches = regex.matches(
            in: text,
            range: NSRange(text.startIndex..<text.endIndex, in: text)
        )

        for match in matches.reversed() {
            guard
                let wholeRange = Range(match.range, in: output),
                let labelRange = Range(match.range(at: 1), in: text),
                let targetRange = Range(match.range(at: 2), in: text)
            else { continue }

            let label = String(text[labelRange])
            let target = String(text[targetRange])
            let replacement = label == target ? label : "\(label) (\(target))"
            output.replaceSubrange(wholeRange, with: replacement)
        }

        return output
    }

    private static func removeFenceLines(from text: String) -> String {
        text
            .components(separatedBy: "\n")
            .filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return !trimmed.hasPrefix("```") && !trimmed.hasPrefix("~~~")
            }
            .joined(separator: "\n")
    }
}

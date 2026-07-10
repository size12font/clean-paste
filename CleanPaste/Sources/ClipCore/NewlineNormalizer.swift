import Foundation

public enum NewlineNormalizer {
    public static func normalize(_ text: String) -> String {
        let unified = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        let trimmedLines = unified
            .components(separatedBy: "\n")
            .map { $0.replacingRegex(#"[ \t]+$"#, with: "") }
            .joined(separator: "\n")

        let collapsed = trimmedLines.replacingRegex(#"\n{3,}"#, with: "\n\n")

        return collapsed.trimmingCharacters(in: .newlines)
    }
}

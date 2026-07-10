import Foundation

enum SemanticHTMLRenderer {
    private enum ListItem {
        case ordered(number: Int, text: String)
        case unordered(text: String)

        var isOrdered: Bool {
            if case .ordered = self { return true }
            return false
        }

        var text: String {
            switch self {
            case .ordered(_, let text), .unordered(let text): text
            }
        }

        var number: Int? {
            if case .ordered(let number, _) = self { return number }
            return nil
        }
    }

    static func renderIfNeeded(_ text: String) -> String? {
        let lines = text.components(separatedBy: "\n")
        guard lines.contains(where: { parseListItem($0) != nil }) else {
            return nil
        }

        var blocks: [String] = []
        var index = 0

        while index < lines.count {
            if lines[index].trimmingCharacters(in: .whitespaces).isEmpty {
                if blocks.last != "<br>" {
                    blocks.append("<br>")
                }
                index += 1
                continue
            }

            if let firstItem = parseListItem(lines[index]) {
                let ordered = firstItem.isOrdered
                var items: [ListItem] = []

                while index < lines.count,
                      let item = parseListItem(lines[index]),
                      item.isOrdered == ordered {
                    items.append(item)
                    index += 1
                }

                blocks.append(renderList(items, ordered: ordered))
                continue
            }

            var paragraphLines: [String] = []
            while index < lines.count,
                  !lines[index].trimmingCharacters(in: .whitespaces).isEmpty,
                  parseListItem(lines[index]) == nil {
                paragraphLines.append(escape(lines[index]))
                index += 1
            }
            blocks.append("<p>\(paragraphLines.joined(separator: "<br>"))</p>")
        }

        return "<!doctype html><html><head><meta charset=\"utf-8\"></head><body>\(blocks.joined())</body></html>"
    }

    private static func renderList(_ items: [ListItem], ordered: Bool) -> String {
        let tag = ordered ? "ol" : "ul"
        let startAttribute: String

        if ordered, let firstNumber = items.first?.number, firstNumber != 1 {
            startAttribute = " start=\"\(firstNumber)\""
        } else {
            startAttribute = ""
        }

        let itemHTML = items.enumerated().map { offset, item in
            let valueAttribute: String
            if ordered,
               let number = item.number,
               let firstNumber = items.first?.number,
               number != firstNumber + offset {
                valueAttribute = " value=\"\(number)\""
            } else {
                valueAttribute = ""
            }
            return "<li\(valueAttribute)>\(escape(item.text))</li>"
        }.joined()

        return "<\(tag)\(startAttribute)>\(itemHTML)</\(tag)>"
    }

    private static func parseListItem(_ line: String) -> ListItem? {
        let range = NSRange(line.startIndex..<line.endIndex, in: line)

        if let match = orderedPattern.firstMatch(in: line, range: range),
           let numberRange = Range(match.range(at: 1), in: line),
           let textRange = Range(match.range(at: 2), in: line),
           let number = Int(line[numberRange]) {
            return .ordered(number: number, text: String(line[textRange]))
        }

        if let match = unorderedPattern.firstMatch(in: line, range: range),
           let textRange = Range(match.range(at: 1), in: line) {
            return .unordered(text: String(line[textRange]))
        }

        return nil
    }

    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private static let orderedPattern = try! NSRegularExpression(
        pattern: #"^\s*(\d+)[.)]\s+(.+)$"#
    )
    private static let unorderedPattern = try! NSRegularExpression(
        pattern: #"^\s*[-*+•◦‣]\s+(.+)$"#
    )
}

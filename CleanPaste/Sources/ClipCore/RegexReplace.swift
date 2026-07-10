import Foundation

extension String {
    func replacingRegex(
        _ pattern: String,
        with template: String,
        options: NSRegularExpression.Options = []
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return self
        }

        let range = NSRange(startIndex..<endIndex, in: self)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: template)
    }

    func matchesRegex(_ pattern: String, options: NSRegularExpression.Options = []) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return false
        }

        let range = NSRange(startIndex..<endIndex, in: self)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}


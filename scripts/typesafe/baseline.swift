import Foundation
@main struct Baseline {
    static func main() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        let fixtures = try JSONSerialization.jsonObject(with: data) as! [[String: Any]]
        let results = try fixtures.map { fixture -> [String: Any] in
            let start = Date()
            let output = try CleanPasteTransform.previewText(from: PasteboardContent(plainText: fixture["input"] as! String))
            return ["id": fixture["id"]!, "text": output, "latencyMs": Date().timeIntervalSince(start) * 1000]
        }
        try JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
    }
}

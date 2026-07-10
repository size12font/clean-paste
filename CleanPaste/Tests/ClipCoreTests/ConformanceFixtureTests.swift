import XCTest
@testable import ClipCore

final class ConformanceFixtureTests: XCTestCase {
    func testSourceFixturesProduceCanonicalExpectedPreviews() throws {
        let fixturesRoot = packageRoot().appendingPathComponent("qa/fixtures")
        let fixtureURLs = try allFixtureDirectories(fixturesRoot)
        let categories = Set(fixtureURLs.map { $0.deletingLastPathComponent().lastPathComponent })

        XCTAssertGreaterThanOrEqual(fixtureURLs.count, 8)
        XCTAssertTrue(categories.isSuperset(of: [
            "ai-chat",
            "browser-selection",
            "code-editor",
            "html-only",
            "messaging",
            "rich-doc",
            "social-editor",
            "webpage-form"
        ]))

        for fixtureURL in fixtureURLs {
            let expectedURL = fixtureURL.appendingPathComponent("expected-preview.txt")
            let metadataURL = fixtureURL.appendingPathComponent("observed-formats.json")
            XCTAssertTrue(FileManager.default.fileExists(atPath: expectedURL.path), fixtureURL.path)
            XCTAssertTrue(FileManager.default.fileExists(atPath: metadataURL.path), fixtureURL.path)

            let metadata = try fixtureMetadata(at: metadataURL)
            XCTAssertFalse(metadata.captureMode.hasPrefix("starter"), fixtureURL.lastPathComponent)
            XCTAssertFalse(metadata.types.isEmpty, fixtureURL.lastPathComponent)

            let paste = try CleanPasteTransform.clean(try pasteboardContent(
                for: fixtureURL,
                metadata: metadata
            ))
            let expected = try fixtureText(at: expectedURL)

            XCTAssertEqual(paste.previewText, expected, fixtureURL.lastPathComponent)
            XCTAssertEqual(paste.observedTypeIdentifiers, metadata.types.sorted(), fixtureURL.lastPathComponent)
            XCTAssertEqual(paste.transformVersion, CleanPasteTransform.version, fixtureURL.lastPathComponent)
            XCTAssertEqual(
                paste.sourceFlavor,
                metadata.preferredSourceFlavor.map(PasteboardSourceFlavor.init(rawValue:))
                    ?? (metadata.hasPlainText ? .plainText : .html),
                fixtureURL.lastPathComponent
            )
        }
    }

    private func packageRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func allFixtureDirectories(_ root: URL) throws -> [URL] {
        let categories = try FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey]
        )
        .filter(\.hasDirectoryPath)

        return try categories.flatMap { category in
            try FileManager.default.contentsOfDirectory(
                at: category,
                includingPropertiesForKeys: [.isDirectoryKey]
            )
            .filter(\.hasDirectoryPath)
        }
        .sorted { $0.path < $1.path }
    }

    private func fixtureMetadata(at url: URL) throws -> FixtureMetadata {
        try JSONDecoder().decode(FixtureMetadata.self, from: Data(contentsOf: url))
    }

    private func fixtureText(at url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
            .trimmingCharacters(in: .newlines)
    }

    private func pasteboardContent(
        for fixtureURL: URL,
        metadata: FixtureMetadata
    ) throws -> PasteboardContent {
        let plainURL = fixtureURL.appendingPathComponent("raw/plain.txt")
        let htmlURL = fixtureURL.appendingPathComponent("raw/source.html")
        var representations: [String: String] = [:]

        if FileManager.default.fileExists(atPath: plainURL.path) {
            representations[PasteboardTypeIdentifier.plainText] = try String(
                contentsOf: plainURL,
                encoding: .utf8
            )
        }
        if FileManager.default.fileExists(atPath: htmlURL.path) {
            representations[PasteboardTypeIdentifier.html] = try String(
                contentsOf: htmlURL,
                encoding: .utf8
            )
        }

        return PasteboardContent(
            textualRepresentations: representations,
            availableTypeIdentifiers: metadata.types
        )
    }
}

private struct FixtureMetadata: Decodable {
    let captureMode: String
    let category: String
    let fullCapture: Bool
    let hasHTML: Bool
    let hasPlainText: Bool
    let preferredSourceFlavor: String?
    let types: [String]
}

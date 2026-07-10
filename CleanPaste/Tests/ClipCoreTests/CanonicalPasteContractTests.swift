import XCTest
@testable import ClipCore

final class CanonicalPasteContractTests: XCTestCase {
    func testCanonicalPasteCarriesDeterministicProvenanceAndVersion() throws {
        let paste = try CleanPasteTransform.clean(PasteboardContent(
            plainText: "Hello **world**",
            htmlText: "<p>Ignored</p>",
            availableTypeIdentifiers: [
                PasteboardTypeIdentifier.html,
                PasteboardTypeIdentifier.plainText,
                PasteboardTypeIdentifier.html
            ]
        ))

        XCTAssertEqual(paste.previewText, "Hello world")
        XCTAssertEqual(paste.sourceFlavor, .plainText)
        XCTAssertEqual(paste.observedTypeIdentifiers, [
            PasteboardTypeIdentifier.html,
            PasteboardTypeIdentifier.plainText
        ])
        XCTAssertEqual(paste.transformVersion, CleanPasteTransform.version)
        XCTAssertFalse(paste.transformVersion.isEmpty)
    }

    func testDefaultExtractorsPreferPlainTextAndRecoverHTML() throws {
        let plain = try SourceExtractionPipeline.default.extract(from: PasteboardContent(
            plainText: "Plain",
            htmlText: "<p>HTML</p>"
        ))
        let html = try SourceExtractionPipeline.default.extract(from: PasteboardContent(
            htmlText: "<p>HTML</p>"
        ))

        XCTAssertEqual(plain, SourceExtraction(text: "Plain", flavor: .plainText))
        XCTAssertEqual(html, SourceExtraction(text: "HTML", flavor: .html))
    }

    func testNewTextFlavorNeedsOnlyAnExtractor() throws {
        let customType = "com.example.cleanpaste.custom-text"
        let content = PasteboardContent(
            textualRepresentations: [customType: "Custom **content**"],
            availableTypeIdentifiers: [customType]
        )
        let pipeline = SourceExtractionPipeline(extractors: [
            TypeIdentifierSourceExtractor(
                typeIdentifier: customType,
                sourceFlavor: PasteboardSourceFlavor(rawValue: "custom_text")
            )
        ])

        let paste = try CleanPasteTransform.clean(content, using: pipeline)

        XCTAssertEqual(paste.previewText, "Custom content")
        XCTAssertEqual(paste.sourceFlavor.rawValue, "custom_text")
        XCTAssertEqual(paste.observedTypeIdentifiers, [customType])
    }

    func testExtractorPipelineRejectsWhitespaceOnlyRepresentations() {
        let pipeline = SourceExtractionPipeline(extractors: [
            TypeIdentifierSourceExtractor(
                typeIdentifier: "com.example.empty",
                sourceFlavor: PasteboardSourceFlavor(rawValue: "empty")
            )
        ])

        XCTAssertThrowsError(try pipeline.extract(from: PasteboardContent(
            textualRepresentations: ["com.example.empty": "  \n  "]
        ))) { error in
            XCTAssertEqual(error as? CleanPasteTransformError, .noSupportedText)
        }
    }
}

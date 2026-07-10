import XCTest
@testable import ClipCore

final class CleanPasteTransformTests: XCTestCase {
    func testParagraphFixtureCollapsesExtraBlankLinesAndStripsEmphasis() throws {
        let result = try CleanPasteTransform.previewText(from: PasteboardContent(plainText: try fixture("ai-chat/source", "txt")))
        XCTAssertEqual(result, try fixture("ai-chat/expected", "txt"))
    }

    func testMarkdownKeepsLegitimateTypographyAndIdentifiers() throws {
        let result = try CleanPasteTransform.previewText(from: PasteboardContent(plainText: try fixture("markdown/source", "txt")))
        XCTAssertEqual(result, try fixture("markdown/expected", "txt"))
    }

    func testMarkdownHeadingRemovalPreservesSurroundingBlankLines() throws {
        let input = """
        Intro paragraph.

        ### Top 10 Highest Global Obesity Rates

        Detail paragraph.

        1. **American Samoa** — 75.9%
        2. **Tonga** — 72.3%

        ### High Obesity Rates in Other Regions

        **The Caribbean**
        """

        let result = try CleanPasteTransform.previewText(from: PasteboardContent(plainText: input))

        XCTAssertEqual(result, """
        Intro paragraph.

        Top 10 Highest Global Obesity Rates

        Detail paragraph.

        1. American Samoa — 75.9%
        2. Tonga — 72.3%

        High Obesity Rates in Other Regions

        The Caribbean
        """)
    }

    func testUnicodeCleanupRemovesInvisibleSpacingNoise() throws {
        let input = "A\u{00A0}B\u{202F}C\u{2009}D\u{200B}\u{200C}\u{200D}E\u{FEFF}"
        let result = try CleanPasteTransform.previewText(from: PasteboardContent(plainText: input))
        XCTAssertEqual(result, "A B C D\u{200D}E")
    }

    func testUnicodeCleanupPreservesEmojiJoiners() throws {
        let result = try CleanPasteTransform.previewText(from: PasteboardContent(
            plainText: "Family 👨‍👩‍👧‍👦"
        ))

        XCTAssertEqual(result, "Family 👨‍👩‍👧‍👦")
    }

    func testMarkdownSelfLabeledURLIsNotDuplicated() throws {
        let result = try CleanPasteTransform.previewText(from: PasteboardContent(
            plainText: "Read [https://example.org/f3](https://example.org/f3)"
        ))

        XCTAssertEqual(result, "Read https://example.org/f3")
    }

    func testMarkdownDescriptiveLinkKeepsLabelAndTarget() throws {
        let result = try CleanPasteTransform.previewText(from: PasteboardContent(
            plainText: "Read [example](https://example.org/f3)"
        ))

        XCTAssertEqual(result, "Read example (https://example.org/f3)")
    }

    func testHTMLNestedUnorderedListsPreserveHierarchy() throws {
        let result = try CleanPasteTransform.previewText(from: PasteboardContent(htmlText: """
            <ul><li>Parent<ul><li>Child A</li><li>Child B</li></ul></li></ul>
            """))

        XCTAssertEqual(result, "- Parent\n  - Child A\n  - Child B")
    }

    func testHTMLNestedOrderedListsPreserveHierarchyAndNumbers() throws {
        let result = try CleanPasteTransform.previewText(from: PasteboardContent(htmlText: """
            <ol start="3"><li>Parent<ol><li>Child A</li><li>Child B</li></ol></li></ol>
            """))

        XCTAssertEqual(result, "3. Parent\n  1. Child A\n  2. Child B")
    }

    func testHTMLMixedNestedListsPreserveHierarchy() throws {
        let result = try CleanPasteTransform.previewText(from: PasteboardContent(htmlText: """
            <ul><li>Parent<ol><li>Step A<ul><li>Detail</li></ul></li></ol></li></ul>
            """))

        XCTAssertEqual(result, "- Parent\n  1. Step A\n    - Detail")
    }

    func testHTMLFallbackPreservesBlocksListsAndTables() throws {
        let result = try CleanPasteTransform.clean(PasteboardContent(htmlText: try fixture("html-only/source", "html")))
        XCTAssertEqual(result.sourceFlavor, .html)
        XCTAssertEqual(result.previewText, try fixture("html-only/expected", "txt"))
    }

    func testPlainTextWinsOverHTMLWhenBothExist() throws {
        let result = try CleanPasteTransform.clean(PasteboardContent(
            plainText: "Plain **wins**",
            htmlText: "<p>HTML loses</p>"
        ))

        XCTAssertEqual(result.sourceFlavor, .plainText)
        XCTAssertEqual(result.previewText, "Plain wins")
    }

    func testHTMLRestoresParagraphBreaksWhenItsWordsMatchPlainText() throws {
        let paragraph = "Based on data from WHO, the highest rates are concentrated globally."
        let heading = "Top 10 Highest Global Obesity Rates"
        let detail = "Pacific Island nations occupy the highest slots globally."
        let result = try CleanPasteTransform.clean(PasteboardContent(
            plainText: "\(paragraph)\n\(heading)\n\(detail)",
            htmlText: "<p>\(paragraph)</p><h2>\(heading)</h2><p>\(detail)</p>"
        ))

        XCTAssertEqual(result.sourceFlavor, .html)
        XCTAssertEqual(result.previewText, "\(paragraph)\n\n\(heading)\n\n\(detail)")
    }

    func testHTMLRestoresBreaksWhenItContainsCitationChipsMissingFromPlainText() throws {
        let paragraph = "Based on data from WHO, the highest rates are concentrated globally."
        let heading = "Top 10 Highest Global Obesity Rates"
        let detail = "Pacific Island nations occupy the highest slots globally."
        let firstItem = "1. American Samoa — 75.9%"
        let result = try CleanPasteTransform.clean(PasteboardContent(
            plainText: "\(paragraph)\n\(heading)\n\(detail)\n\(firstItem)",
            htmlText: """
            <p>\(paragraph) <span class="citation-chip">statranker.org</span></p>
            <h2>\(heading)</h2>
            <p>\(detail) <button>basarihospital.com</button></p>
            <ol><li><strong>American Samoa — 75.9%</strong> <span>data.worldobesity.org</span></li></ol>
            """
        ))

        XCTAssertEqual(result.sourceFlavor, .html)
        XCTAssertEqual(result.previewText, "\(paragraph)\n\n\(heading)\n\n\(detail)\n\n\(firstItem)")
    }

    func testEmptyClipboardFailsWithoutOutput() {
        XCTAssertThrowsError(try CleanPasteTransform.previewText(from: PasteboardContent())) { error in
            XCTAssertEqual(error as? CleanPasteTransformError, .noSupportedText)
        }
    }

    func testCodeFenceRemovesFenceMarkersAndKeepsContents() throws {
        let input = """
        ```swift
        let snake_case = "file_name.txt"
        ```
        """

        let result = try CleanPasteTransform.previewText(from: PasteboardContent(plainText: input))
        XCTAssertEqual(result, #"let snake_case = "file_name.txt""#)
    }

    func testCodeAndNestedListIndentationSurvivesTrailingWhitespaceCleanup() throws {
        let input = """
        ```swift
        if ready {
            run()   
        }
        ```

          * Nested item   
        """

        let result = try CleanPasteTransform.previewText(from: PasteboardContent(plainText: input))

        XCTAssertEqual(result, """
        if ready {
            run()
        }

          - Nested item
        """)
    }

    func testHTMLFallbackPreservesOrderedListNumbers() throws {
        let html = "<ol><li>First step</li><li><strong>Second</strong> step</li></ol>"

        let result = try CleanPasteTransform.previewText(from: PasteboardContent(htmlText: html))

        XCTAssertEqual(result, "1. First step\n2. Second step")
    }

    func testHTMLFallbackDropsHiddenElementContents() throws {
        let html = """
        <p>Hello <span style="display: none">secret</span>world</p>
        <div hidden>hidden attribute</div>
        <div aria-hidden="true">aria hidden</div>
        <section style="visibility:hidden">invisible</section>
        <p>Visible</p>
        """

        let result = try CleanPasteTransform.previewText(from: PasteboardContent(htmlText: html))

        XCTAssertEqual(result, "Hello world\n\nVisible")
    }

    private func fixture(_ name: String, _ ext: String) throws -> String {
        let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Fixtures"))
        return try String(contentsOf: url, encoding: .utf8)
            .trimmingCharacters(in: .newlines)
    }
}

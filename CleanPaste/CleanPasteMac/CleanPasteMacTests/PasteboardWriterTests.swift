import AppKit
import ClipCore
import XCTest
@testable import CleanPasteMacCore

final class PasteboardWriterTests: XCTestCase {
    func testWriterClearsRichFlavorsAndLeavesOnlyPlainText() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("CleanPasteTests.\(UUID().uuidString)"))
        pasteboard.clearContents()
        pasteboard.setString("plain", forType: .string)
        pasteboard.setString("<b>rich</b>", forType: .html)

        let writer = CleanPasteboardWriter(pasteboard: pasteboard)
        try writer.write("clean text")

        XCTAssertEqual(pasteboard.string(forType: .string), "clean text")
        XCTAssertNil(pasteboard.string(forType: .html))
        XCTAssertNil(pasteboard.data(forType: .rtf))
        XCTAssertTrue(Set(pasteboard.types?.map(\.rawValue) ?? []).isSubset(of: [
            PasteboardTypeIdentifier.plainText,
            "NSStringPboardType"
        ]))
    }

    func testWriterRefusesEmptyTextBeforeClearing() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("CleanPasteTests.\(UUID().uuidString)"))
        pasteboard.clearContents()
        pasteboard.setString("keep me", forType: .string)

        let writer = CleanPasteboardWriter(pasteboard: pasteboard)

        XCTAssertThrowsError(try writer.write("   ")) { error in
            XCTAssertEqual(error as? PasteboardWriteError, .emptyText)
        }
        XCTAssertEqual(pasteboard.string(forType: .string), "keep me")
    }

    func testWriterAddsSemanticHTMLForOrderedLists() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("CleanPasteTests.\(UUID().uuidString)"))
        let writer = CleanPasteboardWriter(pasteboard: pasteboard)

        try writer.write("Steps\n\n1. First\n2. Second")

        XCTAssertEqual(pasteboard.string(forType: .string), "Steps\n\n1. First\n2. Second")
        let html = try XCTUnwrap(pasteboard.string(forType: .html))
        XCTAssertTrue(html.contains("<ol>"))
        XCTAssertTrue(html.contains("<li>First</li>"))
        XCTAssertTrue(html.contains("<li>Second</li>"))
        XCTAssertTrue(html.contains("<p>Steps</p><br><ol>"))
    }

    func testWriterAddsSemanticHTMLForBulletLists() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("CleanPasteTests.\(UUID().uuidString)"))
        let writer = CleanPasteboardWriter(pasteboard: pasteboard)

        try writer.write("- Apples\n- Pears & oranges")

        let html = try XCTUnwrap(pasteboard.string(forType: .html))
        XCTAssertTrue(html.contains("<ul>"))
        XCTAssertTrue(html.contains("<li>Apples</li>"))
        XCTAssertTrue(html.contains("<li>Pears &amp; oranges</li>"))
    }

    func testWriterUsesLiteralMarkersWithoutHTMLForLinkedInStyleTargets() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("CleanPasteTests.\(UUID().uuidString)"))
        let writer = CleanPasteboardWriter(pasteboard: pasteboard)

        try writer.write("Intro\n\n1. First\n2. Second", listMode: .literalMarkers)

        XCTAssertEqual(pasteboard.string(forType: .string), "Intro\n\n1. First\n2. Second")
        XCTAssertNil(pasteboard.string(forType: .html))
    }

    func testReaderCapturesAllTextualRepresentationsForExtractors() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("CleanPasteTests.\(UUID().uuidString)"))
        let customType = NSPasteboard.PasteboardType("com.example.cleanpaste.custom-text")
        pasteboard.clearContents()
        pasteboard.setString("custom payload", forType: customType)

        let snapshot = PasteboardReader(pasteboard: pasteboard).snapshot()

        XCTAssertEqual(snapshot.typeIdentifiers, [customType.rawValue])
        XCTAssertEqual(snapshot.content.text(forTypeIdentifier: customType.rawValue), "custom payload")
        XCTAssertNil(snapshot.content.plainText)
        XCTAssertNil(snapshot.content.htmlText)
    }
}

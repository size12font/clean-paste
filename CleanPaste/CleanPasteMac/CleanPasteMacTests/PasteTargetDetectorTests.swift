import XCTest
@testable import CleanPasteMacCore

final class PasteTargetDetectorTests: XCTestCase {
    func testSlackUsesSemanticLists() {
        XCTAssertEqual(
            PasteTargetDetector.listOutputMode(bundleIdentifier: "com.tinyspeck.slackmacgap"),
            .semanticLists
        )
    }

    func testLinkedInInBrowserUsesLiteralMarkers() {
        XCTAssertEqual(
            PasteTargetDetector.listOutputMode(
                bundleIdentifier: "com.google.Chrome",
                windowTitle: "size12font | LinkedIn"
            ),
            .literalMarkers
        )
        XCTAssertEqual(
            PasteTargetDetector.listOutputMode(bundleIdentifier: "com.apple.Safari"),
            .literalMarkers
        )
    }

    func testSlackInBrowserUsesSemanticLists() {
        XCTAssertEqual(
            PasteTargetDetector.listOutputMode(
                bundleIdentifier: "com.google.Chrome",
                windowTitle: "general | GooseWorks | Slack"
            ),
            .semanticLists
        )
    }

    func testLinkedInArticleMentioningSlackStillUsesLiteralMarkers() {
        XCTAssertEqual(
            PasteTargetDetector.listOutputMode(
                bundleIdentifier: "com.google.Chrome",
                windowTitle: "Slack CEO interview | LinkedIn"
            ),
            .literalMarkers
        )
    }

    func testUnknownTargetSafelyUsesLiteralMarkers() {
        XCTAssertEqual(
            PasteTargetDetector.listOutputMode(bundleIdentifier: "com.example.editor"),
            .literalMarkers
        )
    }
}

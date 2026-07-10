import XCTest
import ClipCore
@testable import CleanPasteMacCore

final class CleanPasteControllerTests: XCTestCase {
    @MainActor
    func testCleanClipboardWritesPreviewText() {
        let writer = SpyWriter()
        let controller = CleanPasteController(
            reader: StubReader(snapshot: PasteboardSnapshot(
                changeCount: 1,
                typeIdentifiers: ["public.utf8-plain-text", "public.html"],
                plainText: "**Hello**"
            )),
            writer: writer,
            pasteSender: StubPasteSender(succeeds: false),
            permissionChecker: StubPermissionChecker(isTrusted: false)
        )

        let result = controller.cleanClipboardNow()

        XCTAssertEqual(result, .cleaned("Hello"))
        XCTAssertEqual(writer.writes, ["Hello"])
        XCTAssertEqual(controller.previewModel.canonicalPaste?.previewText, "Hello")
        XCTAssertEqual(controller.previewModel.canonicalPaste?.sourceFlavor, .plainText)
        XCTAssertEqual(controller.previewModel.canonicalPaste?.observedTypeIdentifiers, [
            "public.html",
            "public.utf8-plain-text"
        ])
        XCTAssertEqual(controller.previewModel.canonicalPaste?.transformVersion, CleanPasteTransform.version)
    }

    @MainActor
    func testAutomaticCleanUsesObservedSnapshot() {
        let writer = SpyWriter()
        let controller = CleanPasteController(
            reader: StubReader(snapshot: PasteboardSnapshot(
                changeCount: 99,
                typeIdentifiers: [PasteboardTypeIdentifier.plainText],
                plainText: "Wrong reader value"
            )),
            writer: writer,
            pasteSender: StubPasteSender(succeeds: false),
            permissionChecker: StubPermissionChecker(isTrusted: false)
        )

        let result = controller.cleanAutomatically(PasteboardSnapshot(
            changeCount: 2,
            typeIdentifiers: [PasteboardTypeIdentifier.plainText],
            plainText: "**Copied** value"
        ))

        XCTAssertEqual(result, .cleaned("Copied value"))
        XCTAssertEqual(writer.writes, ["Copied value"])
    }

    @MainActor
    func testUnsupportedAutomaticCopyDoesNotReplaceStatus() {
        let previewModel = PreviewModel(status: .cleaned)
        let controller = CleanPasteController(
            reader: StubReader(snapshot: PasteboardSnapshot(changeCount: 1, typeIdentifiers: [])),
            writer: SpyWriter(),
            pasteSender: StubPasteSender(succeeds: false),
            permissionChecker: StubPermissionChecker(isTrusted: false),
            previewModel: previewModel
        )

        _ = controller.cleanAutomatically(PasteboardSnapshot(
            changeCount: 2,
            typeIdentifiers: ["public.png"]
        ))

        XCTAssertEqual(previewModel.status, .cleaned)
    }

    @MainActor
    func testPreparingForSlackRewritesCanonicalTextWithSemanticLists() {
        let writer = SpyWriter()
        let previewModel = PreviewModel(canonicalPaste: CanonicalPaste(
            previewText: "1. First\n2. Second",
            sourceFlavor: .plainText,
            observedTypeIdentifiers: [PasteboardTypeIdentifier.plainText],
            transformVersion: CleanPasteTransform.version
        ))
        let controller = CleanPasteController(
            reader: StubReader(snapshot: PasteboardSnapshot(changeCount: 1, typeIdentifiers: [])),
            writer: writer,
            pasteSender: StubPasteSender(succeeds: false),
            permissionChecker: StubPermissionChecker(isTrusted: false),
            targetDetector: StubTargetDetector(mode: .semanticLists),
            previewModel: previewModel
        )

        XCTAssertTrue(controller.prepareClipboardForCurrentTarget())
        XCTAssertEqual(writer.writes, ["1. First\n2. Second"])
        XCTAssertEqual(writer.modes, [.semanticLists])
    }

    @MainActor
    func testCleanAndPasteFallsBackWhenAccessibilityDenied() {
        let writer = SpyWriter()
        let permission = StubPermissionChecker(isTrusted: false)
        let pasteSender = StubPasteSender(succeeds: true)
        let controller = CleanPasteController(
            reader: StubReader(snapshot: PasteboardSnapshot(
                changeCount: 1,
                typeIdentifiers: ["public.utf8-plain-text"],
                plainText: "Manual **paste**"
            )),
            writer: writer,
            pasteSender: pasteSender,
            permissionChecker: permission
        )

        let result = controller.cleanAndPaste()

        XCTAssertEqual(result, .needsManualPaste("Manual paste"))
        XCTAssertEqual(writer.writes, ["Manual paste"])
        XCTAssertEqual(permission.promptCount, 1)
        XCTAssertEqual(pasteSender.sendCount, 0)
    }

    @MainActor
    func testCleanAndPasteRequestsAccessibilityOnlyOncePerSession() {
        let permission = StubPermissionChecker(isTrusted: false)
        let controller = CleanPasteController(
            reader: StubReader(snapshot: PasteboardSnapshot(
                changeCount: 1,
                typeIdentifiers: [PasteboardTypeIdentifier.plainText],
                plainText: "Manual paste"
            )),
            writer: SpyWriter(),
            pasteSender: StubPasteSender(succeeds: true),
            permissionChecker: permission
        )

        XCTAssertEqual(controller.cleanAndPaste(), .needsManualPaste("Manual paste"))
        XCTAssertEqual(controller.cleanAndPaste(), .needsManualPaste("Manual paste"))
        XCTAssertEqual(permission.promptCount, 1)
    }

    @MainActor
    func testCleanAndPasteSendsPasteWhenAccessibilityAllowed() {
        let pasteSender = StubPasteSender(succeeds: true)
        let permission = StubPermissionChecker(isTrusted: true)
        let controller = CleanPasteController(
            reader: StubReader(snapshot: PasteboardSnapshot(
                changeCount: 1,
                typeIdentifiers: [PasteboardTypeIdentifier.plainText],
                plainText: "Paste **now**"
            )),
            writer: SpyWriter(),
            pasteSender: pasteSender,
            permissionChecker: permission
        )

        XCTAssertEqual(controller.cleanAndPaste(), .pasted("Paste now"))
        XCTAssertEqual(pasteSender.sendCount, 1)
        XCTAssertEqual(permission.promptCount, 0)
        XCTAssertEqual(controller.previewModel.status, .pasted)
    }

    @MainActor
    func testCleanAndPasteFallsBackWhenSyntheticPasteFails() {
        let pasteSender = StubPasteSender(succeeds: false)
        let controller = CleanPasteController(
            reader: StubReader(snapshot: PasteboardSnapshot(
                changeCount: 1,
                typeIdentifiers: [PasteboardTypeIdentifier.plainText],
                plainText: "Keep clipboard"
            )),
            writer: SpyWriter(),
            pasteSender: pasteSender,
            permissionChecker: StubPermissionChecker(isTrusted: true)
        )

        XCTAssertEqual(controller.cleanAndPaste(), .needsManualPaste("Keep clipboard"))
        XCTAssertEqual(pasteSender.sendCount, 1)
        XCTAssertEqual(controller.previewModel.status, .manualPasteRequired)
    }

    @MainActor
    func testUnsupportedClipboardFailsWithoutWritingOrReplacingLastPreview() {
        let writer = SpyWriter()
        let previousPaste = CanonicalPaste(
            previewText: "Previous preview",
            sourceFlavor: .plainText,
            observedTypeIdentifiers: [PasteboardTypeIdentifier.plainText],
            transformVersion: CleanPasteTransform.version
        )
        let previewModel = PreviewModel(canonicalPaste: previousPaste)
        let controller = CleanPasteController(
            reader: StubReader(snapshot: PasteboardSnapshot(
                changeCount: 2,
                typeIdentifiers: ["public.png"]
            )),
            writer: writer,
            pasteSender: StubPasteSender(succeeds: true),
            permissionChecker: StubPermissionChecker(isTrusted: true),
            previewModel: previewModel
        )

        let result = controller.cleanClipboardNow()

        guard case .failed = result else {
            return XCTFail("Expected unsupported clipboard to fail")
        }
        XCTAssertTrue(writer.writes.isEmpty)
        XCTAssertEqual(previewModel.canonicalPaste, previousPaste)
    }
}

private struct StubReader: PasteboardReading {
    var storedSnapshot: PasteboardSnapshot

    init(snapshot: PasteboardSnapshot) {
        self.storedSnapshot = snapshot
    }

    func snapshot() -> PasteboardSnapshot { storedSnapshot }
}

private final class SpyWriter: CleanPasteboardWriting, @unchecked Sendable {
    private(set) var writes: [String] = []
    private(set) var modes: [ListOutputMode] = []

    func write(_ text: String, listMode: ListOutputMode) throws {
        writes.append(text)
        modes.append(listMode)
    }
}

@MainActor
private final class StubTargetDetector: PasteTargetDetecting {
    let mode: ListOutputMode

    init(mode: ListOutputMode) {
        self.mode = mode
    }

    func currentListOutputMode() -> ListOutputMode { mode }
}

private final class StubPasteSender: PasteSending, @unchecked Sendable {
    var succeeds: Bool
    private(set) var sendCount = 0

    init(succeeds: Bool) {
        self.succeeds = succeeds
    }

    func sendPaste() -> Bool {
        sendCount += 1
        return succeeds
    }
}

private final class StubPermissionChecker: AccessibilityPermissionChecking, @unchecked Sendable {
    var isTrusted: Bool
    private(set) var promptCount = 0

    init(isTrusted: Bool) {
        self.isTrusted = isTrusted
    }

    func requestAccessPrompt() {
        promptCount += 1
    }
}

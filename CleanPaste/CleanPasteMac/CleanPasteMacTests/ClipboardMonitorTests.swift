import XCTest
import ClipCore
@testable import CleanPasteMacCore

final class ClipboardMonitorTests: XCTestCase {
    @MainActor
    func testPollNotifiesOnceForNewUserCopyAndAcknowledgesAppWrite() {
        let reader = MutableReader(snapshot: PasteboardSnapshot(
            changeCount: 1,
            typeIdentifiers: []
        ))
        let monitor = ClipboardMonitor(reader: reader)
        var observed: [Int] = []

        monitor.start { snapshot in
            observed.append(snapshot.changeCount)
            reader.storedSnapshot = PasteboardSnapshot(
                changeCount: 3,
                typeIdentifiers: [PasteboardTypeIdentifier.plainText],
                plainText: "Cleaned"
            )
        }

        reader.storedSnapshot = PasteboardSnapshot(
            changeCount: 2,
            typeIdentifiers: [PasteboardTypeIdentifier.plainText],
            plainText: "**Copied**"
        )
        monitor.poll()
        monitor.poll()

        XCTAssertEqual(observed, [2])
        monitor.stop()
    }
}

private final class MutableReader: PasteboardReading, @unchecked Sendable {
    var storedSnapshot: PasteboardSnapshot

    init(snapshot: PasteboardSnapshot) {
        self.storedSnapshot = snapshot
    }

    func snapshot() -> PasteboardSnapshot { storedSnapshot }
}

import Carbon.HIToolbox
import XCTest
@testable import CleanPasteMacCore

final class HotkeyControllerTests: XCTestCase {
    @MainActor
    func testGlobalHotkeyRegistrationReceivesCommandShiftV() throws {
        let controller = HotkeyController()
        var invocationCount = 0

        XCTAssertTrue(controller.start {
            invocationCount += 1
        })
        defer { controller.stop() }

        var event: EventRef?
        XCTAssertEqual(CreateEvent(
            nil,
            OSType(kEventClassKeyboard),
            UInt32(kEventHotKeyPressed),
            GetCurrentEventTime(),
            EventAttributes(kEventAttributeNone),
            &event
        ), noErr)
        XCTAssertEqual(
            SendEventToEventTarget(try XCTUnwrap(event), GetApplicationEventTarget()),
            noErr
        )

        let deadline = Date().addingTimeInterval(2)
        while invocationCount == 0, Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.02))
        }

        XCTAssertEqual(invocationCount, 1)
    }
}

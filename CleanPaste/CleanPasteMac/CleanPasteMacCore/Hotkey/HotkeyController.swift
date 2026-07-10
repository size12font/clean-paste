import AppKit
import Carbon.HIToolbox
import Foundation

@MainActor
public final class HotkeyController {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var action: (@MainActor () -> Void)?

    public init() {}

    @discardableResult
    public func start(action: @escaping @MainActor () -> Void) -> Bool {
        stop()
        self.action = action

        let hotKeyID = EventHotKeyID(signature: Self.hotKeySignature, id: 1)
        let registrationStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard registrationStatus == noErr else {
            self.action = nil
            return false
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                let controller = Unmanaged<HotkeyController>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in
                    controller.action?()
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        guard handlerStatus == noErr else {
            stop()
            return false
        }

        return true
    }

    public func stop() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
        action = nil
    }

    private static let hotKeySignature: OSType = 0x43505354
}

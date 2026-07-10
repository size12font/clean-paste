import ApplicationServices
import Foundation

public protocol PasteSending: Sendable {
    func sendPaste() -> Bool
}

public struct SyntheticPasteSender: PasteSending {
    public init() {}

    public func sendPaste() -> Bool {
        let source = CGEventSource(stateID: .hidSystemState)
        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        else {
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }
}


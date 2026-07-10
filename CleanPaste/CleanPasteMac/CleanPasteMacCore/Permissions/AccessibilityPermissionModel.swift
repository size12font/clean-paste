import ApplicationServices
import Foundation

public protocol AccessibilityPermissionChecking: Sendable {
    var isTrusted: Bool { get }
    func requestAccessPrompt()
}

public struct AccessibilityPermissionModel: AccessibilityPermissionChecking {
    public init() {}

    public var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    public func requestAccessPrompt() {
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }
}

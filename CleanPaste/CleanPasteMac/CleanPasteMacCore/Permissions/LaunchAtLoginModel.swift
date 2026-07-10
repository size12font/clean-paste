import Combine
import Foundation
import ServiceManagement

@MainActor
public protocol LaunchAtLoginServicing {
    func register() throws
    func unregister() throws
}

public struct MainAppLaunchAtLoginService: LaunchAtLoginServicing {
    public init() {}

    public func register() throws {
        try SMAppService.mainApp.register()
    }

    public func unregister() throws {
        try SMAppService.mainApp.unregister()
    }
}

@MainActor
public final class LaunchAtLoginModel: ObservableObject {
    public static let preferenceKey = "CleanPaste.launchAtLoginRequested"

    private let defaults: UserDefaults
    private let service: any LaunchAtLoginServicing

    @Published public private(set) var isEnabled: Bool
    @Published public private(set) var lastError: String?

    public init(
        defaults: UserDefaults = .standard,
        service: any LaunchAtLoginServicing = MainAppLaunchAtLoginService()
    ) {
        self.defaults = defaults
        self.service = service
        self.isEnabled = defaults.bool(forKey: Self.preferenceKey)
    }

    public func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            defaults.set(enabled, forKey: Self.preferenceKey)
            isEnabled = enabled
            lastError = nil
        } catch {
            defaults.set(false, forKey: Self.preferenceKey)
            isEnabled = false
            lastError = error.localizedDescription
        }
    }
}

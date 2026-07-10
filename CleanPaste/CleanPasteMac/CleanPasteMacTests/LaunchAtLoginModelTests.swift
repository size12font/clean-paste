import XCTest
@testable import CleanPasteMacCore

final class LaunchAtLoginModelTests: XCTestCase {
    @MainActor
    func testSuccessfulRegistrationPersistsPreference() throws {
        let suiteName = "CleanPasteTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let service = StubLaunchAtLoginService()
        let model = LaunchAtLoginModel(defaults: defaults, service: service)

        model.setEnabled(true)

        XCTAssertTrue(model.isEnabled)
        XCTAssertTrue(defaults.bool(forKey: LaunchAtLoginModel.preferenceKey))
        XCTAssertEqual(service.registerCount, 1)
        XCTAssertTrue(LaunchAtLoginModel(defaults: defaults, service: service).isEnabled)
    }

    @MainActor
    func testRegistrationFailureDoesNotPersistEnabledState() throws {
        let suiteName = "CleanPasteTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let service = StubLaunchAtLoginService(error: StubError.failed)
        let model = LaunchAtLoginModel(defaults: defaults, service: service)

        model.setEnabled(true)

        XCTAssertFalse(model.isEnabled)
        XCTAssertFalse(defaults.bool(forKey: LaunchAtLoginModel.preferenceKey))
        XCTAssertNotNil(model.lastError)
    }
}

private enum StubError: Error {
    case failed
}

private final class StubLaunchAtLoginService: LaunchAtLoginServicing, @unchecked Sendable {
    private let error: Error?
    private(set) var registerCount = 0
    private(set) var unregisterCount = 0

    init(error: Error? = nil) {
        self.error = error
    }

    func register() throws {
        registerCount += 1
        if let error { throw error }
    }

    func unregister() throws {
        unregisterCount += 1
        if let error { throw error }
    }
}

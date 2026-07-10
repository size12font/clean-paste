import XCTest
@testable import ClipCore

final class TargetCapabilityTests: XCTestCase {
    func testReleaseGateDeclaresEveryCapabilityClassBehaviorally() throws {
        let capabilities = TargetCapability.releaseGate

        XCTAssertEqual(Set(capabilities.map(\.kind)), Set(TargetCapabilityKind.allCases))
        XCTAssertEqual(capabilities.count, TargetCapabilityKind.allCases.count)

        for capability in capabilities {
            XCTAssertTrue(capability.acceptsPlainText, capability.kind.rawValue)
            XCTAssertTrue(capability.preservesNewlines, capability.kind.rawValue)
            XCTAssertTrue(capability.preservesListMarkers, capability.kind.rawValue)
            XCTAssertNil(capability.maximumLength, capability.kind.rawValue)
        }

        let data = try JSONEncoder().encode(capabilities)
        XCTAssertEqual(try JSONDecoder().decode([TargetCapability].self, from: data), capabilities)
    }
}

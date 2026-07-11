import XCTest
import CoreLocation
@testable import Forge

final class RunMathTests: XCTestCase {
    func testPaceNilUntilMeaningfulMovement() {
        XCTAssertNil(RunMath.paceSecPerKm(meters: 10, seconds: 60))
        XCTAssertNotNil(RunMath.paceSecPerKm(meters: 500, seconds: 150))
    }
    func testPaceMath() {
        // 5:00/km: 1000m in 300s
        XCTAssertEqual(RunMath.paceSecPerKm(meters: 1000, seconds: 300)!, 300, accuracy: 0.01)
        XCTAssertEqual(RunMath.paceLabel(secPerKm: 300, imperial: false), "5'00\"")
        // Imperial conversion: 300 s/km ≈ 482.8 s/mi ≈ 8'02"
        XCTAssertEqual(RunMath.paceLabel(secPerKm: 300, imperial: true), "8'02\"")
    }
    func testDistanceLabels() {
        XCTAssertEqual(RunMath.distanceLabel(meters: 5000, imperial: false), "5.00")
        XCTAssertEqual(RunMath.distanceLabel(meters: 1609.344, imperial: true), "1.00")
    }
    func testGPSNoiseFilter() {
        XCTAssertTrue(RunMath.isUsable(accuracy: 10, jumpMeters: 15, dt: 3))
        XCTAssertFalse(RunMath.isUsable(accuracy: 80, jumpMeters: 15, dt: 3), "bad accuracy")
        XCTAssertFalse(RunMath.isUsable(accuracy: 10, jumpMeters: 200, dt: 3), "teleport")
        XCTAssertFalse(RunMath.isUsable(accuracy: -1, jumpMeters: 5, dt: 3), "invalid accuracy")
    }
    func testTrackerLifecycleSafeWithoutAuth() {
        let t = RunTrackerService()
        t.stop(); t.pause(); t.resume()   // no crash from any state
        XCTAssertEqual(t.distanceMeters, 0)
    }
}

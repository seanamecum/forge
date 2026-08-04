import XCTest
@testable import Forge

/// The macro/calorie ring fill logic — honest clamping, never a fabricated full
/// ring, and a clear over-target signal.
final class RingMathTests: XCTestCase {

    func testFillIsProportionAndClampsToOne() {
        XCTAssertEqual(RingMath.fill(90, of: 180), 0.5, accuracy: 0.0001)
        XCTAssertEqual(RingMath.fill(180, of: 180), 1.0, accuracy: 0.0001)
        XCTAssertEqual(RingMath.fill(300, of: 180), 1.0)        // over → still a full ring, never > 1
    }

    func testFillEmptyWhenNoTargetOrNoIntake() {
        XCTAssertEqual(RingMath.fill(50, of: 0), 0)             // no target → never fabricate fill
        XCTAssertEqual(RingMath.fill(0, of: 180), 0)
        XCTAssertEqual(RingMath.fill(-20, of: 180), 0)         // guards against negative
    }

    func testIsOverOnlyPastTarget() {
        XCTAssertTrue(RingMath.isOver(181, target: 180))
        XCTAssertFalse(RingMath.isOver(180, target: 180))      // exactly at target isn't "over"
        XCTAssertFalse(RingMath.isOver(50, target: 180))
        XCTAssertFalse(RingMath.isOver(50, target: 0))         // no target → can't be over
    }
}

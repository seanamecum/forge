import XCTest
import SwiftUI
@testable import Forge

/// Guards the design-system invariants — the scales stay monotonic and the
/// tokens exist, so the "one product, one system" promise can't silently drift.
final class DesignTokensTests: XCTestCase {

    func testSpacingScaleStrictlyIncreases() {
        let scale = [Space.xxs, Space.xs, Space.sm, Space.md, Space.lg, Space.xl, Space.xxl, Space.xxxl]
        XCTAssertEqual(scale, scale.sorted())
        XCTAssertEqual(Set(scale).count, scale.count, "spacing steps must be distinct")
        XCTAssertGreaterThan(Space.tabInset, Space.xxxl)
    }

    func testRadiusScaleStrictlyIncreasesUpToPill() {
        let scale = [Radius.sm, Radius.md, Radius.lg, Radius.xl]
        XCTAssertEqual(scale, scale.sorted())
        XCTAssertEqual(Set(scale).count, scale.count)
        XCTAssertGreaterThan(Radius.pill, Radius.xl)     // capsule is the largest
    }

    func testIconSizeScaleStrictlyIncreases() {
        let scale = [IconSize.xs, IconSize.sm, IconSize.md, IconSize.lg, IconSize.xl, IconSize.hero]
        XCTAssertEqual(scale, scale.sorted())
        XCTAssertEqual(Set(scale).count, scale.count)
    }

    func testMotionDurationsArePositiveAndOrdered() {
        XCTAssertGreaterThan(Motion.Duration.press, 0)
        XCTAssertLessThan(Motion.Duration.press, Motion.Duration.base)
        XCTAssertLessThan(Motion.Duration.base, Motion.Duration.gentle)
        XCTAssertLessThan(Motion.Duration.gentle, Motion.Duration.reveal)
    }

    func testElevationDeepensWithLevel() {
        XCTAssertEqual(Elevation.flat.shadow.radius, 0)
        XCTAssertLessThan(Elevation.card.shadow.radius, Elevation.raised.shadow.radius)
        XCTAssertLessThan(Elevation.raised.shadow.radius, Elevation.modal.shadow.radius)
    }
}

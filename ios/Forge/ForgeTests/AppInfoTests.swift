import XCTest
@testable import Forge

/// The app version shown to users / sent in diagnostics is read from the bundle,
/// never hardcoded — so it can't drift from what shipped.
final class AppInfoTests: XCTestCase {
    func testVersionLabelsAreBundleDerivedAndWellFormed() {
        XCTAssertFalse(AppInfo.version.isEmpty)
        XCTAssertFalse(AppInfo.build.isEmpty)
        XCTAssertTrue(AppInfo.shortLabel.hasPrefix("Forge v"))
        XCTAssertTrue(AppInfo.versionWithBuild.contains("(") && AppInfo.versionWithBuild.contains(")"))
        // The short label carries the real version, not a frozen literal.
        XCTAssertTrue(AppInfo.shortLabel.contains(AppInfo.version))
    }
}

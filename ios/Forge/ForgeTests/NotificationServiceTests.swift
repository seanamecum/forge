import XCTest
@testable import Forge

final class NotificationServiceTests: XCTestCase {

    func testSeedsWithUnreadItems() {
        let service = NotificationService()
        XCTAssertFalse(service.items.isEmpty)
        XCTAssertGreaterThan(service.unreadCount, 0)
    }

    func testMarkAllReadClearsUnread() {
        let service = NotificationService()
        service.markAllRead()
        XCTAssertEqual(service.unreadCount, 0)
        XCTAssertTrue(service.items.allSatisfy(\.read))
    }

    func testDirectiveTimeDefaultsAreSane() {
        let service = NotificationService()
        XCTAssertTrue((0..<24).contains(service.directiveHour))
        XCTAssertTrue((0..<60).contains(service.directiveMinute))
    }

    // NOTE: scheduling/permission paths call the real UNUserNotificationCenter,
    // which hangs in a headless CI simulator (no UI to resolve the auth prompt).
    // Those are verified on-device, not in unit tests.
}

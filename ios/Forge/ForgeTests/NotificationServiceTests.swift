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

    func testPreviewRequiresPermissionAndDoesNotCrash() async {
        // No permission in the test host → sendPreview is a safe no-op (never throws/crashes).
        let service = NotificationService()
        await service.sendPreview()
        XCTAssertFalse(service.permissionGranted)
    }
}

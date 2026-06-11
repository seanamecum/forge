import Foundation
import Observation
import UserNotifications

@Observable
final class NotificationService {
    var items: [ForgeNotification] = MockData.notifications
    var permissionGranted = false

    var unreadCount: Int { items.filter { !$0.read }.count }

    func markAllRead() {
        items = items.map { item in
            var copy = item
            copy.read = true
            return copy
        }
    }

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            permissionGranted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            permissionGranted = false
        }
    }
}

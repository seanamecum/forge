import Foundation
import Observation
import UserNotifications

/// Local notifications — schedules the morning directive and smart nudges so the
/// daily loop reaches out instead of waiting. All on-device (UNUserNotificationCenter),
/// no backend. Preferences persist across launches.
@Observable
final class NotificationService {
    var items: [ForgeNotification] = MockData.notifications
    var permissionGranted = false

    // Preferences (persisted)
    var morningDirectiveOn: Bool {
        didSet { UserDefaults.standard.set(morningDirectiveOn, forKey: Keys.morning) }
    }
    var smartNudgesOn: Bool {
        didSet { UserDefaults.standard.set(smartNudgesOn, forKey: Keys.nudges) }
    }
    var directiveHour: Int {
        didSet { UserDefaults.standard.set(directiveHour, forKey: Keys.hour) }
    }
    var directiveMinute: Int {
        didSet { UserDefaults.standard.set(directiveMinute, forKey: Keys.minute) }
    }

    private enum Keys {
        static let morning = "forge.notif.morning"
        static let nudges = "forge.notif.nudges"
        static let hour = "forge.notif.hour"
        static let minute = "forge.notif.minute"
    }
    private enum ID {
        static let directive = "forge.morningDirective"
        static let protein = "forge.nudge.protein"
        static let pt = "forge.nudge.pt"
    }

    init() {
        let d = UserDefaults.standard
        morningDirectiveOn = d.object(forKey: Keys.morning) as? Bool ?? false
        smartNudgesOn = d.object(forKey: Keys.nudges) as? Bool ?? false
        directiveHour = d.object(forKey: Keys.hour) as? Int ?? 7
        directiveMinute = d.object(forKey: Keys.minute) as? Int ?? 0
    }

    var unreadCount: Int { items.filter { !$0.read }.count }

    func markAllRead() {
        items = items.map { var c = $0; c.read = true; return c }
    }

    // MARK: - Permission

    @MainActor
    @discardableResult
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            permissionGranted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            permissionGranted = false
        }
        return permissionGranted
    }

    @MainActor
    private func ensurePermission() async -> Bool {
        if permissionGranted { return true }
        return await requestPermission()
    }

    // MARK: - Morning directive (daily, repeating)

    @MainActor
    func setMorningDirective(_ on: Bool, headline: String, priority: String) async {
        morningDirectiveOn = on
        guard on else {
            cancel(ID.directive)
            return
        }
        guard await ensurePermission() else { morningDirectiveOn = false; return }
        let content = UNMutableNotificationContent()
        content.title = "Today's Directive"
        content.body = "\(headline) \(priority)"
        content.sound = .default
        var when = DateComponents()
        when.hour = directiveHour
        when.minute = directiveMinute
        let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
        await add(ID.directive, content: content, trigger: trigger)
    }

    /// Re-schedule after a time change while the toggle is on.
    @MainActor
    func rescheduleMorningDirective(headline: String, priority: String) async {
        guard morningDirectiveOn else { return }
        await setMorningDirective(true, headline: headline, priority: priority)
    }

    // MARK: - Smart nudges (daily, repeating)

    @MainActor
    func setSmartNudges(_ on: Bool, proteinRemaining: Int) async {
        smartNudgesOn = on
        guard on else {
            cancel(ID.protein); cancel(ID.pt)
            return
        }
        guard await ensurePermission() else { smartNudgesOn = false; return }

        let protein = UNMutableNotificationContent()
        protein.title = "Protein check"
        protein.body = proteinRemaining > 0
            ? "\(proteinRemaining) g to go — make dinner protein-first."
            : "On target. Lock it in with a casein bowl before bed."
        protein.sound = .default
        await add(ID.protein, content: protein, trigger: dailyAt(hour: 20, minute: 0))

        let pt = UNMutableNotificationContent()
        pt.title = "PT session due"
        pt.body = "Knee rehab — Spanish squats, TKEs, calf raises. ~12 min."
        pt.sound = .default
        await add(ID.pt, content: pt, trigger: dailyAt(hour: 17, minute: 0))
    }

    /// Fire a one-off in a few seconds so the user can see a live notification.
    @MainActor
    func sendPreview() async {
        guard await ensurePermission() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Forge"
        content.body = "Notifications are on. Your morning directive will land here."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 4, repeats: false)
        await add("forge.preview", content: content, trigger: trigger)
    }

    // MARK: - Helpers

    private func dailyAt(hour: Int, minute: Int) -> UNCalendarNotificationTrigger {
        var c = DateComponents(); c.hour = hour; c.minute = minute
        return UNCalendarNotificationTrigger(dateMatching: c, repeats: true)
    }

    private func add(_ id: String, content: UNMutableNotificationContent, trigger: UNNotificationTrigger) async {
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    private func cancel(_ id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}

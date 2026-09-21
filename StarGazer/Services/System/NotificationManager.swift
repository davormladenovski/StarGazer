import Foundation
import UserNotifications

/// The three switches exposed in Settings ▸ Notifications.
enum NotificationCategory: String, CaseIterable {
    case iss, moon, events

    /// Identifier prefix, so a category can be cancelled wholesale.
    var prefix: String {
        switch self {
        case .iss: return "iss-"
        case .moon: return "moon-"
        case .events: return "event-"
        }
    }
}

@Observable
final class NotificationManager {
    static let shared = NotificationManager()

    private var settings: SettingsManager { .shared }
    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func isEnabled(_ category: NotificationCategory) -> Bool {
        switch category {
        case .iss: return settings.notifyISS
        case .moon: return settings.notifyMoon
        case .events: return settings.notifyEvents
        }
    }

    /// Drops every still-pending notification belonging to one category.
    func cancelPending(_ category: NotificationCategory) async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(category.prefix) }
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Applies a Settings toggle. Returns `false` when the user has denied
    /// notification permission, so the UI can flip the switch back.
    @discardableResult
    func apply(_ category: NotificationCategory, enabled: Bool) async -> Bool {
        guard enabled else {
            await cancelPending(category)
            return true
        }
        guard await requestAuthorization() else { return false }
        if category == .moon { await scheduleMoonPhases() }
        return true
    }

    /// Re-syncs anything we schedule ourselves (rather than on user action).
    func refreshScheduledWork() async {
        if settings.notifyMoon {
            await scheduleMoonPhases()
        } else {
            await cancelPending(.moon)
        }
    }

    // MARK: - Moon phases

    /// Schedules the next full and new moon at 20:00 local on the day they fall.
    func scheduleMoonPhases() async {
        guard settings.notifyMoon else { return }
        guard await requestAuthorization() else { return }

        await cancelPending(.moon)   // avoid stacking duplicates across launches

        let phase = MoonPhaseCalculator.phase()
        await scheduleMoon(id: "moon-full", title: "Full moon tonight",
                           body: "The Moon is full \u{1F315} — a bright night for lunar detail.",
                           on: phase.nextFullMoon)
        await scheduleMoon(id: "moon-new", title: "New moon tonight",
                           body: "Darkest skies of the month \u{1F311} — ideal for faint objects.",
                           on: phase.nextNewMoon)
    }

    private func scheduleMoon(id: String, title: String, body: String, on date: Date) async {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month, .day], from: date)
        comps.hour = 20
        comps.minute = 0

        // Prefer 20:00 on the day itself; fall back to the exact phase time if
        // that evening has already passed.
        let fireDate = calendar.date(from: comps).flatMap { $0 > Date() ? $0 : (date > Date() ? date : nil) }
        guard let fireDate else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: "\(id)-\(Int(fireDate.timeIntervalSince1970))",
                                            content: content, trigger: trigger)
        try? await center.add(request)
    }

    func scheduleISSPass(at date: Date, direction: String) async {
        guard settings.notifyISS else { return }
        guard await requestAuthorization() else { return }
        let content = UNMutableNotificationContent()
        content.title = "ISS Pass"
        content.body = "Visible pass soon • \(direction)"
        content.sound = .default

        let leadTime = max(60, date.timeIntervalSinceNow - 5 * 60) // 5 min before
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: leadTime, repeats: false)
        let request = UNNotificationRequest(identifier: "iss-\(date.timeIntervalSince1970)", content: content, trigger: trigger)
        try? await center.add(request)
    }

    func scheduleEvent(name: String, at date: Date) async {
        guard settings.notifyEvents else { return }
        guard await requestAuthorization() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Astronomical event"
        content.body = name
        content.sound = .default
        let leadTime = max(60, date.timeIntervalSinceNow - 60 * 60)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: leadTime, repeats: false)
        let request = UNNotificationRequest(identifier: "event-\(name)-\(date.timeIntervalSince1970)", content: content, trigger: trigger)
        try? await center.add(request)
    }

    func scheduleObservationReminder(tomorrowNightFor title: String) async {
        guard await requestAuthorization() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Time to observe"
        content.body = "Don't forget: \(title)"
        content.sound = .default

        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date().addingTimeInterval(86400))
        comps.hour = 21
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: "obs-\(UUID().uuidString)", content: content, trigger: trigger)
        try? await center.add(request)
    }
}

import Foundation

@Observable
@MainActor
final class EventsViewModel {
    var displayedMonth: Date = Date()
    var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    var notifyToggles: [String: Bool] = [:]

    private let service = AstronomicalEventsService.shared

    var monthEvents: [AstronomicalEvent] {
        service.events(in: displayedMonth)
    }

    var datesWithEvents: [Date: [AstronomicalEventType]] {
        service.datesWithEvents(in: displayedMonth)
    }

    func eventsOn(_ day: Date) -> [AstronomicalEvent] {
        service.events(on: day)
    }

    func goToPreviousMonth() {
        if let new = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = new
        }
    }

    func goToNextMonth() {
        if let new = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = new
        }
    }

    func toggleNotify(for event: AstronomicalEvent) {
        let enabled = !(notifyToggles[event.id] ?? false)
        notifyToggles[event.id] = enabled
        if enabled {
            Task { await NotificationManager.shared.scheduleEvent(name: event.name, at: event.date) }
        }
    }
}

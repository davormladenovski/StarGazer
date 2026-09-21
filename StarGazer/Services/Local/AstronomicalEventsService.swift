import Foundation
import SwiftUI

enum AstronomicalEventType: String, Codable, CaseIterable, Identifiable {
    case fullMoon, newMoon, meteorShower, lunarEclipse, solarEclipse, conjunction, issPass, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fullMoon: return "Full moon"
        case .newMoon: return "New moon"
        case .meteorShower: return "Meteor shower"
        case .lunarEclipse: return "Lunar eclipse"
        case .solarEclipse: return "Solar eclipse"
        case .conjunction: return "Conjunction"
        case .issPass: return "ISS Pass"
        case .other: return "Other"
        }
    }

    var color: Color {
        switch self {
        case .fullMoon: return .white
        case .newMoon: return ColorTheme.textSecondary
        case .meteorShower: return .red
        case .lunarEclipse: return .purple
        case .solarEclipse: return .orange
        case .conjunction: return .cyan
        case .issPass: return .blue
        case .other: return ColorTheme.secondaryAccent
        }
    }

    var icon: String {
        switch self {
        case .fullMoon: return "moon.fill"
        case .newMoon: return "moon"
        case .meteorShower: return "sparkles"
        case .lunarEclipse: return "moon.haze.fill"
        case .solarEclipse: return "sun.haze.fill"
        case .conjunction: return "circle.dotted.and.circle"
        case .issPass: return "airplane"
        case .other: return "star.circle"
        }
    }
}

struct AstronomicalEvent: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let type: AstronomicalEventType
    let date: Date
    let description: String
    let directionHint: String

    enum CodingKeys: String, CodingKey {
        case id, name, type, date, description, directionHint
    }
}

@Observable
final class AstronomicalEventsService {
    static let shared = AstronomicalEventsService()

    private(set) var events: [AstronomicalEvent] = []

    private init() {
        load()
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "astronomical_events_2026", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            events = []
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        events = (try? decoder.decode([AstronomicalEvent].self, from: data)) ?? []
    }

    func events(in month: Date) -> [AstronomicalEvent] {
        let cal = Calendar.current
        return events.filter {
            cal.isDate($0.date, equalTo: month, toGranularity: .month)
        }.sorted { $0.date < $1.date }
    }

    func events(on day: Date) -> [AstronomicalEvent] {
        let cal = Calendar.current
        return events.filter { cal.isDate($0.date, inSameDayAs: day) }
    }

    func datesWithEvents(in month: Date) -> [Date: [AstronomicalEventType]] {
        let cal = Calendar.current
        var dict: [Date: [AstronomicalEventType]] = [:]
        for event in events where cal.isDate(event.date, equalTo: month, toGranularity: .month) {
            let day = cal.startOfDay(for: event.date)
            dict[day, default: []].append(event.type)
        }
        return dict
    }
}

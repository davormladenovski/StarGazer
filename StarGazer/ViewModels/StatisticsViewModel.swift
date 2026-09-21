import Foundation

struct MonthlyCount: Identifiable {
    let id = UUID()
    let month: Date
    let label: String
    let count: Int
}

struct LocationCount: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let latitude: Double
    let longitude: Double
}

@Observable
@MainActor
final class StatisticsViewModel {

    func monthlyCounts(from observations: [StarObservation], months: Int = 6) -> [MonthlyCount] {
        let cal = Calendar.current
        let now = Date()
        let f = DateFormatter(); f.dateFormat = "LLL"
        var result: [MonthlyCount] = []

        for offset in stride(from: months - 1, through: 0, by: -1) {
            guard let monthStart = cal.date(byAdding: .month, value: -offset, to: cal.startOfMonth(for: now)) else { continue }
            let count = observations.filter { cal.isDate($0.timestamp, equalTo: monthStart, toGranularity: .month) }.count
            result.append(MonthlyCount(month: monthStart, label: f.string(from: monthStart), count: count))
        }
        return result
    }

    func mostObservedType(_ observations: [StarObservation]) -> ObjectType? {
        Dictionary(grouping: observations, by: { $0.objectType })
            .max { $0.value.count < $1.value.count }?.key
    }

    func favoriteLocation(_ observations: [StarObservation]) -> LocationCount? {
        let groups = Dictionary(grouping: observations, by: { $0.locationName })
        let pairs = groups
            .filter { !$0.key.isEmpty }
            .map { (name, obs) -> LocationCount in
                let any = obs.first
                return LocationCount(
                    name: name,
                    count: obs.count,
                    latitude: any?.latitude ?? 0,
                    longitude: any?.longitude ?? 0
                )
            }
        return pairs.max { $0.count < $1.count }
    }

    func nightsObserved(_ observations: [StarObservation]) -> Int {
        let cal = Calendar.current
        return Set(observations.map { cal.startOfDay(for: $0.timestamp) }).count
    }

    func longestStreak(_ observations: [StarObservation]) -> Int {
        let cal = Calendar.current
        let days = Set(observations.map { cal.startOfDay(for: $0.timestamp) }).sorted()
        guard !days.isEmpty else { return 0 }
        var best = 1
        var current = 1
        for i in 1..<days.count {
            if let prev = cal.date(byAdding: .day, value: 1, to: days[i - 1]),
               cal.isDate(prev, inSameDayAs: days[i]) {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
    }

    func uniqueLocations(_ observations: [StarObservation]) -> [LocationCount] {
        let groups = Dictionary(grouping: observations, by: { $0.locationName })
        return groups.compactMap { name, obs -> LocationCount? in
            guard let any = obs.first, !name.isEmpty else { return nil }
            return LocationCount(name: name, count: obs.count, latitude: any.latitude, longitude: any.longitude)
        }
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}

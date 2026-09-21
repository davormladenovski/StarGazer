import Foundation

struct MoonPhase {
    let name: String
    let emoji: String
    let illuminationPercent: Double
    let ageDays: Double
    let nextFullMoon: Date
    let nextNewMoon: Date
}

/// Moon phase calculator using a known reference new moon and the synodic period.
/// Accuracy: ±0.5 day — sufficient for the dashboard / journal labelling.
enum MoonPhaseCalculator {

    /// Reference new moon: 2000-01-06 18:14 UTC (Jean Meeus reference).
    private static let referenceNewMoon: Date = {
        var c = DateComponents()
        c.year = 2000; c.month = 1; c.day = 6
        c.hour = 18; c.minute = 14
        c.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: c)!
    }()

    private static let synodicPeriod: Double = 29.530588853  // days

    static func phase(for date: Date = Date()) -> MoonPhase {
        let secondsSince = date.timeIntervalSince(referenceNewMoon)
        let daysSince = secondsSince / 86400.0
        var age = daysSince.truncatingRemainder(dividingBy: synodicPeriod)
        if age < 0 { age += synodicPeriod }

        let normalized = age / synodicPeriod  // 0 → 1
        // Illumination: 0 at new, 1 at full, 0 at new — use cosine.
        let illumination = (1 - cos(normalized * 2 * .pi)) / 2

        let name: String
        let emoji: String
        switch normalized {
        case 0..<0.03, 0.97...1.0:
            name = "New Moon"; emoji = "🌑"
        case 0.03..<0.22:
            name = "Wax. crescent"; emoji = "🌒"
        case 0.22..<0.28:
            name = "First quarter"; emoji = "🌓"
        case 0.28..<0.47:
            name = "Wax. gibbous"; emoji = "🌔"
        case 0.47..<0.53:
            name = "Full Moon"; emoji = "🌕"
        case 0.53..<0.72:
            name = "Wan. gibbous"; emoji = "🌖"
        case 0.72..<0.78:
            name = "Last quarter"; emoji = "🌗"
        default:
            name = "Wan. crescent"; emoji = "🌘"
        }

        let nextFull = nextOccurrence(of: 0.5, after: date)
        let nextNew = nextOccurrence(of: 0.0, after: date)

        return MoonPhase(
            name: name,
            emoji: emoji,
            illuminationPercent: illumination * 100,
            ageDays: age,
            nextFullMoon: nextFull,
            nextNewMoon: nextNew
        )
    }

    private static func nextOccurrence(of normalizedPhase: Double, after date: Date) -> Date {
        let secondsSince = date.timeIntervalSince(referenceNewMoon)
        let daysSince = secondsSince / 86400.0
        let currentNormalized = (daysSince.truncatingRemainder(dividingBy: synodicPeriod)) / synodicPeriod
        var delta = normalizedPhase - currentNormalized
        if delta <= 0 { delta += 1 }
        return date.addingTimeInterval(delta * synodicPeriod * 86400)
    }
}

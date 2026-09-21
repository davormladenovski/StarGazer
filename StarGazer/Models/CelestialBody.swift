import Foundation

enum CelestialBodyKind {
    case star
    case planet
    case moon
    case sun
    case deepSky
}

/// A point in the celestial sphere with optional horizontal coordinates
/// (filled in by `CelestialMath.toHorizontal`).
struct CelestialBody: Identifiable, Hashable {
    let id: String
    let name: String
    let kind: CelestialBodyKind
    let rightAscensionDeg: Double   // 0-360
    let declinationDeg: Double      // -90..+90
    let magnitude: Double           // visual magnitude
    let constellation: String?

    // Filled by CelestialMath:
    var azimuth: Double = 0
    var altitude: Double = 0

    var isAboveHorizon: Bool { altitude > 0 }

    var symbol: String {
        switch kind {
        case .star: return "star.fill"
        case .planet: return "circle.dotted"
        case .moon: return "moon.stars.fill"
        case .sun: return "sun.max.fill"
        case .deepSky: return "circle.hexagonpath.fill"
        }
    }
}

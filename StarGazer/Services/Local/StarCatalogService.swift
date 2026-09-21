import Foundation

@Observable
final class StarCatalogService {
    static let shared = StarCatalogService()

    private(set) var stars: [CelestialBody] = []

    private init() {
        loadFromBundle()
    }

    private func loadFromBundle() {
        guard let url = Bundle.main.url(forResource: "yale_bright_star_catalog", withExtension: "csv"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            stars = fallbackStars()
            return
        }
        var result: [CelestialBody] = []
        let lines = text.split(whereSeparator: \.isNewline)
        for (i, rawLine) in lines.enumerated() {
            if i == 0 { continue } // header
            let parts = rawLine.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            guard parts.count >= 6 else { continue }
            let hr = parts[0]
            let name = parts[1]
            guard let ra = Double(parts[2]),
                  let dec = Double(parts[3]),
                  let mag = Double(parts[4]) else { continue }
            let constellation = parts[5].trimmingCharacters(in: .whitespaces)
            result.append(CelestialBody(
                id: "HR\(hr)-\(name)",
                name: name,
                kind: .star,
                rightAscensionDeg: ra,
                declinationDeg: dec,
                magnitude: mag,
                constellation: constellation.isEmpty ? nil : constellation
            ))
        }
        stars = result.isEmpty ? fallbackStars() : result
    }

    private func fallbackStars() -> [CelestialBody] {
        [
            CelestialBody(id: "sirius", name: "Sirius", kind: .star, rightAscensionDeg: 101.29, declinationDeg: -16.72, magnitude: -1.46, constellation: "Canis Major"),
            CelestialBody(id: "vega", name: "Vega", kind: .star, rightAscensionDeg: 279.23, declinationDeg: 38.78, magnitude: 0.03, constellation: "Lyra"),
            CelestialBody(id: "polaris", name: "Polaris", kind: .star, rightAscensionDeg: 37.95, declinationDeg: 89.26, magnitude: 1.98, constellation: "Ursa Minor")
        ]
    }

    /// Compute horizontal coordinates for every star for the given observer/time
    /// and return only those above the horizon, sorted by brightness.
    func visibleStars(latitude: Double, longitude: Double, date: Date = Date(), maxMagnitude: Double = 5.0) -> [CelestialBody] {
        var result: [CelestialBody] = []
        for star in stars where star.magnitude <= maxMagnitude {
            let h = CelestialMath.toHorizontal(
                rightAscensionDeg: star.rightAscensionDeg,
                declinationDeg: star.declinationDeg,
                latitudeDeg: latitude,
                longitudeDeg: longitude,
                date: date
            )
            if h.altitude > 0 {
                var s = star
                s.azimuth = h.azimuth
                s.altitude = h.altitude
                result.append(s)
            }
        }
        return result.sorted { $0.magnitude < $1.magnitude }
    }

    /// Stars within `fieldOfView` degrees of the given pointing direction.
    func nearestStars(
        azimuth: Double,
        altitude: Double,
        latitude: Double,
        longitude: Double,
        date: Date = Date(),
        fieldOfView: Double = 15
    ) -> [CelestialBody] {
        visibleStars(latitude: latitude, longitude: longitude, date: date)
            .filter { CelestialMath.angularSeparation(az1: $0.azimuth, alt1: $0.altitude, az2: azimuth, alt2: altitude) <= fieldOfView }
            .sorted { $0.magnitude < $1.magnitude }
    }
}

import Foundation
import CoreLocation

@Observable
@MainActor
final class SkyCompassViewModel {
    var visibleBodies: [CelestialBody] = []   // everything above horizon
    var nearestBodies: [CelestialBody] = []   // within field of view of pointing direction
    var locationName: String = ""
    var error: String?

    private var refreshTask: Task<Void, Never>?
    private var currentLatitude: Double = 0
    private var currentLongitude: Double = 0
    private var hasLocation = false

    let fieldOfView: Double = 25  // degrees

    func start() {
        cancel()
        refreshTask = Task { [weak self] in
            await self?.loadLocation()
            while !Task.isCancelled {
                await self?.computeBodies()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    func cancel() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func updatePointing(azimuth: Double, altitude: Double) {
        guard hasLocation else { return }
        let stars = StarCatalogService.shared.nearestStars(
            azimuth: azimuth,
            altitude: altitude,
            latitude: currentLatitude,
            longitude: currentLongitude,
            fieldOfView: fieldOfView
        )
        let planetsAndMoon = visibleBodies.filter { $0.kind != .star }
            .filter { CelestialMath.angularSeparation(az1: $0.azimuth, alt1: $0.altitude, az2: azimuth, alt2: altitude) <= fieldOfView }

        let combined = (planetsAndMoon + stars)
            .sorted { $0.magnitude < $1.magnitude }
        nearestBodies = Array(combined.prefix(3))
    }

    private func loadLocation() async {
        do {
            let loc = try await LocationService.shared.currentLocationOnce()
            currentLatitude = loc.coordinate.latitude
            currentLongitude = loc.coordinate.longitude
            hasLocation = true
            locationName = await LocationService.shared.reverseGeocode(loc)
        } catch {
            // Fall back to a default location so the compass still produces overlay data
            currentLatitude = 41.99
            currentLongitude = 21.43
            locationName = "Skopje (default)"
            hasLocation = true
            self.error = "Using default location."
        }
    }

    private func computeBodies() async {
        guard hasLocation else { return }
        let now = Date()
        var bodies: [CelestialBody] = []

        bodies.append(contentsOf: StarCatalogService.shared.visibleStars(
            latitude: currentLatitude,
            longitude: currentLongitude,
            date: now,
            maxMagnitude: 4.5
        ))
        bodies.append(contentsOf: PlanetCalculator.visiblePlanets(
            latitude: currentLatitude,
            longitude: currentLongitude,
            date: now
        ))

        // Sun
        let (sunRA, sunDec) = sunEquatorial(date: now)
        let sh = CelestialMath.toHorizontal(
            rightAscensionDeg: sunRA, declinationDeg: sunDec,
            latitudeDeg: currentLatitude, longitudeDeg: currentLongitude, date: now
        )
        if sh.altitude > -2 {
            var sunBody = CelestialBody(
                id: "sun",
                name: "Sun",
                kind: .sun,
                rightAscensionDeg: sunRA,
                declinationDeg: sunDec,
                magnitude: -26,
                constellation: nil
            )
            sunBody.azimuth = sh.azimuth
            sunBody.altitude = sh.altitude
            bodies.append(sunBody)
        }

        // Moon
        let moon = MoonPhaseCalculator.phase(for: now)
        let moonRA = approximateMoonRA(date: now)
        let moonDec = approximateMoonDec(date: now)
        let mh = CelestialMath.toHorizontal(
            rightAscensionDeg: moonRA, declinationDeg: moonDec,
            latitudeDeg: currentLatitude, longitudeDeg: currentLongitude, date: now
        )
        if mh.altitude > 0 {
            var moonBody = CelestialBody(
                id: "moon",
                name: "Moon \(moon.emoji)",
                kind: .moon,
                rightAscensionDeg: moonRA,
                declinationDeg: moonDec,
                magnitude: -10,
                constellation: nil
            )
            moonBody.azimuth = mh.azimuth
            moonBody.altitude = mh.altitude
            bodies.append(moonBody)
        }

        visibleBodies = bodies
    }

    // Schlyter low-precision solar position. Accuracy ~0.5°.
    private func sunEquatorial(date: Date) -> (ra: Double, dec: Double) {
        let d = date.julianDay - 2451545.0
        let deg = Double.pi / 180

        let w = (282.9404 + 4.70935e-5 * d) * deg
        let e = 0.016709 - 1.151e-9 * d
        let M = ((356.0470 + 0.9856002585 * d).truncatingRemainder(dividingBy: 360)) * deg

        var E = M + e * sin(M) * (1 + e * cos(M))
        for _ in 0..<5 {
            E -= (E - e * sin(E) - M) / (1 - e * cos(E))
        }

        let xv = cos(E) - e
        let yv = sqrt(1 - e * e) * sin(E)
        let v = atan2(yv, xv)
        let r = sqrt(xv * xv + yv * yv)
        let lon = v + w

        let xs = r * cos(lon)
        let ys = r * sin(lon)

        let ecl = (23.4393 - 3.563e-7 * d) * deg
        let xe = xs
        let ye = ys * cos(ecl)
        let ze = ys * sin(ecl)

        var raRad = atan2(ye, xe)
        let decRad = atan2(ze, sqrt(xe * xe + ye * ye))
        if raRad < 0 { raRad += 2 * .pi }
        return (raRad / deg, decRad / deg)
    }

    // Schlyter low-precision lunar position. Accuracy ~1° — plenty for visual overlay.
    private func approximateMoonRA(date: Date) -> Double {
        moonEquatorial(date: date).ra
    }
    private func approximateMoonDec(date: Date) -> Double {
        moonEquatorial(date: date).dec
    }

    private func moonEquatorial(date: Date) -> (ra: Double, dec: Double) {
        let d = date.julianDay - 2451545.0
        let deg = Double.pi / 180

        // Moon orbital elements (Schlyter, J2000).
        let N = (125.1228 - 0.0529538083 * d).truncatingRemainder(dividingBy: 360) * deg
        let i =   5.1454 * deg
        let w = (318.0634 + 0.1643573223 * d).truncatingRemainder(dividingBy: 360) * deg
        let a =  60.2666
        let e =   0.054900
        let M = (115.3654 + 13.0649929509 * d).truncatingRemainder(dividingBy: 360) * deg

        // Solve Kepler.
        var E = M + e * sin(M) * (1 + e * cos(M))
        for _ in 0..<5 {
            E -= (E - e * sin(E) - M) / (1 - e * cos(E))
        }

        let xv = a * (cos(E) - e)
        let yv = a * sqrt(1 - e * e) * sin(E)
        let v = atan2(yv, xv)
        let r = sqrt(xv * xv + yv * yv)

        // Position in ecliptic coordinates.
        let xh = r * (cos(N) * cos(v + w) - sin(N) * sin(v + w) * cos(i))
        let yh = r * (sin(N) * cos(v + w) + cos(N) * sin(v + w) * cos(i))
        let zh = r * sin(v + w) * sin(i)

        // Convert to equatorial (obliquity ε).
        let ecl = (23.4393 - 3.563e-7 * d) * deg
        let xe = xh
        let ye = yh * cos(ecl) - zh * sin(ecl)
        let ze = yh * sin(ecl) + zh * cos(ecl)

        var raRad = atan2(ye, xe)
        let decRad = atan2(ze, sqrt(xe * xe + ye * ye))
        if raRad < 0 { raRad += 2 * .pi }

        return (raRad / deg, decRad / deg)
    }
}

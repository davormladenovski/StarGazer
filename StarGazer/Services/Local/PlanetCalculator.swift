import Foundation

/// Simplified planet position calculator using Keplerian orbital elements
/// (referenced to J2000.0). Accuracy ~1° — sufficient for the seminar.
///
/// Based on Paul Schlyter's "How to compute planetary positions" approximation.
enum PlanetCalculator {

    struct Elements {
        let N: Double  // longitude of ascending node
        let i: Double  // inclination
        let w: Double  // argument of perihelion
        let a: Double  // mean distance (AU)
        let e: Double  // eccentricity
        let M: Double  // mean anomaly
    }

    /// Days since J2000 (2000-01-01 12:00 UTC).
    private static func daysSinceEpoch(_ date: Date) -> Double {
        date.julianDay - 2451545.0
    }

    static func planets(for date: Date = Date()) -> [CelestialBody] {
        let d = daysSinceEpoch(date)
        var bodies: [CelestialBody] = []

        // Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus, Neptune
        let names = ["Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"]
        let macedonian = ["Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"]
        let elements: [Elements] = [
            // Mercury
            Elements(N: 48.3313 + 3.24587e-5 * d, i: 7.0047 + 5.00e-8 * d, w: 29.1241 + 1.01444e-5 * d, a: 0.387098, e: 0.205635 + 5.59e-10 * d, M: 168.6562 + 4.0923344368 * d),
            // Venus
            Elements(N: 76.6799 + 2.46590e-5 * d, i: 3.3946 + 2.75e-8 * d, w: 54.8910 + 1.38374e-5 * d, a: 0.723330, e: 0.006773 - 1.302e-9 * d, M: 48.0052 + 1.6021302244 * d),
            // Mars
            Elements(N: 49.5574 + 2.11081e-5 * d, i: 1.8497 - 1.78e-8 * d, w: 286.5016 + 2.92961e-5 * d, a: 1.523688, e: 0.093405 + 2.516e-9 * d, M: 18.6021 + 0.5240207766 * d),
            // Jupiter
            Elements(N: 100.4542 + 2.76854e-5 * d, i: 1.3030 - 1.557e-7 * d, w: 273.8777 + 1.64505e-5 * d, a: 5.20256, e: 0.048498 + 4.469e-9 * d, M: 19.8950 + 0.0830853001 * d),
            // Saturn
            Elements(N: 113.6634 + 2.38980e-5 * d, i: 2.4886 - 1.081e-7 * d, w: 339.3939 + 2.97661e-5 * d, a: 9.55475, e: 0.055546 - 9.499e-9 * d, M: 316.9670 + 0.0334442282 * d),
            // Uranus
            Elements(N: 74.0005 + 1.3978e-5 * d, i: 0.7733 + 1.9e-8 * d, w: 96.6612 + 3.0565e-5 * d, a: 19.18171 - 1.55e-8 * d, e: 0.047318 + 7.45e-9 * d, M: 142.5905 + 0.011725806 * d),
            // Neptune
            Elements(N: 131.7806 + 3.0173e-5 * d, i: 1.7700 - 2.55e-7 * d, w: 272.8461 - 6.027e-6 * d, a: 30.05826 + 3.313e-8 * d, e: 0.008606 + 2.15e-9 * d, M: 260.2471 + 0.005995147 * d)
        ]

        // Earth's elements (Sun's reverse), used for converting heliocentric → geocentric.
        let earth = Elements(N: 0, i: 0, w: 282.9404 + 4.70935e-5 * d, a: 1.0, e: 0.016709 - 1.151e-9 * d, M: 356.0470 + 0.9856002585 * d)

        let (xEarth, yEarth, _) = heliocentric(earth, isEarth: true)

        for (idx, e) in elements.enumerated() {
            let (xp, yp, zp) = heliocentric(e, isEarth: false)
            // Geocentric ecliptic
            let xg = xp - xEarth
            let yg = yp - yEarth
            let zg = zp

            // Convert ecliptic → equatorial (using obliquity for J2000)
            let oblique = 23.4393.toRadians()
            let xe = xg
            let ye = yg * cos(oblique) - zg * sin(oblique)
            let ze = yg * sin(oblique) + zg * cos(oblique)

            var ra = atan2(ye, xe).toDegrees()
            if ra < 0 { ra += 360 }
            let dec = atan2(ze, sqrt(xe * xe + ye * ye)).toDegrees()

            bodies.append(CelestialBody(
                id: "planet-\(names[idx])",
                name: macedonian[idx],
                kind: .planet,
                rightAscensionDeg: ra,
                declinationDeg: dec,
                magnitude: planetMagnitude(name: names[idx]),
                constellation: nil
            ))
        }
        return bodies
    }

    /// Returns visible planets above horizon, with az/alt filled.
    static func visiblePlanets(latitude: Double, longitude: Double, date: Date = Date()) -> [CelestialBody] {
        planets(for: date).compactMap { body in
            let h = CelestialMath.toHorizontal(
                rightAscensionDeg: body.rightAscensionDeg,
                declinationDeg: body.declinationDeg,
                latitudeDeg: latitude,
                longitudeDeg: longitude,
                date: date
            )
            guard h.altitude > 0 else { return nil }
            var b = body
            b.azimuth = h.azimuth
            b.altitude = h.altitude
            return b
        }
    }

    // MARK: - private helpers

    private static func heliocentric(_ e: Elements, isEarth: Bool) -> (Double, Double, Double) {
        let M = e.M.truncatingRemainder(dividingBy: 360).toRadians()
        let ecc = e.e

        // Solve Kepler's equation iteratively
        var E = M + ecc * sin(M) * (1 + ecc * cos(M))
        for _ in 0..<5 {
            E = E - (E - ecc * sin(E) - M) / (1 - ecc * cos(E))
        }

        let xv = e.a * (cos(E) - ecc)
        let yv = e.a * sqrt(1 - ecc * ecc) * sin(E)

        let v = atan2(yv, xv)
        let r = sqrt(xv * xv + yv * yv)

        if isEarth {
            // For Earth (Sun-relative), the "planet" is the Sun seen from Earth;
            // simplify by computing position in the ecliptic plane directly.
            let lonSun = (v + e.w.toRadians())
            return (r * cos(lonSun), r * sin(lonSun), 0)
        }

        let N = e.N.toRadians()
        let i = e.i.toRadians()
        let w = e.w.toRadians()

        let xh = r * (cos(N) * cos(v + w) - sin(N) * sin(v + w) * cos(i))
        let yh = r * (sin(N) * cos(v + w) + cos(N) * sin(v + w) * cos(i))
        let zh = r * (sin(v + w) * sin(i))
        return (xh, yh, zh)
    }

    private static func planetMagnitude(name: String) -> Double {
        switch name {
        case "Mercury": return -0.4
        case "Venus": return -4.0
        case "Mars": return 0.7
        case "Jupiter": return -2.0
        case "Saturn": return 0.5
        case "Uranus": return 5.5
        case "Neptune": return 7.8
        default: return 6.0
        }
    }
}

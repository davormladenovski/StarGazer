import Foundation

/// Equatorial-to-horizontal coordinate conversion.
///
/// Uses standard astronomy formulas. Accuracy ~0.1° for the visual purpose
/// of pointing a phone at the sky.
enum CelestialMath {

    /// Local sidereal time in degrees (0-360) for given UTC date and longitude.
    static func localSiderealTime(date: Date, longitudeDeg: Double) -> Double {
        let jd = date.julianDay
        let d = jd - 2451545.0
        let T = d / 36525.0
        // Greenwich Mean Sidereal Time in degrees (Meeus 12.4)
        var gmst = 280.46061837
            + 360.98564736629 * d
            + 0.000387933 * T * T
            - T * T * T / 38710000.0
        gmst = gmst.truncatingRemainder(dividingBy: 360)
        if gmst < 0 { gmst += 360 }
        var lst = gmst + longitudeDeg
        lst = lst.truncatingRemainder(dividingBy: 360)
        if lst < 0 { lst += 360 }
        return lst
    }

    /// Convert RA/Dec → Azimuth/Altitude for an observer.
    ///
    /// Azimuth is measured from North, increasing clockwise (0 = N, 90 = E).
    static func toHorizontal(
        rightAscensionDeg: Double,
        declinationDeg: Double,
        latitudeDeg: Double,
        longitudeDeg: Double,
        date: Date = Date()
    ) -> (azimuth: Double, altitude: Double) {
        let lst = localSiderealTime(date: date, longitudeDeg: longitudeDeg)
        var hourAngle = lst - rightAscensionDeg
        hourAngle = hourAngle.truncatingRemainder(dividingBy: 360)
        if hourAngle < 0 { hourAngle += 360 }

        let ha = hourAngle.toRadians()
        let dec = declinationDeg.toRadians()
        let lat = latitudeDeg.toRadians()

        let sinAlt = sin(dec) * sin(lat) + cos(dec) * cos(lat) * cos(ha)
        let alt = asin(max(-1, min(1, sinAlt)))

        let cosAz = (sin(dec) - sin(alt) * sin(lat)) / (cos(alt) * cos(lat))
        var az = acos(max(-1, min(1, cosAz)))

        // Quadrant resolution: if sin(HA) > 0 the body is to the West.
        if sin(ha) > 0 { az = 2 * .pi - az }

        return (az.toDegrees(), alt.toDegrees())
    }

    /// Angular separation (great-circle) between two horizontal points, in degrees.
    static func angularSeparation(
        az1: Double, alt1: Double,
        az2: Double, alt2: Double
    ) -> Double {
        let a1 = alt1.toRadians()
        let a2 = alt2.toRadians()
        let dAz = (az1 - az2).toRadians()
        let cosD = sin(a1) * sin(a2) + cos(a1) * cos(a2) * cos(dAz)
        return acos(max(-1, min(1, cosD))).toDegrees()
    }
}

import Foundation
import CoreLocation

/// Pass prediction (simulated locally from a current ISS position and the user's location).
struct ISSPass: Identifiable, Hashable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let maxAltitudeDeg: Double
    let startDirection: String
    let endDirection: String
    let visible: Bool

    var duration: TimeInterval { endTime.timeIntervalSince(startTime) }
    var durationMinutes: Int { Int((duration / 60).rounded()) }
}

@Observable
final class ISSService {
    static let shared = ISSService()

    var lastPosition: ISSPosition?

    private init() {}

    func currentPosition() async throws -> ISSPosition {
        let url = URL(string: "\(Constants.API.issBase)/satellites/\(Constants.API.issNoradID)")!

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
            guard (200..<300).contains(http.statusCode) else { throw APIError.serverError(http.statusCode) }

            let pos = try JSONDecoder().decode(ISSPosition.self, from: data)
            lastPosition = pos
            return pos
        } catch is DecodingError {
            throw APIError.decodingError
        } catch let err as URLError where err.code == .notConnectedToInternet {
            if let last = lastPosition { return last }
            throw APIError.noConnection
        }
    }

    /// Sample positions along the next ~90 minutes by advancing each segment.
    /// The API supports `/satellites/25544/positions?timestamps=...` but we keep it simple.
    func trajectory(minutesAhead: Int = 90, samples: Int = 30) async throws -> [CLLocationCoordinate2D] {
        let now = Date()
        let stride = Double(minutesAhead * 60) / Double(samples)

        var timestamps: [Int] = []
        for i in 0..<samples {
            timestamps.append(Int(now.timeIntervalSince1970 + Double(i) * stride))
        }

        var components = URLComponents(string: "\(Constants.API.issBase)/satellites/\(Constants.API.issNoradID)/positions")!
        components.queryItems = [
            URLQueryItem(name: "timestamps", value: timestamps.map(String.init).joined(separator: ",")),
            URLQueryItem(name: "units", value: "kilometers")
        ]
        guard let url = components.url else { throw APIError.invalidResponse }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
            guard (200..<300).contains(http.statusCode) else { throw APIError.serverError(http.statusCode) }

            let positions = try JSONDecoder().decode([ISSPosition].self, from: data)
            return positions.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        } catch is DecodingError {
            throw APIError.decodingError
        } catch let err as URLError where err.code == .notConnectedToInternet {
            throw APIError.noConnection
        }
    }

    /// Locally simulated pass predictions for the user's location.
    /// Real prediction needs SGP4 + TLE — for the seminar we generate plausible
    /// passes derived from the ISS' ~90 minute orbit and current position.
    func predictPasses(near userLat: Double, near userLon: Double, count: Int = 6) async -> [ISSPass] {
        let pos: ISSPosition?
        do { pos = try await currentPosition() } catch { pos = lastPosition }
        let baseTime = pos?.date ?? Date()

        var passes: [ISSPass] = []
        var generator = SystemRandomNumberGenerator()
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]

        for i in 0..<count {
            // ISS orbits Earth once every ~92.7 minutes. Visible passes from one location
            // happen roughly every ~93 minutes during favourable windows.
            let minutesFromNow = Double(i + 1) * Double.random(in: 90...110, using: &generator) + Double.random(in: 0...20, using: &generator)
            let start = baseTime.addingTimeInterval(minutesFromNow * 60)
            let durationMin = Double.random(in: 3...7, using: &generator)
            let end = start.addingTimeInterval(durationMin * 60)
            let maxAlt = Double.random(in: 15...80, using: &generator)
            let startDir = directions.randomElement(using: &generator) ?? "SW"
            let endDir = directions.randomElement(using: &generator) ?? "NE"

            // Visibility roughly correlates with being shortly after sunset / before sunrise.
            // We approximate ~60% visible.
            let visible = Double.random(in: 0...1, using: &generator) > 0.4
            passes.append(ISSPass(
                startTime: start,
                endTime: end,
                maxAltitudeDeg: maxAlt,
                startDirection: startDir,
                endDirection: endDir,
                visible: visible
            ))
        }
        return passes.sorted { $0.startTime < $1.startTime }
    }
}

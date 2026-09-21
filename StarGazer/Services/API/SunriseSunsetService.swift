import Foundation

@Observable
final class SunriseSunsetService {
    static let shared = SunriseSunsetService()

    private var cache: [String: (data: SunData, fetchedAt: Date)] = [:]
    private let iso = ISO8601DateFormatter()

    private init() {}

    func sunData(latitude: Double, longitude: Double, date: Date = Date()) async throws -> SunData {
        let key = cacheKey(latitude, longitude, date: date)
        if let cached = cache[key],
           Date().timeIntervalSince(cached.fetchedAt) < Constants.Refresh.sunCacheSeconds {
            return cached.data
        }

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        dayFormatter.timeZone = TimeZone(identifier: "UTC")

        var components = URLComponents(string: Constants.API.sunriseSunset)!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lng", value: String(longitude)),
            URLQueryItem(name: "date", value: dayFormatter.string(from: date)),
            URLQueryItem(name: "formatted", value: "0")
        ]
        guard let url = components.url else { throw APIError.invalidResponse }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
            guard (200..<300).contains(http.statusCode) else { throw APIError.serverError(http.statusCode) }

            let decoded = try JSONDecoder().decode(SunriseSunsetResponse.self, from: data)
            guard let sunrise = iso.date(from: decoded.results.sunrise),
                  let sunset = iso.date(from: decoded.results.sunset),
                  let tBegin = iso.date(from: decoded.results.civil_twilight_begin),
                  let tEnd = iso.date(from: decoded.results.civil_twilight_end) else {
                throw APIError.decodingError
            }
            let sd = SunData(
                sunrise: sunrise,
                sunset: sunset,
                twilightBegin: tBegin,
                twilightEnd: tEnd,
                dayLengthSeconds: decoded.results.day_length
            )
            cache[key] = (sd, Date())
            return sd
        } catch is DecodingError {
            throw APIError.decodingError
        } catch let err as URLError where err.code == .notConnectedToInternet {
            if let cached = cache[key] { return cached.data }
            throw APIError.noConnection
        }
    }

    private func cacheKey(_ lat: Double, _ lon: Double, date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return "\(lat.rounded(to: 2))_\(lon.rounded(to: 2))_\(f.string(from: date))"
    }
}

import Foundation

@Observable
final class WeatherService {
    static let shared = WeatherService()

    private var cache: [String: (snapshot: WeatherSnapshot, fetchedAt: Date)] = [:]

    private init() {}

    func currentWeather(latitude: Double, longitude: Double) async throws -> WeatherSnapshot {
        let key = cacheKey(latitude, longitude)
        if let cached = cache[key],
           Date().timeIntervalSince(cached.fetchedAt) < Constants.Refresh.weatherCacheSeconds {
            return cached.snapshot
        }

        var components = URLComponents(string: Constants.API.openMeteo)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,cloud_cover,visibility,weather_code")
        ]
        guard let url = components.url else { throw APIError.invalidResponse }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
            guard (200..<300).contains(http.statusCode) else { throw APIError.serverError(http.statusCode) }

            let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            let snapshot = WeatherSnapshot(
                temperatureC: decoded.current.temperature_2m,
                cloudCoverPercent: decoded.current.cloud_cover,
                visibilityMeters: decoded.current.visibility,
                weatherCode: decoded.current.weather_code,
                timestamp: Date()
            )
            cache[key] = (snapshot, Date())
            return snapshot
        } catch is DecodingError {
            throw APIError.decodingError
        } catch let err as URLError where err.code == .notConnectedToInternet {
            if let cached = cache[key] { return cached.snapshot }
            throw APIError.noConnection
        }
    }

    private func cacheKey(_ lat: Double, _ lon: Double) -> String {
        "\(lat.rounded(to: 2))_\(lon.rounded(to: 2))"
    }
}

import Foundation

enum APIError: LocalizedError {
    case noConnection
    case invalidResponse
    case decodingError
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .noConnection: return "No internet connection."
        case .invalidResponse: return "Invalid response from server."
        case .decodingError: return "Failed to decode data."
        case .serverError(let code): return "Server error (\(code))."
        }
    }
}

// MARK: - ISS

struct ISSPosition: Codable, Equatable {
    let name: String
    let id: Int
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let velocity: Double
    let visibility: String
    let timestamp: TimeInterval
    let units: String?

    var date: Date { Date(timeIntervalSince1970: timestamp) }
}

// MARK: - Sunrise-Sunset

struct SunriseSunsetResponse: Codable {
    struct Results: Codable {
        let sunrise: String
        let sunset: String
        let solar_noon: String
        let day_length: Int
        let civil_twilight_begin: String
        let civil_twilight_end: String
    }
    let results: Results
    let status: String
}

struct SunData {
    let sunrise: Date
    let sunset: Date
    let twilightBegin: Date
    let twilightEnd: Date
    let dayLengthSeconds: Int
}

// MARK: - Open-Meteo

struct OpenMeteoResponse: Codable {
    struct Current: Codable {
        let time: String
        let temperature_2m: Double
        let cloud_cover: Double
        let visibility: Double?
        let weather_code: Int
    }
    let current: Current
}

struct WeatherSnapshot {
    let temperatureC: Double
    let cloudCoverPercent: Double
    let visibilityMeters: Double?
    let weatherCode: Int
    let timestamp: Date

    var conditionLabel: String { WeatherCode.label(for: weatherCode) }
    var conditionIcon: String { WeatherCode.icon(for: weatherCode) }

    /// Heuristic: low cloud cover and reasonable visibility makes for good observing.
    var isGoodForObserving: Bool {
        cloudCoverPercent < 30 && (visibilityMeters ?? 10_000) > 5_000
    }
}

enum WeatherCode {
    static func label(for code: Int) -> String {
        switch code {
        case 0: return "Clear"
        case 1, 2: return "Partly cloudy"
        case 3: return "Cloudy"
        case 45, 48: return "Fog"
        case 51, 53, 55, 56, 57: return "Drizzle"
        case 61, 63, 65, 66, 67: return "Rain"
        case 71, 73, 75, 77: return "Snow"
        case 80, 81, 82: return "Showers"
        case 95, 96, 99: return "Thunderstorms"
        default: return "Unknown"
        }
    }
    static func icon(for code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1, 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55, 56, 57: return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67: return "cloud.rain.fill"
        case 71, 73, 75, 77: return "cloud.snow.fill"
        case 80, 81, 82: return "cloud.heavyrain.fill"
        case 95, 96, 99: return "cloud.bolt.fill"
        default: return "questionmark.circle"
        }
    }
}

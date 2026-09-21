import Foundation
import SwiftUI
import MapKit

enum AppTheme: String, CaseIterable, Identifiable {
    case dark, light, auto
    var id: String { rawValue }
    var label: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Bright"
        case .auto: return "Automatic"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .auto: return nil
        }
    }
}

enum Units: String, CaseIterable, Identifiable {
    case metric, imperial
    var id: String { rawValue }
    var label: String { self == .metric ? "Metric" : "Imperial" }
}

enum MapStyleOption: String, CaseIterable, Identifiable {
    case standard, hybrid, satellite
    var id: String { rawValue }
    var label: String {
        switch self {
        case .standard: return "Standard"
        case .hybrid: return "Hybrid"
        case .satellite: return "Satellite"
        }
    }
}

@Observable
final class SettingsManager {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    var username: String {
        didSet { defaults.set(username, forKey: Constants.Storage.username) }
    }
    var faceIDEnabled: Bool {
        didSet { defaults.set(faceIDEnabled, forKey: Constants.Storage.faceIDEnabled) }
    }
    var notifyISS: Bool {
        didSet { defaults.set(notifyISS, forKey: Constants.Storage.notifyISS) }
    }
    var notifyMoon: Bool {
        didSet { defaults.set(notifyMoon, forKey: Constants.Storage.notifyMoon) }
    }
    var notifyEvents: Bool {
        didSet { defaults.set(notifyEvents, forKey: Constants.Storage.notifyEvents) }
    }
    var units: Units {
        didSet { defaults.set(units.rawValue, forKey: Constants.Storage.units) }
    }
    var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Constants.Storage.theme) }
    }
    var mapStyle: MapStyleOption {
        didSet { defaults.set(mapStyle.rawValue, forKey: Constants.Storage.mapStyle) }
    }

    private init() {
        self.username = defaults.string(forKey: Constants.Storage.username) ?? "Stargazer"
        self.faceIDEnabled = defaults.bool(forKey: Constants.Storage.faceIDEnabled)
        self.notifyISS = defaults.object(forKey: Constants.Storage.notifyISS) as? Bool ?? true
        self.notifyMoon = defaults.object(forKey: Constants.Storage.notifyMoon) as? Bool ?? true
        self.notifyEvents = defaults.object(forKey: Constants.Storage.notifyEvents) as? Bool ?? true
        self.units = Units(rawValue: defaults.string(forKey: Constants.Storage.units) ?? "metric") ?? .metric
        self.theme = AppTheme(rawValue: defaults.string(forKey: Constants.Storage.theme) ?? "dark") ?? .dark
        self.mapStyle = MapStyleOption(rawValue: defaults.string(forKey: Constants.Storage.mapStyle) ?? "hybrid") ?? .hybrid
    }
}

// MARK: - Unit formatting

extension Units {
    private static let milesPerKilometre = 0.621371

    /// "421 km" / "262 mi"
    func distance(kilometres: Double, fractionDigits: Int = 0) -> String {
        switch self {
        case .metric: return "\(number(kilometres, fractionDigits)) km"
        case .imperial: return "\(number(kilometres * Self.milesPerKilometre, fractionDigits)) mi"
        }
    }

    /// "27594 km/h" / "17146 mph"
    func speed(kilometresPerHour: Double, fractionDigits: Int = 0) -> String {
        switch self {
        case .metric: return "\(number(kilometresPerHour, fractionDigits)) km/h"
        case .imperial: return "\(number(kilometresPerHour * Self.milesPerKilometre, fractionDigits)) mph"
        }
    }

    /// "22°C" / "72°F"
    func temperature(celsius: Double, fractionDigits: Int = 0) -> String {
        switch self {
        case .metric: return "\(number(celsius, fractionDigits))°C"
        case .imperial: return "\(number(celsius * 9 / 5 + 32, fractionDigits))°F"
        }
    }

    private func number(_ value: Double, _ digits: Int) -> String {
        String(format: "%.\(digits)f", value)
    }
}

// MARK: - Map style

extension MapStyleOption {
    /// `elevation` stays flat by default; the full-screen ISS map opts into 3-D.
    func mapStyle(elevation: MapStyle.Elevation = .automatic) -> MapStyle {
        switch self {
        case .standard: return .standard(elevation: elevation)
        case .hybrid: return .hybrid(elevation: elevation)
        case .satellite: return .imagery(elevation: elevation)
        }
    }
}

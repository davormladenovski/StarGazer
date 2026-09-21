import Foundation
import CoreLocation

@Observable
@MainActor
final class LocationService: NSObject {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var lastPlacemarkName: String = "Unknown location"
    var lastError: String?

    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdates() {
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingLocation()
    }

    func stopUpdates() {
        manager.stopUpdatingLocation()
    }

    func currentLocationOnce() async throws -> CLLocation {
        if let loc = currentLocation,
           Date().timeIntervalSince(loc.timestamp) < 60 {
            return loc
        }
        return try await withCheckedThrowingContinuation { cont in
            self.locationContinuation = cont
            if authorizationStatus == .notDetermined {
                manager.requestWhenInUseAuthorization()
            }
            manager.requestLocation()
        }
    }

    func reverseGeocode(_ location: CLLocation) async -> String {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let p = placemarks.first {
                let parts = [p.locality, p.administrativeArea, p.country].compactMap { $0 }
                let name = parts.joined(separator: ", ")
                if !name.isEmpty {
                    lastPlacemarkName = name
                    return name
                }
            }
        } catch {
            lastError = error.localizedDescription
        }
        return "Unknown location"
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = latest
            if let cont = self.locationContinuation {
                self.locationContinuation = nil
                cont.resume(returning: latest)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.lastError = error.localizedDescription
            if let cont = self.locationContinuation {
                self.locationContinuation = nil
                cont.resume(throwing: error)
            }
        }
    }
}

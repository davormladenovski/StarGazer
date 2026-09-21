import Foundation
import CoreMotion
import CoreLocation

@Observable
@MainActor
final class MotionService: NSObject {
    static let shared = MotionService()

    /// Compass heading in degrees from True North (0 = N, 90 = E).
    var heading: Double = 0
    /// Camera pointing altitude in degrees: 0 = horizon, +90 = zenith, -90 = nadir.
    var pitch: Double = 0
    /// Whether the motion stream is currently running.
    var isActive = false
    var lastError: String?

    // Smoothing — low-pass filter so the overlay glides instead of jitters.
    private let smoothing: Double = 0.15

    private let motion = CMMotionManager()
    private let location = CLLocationManager()

    override private init() {
        super.init()
        location.delegate = self
        location.headingFilter = 0.5
        location.headingOrientation = .portrait
        motion.deviceMotionUpdateInterval = 1.0 / 30.0
    }

    func start() {
        guard !isActive else { return }
        isActive = true

        // Make sure we have location authorization — heading needs it.
        if location.authorizationStatus == .notDetermined {
            location.requestWhenInUseAuthorization()
        }

        if CLLocationManager.headingAvailable() {
            location.startUpdatingHeading()
        }

        if motion.isDeviceMotionAvailable {
            // .xArbitraryZVertical works without magnetometer lock — we use
            // CLLocationManager for heading anyway, so we only need attitude here.
            motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] data, _ in
                guard let self, let data else { return }
                // Compute pointing altitude from gravity vector.
                // When the back camera looks at the horizon, gravity ≈ (0, -1, 0)
                // (down the screen). When camera points up, gravity ≈ (0, 0, -1).
                // Altitude angle = asin(-gravity.z).
                let g = data.gravity
                // Camera pointing altitude from gravity vector in device frame.
                // Screen-up flat (camera at floor) → g.z = -1 → pitch = -90°
                // Upright (camera at horizon)     → g.z =  0 → pitch =   0°
                // Screen-down flat (camera at sky)→ g.z = +1 → pitch = +90°
                let z = max(-1.0, min(1.0, g.z))
                let altRad = asin(z)
                let altDeg = altRad.toDegrees()
                let alpha = self.smoothing
                Task { @MainActor in
                    // Exponential smoothing — heavily weight previous value to reduce hand-shake jitter.
                    self.pitch = self.pitch * (1 - alpha) + altDeg * alpha
                }
            }
        }
    }

    func stop() {
        guard isActive else { return }
        isActive = false
        location.stopUpdatingHeading()
        motion.stopDeviceMotionUpdates()
    }

    func calibrate() {
        location.stopUpdatingHeading()
        location.startUpdatingHeading()
    }
}

extension MotionService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let target = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        let alpha = self.smoothing
        Task { @MainActor in
            // Take the SHORTEST angular distance to avoid wrap-around glitches at 0°/360°.
            var delta = target - self.heading
            if delta > 180 { delta -= 360 }
            if delta < -180 { delta += 360 }
            var next = self.heading + delta * alpha
            if next < 0 { next += 360 }
            if next >= 360 { next -= 360 }
            self.heading = next
        }
    }

    nonisolated func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        true
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            if (status == .authorizedWhenInUse || status == .authorizedAlways),
               CLLocationManager.headingAvailable() {
                manager.startUpdatingHeading()
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            if (status == .authorizedWhenInUse || status == .authorizedAlways),
               CLLocationManager.headingAvailable() {
                manager.startUpdatingHeading()
            }
        }
    }
}

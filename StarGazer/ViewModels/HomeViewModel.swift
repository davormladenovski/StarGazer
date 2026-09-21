import Foundation
import CoreLocation

@Observable
@MainActor
final class HomeViewModel {
    var issPosition: ISSPosition?
    var weather: WeatherSnapshot?
    var sun: SunData?
    var moon: MoonPhase?
    var nextPass: ISSPass?

    var isLoading: Bool = false
    var error: String?

    private var refreshTimer: Task<Void, Never>?

    func startRefresh() {
        cancelRefresh()
        refreshTimer = Task { [weak self] in
            while !Task.isCancelled {
                await self?.loadISS()
                try? await Task.sleep(nanoseconds: UInt64(Constants.Refresh.issDashboardSeconds * 1_000_000_000))
            }
        }
    }

    func cancelRefresh() {
        refreshTimer?.cancel()
        refreshTimer = nil
    }

    func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        moon = MoonPhaseCalculator.phase(for: Date())

        do {
            let loc = try await LocationService.shared.currentLocationOnce()
            async let weatherTask = WeatherService.shared.currentWeather(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
            async let sunTask = SunriseSunsetService.shared.sunData(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
            async let issTask = ISSService.shared.currentPosition()
            async let passesTask = ISSService.shared.predictPasses(near: loc.coordinate.latitude, near: loc.coordinate.longitude, count: 1)

            do { weather = try await weatherTask } catch let fetchError { self.error = (fetchError as? APIError)?.errorDescription }
            do { sun = try await sunTask } catch { /* keep last */ }
            do { issPosition = try await issTask } catch { /* keep last */ }
            nextPass = await passesTask.first
        } catch {
            self.error = "Location is not available."
            do { issPosition = try await ISSService.shared.currentPosition() } catch {}
        }
    }

    private func loadISS() async {
        do { issPosition = try await ISSService.shared.currentPosition() } catch { /* silent */ }
    }
}

import Foundation
import CoreLocation
import MapKit

@Observable
@MainActor
final class ISSMapViewModel {
    var position: ISSPosition?
    var trajectory: [CLLocationCoordinate2D] = []
    var nextPass: ISSPass?
    var error: String?

    private var liveTask: Task<Void, Never>?

    func start() {
        cancel()
        liveTask = Task { [weak self] in
            // Trajectory updates less frequently
            await self?.refreshTrajectory()
            while !Task.isCancelled {
                await self?.refreshPosition()
                try? await Task.sleep(nanoseconds: UInt64(Constants.Refresh.issLiveSeconds * 1_000_000_000))
            }
        }
    }

    func cancel() {
        liveTask?.cancel()
        liveTask = nil
    }

    func loadNextPass() async {
        if let loc = LocationService.shared.currentLocation {
            nextPass = await ISSService.shared.predictPasses(near: loc.coordinate.latitude, near: loc.coordinate.longitude, count: 1).first
        }
    }

    private func refreshPosition() async {
        do {
            position = try await ISSService.shared.currentPosition()
        } catch {
            self.error = (error as? APIError)?.errorDescription
        }
    }

    private func refreshTrajectory() async {
        do {
            trajectory = try await ISSService.shared.trajectory()
        } catch {
            // Non-fatal; continuous fetches will retry.
        }
    }
}

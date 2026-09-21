import Foundation

enum PassFilter: String, CaseIterable, Identifiable {
    case all, visible, week
    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: return "All"
        case .visible: return "Visible"
        case .week: return "This week"
        }
    }
}

@Observable
@MainActor
final class ISSPassesViewModel {
    var passes: [ISSPass] = []
    var locationName: String = "your location"
    var filter: PassFilter = .all
    var isLoading = false
    var error: String?

    var filtered: [ISSPass] {
        let now = Date()
        switch filter {
        case .all: return passes
        case .visible: return passes.filter { $0.visible }
        case .week: return passes.filter { $0.startTime.timeIntervalSince(now) < 7 * 86400 }
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loc = try await LocationService.shared.currentLocationOnce()
            locationName = await LocationService.shared.reverseGeocode(loc)
            passes = await ISSService.shared.predictPasses(near: loc.coordinate.latitude, near: loc.coordinate.longitude, count: 8)
        } catch {
            self.error = "Location is not available."
            passes = await ISSService.shared.predictPasses(near: 41.99, near: 21.43, count: 8)
        }
    }
}

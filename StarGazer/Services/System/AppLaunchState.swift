import Foundation

@MainActor
@Observable
final class AppLaunchState {
    static let shared = AppLaunchState()
    var isHomeReady: Bool = false
    private init() {}
}

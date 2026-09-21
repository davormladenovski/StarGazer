import Foundation
import LocalAuthentication

enum BiometricError: LocalizedError {
    case notAvailable
    case failed(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .notAvailable: return "Biometric authentication is not available."
        case .failed(let msg): return msg
        case .cancelled: return "Authentication was cancelled."
        }
    }
}

@Observable
final class BiometricService {
    var lastError: BiometricError?

    func biometryAvailable() -> Bool {
        let ctx = LAContext()
        var err: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
    }

    func biometryType() -> LABiometryType {
        let ctx = LAContext()
        var err: NSError?
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
        return ctx.biometryType
    }

    @MainActor
    func authenticate(reason: String = "Unlock StarGazer") async throws {
        let ctx = LAContext()
        ctx.localizedFallbackTitle = "Use passcode"
        var err: NSError?

        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &err) else {
            throw BiometricError.notAvailable
        }

        do {
            let ok = try await ctx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            if !ok { throw BiometricError.failed("Authentication failed.") }
        } catch let laError as LAError {
            switch laError.code {
            case .userCancel, .appCancel, .systemCancel:
                throw BiometricError.cancelled
            default:
                throw BiometricError.failed(laError.localizedDescription)
            }
        }
    }
}

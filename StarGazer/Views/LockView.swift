import SwiftUI

struct LockView: View {
    @Binding var isUnlocked: Bool
    @State private var biometric = BiometricService()
    @State private var error: String?
    @State private var isAuthenticating = false
    private let settings = SettingsManager.shared

    private static let bgImage: UIImage? = {
        if let url = Bundle.main.url(forResource: "faceid_screen", withExtension: "png"),
           let img = UIImage(contentsOfFile: url.path) {
            return img
        }
        return nil
    }()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let img = Self.bgImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                AppBackground()
            }

            FallingStarsView()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            LinearGradient(
                colors: [.black.opacity(0.0), .black.opacity(0.5), .black.opacity(0.9)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 14) {
                Spacer()

                if let error {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(ColorTheme.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 4)
                }

                Button {
                    Task { await unlock() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: biometric.biometryType() == .faceID ? "faceid" : "touchid")
                            .font(.title3)
                        Text("Unlock with \(biometric.biometryType() == .faceID ? "Face ID" : "Touch ID")")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [ColorTheme.secondaryAccent, ColorTheme.primaryAccent],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: ColorTheme.primaryAccent.opacity(0.45), radius: 16, y: 6)
                }
                .disabled(isAuthenticating)

                Button("Use passcode") {
                    Task { await unlock() }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(ColorTheme.textSecondary)
                .padding(.top, 4)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 56)
        }
        .task {
            if !settings.faceIDEnabled {
                isUnlocked = true
            }
        }
    }

    private func unlock() async {
        isAuthenticating = true
        defer { isAuthenticating = false }
        do {
            try await biometric.authenticate()
            withAnimation(.easeInOut(duration: 0.3)) {
                isUnlocked = true
            }
        } catch let e as BiometricError {
            error = e.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }
}

#Preview {
    LockView(isUnlocked: .constant(false))
}

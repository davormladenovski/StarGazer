import SwiftUI
import UIKit

struct CameraCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var camera = CameraService()
    let onCaptured: (UIImage) -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if camera.isAuthorized {
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(ColorTheme.textSecondary)
                    Text("Allow camera access in Settings.")
                        .foregroundStyle(ColorTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            VStack {
                HStack {
                    Button {
                        camera.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                }
                .padding()
                Spacer()
                Button {
                    Task {
                        do {
                            let image = try await camera.capturePhoto()
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            camera.stop()
                            onCaptured(image)
                            dismiss()
                        } catch {
                            camera.lastError = error.localizedDescription
                        }
                    }
                } label: {
                    ZStack {
                        Circle().stroke(.white, lineWidth: 4).frame(width: 76, height: 76)
                        Circle().fill(.white).frame(width: 62, height: 62)
                    }
                }
                .padding(.bottom, 32)
                .disabled(!camera.isAuthorized)
            }
        }
        .task {
            await camera.configureSession()
            camera.start()
        }
        .onDisappear { camera.stop() }
    }
}

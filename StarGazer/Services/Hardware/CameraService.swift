import AVFoundation
import SwiftUI
import UIKit

enum CameraError: LocalizedError {
    case denied
    case unavailable
    case captureFailed

    var errorDescription: String? {
        switch self {
        case .denied: return "Camera access denied."
        case .unavailable: return "Camera is not available."
        case .captureFailed: return "Capture failed."
        }
    }
}

@Observable
final class CameraService: NSObject {
    var isAuthorized: Bool = false
    var latestImage: UIImage?
    var lastError: String?

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var photoContinuation: CheckedContinuation<UIImage, Error>?
    private let queue = DispatchQueue(label: "stargazer.camera.session")

    override init() {
        super.init()
    }

    func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            isAuthorized = granted
            return granted
        default:
            isAuthorized = false
            return false
        }
    }

    func configureSession() async {
        let granted = await requestAccess()
        guard granted else { return }

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            queue.async { [weak self] in
                guard let self else { cont.resume(); return }
                self.session.beginConfiguration()
                self.session.sessionPreset = .photo

                if self.session.inputs.isEmpty,
                   let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                   let input = try? AVCaptureDeviceInput(device: device),
                   self.session.canAddInput(input) {
                    self.session.addInput(input)
                }

                // No camera hardware (e.g. Simulator) means no active format, so there is
                // nothing valid to configure the photo output against.
                let device = (self.session.inputs.first as? AVCaptureDeviceInput)?.device

                if let device, self.session.outputs.isEmpty,
                   self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                    if #available(iOS 16.0, *),
                       let maxDimensions = device.activeFormat.supportedMaxPhotoDimensions
                        .max(by: { Int($0.width) * Int($0.height) < Int($1.width) * Int($1.height) }) {
                        self.photoOutput.maxPhotoDimensions = maxDimensions
                    }
                }

                self.session.commitConfiguration()
                cont.resume()
            }
        }
    }

    /// True when the session has a real camera input + photo output and is running.
    var canCapture: Bool {
        session.isRunning && !session.inputs.isEmpty && session.outputs.contains(photoOutput)
    }

    func start() {
        queue.async { [weak self] in
            guard let self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func capturePhoto() async throws -> UIImage {
        guard canCapture else { throw CameraError.unavailable }
        return try await withCheckedThrowingContinuation { cont in
            self.photoContinuation = cont
            let settings: AVCapturePhotoSettings
            if !photoOutput.availablePhotoCodecTypes.isEmpty {
                settings = AVCapturePhotoSettings(format: [
                    AVVideoCodecKey: AVVideoCodecType.jpeg
                ])
            } else {
                settings = AVCapturePhotoSettings()
            }
            settings.flashMode = .off
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            photoContinuation?.resume(throwing: error)
            photoContinuation = nil
            return
        }
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            photoContinuation?.resume(throwing: CameraError.captureFailed)
            photoContinuation = nil
            return
        }
        DispatchQueue.main.async {
            self.latestImage = image
        }
        photoContinuation?.resume(returning: image)
        photoContinuation = nil
    }
}

// MARK: - Preview

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let v = PreviewUIView()
        v.videoPreviewLayer.session = session
        v.videoPreviewLayer.videoGravity = .resizeAspectFill
        return v
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

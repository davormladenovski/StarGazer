import SwiftUI

struct SkyCompassView: View {
    @State private var vm = SkyCompassViewModel()
    @State private var motion = MotionService.shared
    @State private var camera = CameraService()
    @State private var showNewObservation = false
    @State private var detectedForObservation: String?
    @State private var capturedPhoto: Data?
    @State private var capturing = false
    @State private var flashOpacity: Double = 0

    private var azimuth: Double { motion.heading }
    private var altitude: Double { motion.pitch }

    // Match iPhone wide camera in portrait orientation (4:3 sensor, rotated).
    private let horizontalFOV: Double = 46
    private let verticalFOV: Double = 62

    var body: some View {
        ZStack {
            cameraBackground
                .ignoresSafeArea()

            celestialOverlay
                .ignoresSafeArea()

            // Center crosshair — shows where the camera is aimed.
            crosshair
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomPanel
            }

            // Shutter flash overlay.
            Color.white
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .task {
            await camera.configureSession()
            camera.start()
            motion.start()
            vm.start()
        }
        .onDisappear {
            camera.stop()
            motion.stop()
            vm.cancel()
        }
        .onChange(of: motion.heading) { _, _ in
            vm.updatePointing(azimuth: azimuth, altitude: altitude)
        }
        .onChange(of: motion.pitch) { _, _ in
            vm.updatePointing(azimuth: azimuth, altitude: altitude)
        }
        .fullScreenCover(isPresented: $showNewObservation) {
            NavigationStack {
                NewObservationView(
                    prefilledTitle: detectedForObservation,
                    prefilledType: kindToType(vm.nearestBodies.first?.kind),
                    prefilledPhoto: capturedPhoto,
                    detectedBody: detectedForObservation
                )
            }
        }
    }

    // MARK: - Camera background

    private var cameraBackground: some View {
        Group {
            if camera.isAuthorized {
                CameraPreviewView(session: camera.session)
            } else {
                LinearGradient(colors: [ColorTheme.background, ColorTheme.backgroundDeep],
                               startPoint: .top, endPoint: .bottom)
            }
        }
    }

    // MARK: - Overlay of celestial bodies

    private var celestialOverlay: some View {
        GeometryReader { geo in
            ZStack {
                // Pre-filter bodies within FOV — much faster than rendering 1600+ no-op views.
                ForEach(vm.visibleBodies.filter { isInFOV($0) }) { body in
                    if let p = position(for: body, in: geo.size) {
                        bodyLabel(body).position(p)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func isInFOV(_ body: CelestialBody) -> Bool {
        var dAz = body.azimuth - azimuth
        if dAz > 180 { dAz -= 360 }
        if dAz < -180 { dAz += 360 }
        let dAlt = body.altitude - altitude
        return abs(dAz) <= horizontalFOV / 2 && abs(dAlt) <= verticalFOV / 2
    }

    private func position(for body: CelestialBody, in size: CGSize) -> CGPoint? {
        var dAz = body.azimuth - azimuth
        if dAz > 180 { dAz -= 360 }
        if dAz < -180 { dAz += 360 }
        let dAlt = body.altitude - altitude

        if abs(dAz) > horizontalFOV / 2 || abs(dAlt) > verticalFOV / 2 { return nil }

        let x = size.width / 2 + CGFloat(dAz / (horizontalFOV / 2)) * (size.width / 2)
        let y = size.height / 2 - CGFloat(dAlt / (verticalFOV / 2)) * (size.height / 2)
        return CGPoint(x: x, y: y)
    }

    private var crosshair: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.55), lineWidth: 1)
                .frame(width: 26, height: 26)
            Rectangle().fill(Color.white.opacity(0.55)).frame(width: 1, height: 18)
            Rectangle().fill(Color.white.opacity(0.55)).frame(width: 18, height: 1)
        }
        .shadow(color: .black.opacity(0.7), radius: 2)
    }

    private func bodyLabel(_ body: CelestialBody) -> some View {
        let dotSize: CGFloat = max(3, 9 - CGFloat(body.magnitude))
        let useImage = body.kind != .star
        let isBrightStar = body.kind == .star && body.magnitude < 2.5
        let showName = useImage || isBrightStar

        return VStack(spacing: 3) {
            if useImage {
                CelestialIcon(bodyName: body.name, size: 44)
                    .shadow(color: color(for: body).opacity(0.6), radius: 8)
            } else {
                ZStack {
                    if isBrightStar {
                        Circle()
                            .fill(color(for: body).opacity(0.35))
                            .frame(width: dotSize * 2.4, height: dotSize * 2.4)
                            .blur(radius: 4)
                    }
                    Circle()
                        .fill(color(for: body))
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: .black, radius: 1)
                }
            }
            if showName {
                Text(body.name)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black, radius: 2)
            }
        }
    }

    private func color(for body: CelestialBody) -> Color {
        switch body.kind {
        case .star: return ColorTheme.secondaryAccent
        case .planet: return .orange
        case .moon: return .white
        case .sun: return .yellow
        case .deepSky: return .purple
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(cardinal(for: azimuth))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(String(format: "%.0f°  •  alt %.0f°", azimuth, altitude))
                        .font(.caption.monospaced())
                        .foregroundStyle(ColorTheme.textSecondary)
                }
                .shadow(color: .black.opacity(0.7), radius: 4)
                Spacer()
                Button {
                    motion.calibrate()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "location.magnifyingglass")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                compassRose
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var compassRose: some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.35))
                .frame(width: 78, height: 78)
            Circle()
                .strokeBorder(.white.opacity(0.35), lineWidth: 1)
                .frame(width: 78, height: 78)

            // Rose ring counter-rotates so cardinal letters track real-world directions.
            ZStack {
                ForEach(0..<8) { i in
                    let label = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][i]
                    Text(label)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(label == "N" ? ColorTheme.secondaryAccent : .white)
                        .offset(y: -32)
                        .rotationEffect(.degrees(Double(i) * 45.0))
                }
            }
            .rotationEffect(.degrees(-azimuth))

            // Fixed needle pointing where the user is facing (up on screen).
            Triangle()
                .fill(ColorTheme.secondaryAccent)
                .frame(width: 10, height: 22)
                .offset(y: -10)
        }
    }

    // MARK: - Bottom panel

    private var bottomPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("NEAREST BODIES")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.textSecondary)
                    .tracking(1.2)
                Spacer()
                if !vm.locationName.isEmpty {
                    Label(vm.locationName, systemImage: "mappin")
                        .font(.caption2)
                        .foregroundStyle(ColorTheme.textSecondary)
                        .lineLimit(1)
                }
            }

            if vm.nearestBodies.isEmpty {
                Text("Point at the sky…")
                    .font(.caption)
                    .foregroundStyle(ColorTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
            } else {
                ForEach(vm.nearestBodies) { body in
                    HStack(spacing: 10) {
                        if body.kind != .star, CelestialIconCache.image(for: body.name) != nil {
                            CelestialIcon(bodyName: body.name, size: 30)
                        } else {
                            ZStack {
                                Circle().fill(color(for: body).opacity(0.18)).frame(width: 30, height: 30)
                                Image(systemName: body.symbol)
                                    .font(.caption.bold())
                                    .foregroundStyle(color(for: body))
                            }
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(body.name).font(.subheadline.bold()).foregroundStyle(.white)
                            if let c = body.constellation {
                                Text("\(c) • mag \(String(format: "%.1f", body.magnitude))")
                                    .font(.caption2)
                                    .foregroundStyle(ColorTheme.textSecondary)
                            } else {
                                Text("alt \(Int(body.altitude))° • az \(Int(body.azimuth))°")
                                    .font(.caption2)
                                    .foregroundStyle(ColorTheme.textSecondary)
                            }
                        }
                        Spacer()
                    }
                }
            }

            Button {
                Task { await captureAndOpen() }
            } label: {
                HStack(spacing: 8) {
                    if capturing {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "camera.shutter.button.fill")
                    }
                    Text(capturing ? "Capturing…" : "Capture & save")
                }
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    LinearGradient(colors: [ColorTheme.secondaryAccent, ColorTheme.primaryAccent],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(capturing)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.black.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    private func cardinal(for heading: Double) -> String {
        let dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let idx = Int(((heading + 22.5).truncatingRemainder(dividingBy: 360)) / 45) % 8
        return dirs[max(0, idx)]
    }

    private func captureAndOpen() async {
        capturing = true
        defer { capturing = false }
        capturedPhoto = nil
        detectedForObservation = vm.nearestBodies.first?.name

        withAnimation(.easeOut(duration: 0.08)) { flashOpacity = 0.6 }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if camera.isAuthorized {
            // Wait briefly for the session to be running if user tapped quickly.
            for _ in 0..<10 where !camera.canCapture {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            do {
                let image = try await camera.capturePhoto()
                capturedPhoto = image.jpegData(compressionQuality: 0.85)
            } catch {
                capturedPhoto = nil
            }
        }

        withAnimation(.easeIn(duration: 0.25)) { flashOpacity = 0 }
        showNewObservation = true
    }

    private func kindToType(_ kind: CelestialBodyKind?) -> ObjectType? {
        switch kind {
        case .star: return .star
        case .planet: return .planet
        case .moon: return .moon
        default: return nil
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    SkyCompassView()
}

import SwiftUI

struct SplashScreenView: View {
    var onFinish: () -> Void

    @State private var auroraPhase: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 14
    @State private var fadeOut: Bool = false

    private static let splashImage: UIImage? = {
        for ext in ["png", "jpg", "jpeg"] {
            if let url = Bundle.main.url(forResource: "splash", withExtension: ext),
               let img = UIImage(contentsOfFile: url.path) {
                return img
            }
        }
        return nil
    }()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let img = Self.splashImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                LinearGradient(
                    colors: [.black.opacity(0.0), .black.opacity(0.45), .black.opacity(0.85)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            } else {
                aurora.blendMode(.screen).ignoresSafeArea()
            }

            VStack(spacing: 12) {
                Spacer()

                Text("StarGazer")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(ColorTheme.textPrimary)
                    .shadow(color: .black.opacity(0.6), radius: 10)
                    .opacity(textOpacity)
                    .offset(y: textOffset)

                Text("Explore the night sky")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(ColorTheme.textSecondary)
                    .shadow(color: .black.opacity(0.5), radius: 6)
                    .opacity(textOpacity)
                    .offset(y: textOffset)

                Spacer()

                ProgressView()
                    .tint(ColorTheme.secondaryAccent)
                    .opacity(textOpacity)
                    .padding(.bottom, 60)
            }
        }
        .opacity(fadeOut ? 0 : 1)
        .task { await runIntro() }
    }

    // MARK: - Aurora fallback (only when there's no splash image)

    private var aurora: some View {
        ZStack {
            auroraBlob(color: Color(red: 0.0, green: 0.95, blue: 0.7), x: 0.2, y: 0.25, size: 380, phaseOffset: 0)
            auroraBlob(color: Color(red: 0.45, green: 0.0, blue: 0.95), x: 0.8, y: 0.35, size: 420, phaseOffset: 0.6)
            auroraBlob(color: Color(red: 0.0, green: 0.65, blue: 1.0), x: 0.4, y: 0.8, size: 460, phaseOffset: 1.2)
        }
    }

    private func auroraBlob(color: Color, x: CGFloat, y: CGFloat, size: CGFloat, phaseOffset: CGFloat) -> some View {
        GeometryReader { geo in
            let drift = sin(auroraPhase + phaseOffset) * 50
            let driftY = cos(auroraPhase * 0.8 + phaseOffset) * 40
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.55), color.opacity(0)],
                        center: .center, startRadius: 0, endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)
                .blur(radius: 50)
                .position(x: geo.size.width * x + drift, y: geo.size.height * y + driftY)
        }
    }

    // MARK: - Intro choreography

    private func runIntro() async {
        // Animate aurora only if we're actually showing it.
        if Self.splashImage == nil {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
                auroraPhase = .pi
            }
        }
        withAnimation(.easeOut(duration: 0.55)) {
            textOpacity = 1
            textOffset = 0
        }

        // Minimum splash time so the intro can settle.
        let started = Date()
        let minSeconds: TimeInterval = 1.4
        let maxSeconds: TimeInterval = 9.0

        while !AppLaunchState.shared.isHomeReady {
            if Date().timeIntervalSince(started) >= maxSeconds { break }
            try? await Task.sleep(nanoseconds: 200_000_000)
        }

        let elapsed = Date().timeIntervalSince(started)
        if elapsed < minSeconds {
            try? await Task.sleep(nanoseconds: UInt64((minSeconds - elapsed) * 1_000_000_000))
        }

        withAnimation(.easeInOut(duration: 0.45)) {
            fadeOut = true
        }
        try? await Task.sleep(nanoseconds: 450_000_000)
        onFinish()
    }
}

#Preview {
    SplashScreenView(onFinish: {})
}

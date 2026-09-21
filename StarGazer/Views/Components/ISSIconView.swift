import SwiftUI

/// Loads the bundled iss_icon.png. Used for ISS markers across the app.
struct ISSIconView: View {
    var size: CGFloat = 48
    var glow: Bool = true

    private static let image: UIImage? = {
        if let url = Bundle.main.url(forResource: "iss_icon", withExtension: "png"),
           let img = UIImage(contentsOfFile: url.path) {
            return img
        }
        return nil
    }()

    var body: some View {
        ZStack {
            if glow {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cyan.opacity(0.35), .clear],
                            center: .center, startRadius: 0, endRadius: size * 0.9
                        )
                    )
                    .frame(width: size * 1.8, height: size * 1.8)
            }
            if let img = Self.image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
            } else {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: size * 0.6, weight: .bold))
                    .frame(width: size, height: size)
                    .foregroundStyle(.cyan)
            }
        }
    }
}

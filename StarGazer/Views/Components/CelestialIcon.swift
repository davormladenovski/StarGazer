import SwiftUI

/// Loads a bundled image for a celestial body (sun, moon, mercury, venus,
/// mars, jupiter, saturn, uranus, neptune). Falls back to an SF Symbol if
/// the image is missing.
struct CelestialIcon: View {
    let bodyName: String
    var size: CGFloat = 44
    var fallbackSymbol: String = "circle.fill"
    var fallbackColor: Color = .white

    var body: some View {
        if let img = CelestialIconCache.image(for: bodyName) {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: fallbackSymbol)
                .font(.system(size: size * 0.7, weight: .bold))
                .foregroundStyle(fallbackColor)
                .frame(width: size, height: size)
        }
    }
}

/// Process-wide cache so each body image is decoded from disk exactly once.
enum CelestialIconCache {
    private static var cache: [String: UIImage] = [:]
    private static let lock = NSLock()

    static func image(for body: String) -> UIImage? {
        let key = normalize(body)
        lock.lock(); defer { lock.unlock() }
        if let cached = cache[key] { return cached }

        let candidates = filenameCandidates(for: key)
        for name in candidates {
            if let url = Bundle.main.url(forResource: name, withExtension: "png"),
               let img = UIImage(contentsOfFile: url.path) {
                cache[key] = img
                return img
            }
        }
        return nil
    }

    private static func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            // Strip emoji / non-letter trailing chars (Moon name often has 🌖 etc.)
            .components(separatedBy: CharacterSet.letters.inverted)
            .joined()
    }

    private static func filenameCandidates(for key: String) -> [String] {
        // Allow "moon waxing crescent" → "moon", etc.
        var c = [key]
        if let first = key.split(separator: " ").first { c.append(String(first)) }
        return c
    }
}

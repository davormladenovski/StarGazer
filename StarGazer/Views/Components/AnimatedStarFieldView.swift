import SwiftUI

private struct Star {
    let x: CGFloat
    let y: CGFloat
    let baseSize: CGFloat
    let twinkleSpeed: Double
    let phase: Double
}

private struct Meteor {
    let startTime: Double
    let duration: Double
    let startX: CGFloat
    let startY: CGFloat
    let angle: Double
    let length: CGFloat
}

struct AnimatedStarFieldView: View {
    let starCount: Int
    private let stars: [Star]
    private let meteors: [Meteor]

    init(starCount: Int = 50) {
        self.starCount = starCount
        var generator = SystemRandomNumberGenerator()
        var ss: [Star] = []
        for _ in 0..<starCount {
            ss.append(
                Star(
                    x: CGFloat.random(in: 0...1, using: &generator),
                    y: CGFloat.random(in: 0...1, using: &generator),
                    baseSize: CGFloat.random(in: 1...3, using: &generator),
                    twinkleSpeed: Double.random(in: 0.6...2.5, using: &generator),
                    phase: Double.random(in: 0...(2 * .pi), using: &generator)
                )
            )
        }
        var ms: [Meteor] = []
        for i in 0..<3 {
            ms.append(
                Meteor(
                    startTime: Double(i) * 7.0 + Double.random(in: 0...3, using: &generator),
                    duration: Double.random(in: 0.8...1.4, using: &generator),
                    startX: CGFloat.random(in: 0...1, using: &generator),
                    startY: CGFloat.random(in: 0...0.4, using: &generator),
                    angle: Double.random(in: (.pi / 5)...(.pi / 3), using: &generator),
                    length: CGFloat.random(in: 80...160, using: &generator)
                )
            )
        }
        self.stars = ss
        self.meteors = ms
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate

                // Background gradient
                let bg = Path(CGRect(origin: .zero, size: size))
                ctx.fill(bg, with: .linearGradient(
                    Gradient(colors: [
                        ColorTheme.background,
                        ColorTheme.backgroundDeep
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                ))

                // Stars
                for s in stars {
                    let twinkle = (sin(t * s.twinkleSpeed + s.phase) + 1) / 2
                    let opacity = 0.3 + twinkle * 0.7
                    let radius = s.baseSize * (0.7 + twinkle * 0.6)
                    let cx = s.x * size.width
                    let cy = s.y * size.height
                    let rect = CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(opacity)))

                    // Glow
                    if s.baseSize > 2 {
                        let glowR = radius * 2.5
                        let glowRect = CGRect(x: cx - glowR, y: cy - glowR, width: glowR * 2, height: glowR * 2)
                        ctx.fill(Path(ellipseIn: glowRect), with: .color(.white.opacity(opacity * 0.15)))
                    }
                }

                // Meteors
                let cycle: Double = 12.0
                for m in meteors {
                    let localT = (t - m.startTime).truncatingRemainder(dividingBy: cycle)
                    guard localT >= 0 && localT < m.duration else { continue }
                    let progress = localT / m.duration
                    let dx = cos(m.angle) * m.length
                    let dy = sin(m.angle) * m.length
                    let sx = m.startX * size.width
                    let sy = m.startY * size.height
                    let hx = sx + dx * CGFloat(progress)
                    let hy = sy + dy * CGFloat(progress)
                    let tx = hx - dx * 0.25
                    let ty = hy - dy * 0.25

                    var path = Path()
                    path.move(to: CGPoint(x: tx, y: ty))
                    path.addLine(to: CGPoint(x: hx, y: hy))
                    let fade = sin(progress * .pi)
                    ctx.stroke(path, with: .linearGradient(
                        Gradient(colors: [.white.opacity(0), .white.opacity(fade)]),
                        startPoint: CGPoint(x: tx, y: ty),
                        endPoint: CGPoint(x: hx, y: hy)
                    ), lineWidth: 2)

                    let headRect = CGRect(x: hx - 2, y: hy - 2, width: 4, height: 4)
                    ctx.fill(Path(ellipseIn: headRect), with: .color(.white.opacity(fade)))
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    AnimatedStarFieldView()
}

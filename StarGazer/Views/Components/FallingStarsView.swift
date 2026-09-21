import SwiftUI

/// Lightweight falling-star background animation. Uses Canvas + TimelineView
/// so all rendering happens once per frame on the GPU without re-laying out
/// any SwiftUI views.
struct FallingStarsView: View {
    var starCount: Int = 40
    var meteorCount: Int = 2
    var speed: Double = 30          // points per second
    var meteorSpeed: Double = 480

    @State private var stars: [Star] = []
    @State private var meteors: [Meteor] = []
    @State private var lastSize: CGSize = .zero
    @State private var startTime: Date = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
            Canvas { ctx, size in
                ensureSeed(size: size)
                let t = timeline.date.timeIntervalSince(startTime)

                // Falling stars (slow vertical drift + twinkle).
                for s in stars {
                    let y = (s.baseY + CGFloat(t) * CGFloat(speed) * s.speedFactor)
                        .truncatingRemainder(dividingBy: size.height + 40) - 20
                    let twinkle = 0.55 + 0.45 * sin(t * s.twinkleSpeed + s.twinklePhase)
                    let opacity = s.alpha * twinkle
                    let rect = CGRect(x: s.x, y: y, width: s.size, height: s.size)
                    ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(opacity)))
                }

                // Shooting meteors (occasional fast streaks).
                for m in meteors {
                    let cycle = (t + m.offset).truncatingRemainder(dividingBy: m.cycleLength)
                    if cycle < m.duration {
                        let progress = cycle / m.duration
                        let startX = m.startX * size.width
                        let endX = startX + 240
                        let startY = m.startY * size.height
                        let endY = startY + 320
                        let x = startX + (endX - startX) * progress
                        let y = startY + (endY - startY) * progress
                        // Tail
                        var path = Path()
                        path.move(to: CGPoint(x: x - 60, y: y - 80))
                        path.addLine(to: CGPoint(x: x, y: y))
                        ctx.stroke(path,
                                   with: .linearGradient(
                                    Gradient(colors: [.white.opacity(0), .white.opacity(0.85)]),
                                    startPoint: CGPoint(x: x - 60, y: y - 80),
                                    endPoint: CGPoint(x: x, y: y)),
                                   lineWidth: 1.4)
                        // Head
                        ctx.fill(Path(ellipseIn: CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3)),
                                 with: .color(.white))
                    }
                }
            }
        }
    }

    private func ensureSeed(size: CGSize) {
        guard size != lastSize, size.width > 0, size.height > 0 else { return }
        let w = size.width
        let h = size.height
        stars = (0..<starCount).map { _ in
            Star(
                x: CGFloat.random(in: 0...w),
                baseY: CGFloat.random(in: 0...h),
                size: CGFloat.random(in: 1.0...2.4),
                alpha: Double.random(in: 0.35...0.95),
                speedFactor: Double.random(in: 0.4...1.4),
                twinkleSpeed: Double.random(in: 1.5...3.5),
                twinklePhase: Double.random(in: 0...(2 * .pi))
            )
        }
        meteors = (0..<meteorCount).map { i in
            Meteor(
                startX: CGFloat.random(in: 0...0.7),
                startY: CGFloat.random(in: 0...0.4),
                offset: Double(i) * 4.5,
                cycleLength: Double.random(in: 7...12),
                duration: Double.random(in: 0.7...1.1)
            )
        }
        lastSize = size
    }

    private struct Star {
        let x: CGFloat
        let baseY: CGFloat
        let size: CGFloat
        let alpha: Double
        let speedFactor: Double
        let twinkleSpeed: Double
        let twinklePhase: Double
    }

    private struct Meteor {
        let startX: CGFloat
        let startY: CGFloat
        let offset: Double
        let cycleLength: Double
        let duration: Double
    }
}

#Preview {
    ZStack {
        Color.black
        FallingStarsView()
    }
    .ignoresSafeArea()
}

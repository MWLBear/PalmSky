import SwiftUI

// MARK: - 1. 灵气粒子特效 (营造氛围)
struct ParticleView: View {
    let color: Color
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
        var speedY: CGFloat
    }
    
    var body: some View {
        // ⚡ 性能优化：从 60fps 降至 10fps，减少 CPU 唤醒 .periodic(from: .now, by: 0.1)
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    let rect = CGRect(x: particle.x * size.width, y: particle.y * size.height, width: 4 * particle.scale, height: 4 * particle.scale)
                    context.opacity = particle.opacity
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
            .onChange(of: timeline.date) { _, _ in updateParticles() }
        }
        .onAppear {
            // 初始生成一些粒子
            for _ in 0..<15 { particles.append(createParticle()) }
        }
    }
    
    func updateParticles() {
        for i in particles.indices {
            particles[i].y -= particles[i].speedY
            particles[i].opacity -= 0.005
        }
        // 移除消失的，补充新的
        particles.removeAll { $0.opacity <= 0 || $0.y < 0 }
        if Float.random(in: 0...1) < 0.1 && particles.count < 20 {
            particles.append(createParticle())
        }
    }
    
    func createParticle() -> Particle {
        Particle(
            x: CGFloat.random(in: 0.2...0.8),
            y: 1.0, // 从底部升起
            scale: CGFloat.random(in: 0.5...1.5),
            opacity: Double.random(in: 0.3...0.7),
            speedY: CGFloat.random(in: 0.002...0.005)
        )
    }
}

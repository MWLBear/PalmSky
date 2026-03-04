//
//  CelebrationView.swift
//  PalmSky Watch App
//
//  Created by mac on 12/16/25.
//

import SwiftUI

struct CelebrationView: View {
    @State private var floatOffset: CGFloat = 50
    @State private var glowOpacity: Double = 0.3
    @State private var appear: Bool = false


    var body: some View {
        ZStack {

           Color.black.ignoresSafeArea()
            // 中心飘渺文字
            VStack(spacing: 12) {
                Text(NSLocalizedString("watch_celebration_title", comment: ""))
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(glowOpacity), radius: 15, x: 0, y: 0)
                    .opacity(appear ? 1.0 : 0.0)
                    .offset(y: appear ? 0 : floatOffset)
                    .animation(.easeOut(duration: 2.0), value: appear)

                Text(NSLocalizedString("watch_celebration_subtitle", comment: ""))
                    .font(.system(.title3, design: .serif).italic())
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(appear ? 1.0 : 0.0)
                    .offset(y: appear ? 0 : floatOffset / 2)
                    .animation(.easeOut(duration: 2.0).delay(0.3), value: appear)
            }
            .ignoresSafeArea()
            .zIndex(1)
      
            // 光点漂浮（大道至简版）
            ForEach(0..<8) { i in
                Circle()
                    .fill(Color.white)
                    .frame(
                        width: CGFloat.random(in: 4...7),
                        height: CGFloat.random(in: 4...7)
                    )
                    .opacity(0.18 + Double(i) * 0.03)   // 👈 关键：别太低
                    .blur(radius: CGFloat.random(in: 1.5...3))
                    .offset(
                        x: CGFloat.random(in: -80...80),
                        y: CGFloat.random(in: -160...160)
                            + (appear ? -12 : 12)
                    )
                    .shadow(color: .white.opacity(0.25), radius: 6)
                    .blendMode(.screen)
                    .animation(
                        .easeInOut(duration: Double.random(in: 3.5...6))
                            .repeatForever(autoreverses: true),
                        value: appear
                    )
            }



        }
        .onAppear {
            appear = true
        }
    }
}

struct CelebrationView_Previews: PreviewProvider {
    static var previews: some View {
        CelebrationView()
    }
}

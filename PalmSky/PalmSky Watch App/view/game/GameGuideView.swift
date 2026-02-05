//
//  File.swift
//  PalmSky Watch App
//
//  Created by mac on 12/25/25.
//

import Foundation
import SwiftUI

struct GameGuideView: View {
    // 参数
    let title: String
    let subtitle: String
    let icon: String
    
    // 绑定状态，用于自动隐藏
    @Binding var isShowing: Bool
    
    var body: some View {
        if isShowing {
            VStack {
                Spacer()
                
                // 提示胶囊
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .symbolEffect(.bounce, options: .repeating) // iOS 17/watchOS 10+ 动画
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial) // 毛玻璃质感
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                .padding(.bottom, 20) // 距离底部的距离
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // 🔥 核心：允许点击穿透！
            // 这样玩家在看提示的时候直接点屏幕，就能开始游戏，不用先关提示
            .allowsHitTesting(false)
            .transition(.scale.combined(with: .opacity))
            .onAppear {
                // 2.5秒后自动消失
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
            .zIndex(200) // 确保在最顶层
        }
    }
}

// 预览
#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        GameGuideView(
            title: "斩除心魔",
            subtitle: "点击屏幕 发射飞剑",
            icon: "hand.tap.fill",
            isShowing: .constant(true)
        )
    }
}

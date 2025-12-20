//
//  File.swift
//  PalmSky Watch App
//
//  Created by mac on 12/20/25.
//

import SwiftUI

import SwiftUI

struct TaijiShapeView: View {
    let skin: TaijiSkin
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2
            let center = CGPoint(x: size / 2, y: size / 2)
            let dotSize = size * 0.125 // 鱼眼大小 (1/8)
            
            ZStack {
                // 1. 底圆 (阴面背景)
                // 我们不需要画阴鱼的形状，直接画一个满圆作为底色
                // 阳鱼盖住的地方显示阳色，没盖住的地方自然就是阴色
                Circle()
                    .fill(skin.yinGradient)
                
                // 2. 阳鱼 (一体化路径)
                // ✨ 核心修改：用 Path 一笔画出 S 型，确保渐变连贯
                Path { path in
                    // A. 起点：顶部中间
                    path.move(to: CGPoint(x: center.x, y: center.y - radius))
                    
                    // B. 右侧大半圆 (从顶到底)
                    path.addArc(center: center,
                                radius: radius,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(90),
                                clockwise: false)
                    
                    // C. 底部凹陷 (避让阴鱼的头)
                    // 中心在下半部分，画右半边的弧线，形成凹槽
                    path.addArc(center: CGPoint(x: center.x, y: center.y + radius/2),
                                radius: radius/2,
                                startAngle: .degrees(90),
                                endAngle: .degrees(270),
                                clockwise: false)
                    
                    // D. 顶部凸起 (阳鱼的头)
                    // 中心在上半部分，画左半边的弧线，形成凸起
                    path.addArc(center: CGPoint(x: center.x, y: center.y - radius/2),
                                radius: radius/2,
                                startAngle: .degrees(90),
                                endAngle: .degrees(270),
                                clockwise: true)
                    
                    path.closeSubpath()
                }
                .fill(skin.yangGradient) // 🔥 因为是同一个 Shape，渐变完美融合！
                
                // 3. 阴鱼眼 (在上半部，画在阳鱼头里)
                Circle()
                    .fill(skin.yinEyeColor)
                    .frame(width: dotSize, height: dotSize)
                    .position(x: center.x, y: center.y - radius/2)
                    .shadow(color: .black.opacity(0.2), radius: 1) // 增加一点内陷感
                
                // 4. 阳鱼眼 (在下半部，画在阴鱼背景上)
                Circle()
                    .fill(skin.yangEyeColor)
                    .frame(width: dotSize, height: dotSize)
                    .position(x: center.x, y: center.y + radius/2)
                    .shadow(color: .black.opacity(0.2), radius: 1)
            }
        }
        // 整体外发光
       // .shadow(color: skin.glowColor.opacity(0.1), radius: 15)
    }
}

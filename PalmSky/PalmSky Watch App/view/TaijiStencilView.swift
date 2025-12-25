//
//  File.swift
//  PalmSky Watch App
//
//  Created by mac on 12/24/25.
//

import Foundation
import SwiftUI

struct TaijiStencilView: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2
            let center = CGPoint(x: size / 2, y: size / 2)
            let dotSize = size * 0.14 // 鱼眼大小
            
            ZStack {
                // ❌ 以前这里有个底圆，现在绝对不能加！
                // 背景必须是透明的
                
                // 1. 阳鱼 (S形身体)
                // 既然是剪影，我们用 .white，系统会自动把它染成表盘的主题色
                Path { path in
                    path.move(to: CGPoint(x: center.x, y: center.y - radius))
                    
                    // 右侧大半圆
                    path.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
                    
                    // 底部凹陷 (避让阴鱼)
                    path.addArc(center: CGPoint(x: center.x, y: center.y + radius/2), radius: radius/2, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
                    
                    // 顶部凸起 (阳鱼头)
                    path.addArc(center: CGPoint(x: center.x, y: center.y - radius/2), radius: radius/2, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: true)
                    
                    path.closeSubpath()
                }
                .fill(Color.white)
                
                // 2. 阴鱼眼 (在透明区域画一个实心点)
                // 位置：上半部分 (阴鱼的头里)
                Circle()
                    .fill(Color.white)
                    .frame(width: dotSize, height: dotSize)
                    .position(x: center.x, y: center.y - radius/2)
                
                // 3. 阳鱼眼 (在白色区域挖一个孔)
                // 位置：下半部分 (阳鱼的头里)
                // ⚠️ 技巧：我们直接画一个黑色的圆，利用 blendMode 挖空，或者 simply 叠加黑色
                // 在 Tint 模式下，Color.black 会被系统处理为背景色(不发光)
                Circle()
                    .fill(Color.black)
                    .frame(width: dotSize, height: dotSize)
                    .position(x: center.x, y: center.y + radius/2)
                    // 强制混合模式为"擦除"，确保它是透的
                    .blendMode(.destinationOut)
            }
            // 这一步很重要：把内部的图层合成一个组，以便 blendMode 生效
            .compositingGroup()
        }
    }
}

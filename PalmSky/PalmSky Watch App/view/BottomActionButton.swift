//
//  BottomActionButton.swift
//  PalmSky Watch App
//
//  Created by mac on 12/21/25.
//

import Foundation
import SwiftUI

struct BottomActionButton: View {
    let title: String
    let primaryColor: Color
    let action: () -> Void
        
    var body: some View {
        let buttonWidth = maxButtonWidth()
        let buttonHeight = buttonWidth * 0.3 // 高度占宽度比例
        
        Button(action: action) {
            Text(title)
                .font(XiuxianFont.primaryButton)
                .foregroundColor(.white)
                .frame(width: buttonWidth, height: buttonHeight)
                .background(
                    LinearGradient(
                        colors: [primaryColor, primaryColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: primaryColor.opacity(0.5), radius: 8)
        }
        .buttonStyle(.plain)
    }
}

// ---------- maxButtonWidth 函数 ----------
/// 根据圆环缺口计算按钮最大宽度
/// - Parameters:
///   - startTrim: 圆环起点 (0~1)
///   - endTrim: 圆环终点 (0~1)
///   - paddingRatio: 按钮相对于缺口宽度的缩放比例，默认 0.80
/// - Returns: 按钮最大宽度
func maxButtonWidth(
    startTrim: Double = 0.16,
    endTrim: Double = 0.84,
    paddingRatio: CGFloat = 0.80
) -> CGFloat {
    let screenWidth = WKInterfaceDevice.current().screenBounds.width / 2
    let arcLength = endTrim - startTrim
    let gapRatio = 1.0 - arcLength
    let radius = screenWidth * 0.90 // 圆环撑满 90% 屏幕
    let gapAngle = gapRatio * 2 * .pi
    let gapWidth = 2 * radius * sin(gapAngle / 2)
    return gapWidth * paddingRatio
}

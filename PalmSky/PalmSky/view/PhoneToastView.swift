//
//  ToastView.swift
//  Billiards
//
//  Created by mac on 2025/11/16.
//

import Foundation
import SwiftUI


import SwiftUI

// MARK: - Toast Modifier
struct PhoneToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let duration: Double

    // 顶部内边距
    private var topPadding: CGFloat {
        #if os(watchOS)
        return 8
        #else
        return 60
        #endif
    }

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                VStack {
                    PhoneToastView(message: message)
                        .padding(.top, topPadding)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Toast View
struct PhoneToastView: View {
    let message: String

   // 获取当前环境 (判断深浅色模式)
    @Environment(\.colorScheme) private var colorScheme
  
    private var font: Font {
        #if os(watchOS)
        return .system(size: 13, weight: .semibold)
        #else
        return .system(size: 15, weight: .semibold)
        #endif
    }

    private var lineLimit: Int? {
        #if os(watchOS)
        return 2 // watch 上文字不宜太多
        #else
        return nil
        #endif
    }

    var body: some View {
        Text(message)
            .font(font)
            .foregroundColor(.primary)
            .multilineTextAlignment(.center)
            .lineLimit(lineLimit)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
              .regularMaterial,
              in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
        // 适配：浅色模式阴影淡一点，深色模式稍微深一点
              .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15),
                radius: 8, x: 0, y: 4
              )
              .padding(.horizontal, 24)
        // 动画过渡更自然
              .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - View Extension
extension View {
    func toast(_ message: String,
               isPresented: Binding<Bool>,
               duration: Double = 2) -> some View {
        self.modifier(PhoneToastModifier(isPresented: isPresented,
                                    message: message,
                                    duration: duration))
    }
}

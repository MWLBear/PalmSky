//
//  SwipeTutorialView.swift
//  PalmSky Watch App
//
//  Created by mac on 1/6/26.
//

import SwiftUI
// MARK: - Swipe Tutorial View
struct SwipeTutorialView: View {
    @State private var arrowOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 8) {
                // 左滑箭头动画
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .opacity(0.6)
                }
                .offset(x: arrowOffset)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        arrowOffset = -10
                    }
                }
                
                // 提示文字
                Text("左滑进入设置")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.7))
                    .shadow(color: .white.opacity(0.2), radius: 8)
            )
            .padding(.trailing, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    }
}

#Preview {
  SwipeTutorialView()
}

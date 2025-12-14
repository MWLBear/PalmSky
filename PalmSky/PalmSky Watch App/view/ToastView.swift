import SwiftUI

// MARK: - Toast 视图组件 (自带进出场动画)
struct ToastView: View {
    let message: String
    var onCancel: () -> Void
    
    // 控制动画的状态
    @State private var isVisible = false
    
    var body: some View {
        VStack {
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 14))
                
                Text(message)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .background(Color.black.opacity(0.4))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [.green.opacity(0.5), .green.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, y: 5)
            .padding(.top, 10) // 最终停留位置的顶部边距
            
            Spacer()
        }
        // 🔥 核心动画逻辑：
        // 如果 isVisible 为 true，位置在 0 (正常显示)
        // 如果 isVisible 为 false，位置在 -150 (屏幕上方外面)
        .offset(y: isVisible ? 0 : -150)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            // 1. 进场动画：慢慢滑下来
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isVisible = true
            }
            
            // 2. 停留 3 秒后执行退场
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                // 3. 退场动画：慢慢升上去
                withAnimation(.easeIn(duration: 0.4)) {
                    isVisible = false
                }
                
                // 4. 动画播放完后，销毁数据
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onCancel()
                }
            }
        }
        .zIndex(100)
    }
}

// MARK: - ViewModifier 封装
struct ToastModifier: ViewModifier {
    @Binding var message: String?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            // 这里不需要 .transition，因为动画由 ToastView 内部的 .offset 控制
            if let msg = message {
                ToastView(message: msg) {
                    message = nil
                }
            }
        }
    }
}

// MARK: - View 扩展方法
extension View {
    func toast(message: Binding<String?>) -> some View {
        self.modifier(ToastModifier(message: message))
    }
}

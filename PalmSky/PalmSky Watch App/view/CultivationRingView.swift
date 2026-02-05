import SwiftUI

struct CultivationRingView: View {
    // MARK: - 参数
    let ringSize: CGFloat
    let progress: Double
    let primaryColor: Color
    let gradientColors: [Color]
    let isAscended: Bool // 满级状态
    let animateAscend: Bool
    
    // MARK: - 动态配置 (核心修改)
    // 满级时：0.0 ~ 1.0 (全圆)
    // 未满级：0.16 ~ 0.84 (底部缺口)
    private var startTrim: Double { isAscended ? 0.0 : 0.16 }
    private var endTrim: Double   { isAscended ? 1.0 : 0.84 }
    
    // 有效弧度长度
    private var arcLength: Double { endTrim - startTrim }
    
    // 动画配置：慢速、庄重
    private let closeAnimation = Animation.easeInOut(duration: 3.0)
    
 
    var body: some View {
        ZStack {
            // 1. 轨道 (暗色背景)
            Circle()
                .trim(from: CGFloat(startTrim), to: CGFloat(endTrim))
                .stroke(
                    Color.white.opacity(0.12),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(90))
                .frame(width: ringSize, height: ringSize)
                // ✨ 动画：轨道缓慢合拢
                .animation(animateAscend ? closeAnimation : nil, value: isAscended)
            
           
            let ringGradient = AngularGradient(
                gradient: Gradient(
                    colors: isAscended
                        // 满级：同色渐变（看起来就是纯色，但类型没变）
                        ? [primaryColor, primaryColor]
                        // 未满级：灵气流转
                        : gradientColors
                ),
                center: .center,
                startAngle: .degrees(90),
                endAngle: .degrees(360)
            )
          
            // 3. 进度条 (亮色填充)
            Circle()
                .trim(from: CGFloat(startTrim), to: CGFloat(startTrim + (arcLength * progress)))
                .stroke(
                
                  ringGradient,
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(90))
                // 满级时增加发光强度
                .shadow(color: primaryColor.opacity(isAscended ? 0.8 : 0.6), radius: isAscended ? 15 : 8)
                .frame(width: ringSize, height: ringSize)
                // ✨ 动画：进度条缓慢合拢
                .animation(animateAscend ? closeAnimation : nil, value: isAscended)
                // 进度本身的动画
                .animation(.spring(response: 0.5), value: progress)
          
          
            // 3. 进度光点 (流星头)
//            if progress > 0 && !isAscended {
//                Circle()
//                    .fill(Color.white)
//                    .frame(width: 6, height: 6)
//                    .shadow(color: .white, radius: 4)
//                    .offset(x: ringSize / 2)
//                    // ⚠️ 注意：这里的 startTrim 和 arcLength 会随动画动态变化，
//                    // 从而保证光点在圆环合拢时也能平滑移动到正确位置
//                    .rotationEffect(.degrees(92.0 + (360.0 * (startTrim + arcLength * progress))))
//                    // ✨ 动画：光点位置跟随圆环变化
//                    .animation(closeAnimation, value: isAscended)
//                    // 进度本身的动画保持原样
//                    .animation(.spring(response: 0.5), value: progress)
//                   
//            }
            
        }
    }
}

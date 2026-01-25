import SwiftUI

struct RealmHeaderView: View {
    // MARK: - 参数
    let realmName: String   // 境界名 (如: 胎息)
    let layerName: String   // 层级名 (如: 五层)
    let primaryColor: Color // 主题色
    
    var body: some View {
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        // 1. 境界名称 (大标题)
        Text(realmName)
          .font(XiuxianFont.realmTitle)
          .foregroundColor(.white)
        // 文字发光效果
          .shadow(color: primaryColor.opacity(0.8), radius: 8)
        // ⬇️ 修改2：核心适配逻辑
          .lineLimit(1)            // 强制不换行
          .minimumScaleFactor(0.5) // 空间不够时，允许缩小到 13pt
          .layoutPriority(1)       // 如果空间挤，优先压缩这个 Text
        
        // 2. Lv 胶囊 (徽章)
        Text(layerName)
          .font(XiuxianFont.badge)
          .foregroundColor(.white)
          .padding(.horizontal, 5)
          .padding(.vertical, 2)
          .background(primaryColor.opacity(0.25)) // 半透明背景
          .clipShape(Capsule())
        // 稍微往上提一点，视觉上与大标题居中对齐
          .offset(y: -2)
      }
      .padding(.top, 20) // 保持原有的顶部间距
    }
}

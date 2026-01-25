import SwiftUI

struct BaguaContainerView: View {
   @EnvironmentObject var gameManager: GameManager

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            // 保持 1:1 宽高比，以宽度为基准
            let size = w
            
            ZStack {
                // 1. 八卦背景图
                Image("Bagua") // 确保 Assets 中有这个图片
                    .renderingMode(.template) // ✨ 关键：允许修改颜色
                    .resizable()
                    .aspectRatio(contentMode: .fill) // 用户之前改成了 fill，保留
                    .frame(width: size, height: size)
                    .foregroundColor(RealmColor.primaryLastColor(for: gameManager.player.level).opacity(0.8))
                    // 稍微旋转一点增加神秘感？或者保持正位
                    .rotationEffect(.degrees(0))
                    
                // 2. 嵌入 Mini Game
                // 游戏区域大概占八卦图中心的一定比例 (比如 60%)
                // 根据实际图片调整
                let gameSize = size * 0.60
                
                RootPagerView()
                    .frame(width: gameSize, height: gameSize)
                    .clipShape(Circle()) // 裁剪成圆形，契合八卦中心
                   
            }
            .frame(width: w, height: w)
            // 居中显示
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .padding(.horizontal, 10) // 左右留白
    }
}

#Preview {
    BaguaContainerView()
        .environmentObject(GameManager.shared)
        .preferredColorScheme(.dark)
}

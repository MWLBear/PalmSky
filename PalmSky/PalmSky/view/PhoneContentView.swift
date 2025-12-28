import SwiftUI

struct PhoneContentView: View {
    // 1. 监听同步管理器 (不再读取本地 AppStorage)
    @StateObject private var syncManager = SkySyncManager.shared
    @Environment(\.colorScheme) private var colorScheme

    // 快捷获取 player 对象
    var player: Player? {
        syncManager.syncedData 
    }
    
    // 2. 动态计算属性 (依赖共享的 GameLevelManager)
    var realmName: String {
        guard let p = player else { return "筑基" }
        // 确保 GameLevelManager 对 iOS Target 可见
        return GameLevelManager.shared.stageName(for: p.level, reincarnation: p.reincarnationCount)
    }
    
    var layerName: String {
        guard let p = player else { return "一层" }
        return GameLevelManager.shared.layerName(for: p.level)
    }
  
    var realmColor: Color {
      guard let p = player else { return Color(hex: "89A37B") }
      if colorScheme == .light {
        return RealmColor.primaryFirstColor(for: p.level)
      } else {
        return RealmColor.primaryLastColor(for: p.level)
      }
    }
    
   @State private var showReference = false

  
    var body: some View {
        NavigationStack {
          ZStack {
                // 背景：深色修仙风
                  List {
                    // 顶部大卡片：当前境界
                    Section {
                      VStack(alignment: .leading, spacing: 8) {
                        Text("当前境界")
                          .font(.caption)
                          .foregroundColor(.gray)
                        
                        HStack {
                          Text(realmName)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(realmColor)
                         
                          Text(layerName)
                            .font(.subheadline.weight(.semibold))
                            .fontDesign(.rounded)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(realmColor.opacity(0.25))
                            .shadow(
                                color: Color.black.opacity(0.15),
                                radius: 2,
                                x: 0,
                                y: 1
                            )
                            .clipShape(Capsule())
                            .offset(y: 2)
                        }
                      }
                      .padding(.vertical, 10)
                    } header: {
                      Text("道途总览")
                    }
                    
                    // 详细数据
                    Section {
                      // 灵气
                      DouStatRow(
                        title: "当前灵气",
                        value: player?.currentQi.xiuxianString ?? "0", // 使用扩展格式化
                        systemImage: "bolt.circle.fill",
                        iconColor: .blue
                      )
                      
                      // 轮回次数
                      DouStatRow(
                        title: "轮回世数",
                        value: "\((player?.reincarnationCount ?? 0) + 1) 世",
                        systemImage: "arrow.triangle.2.circlepath.circle.fill",
                        iconColor: .orange
                      )
                      
                      // ✨ 新增：总点击数
                      DouStatRow(
                        title: "苦修点击",
                        // 使用 formatted() 会自动加上千分位逗号 (如 12,345)
                        value: "\(player?.click.formatted() ?? "0") 次",
                        systemImage: "hand.tap.fill",
                        iconColor: .red // 红色代表体修/苦力
                      )
                      
                      // 护身符
                      DouStatRow(
                        title: "护身符",
                        value: "\(player?.items.protectCharm ?? 0) 枚",
                        systemImage: "shield.fill",
                        iconColor: .yellow
                      )
                      
                      // 等级 (数字)
                      DouStatRow(
                        title: "累计等级",
                        value: "Lv.\(player?.level ?? 1)",
                        systemImage: "chart.bar.fill",
                        iconColor: .purple
                      )
                    } header: {
                      Text("修行明细")
                    }
                                        
                    // 底部提示
                    VStack(spacing: 4) {
                        Text(NSLocalizedString("career_game_data_source", comment: "游戏数据来源"))
                          .font(.footnote.weight(.semibold))
                          .foregroundColor(.primary)
                          .multilineTextAlignment(.center)
                          .lineLimit(nil)
                        
                        Text(NSLocalizedString("career_play_on_watch", comment: "提示用户在手表上游玩"))
                          .font(.caption)
                          .foregroundColor(.secondary)
                          .multilineTextAlignment(.center)
                          .lineLimit(nil)
                      }
                      .frame(maxWidth: .infinity)
                      .listRowInsets(EdgeInsets())
                      .listRowBackground(Color.clear)
                  }
                }
            }
            .navigationTitle("修行生涯")
            .listStyle(.insetGrouped) // 保留系统分组样式
          // ✨ 新增：右上角工具栏按钮
            .toolbar {
              ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                  showReference = true
                }) {
                  // 使用书本图标，代表图鉴/知识
                  Image(systemName: "book.closed.fill")
                    .foregroundColor(.primary)
                }
              }
            }
          // ✨ 新增：弹窗 Sheet
            .sheet(isPresented: $showReference) {
              RealmReferenceView()
                .presentationDetents([.medium, .large]) // 支持半屏和全屏拖动
            }
          
        }
    }
//}

// MARK: - 辅助视图：数据行
struct DouStatRow: View {
    let title: String
    let value: String
    let systemImage: String
    let iconColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            Text(title)
                .foregroundColor(.primary.opacity(0.9))
            
            Spacer()
            
            Text(value)
                .font(.system(.body, design: .monospaced)) // 数字用等宽字体
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

// 预览需要模拟数据
struct PhoneContentView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneContentView()
    }
}

extension String {
    var cn: LocalizedStringKey {
        LocalizedStringKey(self)
    }
}

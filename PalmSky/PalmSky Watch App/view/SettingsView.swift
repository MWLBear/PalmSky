import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    @State private var showResetAlert = false
  // ✨ 新增：接收父视图传来的页码绑定
    @Binding var currentTab: Int
  
    // 动态获取主题色 (跟随境界变化)
    var themeColor: Color {
        let colors = RealmColor.gradient(for: gameManager.player.level)
        return colors.last ?? .green
    }
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Section 1: 道途信息
                Section {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(themeColor)
                            .font(.title3)
                        Text("当前境界")
                        Spacer()
                        Text(gameManager.getRealmShort())
                            .foregroundColor(.white)
                            .bold()
                    }
                    
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(themeColor)
                            .font(.title3)
                        Text("当前灵气")
                        Spacer()
                        Text(gameManager.player.currentQi.xiuxianString)
                            .foregroundColor(.gray)
                    }
                  
                  // 护身符
                  HStack {
                    Image(systemName: "shield.fill")
                      .foregroundColor(themeColor)
                    Text("护身符")
                    Spacer()
                    Text("\(gameManager.player.items.protectCharm)")
                      .foregroundColor(.gray)
                  }
                  
                } header: {
                    Text("道途信息")
                        .foregroundColor(themeColor)
                }
                
                // MARK: - Section 2: 数值详情 (补回来的部分)
                Section {
                    // 点击收益
                    HStack {
                        Text("点击收益")
                        Spacer()
                        Text("+\(gameManager.getCurrentTapGain().xiuxianString)")
                            .foregroundColor(themeColor) // 跟随主题色
                    }
                    
                    // 自动收益
                    HStack {
                        Text("自动收益/秒")
                        Spacer()
                        // 使用带Buff计算的真实数值
                        Text("+\(gameManager.getCurrentAutoGain().xiuxianString)")
                            .foregroundColor(themeColor)
                    }
                    
                    // 成功率
                    HStack {
                        Text("突破成功率")
                        Spacer()
                        let rate = GameLevelManager.shared.breakSuccess(level: gameManager.player.level)
                        Text("\(Int(rate * 100))%")
                            // 成功率颜色独立逻辑：高绿，中黄，低橙
                            .foregroundColor(rate >= 0.8 ? .green : (rate >= 0.6 ? .yellow : .orange))
                    }
                } header: {
                    Text("数值详情")
                        .foregroundColor(themeColor)
                }
                
                // MARK: - Section 3: 仙府设置
                Section {
                  
                  Toggle(isOn: Binding(
                      get: { gameManager.player.settings.soundEnabled },
                      set: { _ in gameManager.toggleSound() }
                  )) {
                      Label {
                          Text("声音")
                      } icon: {
                          Image(systemName: "speaker.wave.2.fill")
                              .foregroundColor(themeColor)
                      }
                  }
                  .tint(themeColor)
                  
                    Toggle(isOn: Binding(
                        get: { gameManager.player.settings.hapticEnabled },
                        set: { _ in gameManager.toggleHaptic() }
                    )) {
                        Label {
                            Text("震动反馈")
                        } icon: {
                            Image(systemName: "waveform.circle.fill")
                                .foregroundColor(themeColor)
                        }
                    }
                    .tint(themeColor)
                    
                    Toggle(isOn: Binding(
                        get: { gameManager.player.settings.autoGainEnabled },
                        set: { _ in gameManager.toggleAutoGain() }
                    )) {
                        Label {
                            Text("自动修炼")
                        } icon: {
                            Image(systemName: "sparkles")
                                .foregroundColor(themeColor)
                        }
                    }
                    .tint(themeColor)
                } header: {
                    Text("仙府设置")
                        .foregroundColor(themeColor)
                }
                
                // MARK: - Section 4: 危险操作
                Section {
                  if gameManager.player.level >= GameConstants.MAX_LEVEL {
                      // 🌟 满级状态：显示“转世重修” (保留历史)
                      Button {
                        showResetAlert = true
                      } label: {
                        HStack {
                          Spacer()
                          Label("转世重修", systemImage: "arrow.triangle.2.circlepath")
                            .foregroundColor(.yellow) // 金色，代表神圣
                            .bold()
                          Spacer()
                        }
                      }
                  } else {
                    
                      Button(role: .destructive) {
                        showResetAlert = true
                      } label: {
                        Label("散尽修为 (删档)", systemImage: "trash.fill")
                          .foregroundColor(.red)
                      }
                    
                  }
                } footer: {
                  VStack(spacing: 5) {
                         Text("掌上修仙 \(appVersion)")
                             .font(.footnote)
                             .foregroundColor(.gray.opacity(0.5))

                         Text("此道漫长，不必急行。")
                             .font(.footnote)
                             .foregroundColor(.white.opacity(0.35))
                     }
                     .frame(maxWidth: .infinity)
                     .padding(.top, 6)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden) // 移除默认背景
            .background(Color.black)      // 使用纯黑背景
              .alert(isPresented: $showResetAlert) {
                if gameManager.isAscended {
                  // 满级转世
                  return Alert(
                    title: Text("开启新轮回？"),
                    message: Text("你将保留此生记录，回到凡人境界重新修行。"),
                    primaryButton: .destructive(Text("转世重修")) {
                
                      // 直接调用轮回逻辑
                      gameManager.reincarnate()
                      // 弹个震动反馈
                      HapticManager.shared.playIfEnabled(.success)

                      // 关闭设置页，回到主页
                      withAnimation {
                        currentTab = 0
                      }
                      
                    },
                    secondaryButton: .cancel(Text("取消"))
                  )
                } else {
                  // 未满级重置
                  return Alert(
                    title: Text("确定删档重来？"),
                    message: Text("当前所有修为将化为乌有，此操作不可撤销！"),
                    primaryButton: .destructive(Text("确认重置")) {
                      gameManager.resetGame()
                      WKInterfaceDevice.current().play(.directionUp)
                      
                      // 🚀 核心修改：切回第 0 页 (主页)
                      withAnimation {
                        currentTab = 0
                      }
                    },
                    secondaryButton: .default(Text("取消"))
                  )
                }
              }
          }
      
    }
  
  
  private var appVersion: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let _ = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    return " v\(version)"
  }
  
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
      SettingsView(currentTab: .constant(1))
    }
}

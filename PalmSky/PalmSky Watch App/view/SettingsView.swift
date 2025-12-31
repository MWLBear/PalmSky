import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var gameManager: GameManager
    @ObservedObject var purchaseManager = PurchaseManager.shared // ✨ 监听购买状态
    @Environment(\.dismiss) var dismiss
    @State private var showResetAlert = false
    @State private var showPaywall = false // ✨ 新增：控制付费墙显示
  
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
              
                // MARK: - ✨ 机缘 (步数炼化)
                Section(header: Text("炼体").foregroundColor(themeColor)) {
                  // ✅ 直接调用封装好的组件
                  StepRefineRow(themeColor: themeColor) { gain in
                      // 1. 触发主页动画信号
                      gameManager.triggerRefineAnimation(amount: gain)
                      
                      // 2. 切回主页 (延迟一点点，让视觉连贯)
                      withAnimation {
                          currentTab = 0
                      }
                  }
                }
              
                // MARK: - Section 1: 道途信息
                Section {
                    // 🌟 老玩家专属标识
                    if purchaseManager.isLegacyUser {
                        HStack {
                            Image(systemName: "crown.fill") // 皇冠图标
                                .foregroundColor(.yellow)
                          
                            Text("开天道祖") // 霸气的称号
                                .foregroundColor(.yellow)
                                .bold()
                                .shadow(color: .orange.opacity(0.5), radius: 4) // 自带光晕
                      
                          Spacer()
                        }
                    }

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
                      .font(.title3)
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
                
              
              // MARK: - ✨ 新增 Section: 飞升契约 (内购专区)
                Section {
                  
                  // 1. 解锁按钮 (仅未付费时显示)
                  if !purchaseManager.hasAccess {
                    Button {
                      showPaywall = true
                      HapticManager.shared.playIfEnabled(.click)
                    } label: {
                      HStack {
                        // 图标
                        Image(systemName: "lock.open.fill")
                          .foregroundColor(themeColor)
                          .font(.title3)
                          
                        // 文字
                        VStack(alignment: .leading, spacing: 2) {
                          Text("解锁完整版")
                            .font(.headline)
                            .foregroundColor(.white)
                          
                        }
                        
                        Spacer()
                        
                        // 箭头
                        Image(systemName: "chevron.right")
                          .font(.caption)
                          .foregroundColor(.gray)
                      }
                      .padding(.vertical, 4)
                    }
                  }
                  
                  // 2. 恢复购买按钮 (移到这里)
                  Button {
                    Task {
                      HapticManager.shared.playIfEnabled(.click)
                      // 调用恢复逻辑
                      _ = try? await PurchaseManager.shared.restorePurchases()
                      HapticManager.shared.playIfEnabled(.success)
                    }
                  } label: {
                    Label {
                      Text("恢复契约")
                    } icon: {
                      Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(themeColor)
                    }
                  }
                  
                } header: {
                  Text("飞升契约") // 霸气的 Section 标题
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
          // ✨ 挂载付费墙弹窗
            .sheet(isPresented: $showPaywall) {
              PaywallView()
            }
          
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

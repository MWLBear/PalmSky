import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var gameManager: GameManager
    @ObservedObject var purchaseManager = PurchaseManager.shared // ✨ 监听购买状态
    @Environment(\.dismiss) var dismiss
    @State private var showResetAlert = false
    @State private var showPaywall = false // ✨ 新增：控制付费墙显示
    @State private var showLeaderboard = false
  
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
                Section(header: Text(NSLocalizedString("watch_settings_section_refine", comment: "")).foregroundColor(themeColor),
                        footer: Text(NSLocalizedString("watch_settings_refine_footer", comment: ""))
                        .foregroundColor (.secondary)
                ) {
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
                  // ✨ 身份铭牌 (仅 VIP 显示)
                    if purchaseManager.hasAccess {
                      HStack {
                        // 图标区分：老玩家用皇冠，新VIP用勋章
                        Image(systemName: purchaseManager.isLegacyUser ? "crown.fill" : "checkmark.seal.fill")
                          .foregroundColor(.yellow)
                          
                        // 称号区分
                        if purchaseManager.isLegacyUser {
                          // 🌟 老玩家专属
                          Text(NSLocalizedString("watch_settings_legacy_title", comment: ""))
                            .foregroundColor(.yellow)
                            .bold()
                            .shadow(color: .orange.opacity(0.8), radius: 5) // 强光晕
                        
                          
                        } else {
                          // 💰 普通付费玩家 (对应飞升契约)
                          Text(NSLocalizedString("watch_settings_contract_title", comment: ""))
                            .foregroundColor(.yellow)
                            .bold()
                            .shadow(color: .yellow.opacity(0.3), radius: 2) // 弱光晕
                        }
                      }
                    }

                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(themeColor)
                            .font(.title3)
                        Text(NSLocalizedString("watch_settings_current_realm", comment: ""))
                        Spacer()
                        Text(gameManager.getRealmShort())
                            .foregroundColor(.white)
                            .bold()
                    }
                    
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(themeColor)
                            .font(.title3)
                        Text(NSLocalizedString("watch_settings_current_qi", comment: ""))
                        Spacer()
                        Text(gameManager.player.currentQi.xiuxianString)
                            .foregroundColor(.gray)
                    }
                  
                  // 护身符
                  HStack {
                    Image(systemName: "shield.fill")
                      .foregroundColor(themeColor)
                      .font(.title3)
                    Text(NSLocalizedString("watch_settings_protect_charm", comment: ""))
                    Spacer()
                    Text("\(gameManager.player.items.protectCharm)")
                      .foregroundColor(.gray)
                  }
                  
                 #if os(watchOS)
                  HStack {
                    Image(systemName: "trophy.fill")
                      .foregroundColor(themeColor)
                      .font(.title3)
                    Text(NSLocalizedString("watch_settings_leaderboard", comment: ""))
                      .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                      .font(.caption)
                      .foregroundColor(.gray)
                  }
                  .contentShape(Rectangle())
                  .onTapGesture {
                    showLeaderboard = true
                  }
                  #endif
                  
                } header: {
                    Text(NSLocalizedString("watch_settings_section_journey_info", comment: ""))
                        .foregroundColor(themeColor)
                } footer: {
                  // 🔥 新增：如果是老玩家，显示解释文案
                  if purchaseManager.isLegacyUser {
                      Text(NSLocalizedString("watch_settings_legacy_footer", comment: ""))
                          .foregroundColor(.yellow.opacity(0.8)) // 金色小字
                  }
              }
                
                // MARK: - Section 2: 数值详情 (补回来的部分)
                Section {
                    // 点击收益
                    HStack {
                        Text(NSLocalizedString("watch_settings_tap_gain", comment: ""))
                        Spacer()
                        Text("+\(gameManager.getCurrentTapGain().xiuxianString)")
                            .foregroundColor(themeColor) // 跟随主题色
                    }
                    
                    // 自动收益
                    HStack {
                        Text(NSLocalizedString("watch_settings_auto_gain", comment: ""))
                        Spacer()
                        // 使用带Buff计算的真实数值
                        Text("+\(gameManager.getCurrentAutoGain().xiuxianString)")
                            .foregroundColor(themeColor)
                    }
                    
                    // 成功率
                    HStack {
                        Text(NSLocalizedString("watch_settings_break_success_rate", comment: ""))
                        Spacer()
                        let rate = GameLevelManager.shared.breakSuccess(level: gameManager.player.level)
                        Text("\(Int(rate * 100))%")
                            // 成功率颜色独立逻辑：高绿，中黄，低橙
                            .foregroundColor(rate >= 0.8 ? .green : (rate >= 0.6 ? .yellow : .orange))
                    }
                } header: {
                    Text(NSLocalizedString("watch_settings_section_stats", comment: ""))
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
                          Text(NSLocalizedString("watch_settings_unlock_full", comment: ""))
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
                      Text(NSLocalizedString("watch_settings_restore_contract", comment: ""))
                        .foregroundColor(.white)
                    } icon: {
                      Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(themeColor)
                    }
                  }
                  
                } header: {
                  Text(NSLocalizedString("watch_settings_contract_title", comment: "")) // 霸气的 Section 标题
                    .foregroundColor(themeColor)
                }
              
                // MARK: - Section 3: 仙府设置
                Section {
                  
                  Toggle(isOn: Binding(
                      get: { gameManager.player.settings.soundEnabled },
                      set: { _ in gameManager.toggleSound() }
                  )) {
                      Label {
                          Text(NSLocalizedString("watch_settings_sound", comment: ""))
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
                            Text(NSLocalizedString("watch_settings_haptic_feedback", comment: ""))
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
                            Text(NSLocalizedString("watch_settings_auto_cultivate", comment: ""))
                        } icon: {
                            Image(systemName: "sparkles")
                                .foregroundColor(themeColor)
                        }
                    }
                    .tint(themeColor)
                    
                    // ✨ VIP 专属：自动冲关
                    if purchaseManager.hasAccess {
                        Toggle(isOn: Binding(
                            get: { gameManager.player.settings.autoBreakthrough },
                            set: { gameManager.toggleAutoBreakthrough($0) }
                        )) {
                            Label {
                                Text(NSLocalizedString("watch_settings_auto_breakthrough", comment: ""))
                                .foregroundColor(.white)
                            } icon: {
                                Image(systemName: "bolt.horizontal.circle.fill")
                                    .foregroundColor(themeColor)
                            }
                        }
                        .tint(themeColor)
                    } else {
                   
                        Button {
                            showPaywall = true
                            HapticManager.shared.playIfEnabled(.click)
                        } label: {
                            HStack {
                                Label {
                                    Text(NSLocalizedString("watch_settings_auto_breakthrough", comment: ""))
                                    .foregroundColor(.white)

                                } icon: {
                                    Image(systemName: "bolt.horizontal.circle.fill")
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "lock.fill")
                                    //.font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                } header: {
                    Text(NSLocalizedString("watch_settings_section_cave", comment: ""))
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
                          Label(NSLocalizedString("watch_settings_reincarnate", comment: ""), systemImage: "arrow.triangle.2.circlepath")
                            .foregroundColor(.yellow) // 金色，代表神圣
                            .bold()
                          Spacer()
                        }
                      }
                  } else {
                    
                      Button(role: .destructive) {
                        showResetAlert = true
                      } label: {
                        Label(NSLocalizedString("watch_settings_reset_game", comment: ""), systemImage: "trash.fill")
                          .foregroundColor(.red)
                      }
                    
                  }
                } footer: {
                  VStack(spacing: 5) {
                         Text(String(format: NSLocalizedString("watch_settings_app_name_format", comment: ""), appVersion))
                             .font(.footnote)
                             .foregroundColor(.gray.opacity(0.5))

                         Text(NSLocalizedString("watch_settings_footer_quote", comment: ""))
                             .font(.footnote)
                             .foregroundColor(.white.opacity(0.35))
                     }
                     .frame(maxWidth: .infinity)
                     .padding(.top, 6)
                }
            }
            .navigationTitle(NSLocalizedString("settings_nav_title", comment: ""))
          // ✨ 挂载付费墙弹窗
            .sheet(isPresented: $showPaywall) {
              PaywallView()
            }
            .sheet(isPresented: $showLeaderboard) {
              LeaderboardListView()
            }
          
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden) // 移除默认背景
            .background(Color.black)      // 使用纯黑背景
              .alert(isPresented: $showResetAlert) {
                if gameManager.isAscended {
                  // 满级转世
                  return Alert(
                    title: Text(NSLocalizedString("watch_settings_alert_new_cycle_title", comment: "")),
                    message: Text(NSLocalizedString("watch_settings_alert_new_cycle_message", comment: "")),
                    primaryButton: .destructive(Text(NSLocalizedString("watch_settings_reincarnate", comment: ""))) {
                
                      // 直接调用轮回逻辑
                      gameManager.reincarnate()
                      // 弹个震动反馈
                      HapticManager.shared.playIfEnabled(.success)

                      // 关闭设置页，回到主页
                      withAnimation {
                        currentTab = 0
                      }
                      
                    },
                    secondaryButton: .cancel(Text(NSLocalizedString("watch_common_cancel", comment: "")))
                  )
                } else {
                  // 未满级重置
                  return Alert(
                    title: Text(NSLocalizedString("watch_settings_alert_reset_title", comment: "")),
                    message: Text(NSLocalizedString("watch_settings_alert_reset_message", comment: "")),
                    primaryButton: .destructive(Text(NSLocalizedString("watch_settings_alert_reset_confirm", comment: ""))) {
                      gameManager.resetGame()
                      HapticManager.shared.play(.directionUp)
                      // 🚀 核心修改：切回第 0 页 (主页)
                      withAnimation {
                        currentTab = 0
                      }
                    },
                    secondaryButton: .default(Text(NSLocalizedString("watch_common_cancel", comment: "")))
                  )
                }
              }
          }
      
    }
  
  
  private var appVersion: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let _ = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    return "v\(version)"
  }
  
}

// MARK: - Preview
//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//      SettingsView(currentTab: .constant(1))
//    }
//}

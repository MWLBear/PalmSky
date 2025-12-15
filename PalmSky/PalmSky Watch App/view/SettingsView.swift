import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    @State private var showResetAlert = false
    
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
                        Text("+\(GameLevelManager.shared.tapGain(level: gameManager.player.level).xiuxianString)")
                            .foregroundColor(themeColor) // 跟随主题色
                    }
                    
                    // 自动收益
                    HStack {
                        Text("自动收益/秒")
                        Spacer()
                        // 使用带Buff计算的真实数值
                        Text("+\(GameManager.shared.getCurrentAutoGain().xiuxianString)")
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
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("散尽修为 (删档)", systemImage: "trash.fill")
                            .foregroundColor(.red)
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
            .alert("确定重修？", isPresented: $showResetAlert) {
                Button("取消", role: .cancel) { }
                Button("确认重置", role: .destructive) {
                    gameManager.resetGame()
                    dismiss()
                }
            } message: {
                Text("当前所有修为将化为乌有，此操作不可撤销。")
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
        SettingsView()
    }
}

import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @StateObject private var gameManager = GameManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showResetAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.2, green: 0.1, blue: 0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Game info section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("修炼进度")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("当前境界:")
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Text(gameManager.getCurrentRealm())
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Text("当前灵气:")
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Text(String(format: "%.0f", gameManager.player.currentQi))
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Text("护身符:")
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Text("\(gameManager.player.items.protectCharm)")
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                }
                            }
                            .font(.system(size: 13))
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                            .padding(.vertical, 4)
                        
                        // Settings section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("设置")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                            
                            // Haptic toggle
                            Toggle(isOn: Binding(
                                get: { gameManager.player.settings.hapticEnabled },
                                set: { _ in gameManager.toggleHaptic() }
                            )) {
                                HStack(spacing: 8) {
                                    Image(systemName: "waveform")
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("震动反馈")
                                        .foregroundColor(.white)
                                }
                            }
                            .tint(.blue)
                            
                            // Auto gain toggle
                            Toggle(isOn: Binding(
                                get: { gameManager.player.settings.autoGainEnabled },
                                set: { _ in gameManager.toggleAutoGain() }
                            )) {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("自动增长")
                                        .foregroundColor(.white)
                                }
                            }
                            .tint(.blue)
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                            .padding(.vertical, 4)
                        
                        // Game stats
                        VStack(alignment: .leading, spacing: 8) {
                            Text("数值详情")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("点击收益:")
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Text(String(format: "+%.1f", GameLevelManager.shared.tapGain(level: gameManager.player.level)))
                                        .foregroundColor(.green)
                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Text("自动收益/秒:")
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Text(String(format: "+%.2f", GameLevelManager.shared.autoGain(level: gameManager.player.level)))
                                        .foregroundColor(.green)
                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Text("突破成功率:")
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    let rate = GameLevelManager.shared.breakSuccess(level: gameManager.player.level)
                                    Text(String(format: "%.0f%%", rate * 100))
                                        .foregroundColor(rate >= 0.8 ? .green : (rate >= 0.7 ? .yellow : .orange))
                                        .fontWeight(.semibold)
                                }
                            }
                            .font(.system(size: 13))
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                            .padding(.vertical, 4)
                        
                        // Reset button
                        Button(action: {
                            showResetAlert = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("重置数据")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(10)
                        }
                        
                        // Version info
                        Text("掌上修仙 v1.0")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                   
//                }
//            }
          
            .toolbar {
                ToolbarItem {
                  Button("完成") {
                      dismiss()
                  }
                  .foregroundColor(.white)
                }
            }
          
            .alert("重置数据", isPresented: $showResetAlert) {
                Button("取消", role: .cancel) { }
                Button("确认重置", role: .destructive) {
                    gameManager.resetGame()
                    dismiss()
                }
            } message: {
                Text("确定要重置所有数据吗？此操作不可撤销。")
            }
        }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

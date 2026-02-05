//
//  ContentView.swift
//  Billiards
//
//  Created by mac on 2025/11/10.
//

import SwiftUI

// MARK: - 1. 主 ContentView (带 TabView)

struct PhoneMianView: View {
    @StateObject private var syncManager = SkySyncManager.shared
    @State private var showGC = false
    @State private var showToast = false

    var body: some View {
        TabView {
            NavigationView {
              PhoneContentView()
    
            }
            .tabItem {
                VStack {
                    Image(systemName: "person.crop.rectangle.stack.fill")
                    Text(NSLocalizedString("tab_career", comment: ""))

                }
            }

            NavigationView {
              LeaderboardListView()
                  .navigationTitle(NSLocalizedString("leaderboard_nav_title", comment: ""))
                  .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                    
                      Button {
                        if !GameCenterManager.shared.isAuthenticated {
                          // 触发登录界面（系统会在需要时弹出）
                          GameCenterManager.shared.setupAuthenticationHandler()
                          showGC = true
                          return
                        }
                        
                        // 已授权，直接打开 GC 面板
                        showGC = true
                      } label: {
                        // 按钮内容
                        Image(systemName: "gamecontroller.fill")
                          .imageScale(.large)
                          .foregroundColor(.primary)
                      }
                      
                      
                    }
                      
                  }
                  .onAppear {
                    // 确保 Game Center 已尝试认证（初始化里也有，但这里安全冗余一次）
                    _ = GameCenterManager.shared
                  }
                  .fullScreenCover(isPresented: $showGC) {
                      GameCenterViewController()
                          .ignoresSafeArea()
                  }


            }
            .tabItem {
                VStack {
                    Image(systemName: "trophy.fill")
                  Text(NSLocalizedString("tab_leaderboard", comment: ""))

                }
            }

            NavigationView {
                PhoneSettingsView()
                .navigationTitle(NSLocalizedString("settings_nav_title", comment: ""))

            }
            .tabItem {
                VStack {
                    Image(systemName: "gearshape.fill")
                    Text(NSLocalizedString("tab_settings", comment: ""))

                }
            }
        }
        .toast(NSLocalizedString("GameCenterTip", comment: "GameCenterTip"), isPresented: $showToast)
      
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            
            // 背景色自适配
            appearance.backgroundColor = UIColor { trait in
                switch trait.userInterfaceStyle {
                case .dark:
                    return UIColor.systemGray6.withAlphaComponent(0.8) // 暗色半透明灰
                default:
                    return UIColor.systemBackground.withAlphaComponent(0.95) // 亮色背景
                }
            }
            
            // 选中和未选中颜色
            let selectedColor = UIColor.label           // 系统主文本色
            let normalColor = UIColor.secondaryLabel   // 系统次文本色
            
            // 配置 stackedLayoutAppearance（普通布局）
            appearance.stackedLayoutAppearance.normal.iconColor = normalColor
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
            
            appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
            
            // 应用到 TabBar
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
      
        .onReceive(syncManager.$syncedData) { _ in
            // 当手表同步数据更新时，你可以刷新 UI 或做其他操作
        }
    }
}

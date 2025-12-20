//
//  AppTheme.swift
//  PalmSky
//
//  Created by mac on 12/19/25.
//

import SwiftUI
// 九天颜色白色有问题. 暂时不用这个了
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "Auto"  // 跟随系统
    case dark = "Dark"    // 强制深色 (修仙风)
    case light = "Light"  // 强制浅色
    
    var id: String { self.rawValue }
    
    // 显示名称
    var displayName: String {
        switch self {
        case .system: return NSLocalizedString("theme_auto", comment: "自动")
        case .dark: return NSLocalizedString("theme_dark", comment: "深色")
        case .light: return NSLocalizedString("theme_light", comment: "浅色")
        }
    }
    
    // 转换为 SwiftUI 的 ColorScheme?
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}


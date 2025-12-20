//
//  RealmColor.swift
//  PalmSky Watch App
//
//  Created by mac on 12/12/25.
//

import Foundation
import SwiftUI

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Realm Color Logic
struct RealmColor {
    // 获取当前境界的光效渐变
    static func gradient(for level: Int) -> [Color] {
        // level 1..144 -> stage 1..16
        // 公式：((level - 1) / 9) + 1
        let stage = ((level - 1) / 9) + 1
        return colors(for: stage)
    }
    
  /// 前缀 / 文本用的主色（取渐变第一色）
    static func primaryLastColor(for level: Int) -> Color {
      gradient(for: level).last ?? .primary
    }
    
    static func primaryFirstColor(for level: Int) -> Color {
      gradient(for: level).first ?? .primary
    }
  
    private static func colors(for stage: Int) -> [Color] {
        switch stage {
        case 1: return [Color(hex: "506042"), Color(hex: "89A37B")] // 筑基
        case 2: return [Color(hex: "4D597A"), Color(hex: "8FA3D6")] // 开光
        case 3: return [Color(hex: "6B4E73"), Color(hex: "B98AC6")]
        case 4: return [Color(hex: "3A6F6B"), Color(hex: "7ED9C9")]
        case 5: return [Color(hex: "8C6D2E"), Color(hex: "E6C76B")] // 金丹 (金)
        case 6: return [Color(hex: "6A4CB3"), Color(hex: "B89AF4")]
        case 7: return [Color(hex: "3D8CB9"), Color(hex: "7FD4FF")]
        case 8: return [Color(hex: "A34357"), Color(hex: "FF9DAE")]
        case 9: return [Color(hex: "3F7387"), Color(hex: "84D0E9")]
        case 10: return [Color(hex: "B557FF"), Color(hex: "E8C6FF")]
        case 11: return [Color(hex: "F7C542"), Color(hex: "FFEBA4")] // 渡劫 (金亮)
        case 12: return [Color(hex: "46CA92"), Color(hex: "B9FFE0")]
        case 13: return [Color(hex: "63D0FF"), Color(hex: "D6F3FF")]
        case 14: return [Color(hex: "FFB84C"), Color(hex: "FFE2AD")]
        case 15: return [Color(hex: "FF7A7A"), Color(hex: "FFC6C6")]
        default: return [Color(hex: "FFFFFF"), Color(hex: "CBE8FF")] // 九天玄仙 (极白)
        }
    }
}

//
//  TaijiSkin.swift
//  PalmSky Watch App
//
//  Created by mac on 12/20/25.
//

import SwiftUI

struct TaijiSkin: Identifiable, Equatable {
    let id: String
    let name: String
    
    // --- 阳面配置 (通常是白的那面) ---
    let yangColors: [Color] // 渐变色数组
    let yangEyeColor: Color // 鱼眼颜色 (通常是阴面的主色)
    
    // --- 阴面配置 (通常是黑的那面) ---
    let yinColors: [Color]  // 渐变色数组
    let yinEyeColor: Color  // 鱼眼颜色 (通常是阳面的主色)
    
    // --- 特效配置 ---
    let glowColor: Color    // 外发光颜色
    let particleColor: Color // 点击时的粒子颜色 (可选，如果不填就用境界色)
    
    // 辅助：生成渐变
    var yangGradient: LinearGradient {
        LinearGradient(colors: yangColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var yinGradient: LinearGradient {
        LinearGradient(colors: yinColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    // MARK: - 预设皮肤库
    
    // 1. 默认皮肤 (经典道韵)
    // 使用微渐变，比纯黑白更有质感
  // 默认皮肤 (微渐变 = 顶级质感)
    static let `default` = TaijiSkin(
      id: "classic",
      name: "道法自然",
      
      // 阳面：纯白 -> 极浅的灰 (模拟光照从左上角射入)
      yangColors: [Color(hex: "FFFFFF"), Color(hex: "E0E0E0")],
      yangEyeColor: .black,
      
      // 阴面：深灰 -> 纯黑 (增加深邃感)
      yinColors: [Color(hex: "2B2B2B"), Color(hex: "000000")],
      yinEyeColor: .white,
      
      // 光晕：纯白
      glowColor: .white,
      particleColor: .white
    )
  
    
    // 2. (预留) 烈火鉴 (火红 + 金)
    static let fire = TaijiSkin(
        id: "fire",
        name: "烈火鉴",
        yangColors: [Color(hex: "FFD700"), Color(hex: "FFA500")], // 金 -> 橙
        yangEyeColor: Color(hex: "8B0000"),
        yinColors: [Color(hex: "8B0000"), Color(hex: "FF4500")],  // 深红 -> 亮红
        yinEyeColor: Color(hex: "FFD700"),
        glowColor: Color(hex: "FF4500"),
        particleColor: Color(hex: "FF4500")
    )
}


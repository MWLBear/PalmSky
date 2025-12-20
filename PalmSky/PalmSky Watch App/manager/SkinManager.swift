//
//  SkinManager.swift
//  PalmSky Watch App
//
//  Created by mac on 12/20/25.
//

import Foundation
import SwiftUI

class SkinManager: ObservableObject {
    static let shared = SkinManager()
    
    @Published var currentSkin: TaijiSkin
    
    private init() {
        // V1 版本逻辑：
        // 这里以后可以从 UserDefaults 读取用户购买/选择的皮肤 ID
        // 目前直接使用默认
         self.currentSkin = .default
    }
    
    // 预留接口：切换皮肤
    func setSkin(_ skin: TaijiSkin) {
        self.currentSkin = skin
        // TODO: Save to UserDefaults
    }
    
    // 预留接口：获取所有可用皮肤
    var availableSkins: [TaijiSkin] {
        return [.default, .fire]
    }
}

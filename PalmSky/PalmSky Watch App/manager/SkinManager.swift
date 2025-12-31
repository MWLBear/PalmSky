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
    
    @Published var currentSkin: TaijiSkin {
        didSet {
            // 持久化当前皮肤的选择
            UserDefaults.standard.set(currentSkin.id, forKey: SkyConstants.UserDefaults.currentSkinID)
        }
    }
    
    private init() {
        // 1. 尝试从缓存读取上次选择的皮肤 ID
        let cachedID = UserDefaults.standard.string(forKey: SkyConstants.UserDefaults.currentSkinID)
        
        // 2. 在可用皮肤中查找对应配置 (找不到则用默认)
        // 注意: 这里暂时不检查权限, 假设缓存的ID肯定是之前通过校验的
        // 如果想更严格, 可以在这里再次 check isPurchased
        if let savedID = cachedID,
           let skin = TaijiSkin.allCases.first(where: { $0.id == savedID }) {
            self.currentSkin = skin
        } else {
            self.currentSkin = .default
        }
    }
    
    // 切换皮肤 (带权限检查)
    func setSkin(_ skin: TaijiSkin) -> Bool {
        // 1. 检查是否需要付费
        if let pid = skin.productID {
            if !PurchaseManager.shared.isPurchased(pid) {
                print("🔒 Skin locked: \(skin.name). Requires product: \(pid)")
                return false
            }
        }
        
        // 2. 有权限，或者免费 -> 切换成功
        self.currentSkin = skin
        print("🎨 Skin changed to: \(skin.name)")
        return true
    }
    
    // 获取所有可用皮肤 (为了方便SwiftUI遍历, 建议 TaijiSkin 遵循 CaseIterable 或者这里手动维护)
    var availableSkins: [TaijiSkin] {
        return TaijiSkin.allCases
    }
}

// 扩展 TaijiSkin 方便遍历
extension TaijiSkin {
    static var allCases: [TaijiSkin] {
        return [.default, .fire]
    }
}

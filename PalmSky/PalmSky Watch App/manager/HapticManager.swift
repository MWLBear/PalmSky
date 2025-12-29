//
//  HapticManager.swift
//  PalmSky Watch App
//
//  Created by mac on 12/14/25.
//

import Foundation
import WatchKit

// MARK: - Haptic Manager
class HapticManager {
    static let shared = HapticManager()
    private init() {}

    
    // ✨ 内部维护开关状态 (默认开启，由 GameManager 同步)
    var isEnabled: Bool = true

    func playIfEnabled(_ type: WKHapticType) {
        if isEnabled {
            play(type)
        }
    }

    func play(_ type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }
}

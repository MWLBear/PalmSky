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

    
    func playIfEnabled(_ type: WKHapticType) {
      if GameManager.shared.player.settings.hapticEnabled {
        play(type)
      }
    }

    func play(_ type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }
}

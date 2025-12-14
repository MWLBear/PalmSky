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
    
    enum HapticType {
        case light
        case success
        case error
    }
    
    func play(_ type: HapticType) {
        #if os(watchOS)
        switch type {
        case .light:
            WKInterfaceDevice.current().play(.click)
        case .success:
            WKInterfaceDevice.current().play(.success)
        case .error:
            WKInterfaceDevice.current().play(.failure)
        }
        #endif
    }
}

//
//  HapticManager.swift
//  PalmSky Watch App
//
//  Created by mac on 12/14/25.
//

import Foundation
#if os(watchOS)
import WatchKit
typealias HapticType = WKHapticType
#elseif os(iOS)
import UIKit
enum HapticType {
    case click
    case success
    case failure
    case start
    case stop
    case directionUp
    case directionDown
    case notification
    // map others as needed
}
#endif

// MARK: - Haptic Manager
class HapticManager {
    static let shared = HapticManager()
    private init() {}

    
    // ✨ 内部维护开关状态 (默认开启，由 GameManager 同步)
    var isEnabled: Bool = true

    func playIfEnabled(_ type: HapticType) {
        if isEnabled {
            play(type)
        }
    }

    func play(_ type: HapticType) {
        #if os(watchOS)
        WKInterfaceDevice.current().play(type)
        #elseif os(iOS)
        switch type {
        case .click:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .failure:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .start, .stop:
             let generator = UIImpactFeedbackGenerator(style: .medium)
             generator.impactOccurred()
        default:
             let generator = UISelectionFeedbackGenerator()
             generator.selectionChanged()
        }
        #endif
    }
}

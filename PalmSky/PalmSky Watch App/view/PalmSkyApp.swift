//
//  PalmSkyApp.swift
//  PalmSky Watch App
//
//  Created by mac on 12/12/25.
//

import SwiftUI

// MARK: - App Entry Point
@main
struct XiuxianApp: App {
  
    init() {
      _ = EventPool.shared
      let _ = GameCenterManager.shared
      SkySyncManager.shared.activate()
      
    }
    var body: some Scene {
        WindowGroup {
            RootPagerView()
            .environmentObject(GameManager.shared)

        }
    }
}

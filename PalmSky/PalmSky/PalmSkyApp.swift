//
//  PalmSkyApp.swift
//  PalmSky
//
//  Created by mac on 12/12/25.
//

import SwiftUI

@main
struct PalmSkyApp: App {
   
  @AppStorage("app_theme_preference") private var selectedTheme: AppTheme = .dark

  init() {
     let _ = GameCenterManager.shared
     SkySyncManager.shared.activate()
  
  }

  var body: some Scene {
      WindowGroup {
        PhoneMianView()
          .preferredColorScheme(selectedTheme.colorScheme)

      }
  }
  
}

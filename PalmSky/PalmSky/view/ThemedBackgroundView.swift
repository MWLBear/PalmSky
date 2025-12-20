//
//  ThemedBackgroundView.swift
//  MDemo Watch App
//
//  Created by mac on 2025/11/20.
//

import SwiftUI

struct ThemedBackgroundView<Content: View>: View {
  


    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
          Color(uiColor: .systemGroupedBackground)
            .ignoresSafeArea()
    
            content
        }
    }
}


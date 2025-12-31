//
//  WatchRealmListView.swift
//  PalmSky Watch App
//
//  Created by mac on 12/31/25.
//

import Foundation
import SwiftUI

struct WatchRealmListView: View {
    @Environment(\.dismiss) var dismiss
    
    let currentLevel: Int
    let reincarnationCount: Int
    
    // 计算当前处于第几大境界 (0-15)
    private var currentStageIndex: Int {
        GameLevelManager.shared.stage(for: currentLevel)
    }
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    // MARK: - 头部：轮回信息
                    Section {
                        HStack {
                            Image(systemName: "infinity")
                                .foregroundColor(.purple)
                            Text("当前轮回")
                            Spacer()
                            Text("第 \(reincarnationCount + 1) 世") // 0世显示第1世
                                .bold()
                                .foregroundColor(.white)
                        }
                        
                        // 显示前缀 (如 "真", "玄")
                        if reincarnationCount > 0 {
                            HStack {
                                Text("获得称号")
                                Spacer()
                                let name = GameLevelManager.shared.stageName(for: 1, reincarnation: reincarnationCount)
                                // 提取前缀 (比如 "真·")
                                let prefix = name.components(separatedBy: "·").first ?? ""
                                Text(prefix)
                                    .font(.title3.bold())
                                    .foregroundColor(.orange)
                            }
                        }
                    } header: {
                        Text("仙途履历")
                    }
                   
                    
                    // MARK: - 列表：十六大境界
                  // MARK: - 列表：十六大境界
                  Section {
                    ForEach(GameConstants.stageNames.indices, id: \.self) { index in
                      // 🔥 核心修复：把复杂的判断逻辑提出来
                      let isCurrent = (index == currentStageIndex)
                      let isPassed = (index < currentStageIndex)
                      
                      // 1. 计算文字颜色
                      let textColor: Color = {
                        if isCurrent { return .green }
                        if isPassed { return .gray }
                        return .white.opacity(0.6)
                      }()
                      
                      // 3. 计算字重
                      let fontWeight: Font.Weight = isCurrent ? .bold : .regular
                      
                      HStack {
                        // 状态图标
                        if isPassed {
                          Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.gray)
                        } else if isCurrent {
                          Image(systemName: "figure.walk")
                            .foregroundColor(.green)
                            .symbolEffect(.bounce, options: .repeating)
                        } else {
                          Image(systemName: "lock.fill")
                            .foregroundColor(Color.white.opacity(0.1))
                            .font(.caption)
                        }
                        
                        // 境界名称
                        Text(GameConstants.stageNames[index])
                          .foregroundColor(textColor) // 使用变量
                        
                        Spacer()
                        
                        // 当前层级进度 (只在当前境界显示)
                        if isCurrent {
                          Text(GameLevelManager.shared.layerName(for: currentLevel))
                            .font(.caption2)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .clipShape(Capsule())
                        }
                      }
                      .id(index)
                
                    }
                  } header: {
                    Text("境界一览")
                  }
                }
                .navigationTitle("天道图鉴")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    // 自动滚动到当前境界，让玩家一眼看到自己在哪
                    // 延迟一点点，确保列表加载完
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            proxy.scrollTo(currentStageIndex, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    WatchRealmListView(currentLevel: 14, reincarnationCount: 1)
}

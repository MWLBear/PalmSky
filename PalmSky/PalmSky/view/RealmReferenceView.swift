//
//  RealmReferenceView.swift
//  PalmSky
//
//  Created by mac on 12/19/25.
//

import SwiftUI

struct RealmReferenceView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            List {

                // MARK: - 境界体系
                Section {
                    ForEach(GameConstants.stageNames.indices, id: \.self) { index in
                        HStack {
                     
                          // 序号
                            Text("第 \(index + 1) 境")
                            .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .leading)

                            // 境界名
                            Text(GameConstants.stageNames[index])
                                .font(.body)
                                .fontWeight(.semibold)
                                .fontDesign(.rounded)
                                .foregroundColor(getRealmColor(index))

                            Spacer()

                            // 层数
                            Text("共九层")
                                .font(.footnote)
                                 .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("境界 · 修行阶梯")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.secondary)
                } footer: {
                    Text("九天玄仙之后，便是大道尽头。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // MARK: - 轮回体系
                Section {
                    ForEach(GameConstants.zhuanNames.indices, id: \.self) { index in
                        HStack {
                            Text("第 \(index + 1) 世")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .leading)

                            Spacer()

                            if index == 0 {
                                Text("凡躯（无前缀）")
                                    .font(.callout)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            } else {
                              
                                Text("【 \(GameConstants.zhuanNames[index]) 】")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .fontDesign(.rounded)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("轮回 · 前缀一览")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.secondary)
                } footer: {
                    Text("每一世轮回，修炼速度与机缘感应都会大幅提升。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("天道图鉴")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.insetGrouped) // 保留系统分组样式
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                    .foregroundColor(.white)
                }
            }
        }
    }
  
    func getRealmColor(_ index: Int) -> Color {
      let level = (index * 9) + 1   // 每境的第一层
      
      if colorScheme == .light {
        return RealmColor.primaryFirstColor(for: level)
        
      } else {
        return RealmColor.primaryLastColor(for: level)
      }
    }
}


// 预览
struct RealmReferenceView_Previews: PreviewProvider {
    static var previews: some View {
        RealmReferenceView()
            .preferredColorScheme(.dark)
    }
}

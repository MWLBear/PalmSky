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
                            Text(String(format: NSLocalizedString("phone_realm_stage_number_format", comment: ""), index + 1))
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
                            Text(NSLocalizedString("phone_realm_nine_layers", comment: ""))
                                .font(.footnote)
                                 .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text(NSLocalizedString("phone_realm_section_stage_header", comment: ""))
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.secondary)
                } footer: {
                    Text(NSLocalizedString("phone_realm_section_stage_footer", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // MARK: - 轮回体系
                Section {
                    ForEach(GameConstants.zhuanNames.indices, id: \.self) { index in
                        HStack {
                            Text(String(format: NSLocalizedString("phone_realm_life_number_format", comment: ""), index + 1))
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .leading)

                            Spacer()

                            if index == 0 {
                                Text(NSLocalizedString("phone_realm_mortal_no_prefix", comment: ""))
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
                    Text(NSLocalizedString("phone_realm_section_cycle_header", comment: ""))
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.secondary)
                } footer: {
                    Text(NSLocalizedString("phone_realm_section_cycle_footer", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(NSLocalizedString("watch_realm_nav_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.insetGrouped) // 保留系统分组样式
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("phone_common_close", comment: "")) { dismiss() }
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

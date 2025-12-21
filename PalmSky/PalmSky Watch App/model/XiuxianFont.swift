//
//  XiuxianFont.swift
//  PalmSky Watch App
//
//  Created by mac on 12/21/25.
//

import Foundation
import SwiftUI

enum XiuxianFont {

    // MARK: - 核心层级（境界 / 世界观）

    /// 境界主标题（法阵中心 / 首页顶部）
    /// 使用场景：
    /// - BreakthroughView 境界名
    /// - RealmHeaderView realmName
    static let realmTitle =
       Font.system(size: 26, weight: .black, design: .rounded)

    /// 境界结果标题（突破成功 / 失败）
    static let realmResultTitle =
        Font.system(size: 24, weight: .bold, design: .rounded)

    /// 当前境界描述（突破成功后的新境界）
    static let realmSubtitle =
        Font.system(size: 18, weight: .medium, design: .rounded)

    // MARK: - 数值核心层（HUD / 主数值）

    /// 核心数值（灵气总量）
    /// 使用场景：
    /// - BottomControlView 当前灵气
    static let coreValue =
        Font.system(size: 24, weight: .bold, design: .rounded)

    /// HUD 数值 / 百分比
    /// 使用场景：
    /// - 共鸣率 80%
    /// - Gauge / Widget 百分比
    static let hudValue =
        Font.system(size: 12, weight: .bold, design: .rounded)

    // MARK: - 操作层（按钮）

    /// 主操作按钮（立即突破 / 逆天改命）
    static let primaryButton =
       Font.system(size: 18, weight: .bold, design: .rounded)

    /// 次级操作按钮（完成）
    static let secondaryButton =
        Font.system(size: 16, weight: .bold, design: .rounded)

    // MARK: - 正文 / 提示

    /// 标准正文说明
    /// 使用场景：
    /// - “天地灵气汇聚中…”
    /// - “道心受损 -20%”
    static let body =
        Font.system(size: 14, weight: .regular, design: .rounded)

    /// 次要说明文字
    static let caption =
        Font.system(size: 13, weight: .bold, design: .rounded)

    // MARK: - 标签 / Buff / 徽章

    /// Buff / Debuff / 境界层级胶囊
    static let badge =
        Font.system(size: 13, weight: .bold, design: .rounded)

    /// Buff 数值标签（+20% / -10%）
    static let buffTag =
        Font.system(size: 10, weight: .bold, design: .rounded)

    // MARK: - 极小信息（预留）

    /// Corner / 超小辅助信息
    static let micro =
        Font.system(size: 9, weight: .medium, design: .rounded)
}

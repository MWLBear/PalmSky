# zh-Hant 全量本地化扫描与执行计划

- 扫描时间: 2026-02-28
- 范围: `PalmSky` + `PalmSky Watch App` + `Sky` (Widget)
- Swift 中文字符串字面量: 328 处
- 涉及文件数: 38
- 现有 Localizable key 数: 106
- 代码中 `NSLocalizedString` 调用数: 67

## 分层统计

- UI/用户可见文案（Text/Button/标题/Toast/通知等）: 120 处
- Debug/日志中文 `print(...)`: 44 处（可延后）

## 高优先级文件（按中文字面量数量）

```text
  36 PalmSky Watch App/view/SettingsView.swift
  33 PalmSky Watch App/manager/GameManager.swift
  27 PalmSky/view/PhoneSettingsView.swift
  26 PalmSky Watch App/view/LifeReviewView.swift
  18 Sky/XiuxianComplication.swift
  18 PalmSky Watch App/view/PaywallView.swift
  15 PalmSky Watch App/manager/PurchaseManager.swift
  14 PalmSky Watch App/model/GameEvent.swift
  13 PalmSky Watch App/view/EventView.swift
  12 PalmSky Watch App/view/game/MiniGameContainer.swift
  11 PalmSky Watch App/view/game/InscriptionGameView.swift
  10 PalmSky/view/RealmReferenceView.swift
  10 PalmSky Watch App/view/BuffDetailView.swift
   8 PalmSky Watch App/view/WatchRealmListView.swift
   8 PalmSky Watch App/view/StepRefineView.swift
   8 PalmSky Watch App/view/MainView.swift
   8 PalmSky Watch App/view/BreakthroughView.swift
   8 PalmSky Watch App/manager/NotificationManager.swift
   8 PalmSky Watch App/manager/GameLevelManager.swift
   6 PalmSky Watch App/manager/WatchHealthManager.swift
   4 PalmSky Watch App/manager/EventPool.swift
   3 PalmSky/view/AppTheme.swift
   3 PalmSky Watch App/model/GameFormulas.swift
   2 Sky/XiuxianEntranceWidget.swift
   2 PalmSky Watch App/view/game/GameGuideView.swift
   2 PalmSky Watch App/view/CelebrationView.swift
   2 PalmSky Watch App/view/BottomControlView.swift
   2 PalmSky Watch App/model/TaijiSkin.swift
   2 PalmSky Watch App/model/CultivationRecord.swift
   1 Sky/SharedDataManager.swift
   1 PalmSky/view/PhoneContentView.swift
   1 PalmSky Watch App/view/game/MindDemonScene.swift
   1 PalmSky Watch App/view/TaijiStencilView.swift
   1 PalmSky Watch App/view/SwipeTutorialView.swift
   1 PalmSky Watch App/view/BuffStatusBar.swift
   1 PalmSky Watch App/manager/SkySyncManager.swift
   1 PalmSky Watch App/manager/RecordManager.swift
   1 PalmSky Watch App/manager/AchievementReporter.swift
```

## 执行批次（全文件一起纳入）

1. 批次A（核心路径，先上线）
   - `PalmSky Watch App/view/SettingsView.swift`
   - `PalmSky Watch App/view/PaywallView.swift`
   - `PalmSky/view/PhoneSettingsView.swift`
   - `PalmSky Watch App/manager/GameManager.swift`（toast）
   - `PalmSky Watch App/manager/PurchaseManager.swift`（error/loadError）

2. 批次B（游戏流程页）
   - `PalmSky Watch App/view/MainView.swift`
   - `PalmSky Watch App/view/BreakthroughView.swift`
   - `PalmSky Watch App/view/StepRefineView.swift`
   - `PalmSky Watch App/view/EventView.swift`
   - `PalmSky Watch App/view/LifeReviewView.swift`
   - `PalmSky Watch App/view/game/*`

3. 批次C（资料页与模型展示文案）
   - `PalmSky/view/RealmReferenceView.swift`
   - `PalmSky Watch App/view/WatchRealmListView.swift`
   - `PalmSky Watch App/view/Buff*.swift`
   - `PalmSky Watch App/model/GameEvent.swift`
   - `PalmSky Watch App/model/GameFormulas.swift`

4. 批次D（Widget 与扩展）
   - `Sky/XiuxianComplication.swift`
   - `Sky/XiuxianEntranceWidget.swift`
   - `Sky/SharedDataManager.swift`
   - 同步补齐 `SkyExtension` 的本地化资源挂载

## 约束与规范

- 新增 key 命名统一使用语义 key（例如 `settings.realm`），避免继续新增“中文即 key”。
- 动态文案统一用格式化 key（含 `%@`/`%d`），避免拼接造成翻译困难。
- Watch/iOS/Widget 三端共用一份 key 集，按 target membership 分发资源。
- 先保证功能路径可切换繁体，再清理日志中文。

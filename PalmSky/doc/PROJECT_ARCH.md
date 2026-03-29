# Project Architecture

## 1. 项目结构

当前项目主要由 3 个业务目标组成:

- `PalmSky Watch App/`
  - Apple Watch 主游戏工程。
  - 包含主要的修炼循环、界面、健康联动、内购与存档逻辑。
- `PalmSky/`
  - iPhone 端配套应用。
  - 负责承接手机侧展示、设置、Game Center 等能力。
- `Sky/`
  - Widget / Complication 扩展。
  - 负责表盘与小组件快照展示。

补充目录:

- `docs/`
  - 历史专题文档。
- `doc/`
  - 当前维护型项目文档，记录路线、架构、系统设计、变更日志与版本说明。
- `zh-Hans.lproj/`、`zh-Hant.lproj/`
  - 多语言文案资源。

## 2. Watch 端核心模块职责

### manager

- `GameManager.swift`
  - 核心状态中心。
  - 管理玩家数据、收益计算、突破、事件、离线收益、存档与同步。
- `WatchHealthManager.swift`
  - 健康数据入口。
  - 负责步数、睡眠、炼化与相关展示数据。
- `PurchaseManager.swift`
  - 管理内购状态与权益判断。
- `NotificationManager.swift`
  - 管理离线提醒、通知权限与调度。
- `SkySyncManager.swift`
  - 管理 Watch 向 iPhone 的数据同步。
- `RecordManager.swift`
  - 管理本世记录、轮回记录与埋点相关逻辑。

### model

- 负责纯数据结构与常量定义。
- `SkyConstants.swift`
  - 全局 key、配置项、限制常量。
- `GameEvent.swift`
  - 奇遇事件、Buff、Debuff 等模型定义。
- 其他模型文件
  - 承载境界、记录、语言、皮肤、颜色等基础数据。

### view

- 承接 watchOS 主界面与子玩法 UI。
- `MainView.swift`
  - 主修炼界面与场景切换入口。
- `SettingsView.swift`
  - 游戏内通用设置页。
  - 同时承载手表端与 iPhone 游戏主界面内的设置入口。
  - 负责睡眠、商店、统计、数据同步与重置等游戏内设置内容。
- `PhoneSettingsView.swift`
  - iPhone 外层 App 的独立设置页。
  - 承载连接状态、FAQ、支持我们、隐私条款等外围设置内容。
  - 不承担 `SettingsView.swift` 的游戏内通用设置职责。
- `BreakthroughView.swift`
  - 突破流程界面。
- `view/game/`
  - 小游戏与渡劫场景。

### 双端设置入口链路

- Apple Watch 端游戏内设置入口链路:
  - `PalmSky Watch App/view/PalmSkyApp.swift`
  - `RootPagerView`
  - `SettingsView`
- iPhone 端游戏内设置入口链路:
  - `PalmSky/PalmSkyApp.swift`
  - `PhoneMianView`
  - `PhoneContentView`
  - `BaguaContainerView`
  - `RootPagerView`
  - `SettingsView`
- iPhone 端外围设置入口链路:
  - `PalmSky/PalmSkyApp.swift`
  - `PhoneMianView`
  - `PhoneSettingsView`

约定:

- 凡是修仙主循环内的设置、数值展示、数据同步入口，统一归 `SettingsView`。
- 凡是 iPhone 外层容器的连接状态、FAQ、支持与条款页面，统一归 `PhoneSettingsView`。
- 后续新增设置入口时，必须先判断属于“游戏内设置”还是“外围设置”，避免重复加入口或加错页面。

## 3. 当前架构特征

- 架构风格:
  - 以 `GameManager.shared` 为中心的单例状态驱动。
  - 业务逻辑集中在 manager 层。
  - View 层直接观察 manager 状态并响应 UI 更新。
- 当前优点:
  - 开发效率高。
  - 小团队快速迭代成本低。
  - 跨功能串联方便。
- 当前代价:
  - `GameManager` 职责偏大。
  - 业务时序容易在 View 层和 manager 层交叉。
  - 需要更强的文档与约定来避免逻辑扩散。

## 4. 开发约定

### 状态与逻辑

- 业务状态优先收敛到 manager 层，不在 View 中堆积核心逻辑。
- 影响玩家数值、存档、奖励的逻辑必须进入统一管理入口。
- 所有“按天生效”“首次生效”“离线结算”类规则都要明确持久化 key。

### 存档与同步

- 本地存档为主，云端只做兜底恢复。
- 不将 iCloud 作为实时状态源。
- 重置、转世、恢复三类流程必须明确处理本地与云端状态。

### UI 与文案

- 新系统上线时需同步补齐:
  - 设置页展示
  - Toast / Buff / 状态栏反馈
  - 简体与繁体文案
- 文案优先保持修仙世界观一致，不直接使用生硬系统术语。

### 文档维护

- 新版本目标先更新 `doc/ROADMAP.md`。
- 每次 AI 改动后追加 `doc/AI_DEV_LOG.md`。
- 核心机制变动同步更新 `doc/SYSTEM_DESIGN.md`。
- 对外更新点同步记录到 `doc/RELEASE_NOTES.md`。

## 5. 当前重点风险

- `GameManager` 规模较大，跨系统改动时要特别注意副作用。
- 睡眠读取、离线结算、前后台切换存在时序问题，需要明确串联。
- 文档体系刚建立，后续必须持续维护，否则会再次失真。

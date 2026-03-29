# Data Override Design

本文档记录版本 4「两仪同修」的数据覆盖系统实现设计。

当前版本已实现双向手动覆盖:

- `手表覆盖手机`
- `手机覆盖手表`

## 1. 背景

当前项目的数据架构是双端独立:

- Apple Watch 有自己的主存档。
- iPhone 有自己的主存档。
- 护身符库存双端独立，不互通。
- 设置项双端独立，不互通。
- 当前 watch -> phone 的 `WCSession` 传输，主要用于手机侧缓存展示与 Game Center 上传，不会覆盖手机本地主存档。

这套设计本身是合理的，但会带来一个现实问题:

- 有些玩家希望手机和手表完全独立。
- 有些玩家希望在进度分叉后，手动让某一端覆盖另一端。

因此版本 4 不改成“统一云存档”架构，而是在“双端独立”的前提下，新增一个玩家主动触发的手动覆盖桥梁。

## 2. 当前代码现状

### 2.1 已有同步链路

- watch 端通过 `SkySyncManager.sendDataToPhone(player:)` 向手机发送 `Player`。
- 通讯载体是 `WCSession.sendMessage` + `transferUserInfo`。
- iPhone 端在 `SkySyncManager.processIncomingGameData(_:)` 中解码数据。
- 当前 iPhone 收到后只会:
  - 更新 `syncedData`
  - 提交 Game Center 排行榜
  - 上报成就

### 2.2 当前缺口

当前链路**不会**执行以下动作:

- 不会写入 `GameManager.shared.player`
- 不会覆盖 iPhone 本地主存档
- 不会触发 iPhone 端的正常保存流程

所以如果要实现“手表覆盖手机”，必须新增一条明确的覆盖链路，不能直接复用现有“排行榜同步”语义。

### 2.3 相关文件

- `PalmSky Watch App/manager/SkySyncManager.swift`
- `PalmSky Watch App/manager/GameManager.swift`
- `PalmSky Watch App/model/SkyConstants.swift`
- `PalmSky Watch App/view/SettingsView.swift`
- `PalmSky/view/PhoneSettingsView.swift`

## 3. 当前目标

当前版本已支持:

- `手表覆盖手机`
- `手机覆盖手表`

暂不做:

- 双向自动同步
- 云端统一主存档
- 护身符跨端共享
- 设置跨端共享

## 4. 产品定义

### 4.1 功能语义

“手表覆盖手机” 的含义是:

- 以手表当前修炼进度为来源
- 覆盖手机端的主存档进度
- 覆盖完成后，手机本地存档立即更新
- 手机后续的本地保存与 iCloud 备份，以这份新进度为准

### 4.2 明确保留的本地数据

以下内容不参与覆盖，继续保留手机本地值:

- `items.protectCharm`
- `settings`
- `id`

原因:

- 护身符是既定的双端独立商业化资产，不能跨端互相冲掉。
- 设置属于设备本地偏好，不应被另一端替换。
- `id` 属于本地存档身份，不建议跨端强行替换。

### 4.3 特殊字段处理

- `lastLogout` 不直接照搬手表旧值。
- 覆盖时将手机端 `lastLogout` 重置为 `Date()`。

原因:

- 如果把手表旧的 `lastLogout` 一起写入手机，手机端可能在覆盖后额外触发一轮非预期离线收益。

## 5. 覆盖字段白名单

当前建议覆盖以下字段:

- `level`
- `click`
- `currentQi`
- `reincarnationCount`
- `totalFailures`
- `consecutiveBreakFailures`
- `tapBuff`
- `autoBuff`
- `debuff`
- `hasSeenCharmIntro`
- `charmPromptBuckets`

当前建议保留目标端本地值的字段:

- `id`
- `lastLogout`
- `settings`
- `items.protectCharm`

实现原则:

- 不做“整包 Player 直接替换”
- 使用白名单字段逐项覆盖

## 6. 通讯方案

### 6.1 不复用当前自动同步语义

当前 `syncGameData` 是低频、兜底、非破坏性同步。

手动覆盖属于:

- 玩家主动发起
- 破坏性更强
- 需要立即确认结果

因此不建议继续使用:

- `transferUserInfo` 作为主执行通道

### 6.2 当前采用即时消息

当前采用:

- `WCSession.sendMessage`
- `replyHandler`

这样能做到:

- 手表点击后立即知道成功或失败
- 手机只在明确收到覆盖请求后才执行
- 手表可以及时提示玩家结果

### 6.3 可达性要求

该功能只在 `session.isReachable == true` 时允许执行。

不可达时的提示建议:

- 请保持手机与手表连接后重试

当前不做离线排队覆盖，不做“稍后补送”。

## 7. UI 交互设计

### 7.1 入口位置

入口统一放在 [SettingsView.swift](/Users/mac/WatchAPP/PalmSky/PalmSky/PalmSky%20Watch%20App/view/SettingsView.swift)，按当前设备平台动态切换按钮文案与行为:

- watch 端显示: `手表覆盖手机`
- iPhone 端显示: `手机覆盖手表`
- `SettingsView.swift` 是双端共用的游戏内设置页。
- `PhoneSettingsView.swift` 属于 iPhone 外层设置，不作为本功能主入口。
- 当前入口链路:
  - watch: `PalmSky Watch App -> RootPagerView -> SettingsView`
  - iPhone 游戏内入口: `PalmSkyApp -> PhoneMianView -> PhoneContentView -> BaguaContainerView -> RootPagerView -> SettingsView`
  - iPhone 外围设置: `PalmSkyApp -> PhoneMianView -> PhoneSettingsView`

建议新增一个独立 Section，标题统一为:

- `数据校准`

当前双端均已提供可执行入口:

- watch 端按钮可点击，执行 `手表覆盖手机`
- iPhone 端按钮可点击，执行 `手机覆盖手表`

### 7.2 交互流程

1. 玩家在手表设置页点击 `手表覆盖手机`
2. 弹出二次确认 Alert
3. Alert 明确说明:
   - 将用当前手表进度覆盖手机进度
   - 护身符不会同步
   - 手机设置不会同步
4. 玩家确认后发起即时消息
5. 手表收到成功或失败回调
6. 通过轻量提示反馈结果

### 7.3 确认文案建议

标题:

- `手表覆盖手机`
- `手机覆盖手表`

正文:

- `将以当前手表修为覆盖手机本地进度。护身符与设备设置不会同步。`
- `将以当前手机修为覆盖手表本地进度。护身符与设备设置不会同步。`

确认按钮:

- `确认覆盖`

取消按钮:

- `取消`

## 8. 代码实现拆分

## 8.1 `SkyConstants.WatchSync`

新增常量:

- `manualOverwritePhoneProgress`
- `overwriteResult`
- `overwriteMessage`

说明:

- `manualOverwritePhoneProgress` 作为新的 action
- `overwriteResult` 用于 reply 返回是否成功
- `overwriteMessage` 用于返回手表侧提示文案

## 8.2 `SkySyncManager`

### watchOS 侧新增

新增方法建议:

- `requestPhoneProgressOverwrite(player: Player, completion: @escaping (Result<String, Error>) -> Void)`

职责:

- 检查 `activationState` 和 `session.isReachable`
- 编码当前手表 `Player`
- 使用 `sendMessage` 发送覆盖请求
- 处理 reply 成功 / 失败

说明:

- 不要调用 `transferUserInfo`
- 覆盖动作必须是立即执行、立即返回结果

### iOS 侧新增

在 `routeMessage` 中新增 action 分支:

- `manualOverwritePhoneProgress`

新增处理方法建议:

- `handleManualOverwritePhoneProgress(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?)`

职责:

- 解析传入的 `Player`
- 调用 `GameManager.shared.applyProgressOverrideFromWatch(_:)`
- 持久化到手机主存档
- 通过 `replyHandler` 返回成功或失败结果

## 8.3 `GameManager`

新增方法建议:

- `applyProgressOverrideFromWatch(_ source: Player) throws`

职责:

- 读取当前手机本地 `player`
- 按白名单字段覆盖修炼进度
- 保留手机本地:
  - `items.protectCharm`
  - `settings`
  - `id`
- 将 `lastLogout` 设置为 `Date()`
- 覆盖后执行:
  - `player = mergedPlayer`
  - `checkBreakCondition()`
  - `savePlayer(forceSyncToPhone: false)`

说明:

- `savePlayer(forceSyncToPhone: false)` 的目的是避免 iOS 再触发无意义的“回传手表”逻辑
- iOS 端正常的本地保存、Game Center 上传、iCloud 备份仍可继续执行

### 合并逻辑建议

伪代码:

```swift
func applyProgressOverrideFromWatch(_ source: Player) {
    var merged = player

    merged.level = source.level
    merged.click = source.click
    merged.currentQi = source.currentQi
    merged.reincarnationCount = source.reincarnationCount
    merged.totalFailures = source.totalFailures
    merged.consecutiveBreakFailures = source.consecutiveBreakFailures
    merged.tapBuff = source.tapBuff
    merged.autoBuff = source.autoBuff
    merged.debuff = source.debuff
    merged.hasSeenCharmIntro = source.hasSeenCharmIntro
    merged.charmPromptBuckets = source.charmPromptBuckets

    merged.lastLogout = Date()
    // merged.items.protectCharm 保留本地
    // merged.settings 保留本地
    // merged.id 保留本地

    player = merged
    checkBreakCondition()
    savePlayer(forceSyncToPhone: false)
}
```

## 8.4 `SettingsView`

watch 端需要新增本地状态:

- `showOverwritePhoneAlert`
- `isOverwritingPhone`
- `overwriteResultMessage`

职责:

- 展示确认弹窗
- 防止重复点击
- 调用 `SkySyncManager.shared.requestPhoneProgressOverwrite(...)`
- 显示结果反馈

## 8.5 平台判断

`SettingsView` 内部按平台判断显示方向:

- `#if os(watchOS)` 显示 `手表覆盖手机`
- `#if os(iOS)` 显示 `手机覆盖手表`

当前状态:

- `#if os(watchOS)` 已实现 `手表覆盖手机`
- `#if os(iOS)` 已实现 `手机覆盖手表`

## 9. 安全边界

第一阶段必须保证:

- 不做整包覆盖
- 不覆盖护身符
- 不覆盖设置
- 不做自动触发
- 不在后台悄悄执行
- 不在不可达状态下排队执行

如果任一条件不满足，本期应直接视为不通过。

## 10. 失败场景处理

### 10.1 手机不可达

返回失败:

- `手机当前不可达，请保持连接后重试`

### 10.2 数据解码失败

返回失败:

- `数据解析失败，请稍后重试`

### 10.3 手机侧正在等待云恢复选择

如果 iPhone `GameManager` 当前处于 `isAwaitingCloudRestoreChoice == true`，建议拒绝覆盖。

返回失败:

- `手机当前正在处理存档恢复，请稍后再试`

原因:

- 避免“云恢复弹窗”和“手动覆盖”同时争抢手机主存档。

## 11. 测试清单

### 11.1 正常路径

- 手表与手机可达
- 手表点击 `手表覆盖手机`
- 手机本地主存档被替换为手表进度
- 手机护身符数量保持不变
- 手机设置保持不变
- 手机重新打开后仍是覆盖后的进度

### 11.2 失败路径

- 手机不可达时，手表收到明确失败提示
- 手机未安装对应 App 时，不显示可执行成功的假反馈
- 覆盖过程中解码失败时，不应破坏手机已有本地存档

### 11.3 边界验证

- 手机端有待恢复云档弹窗时，覆盖请求应被拒绝
- 覆盖后手机不应额外吃到一轮异常离线收益
- 覆盖后 iCloud 备份应以新的手机本地进度继续更新

## 12. 后续预留

当前双向手动覆盖已完成，后续再评估是否继续扩展:

- 更细的覆盖字段配置
- 更明确的双端状态展示
- 更丰富的覆盖前对比信息

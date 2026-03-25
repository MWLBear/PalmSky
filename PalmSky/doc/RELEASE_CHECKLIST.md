# Release Checklist

用于版本发布前的最终检查，重点覆盖签名能力、核心功能、文案一致性与真机验证。

## 1. 签名与能力

- `PalmSky Watch App` 已开启 `iCloud > Key-value storage`
- `PalmSky` iPhone 主 App 如需各自保留云备份，也已开启 `iCloud > Key-value storage`
- `SkyExtension` 若未直接使用 `NSUbiquitousKeyValueStore`，未额外勾选 iCloud
- `Automatically manage signing` 正常开启
- 真机构建时无 entitlement / provisioning profile 相关报错

### 提审电脑专项检查

- 提审电脑已登录正确的 Apple Developer 账号
- 提审电脑选中的 Team 正确
- 提审电脑使用 `Automatically manage signing`
- 不以开发机上的手动证书配置作为发布依据
- 在提审电脑上重新确认以下 capability 已正确勾选:
  - `HealthKit`
  - `Game Center`
  - `App Groups`
  - `iCloud > Key-value storage`
- 在提审电脑上确认各 target 的 entitlement 与 capability 一致
- 在提审电脑上至少完成一次真机构建或运行
- 在提审电脑上完成一次 `Archive` 验证，无签名或权限报错

## 2. 睡眠系统

- 首次打开时，HealthKit 权限请求行为符合当前设计
- 拒绝权限后，设置页显示“未授权/无数据”
- 已授权时，昨夜睡眠、养神档位、离线加成展示正确
- 同一天睡眠奖励仅在首次有效离线结算时生效一次
- 回前台后，睡眠查询完成再触发离线结算
- 睡眠统计结果在常见场景下合理，无明显重复累计或异常偏差

## 3. iCloud 备份 / 恢复

- 有进度时切后台，会触发本地保存与云端冲刷
- 删除重装后，本地无存档时可弹出恢复提示
- 点击“恢复云端”后，境界与主存档正确恢复
- 点击“重新开始”后，符合当前产品语义，后续本地进度继续覆盖云端
- 删档重置后，本地与云端备份一并清除

## 4. UI 与体验

- 离线收益 Toast 当前样式已确认可接受
- 设置页睡眠区展示无错位、无异常截断
- 云端恢复弹窗文案与实际行为一致
- 多语言文案无明显缺失或未翻译项

## 5. 文案与元数据

- App Store 描述已补充睡眠系统与云端备份恢复能力
- FAQ 中“数据会不会丢失”文案与当前实现一致
- 本次版本更新文案已确认
- 版本号、构建号、更新说明一致

## 6. 文档同步

- `doc/AI_DEV_LOG.md` 已记录本轮代码与文案变更
- `doc/SYSTEM_DESIGN.md` 已同步当前睡眠系统与 iCloud 设计状态
- `doc/RELEASE_NOTES.md` 如需对外说明，已同步本版本重点更新

## 7. 真机回归

- 真机验证一次睡眠权限允许 / 拒绝流程
- 真机验证一次睡眠离线收益结算流程
- 真机验证一次 iCloud 恢复确认流程
- 真机验证一次删档重置流程
- 真机验证一次后台保存后重新进入的核心链路

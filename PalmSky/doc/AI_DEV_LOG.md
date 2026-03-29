# AI Dev Log

用于记录 AI 对项目的代码或文档修改，便于后续追踪变更来源、范围与目的。

## 2026-03-15

- 修改内容:
  - 新建 `doc/` 项目文档目录。
  - 初始化版本路线、系统设计、项目架构、发布说明和 AI 变更日志文档。
  - 根据当前版本路线，补录版本 2、版本 3、版本 4 的阶段目标。
  - 根据当前代码结构，整理睡眠系统、闭关系统、步数收益系统与 iCloud 备份恢复系统的设计摘要。
- 涉及文件:
  - `doc/ROADMAP.md`
  - `doc/AI_DEV_LOG.md`
  - `doc/SYSTEM_DESIGN.md`
  - `doc/PROJECT_ARCH.md`
  - `doc/RELEASE_NOTES.md`
- 备注:
  - 本次为文档初始化，不包含业务逻辑代码修改。
  - 睡眠系统仍处于版本 3 开发中，后续应继续记录功能补全与 Bug 修复。

## 2026-03-15

- 修改内容:
  - 根据当前 `git diff` 梳理睡眠系统的已实现能力。
  - 将睡眠系统当前实现状态、关键流程和待优化项补充到系统设计文档。
  - 记录当前确认的睡眠系统优化清单，便于后续按优先级推进。
- 涉及文件:
  - `doc/SYSTEM_DESIGN.md`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仍为文档补充，不涉及业务代码改动。
  - 当前睡眠系统的首要风险是“睡眠查询异步返回晚于离线收益结算”，会造成奖励偶发失效。

## 2026-03-15

- 修改内容:
  - 修复睡眠查询与离线收益结算的时序竞争。
  - 为 `WatchHealthManager.requestPermission()` 增加完成回调。
  - 为 `WatchHealthManager.fetchLastNightSleep()` 增加完成回调，并保证各分支都能回调。
  - 将前台激活时的离线收益结算从“固定延迟 0.5 秒”改为“睡眠查询完成后再执行”。
- 涉及文件:
  - `PalmSky Watch App/manager/WatchHealthManager.swift`
  - `PalmSky Watch App/view/MainView.swift`
  - `doc/AI_DEV_LOG.md`
  - `doc/SYSTEM_DESIGN.md`
- 备注:
  - 这次修改的核心目标是让睡眠加成结算从概率成功变为确定性成功。

## 2026-03-15

- 修改内容:
  - 对睡眠系统展示做最小修正。
  - 当睡眠时长不可用时，不再显示“养神不足”与“+0%”。
  - 新增统一状态文案“未授权/无数据”，用于和正常睡眠档位区分。
- 涉及文件:
  - `PalmSky Watch App/manager/WatchHealthManager.swift`
  - `PalmSky Watch App/manager/GameManager.swift`
  - `zh-Hans.lproj/Localizable.strings`
  - `zh-Hant.lproj/Localizable.strings`
  - `doc/AI_DEV_LOG.md`
  - `doc/SYSTEM_DESIGN.md`
- 备注:
  - 本次不引入复杂状态机，只修正最容易误导玩家的展示问题。

## 2026-03-15

- 修改内容:
  - 优化睡眠时长统计精度。
  - 将睡眠查询从“直接累加 sample 时长”改为“裁剪窗口后合并重叠区间再求和”。
  - 查询 predicate 从 `.strictStartDate` 调整为普通时间范围查询，减少跨窗口边界片段的漏算风险。
- 涉及文件:
  - `PalmSky Watch App/manager/WatchHealthManager.swift`
  - `doc/AI_DEV_LOG.md`
  - `doc/SYSTEM_DESIGN.md`
- 备注:
  - 本次修改不会改变睡眠档位规则，只提升底层睡眠时长统计的可信度。

## 2026-03-15

- 修改内容:
  - 优化 iCloud Key-Value 备份同步时机。
  - `GameManager` 启动初始化时先调用 `cloudStore.synchronize()`，再尝试读取云备份。
  - `flushCloudBackup()` 在写入云端后追加一次 `synchronize()`，提高进入后台前的同步确定性。
- 涉及文件:
  - `PalmSky Watch App/manager/GameManager.swift`
  - `doc/AI_DEV_LOG.md`
  - `doc/SYSTEM_DESIGN.md`
- 备注:
  - 本次仍未引入实时云同步，也未监听云端外部变更通知，保持“本地优先 + 云端兜底”的设计边界。

## 2026-03-15

- 修改内容:
  - 更新 `SYSTEM_DESIGN` 文档中的睡眠系统与 iCloud 备份恢复系统状态。
  - 补充当前已完成项、明确保留的产品取舍，以及后续测试重点。
- 涉及文件:
  - `doc/SYSTEM_DESIGN.md`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次为文档同步更新，不涉及业务代码改动。

## 2026-03-15

- 修改内容:
  - 更新 FAQ 中关于“数据是否会丢失”的说明文案。
  - 文案调整为符合当前实现：本地优先、iCloud 兜底、非实时同步、手机与手表进度独立。
- 涉及文件:
  - `zh-Hans.lproj/Localizable.strings`
  - `zh-Hant.lproj/Localizable.strings`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅更新文案，不涉及业务逻辑改动。

## 2026-03-17

- 修改内容:
  - 微调离线收益 Toast 的视觉样式。
  - 在不改变原有文案结构的前提下，缩小字体与图标尺寸，并轻微增加行间距。
  - 同步收窄 Toast 的纵向内边距，使缩小后的文字与容器比例更协调。
- 涉及文件:
  - `PalmSky Watch App/view/ToastView.swift`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅做最小视觉优化，不修改 `offlineToastMessage` 的拼接逻辑。

## 2026-03-17

- 修改内容:
  - 清理 `StepRefineRow` 中重复的 HealthKit 权限请求。
  - 保留步数刷新逻辑，移除进入炼体行时再次调用 `requestPermission()` 的行为。
- 涉及文件:
  - `PalmSky Watch App/view/StepRefineView.swift`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 首页与前台激活流程仍会负责 HealthKit 权限申请，因此本次仅做冗余调用清理。

## 2026-03-17

- 修改内容:
  - 新增版本发布前检查清单文档。
  - 汇总睡眠系统、iCloud 备份恢复、签名能力、文案与真机回归的发版检查项。
- 涉及文件:
  - `doc/RELEASE_CHECKLIST.md`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次为发布准备文档整理，不涉及业务代码改动。

## 2026-03-17

- 修改内容:
  - 为发布清单补充“提审电脑专项检查”。
  - 增加自动签名、多能力 target、开发机手动签名与提审机自动签名并存场景下的注意事项。
- 涉及文件:
  - `doc/RELEASE_CHECKLIST.md`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次为发布流程文档补充，不涉及业务代码改动。

## 2026-03-25

- 修改内容:
  - 更新版本路线与发布说明文档。
  - 将版本 3「神游太虚」从开发中状态整理为当前版本记录。
  - 在发布说明中补录版本号 `2.3.0`，并将版本 3 正式排在版本 4 之前。
- 涉及文件:
  - `doc/ROADMAP.md`
  - `doc/RELEASE_NOTES.md`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次为版本文档收口，不涉及业务代码改动。

## 2026-03-25

- 修改内容:
  - 调整版本路线顺序。
  - 将“手动数据覆盖系统”提前为版本 4「两仪同修」。
  - 原版本 4「仙家法宝」顺延为版本 5。
- 涉及文件:
  - `doc/ROADMAP.md`
  - `doc/RELEASE_NOTES.md`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅调整规划顺序，不涉及业务代码改动。

## 2026-03-25

- 修改内容:
  - 同步更新项目规则文档中的当前开发阶段描述。
  - 将 `Agents.md` 中的“当前开发”从睡眠系统调整为版本 4「两仪同修」手动数据覆盖系统。
- 涉及文件:
  - `Agents.md`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 当前线上版本仍记为版本 3「神游太虚」，本次仅同步后续开发方向。

## 2026-03-25

- 修改内容:
  - 新增手动数据覆盖系统实现设计文档。
  - 明确版本 4 第一阶段只实现“手表覆盖手机”。
  - 细化覆盖字段白名单、WatchConnectivity 通讯方案、设置页入口与失败场景处理。
- 涉及文件:
  - `doc/DATA_OVERRIDE_DESIGN.md`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅输出实现设计，不涉及业务代码改动。

## 2026-03-25

- 修改内容:
  - 补充手动数据覆盖系统的双端入口文案规则。
  - 明确 `SettingsView.swift` 为公用入口，按平台显示“手表覆盖手机”或“手机覆盖手表”。
  - 明确第一阶段只开放手表端可执行入口，iPhone 端如需提前露出仅作为说明或占位。
- 涉及文件:
  - `doc/DATA_OVERRIDE_DESIGN.md`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次为交互设计补充，不涉及业务代码改动。

## 2026-03-27

- 修改内容:
  - 按 `DATA_OVERRIDE_DESIGN` 开始实现第一阶段“手表覆盖手机”。
  - 新增 WatchConnectivity 手动覆盖 action 与结果回传字段。
  - 新增手机侧白名单进度覆盖逻辑，保留护身符、设置与本地存档身份。
  - 在 watch 设置页新增“数据校准”入口、确认弹窗与结果提示。
  - 新增相关多语言文案，并在系统设计文档中补充手动数据覆盖系统摘要。
- 涉及文件:
  - `PalmSky Watch App/model/SkyConstants.swift`
  - `PalmSky Watch App/manager/GameManager.swift`
  - `PalmSky Watch App/manager/SkySyncManager.swift`
  - `PalmSky Watch App/view/SettingsView.swift`
  - `zh-Hans.lproj/Localizable.strings`
  - `zh-Hant.lproj/Localizable.strings`
  - `doc/SYSTEM_DESIGN.md`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 当前只实现第一阶段“手表覆盖手机”，手机覆盖手表仍保留在后续版本 4 规划中。

## 2026-03-27

- 修改内容:
  - 修正 `SettingsView` 的平台编译边界。
  - 将 `beginPhoneProgressOverwrite()` 与对应的覆盖确认弹窗一并限定为 `watchOS` 编译，避免 iPhone 端引用不到手表专属逻辑。
- 涉及文件:
  - `PalmSky Watch App/view/SettingsView.swift`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次为第一阶段手表覆盖手机功能的编译修正，不改变业务行为。

## 2026-03-27

- 修改内容:
  - 调整手动覆盖入口在设置页中的位置。
  - 将该 Section 从前部移动到“仙府设置”之后。
  - 相关文案一度尝试调整为更修仙语境的表达，后续已回退为更直白清晰的“数据校准 / 手表覆盖手机”。
- 涉及文件:
  - `PalmSky Watch App/view/SettingsView.swift`
  - `zh-Hans.lproj/Localizable.strings`
  - `zh-Hant.lproj/Localizable.strings`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次主要调整 UI 位置，不改变手动覆盖功能逻辑。

## 2026-03-27

- 修改内容:
  - 调整手动覆盖入口 footer 文案。
  - 明确提示玩家需保持手机与手表同时在前台打开，并确保连接正常。
  - 删除“当前阶段仅支持手表覆盖手机”的阶段性限制文案，为后续补充手机覆盖手表保留空间。
- 涉及文件:
  - `zh-Hans.lproj/Localizable.strings`
  - `zh-Hant.lproj/Localizable.strings`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅优化文案提示，不涉及业务逻辑改动。

## 2026-03-27

- 修改内容:
  - 为“手表覆盖手机”补充手机端轻提示反馈。
  - 手机端在成功接收并应用手表进度后，通过现有 iPhone Toast 组件提示“手机进度已更新”。
- 涉及文件:
  - `PalmSky Watch App/manager/SkySyncManager.swift`
  - `PalmSky/view/PhoneMianView.swift`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅增加目标端反馈，不改变手动覆盖主流程。

## 2026-03-27

- 修改内容:
  - 为 `SkySyncManager` 中本次新增的手动覆盖相关类型、状态和方法补充中文注释。
- 涉及文件:
  - `PalmSky Watch App/manager/SkySyncManager.swift`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅补充代码可读性注释，不涉及业务逻辑改动。

## 2026-03-27

- 修改内容:
  - 为 `GameManager.applyProgressOverrideFromWatch(_:)` 增加 `iOS` 平台编译边界。
  - 明确该方法仅供 iPhone 端消费手表覆盖请求使用。
- 涉及文件:
  - `PalmSky Watch App/manager/GameManager.swift`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅强化平台职责边界，不改变手动覆盖逻辑。

## 2026-03-27

- 修改内容:
  - 对称补齐“手机覆盖手表”链路。
  - 新增 phone -> watch 的手动覆盖 action、iPhone 端发起方法与手表端接收处理。
  - 新增手表侧按白名单应用手机进度的方法，并在手表端落地后补充轻提示。
  - 在 `PhoneSettingsView` 中加入“手机覆盖手表”入口、确认弹窗与结果提示。
  - 同步更新双端覆盖相关文案与系统设计文档。
- 涉及文件:
  - `PalmSky Watch App/model/SkyConstants.swift`
  - `PalmSky Watch App/manager/GameManager.swift`
  - `PalmSky Watch App/manager/SkySyncManager.swift`
  - `PalmSky/view/PhoneSettingsView.swift`
  - `zh-Hans.lproj/Localizable.strings`
  - `zh-Hant.lproj/Localizable.strings`
  - `doc/SYSTEM_DESIGN.md`
  - `doc/DATA_OVERRIDE_DESIGN.md`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 当前双端手动覆盖已具备对称能力，仍保持“本地独立 + 玩家主动校准”的设计边界。

## 2026-03-27

- 修改内容:
  - 调整双端手动覆盖的通用错误提示文案。
  - 将“当前设备不可达”错误改为中性表述，避免在双向覆盖场景下提示对象混淆。
- 涉及文件:
  - `PalmSky Watch App/manager/SkySyncManager.swift`
  - `zh-Hans.lproj/Localizable.strings`
  - `zh-Hant.lproj/Localizable.strings`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅优化双向覆盖错误提示文案，不改变同步逻辑。

## 2026-03-27

- 修改内容:
  - 调整“手机覆盖手表”入口位置。
  - 将该入口从 `PhoneSettingsView` 回迁到公用 `SettingsView`，按平台分支显示。
  - 清理 `PhoneSettingsView` 中为手动覆盖临时加入的状态、弹窗与触发逻辑。
- 涉及文件:
  - `PalmSky Watch App/view/SettingsView.swift`
  - `PalmSky/view/PhoneSettingsView.swift`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 当前双端手动覆盖入口统一收口到公用设置页，避免双套入口分散。

## 2026-03-28

- 修改内容:
  - 更新 `PhoneSettingsView` 中 `faq_missing_data_q / faq_missing_data_a` 对应的 FAQ 文案。
  - 将内容从旧的“数据没有同步到手机”排查说明，改为当前双端手动覆盖与数据校准机制说明。
- 涉及文件:
  - `zh-Hans.lproj/Localizable.strings`
  - `zh-Hant.lproj/Localizable.strings`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅更新 FAQ 文案，不涉及业务逻辑改动。

## 2026-03-28

- 修改内容:
  - 微调数据同步 FAQ 的表述顺序。
  - 将说明从“先强调不是实时同步”调整为“先说明如何手动覆盖，再补充同步边界”。
- 涉及文件:
  - `zh-Hans.lproj/Localizable.strings`
  - `zh-Hant.lproj/Localizable.strings`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅优化 FAQ 语气与阅读顺序，不涉及业务逻辑改动。

## 2026-03-28

- 修改内容:
  - 精简 `faq_data_loss_a` 文案。
  - 保留“本地优先、iCloud 兜底、双端独立”三项关键信息，去掉冗余说明。
- 涉及文件:
  - `zh-Hans.lproj/Localizable.strings`
  - `zh-Hant.lproj/Localizable.strings`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅压缩 FAQ 文案长度，不涉及业务逻辑改动。

## 2026-03-28

- 修改内容:
  - 修正睡眠系统状态展示语义。
  - 为 `WatchHealthManager` 增加睡眠数据状态判断，区分“未授权”和“无数据”。
  - 调整 `GameManager.sleepBonusStatusText`，不再继续使用合并态“未授权/无数据”。
- 涉及文件:
  - `PalmSky Watch App/manager/WatchHealthManager.swift`
  - `PalmSky Watch App/manager/GameManager.swift`
  - `zh-Hans.lproj/Localizable.strings`
  - `zh-Hant.lproj/Localizable.strings`
  - `doc/SYSTEM_DESIGN.md`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅修正睡眠状态展示，不改动睡眠收益结算逻辑。

## 2026-03-28

- 修改内容:
  - 清理睡眠状态拆分后遗留的旧合并态代码与文案。
  - 删除未使用的 `sleepStatusDisplayText` 计算属性。
  - 删除不再使用的 `watch_settings_sleep_status_unavailable` 本地化 key。
- 涉及文件:
  - `PalmSky Watch App/manager/WatchHealthManager.swift`
  - `zh-Hans.lproj/Localizable.strings`
  - `zh-Hant.lproj/Localizable.strings`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次为无行为变化的清理，保持新的“未授权 / 无数据”双态展示口径。

## 2026-03-28

- 修改内容:
  - 将双端手动覆盖入口的 Section 标题从“数据校准”调整为“数据同步”。
- 涉及文件:
  - `zh-Hans.lproj/Localizable.strings`
  - `zh-Hant.lproj/Localizable.strings`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅调整入口标题文案，不涉及按钮行为与同步逻辑改动。

## 2026-03-28

- 修改内容:
  - 调整 `faq_missing_data_q` 的问句表述。
  - 将“同步进度”改为更贴近当前入口命名的“同步数据”。
- 涉及文件:
  - `zh-Hans.lproj/Localizable.strings`
  - `zh-Hant.lproj/Localizable.strings`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅微调 FAQ 问句文案，不涉及业务逻辑改动。

## 2026-03-28

- 修改内容:
  - 为双端“数据同步”入口 footer 补充手动同步说明。
  - 明确提示“默认不会自动同步，需手动发起覆盖”。
- 涉及文件:
  - `zh-Hans.lproj/Localizable.strings`
  - `zh-Hant.lproj/Localizable.strings`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅增强同步规则提示，不涉及业务逻辑改动。

## 2026-03-28

- 修改内容:
  - 清理未使用的 `settings_data_override_footer` 本地化 key。
  - 当前公用设置页实际使用的是 `watch_settings_data_override_footer`。
- 涉及文件:
  - `zh-Hans.lproj/Localizable.strings`
  - `zh-Hant.lproj/Localizable.strings`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次为无行为变化的文案清理。

## 2026-03-27

- 修改内容:
  - 调整 iPhone 端成功覆盖后的提示承载方式。
  - 不再通过 `PhoneMianView` 单独监听中转，而是直接复用 `GameManager.offlineToastMessage` 作为手机端提示出口。
- 涉及文件:
  - `PalmSky Watch App/manager/SkySyncManager.swift`
  - `PalmSky/view/PhoneMianView.swift`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅收敛提示路径，不改变双向覆盖主流程。

## 2026-03-28

- 修改内容:
  - 统一手动数据覆盖系统的文档口径。
  - 修正 `SYSTEM_DESIGN.md` 中仍停留在单向第一阶段的旧描述。
  - 将入口职责收口为 `SettingsView` 按平台承载，避免继续保留与当前实现不一致的双页表述。
- 涉及文件:
  - `doc/SYSTEM_DESIGN.md`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅修正文档描述，不涉及业务代码改动。

## 2026-03-28

- 修改内容:
  - 补充 `SettingsView.swift` 与 `PhoneSettingsView.swift` 的职责分工说明。
  - 在项目架构文档中明确 `SettingsView.swift` 为双端共用的游戏内设置页。
  - 在手动数据覆盖设计文档中明确 `PhoneSettingsView.swift` 不作为数据同步功能主入口。
- 涉及文件:
  - `doc/PROJECT_ARCH.md`
  - `doc/DATA_OVERRIDE_DESIGN.md`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅补充分工约定，避免后续继续混淆两个设置页职责。

## 2026-03-28

- 修改内容:
  - 补充双端设置入口链路说明。
  - 在架构文档中明确 watch 与 iPhone 分别如何进入 `SettingsView.swift`。
  - 在数据覆盖设计文档中补充本功能相关的实际入口链路，避免后续只按文件名判断页面归属。
- 涉及文件:
  - `doc/PROJECT_ARCH.md`
  - `doc/DATA_OVERRIDE_DESIGN.md`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅补充文档说明，不涉及业务代码改动。

## 2026-03-28

- 修改内容:
  - 调整手动数据覆盖中“正在处理云端恢复”错误的提示文案。
  - 将原本指向“手机当前”的表述改为中性的“目标端当前”，避免双向覆盖时提示对象混淆。
- 涉及文件:
  - `zh-Hans.lproj/Localizable.strings`
  - `zh-Hant.lproj/Localizable.strings`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅调整错误提示文案，不涉及覆盖逻辑改动。

## 2026-03-29

- 修改内容:
  - 修正睡眠状态展示中“已授权但无数据”被误判为“未授权”的问题。
  - 调整 `WatchHealthManager.sleepDataStatus` 判断逻辑，不再将只读睡眠权限强依赖 `sharingAuthorized`。
  - 新增“已请求过睡眠权限”的本地标记，用于更稳定地区分“未授权”和“无数据”。
- 涉及文件:
  - `PalmSky Watch App/manager/WatchHealthManager.swift`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次仅修正睡眠状态展示判断，不改动睡眠收益与离线结算逻辑。

## 2026-03-29

- 修改内容:
  - 清理上一条睡眠状态修正中遗留的冗余本地标记变量。
  - 删除未实际参与判断的 `hasRequestedSleepPermission`，保持实现最小化。
- 涉及文件:
  - `PalmSky Watch App/manager/WatchHealthManager.swift`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次为无行为变化的代码清理。

## 2026-03-29

- 修改内容:
  - 将睡眠状态展示改为方案 B 的产品态判断。
  - 重新启用“是否已进入睡眠授权流程”的本地标记，用于区分“未授权”和“无数据”。
  - `sleepDataStatus` 现调整为：
    - 未请求过权限时显示“未授权”
    - 已请求过权限但无样本时显示“无数据”
    - 查询到睡眠样本时显示“有数据”
- 涉及文件:
  - `PalmSky Watch App/manager/WatchHealthManager.swift`
  - `doc/SYSTEM_DESIGN.md`
  - `doc/AI_DEV_LOG.md`
- 备注:
  - 本次为产品态展示语义调整，不代表系统层可以精确识别“用户明确拒绝读取睡眠权限”。

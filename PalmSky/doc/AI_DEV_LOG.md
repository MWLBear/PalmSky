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

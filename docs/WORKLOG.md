# ZYLPVPMOD 2.0 工作日志

本日志记录重构过程、设计决定、验证证据和未解决风险。玩家可见更新另见根目录 `CHANGELOG.md`。

### 2026-09-06 / M0-冻结 1.3.0 基线

- 目标：保存可恢复的重构前版本，并保证原目录不再承载新改动。
- 范围：Git 状态、远端、标签、原目录与新目录边界。
- 设计决定：原目录保持 `main` 和 `v1.3.0` 基线；新目录使用独立 `.git` 和 `codex/refactor-2.0`，克隆时禁用硬链接，避免文件对象共享带来的误修改风险。
- 修改：将原目录 18 个当前改动提交为 `1852e1d`，创建 `v1.3.0` 并推送 GitHub；创建平行目录 `ZYLPVPMOD2.0`。
- 验证：远端 `main` 和 `v1.3.0` 均解析到 `1852e1d`；新目录初始校验通过；两目录 `.git` 独立。
- 风险/待办：外层 `BBGZYL` 也是 Git 工作树，两个内层仓库在外层会显示为未跟踪目录；后续不得误在外层提交内层运行资产。
- 提交：`1852e1d Finalize ZYLPVPMOD 1.3.0 baseline`。

### 2026-09-06 / M0-建立 1.3.0 行为规格

- 目标：在任何玩法代码重构前，登记当前全部功能域、最终覆盖、条件加载、休眠文件和风险。
- 范围：ModInfo 283 个动作、1077 个文件条目、108 个 Criteria，配置、SQL、Lua、UI、地图、秘密结社、平台资源与文档。
- 设计决定：以 ModInfo 是否加载和最终数据库覆盖顺序为权威；上游完整模块用“版本 + 加载域 + 源目录”登记，ZYL 最终覆盖记录具体数值。
- 修改：新增 `ZYLPVPMOD1.3.0修改大全.md`；将其登记为源码文档而非运行文件。
- 验证：`tools/validate.ps1` 通过，结果为 164 XML、108 条件、283 动作、1077 文件、549 活跃引用、49 个当时显式未列出文件。
- 风险/待办：发现旧 README 的毛利解锁描述与最终 SQL 不同；文档采用实际“帝国初期”。
- 提交：`e047697 docs: catalogue ZYLPVPMOD 1.3.0 behavior`。

### 2026-09-06 / M1-工程治理基础

- 目标：建立可持续日志、阶段门、架构边界、测试矩阵和稳定行尾策略。
- 范围：仓库开发文件，不改变游戏运行时行为和 1.3.0 版本号。
- 设计决定：玩家变化与工程过程分开记录；源码文档位于 `docs`，Workshop 构建继续只接受 ModInfo 运行清单。
- 修改：新增 `.gitattributes`、`.gitignore`、`CHANGELOG.md` 以及 `docs` 下的治理文档；校验器识别源码专用文件。新增 `tools/project.json` 作为 Mod ID、包名、语义版本、ModInfo 整数版本和联机握手文件的单一元数据源；组装器与校验器改为读取它。发布脚本默认输出到仓库内忽略的 `artifacts`，并生成逐文件 SHA-256 与聚合哈希报告。
- 验证：PowerShell 三个维护脚本语法解析通过；`tools/validate.ps1` 通过，结果为 164 XML、108 条件、283 动作、1077 文件、549 活跃引用、48 个休眠文件和 13 个源码专用文件。连续两次 universal 构建均为 1072 文件、740.53 MiB、聚合 SHA-256 `10123dfcc47c5b4fa6a154a9bda926ee9e51c89b32e35f2367ffd2b183bfea6c`。
- 风险/待办：现有 ModInfo 和校验器仍为超大单文件，后续里程碑拆分；平台专用包尚未启用。
- 提交：`dbbd3f7 chore: establish 2.0 refactor governance`；`9059c0e build: centralize metadata and reproducible releases`。

### 2026-09-06 / M3-大厅刷新与事件生命周期第一批修复

- 目标：先消除能够静态确认的大厅热循环、重复配置写入、日志噪音和热重载事件泄漏风险。
- 范围：`ui/stagingroom.lua` 的周期刷新、能力标记、版本状态日志、好友判断和全局事件生命周期；不改变投票、Ban/Pick、身份算法或网络协议格式。
- 设计决定：配置事件仍立即执行完整 UI 刷新；发布回调只按原有 `g_tick_size` 的 1–5 秒阶段间隔执行周期任务。所有共享标记保持固定顺序写入，并在新值不同于旧值时才写。
- 修改：OnTick 在任何 Quick/Full Refresh 前节流；缓存 DRAFT 配置读取；Ban 槽和内置能力标记改为差异写入；版本握手周期日志改为调试日志；修正 `fasle`；OnShutdown 对称移除 21 个 Events 和 5 个 LuaEvents 注册。
- 验证：`tools/validate.ps1` 与 `git diff --check` 通过；静态配对统计为 26 个全局事件 Add / 26 个 Remove；未受调试开关保护的 `RefreshStatus` 打印为 0；`GameConfiguration.SetValue` 静态调用点从审计时约 53 个降到 41 个。
- 风险/待办：尚未做 Civ VI 双客户端运行测试；`stagingroom.lua` 仍是巨型脚本，命令、投票、身份和 ViewModel 抽取留在后续批次。
- 提交：`29545c1 perf: throttle staging-room refresh lifecycle`。

### 2026-09-06 / M4-游戏脚本确定性与掉线幂等

- 目标：消除 Multiplayer Helper 对同步随机流的无业务消耗，并使掉线单位冻结/重连恢复可重复调用。
- 范围：`data/MP_helper.lua`；不改变突然死亡、暂停 UI 或聊天协议。
- 设计决定：单位快照第一次写入后保持到成功重连；冻结按当前剩余移动力精确减到 0，恢复按“保存值 - 当前值”调整到精确值。正式日志关闭，调试函数保留。
- 修改：删除每回合 `Game.GetRandNum`/时间戳打印及无消费者的队伍扫描；重复 OnDrop 幂等返回；重连由单位×快照双循环改为 ID 哈希索引；删除两个未使用表工具函数。
- 验证：`tools/validate.ps1` 与 `git diff --check` 通过；`Game.GetRandNum` 和非调试回合开始处理器均为 0；脚本由 425 行降为 396 行。校验器锁定幂等快照、ID 索引、精确差值恢复及禁止随机调用。
- 风险/待办：需在真实双客户端中验证玩家掉线、重复通知、单位在掉线期间被删除以及重连后的移动力；本地 Lua 快照在整个 gameplay context 生命周期内有效，但不跨重新启动进程。
- 提交：`d8a57a2 fix: make disconnect recovery deterministic`。

### 2026-09-06 / M3-投票重开广播与 Tick 生命周期

- 目标：消除重开消息的广播突发、意外全局变量和整局常驻 Tick。
- 范围：`ui/Additions/VotePanel.lua` 的 remap/restart 路径；不改变投票计数和随机种子选择规则。
- 设计决定：房主重开前显式武装刷新跟踪；重载后的房主上下文也根据 `GAME_HOST_IS_JUST_RELOADING=Y` 恢复跟踪；快照请求发出后立即注销 Tick。每次重开执行只广播一份配置和一份玩家状态。
- 修改：统一 `b_remap_armed` 大小写；非房主立即返回；刷新时重新读取当前 host/local ID；使用 `Automation.GetTime`；删除未使用变量和失效注释；正式日志纳入调试开关。
- 验证：`tools/validate.ps1` 与 `git diff --check` 通过；VotePanel 从 784 行降为 744 行；活动 `print` 为 0；重开 Tick 恰有一个受控 Add/Remove；活动配置/玩家广播调用点分别降至 6/3，执行 remap 的分支各调用一次。
- 风险/待办：需要真实联机验证“确认重开→上下文重载→房主请求快照→客户端重同步”完整时序，以及房主迁移发生在该窗口内的行为。
- 提交：`958828a fix: deduplicate remap network lifecycle`。

### 2026-09-06 / M3-重同步控制器限流与输入收敛

- 目标：减少暂停/重同步期间的高频回调和全图重复计算，关闭聊天日志泄漏与无效调试协议。
- 范围：`ui/Additions/MPHOptions.lua` 的 general/targeted resync、种子/地图指纹检查和调试命令；不改变玩家可见按钮和 30 秒安全超时。
- 设计决定：暂停期间仍能运行的 `SystemUpdateUI` 是唯一超时源，但只在 general resync 挂起时注册并按秒节流。地图指纹在每次 LoadScreenClose 重新计算一次，房主响应本轮所有客户端时复用。
- 修改：删除常驻 GameCore Tick 和未定义 `g_local_turn/g_local_seed` 协议；缓存地图指纹；拒绝非数字种子；每条聊天原文和功能日志均置于关闭的 debug 开关；三条直接网络调试命令只在 debug 时可用。
- 验证：`tools/validate.ps1` 与 `git diff --check` 通过；活动 `print` 为 0；Resync 的 SystemUpdateUI Add/Remove 各一处，GameCore resync Tick 为 0；地图指纹只在加载完成时和缓存缺失兜底时计算。
- 风险/待办：地图指纹仍是同步的全图扫描，必须在地图已完全加载后执行；真实多人测试需确认所有客户端 LoadScreenClose 的消息到达顺序和暂停解除条件。
- 提交：`0b335d8 perf: bound multiplayer resync monitoring`。

### 2026-09-06 / M3-突然死亡计时器去重

- 目标：减少计时同步消息，修复畸形命令可能写坏计时状态的问题。
- 范围：`ui/Additions/SuddenDeathPanel.lua`；不改变 3600 秒初始值、淘汰最低分玩家和每次淘汰后 1200 秒规则。
- 设计决定：本地显示仍每秒更新；只有房主在新的游戏回合第一次 PlayerTurnActivated 时持久化并同步时间。计时 Tick 由一个带注册状态的函数管理。
- 修改：缓存 Automation 时间；删除重复 floor、自赋值、未使用 Popup/InstanceManager 和变量；调整时间必须为正数，AI 淘汰目标必须是有效且未连接玩家；聊天和状态日志默认关闭。
- 验证：`tools/validate.ps1` 与 `git diff --check` 通过；活动 `print` 为 0；计时 Tick 恰有一个受控 Add/Remove；校验器锁定按游戏回合去重和调整/淘汰参数验证。
- 风险/待办：需在同时回合和动态回合两种联机模式验证每回合同步频率与长时间客户端时钟漂移；如果实测一回合过长，可改为低频心跳而不是恢复每玩家广播。
- 提交：`80eead2 perf: deduplicate sudden-death synchronization`。

### 2026-09-07 / M3-主回合计时器差异广播

- 目标：减少回合切换、等待处理和聊天加时路径中的重复配置读取与广播，并移除无法成立的旧启动门分支。
- 范围：`ui/Additions/TurnProcessing.lua` 的计时器所有权、智能公式选择、同步回合状态事件和时间调整入口；不改变 0–9 各模式公式、每回合加时次数上限或公开聊天命令名称。
- 设计决定：仍由房主作为唯一计时器写入者；秒数与本地记录的计时器类型都没有变化时不广播。多人同步回合条件集中在一个谓词中，智能公式每次计算只读取一次模式。临时无计时命令保持幂等，正常回合结束恢复标准计时器。
- 修改：增加差异写入和单次配置广播；缓存计时模式；为所有本地/远端回合状态处理补齐统一启用条件；拒绝非数字 `UITimeAdjust`；删除引用未定义 `g_startupGateActive`/`UpdateStartupGate` 的死分支；运行日志转为默认关闭的调试日志。
- 验证：`tools/validate.ps1`、PowerShell 语法解析和 `git diff --check` 通过；全局事件静态统计为 12 个 Add / 12 个 Remove；活动行首 `print` 为 0。校验器锁定差异广播、模式缓存、输入防护、临时无计时幂等和禁止死启动门引用。
- 风险/待办：计时器类型差异判断依赖该脚本作为游戏内唯一写入者；需用双客户端验证相同秒数的连续回合由游戏核心正常重置，以及 `p+`、`p-`、`p+++` 后下一回合恢复标准计时的完整时序。
- 提交：`1e1bf9c perf: deduplicate turn timer broadcasts`。

### 2026-09-07 / M3-主机设置界面生命周期与种子广播

- 目标：消除主机设置 Context 热重载后的重复监听，并缩小刷新种子时的网络广播范围。
- 范围：`ui/hostgame.lua` 的全局事件生命周期、地图/游戏种子刷新、正式日志和不可达的旧 Mod 检测；不改变大厅默认值、赛事预设内容、自然奇观/城邦排除表或种子生成公式。
- 设计决定：所有 Events/LuaEvents 注册必须在 `OnShutdown` 以同一事件和处理器成对注销；需要注销的匿名内容配置监听改为具名函数。种子刷新仍只允许房主执行，地图配置随一次 GameConfig 广播同步，不发送未变化的 PlayerInfo。
- 修改：补齐 17 个全局事件的对称生命周期；为房主/本地 ID 补全空值和负值防护；删除与当前脚本加载前提矛盾的“未启用自身 Mod”扫描及 10% 随机关闭 `SpawnRecalculation` 分支；删除无参数、实际无效果的 `OnUpdateUI()` 调用；正式日志置于关闭的调试开关。
- 验证：`tools/validate.ps1`、PowerShell 语法解析和 `git diff --check` 通过；事件从 17 Add / 4 Remove 变为 17 Add / 17 Remove，活动行首 `print` 从 16 降为 0，`BroadcastPlayerInfo` 从 1 降为 0，脚本从 1131 行降为 1115 行。校验器逐一核对事件/处理器配对，并禁止匿名监听、死分支和无关玩家广播回归。
- 风险/待办：需要在前端热重载、创建房间、恢复默认、切换所有赛事预设和刷新种子后检查 UI 参数刷新及客户端种子一致性。
- 提交：`995678c fix: close host-game event lifecycle`。

### 2026-09-07 / M3-断线控制器幂等状态转换

- 目标：让重复或乱序的断线/连接通知只产生一次 UI 与 gameplay 效果，并保证组件不遗留暂停状态。
- 范围：`ui/Additions/DropControl.lua` 的断线列表、计时 Tick、暂停所有权和转发到 gameplay 的 `UICPLPlayerDrop/UICPLPlayerConnect` 事件；不改变房主手动恢复确认流程和 600 秒红色提示阈值。
- 设计决定：记录项在“已连接→掉线”时清零并开始新计时，在“掉线→已连接”时停止该项；同状态重复通知直接返回。只有真实状态转换才转发 gameplay 事件。组件只撤销自己曾申请的暂停，不干预玩家或其他组件原先的暂停。
- 修改：为玩家 ID 增加类型/范围防护；断线与重连处理统一返回是否发生状态转换；重复断线不再移动计时基准，再次断线清空旧累计时间；`UIEvents` 改为局部别名；`OnShutdown` 停止 Tick 后恢复本组件暂停；恢复确认使用统一房主判断。
- 验证：`tools/validate.ps1`、PowerShell 语法解析和 `git diff --check` 通过；动态 Tick 保持唯一 Add/Remove，活动行首 `print` 为 0，脚本从 248 行降为 243 行。校验器锁定状态幂等、重新计时、暂停归还、局部事件别名和 Tick 生命周期。
- 风险/待办：需双客户端制造重复断线通知、A/B 先后断线与乱序重连、同一玩家二次掉线、断线中热重载，以及“原本已由玩家暂停”的场景，确认只恢复本组件拥有的暂停。
- 提交：本次提交（断线控制器幂等重构）。

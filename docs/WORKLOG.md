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
- 提交：`f7e0426 fix: make drop control transitions idempotent`。

### 2026-09-07 / M3-主菜单全局事件生命周期

- 目标：防止主菜单 Context 热重载或卸载后遗留服务器、云服务、账号和导航事件监听。
- 范围：`ui/mainmenu.lua` 的全局 Events/LuaEvents 生命周期与本地版本/会话诊断日志；不改变菜单结构、联网能力判断、登录、云回合或游戏启动流程。
- 设计决定：保留全部 20 个原有注册位置和处理器，只在既有 `OnShutdown` 中以完全相同的事件/处理器成对注销；Logo 纹理释放仍先执行。正式诊断通过默认关闭的调试函数输出。
- 修改：为 14 个 Events 和 6 个 LuaEvents 补齐 Remove，其中包括原先在初始化函数外注册的 `EnterCrossPlayLobby`；4 个正式 `print` 迁移到调试开关。
- 验证：`tools/validate.ps1`、PowerShell 语法解析和 `git diff --check` 通过；全局事件从 20 Add / 0 Remove 变为 20 Add / 20 Remove，活动行首 `print` 从 4 降为 0。校验器按事件名与处理器名逐一核对配对。
- 风险/待办：需实际执行主菜单热重载、Steam/跨平台服务器断开重连、2K 账号回调、云回合检查、额外内容返回和跨平台大厅入口，确认新 Context 初始化后只响应一次。
- 提交：`584306c fix: close main-menu event lifecycle`。

### 2026-09-07 / M2-Lua 静态校验模块化起步

- 目标：停止在 28 万字节的 `validate.ps1` 中为每个 UI 重复复制事件配对和正式日志正则，建立可复用、可自检的领域模块接口。
- 范围：校验工具与架构/计划文档；不改变 ModInfo、运行包文件或游戏行为。
- 设计决定：`tools/validate.ps1` 保持唯一公开入口和错误汇总者；`tools/validation/LuaChecks.ps1` 提供事件生命周期问题收集、统一上报和无防护 `print` 检查。事件检查按“事件命名空间 + 事件名 + 处理器名”计数，Remove 数少于 Add 数即失败。
- 修改：等待室、主菜单、主机设置的三份事件配对逻辑改为模块调用；主菜单、主机设置、断线、重同步、两类计时器的六份正式日志正则改为统一调用；入口加入完整配对、缺失 Remove、重复 Add 三类正反样例。
- 验证：入口与模块 PowerShell 语法解析通过；`tools/validate.ps1` 和 `git diff --check` 通过，仍检查 164 个 XML、108 条件、283 动作、1077 文件、549 活跃引用和 48 个休眠文件，源码专用文件因新增模块从 13 增至 14。主入口相关重复实现净减少 55 行。
- 风险/待办：当前解析只覆盖具名的 `Events/LuaEvents.X.Add(Handler)` 形式；匿名回调仍需由领域断言禁止。后续继续抽出 ModInfo 清单/XML、数据库契约、地图、UI、联机和发布包检查。
- 提交：`9446649 refactor: extract Lua validation helpers`。

### 2026-09-07 / M1-运行时重构阶段构建检查点

- 目标：确认本轮大厅、计时、断线和校验器重构后仍能从源码树生成稳定、无开发文件污染的 universal 包。
- 范围：提交 `9446649` 的只读校验、元数据同步幂等测试和两次连续发布构建；产物位于已忽略的 `artifacts`，不修改运行源码。
- 设计决定：版本仍保持 1.3.0，直到完整重构与实机矩阵完成；本检查点只证明静态闭合和构建可重复，不替代文明 VI 双客户端测试。
- 修改：仅更新测试矩阵和工作日志中的验证证据。
- 验证：`assemble_modinfo.ps1` 执行前后 ModInfo SHA-256 均为 `94869D352E031F53513FB048095730851842B75BDF7CD4398B4EAF27259BB14D`；连续两次 universal 构建均为 1072 文件、776,502,843 字节（740.53 MiB），聚合 SHA-256 `fc00184ee15b5761dc6b873496ee907a72dd5f922ea7bf8b2853e14daa91b94b`。每次构建前校验均通过 164 XML、108 条件、283 动作、1077 文件、549 活跃引用、48 休眠文件和 14 源码专用文件。
- 风险/待办：哈希相对冻结基线变化是本轮 Lua 运行时修复的预期结果；尚未执行游戏加载、存读档和双客户端联机测试。
- 提交：`79471e4 docs: record reproducible refactor checkpoint`。

### 2026-09-07 / M2-冻结 ModInfo 语义动作图

- 目标：在把超大 ModInfo 拆成分域源文件前，建立能够证明 Criteria、Action、加载顺序和 Files 清单没有静默漂移的机器基线。
- 范围：`ActionCriteria`、`FrontEndActions`、`InGameActions`、`Files` 四个运行图段及报告/校验工具；版本、作者、依赖、Block 和本地化元数据继续由现有 XML/元数据校验负责。
- 设计决定：规范化忽略无语义的 XML 属性顺序和缩进，但保留元素顺序、Action 内文件顺序与 Files 全局顺序；冻结基线只保存来源提交、SHA-256 和计数，完整 482,193 字节图按需生成到 `artifacts/reports`，避免提交第二份巨型派生真值。
- 修改：新增 `tools/validation/ManifestGraph.ps1`、`tools/report_modinfo_graph.ps1` 和 `manifest/baseline-1.3.0-action-graph.json`；主校验器自动比较当前动作图与冻结指纹，同时核对四类计数；`manifest` 纳入源码专用目录。
- 验证：冻结标签与当前动作图 SHA-256 均为 `f41a5c55fc7000b435ffe645d4c25df358ad3950b1e03f105b64d07e49ba14af`，计数均为 108 Criteria、32 FrontEnd Actions、251 InGame Actions、1077 Files。连续两次完整报告文件相同；交换 XML 属性顺序不改变指纹；内存中把首条 Action 文件路径追加 `.probe` 后指纹变为 `bfd7b6efa32c06f011aecaa43601fc0aec3be3946f9d6fcf154bc33db88475ed`，成功检出语义漂移。完整项目校验通过，源码专用文件增至 17。
- 风险/待办：当前基线要求动作图与 1.3.0 完全等价；后续若因兼容性需要有意增删 Action，必须建立显式迁移差异而不是直接覆盖基线。下一步按域拆分清单源并让组装器生成相同指纹。
- 提交：`e210103 test: freeze ModInfo semantic action graph`。

### 2026-09-07 / M2-ActionCriteria 分域生成

- 目标：把 108 条 Criteria 从手工 ModInfo 迁移到按责任域维护的源片段，同时逐项保留冻结顺序和语义。
- 范围：ActionCriteria、共享清单读取模块、组装器、校验器和相关文档；FrontEndActions、InGameActions、Files 暂不迁移。
- 设计决定：按 core、multiplayer、QoL UI、BBG、BBM、Better Deal Window、Rich Mainland、resources、secret societies、ZYL balance 十个域拆分。每条 Criteria 在源片段携带唯一连续 `manifestOrder`，组装进 ModInfo 时移除开发属性；ID 在全部片段间不区分大小写唯一。
- 修改：新增 `manifest/criteria/*.xml` 十个片段和 `tools/manifest/ManifestSources.ps1`；组装器每次从片段重建 ActionCriteria；校验器直接比较分域源生成段与 ModInfo 当前段，并继续检查冻结全图指纹。
- 验证：十域 Criteria 数分别为 4/10/7/50/26/4/3/2/1/1，总计 108；源片段生成段与当前段规范 JSON 完全一致。正常组装前后 ModInfo SHA-256 均为 `94869D352E031F53513FB048095730851842B75BDF7CD4398B4EAF27259BB14D`。负向测试把生成文件首条 `Expansion2` 临时改为 `Expansion2_PROBE` 后校验以退出码 1 拒绝，组装器随后从片段恢复原哈希；最终校验通过 174 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 29 源码专用文件。
- 风险/待办：领域划分目前只约束所有权，不改变跨域引用；下一步用相同 `manifestOrder` 机制迁移 32 条 FrontEnd Actions 和 251 条 InGame Actions，再生成 Files 清单。
- 提交：`815f2e5 refactor: generate Criteria from domain manifests`。

### 2026-09-07 / M2-Actions 分域生成

- 目标：把 32 条 FrontEnd Actions 和 251 条 InGame Actions 从手工 ModInfo 迁移到按责任域维护的源片段，消除动作定义与组装器特例的双重真值。
- 范围：两类 Actions、共享清单读取模块、组装器、校验器和相关文档；Files 暂不迁移，不改变任何游戏运行行为或版本号。
- 设计决定：前端动作按 9 个域拆分为 2/4/7/7/3/1/2/1/5 条，游戏内动作按 9 个域拆分为 39/56/87/20/9/4/13/10/13 条；各段独立使用连续 `manifestOrder` 恢复冻结顺序。分域源拥有全部运行元素，生成 ModInfo 可保留说明注释；元素序列相同时组装器不重写文件。
- 修改：新增 `manifest/actions/frontend/*.xml` 和 `manifest/actions/ingame/*.xml` 共 18 个片段；`ManifestSources.ps1` 支持受限 Action 元素集合；组装器生成两类动作段并删除 `ZYL_TPVP_VampireCastleGameplay`/Files 的硬编码补丁；校验器逐段比较分域源和 ModInfo。
- 验证：PowerShell 语法解析通过；正常组装为字节级幂等，ModInfo SHA-256 保持 `94869D352E031F53513FB048095730851842B75BDF7CD4398B4EAF27259BB14D`，完整动作图仍为 `f41a5c55fc7000b435ffe645d4c25df358ad3950b1e03f105b64d07e49ba14af`。负向测试将生成文件首条 Action 临时改为 `FrontEnd_DRIFT_PROBE` 后校验以退出码 1 检出动作图漂移，组装器恢复精确原哈希；另将源片段临时改为 `FrontEnd_SOURCE_PROBE` 后校验以退出码 1 检出源/生成段不一致，并用重复 `FrontEnd` ID 证明重复动作会被拒绝。PowerShell 7 与 Windows PowerShell 校验均通过 192 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 47 源码专用文件；universal 包仍为 1072 文件、740.53 MiB，聚合 SHA-256 保持 `fc00184ee15b5761dc6b873496ee907a72dd5f922ea7bf8b2853e14daa91b94b`。
- 风险/待办：动作域只改变维护边界，不改变跨域 Criteria/File 引用；下一步迁移 1077 条 Files，并继续拆分校验器领域。
- 提交：`5f25527 refactor: generate Actions from domain manifests`。

### 2026-09-07 / M2-Files 分域生成

- 目标：把 1077 条 Files 从手工 ModInfo 迁移为唯一、可排序、可审查的源清单，完成冻结运行图四段的源化。
- 范围：Files、共享清单读取模块、组装器、校验器和相关文档；不删除或移动任何运行文件，不拆减 Windows/macOS 资产，不改变版本号。
- 设计决定：按 core、multiplayer、QoL UI、BBG、BBM、integrations、Rich Mainland、resources、secret societies、ZYL balance 和 art/platform assets 十一个域拆分，数量分别为 20/60/112/210/71/29/18/329/17/14/197。跨平台美术资产独立成域只是维护归类，不改变 universal 包组成。
- 修改：新增 `manifest/files/*.xml` 十一个片段；共享读取模块支持以规范化 `InnerText` 路径为身份，拒绝空路径、斜杠归一后不区分大小写重复和不连续顺序；组装器生成 Files 末段，校验器直接比较源清单与 ModInfo。
- 验证：1077 条源路径全部唯一映射且生成段与当前 Files 相同；连续两次组装前后 ModInfo SHA-256 均为 `94869D352E031F53513FB048095730851842B75BDF7CD4398B4EAF27259BB14D`，完整动作图保持 `f41a5c55fc7000b435ffe645d4c25df358ad3950b1e03f105b64d07e49ba14af`。负向测试临时删除 `manifestOrder="1"` 的 `README.md` 后，校验以退出码 1 检出从 2 起始的不连续顺序。PowerShell 7 与 Windows PowerShell 最终校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 58 源码专用文件；universal 包仍为 1072 文件、740.53 MiB，聚合 SHA-256 保持 `fc00184ee15b5761dc6b873496ee907a72dd5f922ea7bf8b2853e14daa91b94b`。
- 风险/待办：本阶段只重构清单真值，尚未压缩/删除跨平台资产；下一步拆分其余校验领域并建立明确的运行资产所有者契约。
- 提交：`511466a refactor: generate Files from domain manifests`。

### 2026-09-07 / M2-Manifest 校验模块化

- 目标：把冻结动作图和四段分域源一致性检查从近 5000 行主入口抽离，形成可复用、无副作用且可单测的 Manifest 校验边界。
- 范围：校验工具与架构/计划/工作日志；不改变 ModInfo、分域源、运行文件、版本或玩家行为。
- 设计决定：`ManifestChecks.ps1` 只返回问题列表，不直接写错误或修改输入；继续复用 `ManifestGraph.ps1` 的属性顺序无关规范化和 `ManifestSources.ps1` 的确定性生成。主入口保留统一汇总与退出职责。
- 修改：新增冻结指纹/四类计数检查、ActionCriteria/FrontEndActions/InGameActions/Files 源一致性检查和通用段比较器；主入口删除 123 行内联实现并以 34 行装载、自检和调度代码替代，净减少 89 行。
- 验证：段比较器内建“属性换序但语义相同”正例和“路径值漂移”反例；临时把 Files 源改为 `README_PROBE.md` 时校验以退出码 1 报告源/生成段不一致，临时把生成 Action 改为 `FrontEnd_MANIFEST_CHECK_PROBE` 时冻结基线以退出码 1 报告指纹漂移，组装器随后恢复 ModInfo 原始 SHA-256 `94869D352E031F53513FB048095730851842B75BDF7CD4398B4EAF27259BB14D`。PowerShell 7 与 Windows PowerShell 最终校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 59 源码专用文件；universal 包仍为 1072 文件、740.53 MiB，聚合 SHA-256 保持 `fc00184ee15b5761dc6b873496ee907a72dd5f922ea7bf8b2853e14daa91b94b`。
- 风险/待办：Manifest 域已经抽离；下一步优先抽取通用 XML/工程边界检查，再处理数据库契约、地图、UI、联机和发布包检查。
- 提交：`8d84a7b refactor: extract manifest validation checks`。

### 2026-09-07 / M2-工程边界与 XML 校验模块化

- 目标：统一主入口反复依赖的路径/XML 基础能力，并把外部 Workshop 缓存隔离、组装器输入边界和全项目 XML 解析检查抽成无副作用模块。
- 范围：校验工具与架构/计划/工作日志；不改变运行资产、ModInfo、分域源、版本或玩家行为。
- 设计决定：`ProjectChecks.ps1` 提供路径规范化、源码/生成文件分类和 XML 装载函数，供主入口后续领域断言继续调用；领域检查只返回问题列表。项目文件枚举统一排除 `.git`、`artifacts`、`build`、`dist`，但不隐藏其他未列入运行包的源码。
- 修改：新增工程文件枚举、维护脚本 Workshop 缓存路径扫描、组装器本地输入边界和 XML 可解析性检查；主入口删除 80 行内联实现并以 28 行装载、自检和调度代码替代，净减少 52 行。
- 验证：路径扫描器对安全样例返回 0 个问题、对 `steamapps/workshop` 危险样例返回 1 个问题；源码/运行文件与生成目录分类正反样例通过。临时把 `manifest/files/01-core.xml` 闭合标签改为 `FilesFragment_PROBE` 后，Windows PowerShell 校验以退出码 1 精确报告无效 XML 文件和行列。首次跨版本复核还发现 Windows PowerShell 5.1 会误解码无 BOM 脚本中的《修改大全》中文文件名，已为该模块保留 UTF-8 BOM；修复后 PowerShell 7 与 Windows PowerShell 均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 60 源码专用文件，universal 包仍为 1072 文件、740.53 MiB，聚合 SHA-256 `fc00184ee15b5761dc6b873496ee907a72dd5f922ea7bf8b2853e14daa91b94b`。
- 风险/待办：基础工程边界已抽离，但数据库、地图、UI、联机和发布包契约仍在主入口；下一步应选择高复用且能构造正反样例的领域继续拆分。
- 提交：`2b4bf4a refactor: extract project validation checks`。

### 2026-09-07 / M2-运行资产所有权校验模块化

- 目标：让仓库内每个文件明确属于“发布、休眠或源码”之一，并统一 Action/Criteria 身份和活跃引用视图，减少主入口散落的清单状态。
- 范围：校验工具、休眠文件清单和相关文档；不删除、移动或修改任何运行资产，不改变 ModInfo、版本或玩家行为。
- 设计决定：把 48 个有意休眠/冲突文件从 PowerShell 数组迁移到 `manifest/dormant-files.txt`；`AssetInventoryChecks.ps1` 一次构造 Files、Action、Criteria、活跃引用及其不区分大小写映射，并返回全部问题和供后续领域断言复用的只读视图。
- 修改：新增发布文件存在性、磁盘反向所有权、休眠项存在/未发布、Action/Criteria ID 唯一、Criteria 引用闭合、UpdateArt 不直载 ArtDef、Action 文件引用磁盘/Files 双闭合检查；主入口删除 191 行内联实现并以 33 行装载、自检、调用和视图解包替代，净减少 158 行。
- 验证：规范化路径助手对 `A/file.xml` 与 `a\\FILE.xml` 正确报告重复；临时从休眠清单移除 `BCS/UI/CityStates_SPEC.lua` 后，Windows PowerShell 校验以退出码 1 报告该磁盘文件既不在 Files 也不在休眠白名单；内存中把首个 Action 引用追加 `.probe` 后，同时报告引用磁盘缺失和未列入 Files。恢复后 PowerShell 7 与 Windows PowerShell 均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 62 源码专用文件；ModInfo SHA-256 保持 `94869D352E031F53513FB048095730851842B75BDF7CD4398B4EAF27259BB14D`，universal 包仍为 1072 文件、740.53 MiB，聚合 SHA-256 `fc00184ee15b5761dc6b873496ee907a72dd5f922ea7bf8b2853e14daa91b94b`。
- 风险/待办：所有权模型当前仍以“休眠白名单”为粗粒度原因记录；后续可为休眠项增加原因/来源元数据。下一步继续抽取数据库契约或活跃运行文件危险模式检查。
- 提交：`7374925 refactor: extract runtime asset inventory checks`。

### 2026-09-07 / M2-活跃运行文件安全校验模块化

- 目标：把危险调用、旧组件 ID 和已禁用机制扫描限定到实际被 Action 加载的文本文件，并从主入口抽成可复用模块。
- 范围：校验工具与架构/计划/测试矩阵/工作日志；不改变运行资产、ModInfo、分域源、版本或玩家行为。
- 设计决定：`RuntimeSafetyChecks.ps1` 接收资产所有权模块生成的活跃引用映射，只读取其中的 Lua/SQL/XML；逐行返回带文件和行号的问题，不扫描休眠替代实现。
- 修改：迁移动态 `loadstring`、`Modding.UpdateSubscription`、science/culture anti-stacking 和 8 个旧组件 Mod ID 检查；主入口用模块装载、3 问题反例和单次调度替代原内联扫描。
- 验证：安全文本样例返回 0 个问题；包含 `loadstring`、旧 Mod ID 和 `NO_MORE_STACK` 的三行样例返回 3 个问题。PowerShell 7 与 Windows PowerShell 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 63 源码专用文件；ModInfo SHA-256 保持 `94869D352E031F53513FB048095730851842B75BDF7CD4398B4EAF27259BB14D`，universal 包仍为 1072 文件、740.53 MiB，聚合 SHA-256 `fc00184ee15b5761dc6b873496ee907a72dd5f922ea7bf8b2853e14daa91b94b`。
- 风险/待办：这是静态文本门禁，不能证明 Civ VI 运行时没有通过其他 API 动态加载代码；后续仍需实机日志和双客户端测试。
- 提交：`ba725bd refactor: extract active runtime safety checks`。

### 2026-09-07 / M3-大厅调试日志与状态副作用收敛

- 目标：消除 `stagingroom.lua` 在正式大厅流程中的日志洪泛，并确保调试输出本身不会改变联机状态或产生额外广播。
- 范围：大厅 Lua、静态回归断言、更新日志、计划、测试矩阵和工作日志；不改变正常聊天命令格式、Ban/Pick/投票规则、身份配置或版本号。
- 设计决定：保留现有房主 `.debug` 开关，新增单一 `ZYLDebugLog` 入口；默认 `g_debug=false` 时不写 Lua 日志，显式启用后仍可获得诊断信息。调试消息只能读取已计算状态，不得再次调用有副作用的状态函数。
- 修改：冻结版 88 个活跃 `print` 调用点中删除 1 个启动日志，其余 87 个迁移到调试入口；两条日志改为复用已计算的 `g_next_ID`，`.next` 调试命令改为复用 `tmp`，使 `GetNextID()` 调用点由 15 降至 12；`.broadcast_player_0` 删除把昵称写为 `paf` 的遗留调试副作用。
- 验证：静态计数为 0 个直接 `print`、87 个受控调试调用、0 个日志参数内 `GetNextID()` 和 0 个 `paf` 昵称写入；校验器固定调试入口并拒绝上述回归。临时把 `g_Anon` 调试调用改回直接 `print` 后，Windows PowerShell 校验以退出码 1 报告大厅无防护日志。恢复后 PowerShell 7 与 Windows PowerShell 均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 63 源码专用文件；连续两次 universal 构建均为 1072 文件、776,495,377 字节（740.52 MiB），聚合 SHA-256 `e09404245d3ff1812c194d28cde21d7f4f3b1972aed684c9ac131929a2bbe4ae`。
- 风险/待办：Lua 静态检查不能替代游戏内日志采集；需要在房主/客户端/观察者大厅分别验证默认静默、`.debug` 后可诊断，以及投票/Ban/Pick 不多发 PlayerInfo。
- 提交：`adb900d fix: gate staging-room debug logging`。

### 2026-09-07 / M3-房主批量操作广播合并

- 目标：消除随机分队和批量关闭空槽时按玩家逐项发送的 PlayerInfo 广播，减少大厅网络突发并避免客户端观察到批处理中间状态。
- 范围：大厅两个房主按钮、静态回归断言、更新日志、计划、测试矩阵和工作日志；不改变参与者筛选、Fisher–Yates 洗牌、队伍分配、空槽筛选、按钮权限或版本号。
- 设计决定：依赖本文件现有且已投入使用的无参数 `Network.BroadcastPlayerInfo()` 完整快照语义；先完成同一操作的全部 `PlayerConfigurations` 写入，再发送一次完整玩家配置。批量开槽一次只更改一个槽位，继续按该槽位广播。
- 修改：随机分队的广播次数由参与者数量降为固定 1 次；批量关闭空槽由空槽数量降为固定 1 次。新增结构断言，要求两个写入循环结束后紧邻一次无参数广播。
- 验证：临时把随机分队循环后的无参数广播改回 `Network.BroadcastPlayerInfo(playerID)`，Windows PowerShell 校验以退出码 1 报告批量广播结构回归，随后恢复。PowerShell 7 与 Windows PowerShell 最终均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 63 源码专用文件；连续两次 universal 构建均为 1072 文件、776,495,359 字节（740.52 MiB），聚合 SHA-256 `f71f07333e42b08724c1db52189b6378c72bfe10f45555830758247d1fd2f7c6`。实机仍需房主加至少两个客户端验证队伍/槽位一次同步完成。
- 风险/待办：静态检查只能证明批处理结构，不能证明不同 Civ VI 网络版本对无参数广播的时序完全一致；列入 P08 双客户端验证。
- 提交：`5d4ef3e perf: batch staging-room player broadcasts`。

### 2026-09-07 / M3-匿名昵称刷新路径精简

- 目标：删除从未调用的全房间匿名化实现，并消除单玩家事件为查找已知 ID 而遍历完整多人列表的重复工作。
- 范围：大厅匿名昵称函数、静态回归断言、更新日志、计划、测试矩阵和工作日志；不改变匿名昵称格式、观察者显示名、连接判断、按值去重、广播目标或版本号。
- 设计决定：保留三个现有 `Anonymise_ID(playerID)` 调用点和函数名，直接读取 `PlayerConfigurations[playerID]`；无配置或未连接时提前返回。昵称计算继续复用原有领袖/观察者分支。
- 修改：删除项目内零引用、22 行的 `Anonymise()`；`Anonymise_ID` 去除多人 ID 列表分配与线性扫描，改为常量时间直接索引，同时将重复配置查找收敛到 `playerConfig`。
- 验证：源码树审计只剩 3 个 `Anonymise_ID` 调用和 1 个定义；临时恢复空的 `Anonymise()` 壳后，Windows PowerShell 校验以退出码 1 报告废弃全房间实现回归，随后恢复。PowerShell 7 与 Windows PowerShell 最终均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 63 源码专用文件；连续两次 universal 构建均为 1072 文件、776,494,418 字节（740.52 MiB），聚合 SHA-256 `76355145f3ac027ba45ee50d3219e0734ac41389c80b17e3ef7cd881c629dc19`。实机仍需覆盖匿名模式下加入大厅、切换领袖、观察者和本地 OnShow 路径。
- 风险/待办：静态引用审计无法证明外部未登记代码不会按全局名称调用 `Anonymise()`；当前 ModInfo 活跃引用和整个源码树均未发现调用，风险可控并列入 P09 实机验证。
- 提交：`5f96f5e refactor: simplify lobby anonymisation`。

### 2026-09-07 / M2-数据库时代契约模块化

- 目标：开始把散落在 4700 余行主校验入口中的数据库最终值检查迁移为无副作用、可独立自检的领域模块。
- 范围：时代长度/阈值的 SQL、配置、ModInfo 条件动作和文本契约，以及架构/计划/工作日志；不修改任何运行资产、ModInfo、玩家规则或版本号。
- 设计决定：新增 `DatabaseContractChecks.ps1`，以纯函数 `Get-ZylEraDurationSqlIssues` 校验 SQL 文本，以聚合函数 `Get-ZylEraConfigurationContractIssues` 只读工程文件并返回问题列表；主入口继续统一汇总和决定退出码。
- 修改：迁移八个时代最小/最大回合、黑暗/黄金时代阈值、双资料片大厅开关、Criteria/Action 闭包和中英文计时器标签检查；主入口删除 70 行内联实现，加入模块装载、正反样例和单次调度后净减少 32 行。
- 验证：模块内存正例覆盖八个时代各两次正确分支，错误 Ancient 值反例返回 1 个问题；临时把实际时代 SQL 的 Ancient 最小值由 50 改为 51 后，Windows PowerShell 校验以退出码 1 报告最小/最大不一致，随后恢复。PowerShell 7 与 Windows PowerShell 最终均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 64 源码专用文件；恢复受控测试触碰的 CRLF 工作区字节后，连续两次 universal 构建保持 1072 文件、776,494,418 字节（740.52 MiB）和聚合 SHA-256 `76355145f3ac027ba45ee50d3219e0734ac41389c80b17e3ef7cd881c629dc19`。
- 风险/待办：当前模块只承接首批时代契约，其余文明、领袖、建筑、资源、万神殿和结社数据库契约仍在主入口；后续按依赖闭包逐组迁移，避免一次大搬迁降低可审查性。本次还证明发布器会复制 Git 过滤后不可见的工作区行尾差异，后续应让发布包从规范化文本字节生成或在构建前拒绝非规范行尾。
- 提交：`841cee8 refactor: extract era database contract checks`。

### 2026-09-07 / M8-跨工作区确定性文本发布

- 目标：修复发布器直接复制工作区字节导致相同 Git 内容因 CRLF/LF 状态不同而生成不同包哈希的问题，使干净克隆的跨平台复现要求可验证。
- 范围：universal 发布脚本、工程边界门禁、README、架构、计划、测试矩阵、更新日志和工作日志；不修改运行源码、数据库、ModInfo 语义、玩家规则或版本号。
- 设计决定：以明确后缀和 `LICENSE` 识别 Civ VI 文本资产；严格按 UTF-8 解码，在临时产物中只把 CRLF 转为 LF，保留 UTF-8 BOM、已有 LF、孤立 CR 和全部 Unicode 字节语义。未知/二进制格式继续 `Copy-Item`，不尝试内容检测或重编码。清单路径使用 `StringComparer.Ordinal` 排序，报告使用固定属性顺序、Int64 总字节、压缩 JSON 和 LF 结尾。
- 修改：构建器新增文本边界、自检和规范化写入，运行条目分别记录源码/目标长度；报告升级为 schema 2，增加 `textNormalization=utf8-lf` 和规范化文件数。聚合清单从文化相关 `Sort-Object` 改为序号排序，报告消除 PowerShell 版本相关缩进/数字格式。常规校验固定关键实现片段，防止退回原始文本复制或文化相关排序。
- 验证：607 个候选仓库文本（约 15.4 MiB）全部通过严格 UTF-8 解码；发布清单排除 6 个源码文件后规范化 601 个运行文本。BOM/CRLF/LF/孤立 CR 正例和非法 UTF-8 反例均通过；临时把报告标识改为探针值时 Windows PowerShell 校验以退出码 1 拒绝。首轮跨运行时检查发现逐文件集合完全相同但 `Sort-Object` 聚合顺序不同，修复后时代 SQL 在工作区分别为 1251 字节全 LF 和 1282 字节全 CRLF、且构建器分别运行于 PowerShell 5.1 与 7 时，均生成 1072 文件、776,225,890 字节（740.27 MiB）和聚合 SHA-256 `3c4bcc62c842c916191d77e02ff3d94edf1a27af7462d09b52990bd33d66d280`；两种 PowerShell 生成的报告文本也完全相同，报告 SHA-256 为 `80400c6f1b05629bc4adac89b1484b9ee4814d0dff831aaf85f72b4102d77689`。代表性 SQL/Lua/ArtDef/TEX 与 Git 规范 blob 一致，FGX/DDS 源与产物 SHA-256 一致。
- 风险/待办：文本白名单必须随新增 Civ VI 文本资产格式维护；Windows/macOS 分平台包仍未生成。后续把发布清单与平台引用闭合检查抽成独立模块，并在干净克隆环境复核聚合哈希。
- 提交：`679a6fe build: normalize release text deterministically`。

### 2026-09-07 / M8-分平台确定性发布

- 目标：在不修改源码 ModInfo 与 universal 包语义的前提下生成 Windows/macOS 瘦身包，并让错误平台路径、缺失配对和 Action 直引在构建前失败。
- 范围：发布器、独立发布校验模块、总校验入口、README、架构、计划、测试矩阵、更新日志和工作日志；不修改任何游戏运行代码、数据库规则、冻结清单、Mod ID、名称或版本号。
- 设计决定：平台身份只由路径中任意层级的 `Platforms/MacOS`、`Platforms/Windows` 段决定；每个逻辑路径必须同时拥有 Windows/macOS 成员，Action 不得直接引用其中任一平台文件。universal 保留两端，单平台 profile 只在临时构建树和其 ModInfo 中删除另一端，源码真值不变。
- 修改：新增 `ReleaseChecks.ps1`，抽走发布器实现边界检查并加入平台路径分类、169 组双向配对、Action 非直引和资产定义无平台目录硬编码契约；发布器新增 `-Profile universal|windows|macos`、独立默认目录、profile 报告名和 schema 3 组成字段。Windows/macOS 各排除 169 个另一平台文件，601 个文本文件仍按 UTF-8/LF 确定性生成。
- 验证：模块内建完整配对正例、缺 Windows 成员反例、Action 直引反例、平台字面引用反例和根目录/嵌套路径选择样例；56 个 `.dep/.artdef/.xlp/.tex/.mtl/.anm/.geo` 文件全部能严格按 UTF-8 审计且不含平台目录硬编码。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 65 源码专用文件；两种运行时生成的 Windows 包均为 903 文件、442,484,953 字节，聚合 SHA-256 `ee212707175eea0f2de95628785818d246ed3f0a2e43862ef7383cd565ebf2a7`，macOS 包均为 903 文件、442,484,615 字节，聚合 SHA-256 `45ad3c085f00ea550613b067ac764fd449711b500ba0930c92a6d60e9d1d8d3f`。universal 仍为 1072 文件、776,225,890 字节和 `3c4bcc62c842c916191d77e02ff3d94edf1a27af7462d09b52990bd33d66d280`；三包产物 ModInfo、磁盘文件及全部动作引用闭合，源码 ModInfo SHA-256 保持 `94869D352E031F53513FB048095730851842B75BDF7CD4398B4EAF27259BB14D`，冻结目录干净。
- 风险/待办：路径与清单闭合不能替代目标系统加载器验证；Windows/macOS 单平台包在正式分发前仍需各自实机启动、建图和模型缺失日志检查。重复二进制内容哈希登记与体积预算也尚未完成。
- 提交：`03a2f4f build: add platform-specific release profiles`。

### 2026-09-07 / M8-发布体积预算与重复二进制登记

- 目标：让包体积回归在替换产物前失败，并把相同内容的二进制路径变成可审查数据，而不是凭文件名猜测或直接去重。
- 范围：项目元数据、发布器、发布校验模块、总校验入口、README、架构、计划、测试矩阵、更新日志和工作日志；不修改运行资产内容、ModInfo、清单、版本或玩家行为。
- 设计决定：在 `tools/project.json` 为 universal/windows/macos 分别设置 800,000,000/460,000,000/460,000,000 字节硬上限；临时目录超过预算时不得替换已有产物。重复身份由未参与文本规范化文件的 SHA-256 与字节数共同确定，报告保留所有路径、拷贝数和理论可回收量，但不执行删除、硬链接或引用改写。
- 修改：发布器在原子替换前检查临时包总字节，schema 3 报告新增预算/余量及确定性排序的重复二进制组；`ReleaseChecks.ps1` 新增重复内容聚合与预算边界纯函数，主校验入口加入重复/唯一内容和恰好等于/超过/无效预算样例。
- 验证：universal 为 776,225,890 字节，距预算 23,774,110 字节；检测到 157 个重复二进制组、335,571,728 字节理论重复量，其中绝大多数由同时保留的双平台路径构成。Windows 为 442,484,953 字节、余 17,515,047 字节，macOS 为 442,484,615 字节、余 17,515,385 字节；两者均只剩 14 个重复组和 1,845,008 字节理论重复量。Windows 完整 schema 3 报告在 PowerShell 5.1/7 下逐字节相同，SHA-256 均为 `bce5e3802a61e5c14df877d63bea57068ee1368c5a941c612d17f2629d7c3bf7`；三包文件数与聚合哈希保持上一提交结果。
- 风险/待办：哈希相同不代表路径可互换；剩余 14 组涉及基础资源与 CIVITAS 资源命名空间，删除前必须追踪 `.dep`/ArtDef/BLP 的逻辑名称和目标平台实机日志。本轮只建立审计与回归门，不做冒险去重。
- 提交：`0cb201b build: enforce release size budgets`。

### 2026-09-07 / M3-随机领袖越界修复与线性洗牌

- 目标：修复赛事选人阶段房主跳过时可能从领袖数组之外取值的问题，并清理同一函数的二次方列表删除。
- 范围：大厅随机领袖洗牌/遍历、静态回归断言、更新日志、计划、测试矩阵和工作日志；不修改可选领袖来源、禁选/已选过滤、房主权限、聊天协议、ModInfo 或版本号。
- 根因：地图生成器的 `TerrainBuilder.GetRandomNumber(n)` 返回 `0..n-1`，其常见写法需要 `1 +`；大厅移植后改成 Lua `math.random(n)`（本身返回 `1..n`）却保留加 1，导致下标落在 `2..n+1`。当抽到 `n+1` 时得到空元素，`table.insert`/`table.remove` 路径可能失败或生成不完整列表。
- 修改：复制连续数组后执行从尾到头的 Fisher–Yates，交换下标直接使用 `math.random(index)`；候选选择从 `pairs` 改为 `ipairs`，明确按洗牌顺序查找首个未禁用、未选择且合法的领袖。时间复杂度从 O(n²) 降为 O(n)。
- 验证：校验器要求线性倒序循环、无偏的 `math.random(index)` 和洗牌后选人路径中的顺序数组遍历，并拒绝旧 `1 + math.random(left_to_do)`；PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 65 源码专用文件。三种 profile 重建闭合：universal 为 1072 文件、776,225,674 字节、聚合 SHA-256 `6499a7ae3c517d8c82263f3026ff9f5f3d445018a172f1e3cb24c54ce909cf49`；Windows 为 903 文件、442,484,737 字节、`b8a32dd10e403e79bf653bce6a4903fbcf3e10974c4be9c8aa9e48b01d357735`；macOS 为 903 文件、442,484,399 字节、`09db75d79eeae9dc2acd73c848373ae0ff9c7cf3967b3a597959d46b375e080b`。实机仍需在赛事选人阶段反复使用房主跳过并覆盖接近全禁选列表的边界。
- 风险/待办：UI 层 `math.random` 只由房主用于选出结果，最终领袖仍通过现有聊天与 PlayerInfo 广播同步；本轮不改变同步游戏随机流。G13 实机测试完成前不宣称运行验证通过。
- 提交：`09114a8 fix: prevent forced-leader shuffle overflow`。

### 2026-09-07 / M3-周期赛事配置快照复用

- 目标：减少大厅 1–5 秒周期刷新中对同一 GameConfiguration 值的重复跨边界查询，同时保持配置变化立即刷新和握手轮询行为。
- 范围：`OnTick`、`QuickRefresh`、`Refresh`、静态回归断言、更新日志、计划、测试矩阵和工作日志；不改变刷新间隔、阶段状态机、配置写入、玩家列表扫描、握手、聊天消息、广播或版本号。
- 设计决定：`Refresh` 成为 `DRAFT_SLOT_ORDER`/`DRAFT_TIMER` 的唯一常规刷新入口，初次 Tick 仍预热一次；`QuickRefresh` 与 `Refresh` 各自只读取一次 `CPL_BAN_FORMAT`，前者同时复用一次游戏状态。刷新提示只由完整 `Refresh` 推进。
- 修改：删除 `OnTick` 常规路径与 `Refresh` 内联块的双重赛事设置读取，改为 `Refresh` 调用已有 `RefreshTickSettings`；缓存 Ban/Pick 格式和游戏状态后复用分支条件。目标配置读取由 `DRAFT_*` 6 次加 `CPL_BAN_FORMAT` 7 次，共 13 次/周期，降为 2+2=4 次。
- 验证：校验器提取 `QuickRefresh`/`Refresh` 函数体，固定 Ban/Pick 格式各一次读取、禁止完整刷新重新直接读取 `DRAFT_*`，并要求调用统一设置函数。静态审计确认常规 Tick 不再额外调用设置函数，快速刷新不再推进提示；PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过。三种 profile 重建闭合：universal 为 1072 文件、776,225,097 字节、聚合 SHA-256 `f2f0fa79c6228d1c49387dca546de68d653a2242dcc95c7a0fc80d28c99e6a11`；Windows 为 903 文件、442,484,160 字节、`fb3a4f857b16f55c1f30a8870869d78e788f3b141c01f8d65be21f2e6cfd4dfa`；macOS 为 903 文件、442,483,822 字节、`e6f8440c1e73635652d18db32f458cd5f6727b2ddf41d28e59f1fd4cf7b1525c`。
- 风险/待办：这是跨 Lua/C++ 配置查询数的静态削减，不等于已有实机帧时间数据；仍需 P03/P10 在空闲大厅与 Ban/Pick 1 秒阶段分别采集 Lua 时间。下一步继续分离真正需要周期轮询的握手状态与只需事件触发的 UI 域。
- 提交：`8426401 perf: reuse lobby refresh configuration snapshots`。

### 2026-09-07 / M3-握手状态转换驱动玩家卡片

- 目标：停止版本握手轮询在状态稳定后仍周期性重绘所有已连接玩家卡片，并减少同一玩家的重复网络连接查询。
- 范围：`RefreshStatus`、静态回归断言、更新日志、计划、测试矩阵和工作日志；不改变握手状态值、宽限/重试/超时、版本比较、聊天消息、Tick 间隔、PlayerInfo 广播或其他玩家条目事件。
- 设计决定：每轮每名玩家只读取一次 `Network.IsPlayerConnected`，记录进入本轮时的握手状态；只有玩家仍连接、状态确实发生转换且处于默认/初始化阶段时才调用 `UpdatePlayerEntry`。槽位、准备、队伍和网络延迟继续由既有 `PlayerInfoChanged`、团队事件和 `MultiplayerPingTimesChanged` 更新。
- 修改：将循环首尾两次连接查询收敛为 `isConnected` 快照，以 `previousStatus` 守卫玩家卡片重绘。稳定状态 3/99、等待重试但尚未超时的状态 1 不再产生完整条目更新；0→1、2→3/66 和连接后重新检查仍在同一轮更新。
- 验证：校验器提取 `RefreshStatus` 函数体，要求恰好一次玩家连接查询、恰好一个受状态转换保护的 `UpdatePlayerEntry`，并拒绝旧无条件已连接分支；PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过。三种 profile 重建闭合：universal 为 1072 文件、776,225,186 字节、聚合 SHA-256 `b869878a1b07c5bdf18dad5368d26d4d525069186ad71ee891681665524a6f9c`；Windows 为 903 文件、442,484,249 字节、`b957478e1daf17188ca1355f7aeff087f6b6bf1348a009bb45bda17cd71cdd43`；macOS 为 903 文件、442,483,911 字节、`fe30b75a69315c907852968a718f0025107397b175924a1bd26fe0b3f7ded5ce`。
- 风险/待办：静态事件归属无法证明所有 Civ VI 平台版本都按相同时序发送条目事件；需在房主加两个客户端下观察加入、准备、换队、延迟变化、版本成功和超时，并确认各卡片即时更新。下一步继续把周期 `Refresh` 中不依赖握手变化的 UI 域拆为事件刷新。
- 提交：`ed42a3f perf: update lobby cards on handshake transitions`。

### 2026-09-07 / M3-大厅确定死函数清理

- 目标：继续对 8000 行大厅脚本做有证据的精简，只移除全项目无调用、无事件注册、无 XML 回调的遗留函数。
- 范围：大厅 Lua、静态回归断言、计划、测试矩阵和工作日志；不修改任何活跃回调、UI 控件、握手状态、网络消息、ModInfo、版本或玩家行为。
- 审计：从 `stagingroom.lua` 的命名函数定义生成列表，再在全仓库 Lua/XML/ModInfo 中按完整标识符反查。`CheckStatusID`、`ResetStatus_SpecificID`、空实现 `OnGameSummaryTabClicked`、`OnFriendsTabClicked` 均只有定义本身；实际标签页在 `RealizeInfoTabs` 中注册匿名回调，握手状态由 `RefreshStatusID`/`ResetStatus` 管理。
- 修改：删除上述 4 个函数，共移除两段重复线性扫描/状态重置和两个 TODO 壳；校验器拒绝这些函数名重新进入大厅运行文件。
- 验证：删除后全仓库仅在校验器禁用清单中保留四个标识符；PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过。当前大厅脚本为 8047 行、290,018 源码字节；三种 profile 重建闭合：universal 为 1072 文件、776,223,699 字节、聚合 SHA-256 `98c315d0cd9c54ab19c49f3fd760c47258e88c80c491f3c0c28055438d20c55d`；Windows 为 903 文件、442,482,762 字节、`ed0990e361f356306a0deb382f7d3fbf41236119135a0d5a39e0a21ef2d3d0db`；macOS 为 903 文件、442,482,424 字节、`71d22344f035825a600125b143c249e59bf817d7873953c70f99a81a91a290fd`。源码 ModInfo 与冻结动作图未变化。
- 风险/待办：全仓库静态引用不能证明外部未登记 Mod 会按全局函数名调用，但四个名字均为内部 MPH 实现细节且没有 LuaEvent/Context 约定；风险低。后续继续采用“定义清单 + 全仓库反查”处理死代码，避免按肉眼批量删除。
- 提交：`d80404f refactor: remove dead staging-room helpers`。

### 2026-09-07 / M2-大厅联机契约校验模块化

- 目标：把持续增长的大厅身份、生命周期、网络和性能断言从总校验入口迁移为可复用、无副作用的联机领域模块。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改任何运行资产、ModInfo、发布清单、玩家行为或版本号。
- 设计决定：`MultiplayerChecks.ps1` 只接收大厅 Lua 源文本并返回问题列表，复用 `LuaChecks.ps1` 的事件生命周期纯函数；文件读取、负向变体构造、统一错误汇总和退出码仍由 `validate.ps1` 负责。
- 修改：迁移身份局输入/开局阻断、Tick 节流、事件注销、调试日志、关键配置读取上限、握手转换更新、随机分队/空槽批量广播、随机领袖、匿名昵称和死函数回归等全部大厅源码断言。总入口以 22 行装载/调度/自检替换 125 行内联检查，从 4837 行降至 4734 行；新增模块 171 行。
- 验证：当前 `stagingroom.lua` 对模块返回 0 个问题；把 `math.random(index)` 改为 `1 + math.random(index)`、或删除 `player.Status ~= previousStatus` 守卫的两个内存反例均产生问题。PowerShell 7 与 Windows PowerShell 5.1 最终校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 66 源码专用文件；universal 重建仍为 1072 文件、776,223,699 字节、聚合 SHA-256 `98c315d0cd9c54ab19c49f3fd760c47258e88c80c491f3c0c28055438d20c55d`，证明新增工具未进入运行包。
- 风险/待办：模块目前覆盖大厅，但投票面板、重同步、断线控制器和两类计时器的详细契约仍散落在总入口；后续按控制器逐块迁移并为每块保留独立反例。
- 提交：`002ce54 refactor: extract staging-room validation checks`。

### 2026-09-07 / M2-联机控制器契约校验模块化

- 目标：继续缩小总校验入口，把投票重开、断线控制、重同步和突然死亡四组联机断言迁入无副作用的领域模块，并确保迁移后仍能识别真实回归。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改运行资产、ModInfo、发布清单、玩家行为或版本号。
- 设计决定：`LuaChecks.ps1` 新增返回问题列表的正式日志纯函数，旧的汇总包装器保持兼容；`validate.ps1` 以控制器规格表统一文件读取、函数调度和负向变体构造，具体契约与错误文本归属 `MultiplayerChecks.ps1`。
- 修改：迁移投票刷新注册/房主权限/广播去重、掉线幂等与暂停恢复、重同步限流/地图指纹缓存/输入防护、突然死亡每回合广播与参数防护等原有断言。主入口由 4734 行降至 4636 行；联机模块由 171 行扩展到 370 行。
- 验证：四份真实 Lua 源码均返回 0 个问题；分别破坏投票局部状态、掉线幂等守卫、重同步同秒限流和突然死亡同回合去重的内存反例均被拒绝。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 66 源码专用文件。universal 重建仍为 1072 文件、776,223,699 字节、聚合 SHA-256 `98c315d0cd9c54ab19c49f3fd760c47258e88c80c491f3c0c28055438d20c55d`，证明此次工具和文档改动未进入运行包。
- 风险/待办：这些仍是静态源码契约，不能代替 Civ VI 房主/客户端的时序验证；主回合计时器和其他领域检查仍留在总入口，后续继续按“纯函数 + 真实正例 + 内存反例”迁移。
- 提交：`211802c refactor: extract multiplayer controller checks`。

### 2026-09-08 / M2-主回合计时器契约校验模块化

- 目标：完成当前主入口中最后一组联机 Lua 控制器断言迁移，让 P++ 命令限额、两种 Casual 公式和计时器生命周期由独立领域函数统一维护。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改 `TurnProcessing.lua`、配置 XML、ModInfo、运行资产、玩家行为或版本号。
- 设计决定：配置 XML 中的默认值和选项定义继续留在配置域；`MultiplayerChecks.ps1` 只接收 `TurnProcessing.lua` 文本，返回命令限额、公式、写入去重、临时无计时、输入防护、死启动门和正式日志问题。
- 修改：以一组纯函数调用和内存漂移反例替换 62 行内联源码检查，并为控制器缺失增加直接错误。主入口由 4636 行降至 4593 行；联机模块由 370 行扩展到 440 行。
- 验证：真实 `TurnProcessing.lua` 返回 0 个问题；把每回合 P++ 上限守卫替换为恒假分支的内存反例被拒绝。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 66 源码专用文件。universal 产物继续保持 1072 文件、776,223,699 字节和聚合 SHA-256 `98c315d0cd9c54ab19c49f3fd760c47258e88c80c491f3c0c28055438d20c55d`。
- 风险/待办：公式与状态守卫仍是静态契约，无法证明不同联机回合模式下的广播时序和客户端显示一致；必须在 Civ VI 双客户端矩阵中实测 P++ 上限、两种 Casual 模式、临时无计时和恢复流程。
- 提交：`13be374 refactor: extract turn timer validation checks`。

### 2026-09-08 / M2-Rich Mainland 地图契约校验模块化

- 目标：把主入口中体量最大的独立地图块迁入地图领域模块，同时保持 Rich Mainland 两个公开变体、出生回退与确定性约束不丢失。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改地图 Lua/SQL/XML、ModInfo、发布清单、生成算法、玩家行为或版本号。
- 设计决定：`MapChecks.ps1` 以五个纯源码检查函数分别负责出生分配、平衡兜底、核心画布、FFA 入口和 FFA 配置，再由只读聚合函数核对 18 个 Files、3 个 Criteria 和 6 个 Action；共享路径规范化与主入口已有清单快照，不另建第二真值源。
- 修改：用 26 行装载/调度/自检替换主入口 258 行 Rich Mainland 内联检查；主入口由 4593 行降至 4361 行，新地图模块 347 行。补充空问题集合在 Windows PowerShell 5.1/PowerShell 7 下的显式兼容标记。
- 验证：当前清单、动作图及五份源码对模块返回 0 个问题；把 `__PlaceMissingMinorCivsRelaxed` 改成遗留入口名的内存反例被拒绝。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 67 源码专用文件。
- 风险/待办：静态契约只能证明高风险保护仍在源码和加载图中，不能证明固定种子输出、生成耗时或不同地图尺寸的实际出生质量；S08 继续保持未覆盖，必须通过 Civ VI 地图生成夹具或实机日志补齐。
- 提交：`dd456f6 refactor: extract rich mainland validation checks`。

### 2026-09-08 / M2-Rich Mainland 配置契约归并

- 目标：消除仍夹在 TPT/UI 区域的 Rich Mainland 配置断言，使该地图域的加载图、源码、配置和本地化由同一模块完整拥有。
- 范围：校验工具、架构、计划和工作日志；不修改地图配置、文本、地图脚本、ModInfo、运行行为或版本号。
- 修改：地图模块新增纯 XML 检查，覆盖 Team/FFA 地图条目、6/11 个尺寸、FFA 2–12 人覆盖、均匀分布参数与双语文本、路线/团队出生默认值、各尺寸城邦数、BBM 标准尺寸城邦数和四个旧 Mountainous 引用禁用；聚合函数新增只读 ModInfo 输入。主入口删除 138 行散落检查，由 4361 行降至 4223 行；地图模块由 347 行扩展到 561 行。
- 验证：PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 67 源码专用文件；原有地图源码内存反例继续被拒绝。
- 风险/待办：配置闭包完整仍不等于地图生成结果确定；固定种子摘要、尺寸生成时长和出生质量实测仍是 M7/S08 的未完成发布门。
- 提交：`87e6e1e refactor: consolidate rich mainland config checks`。

### 2026-09-08 / M2-TPT UI 契约校验模块化

- 目标：建立 UI 领域模块，收拢一组容易“文件仍在但加载失效”或恢复危险旧实现的 TPT 前端/QoL 检查。
- 范围：校验工具、架构、计划和工作日志；不修改 UI Lua/XML、配置、ModInfo、玩家行为或版本号。
- 设计决定：`UiChecks.ps1` 的聚合函数消费已有 Files/Criteria/Action 快照并只读加载相关源码；强制结束回合和随机晋升快捷键各有独立纯源码函数。缺少 Context/LuaReplace 节点时返回完整错误而不是触发空引用中止总校验。
- 修改：迁移强制结束回合三文件/动作/单次请求、LAN 名称 128 字符、开局提示脚本与文本、禁地图标记三动作、随机晋升快捷键安全清理和 BBG UnitPanel 建城处理所有权。主入口以 24 行调度/自检替换 162 行内联检查，由 4223 行降至 4085 行；新增 UI 模块 234 行。
- 验证：真实 `ForcedEndButton.lua` 返回 0 个问题；把 `ACTION_ENDTURN` 改为旧 `ACTION_UNREADYTURN` 的内存反例被拒绝。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 68 源码专用文件。
- 风险/待办：静态加载图无法证明按钮位置、可见条件、热键冲突或游戏内点击反馈；需在 UI 比例/分辨率组合和多人回合状态下实测，身份面板、贸易界面与剩余 UI 上下文检查仍待迁移。
- 提交：`f0ac9c7 refactor: extract tpt ui validation checks`。

### 2026-09-08 / M2-身份模式纵向契约模块化

- 目标：把身份模式跨配置、大厅、UI、默认值和文本的完整闭包从总入口迁入独立纵向模块，避免后续只改其中一层造成静默失配。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改发牌算法、Lua/XML 运行资产、ModInfo、玩家行为或版本号。
- 设计决定：`IdentityChecks.ps1` 分为配置纯 XML 检查、只读面板纯源码检查和工程聚合检查；实际身份发牌/重发算法继续由大厅联机模块拥有。身份模式必须只在大厅写入同步配置，游戏内面板只解析并展示，禁止注册 Gameplay 脚本或调用外交、队伍和属性写入。
- 修改：迁移六个大厅参数、隐藏发牌数据、五项依赖、两个计数域、禁止 Gameplay 文件/动作/清单、面板 Lua/XML、InGame UI 动作、大厅八控件、最终默认值、房主重置和 23 个三语文本标签。主入口以 28 行聚合/自检替换 266 行散落检查，由 4085 行降至 3847 行；新增身份模块 363 行。
- 验证：真实 `IdentityRolePanel.lua` 返回 0 个问题；把本地玩家只读入口替换成 `Game:SetProperty` 的内存反例被拒绝。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 69 源码专用文件。
- 风险/待办：静态闭包无法证明 3/6/12 人发牌、分离玩家、观察者排除、设置变化后旧牌失效和各客户端显示时序；G10、G12 与 N09 仍必须通过真实多人测试。
- 提交：`b73cb41 refactor: extract identity mode validation checks`。

### 2026-09-08 / M2-Better Trade Screen 契约模块化

- 目标：把 Better Trade Screen Lite 的完整启用闭包迁入 UI 模块，防止只加载部分文件、LoadOrder 漂移或 BBG 旧交易链同时生效。
- 范围：校验工具、架构、计划和工作日志；不修改交易 Lua/XML/SQL、ModInfo、玩家行为或版本号。
- 设计决定：聚合函数负责 Files/活跃引用、Criteria、配置开关、动作和旧链排斥；`TradeSupport.lua` 与路线选择器使用独立纯源码函数，以便针对缓存/收益兼容和排序能力构造反例。缺失 LoadOrder 节点返回领域错误，不再因空引用中止整个校验。
- 修改：迁移 14 个运行文件、双入口启用条件、自定义模式依赖、5 个连续 LoadOrder 动作、4 条旧 BBG 路径排斥、Amani 食物/生产收益、路线缓存序列化和 7 个排序处理器。主入口以 20 行调度/自检替换 100 行内联检查，由 3847 行降至 3767 行；UI 模块由 234 行扩展到 407 行。
- 验证：真实 `TradeSupport.lua` 返回 0 个问题；把 `GetBBGAmaniTradeRouteYieldBonus` 替换为遗留接口名的内存反例被拒绝。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 69 源码专用文件。
- 风险/待办：静态检查无法证明路线列表在大地图/大量城市下的帧耗、排序稳定性或 Amani 实际收益显示；需在游戏内与 BBG 总督、跨洲路线和存读档缓存组合实测。Better Deal Window 与外交条集成仍待模块化。
- 提交：`dadff11 refactor: extract better trade screen checks`。

### 2026-09-08 / M2-外交交易与地图标记集成契约模块化

- 目标：把 Better Deal Window、Detailed Map Tacks、NHK 和外交条的跨组件集成约束收拢到 UI 模块，确保每个 Civ VI UI Context 只有一个最终所有者。
- 范围：校验工具、架构、计划和工作日志；不修改外交/地图标记 Lua/XML、ModInfo、玩家行为或版本号。
- 设计决定：聚合函数消费 Action 节点、Files/活跃引用与 ModInfo 阻断表；外交条、BDW 入口和 MPH 兼容层各用纯源码函数。查找 ReplaceUIScript 时先验证节点存在，避免损坏动作图使校验器本身空引用崩溃。
- 修改：迁移 4 个唯一替换 Context、3 个外部 Mod 阻断 ID、12 个集成文件、外交条 21 个控件/顺序/默认隐藏和 25 个可见性令牌、XP2 成对导入、旧 MPH/DMT 路径排斥、BDW 商品模式与 9 个交易限制、DMT 禁标记和 NHK 三监听器去重。主入口以 22 行聚合/自检替换 191 行内联检查，由 3767 行降至 3598 行；UI 模块由 407 行扩展到 706 行。
- 验证：真实 BDW XP2 入口返回 0 个问题；把 `ZYLPVP_BDW_MPH_Compatibility` 替换为遗留兼容模块名的内存反例被拒绝。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 69 源码专用文件。
- 风险/待办：静态所有权无法证明外交交易窗口在商品模式、所有禁交易组合和不同比例 UI 下正确显示，也不能替代地图标记热键实测；这些组合仍需游戏内覆盖。
- 提交：`52300f9 refactor: extract integrated ui checks`。

### 2026-09-08 / M2-全局 UI Context 与 EndGame 所有权模块化

- 目标：把所有 ReplaceUIScript 的跨组件所有权规则和 EndGame 组合所有权迁入 UI 模块，防止集成更新重新引入双重替换。
- 范围：校验工具、架构、计划和工作日志；不修改 UI 资产、ModInfo、玩家行为或版本号。
- 修改：`Get-ZylUiContextOwnerIssues` 对每个替换动作验证 Context/LuaReplace 完整性，按 Toolbox/BBG/BBM 归属聚合并拒绝跨组件共占；`Get-ZylEndGameUiOwnershipIssues` 固定 MPH XML 发布、BBG 重复 XML 排除和 BBG Lua 扩展加载。主入口以 21 行调用/夹具替换 34 行内联检查，由 3598 行降至 3585 行；UI 模块由 706 行扩展到 787 行。
- 验证：当前动作图返回 0 个 Context 所有权问题；内存 XML 中由 BBG 与 Toolbox 同时替换 `Fixture` 的反例恰好返回 1 个冲突。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 69 源码专用文件。
- 风险/待办：所有权检查按路径命名空间判定组件，未来新增嵌入组件时必须扩展分类；运行时加载顺序和 EndGame 实际按钮行为仍需游戏内验证。
- 提交：`3c043f9 refactor: extract ui context ownership checks`。

### 2026-09-08 / M2-剩余 UI 行为契约收尾

- 目标：迁移主入口中最后三组具体 UI 行为断言，使总入口只负责装载、调度和反例，不再直接维护 UI Lua/XML 细节。
- 范围：校验工具、架构、计划和工作日志；不修改万神殿、大厅、黑名单运行资产、ModInfo、玩家行为或版本号。
- 修改：新增万神殿选择器早期事件/稳定 `row.Index` 缓存、Ban 下拉领袖纹理与默认图标回退、黑名单复制函数/剪贴板调用/按钮回调与 XML 控件闭包检查。主入口以 18 行聚合/自检替换 42 行内联检查，由 3585 行降至 3561 行；UI 模块由 787 行扩展到 888 行。
- 验证：三份真实 UI 源码均通过；把 `InstanceButton[row.Index]` 退化为瞬态 `InstanceButton[row]` 的内存反例被拒绝。主入口搜索确认 UI 相关剩余项均为模块调用、自检或非 UI 数据契约。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 69 源码专用文件。
- 风险/待办：UI 静态契约模块化已经完成，但早期万神殿事件、图标缺失降级、剪贴板权限及各种 UI 比例下的实际交互仍需 Civ VI 实机验证。
- 提交：`fb9572f refactor: finish ui validation extraction`。

### 2026-09-08 / M2-秘密结社总督点返还契约模块化

- 目标：扩展数据库契约模块，固定所有秘密结社晋升返还一个总督点的完整数据与加载条件。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改 BBG Secret Societies SQL、ModInfo、平衡值、玩家行为或版本号。
- 修改：迁移 `INSERT OR IGNORE` 幂等约束、返还 Civic、猫头鹰/炼金/虚空/血族共 16 个晋升恰好一次，以及 Ethiopia、Gathering Storm、秘密结社模式三重 Criteria。主入口以 20 行调用/自检替换 42 行内联检查，由 3561 行降至 3539 行；数据库模块由 136 行扩展到 199 行。
- 验证：真实 SQL 与 ModInfo 返回 0 个问题；把 `CIVIC_GRANT_PLAYER_GOVERNOR_POINTS` 替换为遗留 Civic 的内存反例被拒绝。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 69 源码专用文件。
- 风险/待办：静态 SQL 只能证明记录和加载门存在，不能证明游戏内每次晋升实际只返还一次；需在秘密结社开/关、四结社与存读档组合实测总督点变化。
- 提交：`738ee33 refactor: extract secret society refund checks`。

### 2026-09-08 / M2-Team PVP 秘密结社纵向契约模块化

- 目标：把 Team PVP Secret Societies 3.93 与 LightweightBalance 资源便利规则的完整闭包从总入口迁入独立纵向模块，避免平衡数据、脚本、美术、文本和加载图只更新其中一层。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改 Gameplay SQL、吸血鬼城堡 Lua、XML、本地化、美术资源、ModInfo、玩家行为或版本号。
- 设计决定：`TeamPvpSocietyChecks.ps1` 一次接收工程根目录、ModInfo、Criteria、Action 和 Files 视图，统一检查全部资源及加载闭包并只返回问题列表；可选 SQL 文本覆盖仅用于无磁盘副作用的反例。含中文契约文本的模块显式保存为 UTF-8 BOM，兼容 Windows PowerShell 5.1。
- 修改：迁移 `.dep`/ArtDef、Gameplay SQL 高风险数值与关系、吸血鬼城堡资源清理脚本、镀金船厂、三语文本、LightweightBalance 资源移除，以及秘密结社模式 Criteria、7 个数据库动作、1 个美术动作、脚本动作和 Files 清单检查。主入口以 35 行调度/自检替换 476 行内联检查，由 3539 行降至 3098 行；新增领域模块 518 行。
- 验证：真实工程返回 0 个问题；内存中把 `DiscoverAtCityStateBaseChance = 100000` 改为 `1` 后，模块准确报告缺失高风险行为。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 70 源码专用文件。universal 产物保持 1072 文件、776,223,699 字节和聚合 SHA-256 `98c315d0cd9c54ab19c49f3fd760c47258e88c80c491f3c0c28055438d20c55d`。
- 风险/待办：静态契约不能证明四结社在开/关模式、不同解锁时代、存读档和多人同步下的实际效果，也不能证明吸血鬼城堡清理资源时各客户端一致；相关组合仍需 Civ VI 实机及双客户端测试。
- 提交：`8c7860d refactor: extract team pvp society checks`。

### 2026-09-08 / M2-BBG Expanded 六资源纵向契约模块化

- 目标：把六种内嵌 BBG Expanded 资源从数据、资产、模式扩展、外部模组交接到最终中文文本的完整闭包迁入独立模块，避免上游资源更新后出现半加载。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改资源 SQL、美术资产、依赖文件、ModInfo、玩家行为或版本号。
- 设计决定：`ExpandedResourceChecks.ps1` 统一消费工程、ModInfo 和资产图视图，只返回领域问题；平衡 SQL 支持仅供反例使用的内存覆盖。动态中文文本动作的 `LoadOrder` 先判空再读取，损坏图会被完整汇总而不会中断校验。
- 修改：迁移六种资源类型及万神殿/产出标签、企鹅海岸与渔船及纸莎草平衡、325 个上游文件、ArtDef/Windows/macOS BLP、3 个外部完整模组 ID、公司模式 Criteria、8 组资源动作、动态简中标签族/最终 LoadOrder/Files 和独立 CIVITAS Resources 阻断。主入口以 34 行装载/调度/自检替换 198 行内联检查，由 3098 行降至 2934 行；新增领域模块 250 行。
- 验证：真实工程返回 0 个问题；内存中把企鹅允许地形从 `TERRAIN_COAST` 改为 `TERRAIN_OCEAN` 后准确拒绝。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 71 源码专用文件。universal 产物保持 1072 文件、776,223,699 字节和聚合 SHA-256 `98c315d0cd9c54ab19c49f3fd760c47258e88c80c491f3c0c28055438d20c55d`。
- 风险/待办：静态契约不能证明六种资源的地图生成密度、美术显示、公司产品和外部完整 BBG Expanded 启用时的实际交接；仍需在公司模式开/关、两种扩展规则与 Windows/macOS 中实机验证。
- 提交：`1a5a3d5 refactor: extract expanded resource checks`。

### 2026-09-08 / M2-精选万神殿与地热矿山纵向契约模块化

- 目标：把 13 个 Lightweight Balance 精选万神殿、ZYL 德鲁伊与 Gathering Storm 地热矿山从数据到加载图的完整闭包迁入独立模块。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改万神殿/地热 SQL、文本、图标、ModInfo、玩家行为或版本号。
- 设计决定：`PantheonChecks.ps1` 统一管理允许和排除清单、关键行为、三语本地化、图标、Action/Files、Gathering Storm Criteria 与独立 LightweightBalance 阻断，只返回领域问题；万神殿 SQL 可用内存覆盖构造反例。
- 修改：迁移 14 个允许信仰、7 个排除信仰、征战之路文化值、9 个关键机制令牌、84 个三语名称/描述节点、14 个图标、地热矿山四项约束、4 个动作/文件、扩展规则门和模组阻断。主入口以 36 行装载/调度/自检替换 122 行内联检查，由 2934 行降至 2848 行；新增领域模块 158 行。
- 验证：真实工程返回 0 个问题；内存中移除德鲁伊 `KIND_BELIEF` 注册后准确报告缺失。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 72 源码专用文件。universal 产物保持 1072 文件、776,223,699 字节和聚合 SHA-256 `98c315d0cd9c54ab19c49f3fd760c47258e88c80c491f3c0c28055438d20c55d`。
- 风险/待办：静态契约不能证明万神殿选择界面、相邻加成、公司/秘密结社组合和地热裂缝矿山在游戏内的实际产出；仍需在基础规则与 Gathering Storm、新局/读档及多人组合中实测。
- 提交：`e6e52a4 refactor: extract pantheon validation checks`。

### 2026-09-08 / M2-开局加成与初始移民纵向契约模块化

- 目标：把跨前端配置、同步 Gameplay 脚本、存档幂等、文本和初始移民数据库效果的开局功能收拢为一个领域契约，为后续联机状态重构固定行为边界。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改配置 XML、发放脚本、移民 SQL、本地化、ModInfo、玩家行为或版本号。
- 设计决定：`StartingBonusChecks.ps1` 自行读取配置和文本，并消费 Action/Files 视图；脚本文本只允许通过测试参数在内存中覆盖。玩家域严格为“无 + 真人 1–12”，类型域严格为四项；发放脚本必须按真人排序、限开局回合并持久化已发放类型，初始移民效果必须以反向宫殿条件自动失效。
- 修改：迁移两个大厅参数、13/4 个域值、9 个同步脚本令牌、Gameplay 动作/文件、4 个初始移民 Modifier、8 个 SQL 行为、反向宫殿要求、66 个三语文本节点。主入口以 33 行装载/调度/自检替换 145 行分散检查，由 2848 行降至 2736 行；新增领域模块 193 行。
- 验证：真实工程返回 0 个问题；内存中把 `player:SetProperty(APPLIED_PROPERTY, selectedBonus)` 的属性键改坏后，模块准确报告幂等写入缺失。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 73 源码专用文件。universal 产物保持 1072 文件、776,223,699 字节和聚合 SHA-256 `98c315d0cd9c54ab19c49f3fd760c47258e88c80c491f3c0c28055438d20c55d`。
- 风险/待办：静态契约不能证明 12 人排序与空槽/AI/观察者排除、出生点寻位、断线读档后不重复发放，以及四项初始移民能力在各客户端同回合消失；相关组合仍需 Civ VI 双客户端和存读档测试。
- 提交：`67b8165 refactor: extract starting bonus checks`。

### 2026-09-08 / M2-海岸与内陆领袖变体纵向契约模块化

- 目标：把三个内陆领袖从数据库别名、美术与 ModInfo 到 BBM/Rich Mainland 出生点分流的完整闭包迁入独立模块，固定“仅出生偏好不同”的设计边界。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改领袖 SQL、ArtDef、地图 Lua、ModInfo、玩家行为或版本号。
- 设计决定：`LeaderVariantChecks.ps1` 统一读取五份 SQL、两份 ArtDef 和两套出生点脚本，并消费 Action 视图；Gameplay SQL 仅允许测试参数在内存中覆盖。内陆变体必须克隆来源领袖最终 Trait、保持重复领袖关系与 TSL 支持，禁止递归生成自身/海岸标签，地图层是唯一差异所有者。
- 修改：迁移北条、腓力二世和威廉明娜三组类型/特性/重复领袖/配置/文本/图标/颜色约束，两份 ArtDef、八个 ModInfo 动作、两套海岸排除与 Rich Mainland 分类逻辑，以及已移除法国奢侈品偏好的三个旧令牌。主入口以 32 行装载/调度/自检替换 149 行内联检查，由 2736 行降至 2619 行；新增领域模块 178 行。
- 验证：真实工程返回 0 个问题；内存中破坏 `LEADER_HOJO_INLAND` 的 Trait 克隆后准确报告与来源领袖失配。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 74 源码专用文件。universal 产物保持 1072 文件、776,223,699 字节和聚合 SHA-256 `98c315d0cd9c54ab19c49f3fd760c47258e88c80c491f3c0c28055438d20c55d`。
- 风险/待办：静态契约不能证明同一来源与内陆变体并存时的大厅限制、图标/颜色显示、TSL 地图支持，以及固定种子下两套出生点算法的实际海岸分流；仍需覆盖 G07 和相关多人实测。
- 提交：`4439833 refactor: extract leader variant checks`。

### 2026-09-08 / M2-行业与公司平衡纵向契约模块化

- 目标：把 Team PVP Balanced 行业/公司削弱、DLC 与 BBG Expanded 产品补全、公司模式加载和最终简中说明迁入独立领域模块。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改行业/公司 SQL、本地化、ModInfo、平衡值、玩家行为或版本号。
- 设计决定：`MonopoliesChecks.ps1` 用解析后的 Modifier/Amount 映射而非零散字符串检查全部 50 个赋值，拒绝缺项、重复项、多余项和错误值；平衡 SQL 只允许测试参数在内存中覆盖。数据库/文本动作的 LoadOrder 节点先判空，损坏动作图会完整返回领域问题。
- 修改：迁移 8 个行业、8 个公司、28 个基础/DLC 产品和 6 个扩展资源产品数值，枫糖住房例外，两项公司模式动作与最终顺序，21 个简中效果标签和百科中的 10 种补充资源。主入口以 33 行装载/调度/自检替换 149 行内联检查，由 2619 行降至 2503 行；新增领域模块 189 行。
- 验证：真实工程返回 0 个问题；内存中把行业城市成长从 10% 改成 11% 后准确报告期望值/实际值。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 75 源码专用文件。universal 产物保持 1072 文件、776,223,699 字节和聚合 SHA-256 `98c315d0cd9c54ab19c49f3fd760c47258e88c80c491f3c0c28055438d20c55d`。
- 风险/待办：静态 SQL/文本契约不能证明行业、公司和产品在公司模式开关、DLC 资源组合及存读档中的实际加成，也不能验证百科渲染；仍需覆盖公司模式游戏内与多人测试。
- 提交：`5dcbbcc refactor: extract monopolies balance checks`。

### 2026-09-08 / M2-BBG 7.4.6 本地化闭合模块化

- 目标：把上游 BBG 玩法变更后的简中同步、英文修正和全包翻译完整性迁入独立模块，避免数据已更新但玩家仍看到旧数值或误标外语文本。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改任何本地化 XML、玩法数据、ModInfo、玩家行为或版本号。
- 设计决定：`BbgLocalizationChecks.ps1` 统一读取最终简中覆盖、上游中英文源和已解析 XML 清单，只返回领域问题；最终简中 XML 允许测试参数在内存中覆盖。覆盖层必须全为 `zh_Hans_CN` 且 Tag 唯一；上游误标的拉丁文本必须有中文覆盖；全包每个英文 Tag 必须存在简中行。缺失 `Text` 子节点不再触发空引用。
- 修改：迁移 BBG 7.4.6 关键中文正向片段、过时中文负向片段、关键英文正向/负向片段、法文误标检测、重复标签与占位符检查，以及全包英文/简中标签闭合。主入口以 38 行装载/调度/自检替换 215 行内联检查，由 2503 行降至 2326 行；新增领域模块 251 行。
- 验证：真实工程返回 0 个问题；内存中把拜占庭战斗单位说明的“宗教压力”改为漂移文本后准确拒绝。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 76 源码专用文件。universal 产物保持 1072 文件、776,223,699 字节和聚合 SHA-256 `98c315d0cd9c54ab19c49f3fd760c47258e88c80c491f3c0c28055438d20c55d`。
- 风险/待办：静态文本闭合不能证明所有占位符在 UI 中按正确数值和语法渲染，也不能发现“中英文都存在但语义共同过时”的未登记条目；仍需结合游戏内百科、领袖选择、建筑和能力提示抽样。
- 提交：`cd4d388 refactor: extract bbg localization checks`。

### 2026-09-08 / M2-BBG 图标与最终玩法文本模块化

- 目标：把 BBG 新政策/秘密结社图标与 ZYL 最终玩法说明从同一大段内联检查拆成两个职责清楚的模块，降低 UI 资产和数据库文本更新时的交叉干扰。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改图标 XML、玩法文本、数据库、ModInfo、玩家行为或版本号。
- 设计决定：`BbgIconChecks.ps1` 从 BBG SQL 动态发现政策，不维护第二份政策清单；`GameplayLocalizationChecks.ps1` 管理最终覆盖文本和嵌入副本一致性。两者只返回问题并各有内存反例。玩法 XML 的字符串读取显式使用 UTF-8，确保 PowerShell 7 与 Windows PowerShell 5.1 得到相同中文夹具。
- 修改：迁移 9 个政策和 4 个结社晋升 alias、动态政策图标闭合、UpdateIcons 动作，以及 20 个最终文本 Tag 和毛利、马里、柬埔寨、克里、舒古巴、萨拉丁、松迪亚塔、瑞典、拉美西斯、法国与俄罗斯等正/负语义约束。主入口以 73 行装载/调度/两组自检替换 264 行内联检查，由 2326 行降至 2135 行；新增图标模块 75 行、玩法文本模块 250 行。
- 验证：删除 `ICON_POLICY_EMPIRICAL_METHOD` alias 的内存 XML 会被图标模块拒绝；把马里市中心信仰由 +2 改成 +3 的内存文本会被玩法文本模块拒绝。首次 Windows PowerShell 5.1 反例因默认本地代码页损坏无 BOM 中文 XML，改为显式 UTF-8 后与 PowerShell 7 均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 78 源码专用文件。universal 产物保持 1072 文件、776,223,699 字节和聚合 SHA-256 `98c315d0cd9c54ab19c49f3fd760c47258e88c80c491f3c0c28055438d20c55d`。
- 风险/待办：静态图标闭合不能证明 Atlas 坐标与实际纹理正确；文本令牌也不能证明 UI 换行、图标替换和跨语言语义完全自然。需在政策卡、总督晋升、领袖选择、百科和能力提示中抽样实测。
- 提交：`02ce11e refactor: extract bbg icon and gameplay text checks`。

### 2026-09-08 / M2-BBG 嵌入 Tooltip 与最终参数修复模块化

- 目标：把与最终数据库不一致风险最高的 BBG 领袖/单位/伟人说明迁入独立模块，并把尾部孤立的 ModifierArguments/总督修复并回数据库契约。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改 BBG/ZYL SQL、本地化、ModInfo、平衡值、玩家行为或版本号。
- 设计决定：`BbgTooltipChecks.ps1` 只负责嵌入 tooltip 与拉美西斯玩法绑定，可用内存英文 XML 反例；`Get-ZylFinalDatabaseRepairIssues` 进入现有 `DatabaseContractChecks.ps1`，统一读取最终玩法/总督 SQL，并允许测试时覆盖源码。文本和数据库修复不再互相混杂。
- 修改：迁移萨拉丁 2 格半径、Tagma 双战斗力、挪威、忽必烈、拉美西斯六个资源 Modifier、埃塞尔弗莱德、德雷克、印度 Dharma 与腓力二世说明；另迁移文化单位、娱乐建筑旅游、伟人移动、迦太基三层购买和 Magnus/总督最终值令牌。主入口以 61 行装载/调度/两组自检替换 134 行内联检查，由 2135 行降至 2062 行；新增 tooltip 模块 114 行，数据库模块由 199 行扩展至 278 行。
- 验证：内存中把萨拉丁作用半径从 2 格回退到 1 格后 tooltip 模块准确拒绝；把摩天轮旅游修复 ID 改坏后数据库模块准确拒绝。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 79 源码专用文件。universal 产物保持 1072 文件、776,223,699 字节和聚合 SHA-256 `98c315d0cd9c54ab19c49f3fd760c47258e88c80c491f3c0c28055438d20c55d`。
- 风险/待办：静态令牌不能证明所有 Tooltip 在不同规则集/UI 中被最终行覆盖，也不能证明 ModifierArguments 实际效果无上游类型变化；需在能力面板、伟人详情、娱乐建筑、迦太基宗主和总督界面抽样实测。
- 提交：`8f2e7a6 refactor: extract bbg tooltip and repair checks`。

### 2026-09-08 / M2-BBG 上游文明平衡契约模块化

- 目标：把 ZYL 最终覆盖所依赖的 BBG 上游动作顺序、文明 SQL 和跨文件文本前置条件迁入独立模块，防止上游更新在最终覆盖之前改变基础结构。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改 BBG/ZYL SQL、本地化、ModInfo、平衡值、玩家行为或版本号。
- 设计决定：`UpstreamBalanceChecks.ps1` 拥有上游源及最终覆盖动作顺序，消费 Action/Files 视图并只返回问题；马里源码允许测试参数在内存中覆盖。BBG 简中动作的 LoadOrder 先判空，损坏 ModInfo 不再中止校验。最终 ZYL SQL 的结果断言继续保留给下一层独立契约。
- 修改：迁移四个最终覆盖动作、两份 BBG 简中动作与 Files、灾害 -1、科技 +5% 禁用、巨像头像住房，以及马里、高棉、克里、大哥伦比亚、高卢、维钦托利和图拉真源 SQL 与多份中英文副本约束。主入口以 34 行装载/调度/自检替换 311 行内联检查，由 2062 行降至 1785 行；新增领域模块 349 行。
- 验证：真实工程返回 0 个问题；内存中移除曼萨·穆萨 `GOLDEN_AGE_TRADE_ROUTE` 保留标识后准确拒绝。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 80 源码专用文件。universal 产物保持 1072 文件、776,223,699 字节和聚合 SHA-256 `98c315d0cd9c54ab19c49f3fd760c47258e88c80c491f3c0c28055438d20c55d`。
- 风险/待办：静态源契约不能证明所有文明效果在 DLC/规则集组合中的最终数据库值，也无法验证上游 SQL 执行失败时的 Civ VI 日志；下一步需迁移最终 Gameplay SQL 契约并在实机数据库日志中抽查。
- 提交：`07641f3 refactor: extract upstream balance checks`。

### 2026-09-08 / M2-ZYL 最终 Gameplay 契约模块化

- 目标：把 BBG 上游输入之后的 ZYL 最终数据库状态迁入独立模块，与上游源前置条件形成清晰的输入/输出两层契约。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改最终 Gameplay/总督 SQL、BBG 源、ModInfo、平衡值、玩家行为或版本号。
- 设计决定：`FinalGameplayChecks.ps1` 只管理最终 SQL 结果与必要上游源状态，Gameplay SQL 允许测试参数在内存中覆盖。模块不依赖 ModInfo 图，加载顺序仍由 `UpstreamBalanceChecks.ps1` 负责；同一规则的上游结构和最终覆盖可分别定位失败。
- 修改：迁移无水/海岸住房、天文导航前置、玛雅住房，毛利、马里/曼萨·穆萨、高棉、克里、大哥伦比亚、图拉真、高卢、绿洲、俄罗斯、法国/华丽壮观、斯基泰、西班牙、苏莱曼、时代着力点、约翰内斯堡、间谍/奇琴伊察损坏链，以及毛利/德国/莫克沙源约束。主入口以 28 行装载/调度/自检替换 324 行内联检查，由 1785 行降至 1489 行；新增领域模块 349 行。
- 验证：真实工程返回 0 个问题；内存中移除 `CITY_POPULATION_NO_WATER` 键后准确报告无水城市住房不再锁定为 3。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 81 源码专用文件。universal 产物保持 1072 文件、776,223,699 字节和聚合 SHA-256 `98c315d0cd9c54ab19c49f3fd760c47258e88c80c491f3c0c28055438d20c55d`。
- 风险/待办：静态 SQL 正则/令牌不能证明不同 DLC 数据表版本下全部语句成功，也不能替代最终数据库快照；需从 Civ VI Database.log 和游戏内对象抽取实际值，并为关键规则建立可重复数据库摘要。
- 提交：`1e0c8d0 refactor: extract final gameplay checks`。

### 2026-09-08 / M2-最终大厅配置与房主流程模块化

- 目标：把散落在主入口两处的前端参数、计时器、晚加载默认值、房主重置和 BBG 移民选项合并为一个完整大厅配置契约。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改 XML/Lua 运行资产、ModInfo、默认玩法、玩家行为或版本号。
- 设计决定：`LobbyConfigurationChecks.ps1` 只读取传入工程/ModInfo 视图并返回问题，复用现有时代长度、回合计时器和 Lua 生命周期检查。配置文件与 Lua 源支持内存覆盖；缺失 ZYL/CPL/大厅/房主/BBG 配置现在返回可汇总领域错误，损坏 LoadOrder 也不会因强制数值转换中止整个校验器。
- 修改：迁移 15 秒警告、外交条模式、Balanced/Relaxed Casual 定义与 P++ 限制、时代长度、16 个最终大厅默认值及动作顺序、房主 Fresh/Restore/MPH None 应用路径、房主权限与事件注销、BBG `SettlersConfig=0`。主入口由 1489 行降至 1362 行；新增领域模块 343 行。
- 验证：真实工程返回 0 个问题；内存中把最终 `CPL_SMARTTIMER` 默认值由 9 改为 8，以及移除每回合 P++ 次数上限，均被准确拒绝。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 82 源码专用文件。universal 产物保持 1072 文件、776,223,699 字节和聚合 SHA-256 `98c315d0cd9c54ab19c49f3fd760c47258e88c80c491f3c0c28055438d20c55d`。
- 风险/待办：静态配置契约不能证明 Firaxis 前端数据库的最终合并值，也不能覆盖房主切换、Restore Defaults、MPH None 和 P++ 输入在真实联机房间中的时序；这些仍需双客户端实测。
- 提交：`4768093 refactor: extract lobby configuration checks`。

### 2026-09-08 / M2-BBM 根美术依赖与坏引用边界模块化

- 目标：把 BBM 根级 `.dep` 装载链和已清理的上游坏引用集中到独立兼容性契约，避免艺术资源升级时只检查“文件存在”而漏掉动作或平台依赖。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改 `.dep`、ArtDef、BLP、ModInfo、运行包内容、玩家行为或版本号。
- 设计决定：`ArtIntegrationChecks.ps1` 同时消费 Action、Files 与活跃引用视图，安全处理没有 File 子节点的 UpdateArt 动作，读取 `NaturalWondersMod.dep` 后核对根 `ArtDefs` 和 Windows/macOS BLP。依赖 XML 支持内存覆盖，模块只返回问题；缺失 dep 现在给出领域错误而不是依赖后续空引用。
- 修改：迁移唯一根 UpdateArt 动作、dep 中所有 ArtDef/PackageDependencies 双平台闭包，以及 BBG 印度尼西亚/高棉、苏丹萨拉丁和 BBM 两条失效文件引用防回流检查。主入口由 1362 行降至 1359 行；新增领域模块 99 行。
- 验证：真实工程返回 0 个问题；内存中把首个 ArtDef 依赖改为 `__selftest_missing__.artdef` 后准确拒绝。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 83 源码专用文件。universal 产物保持 1072 文件、776,223,699 字节和聚合 SHA-256 `98c315d0cd9c54ab19c49f3fd760c47258e88c80c491f3c0c28055438d20c55d`。
- 风险/待办：静态闭包不能证明 Civ VI 在 Windows/macOS 上实际解析 `.dep`、ArtDef 和 BLP 成功，也不能验证纹理/模型视觉结果；两平台包仍需实机加载和地图生成抽样。
- 提交：`4d36112 refactor: extract art integration checks`。

### 2026-09-08 / M2-包身份与多人握手契约模块化

- 目标：把项目单一版本源、ModInfo 可见身份和 Gameplay 多人握手收敛为一个跨前端/游戏内契约，避免以后改名或升版时只更新一半。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改 `project.json`、ModInfo、`MP_helper.lua`、运行包内容、玩家行为或版本号。
- 设计决定：`PackageIdentityChecks.ps1` 读取项目期望值和 ModInfo/XML 视图，只返回问题；多人辅助源支持内存覆盖。ModInfo 的属性节点、标题/描述节点及辅助文件缺失时现在给出可定位错误，不再通过直接 `.InnerText` 访问提前中止总校验；中文错字以 Unicode 码位构造，模块保持 ASCII 并兼容 Windows PowerShell 5.1。
- 修改：迁移 Mod ID、三处版本值、本地化标题键、英/简中标题、简中描述已知错字、`MP_helper.lua` 版本握手、掉线恢复的保存移动力路径、正式日志包装，以及随机流/旧清空移动力/死函数禁用项。主入口由 1359 行降至 1349 行；新增领域模块 134 行。
- 验证：真实工程返回 0 个问题；内存中把 `ZYLPVPMOD v1.3.0` 握手改为漂移版本后准确拒绝。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 84 源码专用文件。universal 产物保持 1072 文件、776,223,699 字节和聚合 SHA-256 `98c315d0cd9c54ab19c49f3fd760c47258e88c80c491f3c0c28055438d20c55d`。
- 风险/待办：静态字符串一致只能保证双方声明同版，不能证明 Steam 实际分发内容一致或断线重连状态正确恢复；版本不一致阻断和移动力恢复仍需双客户端实测。
- 提交：`3b3205f refactor: extract package identity checks`。

### 2026-09-08 / M2-多人 UI 运行时调度与自检收拢

- 目标：把主入口中等待室、四个联机控制器和主菜单的文件读取、函数选择及漂移夹具收回 `MultiplayerChecks.ps1`，让入口只负责编排领域和汇总错误。
- 范围：校验工具、架构、计划、测试矩阵和工作日志；不修改任何 Lua 运行资产、ModInfo、联机协议、玩家行为或版本号。
- 设计决定：新增 `Get-ZylMultiplayerUiRuntimeContractIssues` 统一处理六个源码入口，新增无副作用的 `Get-ZylMultiplayerUiRuntimeSelfTestIssues` 管理七类内存漂移；主菜单取得独立 `Get-ZylMainMenuContractIssues`，与其他控制器一样只返回生命周期/日志问题。缺文件由实际契约报告，自检则跳过不存在的夹具，避免同一根因重复噪声。
- 修改：迁移 staging room 正例、线性洗牌和握手状态转换反例，VotePanel/DropControl/MPHOptions/SuddenDeathPanel 四个控制器正反例，以及 main menu 调试开关、Shutdown、跨平台大厅/系统更新事件注销和正式日志检查；新增主菜单 Shutdown 漂移反例。主入口由 1349 行降至 1257 行，`MultiplayerChecks.ps1` 由 440 行扩展至 619 行。
- 验证：六个真实 UI 源返回 0 个问题，七个内存漂移全部被对应领域函数拒绝。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 84 源码专用文件。universal 产物保持 1072 文件、776,223,699 字节和聚合 SHA-256 `98c315d0cd9c54ab19c49f3fd760c47258e88c80c491f3c0c28055438d20c55d`。
- 风险/待办：静态 Lua 片段不能证明事件在 Civ VI 热载入、掉线重连和房主切换时只注册一次，也不能测量状态广播顺序；仍需双客户端执行 N02/N03/N05/N06。
- 提交：`06662e0 refactor: centralize multiplayer ui validation`。

### 2026-09-09 / M3-普通大厅周期全量刷新门控

- 目标：停止普通等待室在状态稳定时每 4–5 秒重复执行完整 `QuickRefresh + Refresh`，同时保留赛事阶段动画/流程刷新和版本握手重试。
- 范围：`ui/stagingroom.lua`、联机静态契约、架构、计划、测试矩阵、更新日志和工作日志；不改变 ModInfo、SQL、平衡值、版本号或握手协议。
- 设计决定：新增 `g_full_refresh_requested`。首次显示、配置变化、HostReset、玩家加入/离开和房主迁移显式请求刷新；普通阶段的 OnTick 仅在该标志为真时执行一次全量刷新，`g_phase ~= PHASE_DEFAULT` 的赛事阶段仍持续刷新，`RefreshStatus` 与轻量编辑按钮状态保持独立周期执行。配置事件已同步完成刷新后清除请求，避免下一周期重复。
- 修改：OnTick 增加请求/赛事门控，并在会改变房间阶段或上下文可见性的六条路径维护请求标志；`Get-ZylStagingRoomContractIssues` 新增 OnTick 结构和调用次数断言，联机模块新增把门控强制为 `true` 的第八类内存反例。
- 验证：门控源码在 PowerShell 7 与 Windows PowerShell 5.1 下通过完整静态校验；内存中恢复无条件全量刷新后会被 staging-room 契约拒绝。当前环境没有独立 Lua 解析器，实际 Civ VI 空闲 60 秒计数、赛事 Ban/Pick 和成员/房主事件刷新仍需实机验证。三种 profile 均构建通过：universal 1072 文件、776,224,089 字节、SHA-256 `d4b96cdaa1123aa5fd654e4f6a741248b27aa850ae62b08cd27e34067916219a`；Windows 903 文件、442,483,152 字节、`554d798d324c1d2c51420dc450426db004f4a31081cbc2f93ef648ca7f6403a9`；macOS 903 文件、442,482,814 字节、`c5bf50979a28c6f53ee7d2857ad78e563346ebd2b739f08a03471e9fb3b8c4ce`。
- 风险/待办：Firaxis 可能存在不触发已登记事件的隐式 UI 状态变化；若实测发现，应为对应事件补充请求标志，而不是恢复普通阶段固定全量轮询。优先执行 P01、G05/G06、N02/N03/N06。
- 提交：`2e4ee53 perf: gate idle lobby full refreshes`。

### 2026-09-09 / M3-赛事设置脏缓存

- 目标：停止 Ban/Pick 赛事阶段每秒重复读取只会随游戏配置事件改变的 `DRAFT_SLOT_ORDER` 和 `DRAFT_TIMER`。
- 范围：`ui/stagingroom.lua`、联机静态契约、架构、计划、测试矩阵、更新日志和工作日志；不改变选人规则、倒计时公式、ModInfo、版本号或网络协议。
- 设计决定：新增 `g_tournament_settings_dirty`，初始化和重新显示时为脏；`OnGameConfigChanged` 在调用完整刷新前标脏，`RefreshTickSettings` 读取两项后清除。`Refresh()` 只在脏时调用该函数，赛事周期仍各读取一次 Quick/Full 所需的 `CPL_BAN_FORMAT`，不在本批次改变函数参数或阶段状态机。
- 修改：把赛事设置读取从每次 `Refresh()` 改为事件失效缓存；静态契约要求脏标志、清除点和条件调用同时存在，并增加把条件改回恒真的第九类联机内存反例。
- 验证：PowerShell 7 与 Windows PowerShell 5.1 完整校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 84 源码专用文件；内存反例恢复周期读取后被准确拒绝。当前环境无 Lua 解释器；赛事设置变更、重开/重新显示和倒计时仍需 G05/G06/G13 实机回归。三种 profile 均构建通过：universal 1072 文件、776,224,282 字节、SHA-256 `b6f8b33c83d8e2390de001c059b8b345f33591579e9451ad3134bf7029f04262`；Windows 903 文件、442,483,345 字节、`6d1d7d8c0d5ad5217c9fa6bf694d6489129fe30529f12c15597d9a8596787daa`；macOS 903 文件、442,483,007 字节、`8fb141c23690fac1981598584b9b6e0575303e32d2d36af177b78be6a5ae9754`。
- 风险/待办：依赖 Civ VI 对 `DRAFT_*` 变化触发 `GameConfigChanged`；若实测发现特定本地修改不触发，应在对应写入入口标脏，不能恢复周期读取。
- 提交：`574aab0 perf: cache tournament lobby settings`。

### 2026-09-09 / M3-Mod 能力与玩家昵称子域缓存

- 目标：移除赛事阶段每秒遍历启用 Mod 和全部玩家槽的两个稳定子域，同时保持匿名昵称切换、玩家变动和 Mod 下载后的即时一致性。
- 范围：`ui/stagingroom.lua`、联机静态契约、架构、计划、测试矩阵、更新日志和工作日志；不修改 ModInfo、匿名模式规则、玩家名称协议、版本号或 Gameplay。
- 设计决定：`RefreshModCapabilities` 从 `Refresh` 提取并由 `g_mod_capabilities_dirty` 驱动，配置事件、Mod 状态和重新显示使其失效；Mod 状态事件还请求一次完整刷新。全玩家昵称块由 `g_player_names_refresh_requested` 或匿名模式实际变化驱动，并同步更新 `g_Anon`；已有 `OnPlayerInfoChanged`/`Anonymise_ID` 保持单玩家定向路径。
- 修改：稳定赛事周期不再调用 `GetEnabledMods`、遍历四个能力值或遍历所有玩家重绘昵称；`GetEnabledMods` 增加 nil 回退。静态契约要求两个失效条件、能力函数和全量昵称门控，并新增把两者改成恒真的第十/十一类联机内存反例。
- 验证：PowerShell 7 与 Windows PowerShell 5.1 完整校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 84 源码专用文件；两个内存反例均被准确拒绝。当前环境无 Lua 解释器；匿名开关、玩家改名/加入和 Mod 下载完成后的 UI 结果仍需 G05/G06/G12/N06 实机回归。三种 profile 均构建通过：universal 1072 文件、776,224,872 字节、SHA-256 `f0ed26ef11dc0f6f05c9aa5b20ca49775e1de4f948ca1f328d411fb6c02df39f`；Windows 903 文件、442,483,935 字节、`85daa2cd0dadb252b104ec4e9ef644cd87a0996f310cf8475ca415d95804f525`；macOS 903 文件、442,483,597 字节、`444e3d3c41bf7ce5e802c272cf9cc70098f58bb40f337056116d8f82b817555b`。
- 风险/待办：依赖 `GameConfigChanged`/`ModStatusUpdated` 覆盖启用 Mod 集合变化，且依赖现有单玩家事件覆盖稳定匿名模式下的加入/改名；若日志显示漏刷，应补对应失效入口，不恢复周期全扫。
- 提交：`f8379b0 perf: cache lobby refresh subdomains`。

### 2026-09-09 / M3-多人握手状态 playerID 索引

- 目标：消除单玩家加入、版本回复和状态查询对 `g_player_status` 的线性扫描，同时保持现有有序数组的批量 UI 遍历顺序。
- 范围：`ui/stagingroom.lua`、联机静态契约、架构、计划、测试矩阵、更新日志和工作日志；不修改握手消息格式、超时/重试值、ModInfo、版本号或数据库。
- 设计决定：新增 `g_player_status_by_id`，`AddPlayerStatus` 同步写数组/索引，`ClearPlayerStatusCache` 原子清空两者；工程内六个插入点和四个清空点全部改用帮助函数。`RefreshStatusID` 每次只读取一次连接状态和玩家配置，已有/回复记录直接索引；批量 `RefreshStatus` 继续按数组顺序运行。
- 修改：`RefreshStatusID` 移除两个全数组扫描，`GetStatus_SpecificID` 改为 O(1)；连接已建立但 `PlayerConfigurations[playerID]` 尚未就绪时不再空引用崩溃，而是保留/等待后续事件。静态契约要求所有插入都集中在帮助函数、单玩家函数不得出现 `pairs/ipairs(g_player_status)`，并增加移除索引读取的第十二类联机内存反例。
- 验证：PowerShell 7 与 Windows PowerShell 5.1 完整校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 84 源码专用文件；移除直接索引的内存反例被准确拒绝。剥离 Civ VI 专有类型注解后，Python `luaparser` 对完整 staging room 的 AST 解析通过。三种 profile 均构建通过：universal 1072 文件、776,224,728 字节、SHA-256 `d856b3cf01030aebedcd259c1f5de749a46e76e83329b245fcae8059f2eff1c8`；Windows 903 文件、442,483,791 字节、`fcd6eb80b9faaf174ffa376683141ae663a08b1b119ff28adb883396f9332f00`；macOS 903 文件、442,483,453 字节、`8e69feb5ea9c15118dcf811aad30efd71bda5ed002d567fa0c085d5f8baa33ec`。12 人加入、重复版本回复、断线/重连和房主迁移仍需 G05/G06/G12/N02/N03 实机回归。
- 风险/待办：数组和索引必须始终同源；契约已禁止旁路插入，但真实事件乱序仍可能暴露 stale entry，需要双客户端日志确认。
- 提交：`94e2334 perf: index multiplayer handshake status`。

### 2026-09-09 / M3-版本回复终态幂等

- 目标：阻止重复或迟到的客户端版本回复把已完成、已失败或房主握手记录重新置为待验证，避免重复反馈和错误状态倒退。
- 范围：`ui/stagingroom.lua`、联机静态契约、架构、计划、测试矩阵、更新日志和工作日志；不修改握手消息格式、超时/重试值、ModInfo、版本号或数据库。
- 设计决定：`RefreshStatusID` 在处理版本号前直接读取 playerID 索引；状态 3（成功）、66（版本错误）和 99（房主）均视为本轮终态并忽略后续回复。手动 Mod Check 和断线重连仍先通过现有清空/重建路径显式开启新一轮握手，因此不会被终态守卫永久锁死。
- 修改：在版本回复分支加入终态提前返回；联机契约固定守卫，并新增把守卫替换为恒假的第十三类内存漂移，防止后续重构重新开放终态。
- 验证：剥离 Civ VI 专有类型注解后，Python `luaparser` 对完整 staging room 的 AST 解析通过；PowerShell 语法解析、PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 84 源码专用文件；终态重开内存反例被准确拒绝。三种 profile 均重建闭合：universal 1072 文件、776,224,825 字节、SHA-256 `a6dc55c428ef83c02eee4f9720227df6fa8ecc70265680d75183c96f1743a7b1`；Windows 903 文件、442,483,888 字节、`58a8696aa490c676df36967d53bd27e2c216f40878cfa9994598b146a4bbbe6e`；macOS 903 文件、442,483,550 字节、`78a466911396830b308517d121eff82a0a851b9968f4320c62b765446a03447e`。
- 风险/待办：静态契约验证终态不会被单条回复重开，但仍需 G05/G06/G12/N02/N03/N04 实机覆盖成功后重复回复、错误后迟到回复、手动复查、重连和房主迁移。
- 提交：`7ce1d3e fix: keep handshake terminal states idempotent`。

### 2026-09-09 / M5-数据库表级写集合基线

- 目标：把所有实际加载的数据库源、条件、顺序和触及表变成可重复查询的机器报告，为后续识别死写、重复覆盖和兼容性冲突建立冻结证据。
- 范围：新增数据库写集合校验模块、报告器和契约文件，接入总校验并更新架构、计划、测试矩阵、Manifest 说明和工作日志；不修改任何运行数据库源、ModInfo、版本号或发布文件。
- 设计决定：扫描范围取 FrontEnd/InGame 的全部 `UpdateDatabase`，而不是按扩展名猜测磁盘文件；同一源的多动作/多 Criteria 引用分别保留。SQL 解析按引号/注释安全地切分语句，识别 insert/replace/update/delete/create/drop/alter table；XML 只接受 Civ VI 数据动作 `Row/InsertOrIgnore/Replace/Update/Delete`。逐操作行号仅用于定位，不进入语义指纹，注释和空行变化不会伪造写集合漂移。
- 修改：新增 `DatabaseWriteSet.ps1`、`report_database_writes.ps1` 和 `database-write-set-contract.json`；契约永久保存冻结 1.3.0 指纹，同时单独维护当前预期指纹。计划中的旧口径 247 已按真实动作图修正为 145 个动作、286 次引用、254 个唯一源（234 SQL、20 XML）。
- 结果：当前共识别 6192 次表级写操作、223 张表和 135 张由多个源触及的表；发现 5 个活跃 SQL 只有注释而无写入：`Base/GreatWorks.sql`、两个秦始皇统一者 LP 条件文件、`mali_dlc_babylon.sql` 和 XP1 `Netherlands.sql`。多源触及仅作为主键级分析候选，不直接判定冲突。
- 验证：SQL 自检覆盖注释假语句、引号内分号、四种标识符引用、冲突模式和六类写法，并拒绝缺少 `SET` 的畸形 UPDATE；XML 正例覆盖五种动作，`Merge` 反例被拒绝；指纹漂移反例被契约拒绝。冻结原目录与当前目录分别扫描得到相同语义 SHA-256 `29aa1f00656a94493c5ea1c443d169d3c0eaf806c2cdb5dc259a15aef6c37e56`。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、283 Actions、1077 Files、549 活跃引用、48 休眠文件和 87 源码专用文件；两套运行时生成的 934,527 字节报告逐字节一致，文件 SHA-256 为 `29c8c14dc8d68c4994f28964c8d80d1f24053e60e2a4f3681cbee3afd59929b3`。
- 风险/待办：本批只证明“哪些源以何种操作触及哪些表”，尚不能区分条件互斥、同主键覆盖或最终值等价；下一批应提取 INSERT/XML 行的键候选，并对 UPDATE/DELETE 的 WHERE 范围建立保守分类，不能按 135 张重叠表或 5 个零写源直接批量删除。
- 提交：`ea0d371 refactor: baseline database write sets`。

### 2026-09-09 / M5-零写入数据库源清理

- 目标：删除表级报告确认的 5 个零写入 SQL 和 3 个空数据库动作，在不改变任何实际 SQL/XML 写入的前提下缩小加载图和发布包。
- 范围：BBG InGame 动作/Files 分域源、生成 ModInfo、5 个注释空文件、动作图与数据库写集合契约、组装器顺序语义、报告器、架构、计划、测试矩阵、更新日志和工作日志；不修改有效数据库语句、Criteria 定义、玩法值、包身份或版本号。
- 设计决定：`manifestOrder` 从连续数组下标改为正数唯一的稳定排序号；删除条目保留 122/131/133 等历史空洞，避免机械重排后续动作和 700 余文件。动作图契约升级为冻结 1.3.0 与当前分支双字段，冻结 SHA/计数永久保留，有意精简只更新当前字段。数据库写集合采用同样的冻结/当前模型。
- 修改：从 BBG Base/XP1 聚合动作移除 `GreatWorks.sql`、XP1 `Netherlands.sql` 两个空文件；完整移除 Babylon XP2、秦始皇统一者 XP1/XP2 三个仅加载空 SQL 的动作；从 Files 清单和 2.0 源码树删除全部 5 个文件。文件仍可从冻结目录和 Git 历史恢复。
- 等价证据：数据库动作 145→142、引用 286→281、唯一源 254→249（234→229 SQL，XML 保持 20），零写入源 5→0；识别出的写操作仍严格为 6192 次、223 张表、135 张多源触及表。Criteria 保持 108，FrontEnd Action 保持 32；InGame Action 251→248，Files 1077→1072，活跃引用 549→544。当前动作图 SHA-256 为 `16501b36cc20ad1401f958e5271d7d94349c7259e81da458a2ce08e24bcd1019`，冻结动作图 `f41a5c55fc7000b435ffe645d4c25df358ad3950b1e03f105b64d07e49ba14af` 未覆盖；当前数据库写集合为 `a1dee0fdd2f779b020fc017024ffbf6233507a275ec3e57b4a070de5e428a56c`，冻结写集合 `29aa1f00656a94493c5ea1c443d169d3c0eaf806c2cdb5dc259a15aef6c37e56` 未覆盖。
- 验证：PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、280 Actions、1072 Files、544 活跃引用、48 休眠文件和 87 源码专用文件；数据库与动作图报告生成通过。三种 profile 均构建闭合：universal 1067 文件、776,218,110 字节、SHA-256 `6a50a6fb107bd7fe134be8116915b20e1a42640579ba9329db46616cc27b2298`；Windows 898 文件、442,477,173 字节、`a5095b31b250f46995b42868973b731621e23565f5faf671107a137b2d6e1b42`；macOS 898 文件、442,476,835 字节、`7a694a51739c02e7983617baa6fa86f0213b8c846463f60667632c6c9ba06e23`。
- 风险/待办：空动作删除依赖“注释不执行”的 SQLite/Civ VI 常规语义，静态与报告证据充分；仍需目标平台实机加载确认 BBG DLC 组合日志中不再出现这三个动作且无意外加载器依赖。下一批继续做主键级重叠分析，不把表级重叠直接当成冲突。
- 提交：`bb86e32 refactor: remove empty database loads`。

### 2026-09-09 / M5-同动作精确重复 SQL 清理

- 目标：识别并删除不同 SQL 文件在同一个数据库动作中必然重复执行的完全相同语句，同时保留不同 DLC/配置 Criteria 分支中的有意重复。
- 范围：数据库写集合扫描器/报告/双契约、BBG Base Beliefs/GreatPeoples、文化胜利 SQL 及其动作/Files 清单、生成 ModInfo、架构、计划、测试矩阵、更新日志和工作日志；不合并仅仅触及相同表或处于不同动作的语句，不修改玩法目标值、包身份或版本号。
- 设计决定：每条 SQL 写语句增加剥离注释并安全切分后的 SHA-256；只有相同指纹出现在不同文件、且所有文件共享至少一个完全相同的 `scope:actionId` 时才列入“同动作精确重复”。同一文件内阶段性重复和不同 Criteria 动作中的相同语句不进入自动清理候选。
- 修改：从后加载的 `GreatPeoples.sql` 删除已由同一 BBG Base 动作内前置 `Beliefs.sql` 以 `INSERT OR IGNORE` 建立的 Requirements、RequirementArguments、RequirementSets、RequirementSetRequirements 四条定义；从 `new_bbg_cv_2.sql` 删除基础 `new_bbg_cv.sql` 已执行的同值旅游阈值 UPDATE。后者随即成为零写入文件，故从三个始终同时加载基础文件的动作、Files 清单和 2.0 源码树一并移除，仍可从冻结目录或 Git 历史恢复。
- 等价证据：数据库动作保持 142，引用 281→278，唯一源 249→248（SQL 229→228，XML 保持 20）；写操作 6192→6187，但触及表仍为 223、多源触及表仍为 135、零写入源仍为 0；同动作精确重复组由冻结基线的 5 降为 0。动作总数保持 280，Files 1072→1071，活跃引用 544→543。当前数据库写集合 SHA-256 为 `6e17ece0f355448df595dafbc10413c14202c96b22c248367cdc7c63c62fd202`，当前动作图为 `6b183e57b359f46c6d70321f98dddf9b424c11d84ae8dae637db78d551cee2c2`；两份冻结指纹均保持不变。
- 验证：PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、280 Actions、1071 Files、543 活跃引用、48 休眠文件和 87 源码专用文件；两套运行时生成的 1,381,536 字节数据库报告逐字节一致，文件 SHA-256 为 `7f337aa9696c30641220395d698fb8f8b0fa56abbf5a559990289b78c0d66da3`。三种 profile 均构建闭合：universal 1066 文件、776,216,449 字节、SHA-256 `f93b09c827e84677cde0815926875b0983a768929689bd20b6659e49bb041e44`；Windows 897 文件、442,475,512 字节、`5fd72074ba21c7b9ad5380c82da782bd241672dbfc57920f603cb59f4ff72714`；macOS 897 文件、442,475,174 字节、`6223689663a3c9307b30c959c79b428c2b93d348301e6255ea1eb08fc58062a4`。
- 风险/待办：本批等价性依赖同一动作中文件声明顺序和 `INSERT OR IGNORE`/同值 UPDATE 语义，已由动作引用报告和当前指纹固定；仍需实机对文化胜利设置 2/全局设置 2/Legacy、Boudica 与 Initiation Rites 做数据库日志或百科值抽查。下一步继续主键级分析，不能把不同 Criteria 下的相同 SQL 误判为重复。
- 提交：`d540bfa refactor: remove same-action duplicate sql`。

### 2026-09-09 / M5-官方 Schema 主键快照

- 目标：为主键级写集合和最终值冲突分析建立可审查的官方表结构依据，同时保证日常构建/校验不依赖本机 Steam 路径。
- 范围：新增官方 Schema 导出器、键快照、Schema 校验/覆盖模块、外部表契约，接入数据库报告和总校验，并更新工程元数据、忽略规则、Manifest 说明、架构、计划、测试矩阵和工作日志；不修改任何运行资产、数据库动作、ModInfo、玩法值、包身份或版本号。
- 设计决定：一次性读取本机 Civ VI build 15296837 的 `01_GameplaySchema.sql`、Expansion1/2 Schema、四份 Configuration Schema 和三份 Gameplay XML Schema，在独立内存 SQLite 中分别建立 configuration、gameplay-base、gameplay-xp1、gameplay-xp2；只把表列、主键、唯一键、相对源路径及源 SHA-256 固化入仓库。验证器只读快照及 `project.json` 中的快照哈希/build id，不读取游戏安装目录。
- 修改：新增 `tools/schema/export_civ6_schema_keys.py`、368,010 字节 `manifest/civ6-schema-keys.json`、`DatabaseSchemaChecks.ps1` 和 `external-database-tables.json`；数据库报告新增逐表 Schema 分类和主键字段。导出器使用 Python 标准库 sqlite3/XML/JSON，`-B` 重导不会生成缓存，`.gitignore` 也显式排除 `__pycache__`/`.pyc`。
- 结果：快照含 Configuration 78 表、基础 Gameplay 318 表、XP1 351 表、XP2 428 表，三个 Gameplay ruleset 的同名表主键无漂移。当前写集合触及的 223 表中，199 张解析到官方 Schema、186 张有显式主键，22 张由项目自身 CREATE TABLE；仅 `ConfigEnabledUniqueUnits` 与 `EnabledUniqueUnits` 属外部 BBG Expanded/MOAR Units 表，二者所有动作均由 WIP/Release 提供者 Mod ID 的 `ModInUse` Criteria 门控。
- 验证：导出器重跑得到与跟踪快照相同的 SHA-256 `2bf887e0437393706e0a6bdfdc4b01ef399e664e3ec1925005c5ee9b0376db4b`；错误主键列和缺失外部提供者表两个内存反例均被拒绝。PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、280 Actions、1071 Files、543 活跃引用、48 休眠文件和 91 源码专用文件；两套运行时数据库报告逐字节一致。此次全部是开发期快照/工具/文档，三个发布包内容与 `d540bfa` 保持不变。
- 风险/待办：快照对应 build 15296837；游戏更新官方 Schema 后必须显式重导并审查哈希/主键变化。22 张项目自建表的键仍需从 CREATE TABLE 提取，13 张无显式官方主键的表需保守处理；外部表结构不能凭提供者存在而猜测。下一步只对已解析主键且 INSERT/XML 行可静态求值的写入生成键候选。
- 提交：`28f5dbd refactor: snapshot official database schemas`。

### 2026-09-09 / M5-SQL/XML 主键候选分析

- 目标：把表级“多个文件触及同一表”收窄为可审查的具体主键行，且不把条件互斥、顺序覆盖或冲突模式不同的写入误删为重复代码。
- 范围：新增 `DatabasePrimaryKeys.ps1` 和主键分析契约，把分析接入数据库报告与总校验，并更新工程元数据、Manifest 说明、架构、计划、测试矩阵和工作日志；不修改运行资产、数据库动作、玩法值、ModInfo、包身份或版本号。
- 设计决定：仅解析 SQL `INSERT/REPLACE ... VALUES` 和 XML `Row/InsertOrIgnore/Replace`；显式列按列名映射，省略列名时仅接受所有相关官方 profile 完全一致的列序。所有主键字段都必须是字符串、数字、NULL、布尔或 blob 字面量；`INSERT ... SELECT`、表达式主键、缺失主键字段、无官方主键、外部表和项目自建表均保守留作未解析。重复主键只生成候选组，并额外计算所有出现位置是否共享同一数据库动作。
- 结果：共发现 4288 个 INSERT/REPLACE 操作，2846 个完全解析、0 个部分解析、1442 个未解析；得到 120 张表的 6632 行主键候选。未解析操作分为 `insert-select` 362、`missing-primary-key-column` 196、`mod-created-schema-pending` 44、`no-primary-key` 840。共出现 20 组重复主键，但同一动作内重复为 0，因此本批不删除任何 SQL/XML；后续必须结合 Criteria、加载顺序、冲突模式和最终值逐组判定。
- 契约：`manifest/database-primary-key-contract.json` 固定当前分析 SHA-256 `4ec2ec940411b74e694ebda80d305437f3020e996c230ed007ba32c8a91d3abc`、覆盖计数与未解析原因；解析器有带逗号字符串、嵌套函数、转义字符串和 `INSERT ... SELECT` 正/负自检，契约有错误指纹反例。
- 验证：PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、280 Actions、1071 Files、543 活跃引用、48 休眠文件和 93 源码专用文件；两套运行时生成的 5,615,311 字节完整数据库报告逐字节一致，SHA-256 为 `4763d26389e5a273fa8be5dc430d74f7526296d9d575df7f615ed828e28a0f33`。表级写集合 SHA-256 保持 `6e17ece0f355448df595dafbc10413c14202c96b22c248367cdc7c63c62fd202`；本批不改变发布包内容，最近三个发布包仍与 `d540bfa` 相同。
- 风险/待办：当前不对 22 张项目自建表推断主键，不使用无显式主键表的唯一键替代主键，也不静态执行 362 个 `INSERT ... SELECT`。下一步从项目 `CREATE TABLE` 提取可验证键结构，并为 20 个重复候选组建立 Criteria/顺序审查；实机数据库与日志仍是最终等价性门槛。
- 提交：`21769d9 refactor: analyze literal database row keys`。

### 2026-09-09 / M5-项目自建表主键补齐

- 目标：消除主键候选分析中“项目自建表结构待定”的人为缺口，同时不为真实无主键的临时表、映射表或设置表臆造唯一性。
- 范围：扩展 `DatabasePrimaryKeys.ps1` 的 `CREATE TABLE` 解析、主键分析契约、总校验自检、数据库报告输出及相关文档；不修改运行资产、建表 SQL、动作图、玩法值、ModInfo、包身份或版本号。
- 设计决定：从 22 条活跃 `CREATE TABLE` 语句直接提取列序、临时表标记以及表级/列级 `PRIMARY KEY`，并将解析结果纳入主键分析语义指纹。只有声明了主键的自建表进入行候选；没有主键的 13 张表标记为 `mod-created-no-primary-key`。不会用列名习惯或当前数据碰巧唯一来推断主键。
- 结果：22 张自建表全部成功解析，其中 9 张有显式主键、13 张无主键。完全解析的 INSERT/REPLACE 操作由 2846 增至 2862，未解析由 1442 降至 1426；行候选由 6632 增至 6725，覆盖表由 120 增至 127。新的未解析分布为 `insert-select` 372、`missing-primary-key-column` 196、`mod-created-no-primary-key` 18、`no-primary-key` 840；`BBCC_DynamicYields`、`CustomPlacement` 虽有键但仅由 `INSERT ... SELECT` 写入，因此没有静态行候选。重复主键仍为 20 组、同一动作仍为 0，本批不删除数据库代码。
- 契约：主键分析基线推进到 `21769d9`，SHA-256 更新为 `3bb96c922c15895e331d896d02487a33c4a726c8fc0b6115d07098e4efbe9a28`；新增自建表总数/有键表数计数。内存自检覆盖临时表、`IF NOT EXISTS`、引号列名、列级主键、唯一约束和外键约束，防止把表约束误识别成列。
- 验证：PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、280 Actions、1071 Files、543 活跃引用、48 休眠文件和 93 源码专用文件；两套运行时生成的 5,657,093 字节完整数据库报告逐字节一致，SHA-256 为 `4ccf38d5d74ebe58f566b68b7aefb17084989c46f30b9397ac0502357314cb06`。表级写集合 SHA-256 保持 `6e17ece0f355448df595dafbc10413c14202c96b22c248367cdc7c63c62fd202`，发布包内容不变。
- 风险/待办：13 张无主键表不能参加主键冲突分析，372 个 `INSERT ... SELECT` 仍需未来用实际 SQLite 或受控查询求值。下一步为 20 个重复候选组补充 Criteria 相容性、动作顺序与最终值审查；实机数据库与日志仍是最终等价性门槛。
- 提交：`0704731 refactor: derive keys for mod-created tables`。

### 2026-09-09 / M5-完整行与加载支配分析

- 目标：在主键重复之上验证整行是否相同，并结合动作 Criteria、全局顺序与冲突模式筛出可以等价删除的更晚空操作。
- 范围：扩展 `DatabasePrimaryKeys.ps1` 的完整行哈希、重复组分类和更晚 Ignore 支配分析，更新分析契约、报告、自检及相关文档；不修改运行 SQL/XML、动作图、玩法值、ModInfo、包身份或版本号。
- 设计决定：只有一行所有显式字段均为字面量时才生成与列顺序无关的完整行 SHA-256；同主键组的所有行哈希相同才标记 `identicalRow`。只有目标出现位置是 `INSERT OR IGNORE`，并且其每个加载动作之前都存在同 scope、无 Criteria、相同行的较早写入，才列入 `removableLaterIgnoreOccurrences`；无条件写入位于后方、条件动作彼此可能共存或行内容不可求值时均不判定为支配。
- 结果：20 组重复主键全部证明为完整相同行；7 组各有 1 个更晚 Ignore 被严格支配，具体是 XP2 信仰教条 2 行、BBM XP2 西班牙海岸偏好 1 行、Gran Colombia/Maya 文件重复的 Types 2 行与 UnitAbilities 2 行。其余 13 组没有更早无条件来源，不进入自动精简清单。
- 契约：主键分析基线推进到 `0704731`，SHA-256 更新为 `6f7bb04f8cf2693c819bc40469e91006605db7ea4c0e5a1845049c89aef8c124`；新增相同行组、受支配组和受支配出现位置计数。行哈希自检证明字段顺序不影响结果而字段值漂移会改变哈希。
- 验证：PowerShell 7 与 Windows PowerShell 5.1 全量校验均通过 203 XML、108 Criteria、280 Actions、1071 Files、543 活跃引用、48 休眠文件和 93 源码专用文件；两套运行时生成的 6,190,860 字节完整数据库报告逐字节一致，SHA-256 为 `a1c4b2bbd7660bfa3e70b8abe4a73c2ec151f8d7c4b7321745ff32fb4ee11069`。表级写集合 SHA-256 仍为 `6e17ece0f355448df595dafbc10413c14202c96b22c248367cdc7c63c62fd202`，发布包内容不变。
- 风险/待办：支配分析证明更晚 Ignore 在数据库层不会改变结果，但删除后仍须重跑跨版本契约、动作闭包并构建三种发布 profile。下一步只删除清单中的 7 行，不处理剩余 13 组，也不据此推断实机最终数据库已验证。
- 提交：本次提交（完整行与加载支配分析）。

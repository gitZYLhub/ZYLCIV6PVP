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
- 提交：本次提交（活跃运行文件安全校验模块化）。

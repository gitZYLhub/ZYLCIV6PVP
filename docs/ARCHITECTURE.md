# 架构与责任边界

## 运行阶段

```text
ModInfo
├─ FrontEnd：配置、预设、地图、房间和大厅 UI
├─ InGame Database：BBG → BBM/组件 → ZYL 最终覆盖
├─ InGame Gameplay：持久状态、回合事件、地图/模式脚本
├─ InGame UI：唯一替换者 + 可组合增补
└─ Assets：Icons / Colors / ArtDefs / .dep / Platforms
```

最终目标不是把所有文件搬进少数“公共模块”，而是使每个模块的输入、输出、加载条件和所有者可被机器检查。

## 目标模块

| 模块 | 唯一责任 | 不得承担 |
| --- | --- | --- |
| Manifest | 根据声明生成 ModInfo 动作图和运行文件清单 | 游戏规则实现、手工补丁特例 |
| Config | 配置定义、默认值、预设映射 | UI 绘制、网络发送 |
| Lobby Domain | 房间状态、权限、命令、投票、身份和版本协议 | 控件查找、每帧绘制 |
| Lobby UI | 渲染 ViewModel、收集用户意图 | 直接写多项共享状态 |
| Network | 权威写入、版本号、去重广播、接收幂等 | 业务规则判断散落各处 |
| Gameplay DB | 可条件加载的确定性数据库变更 | Lua 运行时副作用 |
| Gameplay Runtime | 事件驱动、存档幂等的游戏逻辑 | 本地 UI 状态 |
| UI Components | 一个 Context 一个最终替换者，可组合功能 | 多 Mod 同时全量替换同一文件 |
| Maps | 地图生成与固定种子确定性 | 大量无等级正式日志 |
| Build | 从清单复制、验证、报告和原子替换产物 | 读取 Workshop 缓存或外部源码 |
| Validation | 检查声明、引用和行为契约 | 静默修复输入 |

Manifest 迁移采用“分段替换而非一次重写”：`manifest/criteria`、`manifest/actions/frontend`、`manifest/actions/ingame` 和 `manifest/files` 分别是 ActionCriteria、FrontEndActions、InGameActions 和 Files 运行元素的唯一开发源。组装器按稳定、允许留洞的 `manifestOrder` 恢复各段相对顺序并移除该开发属性，允许删除死条目而不重排数百个无关序号。生成段必须符合冻结 1.3.0/当前分支双动作图契约；冻结指纹永久不变，有意精简只更新当前指纹与计数。

## 联机状态原则

```text
玩家意图 → 权限/参数校验 → 房主提交状态版本 → 单次广播
                                      ↓
客户端接收 → 检查版本/幂等键 → 应用本地镜像 → 标记 UI 脏域 → 合并刷新
```

- 所有共享状态必须有明确所有者：房主、玩家本人或游戏引擎。
- 单次操作产生一个可识别的状态版本；旧包、重复包和乱序包不得重复产生副作用。
- UI 不通过定时轮询“猜测”网络变化，网络和游戏事件只标记需要刷新的最小领域。
- 纯本地设置不广播；共享配置不写入 UserConfiguration。
- 任何随机数调用都必须说明是否属于同步游戏随机流，并保持跨客户端一致的调用次数与顺序。

## 校验层

- `tools/validate.ps1` 是唯一公开入口，负责装载项目元数据、调度各领域检查并统一汇总错误；它不得静默修改任何源码或运行资产。
- `tools/validation/*.ps1` 保存无副作用、可用正反样例验证的领域检查函数。首个模块 `LuaChecks.ps1` 负责 Lua 全局事件生命周期和正式日志约束。
- `ManifestGraph.ps1` 把 ActionCriteria、FrontEndActions、InGameActions 和 Files 转成忽略 XML 属性顺序、但保留节点与文件顺序的规范图；`manifest/baseline-1.3.0-action-graph.json` 同时保存不可变的冻结版本指纹/计数与可审查演进的当前指纹/计数。
- `ManifestChecks.ps1` 负责冻结指纹/计数和四段分域源一致性检查，只返回问题列表；主入口负责决定失败退出。段比较器内建属性换序应通过、路径漂移应失败的正反样例。
- `ProjectChecks.ps1` 统一路径规范化、源码/生成目录分类、工程文件枚举、Workshop 外部缓存隔离、组装器本地输入边界和 XML 可解析性检查；它同样只返回问题列表，并由入口用安全/危险路径样例自检。
- `AssetInventoryChecks.ps1` 生成发布文件、休眠文件、源码文件、Action/Criteria 身份与活跃引用的统一视图，检查磁盘、Files 与 Action 引用双向闭合；`manifest/dormant-files.txt` 取代隐藏在代码中的休眠白名单。
- `RuntimeSafetyChecks.ps1` 只扫描资产视图中的活跃 Lua/SQL/XML，拒绝动态 `loadstring`、Workshop 自更新调用、已禁用反叠加机制和旧组件 Mod ID；休眠替代文件不会制造误报。
- `DatabaseContractChecks.ps1` 逐步承接关键数据库最终值和其配置/动作/文本闭包；现覆盖时代长度/阈值/大厅开关/计时器文本、秘密结社 16 个晋升的幂等总督点返还与 DLC/模式 Criteria，以及旅游/伟人移动/迦太基购买参数和总督最终值修复，并用正确/错误 SQL 片段自检。
- `DatabaseWriteSet.ps1` 从 FrontEnd/InGame 的 `UpdateDatabase` 动作提取加载域、顺序、Criteria 与唯一 SQL/XML 源；SQL 扫描器正确跳过注释并保护引号内分号，XML 扫描器识别 `Row/InsertOrIgnore/Replace/Update/Delete`，最后按表汇总操作、多源触及、零写入源，以及不同文件在同一动作内的精确重复 SQL。`manifest/database-write-set-contract.json` 同时保留冻结 1.3.0 指纹/计数和可演进的当前指纹/计数，避免为了后续等价精简而覆盖历史基线。
- `DatabaseSchemaChecks.ps1` 校验由 `tools/schema/export_civ6_schema_keys.py` 一次性导出的官方 Schema 快照：基础、XP1、XP2 Gameplay 和 Configuration 分库保留各表列、复合主键、唯一键、源文件哈希与游戏 build id。写集合报告把 223 张触及表分为官方、项目自建和外部依赖；外部表必须登记提供者 Mod ID，并证明每个引用动作都受对应 `ModInUse` Criteria 保护。
- `DatabasePrimaryKeys.ps1` 在 Schema 覆盖层之上解析官方表及项目 `CREATE TABLE` 的表级/列级主键与列序，并保守解析 SQL `VALUES`（显式列及列序一致时的隐式列）和 XML 属性行；只有全部主键字段为字面量时才输出行候选。`INSERT ... SELECT`、缺少主键字段和真实无主键表分别记录未解析原因；跨文件同主键分组会计算共同动作，但不会忽略 Criteria、加载顺序或冲突模式而自动判定为冗余。
- `BbgLocalizationChecks.ps1` 纵向拥有 BBG 7.4.6 简中同步层、误标为中文的拉丁文本补救、关键中英文正/负文本规则和全包英文/简中标签闭合；入口以内存修改拜占庭关键译文的反例自检，缺失 Text 节点会返回可定位问题。
- `BbgIconChecks.ps1` 从嵌入 BBG SQL 动态发现新增政策，并统一验证政策/四结社晋升的图标定义或 stock alias 以及 InGame UpdateIcons 动作；入口以内存删除政策 alias 的反例防止空图标和 UI 日志刷屏。
- `GameplayLocalizationChecks.ps1` 纵向拥有最终玩法覆盖层的中英文说明，以及毛利、马里、柬埔寨、克里、萨拉丁、瑞典、法国、俄罗斯等跨上游副本一致性；测试覆盖文本始终显式按 UTF-8 读取，避免 Windows PowerShell 5.1 的本地代码页破坏中文。
- `BbgTooltipChecks.ps1` 统一核对萨拉丁、Tagma、挪威、忽必烈、拉美西斯，以及埃塞尔弗莱德、德雷克、印度和腓力二世的嵌入 tooltip 与最终玩法绑定；入口以内存回退萨拉丁作用半径的反例保护上游文本同步。
- `UpstreamBalanceChecks.ps1` 统一保护最终覆盖动作顺序、灾害关闭值、科技倍率禁用、城邦住房，以及马里、高棉、克里、大哥伦比亚、高卢/维钦托利、图拉真等上游 SQL 与多份文本副本；入口以内存移除曼萨·穆萨黄金时代路线标识的反例验证上游保留规则。
- `FinalGameplayChecks.ps1` 负责上游加载后的最终数据库状态：城市住房/科技、毛利、马里、高棉、克里、大哥伦比亚、高卢、俄罗斯、法国、苏莱曼、时代着力点、约翰内斯堡与损坏 Modifier 链清理，并复核毛利/德国/BBG 总督源；入口以内存删除无水城市住房键的反例验证最终层。
- `LobbyConfigurationChecks.ps1` 纵向拥有 ZYL/CPL/BBG 前端配置、两档 Casual 计时器、可选时代长度、最终大厅默认值及其晚加载动作、房主重置/权限/生命周期；入口以内存改变智能计时默认值和移除 P++ 次数上限的反例保护配置与运行时两端一致。
- `ArtIntegrationChecks.ps1` 保护 BBM 根级 `NaturalWondersMod.dep` 的唯一 UpdateArt 动作、ArtDef 与 Windows/macOS BLP 依赖闭包，并阻止五条已清理的 BBG/BBM 上游坏引用回流；入口以内存改写 ArtDef 路径的反例验证缺失依赖会被拒绝。
- `PackageIdentityChecks.ps1` 把 `tools/project.json` 的 Mod ID/版本/名称与 ModInfo 属性、双语标题、简中描述和 `MP_helper.lua` 多人握手绑定为单一身份契约，同时保护掉线恢复不得重新引入同步随机流、清空移动力或废弃函数；入口以内存改变握手版本的反例验证单一版本源。
- `TeamPvpSocietyChecks.ps1` 纵向拥有 Team PVP Secret Societies 3.93 整合层：资源存在性、Gameplay SQL、吸血鬼城堡脚本、镀金船厂、三语文本、美术依赖、LightweightBalance 资源移除，以及秘密结社模式 Criteria/Action/Files 闭包统一由一个无副作用函数检查；入口通过内存修改城邦发现概率证明高风险平衡漂移会被拒绝。
- `ExpandedResourceChecks.ps1` 纵向拥有 BBG Expanded 六种资源的核心/平衡 SQL、325 个上游文件、美术依赖与双平台包、公司模式扩展、外部完整模组交接、动态简体中文和独立模组阻断；入口以内存资源地形漂移反例自检，损坏的中文文本动作则返回领域错误而不会使校验器空引用退出。
- `MonopoliesChecks.ps1` 纵向拥有行业、公司及产品的 50 个最终数值、枫糖住房例外、公司模式数据库/文本加载顺序、21 个简中效果标签和百科资源清单；入口以内存百分比漂移反例自检，缺失 LoadOrder 节点会作为问题汇总而不会中止校验。
- `PantheonChecks.ps1` 纵向拥有 13 个 Lightweight Balance 精选万神殿与 ZYL 德鲁伊的允许/排除清单、关键数据库行为、三语文本、图标、地热矿山和 Gathering Storm 条件，以及独立 LightweightBalance 阻断；入口以内存删除德鲁伊注册的反例验证允许清单。
- `MapChecks.ps1` 承接 Rich Mainland 的发布文件、Criteria/Action 图、地图/尺寸配置、本地化、旧引用禁用、城邦回退、战略资源兜底、海岸出生、画布宽度和 FFA 尺寸契约；领域函数只读取传入源码或工程快照并返回问题，总入口以真实地图源码和删除回退入口的内存反例自检。
- `UiChecks.ps1` 承接 UI/QoL 的文件、Criteria/Action、上下文和安全源码契约；覆盖 TPT 功能、两类交易 UI、外交/地图标记集成、全局 Context、EndGame、万神殿稳定索引、大厅领袖图标回退和黑名单剪贴板导出，并以真实源码和错误动作图反例自检。
- `IdentityChecks.ps1` 纵向拥有身份模式的大厅参数与依赖、隐藏发牌数据、默认值/房主重置、三语文本、只读游戏内面板、大厅控件和“不得进入 Gameplay”边界；发牌算法本身仍由 `MultiplayerChecks.ps1` 的大厅契约保护。
- `StartingBonusChecks.ps1` 纵向拥有开局加成的大厅玩家/类型域、同步 Gameplay 发放脚本、持久化幂等标记、Action/Files、三语文本，以及初始移民在首座宫殿前的移动/地形/河流/上岸能力；入口以内存破坏属性写入的反例保护存读档与多人重复发放边界。
- `LeaderVariantChecks.ps1` 纵向拥有北条、腓力二世和威廉明娜三个内陆变体的 Gameplay/Config 克隆、重复领袖关系、递归文本防护、图标/颜色、美术、八个 ModInfo 动作及 BBM/Rich Mainland 出生点分流；入口以内存破坏 Trait 克隆的反例保证变体不会演化成第二套玩法数据。
- `ReleaseChecks.ps1` 统一 universal/windows/macos 路径选择、跨平台资产成对约束、Action 不直指平台二进制、资产定义不硬编码平台目录和发布器实现边界；根目录与任意嵌套目录中的 `Platforms/MacOS`、`Platforms/Windows` 都按同一规则识别。
- `MultiplayerChecks.ps1` 承接大厅身份配置、事件生命周期、正式日志、周期读取、请求式完整刷新，赛事设置/启用 Mod 能力/玩家昵称三个失效缓存，以及多人状态的有序数组 + playerID 索引；另保护握手转换与终态幂等、批量广播、随机领袖、投票重开、断线、重同步、突然死亡、主菜单和主回合计时器。领域调度器统一读取六个 UI 源，独立自检函数对默认阶段全扫、三个缓存、状态索引、终态重开及其他联机路径构造十三类内存漂移。
- `tools/report_modinfo_graph.ps1` 将完整规范图写入已忽略的 `artifacts/reports`，用于拆分前后定位差异；`tools/report_database_writes.ps1` 输出逐动作、逐源、逐操作和逐表的数据库写集合，并显示是否偏离冻结指纹。两种报告都不进入 Workshop 包，也不是新的手工真值源。
- 领域模块返回问题或调用统一的 `Add-ValidationError`，不得自行终止整个校验流程；只有入口脚本负责最终退出码与摘要。
- 抽取模块时必须保持原断言有效，并至少提供一个应通过和一个应失败的内建样例，防止“为了拆文件而让校验失效”。

## 发布层

- `tools/build_workshop_release.ps1` 从 ModInfo 的 Files 清单建立临时目录，经完整校验后原子替换对应的 `artifacts/workshop*` 目录；源码、文档、Git 元数据和休眠文件不得进入运行包。universal 保留全部平台资产，windows/macos 只在临时清单与产物 ModInfo 中裁剪另一平台资产。
- 已知文本格式必须通过严格 UTF-8 解码并在临时产物中规范为 LF，BOM 与孤立 CR 保留；`.dds/.fgx` 等二进制资产逐字节复制。构建过程不得为了统一行尾修改源码树。
- 报告 schema 3 记录 profile、源码/平台排除数、保留的平台资产数、体积预算、`textNormalization=utf8-lf`、规范化文本数量、逐文件大小/哈希和聚合哈希；未按文本规则处理的文件还会按“SHA-256 + 大小”生成确定性重复组和理论可回收体积。不同路径可能属于加载契约，报告不得自动去重或改写引用。相同 Git 内容的 CRLF/LF 工作区变体必须产生相同报告哈希。

## 目录迁移约束

重构可逐步新增 `src`、`manifest` 或 `tests` 等开发目录，但不能在未同步更新 `.dep`、ArtDefs、ModInfo 和平台引用时移动运行资产。Civ VI 对 UI Context 文件名、相对路径和平台目录的约定优先于常规软件项目的目录美观。

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

Manifest 迁移采用“分段替换而非一次重写”：`manifest/criteria`、`manifest/actions/frontend`、`manifest/actions/ingame` 和 `manifest/files` 分别是 ActionCriteria、FrontEndActions、InGameActions 和 Files 运行元素的唯一开发源。组装器按 `manifestOrder` 恢复各段原顺序并移除该开发属性，允许生成后的 ModInfo 保留不影响运行的说明注释。四段都必须保持冻结动作图指纹一致。

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
- `ManifestGraph.ps1` 把 ActionCriteria、FrontEndActions、InGameActions 和 Files 转成忽略 XML 属性顺序、但保留节点与文件顺序的规范图；`manifest/baseline-1.3.0-action-graph.json` 固定冻结版本的语义指纹与计数。
- `ManifestChecks.ps1` 负责冻结指纹/计数和四段分域源一致性检查，只返回问题列表；主入口负责决定失败退出。段比较器内建属性换序应通过、路径漂移应失败的正反样例。
- `ProjectChecks.ps1` 统一路径规范化、源码/生成目录分类、工程文件枚举、Workshop 外部缓存隔离、组装器本地输入边界和 XML 可解析性检查；它同样只返回问题列表，并由入口用安全/危险路径样例自检。
- `AssetInventoryChecks.ps1` 生成发布文件、休眠文件、源码文件、Action/Criteria 身份与活跃引用的统一视图，检查磁盘、Files 与 Action 引用双向闭合；`manifest/dormant-files.txt` 取代隐藏在代码中的休眠白名单。
- `tools/report_modinfo_graph.ps1` 将完整规范图写入已忽略的 `artifacts/reports`，用于拆分前后定位差异；报告不进入 Workshop 包，也不是新的手工真值源。
- 领域模块返回问题或调用统一的 `Add-ValidationError`，不得自行终止整个校验流程；只有入口脚本负责最终退出码与摘要。
- 抽取模块时必须保持原断言有效，并至少提供一个应通过和一个应失败的内建样例，防止“为了拆文件而让校验失效”。

## 目录迁移约束

重构可逐步新增 `src`、`manifest` 或 `tests` 等开发目录，但不能在未同步更新 `.dep`、ArtDefs、ModInfo 和平台引用时移动运行资产。Civ VI 对 UI Context 文件名、相对路径和平台目录的约定优先于常规软件项目的目录美观。

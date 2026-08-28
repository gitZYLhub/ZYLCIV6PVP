# 冲突处理记录

## ModInfo 与数据库动作

- BBG 和 BBM 的所有 Action ID 都加上 `ZYLPVP_BBG_` / `ZYLPVP_BBM_` 前缀及序号，避免同名动作覆盖。
- 两者的 ActionCriteria 都加组件命名空间；动作内的元素式和属性式条件引用同步改写。
- 原套件动作保留原 ID，BBG/BBM 动作使用独立命名空间。
- BBG/BBM 上游重复或失效的文件引用不进入发布清单。
- 所有文件路径采用 `/` 写入 ModInfo，并按不区分大小写去重。
- MPH 比赛预设在 BBG/BBM 前端参数之后加载，避免预设依赖尚未创建的参数。

## UI 所有权

每个高风险 UI 上下文只允许一个组件系列拥有：

| 上下文/功能 | 所有者 | 处理 |
|---|---|---|
| StagingRoom、HostGame、MainMenu | MPH/ZYL | 不加载 TPT BSR |
| ChatPanel、DiplomacyActionView、InGameTopOptionsMenu | MPH/ZYL | 保留比赛协议和权限边界 |
| EndGameMenu 完整布局 | MPH/ZYL | BBG 只加载传统胜利 Lua 扩展 |
| WorldRankings、UnitPanel、TradeOverview | BBG | 不加载 TPT 同类 replacement |
| ReportScreen | ZYL/TPT 的 BRS | 按 XP1/XP2 条件加载同一实现 |
| TopPanel、Tech/Civic、Pantheon、CityStates、GreatPeople | ZYL/TPT UI | 保留配置条件，避免重复实现 |

校验器按 `LuaContext` 统计所有 `ReplaceUIScript`；同一组件内部的有序 include 链可以共存，跨组件抢占同一上下文会失败。

## 地图与美术

- BBM 脚本保留在 `Components\BBM`，避免和工具箱及 BBG 文件同名。
- `NaturalWondersMod.dep` 内部的 ArtDef 路径是裸文件名，BLP 路径也从平台 BLP 根解析，因此 `.dep`、`ArtDefs`、`Platforms` 必须位于 Mod 根目录。
- `UpdateArt` 只保留一个根路径 `NaturalWondersMod.dep`。
- BBM 1.39.1 的大小写重复地图脚本仅发布一次。

## 版本握手和组件检测

- 准备房间只把统一 Mod ID 识别为 MPH、BBG、BBM 三种能力同时存在。
- `MOD_MPH_ID`、`MOD_BBG_ID`、`MOD_BBS_ID` 三个兼容配置标志由统一包同时设置，以维持 MPH 预设语义。
- 套件版本从统一 ModInfo 读取；BBG/BBM 组件版本分别固定为 `7.4.6` 和 `1.39.1`，并通过原 MPH 私聊协议发送给房主。
- 旧 BBG/BBM/MPH/TPT/ZYL ID 只允许出现在 `<Blocks>`、文档或构建脚本中，不允许进入活动运行时代码。

## 回合、计时与科文

- MPH 保留强制结束回合的单次请求语义；TPT 原版重复请求实现不加载。
- P++ 修改通过公共聊天请求、由房主落地并广播，避免客户端互相覆盖计时配置。
- 无计时模式不会被回合切换逻辑擅自恢复为标准计时。
- `NoMoreStack` 防堆科文代码不在活动文件中，保留原版科技/市政溢出积累。

## 已知边界

静态冲突可以通过文件、动作、条件、上下文和危险模式检查消除；Civ VI 的 UI 加载次序、数据库内容互操作、地图生成随机路径、网络事件顺序与掉线重连状态必须靠游戏实测。这里的“已处理冲突”不等于承诺不存在任何运行时 Bug。

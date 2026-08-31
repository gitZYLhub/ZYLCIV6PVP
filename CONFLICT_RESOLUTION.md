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
| ChatPanel、DiplomacyActionView、InGameTopOptionsMenu | MPH/ZYL | 保留比赛协议和权限边界；TPT 黑名单导出拆到独立 `BlacklistPanel`，不再替换聊天面板 |
| EndGameMenu 完整布局 | MPH/ZYL | BBG 只加载传统胜利 Lua 扩展 |
| WorldRankings、UnitPanel、TradeOverview | BBG | 不加载 TPT 同类 replacement；RCT 的坐城免确认函数直接并入 BBG `UnitPanel` |
| ReportScreen | ZYL/TPT 的 BRS | 按 XP1/XP2 条件加载同一实现 |
| TopPanel、Tech/Civic、Pantheon、CityStates、GreatPeople | ZYL/TPT UI | 保留配置条件，避免重复实现 |
| DiplomacyDealView | Better Deal Window + MPH 兼容层 | 只加载一个 XP2 入口；BDW 提供界面，`ZYLPVP_BDW_MPH_Compatibility.lua` 隐藏 MPH 禁用的交易类别 |
| DiplomacyRibbon | 原版 XP2 + ZYL BSM 风格包装 | 保留 XP2 控件 ID 和事件链；增加 BSM 风格头像下方扩展栏、能见度分级情报与领袖/文明能力提示，不加载 BSM 旧脚本 |
| MapPinManager、MapPinPopup | Detailed Map Tacks | 只加载 DMT replacement；NHK 不再重复监听 Add/Delete/Toggle，仍提供聊天地图钉 |
| MapPinListPanel | MPH（正常）/TPT RMP（禁钉） | `CPL_NO_PINS=1` 时用空列表替换并隐藏小地图入口 |

不占用上述游戏内上下文的 TPT 前端/辅助功能单独加载：`Option/Options.xml` 只把局域网玩家名长度上限从 22 改为 128；`NT/Notice.lua` 只在开局提示已启用的新快捷键或禁用地图钉规则；安全重写的 `NewUnitOperation` 只处理随机晋升，不运行原版反作弊扫描或 Workshop 更新。

校验器按 `LuaContext` 统计所有 `ReplaceUIScript`；同一组件内部的有序 include 链可以共存，跨组件抢占同一上下文会失败。

- Better Deal Window 保留 XP2 主界面和本地化；上游 Base/XP2/Monopolies 四个 replacement 不直接装载，避免同一 `DiplomacyDealView` 上下文互相覆盖。公司模式只在统一入口中替换产品图标。
- MPH 的 `DIPLOMATIC_DEAL` 及各项 `NO_TRADING_*` 选项在 BDW 可用物品函数上做后置包装；禁用类别返回 0 并隐藏分类根控件，避免空列表仍可交互。
- Detailed Map Tacks 使用上游 `mappinmanager_dmt.lua`、`mappinpopup_dmt.lua` 和计算器，但不装载重复的 `dmt_config.xml`；NHK 的聊天地图钉独占 `AddMapMessage`，DMT 独占普通地图钉三键。
- DMT 缓存序列化移除执行 Lua 字符串的路径。旧格式缓存会安全失效，加载时从实际地图钉自动重建。
- 禁钉条件下继续保留唯一的 DMT `MapPinManager`/`MapPinPopup` 所有权，但输入被拦截，`MapPinListPanel` 切换为 TPT 的空实现，小地图按钮由独立附加 UI 隐藏。

## 地图与美术

- BBM 脚本保留在 `Components\BBM`，避免和工具箱及 BBG 文件同名。
- `NaturalWondersMod.dep` 内部的 ArtDef 路径是裸文件名，BLP 路径也从平台 BLP 根解析，因此 `.dep`、`ArtDefs`、`Platforms` 必须位于 Mod 根目录。
- `UpdateArt` 只保留一个根路径 `NaturalWondersMod.dep`。
- BBM 1.39.1 的大小写重复地图脚本仅发布一次。

## BBG Expanded 六种资源

- 资源数据库、美术、图标和文本从 BBG Expanded 201 的 `CIVITASResources` 原目录完整内嵌，保持 `.dep` 的相对路径结构，不与 BBM 根目录美术混放。
- 独立 CIVITAS Resources Expanded 的 Mod ID 被阻止重复启用。外置 BBG Expanded 不被阻止；检测到其任一正式/WIP ID 时，内嵌的数据库、美术、图标、文本和公司模式动作全部跳过，由外置 Expanded 提供同一批资源。
- 无外置 Expanded 时，BBG 的 `sql/BBG_Expanded/Resources.sql` 由独立后置动作加载，因此企鹅的海洋生成、渔船改良和额外食物，以及莎草的额外生产力都会正常生效。
- 公司模式 SQL 只在 `GAMEMODE_MONOPOLIES=1` 时加载；普通规则集不会引用公司模式专属表。

## 海岸/内陆领袖选择

- 北条时宗、腓力二世、威廉明娜在大厅中各提供“海岸”和“内陆”两个名称；内陆版使用新的领袖 ID，但继续绑定原文明。
- 两个版本复制同一套最终领袖特性、文明单位/建筑、城市列表、议程、颜色、图标和领袖美术；原版与 BBG 的能力改动不会分叉。
- 内陆版只过滤 `TERRAIN_COAST` 出生关联。荷兰的河流关联和西班牙的大陆分界自定义关联继续保留。
- BBM 常规图、两张富饶大陆及其 Firaxis 回退路径都按领袖 ID 过滤海岸；同一优先级将来增加其他地形关联时也不会误删。
- 海岸与内陆版本登记为重复领袖，避免同一局把同一角色的两个版本同时分配给不同玩家。

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

## BBG 后置规则覆盖

- BBG 的文明、单位、建筑和科技树单项平衡继续完整加载；其 `base.sql` 中对中世纪及以后所有科技统一乘 1.05 的语句在内嵌副本中停用，避免后置除法误改 BBG 后续显式设定的未来科技成本。
- `sql/ZYL_GameplayOverrides.sql` 在全部 BBG/BBM 数据库动作之后统一拥有科技时代折扣、天文导航、八项尤里卡/鼓舞、商业中心奢侈相邻和俄罗斯冻土/冻土丘陵信仰规则。
- `sql/ZYL_GovernorOverrides.sql` 只在迭起兴衰/风云变幻总督表存在时加载，最后移除马格努斯左一增长、移动免人口移民效果，并把右一工业区建筑加成覆盖到 40%。

## 初始移民

- 复用 LightweightBalance 的“玩家尚无宫殿”条件，只增强游戏开始时的初始移民。
- 初始移民获得 +1 移动力、忽略地形和过河移动消耗，上下船不消耗移动力。
- 首都建立后条件立即不满足；之后生产或购买的移民保持 BBG/原版移动规则。
- 所有数据库 ID 使用 `ZYL_` 命名空间，避免与 BBG、BBM 及其他整合组件发生主键冲突。

## 秘密结社与资源移除

- Team PVP Balanced mod 结社 3.93 的四结社平衡、镀金船厂、文本、图标和建筑美术已内嵌；独立原模组 ID 被阻止同时加载。
- 结社建筑美术由 `TeamPVPSecretSocieties.dep` 声明 Ethiopia GameArt 依赖并路由给 Landmarks/战略视图消费者；`UpdateArt` 不直接引用 `.artdef`，避免 `Unknown extension`。
- Team PVP 源 SQL 中的波兰遗物、阿玛尼使者和 `SIMULTANEUM` 政策属于同文件内混放的非结社改动，因此不进入整合层；注释方案与数值为 0 的吸血鬼移动 Modifier 同样不加载。
- 免费结社头衔只由 `Components\BBG\sql\Secret_Societies.sql` 插入一次；该动作与 Team PVP 结社层都要求《风云变幻》、埃塞俄比亚包和已开启的秘密结社模式。
- 调查任意部落村庄时，对四个结社分别使用 `DiscoverAtGoodyHutBaseChance = 100000` 发起发现判定；Team PVP 原有的四结社城邦发现来源及各结社其他原有来源不删除。
- Team PVP 新增对象全部使用 `ZYL_TPVP_` 命名空间，重复加载敏感表使用 `INSERT OR IGNORE` / `INSERT OR REPLACE`，避免裸主键插入导致整个 SQL 文件回滚。
- 奢侈/战略资源移除独立于秘密结社模式加载；地脉移除与地脉农场随结社层加载，确保未开启模式时不会引用未载入的地脉内容。

## 已知边界

静态冲突可以通过文件、动作、条件、上下文和危险模式检查消除；Civ VI 的 UI 加载次序、数据库内容互操作、地图生成随机路径、网络事件顺序与掉线重连状态必须靠游戏实测。这里的“已处理冲突”不等于承诺不存在任何运行时 Bug。

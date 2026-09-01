# 来源与版本

## 上游副本

| 组件 | 版本 | 本机只读来源 | 整合位置 |
|---|---:|---|---|
| Better Balanced Game | 7.4.6 | `D:\Steam\steamapps\workshop\content\289070\2865001760` | `Components\BBG` |
| Better Balanced Map | 1.39.1 | `D:\Steam\steamapps\workshop\content\289070\3179425402` | `Components\BBM`；美术依赖位于根目录 |
| ZYL Multiplayer Suite | 1.0.0 | `D:\Civilization\Civ6mods\BBGZYL\ZYL_MultiplayerSuite` | 整合包根目录 |
| Multiplayer Helper | 1.7.9 | `D:\Steam\steamapps\workshop\content\289070\3307282026` | 已在 ZYL Multiplayer Suite 中完成冲突处理 |
| Team PVP Tools | 1.65 | `D:\Steam\steamapps\workshop\content\289070\3693899014` | 已在 ZYL Multiplayer Suite 中择取 UI/QoL；Better Trade Screen Lite 位于 `BTS` |
| Team PVP Balanced mod 结社 | 3.93 | `D:\Civilization\Civ6mods\BBGZYL\steamcmd\steamapps\workshop\content\289070\3475173328` | `Components\TeamPVPSecretSocieties`；移植结社平衡、镀金船厂及配套文本/美术 |
| ZYL Lightweight Balance | 0.10.2 | `D:\Civilization\Civ6mods\BBGZYL\ZYL_LightweightBalance` | 择取结社头衔免费化、村庄统一发现结社、初始移民移动、资源便利、13 个精选万神殿、地热裂缝矿山机制与可选世界时代长度；另由 ZYL 新增德鲁伊万神殿 |
| BBG Expanded | 201 | `D:\Steam\steamapps\workshop\content\289070\3533091092` | 择取 `CIVITASResources` 六种奢侈资源本体、美术、本地化及公司模式支持；不内嵌其文明/领袖 |
| Better Deal Window | 12 | `D:\Civilization\Civ6mods\BBGZYL\referencemods\Better Deal Window` | `Components\BetterDealWindow`；XP2 交易界面、奢侈品来源/交易历史、公司模式产品图标；入口叠加 MPH 交易限制 |
| Detailed Map Tacks | 1 | `D:\Civilization\Civ6mods\BBGZYL\referencemods\DetailedMapTacks` | `Components\DetailedMapTacks`；产出/相邻计算器、可放置检查、自动删除和地图钉 UI；跳过重复 `dmt_config.xml` |

生成的统一 Mod ID 为 `4dd01931-9d44-4a8a-8e74-712cba0f0072`，ModInfo 版本为 `125`，用户可见版本为 `1.2.5`。

## 整合副本中的确定性修复

- BBG：将缺失的 `_dlc_indo_khmer_utils.sql` 引用改到现存 `Base.sql`；移除不存在的 `Other.sql` 和仅剩失效引用的 `lp_arabia_saladin_sultan.sql`。
- BBG：补出上游引用但未定义的 `BBGExpanded` OR 条件。
- BBG：内嵌 BBM 后固定加载 BBM 兼容 SQL，不再依赖外部 BBM Mod ID。
- BBG：移除其完整 `EndGameMenu.xml`，保留 `endgamemenu_bbg.lua` 扩展。
- BBM：移除上游 ModInfo 中不存在的 `BBS_D.lua` 和 `BBS_Balance.lua`。
- BBM：合并大小写不同但实际相同的 `perfectworld6.lua` / `PerfectWorld6.lua` 清单项。
- BBM：把 `NaturalWondersMod.dep`、`ArtDefs` 和 `Platforms` 移到整合包根目录，以满足 `.dep` 的相对资源路径。
- BBM：修正法语和葡萄牙语 XML 声明中的 `frcoding` 拼写错误。
- BBM：移除三个零字节文本占位文件（意大利语、波兰语、西班牙语）及其加载引用，避免空 XML 导入失败。
- 工具箱：把旧组件 Mod ID 检测改为统一 ID，同时明确广播 BBG 7.4.6、BBM 1.39.1 和套件版本。
- 工具箱：保留可堆科技/市政行为；不加载 `NoMoreStack`。
- 工具箱：恢复 TPT 的局域网玩家名 128 字符上限与开局功能提示；提示脚本兼容布尔/整数配置值、无本地玩家时安全退出，并补齐英语文本。
- 工具箱：恢复禁钉模式的空 `MapPinListPanel` 与小地图按钮隐藏；布尔/整数/字符串三种配置值都可识别。恢复随机晋升快捷键和坐城免确认，但前者使用无反作弊、无 Workshop 更新的安全重写，后者并入 BBG 的唯一 `UnitPanel`。
- 工具箱：黑名单的剪贴板导出从冲突的完整 `ChatPanel` replacement 中拆出，移入独立 `BlacklistPanel`；继续由 MPH 独占聊天上下文。
- 工具箱：恢复 TPT `DD/DD_Config.sql` 的灾害强度 `-1` 档，使用命名后的独立 SQL 前端动作，不引入 TPT 的交易/和解规则。
- 工具箱：不加载社区伟人冠名 `GPN/GreatPersonNames.sql`；其最终写入以完整 Team PVP Balanced 文本中的“号码菌”标记为条件，而本包按需求只移植该模组的秘密结社平衡。
- 工具箱：大厅默认值改由最后加载的 `ZYL_LobbyDefaults.xml` 统一覆盖，避免原先在 MPH/BBG 参数创建前执行 `Update` 而命中零行；新建房间、恢复默认和把 MPH 预设切回“无”都会恢复 BCY 全城市+最大值、休闲（均衡）计时、FFA 外交栏情报、时代长度优化、无蛮族、公司、秘密结社和两项 TPT 计时开关。`休闲（均衡）` 直接按真人玩家中的最高城市数和最高单位数计算负载；第 45 回合起增加 40 秒，第 90 回合起再增加 20 秒（合计 60 秒）。
- 工具箱：普通玩家外交栏直接采用 Team PVP Tools 1.65 DPR 的 XML/Lua 布局、左右键分页、研究卡片和头像能力提示命中区；只在数据赋值层叠加 ZYL 的 FFA/组队外交能见度遮罩，未接触玩家保持匿名。
- 工具箱：完整移植 Team PVP Tools 1.65 的 Better Trade Screen Lite，以 BTS 独占贸易总览、商路选择与出发城市选择界面，恢复按六类收益和完成回合数排序；停用 BBG 的冲突商路 UI 动作，并把其阿玛妮城邦商路收益显示修正迁入 BTS。BTS 玩家配置缓存改用长度前缀序列化，旧 `loadstring` 缓存不会执行。
- 构建：校验器反向检查磁盘文件与 `<Files>`；仅允许显式登记的旧模式、冲突 replacement、已合并源文件和上游未发布文件保持休眠，其他漏列文件直接失败。
- LightweightBalance：只在建立首都前为初始移民提供 +1 移动力、无视地形/河流及上下船移动消耗；建立宫殿后失效，不影响后续移民。
- Team PVP 结社：重写上游易产生主键冲突的裸 `INSERT`，为新数据库 ID 加 `ZYL_TPVP_` 命名空间，并只在秘密结社模式实际开启时加载；四结社三级统一在文艺复兴时代解锁，四级统一提前至工业时代；地卜师按“上古维序者 2.3”移植到黄金黎明，保留地脉移动 UI/Gameplay，并删除被捕获转为地球工程师的规则、改为伟人式撤回首都；源文件中混放的波兰、阿玛尼和宗教政策修改不属于结社平衡，未带入。
- Team PVP 结社美术：新增 `TeamPVPSecretSocieties.dep` 并声明 Ethiopia GameArt 依赖，由 `UpdateArt` 加载 `.dep` 后把 `Buildings.artdef` 路由给地标和战略视图消费者，消除直接加载未知 `.artdef` 扩展的日志错误。
- LightweightBalance 资源：奢侈资源可移除并获得 40 金币，战略资源可移除并获得 20 生产力；地脉可移除并获得 40 金币，也可修建农场。公司模式专属奢侈品不生成建造者移除动作。
- 万神殿：移植用户指定的 13 项 LightweightBalance 信条，并新增德鲁伊；神圣道路的 BBG 树林标准相邻转交德鲁伊，只保留雨林和沼泽标准相邻。征战之路文化由上游 +2 改为 +1。财富女神一并移植跨规则集的商业中心前置科技修正器。
- LightweightBalance 地热：仅在风云变幻规则集加入“采矿业解锁地热裂缝矿山”，矿山与裂缝共存并保留裂缝原产出；独立 LightweightBalance 被阻止重复启用。
- BBG Expanded 资源：内嵌企鹅、石榴、莎草、枫树、蛋白石和李子六种奢侈品的完整跨平台美术、图标、百科文本及公司/产品内容；始终加载 BBG 7.4.6 的企鹅与莎草平衡补丁。独立 CIVITAS Resources 被阻止重复启用；若外置 BBG Expanded 启用，则自动跳过内嵌资源动作并使用外置版本，保留其文明/领袖可用性。
- 简中同步：新增 BBG 7.4.6 后置文本覆盖层，以实际 Gameplay SQL 校对上游旧汉化和英文本身的过时数值；巨神头像按游戏本体 `Housing / TilesRequired` 公式采用实际的 +0.5 住房，并补齐改良设施自身缺失的 +1 食物与住房说明。另用 `LocalizedText` SQL 补齐 BBG Expanded 六资源动态生成的百科、公司项目、产业效果和30个产品名称。维钦托利与特·基尼奇二世被上游误标为简中的整批法语百科和外交文本也由后置层重译，并补正特·基尼奇二世科技型议程的错误 Tag。
- BBG Mod Manager 过滤表：把被内嵌的 BBM/MPH 条目替换为统一 Mod ID。
- Better Deal Window：跳过其四个独立 `DiplomacyDealView` replacement，改由 `DiplomacyDealView_ZYLPVP_Expansion2.lua` 统一接管；公司模式产品图标内联，MPH 交易限制作为后置 wrapper 应用。
- Detailed Map Tacks：跳过重复的 `dmt_config.xml`，沿用 NHK 的 `AddMapMessage` 定义和 Shift+M 显隐键；`MapPinManager`/`MapPinPopup` 各保留一个 DMT replacement，NHK 不再重复监听三项普通地图钉动作。DMT 的 `dmt_serialize.lua` 改为长度前缀序列化，避免运行 `loadstring`。
- BBG / Team PVP / LightweightBalance 规则覆盖：新增默认开启的大厅时代长度选项，开启时标准速度为远古 40–50、古典和中世纪 50–60（联机速度分别为 20–25、25–30）；取消 BBG 中世纪以后科技统一 +5% 基础成本，落后时代科技改为 -25%；天文导航恢复航海术+占星术双前置并保留所有陆地单位上船解锁，同时按用户指定来源覆盖八项尤里卡/鼓舞。
- 地图与文明规则覆盖：富饶大陆的海岸出生关联文明先于内陆文明放置并优先东西岸、南北岸仅作无可用位置时的后备；奢侈资源为商业中心及特色替代区域提供 +1 金币相邻；俄罗斯与圣地/拉夫拉相邻的冻土和冻土丘陵 +1 信仰；法国文明全体领袖拥有覆盖全部已启用奢侈资源的 T4 出生关联，寻欢作乐凯瑟琳的已改良奢侈/加成/战略资源 +1 文化分别在技艺/封建主义/城堡解锁；马里移除城市生产力惩罚及对外贸易城市信仰，非市中心无地貌沙漠/沙漠丘陵改为 +2 食物、+1 生产力、+1 信仰，曼丁哥市场购买折扣调回 10%，曼萨·穆萨恢复每次进入黄金时代永久 +1 贸易路线容量；普通绿洲全局调整为 4 食物、1 金币；马格努斯左一移除增长并接收免人口移民，右一工业区建筑加成改为 40%。最终 Gameplay 数据库另经文明/领袖 Trait、Modifier、Requirement、特色单位/建筑/改良和简中描述反向审计，过时文本由后置本地化覆盖层校正，并清理斯基泰无效能力授予项及西班牙传教团的三条孤儿 Modifier 引用。

`tools\assemble_modinfo.ps1` 可从固定的上游 ModInfo 重新生成统一 ModInfo。脚本不会写入 Steam Workshop 目录。

## 许可

原组件的许可和作者声明保留在随包文件、ModInfo 属性和源文件注释中。整合本身不授予超出上游许可的再分发权。

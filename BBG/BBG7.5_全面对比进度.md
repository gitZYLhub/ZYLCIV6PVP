# BBG 7.5 与旧版 BBG 全面对比进度

> 用途：本文件是本次比较任务的外置记忆与事实台账。每完成一批核查就更新，避免上下文压缩后丢失进度。
>
> 比较方式：以 Git 提交范围为主，结合文件级 SQL/Lua/XML 静态审查。最终结论需要区分“实际生效代码”“注释/回退代码”“本地化与格式变化”。目前尚未在《文明 VI》内启动验证。

## 1. 比较对象与基线

- 新版目录：`D:\Civilization\Civ6mods\BBGZYL\BBG7.5`
- 旧版目录：`D:\Civilization\Civ6mods\BBGZYL\BetterBalancedGame`
- 旧版提交：`7b3cddbe0c559fb13905d90b58c5057acdf93f5b`
  - 日期：2026-04-21
  - 信息：`modinfo`
- 新版提交：`6df05e0b231b41dae697e2878955647cdde556c6`
  - 分支：`7.5`
  - 日期：2026-08-30
  - 信息：`fix japanease file`
- 旧提交是新提交的祖先，因此可靠比较范围为：`7b3cddb..6df05e0`
- 两个目录在首次核对时均无未提交文件变化。

## 2. 总体统计

- 新版相对旧版前进：374 个提交
- Git 差异文件：81
- 新增文件：11
- 修改文件：70
- 删除文件：0
- Git 行数统计：新增 29,206 行，删除 10,885 行
- 实际游戏文件数量：219 → 230
- 版本号：`7.4.3 / 7043` → `7.5.0 / 70500`
- 注意：本地化文件包含大量翻译合并、标签补全、XML 重排和换行差异，不能把所有行数变化视为玩法改动。

## 3. 新增文件

- `lua/BBG_Expanded/Goth.lua`
- `sql/BBG_Expanded/Austria.sql`
- `sql/BBG_Expanded/Austria_Front.sql`
- `sql/BBG_Expanded/England_UU.sql`
- `sql/BBG_Expanded/Goths.sql`
- `sql/BBG_Expanded/PolandStanislaw.sql`
- `sql/BBG_Expanded/TainoAnacaona.sql`
- `sql/BBG_Expanded/Units.sql`
- `sql/BBG_Expanded/Wonders.sql`（目前只有注释，无有效 SQL）
- `sql/Base/LoadLast.sql`
- `ui/replacements/greatpeoplepopup_bbg.lua`

## 4. 加载机制与脚本

### `BetterBalancedGame.modinfo`

- 加载 Austria、Goths、Poland、Taino、England Longbowman 等 Expanded 内容。
- 新增 `LoadLast.sql`，加载顺序为 `200000000`，用于最终覆盖单位和奇观数值。
- `LoadLast.sql` 的实际 `UpdateDatabase` 动作带有 `XP1_AND_XP2` 条件；其 +4 单位战斗力与 Lake Victoria 覆盖不能无条件理解为所有规则集都会加载。
- 新增 Goth Lua 脚本。
- 新增 Great People UI 替换脚本，用于隐藏奥地利外交官伟人。
- Expanded 文件加载条件扩展到更多 DLC/规则组合。
- Expanded 的 WIP/Release 主数据库动作都要求：对应 Expanded 模组 + `XP1_AND_XP2` + Aztec + Macedon/Persia + Byzantium/Gaul + Gran Colombia/Maya；因此 Austria、Goths、Stanislaw Poland、Taíno、Longbowman 等新增内容并非只要启用 BBG Expanded 就必然加载。
- `XP1_AND_XP2` 的定义是 `any="1"`：使用 Gathering Storm 规则集，或列表中的任一 Rise and Fall 领袖可玩即可满足；名称看似“XP1 且 XP2”，实际 XML 语义并非简单逻辑 AND。

### `config/config.sql`

- 从英格兰所有领袖的通用配置中移除 Sea Dog，之后仅在 Elizabeth 文件中重新赋予。

### `scripts/bbg_script.lua`

- 建城时除标记首都地块外，也标记首都周围六格为 `CS_ADJACENT_BBG`。
- 此标记供奥地利外交官判断是否靠近城邦首都使用。

### `sql/_utils.sql`

- 新增按建筑生成的“城市拥有建筑”要求集、按时代生成的“单位处于该时代或更早”要求集、按晋升类/编制类/单位类型生成的要求，以及“单位/对手是否为独特单位”标签要求。
- 为每个单位晋升生成隐藏伪能力和对应要求集，用于 Oligarchy 按晋升等级授予 +1 战斗力；这些是通用基础设施，不是单独的单位数值改动。

## 5. BBG Expanded 新增或重做内容

### 奥地利

- 删除原有出生偏好。
- 删除原 BBG Expanded 中“总督提供外交支持”、免费近战单位和外交政策槽相关修正；原模组本体不在本次两个 Git 版本内，因此只能根据被删除的 Modifier ID 与新版文本判断旧能力，无法在仓库内完整还原其原始数值。
- Grenzer：`Combat=60`、`RangedCombat=70`。
- 新增“伟大外交官”伟人类别、12 名外交官伟人及专属外交官单位。
- 外交官可以吞并玩家作为宗主国控制的城邦。
- 外交官在外国领土、靠近其他文明宫殿且不靠近城邦时，提供 `+1 外交支持/回合`。
- 政府广场不同建筑分别提供外交官。
- Maria Theresa 的总督效果重新实现：把两个 +15% 修正挂到所有 0 级总督晋升上，使已就任总督所在城市获得区域生产 +15%、单位生产 +15%。新版文本还保留“每名已就任总督 +1 影响力/回合”，但这部分 SQL 依赖外部 BBG Expanded 原能力，本新增文件本身没有重新创建该影响力 Modifier。
- 添加奥地利专属河流、湖泊名称。
- Coffee House 的伟人作品文化和旅游值均设为 4。

### 哥特

- 删除出生地形偏好。
- Militond：战斗力 38，需要铁；区域战斗力加成 +10 → +5；铁消耗 10。
- Gadrauht：战斗力 47，成本 180；无 Temple 的城市生产时额外消耗 1 人口；获得免费晋升。
- 删除部分占领城市区域生产效果。
- Hlaiw：允许训练 Warrior Monk；信仰和文化人口收益各为 0.25；使 6 格内非骑兵陆军获得 +1 移动力。
- 添加哥特河流、湖泊、山脉、火山、海洋名称。
- 新 Lua 机制：研究 Early Empire 后建立或征服城市时，使 6 格内、至少有 2 点空闲住房的其他哥特城市获得 +1 人口；同一来源城市只触发一次；人类玩家显示世界文本。

### 波兰 Stanislaw

- Uhlan：移动力 5，成本 330，侧翼加成 100% → 50%。
- 删除原 National Education 后重新实现。
- 战略资源/改良地块靠近军事区域及建筑时获得：
  - Encampment：+1 食物
  - Barracks/Stable：+1 文化
  - Armory：+1 科技
  - Military Academy：+1 生产

### Taíno / Anacaona

- 删除出生偏好。
- 重做时代奉献与纪念效果对应的政策槽位。
- Great Person 政策：对应区域 +2 食物，对应建筑 +1 食物。
- 外交政策在有 Batéy 的城市提供 +1 宜居度。
- 幸福度金币百分比：Happy +5%、Ecstatic +10%、Euphoric +15%。
- Batéy：商业中心相邻 +2 生产/+3 金币；港口相邻 +4 生产/+6 金币；Arena 提供 2 个写作巨作槽位。
- Batéy 成本设为 30、成本增长参数 35、基础娱乐值 2；相邻 Batéy 的 Theater Square 另获 +2 文化相邻。
- Taino 独特项目的信仰转换效率翻倍，伟人点数调整。
- Macana：先设基础战斗力 15，再为 Oligarchy 全局重做手动 +4，最终数据库值为 19；对更强单位 +5、对城市中心 -5，移动力与视野均为 3，并删除原来禁用 Scout 的修正。新版文本以重做后的 Warrior 为参照写作“基础战斗力 -5”。
- Taíno 的幸福度金币修正使用 `HAPPINESS_HAPPY`、`HAPPINESS_ECSTATIC` 和内部 `HAPPINESS_UNHAPPY` 三个枚举；后者在本项目中被沿用表示最高（8+宜居度）档位，因此不是给不满城市发金币。
- 独特改良设施：可建于草原丘陵、平原丘陵、冻土丘陵；不能彼此相邻；按地形和相邻资源获得食物/生产；重商主义后相邻加成或奢侈资源提供 +2 金币；Natural History 后 +1 文化。

### 英格兰 Expanded 单位

- Longbowman 改为 Medieval Faires 解锁。
- 删除原先对近战/骑兵额外 +4 的能力。
- Longbowman 加入 MOAR Units 启用列表。
- Sea Dog 现在仅属于 Elizabeth。

### 其他 Expanded

- `UNIT_DLV_COG` 战斗力设为 42。
- Spearthrower：Consulate 增加贸易路线容量；建造外交区建筑时 +100% 生产。
- Trisong：Dzong 的区域成本增长参数设为 35。

## 6. 单位与战斗系统

### `sql/Base/Units.sql` 与 `sql/XP2/Units.sql` 的净变化

- Modern Armor：继续保留移动力 5；旧版的“友方领土防守/非友方领土进攻 +5”条件能力被删除，改为基础战斗力 95 → 100，即无条件 +5。
- Heavy Chariot：战斗力 28 → 36，移动力 3 → 2，成本 65 → 90，时代改为 Classical，并设为消耗铁（`ResourceCost=20`，标准速度口径）。
- Heavy Cavalry：新增对 Melee、Nihang、Warrior Monk +3 战斗力。
- Battlecry 晋升：+7 → +5；Thrust 晋升：旧版主动设为 +10，新版撤销该覆盖，回到原版 +5。
- Machine Gun：移除旧版 80 防空值；远程战斗力在当前数据库值上 -5；成本设为 600。移动力 3 是旧版已有值，不是 7.5 新改。
- Recon：Skirmisher 成本降至 120；Taíno 的 Macana 被排除在“所有侦察单位额外 +1 视野”之外。其余侦察单位战斗力、Spyglass/Sentry 重组和 Spyglass +2 移动力是旧版已有代码的搬家。
- Infantry：前置科技改为 Refining。
- Mechanized Infantry：前置科技改为 Guidance Systems；撤销旧版额外移动力 5 和忽略 ZOC，战斗力 90 保持不变。
- AT Crew：+1 移动力，Advanced Ballistics 解锁，成本 460，维护费 6；战斗力 80 为旧版已有。
- Modern AT：+1 移动力；战斗力 90 为旧版已有。
- Mobile SAM：改为 Satellites 解锁；125 防空、5 移动力是旧版已有值。
- Quadrireme：射程改为 2，远程战斗力 23，成本 160。
- Rock Band：移动力改为 2，可被击杀，不再捕获单位。
- Anti-Air Gun：基础移动力调整为 4。
- Military Engineer：前置科技改为 Engineering；在普通文明中需要 Barracks 或 Stable，马其顿可由 Basilikoi Paides 满足，蒙古可由 Ordu 满足。
- Mountain Tunnel：前置科技从 Military Science 提前到 Military Engineering。
- Medic 的 +1 移动力光环新增支持 Warrior Monk 与 Nihang。
- Battering Ram 新增 +1 移动力光环，影响古典或更早的 Melee、Ranged、Anti-Cavalry、Warrior Monk、Nihang。
- Siege Tower 新增 +1 移动力光环：Melee、Ranged、Anti-Cavalry 可作用至文艺复兴；Warrior Monk、Nihang 限古典或更早。
- 原来只有 Artillery/Rocket Artillery 获得的“攻击区域 +5”能力扩展为全部 Siege 类单位。
- 所有战斗单位新增攻击“已驻扎骑兵”时 +4 战斗力的能力。

### `sql/Base/LoadLast.sql`

- 近战、反骑兵、海军近战、Nihang、Warrior Monk 基础战斗力 +4。
- 具有远程攻击值的上述近战类单位，远程战斗力也 +4。
- Political Philosophy 之前对相关单位施加 -4，研究后移除。
- 用极晚加载顺序确保最终数值覆盖其他模组的单位调整。
- 以上内容在 `modinfo` 中受 `XP1_AND_XP2` 条件控制；标准 Gathering Storm 组合会加载，但不应视为任何 DLC/规则集组合下都必然生效。
- Roman Legion：旧版在 `Rome.sql` 中强制设为 38，新版注释撤销该覆盖；按原版 40 计算，在加载本文件后数据库基础值为 44，Political Philosophy 前再受 -4 临时战斗修正。

## 7. 科技树、海洋与淘汰机制

### `sql/Base/base.sql`

- 单次战斗最大经验：8 → 10。
- Wheel 移至 Classical，成本 120。
- Steam Power 前置：Scientific Theory → Astronomy。
- Composites、Guidance Systems 加入 Nuclear Fission 路径。
- Advanced Ballistics 删除 Replaceable Parts 前置。
- Cartography 增加 Military Tactics 前置。
- Ocean：移动成本设为 2；Buttress 解锁海洋航行；Cartography 降低海洋移动成本。
- Beach Resort 吸引力旅游倍率：150% → 100%。
- Gunpowder、Sanitation 删除原版无意义科技描述。
- 新增多个后期市政 Eureka/鼓舞条件：5 个 Spy、1 个 GDR、2 个 Spaceport、研究 Predictive Systems、3 个 Wind Farm。
- Fort：+1 生产、+1 金币。

### 单位淘汰科技

- Musketman、Conquistador、Janissary → Refining。
- Line Infantry、Redcoat、Garde Imperiale → Guidance Systems。
- Pikeman → Advanced Ballistics。
- Pike and Shot → Composites。
- Quadrireme → Refining。

## 8. 政体与政策卡

### Oligarchy 重做

- 删除原近战专属效果。
- 非军事和支援单位在友方领土开始回合时获得 +1 移动力。
- 政体及 Legacy 效果提供 +40% 单位经验。
- 军事单位按已经获得的晋升等级获得 +1 战斗力。
- 适用范围扩展至侦察、近战、远程、攻城、反骑兵、轻重骑兵、海军、僧侣、飞机等类别。
- Political Philosophy 前的 -4 由 `LoadLast.sql` 处理。

### 其他政体

- Communism：删除 Scientific Vanguard 政策卡实现，改为拥有 Campus 的城市 +10% 科技。
- Autocracy：删除 Palace 相关加成。
- Fascism：Third Alternative 增加 Seaport +4 金币、+2 文化。
- Democracy：政府本体贸易路线体系不变；Legacy 政策不再删除盟友/宗主贸易路线的生产修正，因此恢复这些路线的 +2 生产，同时继续移除联盟点数效果。

### 基础政策卡

- 新增 Modern Drill：Mobilization 解锁，为古代至现代的近战、远程、反骑兵、侦察单位提供生产加成；它成为 Grande Armée 与 Military First 之间的新阶段卡。
- Grande Armée 移除现代时代近战、远程、反骑兵、侦察单位生产效果，但补上古典远程单位生产效果。
- Military First 的解锁位置从 Mobilization 后移到 Ideology。
- Defense of the Motherland：Ideology → Mass Media。
- Discipline：保留对野蛮人 +10，侦察单位额外 +1 视野。
- Caravansaries：国际贸易路线 +1 生产。
- Triangular Trade：国际贸易路线 +1 生产。
- Religious Orders：宗教单位在外国城市传播能力 +50%。
- 新增 Naval Guilds：Civil Service 解锁；古代至中世纪海军单位 +100% 生产；位于 Maritime Industries、Press Gangs、International Waters 之间。

### XP2 政策卡

- Professional Army：升级折扣 50% → 40%。
- 新增 Military Standardization：Nationalism 解锁，升级折扣 45%。
- Force Modernization：Ideology 解锁，升级折扣 50%。
- Resource Management：改良战略资源地块 +2 生产。
- Revelation 不再自动过时。

### XP1/XP2 文化建筑政策

- Simultaneum、Grand Opera、Free Market 的高人口/高相邻加成：50% → 100%。

### 伟人

- Euclid：删除随机中世纪科技 Eureka，改为让激活城市的区域容量 +1；其数学 Eureka 保留。
- Modern 时代 Great General 的范围加成新增覆盖 Information 时代陆军。
- Zhou Daguan、Alvar Aalto、Simon Bolivar 等代码块主要是重排，最终能力与旧版一致。

## 9. 区域、建筑、改良设施与自然奇观

- Neighborhood：每城限建 1 个；基础 +2 食物；相邻区域的标准相邻加成全部 +1。
- Workshop：生产 4 → 3。
- Shipyard：无改良海岸/湖泊 +1 生产 → +2。
- Food Market：成本 290，食物 5。
- Seaport：+2 Oil → +1 Coal、+1 Oil。
- Great Bath：城内洪泛平原 +1 食物。
- Panama Canal：前置科技提前到 Industrialization。
- Roman Bath：文化相邻效果改为每个相邻区域 +1。
- Roman Fort：+1 生产、+1 金币，并绑定 Rome 专属改良设施特性。
- Lake Victoria：`LoadLast.sql` 先删除其食物行再写入 3 食物；此为最终覆盖值，并受该文件的 `XP1_AND_XP2` 加载条件约束。
- White Desert：+1 食物。
- Gibraltar：相邻地块 +1 生产。
- River Goddess：圣地河流相邻信仰 +2 → +1。
- Beach Resort：旅游倍率 150% → 100%。
- Great Works：艺术槽位重复艺术家时文化/旅游统一为 4；文物槽位为 6；Palace 槽位为 4；修正范围扩展至所有对应槽位类型。

## 10. 文明与领袖调整

- Egypt：Heavy Chariot 相关科技改为 Masonry。
- Arabia：移除两条排除相邻规则查询中的 `GROUP BY CivilizationType`，使非阿拉伯文明的所有 Trait 都会被加入排除表，修复过去每个文明只随机/任取一个 Trait 而可能漏掉 Campus–Holy Site 专属相邻排除的问题；不改变阿拉伯自身相邻数值。
- Australia：Digger 的前置科技改为 Refining。
- England：Sea Dog 仅 Elizabeth；Powered Buildings 效果回到 England，统一降为 +3。
- Victoria（Age of Steam）：恢复已改良战略资源地块 +1 生产；Powered Buildings 加成不再是她的领袖专属，而是回归英格兰文明能力。
- Germany / Barbarossa：原本对城邦单位的 +7 战斗力，扩大为对城邦单位或任何文明独特单位均生效。
- India：Varu 成本设为 110，邻近敌军减益从 -5 调整为 -3。
- Jadwiga：军事政策槽转通配槽不再从开局生效，改为研究 Early Empire 后生效。
- Macedon / Mongolia：Military Engineer 分别可由 Basilikoi Paides / Ordu 满足其兵营或马厩前置要求。
- Norway：Longship/Berserker 获得海洋快速移动；Early Ocean Navigation 限制 Quadrireme；增加 Rainforest 负出生偏好。
- Persia：Immortal 射程降至 1；删除 Ranged 类标签。
- Nubia：Ta-Seti 对海军远程单位也提供各时代生产加成。
- Sundiata：Theater 对 Suguba 金币相邻 +1 → +2。
- Yongle：每人口金币 1 → 0.5。
- Lincoln：所有 Industrial Zone 建筑 +2 文化。
- Georgia：Tsikhe +1 Great Prophet 点数。
- Russia：Lavra 冻土地块食物效果需要 Temple，不再只需要 Shrine。
- Mali：删除 -5% 城市生产惩罚；Suguba 购买折扣 20% → 10%；删除 Holy Site 对 Suguba 的通用金币相邻；Mansa 专属 Holy Site 相邻 +2 金币；Holy Site/建筑生产加成 15% → 10%。
- Māori：Toa 邻近敌人惩罚 -5 → -3；删除 Fishing Boat 文化炸弹；Pā +1 生产、+1 金币。
- Sweden：Nobel Prize 的 +50% 生产从四个指定建筑扩到全部 Campus/Industrial Zone 建筑；按建筑类型增加科学家/工程师伟人点数；Queen's Bibliothèque 的 6 个 Palace 巨作槽位各提供 4 文化、4 旅游。
- Inca：Terrace Farm 所在城市有 Water Mill 时 +1 生产。
- Ottoman：Grand Bazaar 移至 Guilds 解锁。
- Liang：Agriculture 和 Zoning Commissioner 不再作用于全部已揭示资源，只作用于已改良资源或建立在资源上的 City Center。
- Maya/Colombia 相关：Battering Ram、Siege Tower 补齐对 Nihang 的移动力效果。
- 玩家颜色：新增/覆盖 Austria、Taíno/Anacaona、Ahiram、Goths/Theodoric 的主色或备用配色。

## 10.1 间谍与时代奉献补充

- 反间谍效果加强：所有 `OFFENSIVESPY` 行动的 `EnemyProbChange` 与 `EnemyLevelProbChange` 均变为原来的 2 倍。
- 军事型黄金时代奉献（代码中的 `COMMEMORATION_RELIGIOUS` 重做项）取消每个军事单位 -1 金币维护费；原有 +15% 军事单位生产、Encampment +1 生产、击杀获文化等 BBG 效果保留。

## 11. 本地化统计

| 语言 | 旧标签 | 新标签 | 新增 | 删除 | 修改 |
|---|---:|---:|---:|---:|---:|
| English | 1194 | 1300 | 107 | 1 | 55 |
| Chinese | 1452 | 3373 | 2023 | 102 | 1012 |
| French | 2492 | 3217 | 726 | 1 | 86 |
| German | 2432 | 3084 | 652 | 0 | 238 |
| Italian | 1172 | 1172 | 0 | 0 | 2 |
| Japanese | 1283 | 1943 | 661 | 1 | 70 |
| Korean | 1329 | 1586 | 285 | 28 | 189 |
| Polish | 458 | 458 | 0 | 0 | 2 |
| Portuguese | 2104 | 2104 | 0 | 0 | 2 |
| Russian | 1948 | 2532 | 585 | 1 | 57 |
| Spanish | 971 | 971 | 0 | 0 | 3 |

- 英文新增/修改文本集中在：奥地利 Great Diplomat、哥特迁移人口、Modern Drill、Military Standardization、Naval Guilds、Oligarchy、Neighborhood、Taino/Batéy/Anacaona、Heavy Cavalry、Great Bath、Euclid、Terrace Farm、Longbowman/Sea Dog、River Goddess、Mali、Māori、Machine Gun、Modern Armor 等。
- 中文和多国语言的大幅增长主要来自 BBG Expanded 标签合并、翻译补全与格式重排，不代表同等数量的玩法变化。
- 升级折扣 SQL 最终为 40% / 45% / 50%。英文、中文、日文、法文、德文和俄文的 XP2 标签已写成这一组数值；俄文同时残留一组非 XP2 标签写成 30% / 40%，葡萄牙文的 Professional Army 仍写 50%，在不同规则集或标签选择下可能出现描述与代码不一致。

## 12. 已确认的注释、回退和重排（不能误报为生效改动）

- `sql/BBG_Expanded/Wonders.sql` 目前只有注释，没有实际 Porcelain Tower 改动。
- Vietnam 洪泛平原建筑金币方案全部被注释，实际未启用。
- India Stepwell 的“邻近 Holy Site 获得生产/信仰，并为 Holy Site 提供相邻”方案全部被注释，实际未启用。
- Byzantium Dromon 成本 160 的新增语句被注释，实际未启用。
- Simultaneum 的大范围多产出方案被注释；实际启用的是 Faith 加成提高至 100%。
- Light Cavalry 击杀回血方案已注释回退。
- Modern Armor 的条件战斗力方案已注释；生效的是基础战斗力与移动力调整。
- Big Ben 移至 Capitalism 的改动已注释回退。
- XP2 单位文件中的飞机和部分单位成本代码移至 `Base/Units.sql`，不应仅凭删除/新增重复计算为数值变化。
- `GreatPeoples.sql` 有大量区块重排；Simon Bolivar、Aalto 等部分内容只是移动或重组。
- `Mapuche.sql` 最终仍是对黄金时代文明 +3；中间提交曾改到 +5，随后在 2026-08-29 回退，最终 diff 只有注释变化。
- `lp_rome_caesar.sql` 的“每级晋升 +1 战斗力”代码与旧版相同，本次只新增回退说明注释，不是新能力。
- 某些 Mapuche、Mali、Vietnam 描述变化属于翻译或注释同步，不一定是本次新增玩法代码。

## 13. 待继续核对

以下项目已完成静态核对；仍不能替代游戏内数据库加载测试：

- 关键结论已补齐文件和行号（正文各节及质量审计节中的引用）。
- `git diff --name-status` 返回的 81 个差异文件已全部列入第 14.1 节并归类；未发现遗漏文件。
- `modinfo` 的 DLC/规则集条件、`XP1_AND_XP2` 的 `any="1"` 语义及 `LoadLast.sql` 的最终覆盖顺序已复核。
- 已做新增标识符交叉引用检查：从新增 SQL 行提取的 65 个 `ModifierId`/要求集/能力等标识符均能在新版目录中找到定义或引用；这只能排除明显拼写遗漏，不能证明基础游戏表结构一定接受它们。
- 已复查重复 ID、加载顺序、XML 解析和文本—代码一致性；剩余事项全部转入第 13.1 节“风险”，不再作为未完成的比较范围。
- 最终中文报告按“总体统计 → 加载机制 → 核心玩法 → Expanded → 文明领袖 → 本地化 → 回退/注释 → 风险与验证范围”整理。

## 13.1 质量审计与潜在问题

### 补丁空白检查

- 已运行 `git diff --check 7b3cddb..6df05e0`。
- 原始输出为 11,479 行，但其中包含每条诊断后显示的补丁内容行；按 `文件:行号: 诊断` 精确统计，实际共有 **5,741 条诊断**：
  - 5,708 条行尾空白；
  - 15 条缩进中空格位于 Tab 前；
  - 15 条同时包含上述两类问题；
  - 3 条文件末尾新增空行。
- 按目录：`lang` 5,618 条、`sql` 115 条、`BetterBalancedGame.modinfo` 5 条、`lua` 3 条。
- 最集中的文件：German 2,869、Russian 2,102、English 423、Korean 123、French 55、Japanese 38。其余主要为少量 SQL/Lua/Modinfo 格式问题。
- 这些大多是格式/维护性问题，不等于 SQL 或 XML 无法加载；但会制造巨量噪声，降低后续审查和合并可靠性。

### XML 与本地化重复标签

- PowerShell XML 解析器已成功解析 11 个语言 XML，静态上未发现 XML 结构损坏。
- 法文新增冲突：`LOC_AGENDA_MER_ROMAN_GOTH_NAME` 同时写为 `Elisaweta` 与 `Romanitas`；后者位于后面，通常会覆盖前者。
- 俄文新增 10 个重复键，其中高风险冲突包括：
  - `LOC_POLICY_MILITARY_STANDARDIZATION_DESCRIPTION` 同时为 45% 与 40%；后写的 40% 可能覆盖 SQL 对应的 45%。
  - `LOC_UNIT_MER_GRENZER_DESCRIPTION` 一版正确描述增强后的远程攻击，另一版仍写“65 对 60”，与新版 `RangedCombat=70` 不符。
  - `LOC_AGENDA_MER_ROMAN_GOTH_NAME` 同时为“Елизавета”和“Романитас”。
  - Medic、Battering Ram、Siege Tower 的移动光环描述存在两版；Great Diplomat 名称也有同文重复。
- 日文新增 5 个重复键：Discipline、Triangular Trade、Taíno Theater Culture、Autocracy、Classical Republic。其中 Discipline 的旧版不含侦察视野 +1，Triangular Trade 的旧版不含国际贸易路线 +1 生产；需依 XML 后写顺序确认游戏最终显示。
- 德文新增一条 Anacaona 外交文本重复、韩文新增一条 Fascism 描述重复；两处重复文本相同，主要是维护风险。

### 已确认的文本—代码不一致或覆盖风险

- `lang/french.xml:6530` 的法文 `LOC_HAPPINESS_UNHAPPY_NAME` 错写 `Language="ko_KR"`，会把法文 `Euphorique` 放入韩文本地化域，法文本身没有获得该替换。
- Longbowman 的 SQL 已删除“对近战/骑兵额外 +4”；单位说明 `LOC_UNIT_ENGLISH_LONGBOWMAN_DESCRIPTION` 已同步，但英文能力说明 `LOC_ABILITY_LONGBOWMAN_DESCRIPTION` 仍保留这段旧能力。中文、日文、俄文、德文对应能力说明已是正确的新文本。
- `LoadLast.sql` 实际让 Melee、Anti-Cavalry、Naval Melee、Warrior Monk、Nihang 在 Political Philosophy 后解除 -4；英文及多国语言的 Political Philosophy 描述只列前三类，遗漏 Warrior Monk 与 Nihang。
- Quadrireme 的实际 SQL 已改为射程 2，但英文 `lang/english.xml:1869-1870` 仍写射程 1；这是新增玩法值未同步到英文说明。
- Siege Tower 的英文光环说明还有时代范围错误：`lang/english.xml:2058-2059` 写“Medieval 或更早”，但 `sql/Base/Units.sql:426-466` 对 Melee、Ranged、Anti-Cavalry 使用的是 Renaissance 或更早；Warrior Monk 及 DLC 补入的 Nihang 才限制为 Classical 或更早。
- 新增的 `LOC_BBG_ABILITY_LIGHT_CAV_HEAL_ON_KILL_NAME` 仍留在英文文件，但 `sql/Base/Units.sql:35-49` 的新轻骑兵击杀回血能力已经全体注释回退；该名称属于不会被新能力引用的残留标签，不是生效玩法。更值得注意的是，英文 `lang/english.xml:2083-2084` 把现有 Scythia 击杀回血说明追加成“(Light Cavalry)”，而未变的 `sql/Base/Scythia.sql:45-51` 仍把该能力挂给全部战斗单位；这段英文限定本身不正确。
- Great People UI 替换先调用原 `PopulateData`，再从 `data.Timeline` 删除 Austria Diplomat。缺少游戏原 UI 文件来确认基础函数是否已在删除前消费 Timeline 数据，故只能标记为待游戏内验证，不能断言隐藏功能失效。
- 对工作区内另一份完整 `GreatPeoplePopup.lua` 的旁证检查显示，原 `PopulateData` 只负责向 `data.Timeline` 填充数据，调用方随后才执行 `ViewCurrent/ViewPast`；因此“先调用基础填充，再删除外交官”在该版本 UI 结构下顺序合理。仍需游戏内确认被 include 的实际原版脚本版本和替换冲突情况。

### `modinfo` 动作标识风险

- 新版前端新增两项 `UpdateDatabase`，分别以 `BBGExpanded_WIP` 和 `BBGExpanded_Release` 为条件加载 `Austria_Front.sql`，但两项都使用同一个 `id="BBG_Expanded_UU"`（`BetterBalancedGame.modinfo:363` 与 `:370`）。旧版没有这个重复；相同动作 ID 可能导致其中一项被覆盖或行为依赖 Mod 加载器实现，应改为两个唯一 ID 并在游戏前端验证外交官条目。
- `modinfo` 还引用了 3 个磁盘中不存在的文件（Indonesia/Khmer 的两个文件与 Saladin Sultan 文件），但旧版已存在同样引用，不是 7.5 新引入的问题。

### 追加核对（支持单位、Third Alternative、Sejong、Heavy Cavalry）

- 英文支持单位光环文本不完整：`lang/english.xml:2052-2065` 的 Ram、Siege Tower、Medic 说明只列 Melee、Anti-Cavalry、Ranged；对应 SQL 还明确覆盖 Warrior Monk 与 Nihang（Ram/Siege Tower 另有时代限制）。这是本地化遗漏，不改变 SQL 实际效果。
- Third Alternative 文本漏项：`sql/Base/Government.sql:367-381` 为 Seaport 添加 `+4 Gold` 与 `+2 Culture`；英文 `lang/english.xml:3697-3698` 只写 `+4 Gold`，未显示 `+2 Culture`。
- Sejong 文本与代码不一致：`lang/english.xml:983-984` 删除了“仅无总督城市”的条件；`sql/LP/Sejong.sql:38-44` 仍通过 `CITY_HAS_NO_GOVERNOR_REQUIREMENTS` 限制为无总督城市。因此英文描述会误导玩家以为封建主义后所有城市都获得 `+30% Builder` 生产。
- Heavy Cavalry 文本不完整：`lang/english.xml:2075-2076` 只写对 Melee `+3`；`sql/Base/Units.sql:102-124` 的同一要求集还覆盖 Nihang 与 Warrior Monk。
- 所有战斗单位攻击已驻扎骑兵的 `+4` 已在 `sql/Base/Units.sql:722-746` 确认是有效 SQL（不是注释）；该玩法变化已归入“单位与战斗系统”，此处补充精确行号。
- Naval Guilds 存在一个静态引用风险：`sql/Base/Policies.sql:582-600` 将 `POLICY_SUK_JAHAZI_PRODUCTION` 作为 `ModifierId` 挂入 `PolicyModifiers`，但在新旧 BBG 目录中都找不到该 ID 的定义（仅找到 Jahazi 单位的其他 Modifier）。若基础游戏或其他外部模组未提供同名 Modifier，这一条不会产生预期效果，需在游戏数据库中确认。

### 收口复核（2026-09-03）

- 两个目录工作区均干净，当前提交仍分别为 `6df05e0b231b41dae697e2878955647cdde556c6`（7.5）与 `7b3cddbe0c559fb13905d90b58c5057acdf93f5b`（旧版）；比较基线未漂移。
- 用新增 SQL 行提取出的 65 个标识符做新版全文交叉引用，未发现“新增行引用、但新版目录完全没有出现”的 `ModifierId`、`RequirementId`、`RequirementSetId`、`UnitAbilityType` 或同类标识符。此检查不包含基础游戏数据库，因此不能排除引用外部表/Modifier 的运行时问题。
- `POLICY_SUK_JAHAZI_PRODUCTION` 仍是唯一已确认的可疑外部 Modifier 引用：它在两版目录都没有定义，且 7.5 的 `Naval Guilds` 新政策新增了该引用；请在游戏数据库日志中确认是否由 Sukritact/其他外部模组提供。
- 跨目录比对确认多项大段“删除+新增”只是文件内搬家，最终数值未改变，例如 Garrison +7、ANTI_SPEAR +10、海军晋升 +5、GDR 防空 +20、部分伟人既有修正和飞机数值；这些未重复计入 7.5 新玩法。
- 11 个语言 XML 仍可解析；新增重复标签集中在法文 1 组、德文 1 组、日文 5 组、韩文 1 组、俄文 10 组（详见上文），其余重复组在旧版已存在。后写覆盖顺序和错语言属性仍需实际加载确认。

## 14. 常用只读命令

旧目录存在 Windows Git 所有权告警，查询时使用：

```powershell
git -c safe.directory=D:/Civilization/Civ6mods/BBGZYL/BetterBalancedGame -C .\BetterBalancedGame ...
```

新版提交范围检查：

```powershell
git -C .\BBG7.5 diff 7b3cddb..6df05e0
git -C .\BBG7.5 diff --check 7b3cddb..6df05e0
```

## 14.1 差异文件覆盖核对

以下为 `git diff --name-status 7b3cddb..6df05e0` 返回的全部 81 个文件；每个文件均已归入“有效玩法/加载机制”“本地化”“注释、回退或重排”之一。未列为单独条目的文件，其有效语句已在上文对应主题中合并说明。

- 加载与脚本：`BetterBalancedGame.modinfo`、`config/config.sql`、`scripts/bbg_script.lua`、`lua/BBG_Expanded/Goth.lua`、`ui/replacements/greatpeoplepopup_bbg.lua`。
- Expanded：`sql/BBG_Expanded/Austria.sql`、`Austria_Front.sql`、`England_UU.sql`、`Goths.sql`、`MOARUnits_enabled.sql`、`MOARUnits_enabledconfig.sql`、`PolandStanislaw.sql`、`Spearthrower.sql`、`TainoAnacaona.sql`、`Trisong.sql`、`Units.sql`、`Wonders.sql`。
- 基础规则：`sql/Base/Arabia.sql`、`Beliefs.sql`、`Buildings.sql`、`Districts.sql`、`Egypt_XP2.sql`、`England.sql`、`Features.sql`、`Germany.sql`、`Government.sql`、`GreatPeoples.sql`、`India.sql`、`LoadLast.sql`、`Norway.sql`、`Policies.sql`、`Rome.sql`、`Russia.sql`、`Spy.sql`、`Units.sql`、`Wonders.sql`、`base.sql`。
- DLC/领袖/资料片：`sql/DLC_Australia/dlc_australia.sql`、`sql/DLC_Macedon_Persia/Macedon.sql`、`Persia.sql`、`sql/DLC_Nubia/dlc_nubia.sql`、`sql/DLC_Poland/dlc_poland.sql`、`sql/LP/Elizabeth.sql`、`Sundiata.sql`、`VictoriaSteam.sql`、`Yongle.sql`、`lp_america_lincoln.sql`、`lp_rome_caesar.sql`、`sql/NFP/Byzantium.sql`、`Vietnam.sql`、`dlc_maya_colombia.sql`、`sql/XP1/Buildings_XP1_or_XP2.sql`、`Georgia.sql`、`Government_XP1_or_XP2.sql`、`Mapuche.sql`、`Mongolia.sql`、`Other_XP1_or_XP2.sql`、`Policies_XP1_or_XP2.sql`、`sql/XP2/Buildings.sql`、`Governors.sql`、`Mali.sql`、`Maori.sql`、`Policies.sql`、`Sweden.sql`、`Units.sql`、`new_bbg_inca.sql`、`new_bbg_ottoman.sql`、`sql/_utils.sql`、`sql/colors.sql`、`sql/victories/new_bbg_cv.sql`。
- 本地化：`lang/chinese.xml`、`english.xml`、`french.xml`、`german.xml`、`italian.xml`、`japanese.xml`、`korean.xml`、`polish.xml`、`portuguese.xml`、`russian.xml`、`spanish.xml`。

## 15. 更新日志

- 2026-09-03：建立本文件；写入当前已确认的基线、统计、文件清单、主要玩法变化、本地化统计、注释/回退项和后续核查清单。
- 2026-09-03（续）：补录 LoadLast 条件、Legion/Lake Victoria 最终值、Jadwiga、Arabia、Great General、Euclid、Democracy Legacy、玩家颜色与本地化折扣风险；细化 Austria 与 Taíno 的代码语义，并确认 Mapuche/Caesar 为回退或注释而非新变化。
- 2026-09-03（质量审计）：完成 `diff --check` 精确统计和全部语言 XML 解析；记录新增重复标签、法文语言代码错误、Longbowman/Political Philosophy 文本遗漏以及 Great People UI 的运行时验证风险。
- 2026-09-03（逐文件复核）：补充 Expanded 的完整加载条件与 `XP1_AND_XP2` 实际语义；发现 Austria 前端动作 ID 重复；以工作区内完整 Great People UI 脚本为旁证，下调外交官 Timeline 删除顺序本身的风险，但保留实际游戏验证要求。
- 2026-09-03（追加文本核对）：补入支持单位光环、Third Alternative、Sejong、Heavy Cavalry 的文本—代码差异；确认 `Units.sql:722-746` 的驻扎骑兵攻击 `+4` 为有效语句；新增 81 个差异文件全覆盖清单。
- 2026-09-03（收口复核）：确认两个仓库提交与工作区未漂移；完成新增 65 个标识符交叉引用、搬家代码净值复核及新增重复本地化标签统计；将待办全部收口到风险与游戏内验证清单。

## 16. 最终摘要（快速恢复用）

- **比较结论**：7.5 是一次大规模平衡与 Expanded 扩展更新，不是单纯版本号/翻译更新。有效变化集中在 Oligarchy、单位战斗力与升级路径、科技/海洋、政策卡、区域建筑、Great People、Mali/Norway/Sweden 等文明领袖，以及 Austria/Goths/Stanislaw Poland/Taíno/Expanded England。
- **最大规则级变化**：Oligarchy 改为非军事/支援单位友方领土 +1 移动力、单位经验 +40%、按晋升等级 +1 战斗力；`LoadLast.sql` 在指定规则集下对多类单位基础战斗力/远程战斗力 +4，并对攻击驻扎骑兵 +4；Heavy Chariot、Modern Armor、Machine Gun、AT、Quadrireme、Rock Band 等均有最终数值或行为改动。
- **Expanded 重点**：新增奥地利 Great Diplomat 与吞并城邦/外交支持、哥特建城人口联动、Taíno/Anacaona 全套重做、Stanislaw Poland 资源—军事区加成、Longbowman 新解锁与 Sea Dog 归属收紧。
- **已排除误报**：多处代码只是重排/搬家；Wonders、Vietnam、India、Byzantium、Light Cavalry、Modern Armor 条件能力、Big Ben 等方案已注释或回退，详见第 12 节。
- **主要风险**：`Austria_Front.sql` 两个前端动作共用 `id="BBG_Expanded_UU"`；`Naval Guilds` 引用目录内未定义的 `POLICY_SUK_JAHAZI_PRODUCTION`；法/俄/日/德/韩等本地化存在新增重复键，法文 Euphorique 行语言属性错误；若干英文描述未同步新 SQL 数值/条件。
- **验证边界**：已完成 Git、SQL/XML 静态审查和全文交叉引用；尚未启动《文明 VI》验证数据库加载、Mod 条件组合、UI 隐藏外交官及实际游戏效果。

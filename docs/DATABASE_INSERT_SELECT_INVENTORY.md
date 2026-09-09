# 动态 INSERT SELECT 清单

本清单覆盖 ModInfo 当前实际加载的全部 SQL 源，用于在精简数据库代码前区分静态重复、兼容性守卫、按上游数据生成的行和有顺序依赖的临时表流程。完整逐语句记录由 `tools/report_database_writes.ps1` 可重复生成到已忽略的 `artifacts/reports/ZYLPVPMOD-2.0.0-database-writes.json`；`manifest/database-insert-select-contract.json` 固定记录集合的语义 SHA-256 和所有聚合计数。

## 当前基线

- 动态 `INSERT ... SELECT` 源码总数：381，覆盖 47 个文件、60 个目标表、66 个直接源表和 35 个 Action；分析语义 SHA-256 为 `03ea2f82244fe69388bd17293da7725c2984145e8113c615ba320aeb046739fe`。
- 主键分析显示 371 条的首要未解析原因为 `insert-select`。其余 10 条仍是动态查询，只是先被 4 个“项目自建表无主键”和 6 个“官方表无主键”原因遮蔽，不能把 371 误当源码总数。
- 冲突模式为普通插入 278 条、`OR IGNORE` 83 条、`OR REPLACE` 20 条；208 条随所在源文件受至少一个 Criteria 门控。
- 结构互斥分类为 simple 304、joined 33、nested 30、compound 8、grouped 6。结构特征可重叠：291 条带过滤、43 条含嵌套查询、33 条含连接、26 条含 `EXISTS`、23 条使用 `DISTINCT`、8 条集合查询、6 条分组、4 条排序；当前没有 CTE 或 `LIMIT`。
- 18 条外层没有 `FROM`，只通过嵌套 `EXISTS` 判断可选内容是否存在；58 条读取自己的目标表，包含变体克隆、防重复插入和阶段式临时表展开。
- 源表提取问题为 0。每条记录固定路径、行号、插入序号、目标表、源表、Action、Criteria、冲突模式、语句哈希和结构标记。

## 集中区域

目标表最高的十组为：`ModifierArguments` 76、`RequirementSetRequirements` 41、`Modifiers` 38、`RequirementArguments` 26、`Requirements` 24、`RequirementSets` 17、`TraitModifiers` 15、`BuildingModifiers` 10、`ExcludedAdjacencies` 6、`ModifierStrings` 6。

直接源表最高的十组为：`Resources` 39、`Leaders` 34、`Eras` 27、`WonderTerrainFeature_BBG` 24、`Buildings` 22、`Yields` 20、`Units` 17、`Districts` 16、`Teotihucan_trades` 16、`BuildingReplaces` 12。

文件最高的十组为：

| 数量 | 文件 |
| ---: | --- |
| 49 | `Components/BBG/sql/_utils.sql` |
| 30 | `LeaderVariants/ZYL_CoastLeaderVariants_Gameplay.sql` |
| 23 | `Components/BBG/sql/Base/Beliefs.sql` |
| 23 | `Components/TeamPVPSecretSocieties/Gameplay.sql` |
| 21 | `Components/BBG/sql/BBG_Expanded/Spearthrower.sql` |
| 21 | `LeaderVariants/ZYL_CoastLeaderVariants_Config.sql` |
| 20 | `Components/BBG/sql/XP2/new_bbg_inca.sql` |
| 20 | `Components/BBG/sql/XP2/xp2__gathering_storm.sql` |
| 15 | `Components/BBG/sql/XP2/Government.sql` |
| 13 | `Components/BBG/sql/Base/Greece.sql` |

## 精简判定

“simple”只代表语法结构简单，不代表结果静态。只要查询读取 `Resources`、`Leaders`、`Buildings` 等表，结果就可能随 DLC、其他 Mod、Criteria 和前序动作变化；把它展开成固定 `VALUES` 会直接降低兼容性。

以下类别默认保留，除非实机数据库和所有受支持 profile 都证明等价：

- 18 条仅 `EXISTS` 守卫：它们按可选 DLC/对象存在性决定是否生成行，是兼容性逻辑。
- 58 条自读目标表：海岸/内陆领袖变体会把已加载完成的同表行复制到新键；另有临时表闭包和防重复查询，执行顺序本身属于语义。
- BBCC 的唯一精确重复组：`Components/BBG/sql/bbcc/no_rng_bbcc.sql` 第 340、349、358 行三次执行相同的自读插入，源码注释明确用于展开最多三层嵌套 RequirementSet。删除重复或改成递归 CTE 前必须先确认 Civ VI SQLite 能力、最终行集合和加载耗时。
- `OR IGNORE`/`OR REPLACE` 查询：冲突模式通常承担跨 DLC、跨动作或上游/最终覆盖的兼容职责，不能按文本相似度合并。

下一轮候选审查按“同文件相邻语句生成同一键族、非自读、非存在性守卫、相同 Criteria/Action”收窄，并对每个候选记录当前 SQLite 最终行、不同 DLC profile 和 `Database.log`。没有这些证据时只做清单化，不修改运行 SQL。

## 重现

```powershell
./tools/report_database_writes.ps1
```

报告中的 `insertSelectAnalysis.records` 是完整逐语句清单，`insertSelectAnalysis.counts` 和 `shapeCounts` 是聚合口径。`tools/validate.ps1` 会同时验证分类器正反例、语义指纹和所有计数；报告行号只用于定位、不进入语义视图，目标/源表、Criteria、Action、冲突模式、语句指纹或结构发生变化时必须显式审查并更新契约。

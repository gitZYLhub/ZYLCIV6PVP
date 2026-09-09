# Gameplay SQLite 最终值快照

这套工具把静态 SQL/XML 契约与 Civ VI 实际生成的 `DebugGameplay.sqlite` 接起来。它只读数据库，不修改游戏缓存；报告只写入仓库中已忽略的 `artifacts/`。

## 首批覆盖

默认 profile 为 `xp2-full-content`，要求 Gathering Storm 及 13 个兼容重复键涉及的 DLC/Leader provider 全部可用。28 个探针分为：

- 13 个保留重复主键的实际最终行；
- 7 个受支配后置 `INSERT OR IGNORE` 删除后的回归行（Work Ethic 2、西班牙 Coast 1、Nihang Types/UnitAbilities 4）；
- 8 个 Gaul、Gran Colombia、Khmer 最终覆盖及常量插入等价精简的正向值或旧绑定缺失状态。

查询及期望行保存在 `manifest/database-final-value-contract.json`，文件哈希由 `tools/project.json` 固定。每个查询必须是带 `ORDER BY` 的单条 `SELECT`/CTE；SQLite 连接还会强制 `query_only`。

## 生成可作为证据的报告

1. 先完成并提交待验证改动，确认 `git status --short` 为空。
2. 确认游戏实际加载的是该提交对应的 Mod，使用 Gathering Storm 与完整内容组合进入建局流程，使 Civ VI 重新生成 Gameplay 调试数据库，然后正常退出游戏。
3. 确认数据库时间晚于当前 Git 提交，再执行：

```powershell
$gameplayDb = Join-Path $env:LOCALAPPDATA "Firaxis Games\Sid Meier's Civilization VI\Cache\DebugGameplay.sqlite"
python tools/database/capture_final_values.py --database $gameplayDb
```

成功条件是进程退出码为 0、`Probes: 28/28 passed`，且报告中的 `summary.evidenceGuardsPassed` 为 `true`、`issues` 为空。默认报告位置是 `artifacts/reports/ZYLPVPMOD-1.3.0-xp2-full-content-database-final-values.json`。

同一次游戏加载还应按 [DATABASE_LOG_AUDIT.md](DATABASE_LOG_AUDIT.md) 审计 `Database.log`；数据库与日志必须都晚于同一提交，才能作为配对的实机证据。

## 诊断与基线比较

数据库尚未重载时，可以显式运行诊断：

```powershell
python tools/database/capture_final_values.py --database $gameplayDb --allow-stale --allow-dirty
```

诊断豁免只让查询继续执行；报告仍会把证据门标为未通过，不能登记为发布或等价性证据。

拥有经审查的冻结报告后，可增加语义比较：

```powershell
python tools/database/capture_final_values.py --database $gameplayDb --baseline path\to\approved-baseline.json
```

基线比较使用规范化 `semanticSha256`，忽略采集时间、数据库文件哈希等环境元数据。任何列、行、顺序、契约哈希或 profile 漂移都会失败。

## 安全边界

- 数据库以 `mode=ro` 打开，并设置 `PRAGMA query_only=ON`。
- 非空 `-wal` 会失败；应先正常退出 Civ VI，让数据库完成 checkpoint。
- 捕获前后文件大小或修改时间变化会失败，避免读取游戏正在更新的数据库。
- 报告不记录输入数据库的绝对路径，只保存文件名、大小、时间和 SHA-256。
- 输出路径强制位于 `artifacts/`；正式基线只能在人工确认游戏版本、DLC/profile、Mod 提交和日志后另行提升到版本控制。

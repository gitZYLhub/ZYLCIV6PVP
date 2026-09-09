# Database.log 加载错误审计

`tools/logs/audit_database_log.py` 审计 Civ VI 实际生成的 `Database.log`，与 Gameplay SQLite 最终值报告共同构成数据库重构的实机证据。

## 正式采集

先确保待验证改动已经提交、工作树干净，并用该提交对应的 Mod 完成一次目标 DLC/profile 加载后正常退出游戏。然后执行：

```powershell
$databaseLog = Join-Path $env:LOCALAPPDATA "Firaxis Games\Sid Meier's Civilization VI\Logs\Database.log"
python tools/logs/audit_database_log.py --log $databaseLog
```

正式通过要求：

- Configuration、Gameplay、Localization 三个外键验证序列全部通过；
- `unexpectedErrorCount` 为 0；
- `evidenceGuardsPassed` 为 `true`；
- `issues` 为空。

默认报告写入 `artifacts/reports/ZYLPVPMOD-1.3.0-database-log-audit.json`，不会记录本机日志绝对路径。

## 已知外部错误

当前 Civ VI/Firaxis Live 会从多个 `CurrentClickouts/<UUID>/Text/ClickoutText_en_US.xml` 重复插入 `LOC_CLICKOUT_26_CAROUSEL_TOOLTIP`。只有 ERROR 的 scope、唯一键消息、标签、BaseGameText 操作和上下文相对文件全部符合 `manifest/database-log-contract.json` 时才允许归类为外部噪声。

Gameplay、Configuration 或本项目文件产生的错误不能加入该白名单；上下文出现其他文件时，即使错误消息相同也会失败。

## 诊断与基线

检查旧日志时可以使用：

```powershell
python tools/logs/audit_database_log.py --log $databaseLog --allow-stale --allow-dirty
```

诊断豁免不会把旧输入变成正式证据，报告仍会保留 `evidenceGuardsPassed=false`。获得经审查的冻结报告后，可用 `--baseline path\to\approved-report.json` 比较规范语义哈希；已允许外部错误的出现次数不会影响语义哈希，缺少必需验证序列或任何未解释错误会影响并失败。

同一次加载还必须执行 [DATABASE_FINAL_VALUE_SNAPSHOT.md](DATABASE_FINAL_VALUE_SNAPSHOT.md) 和 [LUA_LOG_AUDIT.md](LUA_LOG_AUDIT.md)，并确认 SQLite 与两份日志都晚于同一 Git 提交。

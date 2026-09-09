# Lua.log 致命错误审计

`tools/logs/audit_lua_log.py` 审计 Civ VI 实际生成的 `Lua.log`，用于发现会中断 Gameplay、UI 或地图脚本加载的高置信错误。

## 正式采集

先提交待验证改动并保持工作树干净。用该提交对应的 Mod 完成目标 DLC/profile 的新局、读档或多人流程，正常退出游戏后执行：

```powershell
$luaLog = Join-Path $env:LOCALAPPDATA "Firaxis Games\Sid Meier's Civilization VI\Logs\Lua.log"
python tools/logs/audit_lua_log.py --log $luaLog
```

正式通过要求：

- `fatalCount` 为 0；
- `minimumLineCountPassed` 和 `evidenceGuardsPassed` 均为 `true`；
- `issues` 为空。

默认报告写入 `artifacts/reports/ZYLPVPMOD-2.0.0-lua-log-audit.json`。报告只记录 `Lua.log` 文件名、时间、大小和哈希；错误上下文中的项目脚本会保留仓库相对路径及行号，其他绝对路径会脱敏。

## 零白名单边界

`manifest/lua-log-contract.json` 当前固定五类致命标记：

- `Runtime Error`；
- `Syntax Error`；
- `Error loading file`；
- `stack traceback`；
- `Lua callstack`。

任一标记出现即失败，不为项目脚本、上游组件或官方脚本建立豁免。审计器不会因为一行只含普通的 `Attempt`、`Warning` 或 `Failed` 就失败；例如地图放置回退和 Mod 浏览器搜索上下文提示需要另行判断，不能掩盖上述致命标记。

## 诊断与基线

检查旧日志时可以使用：

```powershell
python tools/logs/audit_lua_log.py --log $luaLog --allow-stale --allow-dirty
```

这两个参数只允许完成诊断输出，不会把旧日志或脏工作树变成正式证据；报告仍保留 `evidenceGuardsPassed=false`，致命错误仍会令命令退出 1。获得经审查的新鲜报告后，可用 `--baseline path\to\approved-report.json` 比较规范语义哈希。

正式测试应在同一次游戏加载后同时执行 [DATABASE_LOG_AUDIT.md](DATABASE_LOG_AUDIT.md)、[MODDING_LOG_AUDIT.md](MODDING_LOG_AUDIT.md) 和 [DATABASE_FINAL_VALUE_SNAPSHOT.md](DATABASE_FINAL_VALUE_SNAPSHOT.md)，确保三份日志与 Gameplay SQLite 都晚于同一干净 Git 提交。不同 DLC/profile、新局、读档及双客户端流程应分别留存报告；一个干净日志不能替代未运行的场景。

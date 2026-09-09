# Modding.log 组件加载审计

`tools/logs/audit_modding_log.py` 审计 Civ VI 实际生成的 `Modding.log`，确认目标 Mod 身份、组件所有者、应用过程和加载期警告没有被外部内容噪声掩盖。

## 正式采集

先提交待验证改动并保持工作树干净。确认游戏加载的是该提交对应的 Mod，完成目标 DLC/profile 的前端配置、建局及待测流程，正常退出游戏后执行：

```powershell
$moddingLog = Join-Path $env:LOCALAPPDATA "Firaxis Games\Sid Meier's Civilization VI\Logs\Modding.log"
python tools/logs/audit_modding_log.py --log $moddingLog
```

正式通过要求：

- `requiredMarkersPassed` 等于 `requiredMarkerCount`，且当前契约要求“设置应用完成”和“游戏重配置成功”两个标记；
- `projectIdentityOccurrences`、`projectTargetComponentCount` 和 `projectAppliedComponentCount` 均达到契约下限；
- `componentOwnerConflictCount`、`unmappedAppliedComponentCount`、`missingProjectAppliedComponentCount`、`unexpectedWarningCount` 和 `projectWarningCount` 均为 0；
- `evidenceGuardsPassed` 为 `true`，`issues` 为空。

默认报告写入 `artifacts/reports/ZYLPVPMOD-1.3.0-modding-log-audit.json`。报告只记录日志文件名、时间、大小、哈希、组件相对路径和分类结果，不保存本机日志绝对路径。

## 外部警告边界

`manifest/modding-log-contract.json` 只允许当前游戏安装中已经核实的外部记录：

- 一条文字完全一致的 Firaxis 新旧排序算法提示；
- 仅限 `../../../DLC/<包>/...xml` 的缺失文件警告，而且下一行必须紧邻官方 `LocalizedText` 加载失败提示；
- Rulers of the Sahara 基础/XP2 的 `RulersOfTheSahara_RemoveData.xml`，以及 Catherine de Medici persona 的 `CatherineDeMedici_Modifiers.xml`；三者都必须同时匹配官方 Mod ID、组件 ID、`UpdateDatabase` 操作、相对文件和消息。

组件归属从日志的 Target Mods/Actions 区块建立，跨重新配置阶段会主动清空，防止把后续官方本地化噪声归给上一组件。任何已应用但无法映射所有者的组件、任何列为本项目目标但未见应用的组件，以及由本项目 Mod ID 拥有的组件警告都不能通过；未知 `Warning:`/`Error:`、归属冲突、身份或完成标记缺失也会失败。`Mod Selection Service missing` 等不带 Warning/Error 前缀的引擎服务提示不属于本契约的错误分类范围。

## 诊断与基线

检查旧日志时可以使用：

```powershell
python tools/logs/audit_modding_log.py --log $moddingLog --allow-stale --allow-dirty
```

诊断豁免只允许生成报告；旧日志或脏工作树仍会保留 `evidenceGuardsPassed=false`，身份、标记和未解释警告照常失败。获得经审查的新鲜报告后，可用 `--baseline path\to\approved-report.json` 比较规范语义哈希；已允许外部警告的出现次数不进入语义哈希。

正式测试应在同一次游戏加载后同时执行 [DATABASE_LOG_AUDIT.md](DATABASE_LOG_AUDIT.md)、[LUA_LOG_AUDIT.md](LUA_LOG_AUDIT.md) 和 [DATABASE_FINAL_VALUE_SNAPSHOT.md](DATABASE_FINAL_VALUE_SNAPSHOT.md)，确认三份日志与 Gameplay SQLite 都晚于同一干净 Git 提交。不同 DLC/profile、新局、读档和双客户端流程必须分别留存证据。

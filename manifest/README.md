# ModInfo 源清单

本目录保存用于生成 `ZYLPVPMOD.modinfo` 的开发源，不进入 Civilization VI 运行包。

- `baseline-1.3.0-action-graph.json`：冻结 1.3.0 与当前分支的 Action/Criteria/Files 双语义指纹；未来有意精简只更新当前指纹与计数，不得覆盖冻结字段。
- `database-write-set-contract.json`：冻结 1.3.0 与当前分支的数据库写集合指纹、计数和零写入源清单；未来有意重构只更新 `expectedCurrentAnalysisSha256`，不得覆盖冻结指纹。
- `civ6-schema-keys.json`：从 Civ VI build 15296837 的官方基础/XP1/XP2/Configuration Schema 确定性导出的表列、主键和唯一键快照；日常校验不读取游戏安装目录。
- `external-database-tables.json`：官方 Schema 和本项目建表语句之外的外部表及其提供者 Mod ID/Criteria 门控白名单。
- `database-primary-key-contract.json`：对官方 Schema 及项目 `CREATE TABLE` 可验证主键下的 SQL `VALUES`/XML 插入行建立主键/完整行指纹、覆盖计数和未解析原因契约；只把“更早无条件同值写入支配更晚 `INSERT OR IGNORE`”标记为强精简候选。
- `database-duplicate-key-allowlist.json`：必须保留的相同主键行，区分“独立 DLC/Leader 提供者”与“上游源自洽 + 最终 ZYL 兜底”两类；每组固定完整行相等、允许的冲突模式、来源路径及 Criteria 形状，拒绝用白名单掩盖普通冲突。
- `database-final-value-contract.json`：在 Civ VI `DebugGameplay.sqlite` 上执行的只读最终值契约；`xp2-full-content` 逐组覆盖 13 个保留重复键、7 行受支配精简回归和 7 个高风险最终覆盖状态，契约文件哈希由 `project.json` 固定。
- `criteria/*.xml`：按责任域拆分的 Criteria；`manifestOrder` 仅用于恢复冻结版全局顺序，组装时会移除。
- `actions/frontend/*.xml`：按责任域拆分的 FrontEndActions。
- `actions/ingame/*.xml`：按责任域拆分的 InGameActions。
- `files/*.xml`：按责任域拆分的 Files 路径，跨平台美术资产单独成域但仍完整保留。
- `dormant-files.txt`：有意保留在源码树、但因冲突或未启用而不得进入 ModInfo 的文件白名单。

当前 ActionCriteria、FrontEndActions、InGameActions 和 Files 已全部由分域片段生成。`tools/assemble_modinfo.ps1` 每次运行都会从片段重建这些运行元素，并保留 ModInfo 中不影响运行语义的人工说明注释；`tools/validate.ps1` 会拒绝片段与生成文件不一致的状态。

所有片段必须使用 `schemaVersion="1"`、目录内唯一 `domain` 以及全段正数且唯一的 `manifestOrder`。`manifestOrder` 是稳定排序号，删除条目后允许留洞，禁止为了连续而重排无关记录。Criteria 和 Actions 的 `id` 必须不区分大小写唯一；Files 路径会统一斜杠后按不区分大小写检查唯一性。不要直接手改生成后的四个运行图段；修改源片段后运行 `tools/assemble_modinfo.ps1`，再用 `tools/validate.ps1` 检查冻结/当前双语义契约。

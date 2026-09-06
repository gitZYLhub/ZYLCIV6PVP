# ModInfo 源清单

本目录保存用于生成 `ZYLPVPMOD.modinfo` 的开发源，不进入 Civilization VI 运行包。

- `baseline-1.3.0-action-graph.json`：冻结版 Action/Criteria/Files 语义指纹。
- `criteria/*.xml`：按责任域拆分的 Criteria；`manifestOrder` 仅用于恢复冻结版全局顺序，组装时会移除。

当前 Criteria 已由分域片段生成；FrontEndActions、InGameActions 和 Files 仍等待后续迁移。`tools/assemble_modinfo.ps1` 每次运行都会从片段重建 Criteria，`tools/validate.ps1` 会拒绝片段与生成文件不一致的状态。

所有片段必须使用 `schemaVersion="1"`、唯一 `domain`、连续且唯一的 `manifestOrder` 和不区分大小写唯一的 `id`。不要直接手改生成后的 ActionCriteria；修改源片段后运行 `tools/assemble_modinfo.ps1`，再用 `tools/validate.ps1` 检查冻结语义基线。

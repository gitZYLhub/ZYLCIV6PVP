# ModInfo 源清单

本目录保存用于生成 `ZYLPVPMOD.modinfo` 的开发源，不进入 Civilization VI 运行包。

- `baseline-1.3.0-action-graph.json`：冻结版 Action/Criteria/Files 语义指纹。
- `criteria/*.xml`：按责任域拆分的 Criteria；`manifestOrder` 仅用于恢复冻结版全局顺序，组装时会移除。
- `actions/frontend/*.xml`：按责任域拆分的 FrontEndActions。
- `actions/ingame/*.xml`：按责任域拆分的 InGameActions。
- `files/*.xml`：按责任域拆分的 Files 路径，跨平台美术资产单独成域但仍完整保留。

当前 ActionCriteria、FrontEndActions、InGameActions 和 Files 已全部由分域片段生成。`tools/assemble_modinfo.ps1` 每次运行都会从片段重建这些运行元素，并保留 ModInfo 中不影响运行语义的人工说明注释；`tools/validate.ps1` 会拒绝片段与生成文件不一致的状态。

所有片段必须使用 `schemaVersion="1"`、目录内唯一 `domain` 以及段内连续且唯一的 `manifestOrder`。Criteria 和 Actions 的 `id` 必须不区分大小写唯一；Files 路径会统一斜杠后按不区分大小写检查唯一性。不要直接手改生成后的四个运行图段；修改源片段后运行 `tools/assemble_modinfo.ps1`，再用 `tools/validate.ps1` 检查冻结语义基线。

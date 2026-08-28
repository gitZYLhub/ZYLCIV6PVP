# 来源与版本

## 上游副本

| 组件 | 版本 | 本机只读来源 | 整合位置 |
|---|---:|---|---|
| Better Balanced Game | 7.4.6 | `D:\Steam\steamapps\workshop\content\289070\2865001760` | `Components\BBG` |
| Better Balanced Map | 1.39.1 | `D:\Steam\steamapps\workshop\content\289070\3179425402` | `Components\BBM`；美术依赖位于根目录 |
| ZYL Multiplayer Suite | 1.0.0 | `D:\Civilization\Civ6mods\BBGZYL\ZYL_MultiplayerSuite` | 整合包根目录 |
| Multiplayer Helper | 1.7.9 | `D:\Steam\steamapps\workshop\content\289070\3307282026` | 已在 ZYL Multiplayer Suite 中完成冲突处理 |
| Team PVP Tools | 1.65 | `D:\Steam\steamapps\workshop\content\289070\3693899014` | 已在 ZYL Multiplayer Suite 中择取 UI/QoL |

生成的统一 Mod ID 为 `4dd01931-9d44-4a8a-8e74-712cba0f0072`，ModInfo 版本为 `100`，用户可见版本为 `1.0.0`。

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
- BBG Mod Manager 过滤表：把被内嵌的 BBM/MPH 条目替换为统一 Mod ID。

`tools\assemble_modinfo.ps1` 可从固定的上游 ModInfo 重新生成统一 ModInfo。脚本不会写入 Steam Workshop 目录。

## 许可

原组件的许可和作者声明保留在随包文件、ModInfo 属性和源文件注释中。整合本身不授予超出上游许可的再分发权。

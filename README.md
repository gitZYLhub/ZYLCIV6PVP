# ZYLPVPMOD 1.0.0

`ZYLPVPMOD` 是一个自包含的文明 VI 多人联机整合包：

- Better Balanced Game（BBG）7.4.6
- Better Balanced Map（BBM）1.39.1
- ZYL Multiplayer Suite 1.0.0：以 Multiplayer Helper（MPH）1.7.9 为比赛控制框架，合入经筛选和修复的 Team PVP Tools 1.65 UI/QoL

统一 Mod ID：`4dd01931-9d44-4a8a-8e74-712cba0f0072`

Steam Workshop 原件没有被修改。BBG 和 BBM 保留在 `Components` 命名空间中；BBM 美术资源因 `.dep` 的寻址规则放在整合包根目录。

## 安装与启用

1. 把整个 `ZYLPVPMOD` 文件夹放进文明 VI 的本地 Mods 目录。若当前开发目录已经被游戏扫描，不必再复制。
2. 在“额外内容”中停用原 BBG、BBM/BBS、MPH、Team PVP Tools 和旧 `ZYL Multiplayer Suite`。
3. 只启用 `ZYLPVPMOD 1.0.0`，然后完全退出并重启文明 VI。
4. 所有联机玩家必须使用内容完全相同的整合包；不能只看文件夹名称或 ModInfo 版本号。

本包通过 `<Blocks>` 阻止已知原组件同时启用，包括 BBG release/beta/WIP、BBM、BBS、CCB Maps、MPH、TPT、旧 ZYL 工具箱，以及已经内嵌或争夺同一上下文的 Better Report Screen、Better City States、Tech Civic Progress Plus、Better Builder Charges、Real Great People 和 Detailed Map Tacks。未知分支、改版和其他替换型 UI Mod 仍需人工排除。

本包依赖《迭起兴衰》和《风云变幻》，沿用 BBG 7.4.6 的依赖要求。

## 功能归属

MPH/ZYL 工具箱负责准备房间、版本握手、赛事预设、Ban/Pick、投票、计时、掉线暂停、重连、Resync、Remap/Restart、投降、观察者、匿名模式、Sudden Death 和强制结束回合。TPT 的右下角强制结束回合按钮也已保留，并改成与 MPH 快捷键一致的单次请求。

BBG 负责规则平衡、文明/领袖调整及其专用 `WorldRankings`、`UnitPanel`、`TradeOverview`。结束游戏界面由 MPH 提供完整 XML，BBG 只追加传统征服胜利逻辑。

BBM 负责地图脚本、出生点分配、地形/资源/奇观生成和相关美术依赖。

TPT 来源的代码只保留不争夺上述所有权的 UI/QoL，例如 Better Report Screen、万神殿/伟人/城邦界面、顶部栏、科技市政进度、通知清理、队友资源、地图钉快捷键、黑名单和本地设置。

## 多山富饶大陆

地图列表新增独立地图“多山富饶大陆”，不会覆盖原 BBM 地图。上一代强化地图已废弃并移除。新版直接基于 `ZYL_LightweightBalance` 的“富饶竖向大陆”生成逻辑：

- 保留南北向的长主大陆、东西宽海、外海岛屿、海洋资源和 1～10 级富饶度。
- 比原“富饶竖向大陆”温和提高山脉密度：提高构造山与独立山出现率，同时保留山口清理，避免主大陆被完全封死。目标是山地总量约提高 15%～25%，实际比例受尺寸、世界年龄和种子影响。
- 大陆编号改用文明 VI 的 `TerrainBuilder.StampContinents()` 地理板块盖章；东西/南北分队选项只影响出生点，不再把大陆分成横向或纵向条带。
- 可关闭道路，或选择远古、古典、工业、现代和铁路；默认为远古道路，在可通行的沿海/沿河地块生成，沿海种子优先主大陆。
- 运行时只加载该地图的独立命名空间工具，不替换 BBM 其他地图的生成器。鲨鱼等 `ZYL_LightweightBalance` 私有资源不会被间接生成。

当前提供 2/4/6/8/10/12 人档，推荐联机默认值为富饶度 4、东西分队、远古道路。

## 回合与科文行为

- 保留 MPH 的单次 `Shift+F` 强制结束回合请求，不使用 TPT 原来会持续重复提交的实现。
- 右下角新增 TPT 强制结束回合按钮，默认显示，可在工具箱本地设置中关闭。左键点击与 `Shift+F` 一样只发送一次 `ACTION_ENDTURN` 请求；原 TPT 右键持续重试路径已移除。
- `p+` / `p++`：本回合增加 20 秒；每回合最多一次。剩余不足 8 秒时增加 24 秒用于同步补偿。
- `p-` / `p--`：本回合减少 10 秒；每回合最多一次，最低 40 秒。
- `p+++` / `p++++`：本回合临时切为无计时，下一回合恢复所选 MPH 智能计时。
- 不加载 MPH 的 `NoMoreStack` 防堆科文功能。科技和市政可以像原版一样在未选择项目时继续积累溢出值。

## 已排除的高冲突模块

- TPT BSR 准备房间、TimerPro、NetHelper、Poker/21 点、AutoUpdate。
- TPT `WorldRankings`、`UnitPanel`、`TradeOverview` 和重复 UnitFlag replacements。
- TPT TOM、EGM、DDV、DPR、RCT 等会争夺现有界面的模块。
- TPT `NewUnitOperation` 及其高误报/自动更新路径。
- BSM 观察者外交条。

具体合并决策见 [CONFLICT_RESOLUTION.md](CONFLICT_RESOLUTION.md)，来源与本地修复见 [SOURCES.md](SOURCES.md)。

## 静态校验与实机测试

在本目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate.ps1
```

校验器检查 XML、ModInfo、动作/条件 ID、文件引用、BBM 美术依赖、LuaReplace 跨组件所有权、旧组件运行时 ID、上游失效引用、自动更新/动态加载和防堆科文代码。

静态通过不等于文明 VI 联机通过。正式比赛前必须按 [TEST_CHECKLIST.md](TEST_CHECKLIST.md) 至少用两个真实 Steam 客户端测试开房、生成地图（包括多山富饶大陆）、P++、强制过回合、掉线重连、Resync 和保存加载，并检查 `Lua.log`、`UI.log`、`Database.log`、`Modding.log` 与 `Multiplayer.log`。

## 分发说明

本包定位为自用测试整合。各组件的原作者和许可没有因整合而改变；公开上传、二次分发或宣称为原创前，必须分别确认 BBG、BBM、MPH、TPT 及其内含 UI 模块的授权要求。

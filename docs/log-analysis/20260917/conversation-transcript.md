# 出生点分配与游玩日志分析——对话全文

> 整理范围：本任务中用户消息与助手可见的过程说明/回答。未收录模型内部推理和工具原始输出。
>
> 日志来源：`D:\Civilization\Civ6mods\BBGZYL\logs\Logs_2026091701`、`D:\Civilization\Civ6mods\BBGZYL\logs\Logs_2026091702`

---

## 1. 用户

阅读新的日志"D:\Civilization\Civ6mods\BBGZYL\logs\Logs\_2026091701"和"D:\Civilization\Civ6mods\BBGZYL\logs\Logs\_2026091702"。主要分析两个问题：
1.玩家出生点分配是怎样的？有没有出现什么问题？
2.游玩过程中有没有出现问题？

---

## 2. 助手（回答）

我实际读取的是：

- `D:\Civilization\Civ6mods\BBGZYL\logs\Logs_2026091701`
- `D:\Civilization\Civ6mods\BBGZYL\logs\Logs_2026091702`

你消息中的 `logs\Logs\_2026091701` 路径不存在。总体结论：最终出生点分配成功，但存在明显的城邦重叠和马里出生点贫瘠问题；游玩阶段则存在严重的联机同步、反复重连和掉线。

## 1. 出生点分配

`Logs_2026091701` 中有两次地图生成：

- 20:04：8 个主要文明，BBS 成功完成。
- 20:22：10 个主要文明、12 个城邦；这才是 `Logs_2026091702` 继续游玩的地图。地图种子为 `-1873172215`，游戏种子为 `-1873172216`。

最终采用的是 5v5 环形大陆分配：

- 队伍 0：玩家 0–4
- 队伍 1：玩家 5–9
- 同队出生点距离下限：12
- 不同队出生点距离下限：18
- 每个玩家按照大厅顺序分配环形扇区，再结合文明出生偏好选点。

最终主要文明出生点如下：

| 队伍 | 玩家 | 文明/领袖 | 出生点 | 起点圈粮食/产能评估 |
|---|---:|---|---|---:|
| 0 | 0 | 埃及 / Cleopatra Alt | (44,78) | 11.3 / 10.2 |
| 0 | 1 | 巴比伦 / Hammurabi | (75,49) | 7.8 / 7.4 |
| 0 | 2 | 印度 / Chandragupta | (69,61) | 5.1 / 7.3 |
| 0 | 3 | 马里 / Mansa Musa | (75,37) | 0 / 约0 |
| 0 | 4 | 努比亚 / Amanitore | (52,16) | 9.7 / 9.0 |
| 1 | 5 | 马其顿 / Alexander | (26,70) | 5.1 / 7.5 |
| 1 | 6 | 巴西 / Pedro | (13,58) | 7.4 / 6.7 |
| 1 | 7 | 德国 / Barbarossa | (12,44) | 9.2 / 8.3 |
| 1 | 8 | 越南 / Lady Trieu | (25,16) | 7.1 / 14.4 |
| 1 | 9 | 罗马 / Trajan | (38,8) | 8.1 / 13.07 |

主要出生点记录见 [Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:6099)，最终平衡后的评估见 [Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:7879)。

### 发现的问题

1. 印度出生点连续失败 12 次

前 12 次尝试中，印度玩家 2 都没有找到可用的 rated bias：

- `Failed to place 2 CIVILIZATION_INDIA`
- `Error Major Player is missing: 2`

第 13 次才成功放到 `(69,61)`，随后出现 `Successfully ran!`。因此这不是最终缺少印度，而是出生点算法在当前文明组合和硬距离限制下反复失败，最终侥幸成功。

证据：[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:3951)、[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:5651)、[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:5714)。

2. Hattusa 与 Preslav 出生点重叠，这是明确的出生点 Bug

第 13 次最终分配中：

- Hattusa：`(66,72)`
- Preslav：`(66,72)`

随后距离检查明确报出两者距离为 `0`。而且第 13 次给 Preslav 分配时没有出现正常的 `Settled plot` 记录，说明它很可能保留了前一次尝试的旧出生点。

证据：[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:5703)、[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:5712)、[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:5995)。

3. 马里出生点严重贫瘠

日志显示脚本主动对马里出生点进行了大范围沙漠化：

- 影响范围：半径 5，约 101 个格子
- 最终起点圈：34 个沙漠格
- 即时粮食：0
- 即时产能：约 0
- 食物补偿：`Couldn't add Food Bonus`

虽然马里获得了一个“五产出保证”资源，但这不能弥补整个出生区域的贫瘠。这个出生点很可能会造成明显的不公平开局。

证据：[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:6641)、[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:7370)、[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:7884)。

4. 越南的环二礁石资源放置失败

出现一次：

`unable to place ring-two reef resource for coastal-start player 8`

这不会导致文明缺少出生点，但说明越南的海岸资源保证没有完全执行。[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:7940)

另外，`BBS分配出生点失败` 这句中文提示是误导性的。代码使用了始终为真的判断条件，所以每次都会打印；最终是否成功应以 `BBS_AssignStartingPlots: Successfully ran!` 为准。见 [ZYL_RVC_Balance.lua](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_Balance.lua:864>)。

## 2. 游玩过程中

有问题，而且主要是联机同步问题。

### 联机状态严重不同步

`Logs_2026091702\net_message_debug.log` 中统计到：

- 20,470 条 `AutoArchive out of sync`
- 15,245 条数据哈希不一致
- 2,969 条客户端缺少数据
- 2,256 条主机缺少数据

第一次明显异常发生在第 41 回合，之后在多个回合持续出现。游戏进行了大量同步快照和重同步，甚至出现约 22 MB 的同步快照。[net_message_debug.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091702/net_message_debug.log:950)、[net_message_debug.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091702/net_message_debug.log:34204)

另外还出现两次：

`Error: Snapshot data was empty`

说明部分重同步过程本身也不顺利。

### 反复掉线、重连和踢人投票

第二组日志中：

- `ShutdownGame()` 离开网络会话 8 次
- `PlayerConnected` 共 76 次
- `DelayedPlayerLeft` 共 129 次
- 玩家 2、3、4 出现多次连接异常
- 00:38 左右对玩家 2、3 发起过踢人投票，但一个失败、一个超时，并没有证据表明成功踢出

例如：[net_message_debug.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091702/net_message_debug.log:34308)、[net_message_debug.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091702/net_message_debug.log:34372)、[net_message_debug.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091702/net_message_debug.log:34425)。

### 但游戏没有立即崩溃

日志仍推进到了第 59 回合，且 10 个主要文明都在 `Player_Stats.csv` 中有城市和科技数据，没有最终的主要文明缺失或 Lua 崩溃记录。[Player_Stats.csv](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091702/Player_Stats.csv:412)

不过日志在第 59 回合后结束，并伴随玩家掉线，所以不能认为这局运行稳定。

## 其他技术问题

还有一些非出生点问题：

- `DifficultyTraits` 表不存在：1701 中 2 次，1702 中 9 次。
- `ZYL_RingMainland_Text.xml` 反复解析失败。
- 大量重复的 `LocalizedText` 唯一键错误和 DLC 中文翻译加载失败。

这些主要会影响文本、设置显示或难度相关功能，但目前没有证据表明它们直接导致地图生成失败。[Database.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091702/Database.log:174)、[Modding.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091702/Modding.log:28988)

最需要优先修复的是：

1. 每次出生点重试前清空所有主要文明和城邦的旧 `StartingPlot`，并增加出生点唯一性检查。
2. 修复马里沙漠化后的食物/产能补偿。
3. 重点排查多人不同步，尤其是模组加载顺序、版本差异和非确定性的地图/平衡脚本。

---

## 3. 用户

巴比伦/印度和马里的出生点之中明显存在问题，巴比伦在大厅中更靠前，应该离埃及更近，但是实际上埃及离印度更近，巴比伦被分配到了中间的位置，巴比伦正常出生在了自己的扇区内吗？为什么？

---

## 4. 助手（过程说明）

我会把大厅排序、队伍/扇区映射和最终坐标逐一对齐，并计算埃及—巴比伦—印度之间的实际距离，确认巴比伦是“扇区映射错误”还是“扇区内落点被平衡算法挪动”。

---

## 5. 助手（回答）

你的判断是对的：这不是视觉误差。最终地图中，埃及到印度为 34 格，埃及到巴比伦为 46 格；巴比伦到印度、马里都只有 12 格，正好贴着同队最低距离限制。[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:5752)

结论是：

- 巴比伦的“大厅编号→扇区编号”分配是正确的：P0 埃及为 rank1，P1 巴比伦为 rank2，P2 印度为 rank3，P3 马里为 rank4。
- 但巴比伦的最终几何位置并没有落在原始的 rank2 扇区内。

| 玩家 | 原始扇区 | 最终坐标 | 按地图中心计算的角度 |
|---|---:|---:|---:|
| 埃及 P0 | 54°～90° | (44,78) | 约 89.2° |
| 巴比伦 P1 | 18°～54° | (75,49) | 约 9.9° |
| 印度 P2 | -18°～18° | (69,61) | 约 34.5° |
| 马里 P3 | -54°～-18° | (75,37) | 约 -11.7° |

大厅排序和原始扇区定义见[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:5583)，最终坐标见[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:6099)。

原因是：

1. 印度在前 12 次出生点尝试中都没有成功落位，第 13 次才成功。[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:5492)[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:5651)

2. 第 13 次尝试开始，代码把扇区边界放宽 50%。原本每个扇区宽 36°，放宽后每侧增加 18°：

   - 巴比伦 rank2：允许范围从 18°～54°扩大到 0°～72°；
   - 印度 rank3：允许范围扩大到 -36°～36°。

   两者因此产生 0°～36°的大面积重叠。[ZYL_RVC_AssignStartingPlots.lua](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:1467>)

3. 出生点是逐个贪心确定的，没有最后的整体交换或“每个扇区只能有一个玩家”的复核。巴比伦先被放到 `(75,49)`，随后印度才被放到 `(69,61)`，于是实际空间顺序被打乱。扇区中心评分只是软偏好，不是强制条件。[ZYL_RVC_AssignStartingPlots.lua](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:3425>)

所以，准确说法是：

> 巴比伦在程序记录上属于自己的 rank2 扇区，但实际坐标已落入中央重叠区域，接近甚至进入了印度的原始扇区；印度反而落入了巴比伦的原始扇区。这是重试放宽规则与逐个贪心落点共同造成的出生点分配问题，不是大厅顺序读取错误。

---

## 6. 用户

两个问题：
1.埃及的位置为什么如此靠近外侧边界？边家的“扇区中心”的10%的偏移有没有生效？
2.你的意思是巴比伦被放在了`(75,49)`  ，然就印度就找不到地方放了，所以失败了12次。问题是为什么巴比伦会被放在自己的扇区之外？

---

## 7. 助手（过程说明）

我会进一步核对两点：埃及的“外侧”到底是径向位置还是角度位置，以及巴比伦在第几次尝试开始越过原始扇区边界。重点检查重试放宽、落点评分和印度失败之间的先后关系，避免把因果关系说反。

---

## 8. 助手（回答）

先修正我上一条的因果表述：不能简单理解为“巴比伦先占了 `(75,49)`，所以印度随后失败了 12 次”。实际顺序是：印度连续失败触发了重试；重试放宽扇区后，巴比伦才被允许越出原始扇区。

### 1. 埃及为什么靠外侧？10%偏移是否生效？

生效了，但它只调整“角度目标”，不调整径向距离。

最终地图中心约为 `(44,44)`，外圈半径为 40。[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:3215)

埃及 P0 的原始扇区是 `54°～90°`：

- 原始中心：`72°`
- 边家向中间偏移 10%：`72 - 36×10% = 68.4°`
- 日志确实记录了 `target 68.4`。[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:5593)

但最终埃及在 `(44,78)`：

- 实际角度约 `89.2°`，接近扇区边缘；
- 实际半径约 `34.5`，而埃及的径向允许范围是 `26～38`；
- 日志中的 `angleDiff 20.77` 也说明它离目标 `68.4°` 很远。[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:5607)

原因是：

1. 10%偏移只是候选评分加分，不是强制坐标；
2. 埃及属于普通陆地文明，边家并没有额外的“向内圈”径向限制；
3. 地形、文明偏好、距离条件和区域候选优先级可以压过扇区中心评分。

对比第 1 次尝试，埃及曾经在 `(57,77)`，角度几乎正好贴近 `68.4°`，说明偏移公式本身确实运行了。[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:3907)

### 2. 巴比伦为什么会在自己的原始扇区之外？

最终设计扇区中，巴比伦 P1 的 rank2 扇区是 `18°～54°`。但 `(75,49)` 的实际角度约为 `9.9°`，已经落入印度原始的中央扇区 `-18°～18°`。

关键时间线是：

| 尝试 | 巴比伦位置 | 扇区状态 |
|---|---|---|
| 第1～6次 | `(75,54)` | 约18.4°，仍在原始扇区内 |
| 第7～12次 | `(75,49)` | 第7次后扇区放宽，9.9°被允许 |
| 第13次 | `(75,49)` | 继续沿用放宽规则，印度最终在 `(69,61)` 成功 |

第 1 次巴比伦仍在 `(75,54)`，但印度已经失败；第 7 次之后巴比伦才变成 `(75,49)`。[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:3917)[Lua.log](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:4768)

源码规定：

- 第 7 次起，扇区扩展 25%，即每侧增加 9°；
- 第 13 次起，扩展 50%，即每侧增加 18°。[ZYL_RVC_AssignStartingPlots.lua](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:1467>)

因此第 7 次起，巴比伦的有效范围变成：

```text
原始：18°～54°
放宽： 9°～63°
```

`9.9°` 虽然不在原始扇区内，却在放宽范围内，所以程序接受了它。第 13 次印度的有效范围也扩大到 `-36°～36°`，于是印度被放到了约 `34.5°` 的位置，实际进入巴比伦的原始扇区。

所以最终结论是：

> 巴比伦的“玩家编号→扇区编号”没有错，仍然是 rank2；但它的实际坐标已经越过原始扇区边界。这是重试放宽规则造成的，且最终验证使用的也是放宽后的范围，因此没有被判定失败。[ZYL_RVC_AssignStartingPlots.lua](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:1762>)

印度的失败直接表现为 `ratedBiases=nil; regionIndex=0`，日志没有证明“巴比伦占据 `(75,49)`”是前 12 次失败的唯一原因；更准确地说，是印度缺位触发重试，而重试放宽又破坏了扇区的唯一性。

---

## 9. 用户

印度为什么老是失败？

---

## 10. 助手（过程说明）

我再把印度每次失败时的“候选为空”拆开：是没有符合印度扇区的地块、被巴比伦/马里的距离条件筛掉，还是候选存在但评分被判为无效。这个区别决定真正的修复点。

---

## 11. 助手（过程说明）

已经定位到：印度不是“某一块地偶然失败”，而是被当前出生流程稳定地排到了最后，再去填本局最拥挤的中央扇区；前 12 轮的放宽又不够，直到第 13 轮才放宽到能容纳它的范围。

---

## 12. 助手（回答）

印度反复失败的根因是“排位靠后 + 中央扇区过窄 + 放宽太晚”的组合，不是印度文明本身无法出生。

1. 印度被排到了最后

本次有效数据库中，印度没有可供该函数读取的有效 `StartBias`。代码会把无 Bias 文明放到 `tierMax + 1`，所以最终顺序中印度最后才处理：

`埃及 → 巴比伦 → 德国 → 马里 → … → 印度`
见 [ZYL_RVC_AssignStartingPlots.lua:2339](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:2339>) 和 [Lua.log:5648](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:5648)。

因此印度进入自己扇区时，其他文明已经先占掉了大量高质量、满足距离条件的地块。

2. 印度的中央扇区本来是 `-18° ~ 18°`

第 13 轮以前，印度只能在这个中央扇区和半径 `26 ~ 38` 内找点。此时巴比伦、马里已经先落点，印度可用地块很少。

代码还要求主要文明的最高候选分数必须大于 0；否则 `ratedBiases` 就保持 `nil`。备用地块也继续套用印度自己的扇区限制，因此没有真正绕开这个问题。见 [ZYL_RVC_AssignStartingPlots.lua:2417](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:2417>) 和 [ZYL_RVC_AssignStartingPlots.lua:2496](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:2496>)。

所以日志连续出现：

```text
ratedBiases:nil
Attempt to place using fallback 2 CIVILIZATION_INDIA
Failed to place 2 CIVILIZATION_INDIA
```

例如 [Lua.log:3948-3952](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:3948)。

3. 真正成功时已经不是正常扇区出生

第 13 轮开始：

- 扇区角度放宽 50%，印度范围变成 `-36° ~ 36°`
- `isStartCheck=true`，取消了无河流和邻海等强惩罚
- 最终印度出生在 `(69,61)`，相对中央目标的角度偏差是 `34.46°`

也就是说，`(69,61)` 原本就在印度扇区之外，只有第 13 轮放宽后才被接受。见 [Lua.log:5651-5652](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:5651) 和 [ZYL_RVC_AssignStartingPlots.lua:1467](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:1467>)。

所以准确地说：

> 印度前 12 次不是“没有任何地图位置”，而是没有找到同时满足扇区、距离、地形评分和分数阈值的候选点；第 13 次通过放宽扇区和评分条件，才被强行放到相邻扇区。

另外，不能把 12 次失败全部归因于巴比伦 `(75,49)`。第一次印度失败时，巴比伦还在 `(75,54)`；`(75,49)` 是后续重试才出现的结果，见 [Lua.log:3913-3917](D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:3913)。

最优先的修复点是：让印度获得明确的出生优先级，或者让环形地图按大厅顺序处理文明，而不是按 StartBias 顺序处理；同时应在第 1～2 次失败后就放宽印度的相邻扇区搜索。

---

## 13. 用户

可是这很奇怪，哪怕巴比伦、马里已经先落点，但是它们都是落在自己的扇区内，印度也有自己的扇区。你说印度没有`StartBias`，那反而简单了，在自己的扇区内找到一个产出足够高且离其他人距离不是太近的地方就行了，为什么反而很难？到底是什么条件在几十次当中都不满足？

---

## 14. 助手（过程说明）

你这个质疑是对的：如果只是“没有 StartBias”，按理不应该连续 12 轮都找不到合法点。我现在把“高产出”与实际代码的候选筛选分开核对，重点确认到底是扇区几何、硬距离，还是某个通用负面条件把印度扇区内的候选全部打成了无效。

---

## 15. 助手（过程说明）

我已经找到一个比“没有 `StartBias`”更关键的实现细节：这个脚本并不是在扇区里按“产出最高”直接搜索。它先把大量地块硬过滤掉，再要求候选评分大于 0；而且当前代码里真正的相邻产出评分是被注释掉的。我继续把第二份日志也对照一下，确认这是不是重复出现的同一条路径。

---

## 16. 助手（回答）

你这个质疑是对的：我需要修正前面的表述。印度失败的主因不是“没有 `StartBias`”，而是当前脚本实际执行的条件比“扇区内找高产地块”严格得多，而且它实际上没有把最终产出作为主要评分项。

实际流程近似是：

```text
StartPositioner 分出的区域
∩ 扇区/角度范围
∩ 淡水或沿海
∩ 不含特定资源、火山、过多水/障碍
∩ 与已落点距离合格
∩ 最终评分 > 0
```

其中任意一项不满足，印度就没有可用候选。

关键证据是：

- 印度的名义扇区是 `-18° ~ 18°`，第 7–12 次只放宽到 `-27° ~ 27°`；第 13 次才放宽到 `-36° ~ 36°`。[扇区定义](<D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:5593>)、[放宽逻辑](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:1467>)
- 前 12 次印度全部是 `ratedBiases:nil → fallback → Failed to place`。[第一次失败](<D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:3948>)、[第 12 次失败](<D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:5489>)
- 第 13 次成功的印度点是 `(69,61)`，相对中心的角度差为 `34.46°`。[成功记录](<D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:5648>)
- `34.46°` 不在印度原本的 `[-18°,18°]` 内，也不在第 7–12 次的 `[-27°,27°]` 内，只能在第 13 次的 `[-36°,36°]` 放宽后进入。

所以，重复失败的最确定原因是：

> 印度自己的严格扇区内，没有留下一个同时满足地图候选过滤、距离限制、评分大于 0 的地块；最终能用的 `(69,61)` 实际上是靠第 13 次放宽扇区才被纳入的。

巴比伦和马里的落点会进一步减少印度的距离合格候选，但不是唯一原因。第一次印度失败时巴比伦还是 `(75,54)`，并不是最终的 `(75,49)`，所以不能说是 `(75,49)` 单独导致印度失败。

另外还有一个更严重的问题：脚本并没有真正按“相邻产出最高”选点。产出评分代码被注释掉了：[`CountAdjacentYieldsInRange` 未参与评分](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:3368>)。最终印度 `(69,61)` 的日志评估甚至是：

```text
Immediate Food: 0
Immediate Prod: 0
```

见[最终出生点评估](<D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:6102>)。也就是说，它通过的是几何、距离和自定义评分，不是你期望的“高产出条件”。

“没有 `StartBias`”只会让情况更差：

- 无偏好的文明被放到 `tierMax + 1`，通常较晚处理，巴比伦、马里等先占据合法点。[无偏好排序](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:2369>)
- 无偏好时会启用通用反偏好规则，例如无河流、靠海、泛滥平原过多、冻土等惩罚。[相关评分规则](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:2921>)
- 大区最低 fertility `110` 只是区域划分门槛，并不保证最终选中的具体地块产出高。[区域划分](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:1908>)

因此，当前日志能确定“前 12 次联合条件没有满足”，但由于 `__Debug` 函数被禁用了，日志没有记录每个候选具体是因为“扇区外、无淡水、评分≤0，还是距离不合格”被淘汰。要精确统计每一类原因，需要在候选过滤处增加计数日志。

---

## 17. 用户

你提到，印度自己的严格扇区内，没有留下一个同时满足地图候选过滤、距离限制、评分大于 0 的地块。那么，具体来说，是什么原因导致了扇区内没有合适的地块？明明每个文明的扇区有300+的地格数量

---

## 18. 助手（过程说明）

这个问题的关键在于：`300+` 是扇区里的原始地图格数量，但脚本并不是在这 300 个格子上逐格搜索。它只在 `StartPositioner` 预先给出的少量“大区起始候选”里搜索。我要把这两层候选集合分开核对，并进一步确认印度扇区被删掉的主要是“区域候选不足”、还是“淡水/资源/距离/评分”过滤。

---

## 19. 助手（过程说明）

我再把“原始扇区格子”和“真正进入起始点搜索的候选”逐层对齐，并核对这次地图实际使用的肥沃度阈值；这里有一个关键区别：最终这张 Ring 图传入的是 `MIN_MAJOR_CIV_FERTILITY=150`，不是脚本默认值 110。

---

## 20. 助手（回答）

结论：`300+` 是几何扇区内的原始陆地格数，不是印度真正参与评分的候选格数。印度连续失败时，代码实际验证的是：

```text
StartPositioner候选
→ 地图硬过滤
→ 印度环形扇区过滤
→ 距离检查
→ 评分最高者必须 > 0
```

具体过程如下。

1. 首先，地图并没有把整个扇区交给印度搜索。

本次地图传给起始点系统的是：

```lua
MIN_MAJOR_CIV_FERTILITY = 150
```

见 [`zyl_rich_mainland_core.lua:533`](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/zyl_rich_mainland_core.lua:533>)。

随后代码调用：

```lua
StartPositioner.DivideMapIntoMajorRegions(10, 150, ...)
```

见 [`ZYL_RVC_AssignStartingPlots.lua:1908`](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:1908>)。

所以 `__TableSize startPlots: 10` 表示的是 10 个主要区域，不是 10 个格子，也不是整个地图的全部陆格。低肥沃度、未被引擎划入主要起始区域的格子，根本不会进入印度搜索。

顺便更正前面的说法：110 是脚本默认回退值；这次 Ring 地图实际传入的是 150。

2. 进入主要区域后，还会被硬过滤。

[`__FilterStart`](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:2211>) 和 [`__GetValidAdjacent`](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:4530>) 会排除：

- 不是陆地、不可通行；
- 没有淡水且不是海岸；
- 靠近地图边缘；
- 火山、自然奇观缓冲区；
- 周围水域或不可通行地形过多；
- 周围存在特定资源 ID `27、11、28`。

因此，扇区内的300个格子中，很多格子可能连“起始候选”都不是。

3. 印度的严格扇区其实很窄。

印度的原始扇区是：

```text
角度 -18° 到 18°
半径 26 到 38
```

见 [`Lua.log:3895`](<D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:3895>)。

搜索失败阶段：

- 第1～6次：角度仍为 `-18°～18°`；
- 第7～12次：扩大到约 `-27°～27°`；
- 第13次：扩大到约 `-36°～36°`。

代码见 [`__IsPlotInDistributionBand`](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:1455>)。

关键证据是：印度最终成功的 `(69,61)`，相对于环心的角度偏差是：

```text
34.4608°
```

见 [`Lua.log:5650-5652`](<D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:5650>)。

这个位置不在印度原始扇区内，也不在前12次的 `±27°` 范围内，只在第13次 `±36°` 的扩大范围内。因此，最终可用点明显位于印度扇区的外缘，靠近巴比伦方向。

4. “没有 StartBias”并不等于条件宽松。

印度没有有效的 `StartBias`，于是会触发通用的负面规则：

- 前6次没有河流：`-90,000,000`；
- 第6～11次无河流：仍有较大负分；
- 非沿海文明靠近海岸：早期 `-9,000,000`；
- 周围洪泛平原超过3个：`-90,000,000`；
- 周围出现冻土：`-90,000,000`；
- 水域形状过于封闭：`-90,000,000`；
- 与已有文明距离不足：`-90,000,000`。

相关代码在 [`ZYL_RVC_AssignStartingPlots.lua:2921-3007`](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:2921>)。

然后每个主要区域还必须满足：

```lua
tempBiases[1].Score > 0
```

见 [`ZYL_RVC_AssignStartingPlots.lua:2415-2424`](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:2415>)。

印度前12次的日志都是：

```text
ratedBiases: nil
```

例如 [`Lua.log:3948-3952`](<D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:3948>) 和 [`Lua.log:5489-5493`](<D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:5489>)。

这说明真正失败的条件是：

> 在当前扇区范围内，10个主要区域中没有任何一个区域的最高候选分数大于0。

并不等于“300个格子逐个检查后发现产出不足”。

另外，起始点评分实际上没有使用即时粮食和产能。相关即时产出评分代码是注释掉的：

```lua
--ratedPlot.Score = ratedPlot.Score + self:__CountAdjacentYieldsInRange(...)
```

最终印度成功的 `(69,61)` 甚至显示：

```text
Immediate Food: 0
Immediate Prod: 0
```

见 [`Lua.log:6102`](<D:/Civilization/Civ6mods/BBGZYL/logs/Logs_2026091701/Lua.log:6102>)。

所以这次印度失败的核心不是“扇区内没有300个地格”，而是：

> 印度扇区内真正进入起始点系统的候选很少；剩余候选又受到淡水、资源、地形、无Bias负分和已有文明距离限制。前12次严格/半放宽扇区内没有正分候选；第13次扩大到约 `±36°` 后，才把 `(69,61)` 纳入。

现有日志没有输出每个候选具体被哪条规则淘汰，因为 `__Debug` 函数本身是空的（[`ZYL_RVC_AssignStartingPlots.lua:1167`](<D:/Civilization/Civ6mods/BBGZYL/ZYLPVPMOD2.0/Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua:1167>)）。因此可以确定失败链条和主要瓶颈，但不能仅凭现有日志给出“300格中有多少格因淡水失败、多少格因距离失败”的精确数量。

---

## 21. 用户

1.将本次对话的全文整理成文档，上传到github
2.将这两份日志，也同步上传到github

---

## 附件

- `logs/Logs_2026091701/`：第一份原始日志目录
- `logs/Logs_2026091702/`：第二份原始日志目录

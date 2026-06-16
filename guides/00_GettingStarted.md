# 00 入门指南

欢迎使用 SF6 Training Tools 训练工具包。本指南会帮助你完成基本启动和功能入口说明，不需要提前了解 mod 开发。

## 这套工具是什么？

这是一组运行在 REFramework 内的 Street Fighter 6 训练辅助脚本。它提供自定义连段 Trial、命中确认训练、反应训练、距离显示、碰撞框显示、录制槽管理等功能，目标是把训练模式变成更高效的练习环境。

## 第 1 步：确认 REFramework 已安装

REFramework 是这些脚本运行的加载器。如果你正在阅读这个目录，通常说明它已经安装在游戏目录下。如果需要重新安装：

1. 下载适用于 Street Fighter 6 的 REFramework。
2. 解压到 SF6 游戏根目录，也就是 `StreetFighter6.exe` 所在目录。
3. 启动游戏。
4. 如果 REFramework 正常注入，游戏启动时左上角通常会短暂显示 REFramework 水印。

## 第 2 步：打开 REFramework 菜单

游戏内按 **Insert** 打开 REFramework 菜单，再按一次关闭。

如果笔记本键盘没有独立 Insert，可以尝试：

- `Fn + Insert`
- `Fn + Del`
- `Fn + 0`
- `Home`

## 第 3 步：进入训练模式

大多数训练脚本只在 **Training Mode** 中工作。进入训练模式并选择双方角色后，训练工具会开始生效。

## 第 4 步：切换训练脚本

进入训练模式后，可以用两种方式切换主动训练模式。

### 手柄

按住 **FUNC 按钮**，再按 **方块 / X** 循环切换模式。FUNC 默认通常是 SELECT/BACK，可在菜单里修改。

### 键盘

按键盘顶部数字行的 **[0]** 循环切换模式。

屏幕顶部会显示浮动模式栏：

- **确认训练**：练习命中/防御确认。
- **反应训练**：针对木人随机动作做反应。
- **防后训练**：练习防住后惩罚。
- **连段 Trial**：录制并练习自定义连段。

## 工具索引

| 指南 | 工具 | 作用 |
| --- | --- | --- |
| 01 | Distance Viewer | 在画面上显示距离、攻击范围、跳跃轨迹。 |
| 02 | Training Script Manager | 顶部模式栏、模式切换、快捷键和颜色配置。 |
| 03 | Custom Combo Trials | 录制连段并按步骤验证练习。 |
| 04 | Hit Confirm | 练习命中确认和防御确认。 |
| 05 | Post Guard | 练习防住对手攻击后的惩罚。 |
| 06 | Reaction Drills | 针对随机录制动作做反应训练。 |
| 07 | Recording Slot Manager | 管理训练模式木人录制槽。 |
| 08 | Training Remote Control | 用手机网页远程控制训练工具。 |

## 常用术语

- **Dummy / 木人**：训练模式中由 CPU 控制的对手。
- **Frame / 帧**：游戏时间单位。SF6 为 60 FPS，1 帧约等于 0.017 秒。
- **Frame data / 帧数据**：招式启动、持续、硬直等阶段的帧数。
- **Hit Confirm / 命中确认**：根据攻击命中或被防，决定是否继续连段。
- **Oki / 起攻**：对手倒地起身时进行压制。
- **Meaty / 压起身**：让攻击持续帧覆盖对手起身时机。
- **Punish / 确反**：在对手硬直期间命中对手。
- **Whiff Punish / 差返**：打中对手挥空招式的硬直。
- **DI / Drive Impact**：SF6 的 Drive Impact。
- **DRC / Drive Rush Cancel**：普通技取消到 Drive Rush。
- **CH / Counter Hit**：对手启动中被命中。
- **PC / Punish Counter**：对手硬直中被命中，收益更高。
- **数字方向记法**：用数字小键盘表示方向：`6` 前、`4` 后、`2` 下、`8` 上、`5` 中立。

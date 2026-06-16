# 01 Distance Viewer 距离显示

Distance Viewer 用于实时显示攻击范围、双方距离、穿身跳距离和跳跃轨迹。它可用于训练模式，也可以在对战、Battle Hub 和录像中辅助观察距离。

## 这个工具解决什么问题？

格斗游戏中的中距离控制非常依赖距离感。这个工具把当前双方距离和招式最大范围可视化，帮助你练习：

- 牵制距离。
- 对空距离。
- 差返距离。
- 特定招式的最远命中点。
- 跳入是否会穿身。

## 基础模式

基础模式不需要额外设置。打开 REFramework 菜单，找到 **Distance Viewer**，确认 **Expert Mode** 关闭即可。

基础模式会用预设距离阈值显示红、橙、黄、绿等区域，让你快速判断当前距离。

### 穿身跳提示

工具会判断当前位置前跳是否会穿到对手背后：

- **CrossUpSt**：可穿站姿对手。
- **CrossUpCr**：可穿蹲姿对手。
- **No Cross**：不会穿身。

### 跳跃轨迹

可显示前跳轨迹，用于判断跳入、穿身和对空距离。

## Expert Mode

Expert Mode 会用每个招式的具体范围替代简单分区。每个招式都会在距离线上显示标记，让你看到当前距离有哪些招式能碰到对手。

### 开启方式

1. 打开 REFramework 菜单。
2. 找到 **Distance Viewer**。
3. 打开 **Expert Mode**。
4. 工具会读取 `data/SF6_DistanceViewer_data/SF6Distance_Data_Attacks.json` 中的攻击范围数据。

### 显示内容

- **水平距离线**：从角色延伸到对手，按招式范围分段。
- **垂直标记线**：在每个招式范围边界画线。
- **当前距离游标**：标记当前双方距离。
- **对手区域标签**：显示当前距离可命中的招式输入，并随移动实时更新。

## 区域配置

你可以把特定招式设为参考点：

- **Red Zone**：通常设为近距离惩罚或关键按钮。
- **Orange Zone**：通常设为更远的牵制按钮。
- **Yellow Offset**：控制橙色区域外黄色区域的宽度。

每个区域旁的 **TELEPORT** 可以把双方放到该招式最大距离，方便练习最远点确认。

## 单招显示偏好

Expert Mode 中每个角色都有招式列表。你可以：

- 单独开关某个招式是否显示。
- 使用 **Max Only** 只显示每种防御类型下最远的招式。

## 常用显示选项

| 选项 | 说明 |
| --- | --- |
| Show Markers | 显示垂直范围线。 |
| Show Vertical Cursor | 显示当前距离游标。 |
| Show Horizontal Lines | 显示水平距离条。 |
| Show Numbers | 显示距离数值。 |
| Show Opp Zone | 显示对手头上的区域标签。 |
| Crossup Show | 显示穿身跳距离。 |
| Show Jump Arc | 显示前跳轨迹。 |
| Fill Background | 在范围之间填充颜色背景。 |
| Color Text | 文本颜色跟随区域颜色。 |

## Auto Active

Auto Active 可以在对手进入指定范围时自动执行动作：

1. 在 **Auto Active** 区域勾选 **Enable**。
2. 从下拉框选择动作，包括当前角色招式和 **FORWARD JUMP**。
3. 设置延迟帧数：`0` 为立即执行，`60` 约等于 1 秒。
4. 对手进入范围后，木人会自动执行该动作。

`FORWARD JUMP` 特别适合练习对空：木人会在合适距离自动跳入。

## 注意事项

- 攻击范围数据保存在 `data/SF6_DistanceViewer_data/SF6Distance_Data_Attacks.json`。
- 有架势/派生状态的角色可能有多个招式集合。
- 这是被动/辅助工具，不属于顶部互斥训练模式。

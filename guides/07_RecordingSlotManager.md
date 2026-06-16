# 07 Recording Slot Manager 录制槽管理器

Recording Slot Manager 用于管理训练模式中的 8 个假人录制槽，支持导入、导出、启用、停用和随机权重配置。

## 录制槽是什么？

SF6 训练模式允许为假人录制最多 8 段动作序列。Hit Confirm、Reaction Drills、Post Guard 等训练脚本都会依赖这些录制内容。

这个管理器的作用是把录制槽保存成文件，或从文件恢复到游戏中，方便你按角色、场景和训练主题管理假人动作。

## 前置条件

- 进入 **Training Mode**

## 导入录制槽

1. 打开 REFramework 菜单，默认快捷键是 `Insert`
2. 找到 **Recording Slot Manager**
3. 在 **SOLO OPERATIONS** 中选择一个 `.json` 文件
4. 下拉列表会按当前角色过滤文件
5. 点击 **IMPORT**，文件内容会写入游戏录制槽
6. 如果勾选 **Activate On Load**，导入后会自动启用这些槽位

## 导出录制槽

1. 点击 **EXPORT**，把当前槽位保存到当前角色的默认文件
2. 或点击 **SAVE AS**，手动指定文件名
3. 文件保存到 `data/SF6_RecordingSlotManager_data/[Character].json`
4. **EXPORT ALL CHARS** 需要按住按钮 1 秒，会一次性导出所有角色数据

## 实时槽位表

表格会显示全部 8 个槽位：

| 列 | 说明 |
| --- | --- |
| ID | 槽位编号，范围 1-8 |
| Active | 是否启用该槽位参与播放 |
| Weight | 随机选择权重，数值越高出现越频繁 |
| Frames | 录制动作的总帧数 |
| Import | 把 Replay Input Logger 的记录导入到指定槽位 |

常用按钮：

- **ACTIVATE ALL**：启用全部槽位
- **DEACTIVATE ALL**：停用全部槽位
- **Refresh All**：从游戏内重新读取槽位数据

## Replay Input Logger

Replay Input Logger 可以在录像回放中记录输入，之后导入到训练槽中复现。

使用流程：

1. 展开 **REPLAY INPUT LOGGER**
2. 选择记录目标：**P1**、**P2** 或 **Dual**
3. 播放录像时，工具会捕获输入序列
4. 记录文件保存到 `data/TrainingComboTrials_data/ReplayRecords/`
5. 在槽位表的下拉框中选择记录文件并导入

## 数据格式

录制槽使用 timeline 格式：

```json
{"timeline": ["10f : 5", "3f : 2+LP", "1f : 236+HP"]}
```

每一项格式为：

```text
[frame_count]f : [direction]+[buttons]
```

含义：

- `frame_count`：该输入持续多少帧
- `direction`：方向输入，例如 `5`、`2`、`236`
- `buttons`：按键输入，例如 `LP`、`HP`、`2+LP`

## 注意事项

- 管理器会自动处理录制槽内存分配；如果槽位内存不足，会排队执行分配步骤
- Dirty 状态会提示你当前录制槽有未保存改动
- 文件会按角色名过滤，避免误导入其他角色数据
- Weight 会影响随机播放概率，对 Reaction Drills 特别有用

# 06 Reaction Drills 反应训练

反应训练用于练习对随机假人录制动作的即时应对。假人会从录制槽中随机播放动作，你需要在合适窗口内打断、惩罚或做出正确防守。

## 前置条件

- 进入 **Training Mode**
- 在 Script Manager 中切换到模式 **2 (Reaction Drills)**，见 [02_Training_ScriptManager.md](02_Training_ScriptManager.md)
- 在假人录制槽中录入多个动作，动作越丰富，训练价值越高
- 录制槽管理见 [07_RecordingSlotManager.md](07_RecordingSlotManager.md)

## 工作方式

1. 脚本从已启用的假人录制槽中随机选择一个动作
2. 假人播放该动作
3. 玩家需要及时反应，打断或惩罚该动作
4. 脚本按录制槽统计成功率

## 设置流程

1. 在 1-8 号槽录入不同动作，例如牵制、必杀技、Drive Impact、投技等
2. 启用需要练习的录制槽，或使用 **Activate All**
3. 脚本会自动把假人防御设置为 **No Guard**
4. 使用下方控制项开始训练

## 控制方式

| 动作 | 键盘 | 手柄 |
| --- | --- | --- |
| Timer - / Trials - | [1] | FUNC + DOWN |
| Timer + / Trials + | [2] | FUNC + UP |
| Reset / Stop | [3] | FUNC + LEFT |
| Start / Pause | [4] | FUNC + RIGHT |

## 菜单选项

- **Auto-activate**：开始训练时强制启用所有有内容的录制槽
- **Manual mode**：每次动作需要手动播放，不自动循环
- **Show Slot Percentages**：在覆盖层显示每个槽位的成功率，例如 `S1:95% S2:87%`

## 计分规则

- **Success**：你在动作完成前打中了假人，成功打断
- **Fail**：假人动作命中你、你被迫防御，或你挥空未能处理动作

## D2D 覆盖层

反应训练的 D2D HUD 会显示：

- 每个槽位的成功率
- 总体成功率
- 当前计时或剩余次数
- 每次尝试的颜色反馈

## 训练模式

- **TRIALS**：固定次数训练
- **TIMER**：固定时长训练
- 统计结果会导出到 `data/Stats/TrainingReactions_SessionStats.txt`

## 建议

- 同时录入快动作和慢动作，用来训练不同反应窗口
- 在 Recording Slot Manager 中调整槽位权重，让重点动作更常出现
- 自动循环会等待假人动作结束后再进入下一次
- 分槽位统计能帮助你定位最容易失败的具体情景

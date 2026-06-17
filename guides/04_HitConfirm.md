# 04 Hit Confirm 确认训练

Hit Confirm 用于练习命中确认：木人会随机防御或被击中，你需要在命中时继续连段，在被防时停止进攻。

## 什么是命中确认？

命中确认是指根据攻击是否命中来决定后续行动。命中时继续连段拿伤害；被防时停止或转入安全选择。这是实战中非常重要的基础能力。

## 前置条件

- 进入 **Training Mode**。
- 将 Script Manager 切到 **确认训练**。
- 使用游戏训练模式自带的录制槽准备一个攻击序列。

## 工作方式

1. 你攻击木人。
2. 木人随机防御或被击中。
3. **命中时**：继续连段。
4. **被防时**：停止进攻。
5. 脚本判断反应并显示成功或失败。

## 设置

1. 激活确认训练后，木人防御会自动设为随机。
2. 录制你的攻击序列。
3. 用下方快捷键开始 session。

## 控制

| 动作 | 键盘 | 手柄 |
| --- | --- | --- |
| 时间/次数 - | [1] | FUNC + DOWN |
| 时间/次数 + | [2] | FUNC + UP |
| 重置（空闲）/ 停止（运行中） | [3] | FUNC + LEFT |
| 开始（空闲）/ 暂停（运行中） | [4] | FUNC + RIGHT |

## 结果提示

| 提示 | 含义 |
| --- | --- |
| HIT CONFIRM SUCCESS | 命中后正确继续连段。 |
| BLOCK CONFIRMED | 被防后正确停止。 |
| FAIL: HIT NOT CONFIRMED | 命中了，但没有完成确认。 |
| FAIL: GAP IN COMBO AFTER HIT CONFIRMED | 确认后连段中断。 |
| FAIL: ON BLOCK MISCONFIRM | 木人防住了，但你继续进攻。 |
| FAIL: GAP DETECTED AFTER DRC | 被防 DRC 后出现空隙。 |
| FAIL: HEAVY DR CANCEL | 被防时使用了不安全的重攻击 DRC。 |
| FAIL: SUBOPTIMAL (NEED HEAVY) | 命中 DRC 后没有接正确重攻击。 |
| SUCCESS: OPTIMAL DRC HIT CONFIRM | 命中 DRC 后接了正确重攻击。 |

## Session 模式

- **TRIALS**：固定次数练习。
- **TIMER**：固定时间练习。
- 结束后统计导出到 `data/Stats/HitConfirm_SessionStats.txt`。

## 提示

- 多段攻击会被脚本特殊处理，避免重复误判。
- DRC 确认会单独判断，并区分最优/非最优选择。
- 轻攻击通常只需要 Combo 计数验证；中/重攻击更依赖后续动作验证。

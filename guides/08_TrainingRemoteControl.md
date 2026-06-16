# 08 Training Remote Control 远程控制

Training Remote Control 可以用手机浏览器控制训练工具，不需要安装手机 App。它通过电脑上的本地服务提供网页界面，让你在游戏过程中快速切换模式、调整设置和触发动作。

## 功能概览

远程控制的目标是减少手柄和 REFramework 菜单之间的来回切换。你可以在手机上点击按钮，直接控制游戏内训练插件。

典型用途：

- 切换训练模式
- 开始或停止 Combo Trials
- 切换 Trial 文件
- 调整 Distance Viewer
- 开关碰撞框、受击框、打击框显示
- 隐藏或显示游戏内训练 UI

## 启动方式

1. 进入 REFramework 目录下的 `SF6_TrainingRemoteControlServer/`
2. 启动 **SF6_TrainingRemoteControl.exe**
3. Windows 任务栏托盘会出现一个青色六边形图标
4. 右键托盘图标，查看显示的 URL
5. 用手机浏览器打开该 URL
6. 也可以点击 **Show QR Code**，用手机扫码打开

手机和电脑必须处在同一个局域网中，通常就是同一个 Wi-Fi。

## 托盘程序功能

| 选项 | 说明 |
| --- | --- |
| Start Server | 手动启动网页服务 |
| Stop Server | 手动停止网页服务 |
| Show QR Code | 显示二维码窗口，方便手机扫码 |
| Start with Windows | 控制是否随 Windows 启动 |

托盘程序还会自动管理生命周期：

- SF6 启动时自动启动服务
- SF6 关闭后约 5 秒自动停止服务
- 你仍然可以通过托盘菜单手动启动或停止服务

## 手机界面

网页界面会按训练工具分区。

### TRAINING MODE

用于切换训练模式：

- **Disabled**：关闭全部主动训练脚本
- **Hit Confirm**：确认训练，见 [04_HitConfirm.md](04_HitConfirm.md)
- **Reaction Drills**：反应训练，见 [06_ReactionDrills.md](06_ReactionDrills.md)
- **Post Guard**：防后训练，见 [05_PostGuard.md](05_PostGuard.md)
- **Combo Trials**：连段 Trial，见 [03_CustomComboTrials.md](03_CustomComboTrials.md)

选择后会立刻同步到 Script Manager。

### COMBO TRIALS

启用 Combo Trials 后，会出现额外控制项：

| 控制项 | 说明 |
| --- | --- |
| Record | 开始录制连段 |
| Start Trial | 开始当前 Trial |
| Stop | 停止当前 Trial |
| Reset | 重置 Trial 进度 |
| Demo | 播放录制连段演示 |
| Position | 在 ANY、EXACT、MIRROR 之间切换站位要求 |
| File Selector | 选择 Trial JSON 文件 |

### DISTANCE VIEWER

用于从手机配置距离显示：

- 距离区域和阈值
- 哪些招式显示在覆盖层中
- 是否进入训练模式后自动启用

### SHELDON BOXES

用于控制 Sheldon's Boxes 的显示项，包括：

- Hitbox
- Hurtbox
- Collision box

### UI Toggle

**VISIBLE / HIDDEN** 用于显示或隐藏整个游戏内训练 UI。录制视频或截图时，可以用它获得干净画面。

## 工作原理

服务默认运行在 **4850** 端口。手机网页和游戏之间通过本地桥接数据同步：

```text
data/SF6_TrainingRemoteControl_data/
```

手机上改变设置后，游戏内会立即读取并响应；游戏内状态变化也会同步回手机界面。

## 注意事项

- 服务只面向局域网使用
- 可以同时连接多个设备
- 如果二维码无法扫描，可以手动输入托盘菜单中的 URL
- URL 通常是电脑局域网 IP 加 `:4850`
- 托盘程序常驻后台，占用资源很低

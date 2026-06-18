# TrialHub MVP 技术验证报告

## 结论

File System Access API 足以验证 WTT-CN 网页管理器的核心安装器能力：用户授权选择 `Street Fighter 6/` 后，网页可以读取目录、检测文件、创建子目录、写入 Trial JSON，并删除已安装 Trial JSON。

该方案不需要 Electron、Tauri、Python 或 Node 服务端逻辑。前端可以由 `index.html`、`style.css`、`app.js` 组成，服务器只需要提供静态 `manifest.json` 和 Trial JSON 文件。

## 问题回答

1. 是否能读取 SF6 根目录？

   能。用户点击“选择 Street Fighter 6 根目录”后，Chrome / Edge 会弹出目录选择器。网页获得用户授权的目录句柄后，可以检测 `StreetFighter6.exe`、`reframework/` 和 `reframework/autorun/Training_ScriptManager.lua`。

2. 是否能创建目录？

   能。使用 `DirectoryHandle.getDirectoryHandle(name, { create: true })` 可以创建 `reframework/data/TrainingComboTrials_data/CustomCombos/<角色名>/`。

3. 是否能写入 Trial JSON？

   能。使用 `FileHandle.createWritable()` 可以把服务器 Trial JSON 写入角色目录。本 MVP 安装时会先 `fetch()` Trial JSON，再写入本地文件。

4. 是否能删除 Trial JSON？

   能。使用 `DirectoryHandle.removeEntry(fileName)` 可以删除同名本地 JSON。本 MVP 删除后会重新扫描本地目录。

5. 是否需要 HTTPS？

   正式部署需要 HTTPS。File System Access API 只能在安全上下文中使用，生产环境应部署到 HTTPS。`localhost` 通常也被浏览器视为安全上下文，适合本地开发验证。

6. 是否需要用户每次重新授权？

   用户必须主动选择目录并授权。页面刷新后，如果不保存目录句柄，通常需要重新选择目录。可以把目录句柄保存到 IndexedDB，并在下次打开时用 `queryPermission()` / `requestPermission()` 恢复权限，但浏览器仍可能要求用户重新确认。

7. Chrome 和 Edge 是否兼容？

   兼容。Chrome 和 Microsoft Edge 最新版都基于 Chromium，支持 File System Access API 的目录选择、读写文件和删除文件能力。

8. 是否存在浏览器限制？

   存在。主要限制包括：

   - 需要安全上下文，正式环境必须 HTTPS。
   - 需要用户手动授权目录，网页不能静默访问任意磁盘路径。
   - Firefox 和 Safari 不完整支持该 API，不适合作为本 MVP 的目标浏览器。
   - 浏览器不会暴露真实绝对路径，本 MVP 只能显示相对路径。
   - 权限可能随浏览器策略、用户设置、隐私模式或站点数据清理而失效。
   - `fetch("manifest.json")` 和 Trial JSON 需要由同源静态服务提供，直接用某些 `file://` 打开时可能无法正常加载。

## MVP 文件

- `index.html`：单页面结构。
- `style.css`：页面样式。
- `app.js`：File System Access API 检测、扫描、安装、删除逻辑。
- `manifest.json`：静态服务器 Manifest。
- `trials/*.json`：静态 Trial JSON 示例。

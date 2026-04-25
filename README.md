# Claude Code Windows Toast 通知配置

为 Claude Code 添加 Windows Toast 通知功能，当任务完成或需要权限确认时弹出通知。

## 功能

- **Stop 事件**：任务完成时，从 transcript 中提取 AI 最后一条回复显示在通知中
- **Notification 事件**：需要用户关注或批准时弹出通知
- 支持自定义图标
- 三层降级机制：BurntToast → WinRT Toast → BalloonTip

## 效果预览

通知示例（带自定义图标）：

```
┌─────────────────────────────┐
│ [🦀 图标] ClaudeCode        │
│        Task completed...    │
└─────────────────────────────┘
```

## 快速安装

### 方式一：运行安装脚本（推荐）

```powershell
# 在 PowerShell 中运行（不需要管理员权限）
irm https://raw.githubusercontent.com/Yuntun1020/claude-code-windows-notify/main/install.ps1 | iex
```

### 方式二：手动安装

1. 安装 BurntToast 模块：

```powershell
Install-Module -Name BurntToast -Force -Scope CurrentUser
```

2. 创建 hooks 目录：

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\hooks"
```

3. 下载以下文件到 `~/.claude/hooks/` 目录：
   - `notify.ps1`
   - `icon.png`

4. 将 `settings.json` 中的 hooks 配置合并到 `~/.claude/settings.json` 中

5. 重启 Claude Code

## 更换图标

将 `~/.claude/hooks/icon.png` 替换为你的图标（推荐尺寸：宽高比 1.6:1，高度 48-96 像素），重启 Claude Code 后生效。

## 自定义配置

### 修改通知标题

编辑 `notify.ps1`，找到 `$toastTitle` 变量：

```powershell
$toastTitle = "ClaudeCode"  # 修改为你的标题
```

### 修改图标路径

编辑 `notify.ps1`，找到 `$toastIcon` 变量：

```powershell
$toastIcon = Join-Path $scriptDir "icon.png"  # 修改为你的图标路径
```

## 卸载

1. 从 `~/.claude/settings.json` 中删除 hooks 配置
2. 删除 `~/.claude/hooks/` 目录中的 `notify.ps1` 和 `icon.png`

## 常见问题

### 通知没有弹出？

1. 检查 BurntToast 模块是否安装成功：
   ```powershell
   Import-Module BurntToast
   New-BurntToastNotification -Text "测试", "通知测试"
   ```

2. 检查 PowerShell 执行策略：
   ```powershell
   Get-ExecutionPolicy -Scope CurrentUser
   ```
   如果不是 `RemoteSigned` 或 `Bypass`，运行：
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
   ```

3. 重启 Claude Code

### 图标显示不完整？

图标尺寸过大，Windows Toast 通知区域有限。建议使用宽高比 1.6:1、高度 48-96 像素的图标。

## 技术细节

- **通知模块**：BurntToast > WinRT > BalloonTip（三层降级）
- **图标支持**：PNG 格式
- **UTF-8 编码**：脚本强制设置 UTF-8 以支持中文内容
- **安全检查**：使用 `SecurityElement::Escape` 防止 XSS 注入

## License

MIT

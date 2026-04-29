# Claude Code tong1zhi1 通知配置

为 Claude Code 添加 Windows Toast 通知功能，支持任务完成通知、权限请求提醒和 AI 回复摘要。

## 功能

- **Stop 事件**：对话结束时弹出通知，自动读取 transcript 提取 AI 最后一条回复（最多 150 字符）
- **PermissionRequest 事件**：需要权限确认时弹出通知，显示工具名称和命令内容
- **Notification 事件**：需要用户关注时弹出提醒
- 支持自定义图标（.png / .ico）
- 三层降级机制：BurntToast → WinRT Toast → BalloonTip

## 效果预览

通知示例（带自定义图标）

## 快速安装

### 方式一：运行安装脚本（推荐）

```powershell
irm https://raw.githubusercontent.com/Yuntun1020/claude-code-tong1zhi1/main/install.ps1 | iex
```

### 方式二：手动安装

1. 安装 BurntToast 模块：

```powershell
Install-Module -Name BurntToast -Force -Scope CurrentUser
```

2. 创建 tong1zhi1 目录：

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\tong1zhi1"
```

3. 下载以下文件到 `~/.claude/tong1zhi1/` 目录：
   - `ClaudeCodeHooks.ps1` 或 `notify.ps1`（二选一，推荐 ClaudeCodeHooks.ps1）
   - `claude_code.png`
   - `claude_code.ico`
   - `settings.json`

4. 将 `settings.json` 中的 hooks 配置合并到 `~/.claude/settings.json` 中

5. 重启 Claude Code

## 两个脚本的区别

| 脚本 | 特点 |
|------|------|
| `ClaudeCodeHooks.ps1` | 简洁版，支持 Stop + PermissionRequest，三层降级 |
| `notify.ps1` | 完整版，支持 Stop + PermissionRequest + Notification，三层降级，内容更丰富 |

## 更换图标

将 `~/.claude/tong1zhi1/claude_code.png` 和 `claude_code.ico` 替换为你的图标，重启 Claude Code 后生效。推荐 PNG 尺寸：宽高比 1.6:1，高度 48-96 像素。

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

- **通知模块**：BurntToast > WinRT Toast > BalloonTip（三层降级）
- **图标支持**：PNG（BurningToast/WinRT）和 ICO（BalloonTip）格式
- **Hook 事件**：PermissionRequest、Stop、Notification
- **内容提取**：Stop 事件自动从 transcript 读取 AI 最后一条回复
- **安全检查**：使用 `SecurityElement::Escape` 防止 XML 注入

## License

MIT

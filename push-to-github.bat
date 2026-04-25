@echo off
chcp 65001 >nul
echo ======================================
echo Claude Code Windows Toast - GitHub 上传脚本
echo ======================================
echo.
echo 请确保已在 GitHub 创建仓库: Yuntun1020/claude-code-windows-notify
echo.
echo 1. 在浏览器打开: https://github.com/new
echo 2. Repository name 填入: claude-code-windows-notify
echo 3. 选择 Private (私有) 或 Public (公开)
echo 4. 不要勾选任何初始化选项
echo 5. 点击 Create repository
echo.
echo 创建完成后，按任意键继续...
pause >nul
echo.

echo 正在推送到 GitHub...
cd /d "%~dp0"
git remote set-url origin https://github.com/Yuntun1020/claude-code-windows-notify.git
git push -u origin main

echo.
echo ======================================
echo 完成！请重启 Claude Code 使配置生效。
echo ======================================
pause

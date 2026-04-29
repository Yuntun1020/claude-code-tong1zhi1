@echo off
chcp 65001 >nul
echo ======================================
echo Claude Code tong1zhi1 - GitHub 上传脚本
echo ======================================
echo.
echo 正在推送到 GitHub...
cd /d "%~dp0"
git remote set-url origin https://github.com/Yuntun1020/claude-code-tong1zhi1.git
git add .
git commit -m "Update tong1zhi1 notification configuration"
git push -u origin main

echo.
echo ======================================
echo 完成！请重启 Claude Code 使配置生效。
echo ======================================
pause

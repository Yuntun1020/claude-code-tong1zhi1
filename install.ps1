# Claude Code Windows Toast 通知 - 一键安装脚本
# 运行方式: irm https://raw.githubusercontent.com/Yuntun1020/claude-code-windows-notify/main/install.ps1 | iex

param(
    [switch]$SkipModuleCheck
)

$ErrorActionPreference = "Stop"

Write-Host "Claude Code Windows Toast 通知安装器" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# 1. 检查 BurntToast 模块
if (-not $SkipModuleCheck) {
    Write-Host "[1/5] 检查 BurntToast 模块..." -ForegroundColor Yellow

    try {
        Import-Module BurntToast -ErrorAction Stop
        Write-Host "  ✓ BurntToast 已安装" -ForegroundColor Green
    }
    catch {
        Write-Host "  BurntToast 未安装，正在安装..." -ForegroundColor Yellow
        Install-Module -Name BurntToast -Force -Scope CurrentUser -AllowClobber
        Write-Host "  ✓ BurntToast 安装完成" -ForegroundColor Green
    }
}

# 2. 检查执行策略
Write-Host "[2/5] 检查执行策略..." -ForegroundColor Yellow
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -eq "Restricted" -or $policy -eq "Undefined") {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    Write-Host "  ✓ 执行策略已设置为 RemoteSigned" -ForegroundColor Green
} else {
    Write-Host "  ✓ 执行策略正常 ($policy)" -ForegroundColor Green
}

# 3. 创建 hooks 目录
Write-Host "[3/5] 创建 hooks 目录..." -ForegroundColor Yellow
$hooksDir = "$env:USERPROFILE\.claude\hooks"
if (-not (Test-Path $hooksDir)) {
    New-Item -ItemType Directory -Force -Path $hooksDir | Out-Null
}
Write-Host "  ✓ 目录: $hooksDir" -ForegroundColor Green

# 4. 下载文件
Write-Host "[4/5] 下载必要文件..." -ForegroundColor Yellow
$baseUrl = "https://raw.githubusercontent.com/Yuntun1020/claude-code-windows-notify/main"

$files = @{
    "notify.ps1" = "$baseUrl/notify.ps1"
    "icon.png"   = "$baseUrl/icon.png"
}

foreach ($file in $files.GetEnumerator()) {
    $localPath = Join-Path $hooksDir $file.Key
    Write-Host "  下载 $($file.Key)..." -NoNewline
    try {
        Invoke-WebRequest -Uri $file.Value -OutFile $localPath -UseBasicParsing
        Write-Host " ✓" -ForegroundColor Green
    }
    catch {
        Write-Host " ✗" -ForegroundColor Red
        Write-Host "    失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 5. 更新 settings.json
Write-Host "[5/5] 更新 settings.json..." -ForegroundColor Yellow
$settingsPath = "$env:USERPROFILE\.claude\settings.json"

$hooksConfig = @{
    hooks = @{
        Notification = @(
            @{
                matcher = ""
                hooks = @(
                    @{
                        type = "command"
                        command = "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command \"& \\$env:USERPROFILE\\.claude\\hooks\\notify.ps1 -Event Notification\""
                        timeout = 15
                    }
                )
            }
        )
        Stop = @(
            @{
                matcher = ""
                hooks = @(
                    @{
                        type = "command"
                        command = "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command \"& \\$env:USERPROFILE\\.claude\\hooks\\notify.ps1 -Event Stop\""
                        timeout = 15
                    }
                )
            }
        )
    }
}

if (Test-Path $settingsPath) {
    try {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        $settings | Add-Member -Name "hooks" -Value $hooksConfig.hooks -MemberType NoteProperty -Force
        $settings | ConvertTo-Json -Depth 20 | Set-Content $settingsPath -Encoding UTF8
        Write-Host "  ✓ settings.json 已更新" -ForegroundColor Green
    }
    catch {
        Write-Host "  ✗ 更新 settings.json 失败" -ForegroundColor Red
        Write-Host "    请手动将 hooks 配置添加到 settings.json" -ForegroundColor Yellow
    }
} else {
    Write-Host "  settings.json 不存在，跳过" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "安装完成！" -ForegroundColor Green
Write-Host ""
Write-Host "请重启 Claude Code 使配置生效。" -ForegroundColor Cyan
Write-Host ""
Write-Host "测试通知：" -ForegroundColor Yellow
Write-Host '  Import-Module BurntToast; New-BurntToastNotification -Text "测试", "如果看到这个通知，说明安装成功！"' -ForegroundColor Gray
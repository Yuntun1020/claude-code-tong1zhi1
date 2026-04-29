# Claude Code tong1zhi1 通知 - 一键安装脚本
# 运行方式: irm https://raw.githubusercontent.com/Yuntun1020/claude-code-tong1zhi1/main/install.ps1 | iex

param(
    [switch]$SkipModuleCheck
)

$ErrorActionPreference = "Stop"

Write-Host "Claude Code tong1zhi1 通知安装器" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# 1. 检查 BurntToast 模块
if (-not $SkipModuleCheck) {
    Write-Host "[1/5] 检查 BurntToast 模块..." -ForegroundColor Yellow

    try {
        Import-Module BurntToast -ErrorAction Stop
        Write-Host "  [OK] BurntToast 已安装" -ForegroundColor Green
    }
    catch {
        Write-Host "  BurntToast 未安装，正在安装..." -ForegroundColor Yellow
        Install-Module -Name BurntToast -Force -Scope CurrentUser -AllowClobber
        Write-Host "  [OK] BurntToast 安装完成" -ForegroundColor Green
    }
}

# 2. 检查执行策略
Write-Host "[2/5] 检查执行策略..." -ForegroundColor Yellow
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -eq "Restricted" -or $policy -eq "Undefined") {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    Write-Host "  [OK] 执行策略已设置为 RemoteSigned" -ForegroundColor Green
} else {
    Write-Host "  [OK] 执行策略正常 ($policy)" -ForegroundColor Green
}

# 3. 创建 tong1zhi1 目录
Write-Host "[3/5] 创建 tong1zhi1 目录..." -ForegroundColor Yellow
$tongDir = "$env:USERPROFILE\.claude\tong1zhi1"
if (-not (Test-Path $tongDir)) {
    New-Item -ItemType Directory -Force -Path $tongDir | Out-Null
}
Write-Host "  [OK] 目录: $tongDir" -ForegroundColor Green

# 4. 下载文件
Write-Host "[4/5] 下载必要文件..." -ForegroundColor Yellow
$baseUrl = "https://raw.githubusercontent.com/Yuntun1020/claude-code-tong1zhi1/main"

$files = @{
    "ClaudeCodeHooks.ps1" = "$baseUrl/ClaudeCodeHooks.ps1"
    "claude_code.png"     = "$baseUrl/claude_code.png"
    "claude_code.ico"     = "$baseUrl/claude_code.ico"
    "settings.json"        = "$baseUrl/settings.json"
}

foreach ($file in $files.GetEnumerator()) {
    $localPath = Join-Path $tongDir $file.Key
    Write-Host "  下载 $($file.Key)..." -NoNewline
    try {
        Invoke-WebRequest -Uri $file.Value -OutFile $localPath -UseBasicParsing
        Write-Host " [OK]" -ForegroundColor Green
    }
    catch {
        Write-Host " [FAIL]" -ForegroundColor Red
        Write-Host "    失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 5. 合并 settings.json 到用户配置
Write-Host "[5/5] 更新 ~/.claude/settings.json..." -ForegroundColor Yellow
$userSettingsPath = "$env:USERPROFILE\.claude\settings.json"
$repoSettingsPath = Join-Path $tongDir "settings.json"

if (Test-Path $repoSettingsPath) {
    try {
        $repoHooks = (Get-Content $repoSettingsPath -Raw | ConvertFrom-Json).hooks
        $hooksAdded = 0

        if (Test-Path $userSettingsPath) {
            $userSettings = Get-Content $userSettingsPath -Raw | ConvertFrom-Json
            foreach ($event in @("PermissionRequest", "Stop")) {
                if (-not $userSettings.hooks -or -not $userSettings.hooks.$event) {
                    if ($repoHooks.$event) {
                        if (-not $userSettings.hooks) {
                            $userSettings | Add-Member -Name "hooks" -Value ([ordered]@{}) -MemberType NoteProperty
                        }
                        $userSettings.hooks | Add-Member -Name $event -Value $repoHooks.$event -MemberType NoteProperty
                        $hooksAdded++
                    }
                }
            }
            $userSettings | ConvertTo-Json -Depth 20 | Set-Content $userSettingsPath -Encoding UTF8
        } else {
            Copy-Item $repoSettingsPath $userSettingsPath -Force
            $hooksAdded = 2
        }

        Write-Host "  [OK] 已添加 $($hooksAdded) 个 hooks 到 settings.json" -ForegroundColor Green
    }
    catch {
        Write-Host "  [FAIL] 更新 settings.json 失败" -ForegroundColor Red
        Write-Host "    请手动将 hooks 配置添加到 settings.json" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [SKIP] settings.json 下载失败，跳过" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "安装完成！" -ForegroundColor Green
Write-Host ""
Write-Host "请重启 Claude Code 使配置生效。" -ForegroundColor Cyan
Write-Host ""
Write-Host "测试通知：" -ForegroundColor Yellow
Write-Host '  Import-Module BurntToast; New-BurntToastNotification -Text "测试", "通知测试"' -ForegroundColor Gray

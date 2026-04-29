param(
    [string]$Event = "Stop"
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$toastIcon = Join-Path $scriptDir "claude_code.png"
$toastTitle = "Claude Code"
$toastIco = Join-Path $scriptDir "claude_code.ico"

if (-not (Test-Path $toastIcon)) { $toastIcon = $null }
if (-not (Test-Path $toastIco)) { $toastIco = $null }

$inputLines = @()
while ($null -ne ($line = [Console]::In.ReadLine())) { $inputLines += $line }
$rawJson = $inputLines -join "`n"

$data = $null
if ($rawJson.Trim() -ne "") {
    try { $data = $rawJson | ConvertFrom-Json } catch {}
}

$title = $toastTitle
$body = ""

if ($Event -eq "Stop") {
    $projectName = ""
    if ($data -and $data.cwd) { $projectName = Split-Path $data.cwd -Leaf }
    if ($projectName -ne "") { $title = "$toastTitle - $projectName" }

    if ($data -and $data.transcript_path -and $data.transcript_path -ne "" -and (Test-Path $data.transcript_path)) {
        try {
            $lines = Get-Content $data.transcript_path -Tail 30 -Encoding UTF8
            for ($i = $lines.Count - 1; $i -ge 0; $i--) {
                $entry = $null
                try { $entry = $lines[$i] | ConvertFrom-Json } catch { continue }
                if ($entry -and $entry.message -and $entry.message.role -eq "assistant") {
                    $content = $entry.message.content
                    if ($content -is [string]) { $body = $content }
                    elseif ($content -is [array]) {
                        $textBlock = $content | Where-Object { $_.type -eq "text" } | Select-Object -First 1
                        if ($textBlock) { $body = $textBlock.text }
                    }
                    if ($body.Trim() -ne "") { break }
                }
            }
        } catch {}
    }
    if ($body.Trim() -eq "") { $body = "任务完成，请查看结果。" }
    if ($body.Length -gt 150) { $body = $body.Substring(0, 147) + "..." }

} elseif ($Event -eq "PermissionRequest") {
    $title = "$toastTitle - 权限请求"
    if ($data -and $data.arguments) {
        $args = $data.arguments
        if ($args.tool -and $args.tool -ne "") { $body = "工具: $($args.tool)" }
        if ($args.command -and $args.command -ne "") {
            $cmd = $args.command
            if ($cmd.Length -gt 100) { $cmd = $cmd.Substring(0, 97) + "..." }
            if ($body -ne "") { $body = "$body`n$cmd" } else { $body = $cmd }
        }
    }
    if ($body.Trim() -eq "") { $body = "Claude 请求权限确认，请检查操作。" }

} elseif ($Event -eq "Notification") {
    $title = "$toastTitle - 需要关注"
    if ($data -and $data.message -and $data.message.Trim() -ne "") {
        $body = $data.message
        if ($body.Length -gt 150) { $body = $body.Substring(0, 147) + "..." }
    } else {
        $body = "Claude 正在等待你的输入或批准。"
    }
} else {
    $title = $toastTitle
    $body = "事件: $Event"
}

function Send-ToastViaBurntToast {
    param($t, $b)
    Import-Module BurntToast -ErrorAction Stop
    if ($toastIcon) {
        New-BurntToastNotification -AppLogo $toastIcon -Text $t, $b -Sound Default
    } else {
        New-BurntToastNotification -Text $t, $b -Sound Default
    }
}

function Send-ToastViaBalloon {
    param($t, $b)
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $notify = New-Object System.Windows.Forms.NotifyIcon
    if ($toastIco) {
        $notify.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($toastIco)
    } else {
        $notify.Icon = [System.Drawing.SystemIcons]::Information
    }
    $notify.Visible = $true
    $notify.ShowBalloonTip(15000, $t, $b, [System.Windows.Forms.ToolTipIcon]::Info)
    Start-Sleep -Seconds 16
    $notify.Dispose()
}

try {
    Send-ToastViaBurntToast $title $body
} catch {
    try {
        Send-ToastViaBalloon $title $body
    } catch {}
}

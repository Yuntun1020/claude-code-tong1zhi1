param(
    [string]$State = 'Stop'
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pngPath = Join-Path $scriptDir "claude_code.png"
$icoPath = Join-Path $scriptDir "claude_code.ico"
$title = "Claude Code"
$body = ""

# Read stdin JSON
$inputLines = @()
while ($null -ne ($line = [Console]::In.ReadLine())) {
    $inputLines += $line
}
$rawJson = $inputLines -join "`n"

$data = $null
if ($rawJson.Trim() -ne "") {
    try { $data = $rawJson | ConvertFrom-Json } catch {}
}

if ($State -eq "Stop") {

    # Try to extract AI's last reply from transcript
    if ($data -and $data.transcript_path -and $data.transcript_path -ne "" -and (Test-Path $data.transcript_path)) {
        try {
            $lines = Get-Content $data.transcript_path -Tail 30 -Encoding UTF8
            for ($i = $lines.Count - 1; $i -ge 0; $i--) {
                $entry = $null
                try { $entry = $lines[$i] | ConvertFrom-Json } catch { continue }
                if ($entry -and $entry.message -and $entry.message.role -eq "assistant") {
                    $content = $entry.message.content
                    if ($content -is [string]) {
                        $body = $content
                    }
                    elseif ($content -is [array]) {
                        $textBlock = $content | Where-Object { $_.type -eq "text" } | Select-Object -First 1
                        if ($textBlock) { $body = $textBlock.text }
                    }
                    if ($body.Trim() -ne "") { break }
                }
            }
        } catch {}
    }

    # If no transcript content, use project name or default
    if ($body.Trim() -eq "") {
        if ($data -and $data.cwd) {
            $projectName = Split-Path $data.cwd -Leaf
            if ($projectName -ne "") {
                $body = "任务完成: $projectName"
            }
        }
        if ($body.Trim() -eq "") {
            $body = "任务完成，请查看结果。"
        }
    }

    # Truncate
    if ($body.Length -gt 150) {
        $body = $body.Substring(0, 147) + "..."
    }

} elseif ($State -eq "PermissionRequest") {

    $body = "需要权限确认"

    if ($data -and $data.arguments) {
        $args = $data.arguments
        $details = @()
        if ($args.tool -and $args.tool -ne "") {
            $details += "工具: $($args.tool)"
        }
        if ($args.command -and $args.command -ne "") {
            $cmd = $args.command
            if ($cmd.Length -gt 80) { $cmd = $cmd.Substring(0, 77) + "..." }
            $details += $cmd
        }
        if ($details.Count -gt 0) {
            $body = $details -join "`n"
        }
    }

} else {
    $body = "事件: $State"
}

# ---- BurntToast ----
function Send-ToastViaBurntToast {
    param($t, $b)
    Import-Module BurntToast -ErrorAction Stop
    if ((Test-Path $pngPath)) {
        New-BurntToastNotification -Text $t, $b -AppLogo $pngPath -Sound Default
    } else {
        New-BurntToastNotification -Text $t, $b -Sound Default
    }
}

# ---- WinRT Fallback ----
function Send-ToastViaWinRT {
    param($t, $b)
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime] | Out-Null

    $appId = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"

    $safeTitle = [System.Security.SecurityElement]::Escape($t)
    $safeBody  = [System.Security.SecurityElement]::Escape($b)

    if (Test-Path $pngPath) {
        $iconUri = "file:///" + ($pngPath -replace "\\", "/")
        $xml = @"
<toast>
    <visual>
        <binding template='ToastGeneric'>
            <image placement='appLogoOverride' src='$iconUri'/>
            <text>$safeTitle</text>
            <text>$safeBody</text>
        </binding>
    </visual>
    <audio src='ms-winsoundevent:Notification.Default'/>
</toast>
"@
    } else {
        $xml = @"
<toast>
    <visual>
        <binding template='ToastGeneric'>
            <text>$safeTitle</text>
            <text>$safeBody</text>
        </binding>
    </visual>
    <audio src='ms-winsoundevent:Notification.Default'/>
</toast>
"@
    }

    $toastXml = [Windows.Data.Xml.Dom.XmlDocument]::new()
    $toastXml.LoadXml($xml)
    $toast = [Windows.UI.Notifications.ToastNotification]::new($toastXml)
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
}

# ---- BalloonTip Fallback ----
function Send-ToastViaBalloon {
    param($t, $b)
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $notify = New-Object System.Windows.Forms.NotifyIcon
    if (Test-Path $icoPath) {
        $notify.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($icoPath)
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
}
catch {
    try {
        Send-ToastViaWinRT $title $body
    }
    catch {
        try {
            Send-ToastViaBalloon $title $body
        }
        catch {}
    }
}

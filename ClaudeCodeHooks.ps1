param(
    [string]$State = 'Stop'
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pngPath = Join-Path $scriptDir 'claude_code.png'
$icoPath = Join-Path $scriptDir 'claude_code.ico'
$title = 'Claude Code'
$body = ''

$inputLines = @()
while ($null -ne ($line = [Console]::In.ReadLine())) {
    $inputLines += $line
}
$rawJson = $inputLines -join "`n"

$data = $null
if ($rawJson.Trim() -ne '') {
    try { $data = $rawJson | ConvertFrom-Json } catch {}
}

if ($State -eq 'Stop') {
    if ($data -and $data.cwd) {
        $projectName = Split-Path $data.cwd -Leaf
        if ($projectName) { $title = "$title - $projectName" }
    }
    if ($data -and $data.transcript_path -and (Test-Path $data.transcript_path)) {
        try {
            $lines = Get-Content $data.transcript_path -Tail 30 -Encoding UTF8
            for ($i = $lines.Count - 1; $i -ge 0; $i--) {
                try {
                    $entry = $lines[$i] | ConvertFrom-Json
                    if ($entry.message.role -eq 'assistant') {
                        $c = $entry.message.content
                        if ($c -is [string]) { $body = $c }
                        elseif ($c -is [array]) {
                            $tb = $c | Where-Object { $_.type -eq 'text' } | Select-Object -First 1
                            if ($tb) { $body = $tb.text }
                        }
                        if ($body.Trim() -ne '') { break }
                    }
                } catch { continue }
            }
        } catch {}
    }
    if ($body.Trim() -eq '') {
        if ($data.cwd) { $body = '任务完成: ' + (Split-Path $data.cwd -Leaf) }
        if ($body.Trim() -eq '') { $body = '任务完成，请查看结果。' }
    }
    if ($body.Length -gt 150) { $body = $body.Substring(0, 147) + '...' }
}
elseif ($State -eq 'PermissionRequest') {
    $title = "$title - 权限请求"
    $body = '需要权限确认'
    if ($data.arguments) {
        $a = $data.arguments
        $parts = @()
        if ($a.tool) { $parts += '工具: ' + $a.tool }
        if ($a.command) {
            $c = $a.command
            if ($c.Length -gt 80) { $c = $c.Substring(0, 77) + '...' }
            $parts += $c
        }
        if ($parts.Count -gt 0) { $body = $parts -join "`n" }
    }
    if ($body -eq '需要权限确认' -and -not $data.arguments) {
        $body = '需要权限确认，请检查操作。'
    }
}
elseif ($State -eq 'PreTool') {
    if ($data -and $data.cwd) {
        $projectName = Split-Path $data.cwd -Leaf
        if ($projectName) { $title = "$title - $projectName" }
    }
    if ($data.tool) {
        $body = '工具: ' + $data.tool
        if ($data.arguments) {
            $a = $data.arguments
            $details = @()
            if ($a.file_path) { $details += $a.file_path }
            elseif ($a.path) { $details += $a.path }
            if ($a.old_string -and $a.new_string) { $details += '[编辑]' }
            if ($a.text) {
                $t = $a.text
                if ($t.Length -gt 80) { $t = $t.Substring(0, 77) + '...' }
                $details += $t
            }
            if ($details.Count -gt 0) {
                $body += "`n" + ($details -join "`n")
            }
        }
    } else {
        $body = '¼件触发: PreTool'
    }
}
else {
    $body = '事件: ' + $State
}

function Send-ToastBurntToast {
    param($t, $b)
    Import-Module BurntToast -ErrorAction Stop
    if (Test-Path $pngPath) {
        New-BurntToastNotification -AppLogo $pngPath -Text $t, $b -Sound Default
    } else {
        New-BurntToastNotification -Text $t, $b -Sound Default
    }
}

function Send-ToastWinRT {
    param($t, $b)
    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType=WindowsRuntime] | Out-Null
        $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
        $safeTitle = [System.Security.SecurityElement]::Escape($t)
        $safeBody = [System.Security.SecurityElement]::Escape($b)
        if (Test-Path $pngPath) {
            $uri = 'file:///' + ($pngPath -replace '\\', '/')
            $xml = '<?xml version="1.0" encoding="UTF-8"?><toast><visual><binding template="ToastGeneric"><image placement="appLogoOverride" src="' + $uri + '"/><text>' + $safeTitle + '</text><text>' + $safeBody + '</text></binding></visual><audio src="ms-winsoundevent:Notification.Default"/></toast>'
        } else {
            $xml = '<?xml version="1.0" encoding="UTF-8"?><toast><visual><binding template="ToastGeneric"><text>' + $safeTitle + '</text><text>' + $safeBody + '</text></binding></visual><audio src="ms-winsoundevent:Notification.Default"/></toast>'
        }
        $xdoc = [Windows.Data.Xml.Dom.XmlDocument]::new()
        $xdoc.LoadXml($xml)
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xdoc)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
    } catch {}
}

function Send-ToastBalloon {
    param($t, $b)
    try {
        Add-Type -AssemblyName System.Windows.Forms, System.Drawing
        $n = New-Object System.Windows.Forms.NotifyIcon
        if (Test-Path $icoPath) { $n.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($icoPath) }
        else { $n.Icon = [System.Drawing.SystemIcons]::Information }
        $n.Visible = $true
        $n.ShowBalloonTip(15000, $t, $b, [System.Windows.Forms.ToolTipIcon]::Info)
        Start-Sleep -Seconds 16
        $n.Dispose()
    } catch {}
}

try { Send-ToastBurntToast $title $body }
catch {
    try { Send-ToastWinRT $title $body }
    catch { Send-ToastBalloon $title $body }
}

param(
    [string]$State = 'Stop'
)

$pngPath = 'C:\Users\yang\.claude\tong1zhi1\claude_code.png'
$icoPath = 'C:\Users\yang\.claude\tong1zhi1\claude_code.ico'
$title = 'Claude Code'
$msg = switch ($State) {
    'Stop' { '任务完成了' }
    'PermissionRequest' { '权限请求' }
    default { '通知' }
}

try {
    Import-Module BurntToast -ErrorAction Stop
    if (Test-Path $pngPath) {
        New-BurntToastNotification -Text $title, $msg -AppLogo $pngPath
    } else {
        New-BurntToastNotification -Text $title, $msg
    }
    exit 0
} catch {
    Add-Type -AssemblyName System.Windows.Forms
    $notify = New-Object System.Windows.Forms.NotifyIcon
    if (Test-Path $icoPath) {
        $notify.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($icoPath)
    } else {
        $notify.Icon = [System.Drawing.SystemIcons]::Information
    }
    $notify.Visible = $true
    $notify.ShowBalloonTip(15000, $title, $msg, 'Info')
    Start-Sleep -Seconds 16
    $notify.Dispose()
}

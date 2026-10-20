# ── NEON NOIR · notifica di fine comando ───────────────────────────────────
# Se un comando dura almeno $NeonConfig.NotifySeconds e la finestra del terminale non è in primo piano:
# notifica di Windows con esito, durata e directory + lampeggio della barra delle applicazioni.
# Esclusi: comandi interrotti con Ctrl+C e programmi interattivi ($NeonNotifyIgnore).

$NeonNotifyIgnore = 'claude', 'ssh', 'vim', 'nvim', 'less', 'lazygit', 'htop', 'btop', 'pwsh', 'powershell', 'cmd', 'bash', 'wsl', 'zi', 'rgf'
$global:NeonNotifyLastId = (Get-History -Count 1).Id

function Format-NeonDuration([TimeSpan]$t) {
    if ($t.TotalHours -ge 1) { '{0}h {1}m' -f [int][math]::Floor($t.TotalHours), $t.Minutes }
    elseif ($t.TotalMinutes -ge 1) { '{0}m {1}s' -f $t.Minutes, $t.Seconds }
    else { '{0}s' -f [int]$t.TotalSeconds }
}

# Il terminale è in primo piano? (ConPTY: la finestra console nascosta ha come proprietaria quella di Windows Terminal)
function Test-NeonTerminalFocused {
    if (-not ('Neon.Focus' -as [type])) {
        Add-Type -Namespace Neon -Name Focus -MemberDefinition @'
[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll")] public static extern IntPtr GetAncestor(IntPtr hwnd, uint flags);
'@
    }
    $con = [Neon.Focus]::GetConsoleWindow()
    if ($con -eq [IntPtr]::Zero) { return $false }
    $fg = [Neon.Focus]::GetForegroundWindow()
    $fg -eq $con -or $fg -eq [Neon.Focus]::GetAncestor($con, 3)   # 3 = GA_ROOTOWNER
}

# Toast nativo tramite Windows PowerShell 5.1 (ha le API WinRT), senza finestre né tab aggiuntive
function Send-NeonToast([string]$Title, [string]$Body) {
    $t = [Security.SecurityElement]::Escape($Title)
    $b = [Security.SecurityElement]::Escape($Body)
    $script = @"
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
`$x = New-Object Windows.Data.Xml.Dom.XmlDocument
`$x.LoadXml('<toast><visual><binding template="ToastGeneric"><text>$t</text><text>$b</text></binding></visual></toast>')
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe').Show([Windows.UI.Notifications.ToastNotification]::new(`$x))
"@
    $psi = [Diagnostics.ProcessStartInfo]::new("$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe")
    foreach ($a in '-NoProfile', '-NonInteractive', '-EncodedCommand', [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($script))) { $psi.ArgumentList.Add($a) }
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    [void][Diagnostics.Process]::Start($psi)
}

function Update-NeonNotify($code) {
    $h = Get-History -Count 1
    if (-not $h -or $h.Id -eq $global:NeonNotifyLastId) { return }
    $global:NeonNotifyLastId = $h.Id

    if ($h.Duration.TotalSeconds -lt $NeonConfig.NotifySeconds) { return }
    if ($code -in 130, -1073741510, 3221225786) { return }          # Ctrl+C
    $first = ($h.CommandLine.Trim() -split '\s+', 2)[0]
    if ($first -in $NeonNotifyIgnore) { return }
    if (Test-NeonTerminalFocused) { return }

    $cmd = $h.CommandLine.Trim()
    if ([Microsoft.PowerShell.PSConsoleReadLine]::GetDefaultAddToHistoryOption($cmd) -ne 'MemoryAndFile') { $cmd = NeonText 'notify.secret' }
    if ($cmd.Length -gt 80) { $cmd = $cmd.Substring(0, 79) + '…' }
    $dur = Format-NeonDuration $h.Duration
    $title = if ($code -eq 0) { (NeonText 'notify.ok') -f $dur } else { (NeonText 'notify.fail') -f $code, $dur }
    Send-NeonToast $title "$cmd`n$((Get-Location).Path)"
    [Console]::Write([char]7)   # campanella → lampeggio di tab e barra delle applicazioni (nessun suono)
}

if ($null -ne $NeonPromptHooks) { $NeonPromptHooks.Add({ param($code) Update-NeonNotify $code }) }

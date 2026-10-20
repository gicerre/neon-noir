<#
.SYNOPSIS
    Disinstalla NEON NOIR ripristinando i valori trovati da install.ps1.

.DESCRIPTION
    - toglie dal profilo PowerShell il blocco "# >>> NEON NOIR >>>" (il resto del profilo resta);
    - in settings.json di Terminal toglie profili, schemi, tema, azioni e scorciatoie NEON e rimette
      i valori precedenti delle chiavi cambiate, ma solo se nel frattempo non sono stati modificati;
    - toglie la status line NEON di Claude Code (e rimette quella precedente, se c'era);
    - cancella i file installati.
    Preferenze (~/.config/neon-noir) e dati (%LOCALAPPDATA%\neon: cronologia, cache, backup) restano,
    a meno di -Purge. I programmi installati con winget restano: i comandi per toglierli sono stampati alla fine.

.EXAMPLE
    .\uninstall.ps1
.EXAMPLE
    .\uninstall.ps1 -Purge -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    # Cancella anche preferenze, cronologia contestuale, cache e backup
    [switch]$Purge,
    # Cartella dello stato (install.json) se diversa da %LOCALAPPDATA%\neon
    [string]$StateDir
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Run uninstall.ps1 with PowerShell 7 (pwsh).' }
Import-Module (Join-Path $PSScriptRoot 'tools\NeonInstall.psm1') -Force

if (-not $StateDir) { $StateDir = Join-Path $env:LOCALAPPDATA 'neon' }
$manifestPath = Join-Path $StateDir 'install.json'
if (-not (Test-Path -LiteralPath $manifestPath)) { throw "NEON NOIR install.json not found in $StateDir (not installed with install.ps1?)" }
$m = ConvertFrom-NeonJson ([IO.File]::ReadAllText($manifestPath))
$paths = $m.paths
$utf8 = [Text.UTF8Encoding]::new($false)
$backupDir = Join-Path $StateDir "backup\uninstall-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

function Write-Step([string]$Text) { Write-Host "`n  $([char]0x25B8) $Text" -ForegroundColor Green }
function Write-Note([string]$Text, [string]$Color = 'Gray') { Write-Host "    $Text" -ForegroundColor $Color }

function Backup-NeonFile([string]$Path, [string]$Name) {
    if (-not (Test-Path -LiteralPath $Path) -or -not $PSCmdlet.ShouldProcess($Path, 'backup')) { return }
    New-Item -ItemType Directory -Force $backupDir | Out-Null
    Copy-Item -LiteralPath $Path -Destination (Join-Path $backupDir $Name) -Force
}

function Save-NeonText([string]$Path, [string]$Text, [Text.Encoding]$Encoding) {
    if (-not $PSCmdlet.ShouldProcess($Path, 'write')) { return }
    $tmp = "$Path.neon-tmp"
    [IO.File]::WriteAllText($tmp, $Text, $Encoding)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

Write-Host "`n  NEON NOIR · uninstall  ·  v$($m.version)" -ForegroundColor Cyan

# ── profilo ─────────────────────────────────────────────────────────────────
Write-Step "PowerShell profile ($($paths.ProfilePath))"
if (Test-Path -LiteralPath $paths.ProfilePath) {
    $text = [IO.File]::ReadAllText($paths.ProfilePath)
    $new = Remove-NeonProfileBlock $text
    if ($new -cne $text) {
        Backup-NeonFile $paths.ProfilePath 'Microsoft.PowerShell_profile.ps1'
        # Profilo che conteneva solo NEON: lo si elimina invece di lasciarlo vuoto
        if ([string]::IsNullOrWhiteSpace($new)) {
            if ($PSCmdlet.ShouldProcess($paths.ProfilePath, 'delete empty profile')) { Remove-Item -LiteralPath $paths.ProfilePath }
            Write-Note 'block removed, empty profile deleted'
        }
        else { Save-NeonText $paths.ProfilePath $new ([Text.UTF8Encoding]::new($true)); Write-Note 'block removed' }
    }
    else { Write-Note 'no NEON block' 'DarkGray' }
}

# ── Windows Terminal ────────────────────────────────────────────────────────
if ($m['terminalUndo'] -and (Test-Path -LiteralPath $paths.TerminalSettings)) {
    Write-Step "Windows Terminal ($($paths.TerminalSettings))"
    try {
        $s = ConvertFrom-NeonJson ([IO.File]::ReadAllText($paths.TerminalSettings))
        $restored = Undo-NeonTerminalSettings $s $m.terminalUndo
        Backup-NeonFile $paths.TerminalSettings 'terminal-settings.json'
        Save-NeonText $paths.TerminalSettings (ConvertTo-NeonJson $restored) $utf8
        Write-Note 'NEON profiles, schemes, theme and shortcuts removed; previous values restored'
    }
    catch { Write-Note "cannot update settings.json: $($_.Exception.Message) — file not modified" 'Yellow' }
}

# ── Claude Code ─────────────────────────────────────────────────────────────
if ($m['claudeUndo']) {
    Write-Step 'Claude Code status line'
    $cs = Join-Path $paths.ClaudeDir 'settings.json'
    if (Test-Path -LiteralPath $cs) {
        try {
            $s = ConvertFrom-NeonJson ([IO.File]::ReadAllText($cs))
            $restored = Undo-NeonClaudeStatusLine $s $m.claudeUndo
            if (-not (Test-NeonJsonEqual $restored $s)) {
                Backup-NeonFile $cs 'claude-settings.json'
                Save-NeonText $cs (ConvertTo-NeonJson $restored) $utf8
            }
        }
        catch { Write-Note "cannot update $cs`: $($_.Exception.Message) — file not modified" 'Yellow' }
    }
    $js = Join-Path $paths.ClaudeDir 'neon-statusline.js'
    if ((Test-Path -LiteralPath $js) -and $PSCmdlet.ShouldProcess($js, 'delete')) { Remove-Item -LiteralPath $js }
    Write-Note 'removed'
}

# ── file installati ─────────────────────────────────────────────────────────
Write-Step "Files ($($paths.InstallDir))"
if ($PSCmdlet.ShouldProcess($paths.InstallDir, 'delete NEON files')) {
    foreach ($f in @($m.files)) { Remove-Item -LiteralPath (Join-Path $paths.InstallDir $f) -ErrorAction Ignore }
    if ((Test-Path -LiteralPath $paths.InstallDir) -and -not (Get-ChildItem -LiteralPath $paths.InstallDir -Force)) { Remove-Item -LiteralPath $paths.InstallDir }
}
Write-Note "$(@($m.files).Count) file"

# ── stato, preferenze, dati ─────────────────────────────────────────────────
if ($Purge) {
    Write-Step 'Preferences and data'
    foreach ($p in @($paths.ConfigPath, $StateDir)) {
        if (-not (Test-Path -LiteralPath $p) -or -not $PSCmdlet.ShouldProcess($p, 'delete')) { continue }
        # La DLL del predittore resta bloccata finché ci sono sessioni NEON aperte
        try { Remove-Item -LiteralPath $p -Recurse -Force; Write-Note "deleted $p" }
        catch { Write-Note "$p`: $($_.Exception.Message) — close all terminals and delete it by hand" 'Yellow' }
    }
}
elseif ($PSCmdlet.ShouldProcess($manifestPath, 'delete')) {
    Remove-Item -LiteralPath $manifestPath
    Write-Note "Kept: preferences $($paths.ConfigPath) · data and backups $StateDir  (-Purge deletes them)" 'DarkGray'
}

Write-Host "`n  Done. Close and reopen Windows Terminal." -ForegroundColor Cyan
Write-Host '  Programs installed with winget are still there; to remove them:' -ForegroundColor DarkGray
foreach ($d in Get-NeonDependencies) { Write-Host "    winget uninstall --id $($d.Id)" -ForegroundColor DarkGray }
Write-Host ''

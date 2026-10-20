<#
.SYNOPSIS
    Installa NEON NOIR: profilo PowerShell 7, tema di Windows Terminal, status line di Claude Code.

.DESCRIPTION
    Non sostituisce nulla dell'utente:
      - nel profilo PowerShell aggiunge un blocco di tre righe tra i marcatori "# >>> NEON NOIR >>>";
      - in settings.json di Terminal aggiunge schema, tema, profili, azioni e scorciatoie NEON e imposta
        solo le chiavi elencate in terminal/neon-noir.wt.json, ricordando i valori precedenti;
      - le scorciatoie già assegnate ad altre azioni non vengono toccate;
      - la status line di Claude Code viene impostata solo se non ce n'è già un'altra.
    Prima di ogni modifica copia i file in %LOCALAPPDATA%\neon\backup\<data>\.
    Rieseguirlo aggiorna l'installazione; uninstall.ps1 ripristina i valori precedenti.

.EXAMPLE
    .\install.ps1
.EXAMPLE
    .\install.ps1 -Language it -ProjectsRoot D:\code
.EXAMPLE
    .\install.ps1 -WhatIf            # mostra cosa farebbe, senza scrivere nulla
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    # Lingua dei testi di NEON e dell'installer
    [ValidateSet('en', 'it')] [string]$Language,
    # Cartella dei progetti: profilo "Dev" di Terminal e comando `dirty`
    [string]$ProjectsRoot,
    # Non installare i programmi mancanti con winget (né il font)
    [switch]$SkipDependencies,
    # Non modificare Windows Terminal
    [switch]$NoTerminal,
    # Non installare la status line di Claude Code
    [switch]$NoClaude,

    # Percorsi alternativi (test, installazioni particolari)
    [string]$InstallDir, [string]$ProfilePath, [string]$TerminalSettings,
    [string]$ClaudeDir, [string]$ConfigPath, [string]$StateDir
)

$ErrorActionPreference = 'Stop'
# Questo file deve restare leggibile da Windows PowerShell 5.1: niente ??, ?:, && fino al rilancio in pwsh.

# ── Windows PowerShell 5.1: installa PowerShell 7 e rilancia lo script ─────
if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if (-not $pwsh) {
        if ($SkipDependencies -or -not (Get-Command winget -ErrorAction SilentlyContinue)) {
            throw 'NEON NOIR needs PowerShell 7: https://aka.ms/powershell (or: winget install Microsoft.PowerShell)'
        }
        Write-Host 'Installing PowerShell 7 (winget)...'
        winget install --id Microsoft.PowerShell -e --accept-source-agreements --accept-package-agreements --silent
        $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
        $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
        if (-not $pwsh) { throw 'PowerShell 7 installed but pwsh.exe not found: open a new terminal and run install.ps1 again.' }
    }
    $argv = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath)
    foreach ($kv in $PSBoundParameters.GetEnumerator()) {
        if ($kv.Value -is [System.Management.Automation.SwitchParameter]) { if ($kv.Value) { $argv += "-$($kv.Key)" } }
        else { $argv += "-$($kv.Key)"; $argv += "$($kv.Value)" }
    }
    & $pwsh.Source @argv
    exit $LASTEXITCODE
}

$root = $PSScriptRoot
Import-Module (Join-Path $root 'tools\NeonInstall.psm1') -Force

# ── testi ───────────────────────────────────────────────────────────────────
$texts = @{
    en = @{
        title = 'NEON NOIR · install'; deps = 'Dependencies'; installing = 'installing {0} ({1})'; ok = 'present'
        depfail = 'could not install {0}: {1}'; nowinget = 'winget not found: install the missing programs by hand'
        font = 'font JetBrainsMono Nerd Font'; fontskip = 'font: oh-my-posh not available, install JetBrainsMono Nerd Font by hand'
        files = 'Files → {0}'; profile = 'PowerShell profile ({0})'; terminal = 'Windows Terminal ({0})'
        notfound = 'not found, skipped'; badjson = 'cannot read {0}: {1} — skipped, file not modified'
        keyskip = 'shortcut already in use, left as is: {0}'; claude = 'Claude Code status line'
        claudekept = 'another status line is configured: left as is (remove "statusLine" from {0} and run install.ps1 again to use NEON''s)'
        claudenone = 'Claude Code not found, skipped'; backup = 'Backup: {0}'
        done = 'Done. Open a new Windows Terminal tab. Type "neon" for the command list, "cinema --mode" for the themes.'
        modes = @{ appended = 'block added'; updated = 'block updated'; migrated = 'previous NEON profile replaced by the block (copy in backup)' }
    }
    it = @{
        title = 'NEON NOIR · installazione'; deps = 'Dipendenze'; installing = 'installo {0} ({1})'; ok = 'presente'
        depfail = 'impossibile installare {0}: {1}'; nowinget = 'winget non trovato: installare a mano i programmi mancanti'
        font = 'font JetBrainsMono Nerd Font'; fontskip = 'font: oh-my-posh non disponibile, installare a mano JetBrainsMono Nerd Font'
        files = 'File → {0}'; profile = 'Profilo PowerShell ({0})'; terminal = 'Windows Terminal ({0})'
        notfound = 'non trovato, saltato'; badjson = 'impossibile leggere {0}: {1} — saltato, file non modificato'
        keyskip = 'scorciatoia già in uso, lasciata com''è: {0}'; claude = 'Status line di Claude Code'
        claudekept = 'è configurata un''altra status line: lasciata com''è (togliere "statusLine" da {0} e rieseguire install.ps1 per usare quella NEON)'
        claudenone = 'Claude Code non trovato, saltato'; backup = 'Backup: {0}'
        done = 'Fatto. Aprire una nuova scheda di Windows Terminal. "neon" mostra i comandi, "cinema --mode" i temi.'
        modes = @{ appended = 'blocco aggiunto'; updated = 'blocco aggiornato'; migrated = 'profilo NEON precedente sostituito dal blocco (copia nel backup)' }
    }
}

# ── percorsi e stato dell'installazione precedente ─────────────────────────
$paths = Get-NeonDefaultPaths
foreach ($k in @($paths.Keys)) { if ($PSBoundParameters.ContainsKey($k) -and $PSBoundParameters[$k]) { $paths[$k] = [IO.Path]::GetFullPath($PSBoundParameters[$k]) } }
$manifestPath = Join-Path $paths.StateDir 'install.json'
$previous = if (Test-Path -LiteralPath $manifestPath) { ConvertFrom-NeonJson ([IO.File]::ReadAllText($manifestPath)) } else { $null }

# Preferenze: le funzioni di src/config.ps1 leggono e scrivono il file dell'utente
# (-WhatIf varrebbe anche per i cmdlet interni di config.ps1, che non scrivono nulla)
$NeonConfigPath = $paths.ConfigPath
$whatIf = $WhatIfPreference; $WhatIfPreference = $false
. (Join-Path $root 'src\config.ps1')
$WhatIfPreference = $whatIf
$userConfig = Get-NeonUserConfig
if ($Language) { $userConfig.Language = $Language }
if ($ProjectsRoot) { $userConfig.ProjectsRoot = [IO.Path]::GetFullPath($ProjectsRoot) }
$lang = if ($userConfig['Language'] -eq 'it') { 'it' } else { 'en' }
$T = $texts[$lang]
$projects = if ($userConfig['ProjectsRoot']) { $userConfig['ProjectsRoot'] } else { '' }

$version = (Get-Content (Join-Path $root 'src\VERSION') -Raw).Trim()
$backupDir = Join-Path $paths.StateDir "backup\$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$utf8 = [Text.UTF8Encoding]::new($false)
$utf8Bom = [Text.UTF8Encoding]::new($true)
$script:backedUp = $false

function Write-Step([string]$Text) { Write-Host "`n  $([char]0x25B8) $Text" -ForegroundColor Green }
function Write-Note([string]$Text, [string]$Color = 'Gray') { Write-Host "    $Text" -ForegroundColor $Color }

function Backup-NeonFile([string]$Path, [string]$Name) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    if (-not $PSCmdlet.ShouldProcess($Path, 'backup')) { return }
    New-Item -ItemType Directory -Force $backupDir | Out-Null
    Copy-Item -LiteralPath $Path -Destination (Join-Path $backupDir $Name) -Force
    $script:backedUp = $true
}

function Save-NeonText([string]$Path, [string]$Text, [Text.Encoding]$Encoding) {
    if (-not $PSCmdlet.ShouldProcess($Path, 'write')) { return }
    New-Item -ItemType Directory -Force (Split-Path $Path) | Out-Null
    # Scrittura atomica: un file a metà renderebbe Terminal o Claude Code inutilizzabili
    $tmp = "$Path.neon-tmp"
    [IO.File]::WriteAllText($tmp, $Text, $Encoding)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Update-NeonPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

Write-Host "`n  $($T.title)  ·  v$version" -ForegroundColor Cyan

# ── 1. dipendenze ───────────────────────────────────────────────────────────
if (-not $SkipDependencies) {
    Write-Step $T.deps
    $winget = Get-Command winget -ErrorAction Ignore
    foreach ($d in Get-NeonDependencies) {
        if (Get-Command $d.Command -CommandType Application -ErrorAction Ignore) { Write-Note "$($d.Id)  $($T.ok)" 'DarkGray'; continue }
        if (-not $winget) { Write-Note "$($d.Id)  $($T.nowinget)" 'Yellow'; continue }
        if (-not $PSCmdlet.ShouldProcess($d.Id, 'winget install')) { continue }
        Write-Note ($T.installing -f $d.Id, $d.Why)
        # Ambito utente quando il pacchetto lo consente, altrimenti installazione normale
        winget install --id $d.Id -e --scope user --accept-source-agreements --accept-package-agreements --silent | Out-Null
        if ($LASTEXITCODE -ne 0) { winget install --id $d.Id -e --accept-source-agreements --accept-package-agreements --silent | Out-Null }
        if ($LASTEXITCODE -ne 0) { Write-Note ($T.depfail -f $d.Id, "winget exit $LASTEXITCODE") 'Yellow' }
        Update-NeonPath
    }
    if (Test-NeonFont) { Write-Note "$($T.font)  $($T.ok)" 'DarkGray' }
    elseif (Get-Command oh-my-posh -CommandType Application -ErrorAction Ignore) {
        if ($PSCmdlet.ShouldProcess('JetBrainsMono', 'oh-my-posh font install')) {
            Write-Note ($T.installing -f 'JetBrainsMono Nerd Font', 'oh-my-posh')
            oh-my-posh font install JetBrainsMono | Out-Null
        }
    }
    else { Write-Note $T.fontskip 'Yellow' }
}

# ── 2. file ─────────────────────────────────────────────────────────────────
Write-Step ($T.files -f $paths.InstallDir)
$src = Join-Path $root 'src'
$files = @((Get-ChildItem -LiteralPath $src -File).Name)
if ($PSCmdlet.ShouldProcess($paths.InstallDir, 'copy NEON files')) {
    New-Item -ItemType Directory -Force $paths.InstallDir | Out-Null
    foreach ($f in $files) { Copy-Item -LiteralPath (Join-Path $src $f) -Destination (Join-Path $paths.InstallDir $f) -Force }
    # File di una versione precedente che non esistono più
    if ($previous -and $previous.Contains('files')) {
        foreach ($old in @($previous.files)) {
            if ($files -notcontains $old) { Remove-Item -LiteralPath (Join-Path $paths.InstallDir $old) -ErrorAction Ignore }
        }
    }
}
Write-Note "$($files.Count) file"

# Preferenze dell'utente: solo le chiavi passate a install.ps1, il resto del file resta com'è
if ($Language -or $ProjectsRoot) {
    if ($PSCmdlet.ShouldProcess($paths.ConfigPath, 'write preferences')) { Save-NeonUserConfig $userConfig }
    Write-Note $paths.ConfigPath 'DarkGray'
}

# ── 3. profilo PowerShell ───────────────────────────────────────────────────
Write-Step ($T.profile -f $paths.ProfilePath)
$profileText = if (Test-Path -LiteralPath $paths.ProfilePath) { [IO.File]::ReadAllText($paths.ProfilePath) } else { '' }
$r = Add-NeonProfileBlock $profileText (Join-Path $paths.InstallDir 'neon-noir.ps1')
if ($r.Text -cne $profileText) {
    Backup-NeonFile $paths.ProfilePath 'Microsoft.PowerShell_profile.ps1'
    Save-NeonText $paths.ProfilePath $r.Text $utf8Bom
}
Write-Note $T.modes[$r.Mode]
# 'migrated' va ricordato anche nelle reinstallazioni, che trovano già il blocco ('updated')
$profileMode = if ($r.Mode -eq 'updated' -and $previous -and $previous['profileMode']) { $previous.profileMode } else { $r.Mode }

# ── 4. Windows Terminal ─────────────────────────────────────────────────────
$terminalUndo = if ($previous -and $previous['terminalUndo']) { $previous.terminalUndo } else { $null }
if (-not $NoTerminal) {
    Write-Step ($T.terminal -f $paths.TerminalSettings)
    if (-not (Test-Path -LiteralPath (Split-Path $paths.TerminalSettings))) { Write-Note $T.notfound 'Yellow' }
    else {
        $text = if (Test-Path -LiteralPath $paths.TerminalSettings) { [IO.File]::ReadAllText($paths.TerminalSettings) } else { '' }
        try { $settings = ConvertFrom-NeonJson $text } catch { $settings = $null; Write-Note ($T.badjson -f $paths.TerminalSettings, $_.Exception.Message) 'Yellow' }
        if ($null -ne $settings) {
            $fragment = ConvertFrom-NeonJson ([IO.File]::ReadAllText((Join-Path $root 'terminal\neon-noir.wt.json')))
            $m = Merge-NeonTerminalSettings $settings $fragment $projects $terminalUndo
            Backup-NeonFile $paths.TerminalSettings 'terminal-settings.json'
            Save-NeonText $paths.TerminalSettings (ConvertTo-NeonJson $m.Settings) $utf8
            $terminalUndo = $m.Undo
            foreach ($k in $m.Skipped) { Write-Note ($T.keyskip -f $k) 'Yellow' }
            Write-Note "Neon Noir · PowerShell 7 · Dev ($(if ($projects) { $projects } else { '%USERPROFILE%' })) · Admin · Clean"
        }
    }
}

# ── 5. Claude Code ──────────────────────────────────────────────────────────
$claudeUndo = if ($previous -and $previous['claudeUndo']) { $previous.claudeUndo } else { $null }
if (-not $NoClaude) {
    Write-Step $T.claude
    $hasClaude = (Test-Path -LiteralPath $paths.ClaudeDir) -or (Get-Command claude -ErrorAction Ignore)
    if (-not $hasClaude) { Write-Note $T.claudenone 'DarkGray' }
    else {
        $statusScript = Join-Path $paths.ClaudeDir 'neon-statusline.js'
        $claudeSettings = Join-Path $paths.ClaudeDir 'settings.json'
        $text = if (Test-Path -LiteralPath $claudeSettings) { [IO.File]::ReadAllText($claudeSettings) } else { '' }
        try { $cs = ConvertFrom-NeonJson $text } catch { $cs = $null; Write-Note ($T.badjson -f $claudeSettings, $_.Exception.Message) 'Yellow' }
        if ($null -ne $cs) {
            $c = Set-NeonClaudeStatusLine $cs $statusScript $claudeUndo
            if ($c.Status -eq 'kept') { Write-Note ($T.claudekept -f $claudeSettings) 'Yellow' }
            else {
                if ($PSCmdlet.ShouldProcess($statusScript, 'copy status line')) {
                    New-Item -ItemType Directory -Force $paths.ClaudeDir | Out-Null
                    Copy-Item -LiteralPath (Join-Path $root 'claude\neon-statusline.js') -Destination $statusScript -Force
                }
                if (-not (Test-NeonJsonEqual $c.Settings $cs)) {
                    Backup-NeonFile $claudeSettings 'claude-settings.json'
                    Save-NeonText $claudeSettings (ConvertTo-NeonJson $c.Settings) $utf8
                }
                $claudeUndo = $c.Undo
                Write-Note $statusScript
            }
        }
    }
}

# ── 6. manifest (letto da uninstall.ps1 e dalle installazioni successive) ──
$manifest = [ordered]@{
    version      = $version
    installedAt  = (Get-Date).ToString('s')
    paths        = $paths
    files        = $files
    profileMode  = $profileMode
    terminalUndo = $terminalUndo
    claudeUndo   = $claudeUndo
}
Save-NeonText $manifestPath (ConvertTo-NeonJson $manifest) $utf8

if ($script:backedUp) { Write-Host "`n  $($T.backup -f $backupDir)" -ForegroundColor DarkGray }
Write-Host "`n  $($T.done)`n" -ForegroundColor Cyan

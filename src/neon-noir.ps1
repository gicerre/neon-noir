# ── NEON NOIR · avvio ──────────────────────────────────────────────────────
# Caricato dal profilo PowerShell 7 con un blocco scritto da install.ps1
# (uninstall.ps1 lo rimuove senza toccare il resto del profilo).
#
# Preferenze personali in ~/.config/neon-noir/config.psd1 (valori predefiniti in config.ps1)
# "neon config" mostra i valori attuali · "neon title" cambia la scritta dell'intestazione
$NeonHome = $PSScriptRoot
. (Join-Path $NeonHome 'config.ps1')
. (Join-Path $NeonHome 'i18n.ps1')
$env:NEON_LANG = $NeonConfig.Language   # letto dalla status line di Claude Code (processi figli)

# Le sessioni non interattive (pwsh -Command/-File, output rediretto, host diversi dalla console)
# caricano solo le funzioni: niente prompt, banner o key binding.
$neonArgs     = [Environment]::GetCommandLineArgs() | Select-Object -Skip 1
$neonHasCmd   = [bool]($neonArgs -match '^-{1,2}(c|com\w*|f|fi\w*|e|ec|enc\w*)$')
$neonNoExit   = [bool]($neonArgs -match '^-{1,2}noe\w*$')
$NeonInteractive = $Host.Name -eq 'ConsoleHost' -and
    [Environment]::UserInteractive -and
    -not [Console]::IsOutputRedirected -and
    -not ($neonArgs -match '^-{1,2}noni\w*$') -and
    (-not $neonHasCmd -or $neonNoExit)

# Script personale facoltativo (ExtraProfile in config.psd1): funzioni e alias propri dell'utente
if ($NeonConfig.ExtraProfile -and (Test-Path -LiteralPath $NeonConfig.ExtraProfile)) { . $NeonConfig.ExtraProfile }

. (Join-Path $NeonHome 'commands.ps1')
. (Join-Path $NeonHome 'project.ps1')
. (Join-Path $NeonHome 'cinema.ps1')

if ($NeonInteractive) {
    . (Join-Path $NeonHome 'readline.ps1')

    # Errori / avvisi / info con grafica dedicata (solo presentazione)
    if ($NeonConfig.Alerts) { . (Join-Path $NeonHome 'alerts.ps1') }

    if (Get-Command oh-my-posh -CommandType Application -ErrorAction SilentlyContinue) {
        oh-my-posh init pwsh --config (Join-Path $NeonHome 'neon-noir.omp.json') | Invoke-Expression
    }

    # Hook eseguiti prima di ogni prompt: Oh My Posh chiama Set-PoshContext con l'exit code (0 = riuscito).
    # Ogni modulo aggiunge il proprio scriptblock a $NeonPromptHooks.
    $NeonPromptHooks = [Collections.Generic.List[scriptblock]]::new()
    function Invoke-NeonPromptHooks($code) { foreach ($h in $NeonPromptHooks) { try { & $h $code } catch { } } }
    New-Alias -Name 'Set-PoshContext' -Value 'Invoke-NeonPromptHooks' -Scope Global -Force

    # Frecce ↑/↓ contestuali alla directory
    try { . (Join-Path $NeonHome 'dirhistory.ps1') }
    catch {
        Set-PSReadLineOption -PredictionSource None
        Write-Warning ((NeonText 'warn.dirhistory') -f $_.Exception.Message)
    }

    # Notifica di Windows quando un comando lungo termina e il terminale non è in primo piano
    if ($NeonConfig.NotifySeconds -gt 0) { . (Join-Path $NeonHome 'notify.ps1') }

    # zoxide: `z <parte-del-nome>` salta alle directory usate di frequente, `zi` con fzf.
    # L'init viene messo in cache e rigenerato solo quando zoxide si aggiorna.
    $neonZ = Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($neonZ) {
        $neonZCache = Join-Path $env:LOCALAPPDATA 'neon\cache\zoxide.ps1'
        if (-not (Test-Path $neonZCache) -or (Get-Item $neonZCache).LastWriteTime -lt (Get-Item $neonZ.Source).LastWriteTime) {
            New-Item -ItemType Directory -Force (Split-Path $neonZCache) | Out-Null
            & $neonZ.Source init powershell | Out-File -FilePath $neonZCache -Encoding utf8
        }
        . $neonZCache
    }

    . (Join-Path $NeonHome 'banner.ps1')

    # clear / cls: pulisce schermo e scrollback, poi ripropone la schermata iniziale
    function Clear-Host {
        [Console]::Write("$([char]27)[2J$([char]27)[3J$([char]27)[H")
        if ($NeonConfig.Banner -and -not $env:NEON_NO_BANNER) { Show-NeonBanner -NoAnimation }
    }

    # Banner: una volta per sessione, non nelle shell annidate, non nei terminali di VS Code
    if ($NeonConfig.Banner -and -not $env:NEON_NO_BANNER -and -not $env:NEON_BANNER_SHOWN -and
        -not $neonHasCmd -and $env:TERM_PROGRAM -ne 'vscode') {
        Show-NeonBanner
        $env:NEON_BANNER_SHOWN = '1'
    }
}

Remove-Variable neonArgs, neonHasCmd, neonNoExit, neonZ, neonZCache -ErrorAction Ignore

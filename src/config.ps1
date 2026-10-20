# ── NEON NOIR · configurazione ─────────────────────────────────────────────
# Valori predefiniti nel codice + preferenze dell'utente in ~/.config/neon-noir/config.psd1.
# Il file dell'utente contiene solo le chiavi cambiate e non viene mai toccato dagli aggiornamenti.
#
#   Banner        : $true / $false                ($env:NEON_NO_BANNER = 1 per una sessione)
#   Animate       : 'daily' | 'always' | 'never'  ($env:NEON_NO_ANIM = 1 per una sessione)
#   Title         : testo dell'intestazione in caratteri pixel (A-Z 0-9 spazio - _ . /) · `neon title`
#   Alerts        : grafica di errori/avvisi/info ($false = aspetto standard di PowerShell)
#   NotifySeconds : durata minima (s) per la notifica di fine comando (0 = disattivata)
#   ProjectsRoot  : cartella dei progetti usata da `dirty` (vuota = directory corrente)
#   Language      : 'en' | 'it'
#   ExtraProfile  : script personale facoltativo caricato all'avvio (funzioni, alias propri)
#   TerminalSettings : percorso di settings.json di Windows Terminal (vuoto = rilevamento automatico)

$NeonDefaults = [ordered]@{
    Banner           = $true
    Animate          = 'daily'
    Title            = 'NEON//NOIR'
    Alerts           = $true
    NotifySeconds    = 30
    ProjectsRoot     = ''
    Language         = 'en'
    ExtraProfile     = ''
    TerminalSettings = ''
}
# install.ps1 e i test possono indicare un altro file impostando $NeonConfigPath prima di caricare questo script
if (-not $NeonConfigPath) { $NeonConfigPath = Join-Path $HOME '.config\neon-noir\config.psd1' }

# settings.json di Windows Terminal: versione Store, Preview o installazione senza pacchetto
function Get-NeonTerminalSettingsPath {
    if ($NeonConfig.TerminalSettings) { return $NeonConfig.TerminalSettings }
    $candidates = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
        "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
    )
    $found = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if ($found) { $found } else { $candidates[0] }
}

function Get-NeonUserConfig {
    if (-not (Test-Path -LiteralPath $NeonConfigPath)) { return @{} }
    try { Import-PowerShellDataFile -LiteralPath $NeonConfigPath }
    catch { Write-Warning "NEON NOIR: $NeonConfigPath is not valid, using defaults ($($_.Exception.Message))"; @{} }
}

# Scrive solo le chiavi note; i valori sono testo, numeri o booleani
function Save-NeonUserConfig([hashtable]$Config) {
    $lines = foreach ($k in $NeonDefaults.Keys) {
        if (-not $Config.ContainsKey($k)) { continue }
        $v = $Config[$k]
        $text = if ($v -is [bool]) { if ($v) { '$true' } else { '$false' } }
                elseif ($v -is [int] -or $v -is [long] -or $v -is [double]) { "$v" }
                else { "'" + ("$v" -replace "'", "''") + "'" }
        "    $k = $text"
    }
    New-Item -ItemType Directory -Force (Split-Path $NeonConfigPath) | Out-Null
    $body = "# NEON NOIR · preferenze personali (solo le chiavi diverse dai valori predefiniti)`n@{`n" + ($lines -join "`n") + "`n}`n"
    [IO.File]::WriteAllText($NeonConfigPath, $body, [Text.UTF8Encoding]::new($false))
}

# Configurazione effettiva: predefiniti + preferenze dell'utente
$NeonConfig = @{}
foreach ($k in $NeonDefaults.Keys) { $NeonConfig[$k] = $NeonDefaults[$k] }
$neonUser = Get-NeonUserConfig
foreach ($k in $neonUser.Keys) { if ($NeonDefaults.Contains($k)) { $NeonConfig[$k] = $neonUser[$k] } }
Remove-Variable neonUser

# ── NEON NOIR · logica di installazione ────────────────────────────────────
# Funzioni pure usate da install.ps1, uninstall.ps1 e dai test: ricevono e restituiscono
# oggetti (hashtable ordinate), testo e percorsi; le scritture su disco le fanno gli script.
#
# Ogni modifica a file dell'utente produce un "undo": i valori trovati prima dell'installazione,
# così uninstall.ps1 ripristina solo ciò che NEON ha cambiato e lascia stare le modifiche successive.

Set-StrictMode -Version Latest

$script:ProfileBegin = '# >>> NEON NOIR >>>'
$script:ProfileEnd   = '# <<< NEON NOIR <<<'
# Riga del vecchio profilo NEON (prima dell'installer), che sostituiva l'intero profilo
$script:LegacyLoader = "`$NeonHome = Join-Path `$PSScriptRoot 'neon'"

# ── percorsi ────────────────────────────────────────────────────────────────

function Get-NeonDefaultPaths {
    $profilePath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
    [ordered]@{
        InstallDir       = Join-Path (Split-Path $profilePath) 'neon'
        ProfilePath      = $profilePath
        TerminalSettings = Find-NeonTerminalSettings
        ClaudeDir        = Join-Path $HOME '.claude'
        ConfigPath       = Join-Path $HOME '.config\neon-noir\config.psd1'
        StateDir         = Join-Path $env:LOCALAPPDATA 'neon'
    }
}

# Stessa ricerca di Get-NeonTerminalSettingsPath (src/config.ps1): Store, Preview, senza pacchetto
function Find-NeonTerminalSettings {
    $candidates = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
        "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
    )
    $found = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if ($found) { return $found }
    # Terminal installato ma mai avviato: la cartella del pacchetto esiste già
    $pkg = $candidates[0..1] | Where-Object { Test-Path -LiteralPath (Split-Path (Split-Path $_)) } | Select-Object -First 1
    if ($pkg) { $pkg } else { $candidates[0] }
}

# ── JSON ────────────────────────────────────────────────────────────────────

function ConvertFrom-NeonJson([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return [ordered]@{} }
    # settings.json di Terminal ammette commenti e virgole finali: ConvertFrom-Json di pwsh 7 li tollera
    $Text | ConvertFrom-Json -AsHashtable -Depth 64
}

function ConvertTo-NeonJson($Object) { ConvertTo-Json -InputObject $Object -Depth 64 }

function Test-NeonJsonEqual($A, $B) {
    (ConvertTo-Json -InputObject $A -Depth 64 -Compress) -ceq (ConvertTo-Json -InputObject $B -Depth 64 -Compress)
}

function Copy-NeonValue($Value) {
    if ($null -eq $Value) { return $null }
    $json = ConvertTo-Json -InputObject $Value -Depth 64 -Compress
    , ($json | ConvertFrom-Json -AsHashtable -Depth 64 -NoEnumerate)
}

function Get-NeonList($Parent, [string]$Key) {
    if (-not $Parent.Contains($Key) -or $null -eq $Parent[$Key]) { $Parent[$Key] = [Collections.Generic.List[object]]::new() }
    elseif ($Parent[$Key] -isnot [Collections.Generic.List[object]]) {
        $l = [Collections.Generic.List[object]]::new()
        foreach ($x in @($Parent[$Key])) { $l.Add($x) }
        $Parent[$Key] = $l
    }
    , $Parent[$Key]
}

function Find-NeonIndex($List, [scriptblock]$Predicate) {
    for ($i = 0; $i -lt $List.Count; $i++) { if (& $Predicate $List[$i]) { return $i } }
    -1
}

function Test-NeonItem($Item, [string]$Key, $Value) {
    $Item -is [Collections.IDictionary] -and $Item.Contains($Key) -and "$($Item[$Key])" -ceq "$Value"
}

# ── Windows Terminal ────────────────────────────────────────────────────────

function New-NeonTerminalUndo {
    [ordered]@{ globals = [ordered]@{}; defaults = [ordered]@{}; profiles = [ordered]@{}; schemes = [ordered]@{}
                themes = [ordered]@{}; actions = [ordered]@{}; hidden = [ordered]@{}; skippedKeys = @() }
}

# Ricorda il valore precedente di una chiave solo la prima volta (le reinstallazioni non lo sovrascrivono)
function Save-NeonPrior($Bag, [string]$Key, $Parent, $NewValue) {
    if ($Bag.Contains($Key)) { $Bag[$Key].set = Copy-NeonValue $NewValue; return }
    $had = $Parent.Contains($Key)
    $Bag[$Key] = [ordered]@{ had = $had; value = $(if ($had) { Copy-NeonValue $Parent[$Key] }); set = Copy-NeonValue $NewValue }
}

# Profili, schemi, temi e azioni hanno identificatori NEON (guid 6e0a1c11-…, "Neon Noir", Neon.*):
# se esistono già vengono da una versione precedente di NEON, quindi l'uninstall li toglie e basta
function Save-NeonPriorItem($Bag, [string]$Key) {
    if (-not $Bag.Contains($Key)) { $Bag[$Key] = [ordered]@{ had = $false; value = $null } }
}

# Unisce il frammento NEON in settings.json. Restituisce @{ Settings; Undo; Skipped }.
#   Fragment     : contenuto di terminal/neon-noir.wt.json
#   ProjectsRoot : cartella iniziale del profilo Dev (vuota = %USERPROFILE%)
#   PreviousUndo : undo di un'installazione precedente (da install.json), per conservare i valori originali
function Merge-NeonTerminalSettings($Settings, $Fragment, [string]$ProjectsRoot, $PreviousUndo) {
    $s = Copy-NeonValue $Settings
    if ($s -isnot [Collections.IDictionary]) { $s = [ordered]@{} }
    $f = Copy-NeonValue $Fragment
    $undo = New-NeonTerminalUndo
    if ($PreviousUndo) { foreach ($kv in (Copy-NeonValue $PreviousUndo).GetEnumerator()) { $undo[$kv.Key] = $kv.Value } }
    $skipped = [Collections.Generic.List[string]]::new()
    if (-not $ProjectsRoot) { $ProjectsRoot = '%USERPROFILE%' }

    if (-not $s.Contains('$schema')) { $s['$schema'] = 'https://aka.ms/terminal-profiles-schema' }

    foreach ($kv in $f.globals.GetEnumerator()) {
        Save-NeonPrior $undo.globals $kv.Key $s $kv.Value
        $s[$kv.Key] = $kv.Value
    }

    if (-not $s.Contains('profiles') -or $null -eq $s.profiles) { $s.profiles = [ordered]@{} }
    if ($s.profiles -is [Collections.IList]) { $s.profiles = [ordered]@{ list = $s.profiles } }   # formato vecchio
    if (-not $s.profiles.Contains('defaults') -or $null -eq $s.profiles.defaults) { $s.profiles.defaults = [ordered]@{} }
    foreach ($kv in $f.defaults.GetEnumerator()) {
        Save-NeonPrior $undo.defaults $kv.Key $s.profiles.defaults $kv.Value
        $s.profiles.defaults[$kv.Key] = $kv.Value
    }

    # Profili NEON in testa all'elenco, nell'ordine del frammento
    $list = Get-NeonList $s.profiles 'list'
    $pos = 0
    foreach ($p in $f.profiles) {
        if ($p.Contains('startingDirectory')) { $p.startingDirectory = $p.startingDirectory.Replace('{{ProjectsRoot}}', $ProjectsRoot) }
        $guid = $p.guid
        $i = Find-NeonIndex $list { param($x) Test-NeonItem $x 'guid' $guid }
        Save-NeonPriorItem $undo.profiles $guid
        if ($i -ge 0) { $list[$i] = $p } else { $list.Insert([Math]::Min($pos, $list.Count), $p) }
        $pos++
    }
    # Il profilo "PowerShell" generato da Terminal è un doppione di "PowerShell 7"
    foreach ($p in $list) {
        if ((Test-NeonItem $p 'source' 'Windows.Terminal.PowershellCore') -and $p.Contains('guid')) {
            if (-not $undo.hidden.Contains($p.guid)) {
                $undo.hidden[$p.guid] = [ordered]@{ had = $p.Contains('hidden'); value = $p['hidden']; set = $true }
            }
            $p.hidden = $true
        }
    }

    foreach ($pair in @(@('schemes', 'name'), @('themes', 'name'), @('actions', 'id'))) {
        $key, $idKey = $pair
        $target = Get-NeonList $s $key
        foreach ($item in $f[$key]) {
            $id = $item[$idKey]
            $i = Find-NeonIndex $target { param($x) Test-NeonItem $x $idKey $id }
            Save-NeonPriorItem $undo[$key] $id
            if ($i -ge 0) { $target[$i] = $item } else { $target.Add($item) }
        }
    }

    # Scorciatoie: mai rubare un tasto già assegnato a un'altra azione
    $kb = Get-NeonList $s 'keybindings'
    $actions = Get-NeonList $s 'actions'
    foreach ($b in $f.keybindings) {
        $id = $b.id; $keys = $b.keys
        $own = Find-NeonIndex $kb { param($x) Test-NeonItem $x 'id' $id }
        $taken = @($kb | Where-Object { (Test-NeonItem $_ 'keys' $keys) -and -not (Test-NeonItem $_ 'id' $id) }).Count +
                 @($actions | Where-Object { Test-NeonItem $_ 'keys' $keys }).Count
        if ($taken) {
            $skipped.Add("$keys ($id)")
            if ($own -ge 0) { $kb.RemoveAt($own) }
            continue
        }
        if ($own -ge 0) { $kb[$own] = $b } else { $kb.Add($b) }
    }
    $undo.skippedKeys = @($skipped)

    @{ Settings = $s; Undo = $undo; Skipped = @($skipped) }
}

# Ripristina un valore se è ancora quello scritto da NEON; se l'utente l'ha cambiato lo lascia
function Restore-NeonPrior($Parent, [string]$Key, $Entry, [scriptblock]$IsOurs) {
    if (-not $Parent.Contains($Key)) { return }
    $current = $Parent[$Key]
    $ours = (Test-NeonJsonEqual $current $Entry.set) -or ($IsOurs -and (& $IsOurs $current))
    if (-not $ours) { return }
    if ($Entry.had) { $Parent[$Key] = $Entry.value } else { $Parent.Remove($Key) }
}

function Undo-NeonTerminalSettings($Settings, $Undo) {
    $s = Copy-NeonValue $Settings
    $u = New-NeonTerminalUndo
    if ($Undo) { foreach ($kv in $Undo.GetEnumerator()) { $u[$kv.Key] = $kv.Value } }

    foreach ($kv in $u.globals.GetEnumerator()) { Restore-NeonPrior $s $kv.Key $kv.Value $null }

    if ($s.Contains('profiles') -and $s.profiles -is [Collections.IDictionary]) {
        $d = $s.profiles['defaults']
        if ($d -is [Collections.IDictionary]) {
            # modalità cinema accesa al momento della disinstallazione
            if ($d.Contains('experimental.pixelShaderPath') -and "$($d['experimental.pixelShaderPath'])" -match '[\\/]neon[\\/]shaders[\\/]') {
                $d.Remove('experimental.pixelShaderPath')
            }
            foreach ($kv in $u.defaults.GetEnumerator()) {
                $isOurs = if ($kv.Key -eq 'colorScheme') { { param($v) "$v" -clike 'NEON *' } } else { $null }
                Restore-NeonPrior $d $kv.Key $kv.Value $isOurs
            }
        }
        $list = Get-NeonList $s.profiles 'list'
        foreach ($kv in $u.profiles.GetEnumerator()) {
            $guid = $kv.Key
            $i = Find-NeonIndex $list { param($x) Test-NeonItem $x 'guid' $guid }
            if ($i -lt 0) { continue }
            if ($kv.Value.had) { $list[$i] = $kv.Value.value } else { $list.RemoveAt($i) }
        }
        foreach ($kv in $u.hidden.GetEnumerator()) {
            $guid = $kv.Key
            $i = Find-NeonIndex $list { param($x) Test-NeonItem $x 'guid' $guid }
            if ($i -ge 0) { Restore-NeonPrior $list[$i] 'hidden' $kv.Value $null }
        }
    }

    foreach ($pair in @(@('schemes', 'name'), @('themes', 'name'), @('actions', 'id'))) {
        $key, $idKey = $pair
        if (-not $s.Contains($key)) { continue }
        $target = Get-NeonList $s $key
        foreach ($kv in $u[$key].GetEnumerator()) {
            $id = $kv.Key
            $i = Find-NeonIndex $target { param($x) Test-NeonItem $x $idKey $id }
            if ($i -lt 0) { continue }
            if ($kv.Value.had) { $target[$i] = $kv.Value.value } else { $target.RemoveAt($i) }
        }
    }
    # Schemi delle modalità cinema (aggiunti da `cinema`, non dall'installer) e scorciatoie Neon.*
    if ($s.Contains('schemes')) { $s.schemes = @($s.schemes | Where-Object { -not ($_ -is [Collections.IDictionary] -and "$($_['name'])" -clike 'NEON *') }) }
    if ($s.Contains('keybindings')) { $s.keybindings = @($s.keybindings | Where-Object { -not ($_ -is [Collections.IDictionary] -and "$($_['id'])" -clike 'Neon.*') }) }
    $s
}

# ── profilo PowerShell ──────────────────────────────────────────────────────

function Get-NeonProfileBlock([string]$EntryPath) {
    $q = $EntryPath.Replace("'", "''")
    "$script:ProfileBegin`n# Aggiunto da NEON NOIR install.ps1 · uninstall.ps1 rimuove queste righe`nif (Test-Path -LiteralPath '$q') { . '$q' }`n$script:ProfileEnd"
}

function Test-NeonLegacyProfile([string]$Text) { [bool]$Text -and $Text.Contains($script:LegacyLoader) }

# Restituisce @{ Text; Mode } con Mode = 'appended' | 'updated' | 'migrated'
function Add-NeonProfileBlock([string]$Text, [string]$EntryPath) {
    $nl = if ($Text -match "`r`n") { "`r`n" } else { "`n" }
    $block = (Get-NeonProfileBlock $EntryPath) -replace "`n", $nl
    $pattern = '(?s)' + [regex]::Escape($script:ProfileBegin) + '.*?' + [regex]::Escape($script:ProfileEnd)
    if ($Text -match $pattern) {
        return @{ Text = ([regex]$pattern).Replace($Text, { param($m) $block }, 1); Mode = 'updated' }
    }
    # Vecchio profilo NEON scritto a mano: era interamente NEON, lo sostituisce il blocco
    if (Test-NeonLegacyProfile $Text) { return @{ Text = $block + $nl; Mode = 'migrated' } }
    if ([string]::IsNullOrWhiteSpace($Text)) { return @{ Text = $block + $nl; Mode = 'appended' } }
    # Una riga vuota di separazione: Remove-NeonProfileBlock la toglie insieme al blocco
    $sep = if ($Text -match '\r?\n$') { $nl } else { $nl + $nl }
    @{ Text = $Text + $sep + $block + $nl; Mode = 'appended' }
}

function Remove-NeonProfileBlock([string]$Text) {
    $pattern = '(?s)(\r?\n)?' + [regex]::Escape($script:ProfileBegin) + '.*?' + [regex]::Escape($script:ProfileEnd) + '(\r?\n)?'
    [regex]::Replace($Text, $pattern, '')
}

# ── Claude Code ─────────────────────────────────────────────────────────────

function Test-NeonStatusLine($Value) { $Value -is [Collections.IDictionary] -and "$($Value['command'])" -match 'neon-statusline' }

# Restituisce @{ Settings; Undo; Status } con Status = 'set' | 'kept' (status line di altri, non toccata)
function Set-NeonClaudeStatusLine($Settings, [string]$ScriptPath, $PreviousUndo) {
    $s = Copy-NeonValue $Settings
    if ($s -isnot [Collections.IDictionary]) { $s = [ordered]@{} }
    $current = if ($s.Contains('statusLine')) { $s.statusLine } else { $null }
    if ($current -and -not (Test-NeonStatusLine $current)) { return @{ Settings = $s; Undo = $PreviousUndo; Status = 'kept' } }
    # Percorso assoluto con le barre normali: funziona sia con la shell bash sia con cmd di Claude Code
    $value = [ordered]@{ type = 'command'; command = "node `"$($ScriptPath.Replace('\', '/'))`""; padding = 0; refreshInterval = 30 }
    $undo = [ordered]@{}
    if ($PreviousUndo) { foreach ($kv in (Copy-NeonValue $PreviousUndo).GetEnumerator()) { $undo[$kv.Key] = $kv.Value } }
    Save-NeonPrior $undo 'statusLine' $s $value
    $s.statusLine = $value
    @{ Settings = $s; Undo = $undo; Status = 'set' }
}

function Undo-NeonClaudeStatusLine($Settings, $Undo) {
    $s = Copy-NeonValue $Settings
    if ($Undo -and $Undo.Contains('statusLine')) { Restore-NeonPrior $s 'statusLine' $Undo.statusLine { param($v) Test-NeonStatusLine $v } }
    $s
}

# ── dipendenze ──────────────────────────────────────────────────────────────

# Command = eseguibile cercato nel PATH per capire se il componente c'è già
$script:Dependencies = @(
    [ordered]@{ Id = 'Microsoft.PowerShell';    Command = 'pwsh';       Why = 'PowerShell 7' }
    [ordered]@{ Id = 'JanDeDobbeleer.OhMyPosh'; Command = 'oh-my-posh'; Why = 'prompt' }
    [ordered]@{ Id = 'ajeetdsouza.zoxide';      Command = 'zoxide';     Why = 'z / zi' }
    [ordered]@{ Id = 'junegunn.fzf';            Command = 'fzf';        Why = 'Ctrl+R / Ctrl+T / Alt+C' }
    [ordered]@{ Id = 'sharkdp.bat';             Command = 'bat';        Why = 'previews' }
    [ordered]@{ Id = 'BurntSushi.ripgrep.MSVC'; Command = 'rg';         Why = 'rgf' }
)

function Get-NeonDependencies { $script:Dependencies | ForEach-Object { [pscustomobject]$_ } }

# Il frammento usa "JetBrainsMono NFM" (Nerd Font Mono), con Cascadia Mono come riserva
function Test-NeonFont {
    foreach ($k in 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts', 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts') {
        $p = Get-ItemProperty -Path $k -ErrorAction Ignore
        if ($p -and @($p.PSObject.Properties.Name -match '^JetBrainsMono NFM ').Count) { return $true }
    }
    $false
}

Export-ModuleMember -Function Get-NeonDefaultPaths, Find-NeonTerminalSettings, ConvertFrom-NeonJson, ConvertTo-NeonJson,
    Test-NeonJsonEqual, Merge-NeonTerminalSettings, Undo-NeonTerminalSettings, Get-NeonProfileBlock, Test-NeonLegacyProfile,
    Add-NeonProfileBlock, Remove-NeonProfileBlock, Set-NeonClaudeStatusLine, Undo-NeonClaudeStatusLine,
    Get-NeonDependencies, Test-NeonFont

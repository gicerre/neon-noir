# ── NEON NOIR · comandi rapidi ────────────────────────────────────────────
# Solo funzioni: nessun alias predefinito di PowerShell viene sovrascritto (gc, gl, gp, gps, ... restano invariati).
# `neon` mostra l'elenco completo.

# ── navigazione ──
function ..   { Set-Location .. }
function ...  { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
function ll   { Get-ChildItem -Force @args }
function mkcd { param([Parameter(Mandatory)][string]$Path) New-Item -ItemType Directory -Force -Path $Path | Set-Location }
function touch {
    param([Parameter(Mandatory)][string]$Path)
    if (Test-Path -LiteralPath $Path) { (Get-Item -LiteralPath $Path).LastWriteTime = Get-Date }
    else { New-Item -ItemType File -Path $Path | Out-Null }
}
function which { param([Parameter(Mandatory)][string]$Name) Get-Command $Name -All | Select-Object CommandType, Name, Version, Source }
function path  { $env:Path -split ';' | Where-Object { $_ } }

# ── editor / esplora risorse ──
# Usa $env:EDITOR se impostato, altrimenti VS Code
function vs   { param([string]$Path = '.') $ed = if ($env:EDITOR) { $env:EDITOR } else { 'code' }; & $ed $Path }
function open { param([string]$Path = '.') Invoke-Item -LiteralPath $Path }

# ── git ──
function gs   { git status -sb @args }
function gd   { git diff @args }
function gdc  { git diff --cached @args }
function glog { git log --graph --pretty=format:'%C(#39FF88)%h%Creset %C(#A472FF)%d%Creset %s %C(#55665F)· %an, %cr%Creset' --abbrev-commit -n 25 @args }
function gsw  { git switch @args }
function gbr  { git branch --sort=-committerdate --format='%(HEAD) %(color:#39FF88)%(refname:short)%(color:reset) %(color:#55665F)· %(committerdate:relative) · %(contents:subject)%(color:reset)' @args }
function gpull { git pull --ff-only @args }
function gpush { git push @args }

# ── docker (attive solo se docker è installato) ──
function dps { docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' @args }
function dlogs { param([Parameter(Mandatory)][string]$Container) docker logs -f --tail 200 $Container | hl }

# ── link cliccabili (OSC 8: Ctrl+clic in Windows Terminal) ──
function Format-NeonLink([string]$Url, [string]$Text = $Url) { "`e]8;;$Url`e\$Text`e]8;;`e\" }

# ── processi / porte ──
# Porte TCP in ascolto con processo e link http://localhost:<porta>. -All include i servizi di sistema.
function ports {
    param([switch]$All)
    $system = 'System', 'svchost', 'lsass', 'wininit', 'services', 'spoolsv', 'Idle'
    $rows = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Sort-Object LocalPort -Unique |
        ForEach-Object {
            $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
            [pscustomobject]@{ Port = $_.LocalPort; Address = $_.LocalAddress; Id = $_.OwningProcess; Name = if ($p) { $p.ProcessName } else { '?' } }
        } |
        Where-Object { $All -or ($_.Name -notin $system -and $_.Port -lt 49152) }
    if (-not $rows) { alert info (NeonText 'ports.none'); return }
    $x = "`e[0m"; $g = "`e[32m"; $c = "`e[36m"; $d = "`e[90m"; $t = "`e[39m"
    ''
    "  $d{0,-7} {1,-22} {2,-8} {3}$x" -f (NeonText 'ports.h.port'), (NeonText 'ports.h.proc'), (NeonText 'ports.h.pid'), (NeonText 'ports.h.link')
    foreach ($r in $rows) {
        $url = "http://localhost:$($r.Port)"
        $name = if ($r.Name.Length -gt 22) { $r.Name.Substring(0, 21) + '…' } else { $r.Name }
        "  $g{0,-7}$x $t{1,-22}$x $d{2,-8}$x $c{3}$x" -f ":$($r.Port)", $name, $r.Id, (Format-NeonLink $url)
    }
    ''
}
# Chiede sempre conferma prima di terminare il processo
function killport {
    param([Parameter(Mandatory)][int]$Port)
    $owners = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty OwningProcess -Unique
    if (-not $owners) { alert info ((NeonText 'killport.none') -f $Port); return }
    foreach ($id in $owners) { Get-Process -Id $id | Stop-Process -Confirm }
}
function topcpu { param([int]$N = 15) Get-Process | Sort-Object CPU -Descending | Select-Object -First $N Id, ProcessName, @{ n = 'CPU(s)'; e = { [math]::Round($_.CPU, 1) } }, @{ n = 'RAM(MB)'; e = { [math]::Round($_.WorkingSet64 / 1MB) } } | Format-Table -AutoSize }
function topmem { param([int]$N = 15) Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First $N Id, ProcessName, @{ n = 'RAM(MB)'; e = { [math]::Round($_.WorkingSet64 / 1MB) } }, @{ n = 'CPU(s)'; e = { [math]::Round($_.CPU, 1) } } | Format-Table -AutoSize }

# ── avvisi ──
# Stessa grafica degli errori di PowerShell, per script e comandi propri:
#   alert error "Build fallita" -Detail "3 test rossi"   ·   alert warn "..."   ·   alert info "..."   ·   alert ok "..."
# Scrive solo a schermo (Write-Host): non genera errori né cambia $? o gli exit code.
$NeonAlertStyles = @{
    error = @{ Pill = "`e[1;30;41m"; Icon = [char]0xf057; Label = (NeonText 'alert.error'); Text = "`e[91m"; Bar = "`e[31m" }
    warn  = @{ Pill = "`e[1;33;43m"; Icon = [char]0xf071; Label = (NeonText 'alert.warn'); Text = "`e[93m"; Bar = "`e[33m" }
    info  = @{ Pill = $null; Icon = [char]0xf05a; Label = $null; Text = "`e[39m"; Bar = "`e[36m" }
    ok    = @{ Pill = $null; Icon = [char]0xf058; Label = $null; Text = "`e[39m"; Bar = "`e[32m" }
}
function alert {
    param(
        [Parameter(Mandatory, Position = 0)][ValidateSet('error', 'warn', 'info', 'ok')][string]$Level,
        [Parameter(Mandatory, Position = 1)][string]$Message,
        [string]$Detail
    )
    $s = $NeonAlertStyles[$Level]; $x = "`e[0m"
    if ($s.Pill) { Write-Host "$($s.Pill) $($s.Icon) $($s.Label) $x $($s.Text)$Message$x" }
    else { Write-Host "$($s.Bar)$($s.Icon)$x $($s.Text)$Message$x" }
    if ($Detail) { foreach ($l in $Detail -split "`r?`n") { Write-Host "$($s.Bar)▌$x `e[37m$l$x" } }
}

# ── log ──
# Icona e colore per livello:  mvn spring-boot:run | hl   ·   npm run dev | hl   ·   python app.py 2>&1 | hl
# Riconosce Spring/Logback, Maven ([INFO] [WARNING] [ERROR]), npm (warn/error/ERR!), Python (Traceback).
filter hl {
    $l = "$_"; $x = "`e[0m"
    $lvl = if ($l -match '^\s+(at |\.\.\. \d+ more|File ")|^Caused by:') { 'stack' }
        elseif ($l -match 'BUILD SUCCESS|Started \S+ in [\d.,]+ seconds|Tests run:.*Failures: 0, Errors: 0') { 'ok' }
        elseif ($l -match 'BUILD FAILURE|Traceback \(most recent call last\)') { 'error' }
        elseif ($l -match '(?<![\w])(FATAL|SEVERE|ERROR|ERR!|FAILURE|FAILED|WARNING|WARN|INFO|DEBUG|TRACE|SUCCESS|PASSED)(?![\w])') {
            switch -Regex ($Matches[1]) {
                '^(FATAL|SEVERE|ERROR|ERR!|FAILURE|FAILED)$' { 'error'; break }
                '^WARN'                                      { 'warn'; break }
                '^INFO$'                                     { 'info'; break }
                '^(DEBUG|TRACE)$'                            { 'debug'; break }
                default                                      { 'ok' }
            }
        }
        elseif ($l -match 'Exception\b') { 'error' }
        else { '' }
    # URL cliccabili + link al server appena avviato ("Tomcat started on port 8080")
    $l = [regex]::Replace($l, 'https?://[^\s"''<>)\]]+', { param($m) Format-NeonLink $m.Value })
    if ($l -match '(?:Tomcat|Netty|Jetty|Undertow) started on port(?:\(s\))?:? (\d+)') {
        $l += "  `e[36m→ $(Format-NeonLink "http://localhost:$($Matches[1])")$x"
    }
    switch ($lvl) {
        'error' { "`e[31m$([char]0xf057) `e[91m$l$x" }
        'warn'  { "`e[33m$([char]0xf071) `e[93m$l$x" }
        'info'  { "`e[36m$([char]0xf05a)$x $l" }
        'debug' { "`e[90m$([char]0xf188) $l$x" }
        'ok'    { "`e[32m$([char]0xf058) $l$x" }
        'stack' { "`e[31m▏ $l$x" }
        default { "  $l" }
    }
}
# Segue un file di log in tempo reale, colorato
function tailf {
    param([Parameter(Mandatory)][string]$Path, [int]$Tail = 50)
    Get-Content -LiteralPath $Path -Tail $Tail -Wait | hl
}

# ── NEON ──
function banner {
    if (-not (Get-Command Show-NeonBanner -ErrorAction SilentlyContinue)) { . (Join-Path $NeonHome 'banner.ps1') }
    Show-NeonBanner -NoAnimation
}

function Show-NeonHelp {
    $g = "`e[32m"; $c = "`e[36m"; $d = "`e[90m"; $r = "`e[0m"
    $rows = @(
        @('', 'help.s.shell'),
        @('Ctrl+R', 'help.ctrlr'), @('Ctrl+T', 'help.ctrlt'), @('Alt+C', 'help.altc'),
        @('↑ / ↓', 'help.arrows'), @('Ctrl+→', 'help.ctrlright'), @('z <dir>', 'help.z'),
        @('', 'help.s.cmd'),
        @('gs gd gdc glog', 'help.git'), @('gsw gbr', 'help.gsw'), @('gpull gpush', 'help.gpull'),
        @('vs [path]', 'help.vs'), @('open [path]', 'help.open'),
        @('ll mkcd touch', 'help.ll'), @('which path', 'help.which'),
        @('', 'help.s.proj'),
        @('run  test  build', 'help.run'), @('dirty [-All]', 'help.dirty'), @('rgf [text]', 'help.rgf'),
        @('', 'help.s.tools'),
        @('ports  killport <n>', 'help.ports'), @('topcpu topmem', 'help.top'),
        @('<cmd> | hl', 'help.hl'), @('tailf <file>', 'help.tailf'), @('alert <level> <msg>', 'help.alert'),
        @('', 'help.s.look'),
        @('cinema  ·  Ctrl+Alt+C', 'help.cinema'), @('cinema --mode', 'help.cinemamode'),
        @('neon title <text>', 'help.title'), @('neon config', 'help.config'),
        @('banner', 'help.banner'), @('clear / cls', 'help.clear'), @('F12', 'help.f12'),
        @('', 'help.s.wt'),
        @('Alt+Shift+→ / ↓', 'help.split'), @('Alt+arrows', 'help.focus'), @('Ctrl+Shift+Z', 'help.zoom'),
        @('Ctrl+Alt+↑ / ↓', 'help.marks'), @('Ctrl+Shift+F', 'help.find'), @('Ctrl+Shift+S', 'help.export'),
        @('Ctrl+Shift+K', 'help.clearbuf'), @('Ctrl+Alt+D / A / N', 'help.tabs'), @('Ctrl+Shift+Enter', 'help.focusmode')
    )
    ''
    foreach ($row in $rows) {
        if (-not $row[0]) { "  $d── $c$(NeonText $row[1])$r"; continue }
        "  $g{0,-22}$r {1}" -f $row[0], (NeonText $row[1])
    }
    ''
}

# neon               guida rapida
# neon title <testo>  scritta dell'intestazione (neon title --reset = predefinita)
# neon config        preferenze attuali e file in cui sono salvate
function neon {
    param([Parameter(Position = 0)][string]$Command, [Parameter(Position = 1, ValueFromRemainingArguments)][string[]]$Rest)
    switch ($Command) {
        { -not $_ -or $_ -eq 'help' } { Show-NeonHelp; return }
        'title'  { Set-NeonTitle ($Rest -join ' '); return }
        'config' { Show-NeonConfig; return }
        default  { alert error ((NeonText 'neon.unknown') -f $Command) -Detail (NeonText 'neon.usage') }
    }
}

# Il font pixel del banner ha lettere A-Z, cifre, spazio e - _ . /
function Set-NeonTitle([string]$Text) {
    $Text = "$Text".Trim()
    if (-not $Text) { alert info ((NeonText 'title.current') -f $NeonConfig.Title) -Detail (NeonText 'title.usage'); return }
    $user = Get-NeonUserConfig
    if ($Text -eq '--reset') {
        $user.Remove('Title')
        Save-NeonUserConfig $user
        $NeonConfig.Title = $NeonDefaults.Title
        alert ok ((NeonText 'title.reset') -f $NeonDefaults.Title)
    } else {
        $upper = $Text.ToUpperInvariant()
        $bad = ($upper.ToCharArray() | Where-Object { "$_" -cnotmatch '^[A-Z0-9 \-_./]$' } | Select-Object -Unique) -join ' '
        if ($bad) { alert error ((NeonText 'title.invalid') -f $bad) -Detail (NeonText 'title.allowed'); return }
        $user['Title'] = $upper
        Save-NeonUserConfig $user
        $NeonConfig.Title = $upper
        alert ok ((NeonText 'title.saved') -f $upper)
        if ($upper.Length -gt 16) { alert warn ((NeonText 'title.long') -f $upper.Length) }
    }
    if (Get-Command Show-NeonBanner -ErrorAction Ignore) { Show-NeonBanner -NoAnimation }
}

function Show-NeonConfig {
    $user = Get-NeonUserConfig
    $g = "`e[32m"; $c = "`e[36m"; $d = "`e[90m"; $r = "`e[0m"
    ''
    "  $c$((NeonText 'config.path') -f $NeonConfigPath)$r" + $(if (-not (Test-Path $NeonConfigPath)) { " $d$(NeonText 'config.none')$r" } else { '' })
    ''
    foreach ($k in $NeonDefaults.Keys) {
        $v = $NeonConfig[$k]
        $shown = if ($v -is [bool]) { "$v".ToLower() } elseif ("$v" -eq '') { '—' } else { "$v" }
        $src = if ($user.ContainsKey($k)) { "$g$(NeonText 'config.yours')$r" } else { "$d$(NeonText 'config.default')$r" }
        "  $g{0,-14}$r {1,-28} {2}" -f $k, $shown, $src
    }
    ''
}

Register-ArgumentCompleter -CommandName neon -ParameterName Command -ScriptBlock {
    param($cmd, $param, $word)
    'title', 'config', 'help' | Where-Object { $_ -like "$word*" } | ForEach-Object { [Management.Automation.CompletionResult]::new($_) }
}
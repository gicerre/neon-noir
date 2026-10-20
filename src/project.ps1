# ── NEON NOIR · progetti ───────────────────────────────────────────────────
# run / test / build: riconoscono il progetto (risalendo dalla directory corrente) e lanciano il comando giusto.
#   Maven · Gradle (wrapper se presente) · Node (npm/pnpm/yarn/bun dal lockfile) · Python (uv/poetry/.venv)
#   Argomenti extra passati al tool:  run -Dspring-boot.run.profiles=dev   ·   test -- --watch
# dirty: stato git di tutti i repository in $NeonConfig.ProjectsRoot.

function Find-NeonProject {
    $dir = (Get-Location).ProviderPath
    while ($dir) {
        $has = { param($n) Test-Path -LiteralPath (Join-Path $dir $n) }
        $kind = if (& $has 'pom.xml') { 'maven' }
            elseif ((& $has 'build.gradle') -or (& $has 'build.gradle.kts')) { 'gradle' }
            elseif (& $has 'package.json') { 'node' }
            elseif ((& $has 'pyproject.toml') -or (& $has 'requirements.txt') -or (& $has 'manage.py') -or (& $has 'setup.py')) { 'python' }
        if ($kind) { return [pscustomobject]@{ Root = $dir; Kind = $kind; Name = Split-Path $dir -Leaf } }
        $parent = Split-Path $dir -Parent
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
    $null
}

# Restituisce @{ Exe; Args; Logs } per l'azione richiesta, oppure una stringa con l'errore
function Get-NeonProjectCommand($p, [string]$Action) {
    $at = { param($n) Join-Path $p.Root $n }
    switch ($p.Kind) {
        'maven' {
            $exe = if (Test-Path (& $at 'mvnw.cmd')) { & $at 'mvnw.cmd' } else { 'mvn' }
            $spring = (Get-Content (& $at 'pom.xml') -Raw) -match 'spring-boot'
            $goal = switch ($Action) {
                'run'   { if ($spring) { 'spring-boot:run' } else { return (NeonText 'proj.mvn.norun') } }
                'test'  { 'test' }
                'build' { 'package' }
            }
            return @{ Exe = $exe; Args = @($goal); Logs = $true }
        }
        'gradle' {
            $exe = if (Test-Path (& $at 'gradlew.bat')) { & $at 'gradlew.bat' } else { 'gradle' }
            $build = Get-Content (Get-ChildItem $p.Root -Filter 'build.gradle*' | Select-Object -First 1).FullName -Raw
            $task = switch ($Action) { 'run' { if ($build -match 'org\.springframework\.boot') { 'bootRun' } else { 'run' } } 'test' { 'test' } 'build' { 'build' } }
            return @{ Exe = $exe; Args = @($task); Logs = $true }
        }
        'node' {
            $pm = if (Test-Path (& $at 'pnpm-lock.yaml')) { 'pnpm' }
                elseif (Test-Path (& $at 'yarn.lock')) { 'yarn' }
                elseif ((Test-Path (& $at 'bun.lockb')) -or (Test-Path (& $at 'bun.lock'))) { 'bun' }
                else { 'npm' }
            $scripts = (Get-Content (& $at 'package.json') -Raw | ConvertFrom-Json).scripts
            $names = if ($scripts) { $scripts.PSObject.Properties.Name } else { @() }
            $wanted = switch ($Action) { 'run' { 'dev', 'start', 'serve' } 'test' { 'test' } 'build' { 'build' } }
            $script = $wanted | Where-Object { $_ -in $names } | Select-Object -First 1
            if (-not $script) { return ((NeonText 'proj.node.noscript') -f ($wanted -join ' / '), ($names -join ', ')) }
            return @{ Exe = $pm; Args = @('run', $script); Logs = $false }
        }
        'python' {
            $prefix = if (Test-Path (& $at 'uv.lock')) { @('uv', 'run') }
                elseif (Test-Path (& $at 'poetry.lock')) { @('poetry', 'run') }
                elseif (Test-Path (& $at '.venv\Scripts\python.exe')) { @((& $at '.venv\Scripts\python.exe')) }
                else { @('python') }
            $py = if ($prefix[0] -in 'uv', 'poetry') { $prefix + 'python' } else { $prefix }
            $cmd = switch ($Action) {
                'run' {
                    if (Test-Path (& $at 'manage.py')) { $py + 'manage.py', 'runserver' }
                    elseif ($entry = 'main.py', 'app.py' | Where-Object { Test-Path (& $at $_) } | Select-Object -First 1) { $py + $entry }
                    else { return (NeonText 'proj.py.norun') }
                }
                'test'  { $py + '-m', 'pytest' }
                'build' {
                    if ($prefix[0] -in 'uv', 'poetry') { @($prefix[0], 'build') }
                    elseif (Test-Path (& $at 'pyproject.toml')) { $py + '-m', 'build' }
                    else { return (NeonText 'proj.py.nobuild') }
                }
            }
            return @{ Exe = $cmd[0]; Args = @($cmd | Select-Object -Skip 1); Logs = $false }
        }
    }
}

function Invoke-NeonProject([string]$Action, [object[]]$Extra) {
    $p = Find-NeonProject
    if (-not $p) { alert error (NeonText 'proj.none') -Detail (NeonText 'proj.none.detail'); return }
    $c = Get-NeonProjectCommand $p $Action
    if ($c -is [string]) { alert error ((NeonText 'proj.unavailable') -f $Action, $p.Name, $p.Kind) -Detail $c; return }

    $argv = @($c.Args) + @($Extra | Where-Object { $null -ne $_ })
    alert info "$($p.Name) · $($p.Kind)  →  $(Split-Path $c.Exe -Leaf) $($argv -join ' ')"
    $sw = [Diagnostics.Stopwatch]::StartNew()
    Push-Location -LiteralPath $p.Root
    try {
        # Maven/Gradle passano da `hl` (icone per livello); Node/Python restano sul terminale (colori e input interattivo)
        if ($c.Logs) { & $c.Exe @argv 2>&1 | hl } else { & $c.Exe @argv }
        $code = $LASTEXITCODE
    } finally { Pop-Location }
    $t = if ($sw.Elapsed.TotalMinutes -ge 1) { '{0}m {1}s' -f $sw.Elapsed.Minutes, $sw.Elapsed.Seconds } else { '{0:N1}s' -f $sw.Elapsed.TotalSeconds }
    if ($code -eq 0) { alert ok ((NeonText 'proj.done') -f $Action, $t) } else { alert error ((NeonText 'proj.failed') -f $Action, $code, $t) }
    $global:LASTEXITCODE = $code
}

function run   { Invoke-NeonProject 'run' $args }
function test  { Invoke-NeonProject 'test' $args }
function build { Invoke-NeonProject 'build' $args }

# ── dirty: repository con lavoro in sospeso ──
# Mostra modifiche, file non tracciati, commit da pushare/scaricare. -All include i repository puliti.
function dirty {
    param([string]$Root = $NeonConfig.ProjectsRoot, [switch]$All)
    if (-not $Root) { $Root = (Get-Location).ProviderPath }
    $repos = Get-ChildItem -LiteralPath $Root -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName '.git') }
    if (-not $repos) { alert info ((NeonText 'dirty.none') -f $Root); return }

    $state = $repos | ForEach-Object -ThrottleLimit 8 -Parallel {
        $d = $_.FullName
        $out = git -C $d --no-optional-locks status --porcelain=v2 --branch 2>$null
        $r = [ordered]@{ Name = $_.Name; Path = $d; Branch = '?'; Changed = 0; Untracked = 0; Ahead = 0; Behind = 0; Upstream = $false; Last = '' }
        foreach ($l in $out) {
            if ($l -like '# branch.head *') { $r.Branch = $l.Substring(14) }
            elseif ($l -like '# branch.upstream *') { $r.Upstream = $true }
            elseif ($l -match '^# branch\.ab \+(\d+) -(\d+)') { $r.Ahead = [int]$Matches[1]; $r.Behind = [int]$Matches[2] }
            elseif ($l -like '? *') { $r.Untracked++ }
            elseif ($l -match '^[12u] ') { $r.Changed++ }
        }
        $r.Last = git -C $d log -1 --format=%cr 2>$null
        [pscustomobject]$r
    }

    $x = "`e[0m"; $g = "`e[32m"; $y = "`e[33m"; $p = "`e[35m"
    $c = "`e[36m"; $d = "`e[90m"; $t = "`e[39m"; $r = "`e[31m"
    $pending = @($state | Where-Object { $_.Changed -or $_.Untracked -or $_.Ahead -or $_.Behind -or -not $_.Upstream })
    $show = if ($All) { $state } else { $pending }
    $w = [math]::Max(12, ($show | ForEach-Object { $_.Name.Length } | Measure-Object -Maximum).Maximum)

    ''
    "  $c$([char]0xf1d3)$x $t$((NeonText 'dirty.summary') -f $pending.Count, $state.Count)$x $d· $Root$x"
    ''
    foreach ($s in ($show | Sort-Object @{ e = { -($_.Changed + $_.Untracked + $_.Ahead + $_.Behind) } }, Name)) {
        $clean = -not ($s.Changed -or $s.Untracked -or $s.Ahead -or $s.Behind)
        $icon = if ($clean -and $s.Upstream) { "$g$([char]0xf058)$x" } elseif ($s.Changed) { "$y$([char]0xf044)$x" } else { "$p$([char]0xf0ee)$x" }
        $name = Format-NeonLink "file:///$($s.Path -replace '\\', '/')" $s.Name
        $info = @()
        if ($s.Changed)   { $info += "$y$((NeonText 'dirty.changed') -f $s.Changed)$x" }
        if ($s.Untracked) { $info += "$y$((NeonText 'dirty.untracked') -f $s.Untracked)$x" }
        if ($s.Ahead)     { $info += "$p$((NeonText 'dirty.ahead') -f $s.Ahead)$x" }
        if ($s.Behind)    { $info += "$p$((NeonText 'dirty.behind') -f $s.Behind)$x" }
        if (-not $s.Upstream) { $info += "$r$(NeonText 'dirty.noupstream')$x" }
        if (-not $info)   { $info += "$g$(NeonText 'dirty.clean')$x" }
        "  $icon $t$name$x$(' ' * ($w - $s.Name.Length))  $g$($s.Branch)$x  $($info -join "$d · $x")  $d$($s.Last)$x"
    }
    ''
}

# ── NEON NOIR · schermata iniziale ─────────────────────────────────────────
# Font pixel 5×5 disegnato a mano, reso con blocchi pieni e ombra diagonale.
# Nessuna chiamata lenta (CIM/WMI): solo registro, .NET e una chiamata git se la cartella è un repository.

$NeonGlyphs = @{
    'A' = ' ### ', '#   #', '#####', '#   #', '#   #'
    'B' = '#### ', '#   #', '#### ', '#   #', '#### '
    'C' = ' ####', '#    ', '#    ', '#    ', ' ####'
    'D' = '#### ', '#   #', '#   #', '#   #', '#### '
    'E' = '#####', '#    ', '#### ', '#    ', '#####'
    'F' = '#####', '#    ', '#### ', '#    ', '#    '
    'G' = ' ####', '#    ', '#  ##', '#   #', ' ####'
    'H' = '#   #', '#   #', '#####', '#   #', '#   #'
    'I' = '#####', '  #  ', '  #  ', '  #  ', '#####'
    'J' = '#####', '   # ', '   # ', '#  # ', ' ##  '
    'K' = '#   #', '#  # ', '###  ', '#  # ', '#   #'
    'L' = '#    ', '#    ', '#    ', '#    ', '#####'
    'M' = '#   #', '## ##', '# # #', '#   #', '#   #'
    'N' = '#   #', '##  #', '# # #', '#  ##', '#   #'
    'O' = ' ### ', '#   #', '#   #', '#   #', ' ### '
    'P' = '#### ', '#   #', '#### ', '#    ', '#    '
    'Q' = ' ### ', '#   #', '# # #', '#  # ', ' ## #'
    'R' = '#### ', '#   #', '#### ', '#  # ', '#   #'
    'S' = ' ####', '#    ', ' ### ', '    #', '#### '
    'T' = '#####', '  #  ', '  #  ', '  #  ', '  #  '
    'U' = '#   #', '#   #', '#   #', '#   #', ' ### '
    'V' = '#   #', '#   #', '#   #', ' # # ', '  #  '
    'W' = '#   #', '#   #', '# # #', '## ##', '#   #'
    'X' = '#   #', ' # # ', '  #  ', ' # # ', '#   #'
    'Y' = '#   #', ' # # ', '  #  ', '  #  ', '  #  '
    'Z' = '#####', '   # ', '  #  ', ' #   ', '#####'
    '0' = ' ### ', '#  ##', '# # #', '##  #', ' ### '
    '1' = '  #  ', ' ##  ', '  #  ', '  #  ', ' ### '
    '2' = ' ### ', '#   #', '  ## ', ' #   ', '#####'
    '3' = '#### ', '    #', ' ### ', '    #', '#### '
    '4' = '#   #', '#   #', '#####', '    #', '    #'
    '5' = '#####', '#    ', '#### ', '    #', '#### '
    '6' = ' ### ', '#    ', '#### ', '#   #', ' ### '
    '7' = '#####', '    #', '   # ', '  #  ', '  #  '
    '8' = ' ### ', '#   #', ' ### ', '#   #', ' ### '
    '9' = ' ### ', '#   #', ' ####', '    #', ' ### '
    '-' = '     ', '     ', ' ### ', '     ', '     '
    '_' = '     ', '     ', '     ', '     ', '#####'
    '.' = '     ', '     ', '     ', '     ', '  #  '
    '/' = '    #', '   # ', '  #  ', ' #   ', '#    '
    ' ' = '   ', '   ', '   ', '   ', '   '
}

function Get-NeonBitmap([string]$Text) {
    $rows = @('', '', '', '', '')
    foreach ($ch in $Text.ToUpperInvariant().ToCharArray()) {
        $g = $NeonGlyphs["$ch"]
        if (-not $g) { $g = $NeonGlyphs['-'] }
        for ($r = 0; $r -lt 5; $r++) { $rows[$r] += $g[$r] + ' ' }
    }
    $rows
}

function ConvertTo-NeonRgb([string]$Hex) {
    $h = $Hex.TrimStart('#')
    '{0};{1};{2}' -f [Convert]::ToInt32($h.Substring(0, 2), 16), [Convert]::ToInt32($h.Substring(2, 2), 16), [Convert]::ToInt32($h.Substring(4, 2), 16)
}

# Righe ANSI dell'ASCII art: pieno con gradiente verde→ciano, ombra viola sfalsata di (1,1)
function Get-NeonLogo([string]$Text) {
    $bmp = Get-NeonBitmap $Text
    $w = $bmp[0].Length + 1
    $grad = '#39FF88', '#2EF09A', '#22E4AF', '#1CDCC2', '#18D6D0', '#18D6D0'
    $shadow = "`e[38;2;$(ConvertTo-NeonRgb '#3D2A6B')m"
    $lines = for ($r = 0; $r -lt 6; $r++) {
        $fill = "`e[38;2;$(ConvertTo-NeonRgb $grad[$r])m"
        $sb = [Text.StringBuilder]::new('  ')
        for ($c = 0; $c -lt $w; $c++) {
            $on  = $r -lt 5 -and $c -lt $bmp[0].Length -and $bmp[$r][$c] -eq '#'
            $sh  = $r -gt 0 -and $c -gt 0 -and $bmp[$r - 1][$c - 1] -eq '#'
            if ($on)     { [void]$sb.Append($fill).Append([char]0x2588) }
            elseif ($sh) { [void]$sb.Append($shadow).Append([char]0x2592) }
            else         { [void]$sb.Append(' ') }
        }
        [void]$sb.Append("`e[0m")
        $sb.ToString()
    }
    [pscustomobject]@{ Lines = $lines; Width = $w + 2 }
}

function Get-NeonGitSummary {
    # Cerca .git risalendo le cartelle (solo filesystem) prima di invocare git
    $dir = (Get-Location).ProviderPath
    while ($dir -and -not (Test-Path -LiteralPath (Join-Path $dir '.git'))) { $dir = Split-Path $dir -Parent }
    if (-not $dir) { return $null }

    $out = git --no-optional-locks status --porcelain=v2 --branch 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    $branch = 'detached'; $ahead = 0; $behind = 0; $changed = 0; $untracked = 0
    foreach ($l in $out) {
        if ($l -like '# branch.head *') { $branch = $l.Substring(14) }
        elseif ($l -match '^# branch\.ab \+(\d+) -(\d+)') { $ahead = [int]$Matches[1]; $behind = [int]$Matches[2] }
        elseif ($l -like '? *') { $untracked++ }
        elseif ($l -match '^[12u] ') { $changed++ }
    }
    [pscustomobject]@{ Repo = Split-Path $dir -Leaf; Branch = $branch; Ahead = $ahead; Behind = $behind; Changed = $changed; Untracked = $untracked }
}

function Show-NeonBanner {
    param([switch]$NoAnimation)

    $G = "`e[32m"; $C = "`e[36m"; $P = "`e[35m"
    $Y = "`e[33m"; $T = "`e[39m"; $D = "`e[90m"; $X = "`e[0m"

    # Animazione: per default solo alla prima sessione del giorno (~0,2 s), mai se disattivata
    $animate = $false
    if (-not $NoAnimation -and -not $env:NEON_NO_ANIM) {
        $mode = if ($NeonConfig.Animate) { $NeonConfig.Animate } else { 'daily' }
        if ($mode -eq 'always') { $animate = $true }
        elseif ($mode -eq 'daily') {
            $stamp = Join-Path $env:LOCALAPPDATA 'neon\last-anim.txt'
            $today = (Get-Date).ToString('yyyy-MM-dd')
            $last = if (Test-Path $stamp) { (Get-Content $stamp -Raw).Trim() } else { '' }
            if ($last -ne $today) {
                $animate = $true
                New-Item -ItemType Directory -Force (Split-Path $stamp) | Out-Null
                Set-Content -Path $stamp -Value $today -Encoding utf8
            }
        }
    }

    $width = try { $Host.UI.RawUI.WindowSize.Width } catch { 120 }
    $title = if ($NeonConfig.Title) { $NeonConfig.Title } else { 'NEON NOIR' }
    $logo = Get-NeonLogo $title

    # ── dati ambiente ──
    $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
    $build = [Environment]::OSVersion.Version.Build
    $osName = if ($build -ge 22000) { $cv.ProductName -replace 'Windows 10', 'Windows 11' } else { $cv.ProductName }
    $os = "$osName $($cv.DisplayVersion) · build $build.$($cv.UBR)"
    # Lettura diretta del singolo valore: Get-ItemProperty fallisce sui valori binari di questa chiave
    $cpu = "$([Microsoft.Win32.Registry]::GetValue('HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\System\CentralProcessor\0', 'ProcessorNameString', ''))"
    $cpu = ($cpu -replace '\s+', ' ' -replace '\(R\)|\(TM\)|\s*\d+-Core Processor|\s*CPU @.*', '').Trim()
    $ramGB = [math]::Round([GC]::GetGCMemoryInfo().TotalAvailableMemoryBytes / 1GB)
    $up = [TimeSpan]::FromMilliseconds([Environment]::TickCount64)
    $uptime = if ($up.Days) { "{0}$(NeonText 'unit.day') {1}h {2}m" -f $up.Days, $up.Hours, $up.Minutes } else { '{0}h {1}m' -f $up.Hours, $up.Minutes }
    $psrl = (Get-Module PSReadLine).Version

    $tools = 'git', 'node', 'python', 'java', 'mvn', 'docker', 'claude'
    $found = @{}
    # Un solo passaggio sul PATH con File.Exists: molto più rapido di Get-Command per i tool assenti
    $dirs = $env:Path -split ';' | Where-Object { $_ }
    # (attenzione: le variabili PowerShell ignorano le maiuscole, $tool non deve chiamarsi $t come il colore $T)
    foreach ($tool in $tools) {
        $found[$tool] = $false
        foreach ($dir in $dirs) {
            if ([IO.File]::Exists("$dir\$tool.exe") -or [IO.File]::Exists("$dir\$tool.cmd") -or [IO.File]::Exists("$dir\$tool.ps1")) { $found[$tool] = $true; break }
        }
    }
    $toolLine = ($tools | ForEach-Object { if ($found[$_]) { "$G$_$X" } else { "$D$_$X" } }) -join "$D · $X"

    $git = Get-NeonGitSummary

    # ── output ──
    $sep = "$D  " + ([string][char]0x2500 * [math]::Min(72, $width - 4)) + $X
    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add('')
    if ($logo.Width -le $width) { $logo.Lines | ForEach-Object { $lines.Add($_) } }
    else { $lines.Add("  $G$([char]0x2588)$X $T$title$X") }
    $tag = "  $D//$X ${P}NEON NOIR$X $D·$X ${T}dev station$X $D·$X ${C}session online$X"
    $lines.Add('')
    $lines.Add($tag)
    $lines.Add($sep)

    $kv = {
        param($k, $v)
        "  $C$([char]0x25B8)$X $D{0,-9}$X $T{1}$X" -f $k, $v
    }
    $lines.Add((& $kv 'host' "$env:COMPUTERNAME $D·$T $os"))
    $lines.Add((& $kv 'shell' "PowerShell $($PSVersionTable.PSVersion) $D·$T PSReadLine $psrl"))
    $lines.Add((& $kv 'core' "$cpu $D·$T $ramGB GB RAM $D·$T uptime $uptime"))
    $lines.Add((& $kv 'toolchain' $toolLine))
    if ($git) {
        $state = if ($git.Changed + $git.Untracked -eq 0) { "$G$(NeonText 'banner.clean')$X" } else { "$Y$((NeonText 'banner.changed') -f $git.Changed)$X$D,$X $Y$((NeonText 'banner.untracked') -f $git.Untracked)$X" }
        $sync = @()
        if ($git.Ahead) { $sync += "$P↑$($git.Ahead)$X" }
        if ($git.Behind) { $sync += "$P↓$($git.Behind)$X" }
        $lines.Add((& $kv 'git' ("$($git.Repo) $D·$X $G$($git.Branch)$X $D·$X $state" + $(if ($sync) { " $D·$X " + ($sync -join ' ') }))))
    }
    $lines.Add($sep)
    $lines.Add("  ${D}neon$X ${T}$(NeonText 'banner.f.neon')$X  $D·$X  ${D}Ctrl+R$X ${T}$(NeonText 'banner.f.history')$X  $D·$X  ${D}Ctrl+T$X ${T}$(NeonText 'banner.f.files')$X  $D·$X  ${D}z$X ${T}$(NeonText 'banner.f.jump')$X" +
        $(if (Get-Command coding -ErrorAction Ignore) { "  $D·$X  ${D}coding$X ${T}$(NeonText 'banner.f.projects')$X" }))

    # [Console]::Write usa la codifica della console (spesso cp850, senza ▸): UTF-8 solo per il banner
    $prevEncoding = [Console]::OutputEncoding
    try {
    [Console]::OutputEncoding = [Text.Encoding]::UTF8
    if ($animate) {
        # Riga per riga, poi "decodifica" breve del tagline: ~0,2 s in totale
        $logoCount = if ($logo.Width -le $width) { 7 } else { 2 }
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -eq $tag) {
                $plain = '// NEON NOIR · dev station · session online'
                $noise = '!<>-_\/[]{}=+*^?#01'.ToCharArray()
                for ($f = 0; $f -lt 6; $f++) {
                    $chars = $plain.ToCharArray() | ForEach-Object -Begin { $k = 0 } -Process {
                        $k++; if ($k -le ($plain.Length * $f / 6) -or $_ -eq ' ') { $_ } else { $noise[(Get-Random -Maximum $noise.Length)] }
                    }
                    [Console]::Write("`r  $G$(-join $chars)$X")
                    Start-Sleep -Milliseconds 18
                }
                [Console]::Write("`r`e[2K")
                [Console]::WriteLine($tag)
                continue
            }
            [Console]::WriteLine($lines[$i])
            if ($i -lt $logoCount) { Start-Sleep -Milliseconds 12 }
        }
    } else {
        [Console]::WriteLine(($lines -join "`n"))
    }
    } finally { [Console]::OutputEncoding = $prevEncoding }
}

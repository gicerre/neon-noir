# ── NEON NOIR · modalità cinema ─────────────────────────────────────────────
#   cinema          accende la modalità predefinita (neon) o spegne se attiva · anche Ctrl+Alt+C
#   cinema --mode   menu con le frecce: anteprima dal vivo, Invio conferma, Esc annulla
# Ogni modalità è un insieme di #define anteposti a cinema.hlsl; lo shader generato ha un nome che
# cambia con il contenuto, così Windows Terminal lo ricarica sempre.

# Scheme = schema colore di Windows Terminal applicato insieme allo shader ($null = Neon Noir, quello di base).
# Gli schemi danno a ogni categoria di testo un colore proprio; lo shader aggiunge l'atmosfera.
$NeonCinemaModes = [ordered]@{
    'neon' = @{
        Anim = $false; Scheme = $null
        Defines = @{ GLOW_STRENGTH = 1.1; GLOW_SPREAD = 2.2; SCANLINE_PX = 3.0; SCANLINE_DIM = 0.22; VIGNETTE = 0.95; TINT = 'float3(0.0, 0.022, 0.012)' }
    }
    'tv' = @{
        Anim = $false; Scheme = $null
        Defines = @{ SAFE_AREA = 0.05; CURVE = 0.03; SHADOW_MASK = 1; SHADOW_MASK_AMOUNT = 0.35; BEZEL = 1; BEZEL_SIZE = 0.02; BEZEL_RADIUS = 0.04; GLOW_STRENGTH = 1.0; GLOW_SPREAD = 2.0; SCANLINE_PX = 3.0; SCANLINE_DIM = 0.22; CHROMA_PX = 0.6; NOISE = 0.03; CONTRAST = 1.08; DESAT = 0.15; VIGNETTE = 0.9; TINT = 'float3(0.010, 0.010, 0.015)' }
    }
    'matrix' = @{
        Anim = $true; Scheme = 'NEON Matrix'
        Defines = @{ GLOW_STRENGTH = 1.0; GLOW_SPREAD = 2.2; MATRIX_RAIN = 1; RAIN_CELL = 11.0; RAIN_COLOR = 'float3(0.10, 0.90, 0.35)'; RAIN_STRENGTH = 0.45; HALO = 1.0; SCANLINE_PX = 3.0; SCANLINE_DIM = 0.12; VIGNETTE = 1.0; TINT = 'float3(0.0, 0.018, 0.006)' }
    }
    'amber' = @{
        Anim = $true; Scheme = 'NEON Amber'
        Defines = @{ PHOSPHOR_TRAIL = 1; ROLL_BAR = 1; ROLL_SPEED = 0.035; ROLL_DIM = 0.14; GLOW_STRENGTH = 1.0; GLOW_SPREAD = 2.2; CURVE = 0.02; SCANLINE_PX = 3.0; SCANLINE_DIM = 0.22; VIGNETTE = 1.0; TINT = 'float3(0.020, 0.010, 0.0)' }
    }
    'star-wars' = @{
        Anim = $true; Scheme = 'NEON Star Wars'
        Defines = @{ CRAWL = 1; CRAWL_START = 0.45; CRAWL_TILT = 0.9; CRAWL_SPEED = 0.035; CRAWL_GAP = 0.30; CRAWL_FAR_TINT = 'float3(1.00, 0.60, 0.25)'; STARS = 1.4; NEBULA = 1; NEBULA_COLOR = 'float3(0.18, 0.08, 0.34)'; GALAXY = 1; TIE = 1; GLOW_STRENGTH = 0.8; GLOW_SPREAD = 2.0; CONTRAST = 1.05; VIGNETTE = 0.5 }
    }
    'hologram' = @{
        Anim = $true; Scheme = 'NEON Hologram'
        Defines = @{ MONO = 0.2; MONO_COLOR = 'float3(0.45, 0.80, 1.00)'; MONO_GAIN = 1.1; EDGE_GLOW = 1; EDGE_STRENGTH = 0.5; EDGE_COLOR = 'float3(0.25, 0.65, 1.00)'; HOLO_BEAM = 1; HOLO_TOP = 0.55; GLITCH = 1; GLITCH_SLICES = 28.0; GLITCH_RATE = 3.0; GLITCH_AMOUNT = 0.025; GLOW_STRENGTH = 1.0; GLOW_SPREAD = 2.4; SCANLINE_PX = 2.0; SCANLINE_DIM = 0.22; CHROMA_PX = 0.6; VIGNETTE = 0.8; USE_ANIM = 1; BAND_SPEED = 0.08; BAND_JITTER = 1.5; BAND_GLOW = 0.18; BAND_COLOR = 'float3(0.35, 0.75, 1.00)'; FLICKER = 0.02; TINT = 'float3(0.0, 0.020, 0.045)' }
    }
    'blade-runner' = @{
        Anim = $true; Scheme = 'NEON Blade Runner'
        Defines = @{ SKYLINE = 1; NEON_HAZE = 1; RAIN_STREAKS = 1; RAIN_STREAK_COLOR = 'float3(0.13, 0.17, 0.22)'; READ_PANEL = 0.7; HALO = 1.0; GRAIN_ANIM = 0.03; GLOW_STRENGTH = 0.6; GLOW_SPREAD = 2.0; VIGNETTE = 0.9 }
    }
    'tron' = @{
        Anim = $true; Scheme = 'NEON Tron'
        Defines = @{ EDGE_GLOW = 1; EDGE_STRENGTH = 0.3; EDGE_COLOR = 'float3(0.20, 0.85, 1.00)'; GRID = 1; GRID_HORIZON = 0.70; GRID_DENSITY = 6.0; GRID_SPEED = 0.12; GRID_COLOR = 'float3(0.00, 0.50, 0.85)'; GRID_STRENGTH = 0.55; READ_PANEL = 0.3; HALO = 1.0; GLOW_STRENGTH = 0.9; GLOW_SPREAD = 2.2; CONTRAST = 1.05; VIGNETTE = 0.8; TINT = 'float3(0.0, 0.006, 0.014)' }
    }
    'vhs' = @{
        Anim = $true; Scheme = $null
        Defines = @{ VHS = 1; CHROMA_PX = 1.2; USE_ANIM = 1; BAND_SPEED = 0.05; BAND_JITTER = 3.0; BAND_GLOW = 0.08; NOISE = 0.06; DESAT = 0.15; GRADE = 0.5; SHADOW_TINT = 'float3(1.00, 0.95, 1.05)'; HIGHLIGHT_TINT = 'float3(1.10, 1.00, 0.88)'; CONTRAST = 0.95; GLOW_STRENGTH = 0.8; GLOW_SPREAD = 3.0; SCANLINE_PX = 2.0; SCANLINE_DIM = 0.10; CURVE = 0.01; VIGNETTE = 1.0 }
    }
    'mr-robot' = @{
        Anim = $true; Scheme = 'NEON Mr Robot'
        Defines = @{ DESAT = 0.35; CONTRAST = 1.15; GLITCH = 1; GLITCH_SLICES = 40.0; GLITCH_RATE = 2.0; GLITCH_AMOUNT = 0.02; GLITCH_BLOCKS = 1; GRAIN_ANIM = 0.06; GLOW_STRENGTH = 0.7; GLOW_SPREAD = 2.0; SCANLINE_PX = 3.0; SCANLINE_DIM = 0.12; VIGNETTE = 1.3 }
    }
    'synthwave' = @{
        Anim = $true; Scheme = 'NEON Synthwave'
        Defines = @{ SKY = 1; SKY_TOP = 'float3(0.03, 0.0, 0.09)'; SKY_BOTTOM = 'float3(0.28, 0.03, 0.24)'; GRID = 1; GRID_HORIZON = 0.62; GRID_DENSITY = 7.0; GRID_SPEED = 0.25; GRID_COLOR = 'float3(1.00, 0.20, 0.80)'; HALO = 1.0; TEXT_MIN = 0.58; GLOW_STRENGTH = 1.0; GLOW_SPREAD = 2.4; SCANLINE_PX = 3.0; SCANLINE_DIM = 0.10; VIGNETTE = 0.8 }
    }
    'noir' = @{
        Anim = $true; Scheme = 'NEON Film Noir'
        Defines = @{ MONO = 0.9; MONO_COLOR = 'float3(1.00, 1.00, 1.00)'; MONO_GAIN = 1.25; GRADE = 0.3; SHADOW_TINT = 'float3(0.90, 0.95, 1.05)'; CONTRAST = 1.25; GRAIN_ANIM = 0.08; SCRATCHES = 1; EXPOSURE_FLICKER = 0.06; GLOW_STRENGTH = 0.6; GLOW_SPREAD = 2.0; VIGNETTE = 1.4 }
    }
    'terminator' = @{
        Anim = $true; Scheme = 'NEON Terminator'
        Defines = @{ HUD = 1; HUD_COLOR = 'float3(1.00, 0.15, 0.10)'; SEL_FIX = 1; SEL_COLOR = 'float3(0.722, 0.082, 0.055)'; GLOW_STRENGTH = 1.0; GLOW_SPREAD = 2.2; SCANLINE_PX = 2.0; SCANLINE_DIM = 0.20; CONTRAST = 1.05; VIGNETTE = 1.2 }
    }
}
# Palette degli schemi NEON per le modalità cinema (stesso ordine di cinema.ps1).
# Ruoli: foreground = output · green = comandi digitati / prompt · cyan = percorsi, parametri, info
#        yellow = stringhe, avvisi · magenta = parole chiave · red = errori · brightBlack = secondario
$NeonCinemaSchemes = [ordered]@{
    'NEON Matrix' = [ordered]@{   # verdi dominanti · rosso = pillola rossa (errori) · blu = pillola blu (percorsi, parametri, info)
        background = '#020A04'; foreground = '#9CF5B2'; cursorColor = '#7CFF9E'; selectionBackground = '#0F5A2C'
        black = '#0A2414'; red = '#FF4D4D'; green = '#3DF57F'; yellow = '#C6F56A'; blue = '#5C8CFF'; purple = '#2FD17F'; cyan = '#6FA8FF'; white = '#A8DDB5'
        brightBlack = '#3F8A5A'; brightRed = '#FF7A7A'; brightGreen = '#8CFFAE'; brightYellow = '#E4FF9A'; brightBlue = '#8FB0FF'; brightPurple = '#66EBA6'; brightCyan = '#9CC4FF'; brightWhite = '#E6FFEE'
    }
    'NEON Amber' = [ordered]@{    # famiglia ambra: oro (comandi), ambra (output), giallo pallido (stringhe), ambra scura (secondario)
        background = '#0D0700'; foreground = '#FFB21A'; cursorColor = '#FFD24D'; selectionBackground = '#5C3B00'
        black = '#2A1A00'; red = '#FF6A2B'; green = '#FFD84D'; yellow = '#FFE9A3'; blue = '#E09A2E'; purple = '#FF9F45'; cyan = '#FFC766'; white = '#E6A845'
        brightBlack = '#A5701A'; brightRed = '#FF8A55'; brightGreen = '#FFE680'; brightYellow = '#FFF4CC'; brightBlue = '#F0B04D'; brightPurple = '#FFBC7A'; brightCyan = '#FFDA94'; brightWhite = '#FFF7DE'
    }
    'NEON Star Wars' = [ordered]@{ # giallo dei titoli · comandi blu spada laser · parametri verde spada laser · errori rosso Sith
        background = '#000005'; foreground = '#FFE81F'; cursorColor = '#FFE81F'; selectionBackground = '#3D3A12'
        black = '#16161F'; red = '#FF4A3D'; green = '#5CC8FF'; yellow = '#FFD369'; blue = '#6F95FF'; purple = '#C19BFF'; cyan = '#86FF75'; white = '#D9D2A6'
        brightBlack = '#8C8664'; brightRed = '#FF7A6E'; brightGreen = '#8FDCFF'; brightYellow = '#FFE6A3'; brightBlue = '#9CB4FF'; brightPurple = '#D9BFFF'; brightCyan = '#B0FFA3'; brightWhite = '#FFFBE6'
    }
    'NEON Hologram' = [ordered]@{  # azzurri olografici · comandi acquamarina · parole chiave viola · avvisi oro pallido · errori rosa
        background = '#020814'; foreground = '#A8DCFF'; cursorColor = '#9FE6FF'; selectionBackground = '#1D4C7A'
        black = '#0E2240'; red = '#FF6B95'; green = '#62F5D6'; yellow = '#FFE39A'; blue = '#6F9CFF'; purple = '#B99BFF'; cyan = '#66CFFF'; white = '#B3CCE6'
        brightBlack = '#5C7FA3'; brightRed = '#FF96B5'; brightGreen = '#99FFEA'; brightYellow = '#FFF0C2'; brightBlue = '#99BAFF'; brightPurple = '#D6C4FF'; brightCyan = '#A3E6FF'; brightWhite = '#ECF8FF'
    }
    'NEON Blade Runner' = [ordered]@{ # crema caldo (output) · ambra (comandi) · teal (percorsi) · rosa neon (parole chiave) · rosso (errori)
        background = '#0A0C14'; foreground = '#F2DCC0'; cursorColor = '#FFB547'; selectionBackground = '#2F3F66'
        black = '#1A2036'; red = '#FF5A4A'; green = '#FFB547'; yellow = '#FFD98A'; blue = '#6E9EF0'; purple = '#FF7BA0'; cyan = '#4FD8E3'; white = '#CDBDA6'
        brightBlack = '#808AA8'; brightRed = '#FF8577'; brightGreen = '#FFCB7A'; brightYellow = '#FFE9BD'; brightBlue = '#98BAF5'; brightPurple = '#FFA3BD'; brightCyan = '#8AEAF2'; brightWhite = '#FFF6EB'
    }
    'NEON Tron' = [ordered]@{      # bianco ghiaccio (output) · ciano elettrico (comandi) · blu (percorsi) · arancio (parole chiave, stringhe) · rosso (errori)
        background = '#000810'; foreground = '#D3EEFF'; cursorColor = '#3DF5FF'; selectionBackground = '#0B3D6B'
        black = '#0A1E33'; red = '#FF4F3D'; green = '#3DF5FF'; yellow = '#FFB52E'; blue = '#4D9BFF'; purple = '#FF8A33'; cyan = '#3DB8F5'; white = '#A3BDD1'
        brightBlack = '#56789A'; brightRed = '#FF7B6B'; brightGreen = '#9AFBFF'; brightYellow = '#FFD382'; brightBlue = '#80B8FF'; brightPurple = '#FFAD70'; brightCyan = '#7FD4FF'; brightWhite = '#F3FBFF'
    }
    'NEON Mr Robot' = [ordered]@{  # grigi freddi · verde terminale smorzato (comandi) · teal desaturato (percorsi) · senape (avvisi) · rosso fsociety (errori)
        background = '#0A0A0A'; foreground = '#CFCFCF'; cursorColor = '#E0242C'; selectionBackground = '#4D1A1C'
        black = '#1F1F1F'; red = '#F0303A'; green = '#86CC93'; yellow = '#D9B54F'; blue = '#7A9CC2'; purple = '#C27A9E'; cyan = '#78B3B3'; white = '#A8A8A8'
        brightBlack = '#777777'; brightRed = '#FF5C63'; brightGreen = '#ADE6B6'; brightYellow = '#F0D27E'; brightBlue = '#A3BEDB'; brightPurple = '#D9A0BE'; brightCyan = '#A3D6D6'; brightWhite = '#FFFFFF'
    }
    'NEON Synthwave' = [ordered]@{ # ciano neon (comandi) · rosa (percorsi) · giallo sole (stringhe) · viola (parole chiave) · rosso (errori)
        background = '#0E0618'; foreground = '#F5E8FF'; cursorColor = '#36F9F6'; selectionBackground = '#4D2A73'
        black = '#22113A'; red = '#FF4F6A'; green = '#36F9F6'; yellow = '#FEDE5D'; blue = '#7C9CFF'; purple = '#C084FF'; cyan = '#FF7EDB'; white = '#CDBCE6'
        brightBlack = '#8C7AAD'; brightRed = '#FF7F91'; brightGreen = '#86FBF9'; brightYellow = '#FFEC99'; brightBlue = '#A8BCFF'; brightPurple = '#DBB3FF'; brightCyan = '#FFAFEA'; brightWhite = '#FFFFFF'
    }
    'NEON Film Noir' = [ordered]@{      # scala di grigi · bianco pieno per i comandi · rosso spento solo per gli errori
        background = '#0A0A0A'; foreground = '#D6D6D6'; cursorColor = '#FFFFFF'; selectionBackground = '#525252'
        black = '#1C1C1C'; red = '#C27070'; green = '#F5F5F5'; yellow = '#C2C2C2'; blue = '#9A9A9A'; purple = '#ADADAD'; cyan = '#E3E3E3'; white = '#B5B5B5'
        brightBlack = '#7A7A7A'; brightRed = '#DB8F8F'; brightGreen = '#FFFFFF'; brightYellow = '#E0E0E0'; brightBlue = '#B3B3B3'; brightPurple = '#C7C7C7'; brightCyan = '#EDEDED'; brightWhite = '#FFFFFF'
    }
    'NEON Terminator' = [ordered]@{ # rosso dominante · bianco freddo (comandi digitati) · ambra (avvisi) · azzurro ghiaccio (tipi) · selezione rossa piena
        background = '#0A0000'; foreground = '#FF7A6B'; cursorColor = '#FFFFFF'; selectionBackground = '#B8150E'
        black = '#2B0606'; red = '#FF2B1F'; green = '#F2F6FF'; yellow = '#FFB52E'; blue = '#8FB3FF'; purple = '#FF6B8E'; cyan = '#FFA897'; white = '#D9958C'
        brightBlack = '#A84A42'; brightRed = '#FF5A4D'; brightGreen = '#FFFFFF'; brightYellow = '#FFD382'; brightBlue = '#B5CCFF'; brightPurple = '#FF96AE'; brightCyan = '#FFC9BD'; brightWhite = '#FFFFFF'
    }
}

$NeonCinemaDefault = 'neon'

# Aggiunge (o rigenera) gli schemi NEON in settings.json; ritocca Neon Noir perché i colori ANSI
# corrispondano a quelli del prompt (verde #39FF88, nero #12301F). Backup alla prima installazione.
function Install-NeonCinemaSchemes([string]$Text) {
    $backup = Join-Path $env:LOCALAPPDATA 'neon\backup\settings-before-cinema-schemes.json'
    if (-not (Test-Path $backup)) {
        New-Item -ItemType Directory -Force (Split-Path $backup) | Out-Null
        Set-Content -Path $backup -Value $Text -Encoding utf8 -NoNewline
    }
    $j = $Text | ConvertFrom-Json
    $keep = @($j.schemes | Where-Object { $_.name -cnotlike 'NEON *' })
    foreach ($s in $keep) { if ($s.name -eq 'Neon Noir') { $s.green = '#39FF88'; $s.black = '#12301F' } }
    $new = foreach ($name in $NeonCinemaSchemes.Keys) {
        $o = [ordered]@{ name = $name }
        foreach ($kv in $NeonCinemaSchemes[$name].GetEnumerator()) { $o[$kv.Key] = $kv.Value }
        [pscustomobject]$o
    }
    $j.schemes = @($keep) + @($new)
    $j | ConvertTo-Json -Depth 32
}

# Applica shader ($null = nessuno) e schema colore in un'unica scrittura di settings.json
function Set-NeonCinemaLook([string]$ShaderPath, [string]$Scheme) {
    $settings = (Get-NeonTerminalSettingsPath)
    $text = [IO.File]::ReadAllText($settings)
    $missing = @($NeonCinemaSchemes.Keys | Where-Object { $text -cnotmatch ('"name"\s*:\s*"' + [regex]::Escape($_) + '"') })
    if ($missing.Count) { $text = Install-NeonCinemaSchemes $text }
    $text = [regex]::Replace($text, '(?m)^[ \t]*"experimental\.pixelShaderPath"[^\r\n]*\r?\n', '')
    if ($ShaderPath) {
        $json = $ShaderPath -replace '\\', '\\'
        $text = ([regex]'("defaults"\s*:\s*\{)').Replace($text, "`$1`n            `"experimental.pixelShaderPath`": `"$json`",", 1)
    }
    if (-not $Scheme) { $Scheme = 'Neon Noir' }
    $text = ([regex]'("colorScheme"\s*:\s*")[^"]*(")').Replace($text, "`${1}$Scheme`${2}", 1)
    [IO.File]::WriteAllText($settings, $text, [Text.UTF8Encoding]::new($false))
}
# Modalità attualmente impostata in Windows Terminal ($null = spenta)
function Get-NeonCinemaActive {
    $settings = (Get-NeonTerminalSettingsPath)
    $m = Select-String -LiteralPath $settings -Pattern '"experimental\.pixelShaderPath"\s*:\s*"[^"]*\\\\([a-z-]+)-[0-9a-f]{8}\.hlsl"' | Select-Object -First 1
    if ($m) { $m.Matches[0].Groups[1].Value }
}

# Genera lo shader della modalità: #define + template, nome legato al contenuto
function New-NeonCinemaShader([string]$Mode) {
    $defs = $NeonCinemaModes[$Mode].Defines
    $culture = [Globalization.CultureInfo]::InvariantCulture
    $head = ($defs.Keys | Sort-Object | ForEach-Object {
        $v = $defs[$_]
        $text = if ($v -is [string]) { $v } elseif ($v -is [int]) { "$v" } else { ([double]$v).ToString('0.0###', $culture) }
        "#define $_ $text"
    }) -join "`n"
    $source = "// generato da cinema.ps1 (modalità $Mode): modificare cinema.ps1 / cinema.hlsl, non questo file`n$head`n`n" +
        [IO.File]::ReadAllText((Join-Path $NeonHome 'cinema.hlsl'))
    $hash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($source))).Substring(0, 8).ToLower()
    $dir = Join-Path $env:LOCALAPPDATA 'neon\shaders'
    New-Item -ItemType Directory -Force $dir | Out-Null
    $file = Join-Path $dir "$Mode-$hash.hlsl"
    if (-not (Test-Path $file)) {
        Get-ChildItem $dir -Filter "$Mode-*.hlsl" | Remove-Item -ErrorAction Ignore   # versioni precedenti della stessa modalità
        [IO.File]::WriteAllText($file, $source, [Text.UTF8Encoding]::new($false))
    }
    $file
}

# Applica una modalità ('off' = spegne)
function Set-NeonCinemaMode([string]$Mode) {
    if ($Mode -eq 'off') { Set-NeonCinemaLook $null 'Neon Noir' }
    else { Set-NeonCinemaLook (New-NeonCinemaShader $Mode) $NeonCinemaModes[$Mode].Scheme }
}

function Write-NeonCinemaResult([string]$Mode) {
    if ($Mode -eq 'off') { alert info (NeonText 'cin.disabled'); return }
    $m = $NeonCinemaModes[$Mode]
    $anim = if ($m.Anim) { NeonText 'cin.anim' } else { '' }
    alert ok ((NeonText 'cin.enabled') -f $Mode) -Detail "$(NeonText "cin.d.$Mode")$anim"
}

# Menu con le frecce: ogni spostamento applica subito la modalità (anteprima dal vivo)
function Show-NeonCinemaMenu {
    $names = @($NeonCinemaModes.Keys) + 'off'
    $original = Get-NeonCinemaActive
    if (-not $original) { $original = 'off' }
    $index = [array]::IndexOf($names, $original)
    if ($index -lt 0) { $index = 0 }
    $count = $names.Count
    $x = "`e[0m"; $c = "`e[36m"; $d = "`e[90m"; $t = "`e[39m"; $g = "`e[32m"
    $sel = "`e[40m`e[97m"

    Write-Host ''
    Write-Host "  $c$(NeonText 'cin.header')$x  $d$(NeonText 'cin.hint')$x"
    1..$count | ForEach-Object { Write-Host '' }
    $top = [Console]::CursorTop - $count
    $cursorWasVisible = [Console]::CursorVisible
    [Console]::CursorVisible = $false
    $applied = $original
    try {
        while ($true) {
            $width = [Console]::WindowWidth - 1
            for ($i = 0; $i -lt $count; $i++) {
                $n = $names[$i]
                $label = if ($n -eq 'off') { NeonText 'cin.off' } else { $n }
                $desc = if ($n -eq 'off') { NeonText 'cin.offdesc' } else { (NeonText "cin.d.$n") + $(if ($NeonCinemaModes[$n].Anim) { '  ↻' } else { '' }) }
                $mark = if ($n -eq $original) { '●' } else { ' ' }
                # colonne: [0..4] cursore e marcatore · [5..18] nome · [19..] descrizione
                $plain = ' {0} {1} {2,-13} {3}' -f $(if ($i -eq $index) { '▌' } else { ' ' }), $mark, $label, $desc
                if ($plain.Length -gt $width) { $plain = $plain.Substring(0, $width - 1) + '…' }
                [Console]::SetCursorPosition(0, $top + $i)
                if ($i -eq $index) {
                    Write-Host ($sel + $plain.PadRight($width) + $x) -NoNewline
                } else {
                    $pre = $plain.Substring(0, [math]::Min(5, $plain.Length))
                    $lab = if ($plain.Length -gt 5) { $plain.Substring(5, [math]::Min(14, $plain.Length - 5)) } else { '' }
                    $rest = if ($plain.Length -gt 19) { $plain.Substring(19) } else { '' }
                    $preColor = if ($n -eq $original) { $g } else { $d }
                    Write-Host ("$preColor$pre$x$c$lab$x$t$rest$x" + (' ' * [math]::Max(0, $width - $plain.Length))) -NoNewline
                }
            }

            if ($names[$index] -ne $applied) { Set-NeonCinemaMode $names[$index]; $applied = $names[$index] }

            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'UpArrow'   { $index = ($index - 1 + $count) % $count }
                'DownArrow' { $index = ($index + 1) % $count }
                'Home'      { $index = 0 }
                'End'       { $index = $count - 1 }
                'Enter' {
                    [Console]::SetCursorPosition(0, $top + $count)
                    Write-Host ''
                    Write-NeonCinemaResult $names[$index]
                    return
                }
                'Escape' {
                    if ($applied -ne $original) { Set-NeonCinemaMode $original }
                    [Console]::SetCursorPosition(0, $top + $count)
                    Write-Host ''
                    alert info (NeonText 'cin.nochange')
                    return
                }
            }
        }
    } finally {
        [Console]::CursorVisible = $cursorWasVisible
    }
}

# cinema          → accende la modalità predefinita (neon) o spegne se attiva · anche Ctrl+Alt+C
# cinema --mode   → menu con le frecce per scegliere la modalità
function cinema {
    param([Parameter(Position = 0, ValueFromRemainingArguments)][string[]]$Option, [switch]$Quiet)
    $opt = if ($Option) { $Option[0] -replace '^-{1,2}', '' } else { '' }
    if ($opt -eq 'mode') { Show-NeonCinemaMenu; return }
    if ($opt) { alert error ((NeonText 'cin.unknown') -f $Option[0]) -Detail (NeonText 'cin.usage'); return }

    $target = if (Get-NeonCinemaActive) { 'off' } else { $NeonCinemaDefault }
    Set-NeonCinemaMode $target
    if (-not $Quiet) { Write-NeonCinemaResult $target }
}

Register-ArgumentCompleter -CommandName cinema -ParameterName Option -ScriptBlock {
    param($cmd, $param, $word)
    if ('--mode' -like "$word*") { [Management.Automation.CompletionResult]::new('--mode', '--mode', 'ParameterValue', (NeonText 'cin.complete')) }
}

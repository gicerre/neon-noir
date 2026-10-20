# ── NEON NOIR · PSReadLine + fzf ──────────────────────────────────────────
# Il filtro predefinito di PSReadLine (righe con password/token/secret non salvate su disco)
# resta attivo: non viene impostato un AddToHistoryHandler personalizzato.

$e = [char]27
Set-PSReadLineOption -EditMode Windows `
    -PredictionSource None `
    -PredictionViewStyle ListView `
    -HistoryNoDuplicates `
    -HistorySearchCursorMovesToEnd `
    -MaximumHistoryCount 20000 `
    -BellStyle None `
    -ShowToolTips `
    -Colors @{
        Default                = "$e[39m"
        Command                = "$e[32m"
        Parameter              = "$e[36m"
        Operator               = "$e[35m"
        Keyword                = "$e[35m"
        Variable               = "$e[96m"
        String                 = "$e[33m"
        Number                 = "$e[95m"
        Type                   = "$e[94m"
        Member                 = "$e[39m"
        Comment                = "$e[90m"
        Error                  = "$e[31m"
        Emphasis               = "$e[93m"
        Selection              = "$e[7m"
        ContinuationPrompt     = "$e[90m"
        InlinePrediction       = "$e[90m"
        ListPrediction         = "$e[32m"
        ListPredictionSelected = "$e[40m"
    }

# Frecce: ricerca per prefisso (dirhistory.ps1 le sostituisce con la versione contestuale)
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord   # accetta la previsione parola per parola

# F12: pulisce lo schermo e ripropone la schermata iniziale, senza perdere ciò che si sta scrivendo
Set-PSReadLineKeyHandler -Key F12 -BriefDescription 'NeonBanner' -Description (NeonText 'key.banner') -ScriptBlock {
    [Console]::Write("$([char]27)[2J$([char]27)[3J$([char]27)[H")
    Show-NeonBanner -NoAnimation
    # ridisegna il prompt sotto il banner (l'argomento è la riga di partenza)
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt($null, [Console]::CursorTop)
}

# Ctrl+Alt+C: modalità cinema on/off (modalità predefinita)
Set-PSReadLineKeyHandler -Chord 'Ctrl+Alt+c' -BriefDescription 'NeonCinema' -Description (NeonText 'key.cinema') -ScriptBlock { cinema -Quiet }

# ── fzf (Ctrl+R cronologia · Ctrl+T file · Alt+C directory) ─────────────────
if (-not (Get-Command fzf -CommandType Application -ErrorAction SilentlyContinue)) { return }

$env:FZF_DEFAULT_OPTS = @(
    '--height=45%', '--layout=reverse', '--border=rounded', '--info=inline-right',
    '--pointer=▌', '--marker=┃', '--prompt=❯ ', '--separator=─',
    '--color=bg:-1,bg+:0,fg:-1,fg+:15,hl:2,hl+:10',
    '--color=info:8,prompt:6,pointer:2,marker:5,spinner:5',
    '--color=header:8,border:8,label:6,query:15'
) -join ' '

$NeonFzfSkip = '.git,node_modules,target,build,dist,out,.venv,venv,__pycache__,.idea,.gradle,.next,.m2'

# bat: anteprime con evidenziazione della sintassi, colori presi dalla palette del terminale (Neon Noir)
$NeonHasBat = [bool](Get-Command bat -CommandType Application -ErrorAction SilentlyContinue)
if ($NeonHasBat) { $env:BAT_THEME = 'ansi' }

# Esegue fzf con output UTF-8 solo per la durata della chiamata
function Invoke-NeonFzf {
    param([string[]]$FzfArgs, [string]$InputText)
    $prev = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [Text.Encoding]::UTF8
        if ($PSBoundParameters.ContainsKey('InputText')) { $InputText | fzf @FzfArgs } else { fzf @FzfArgs }
    } finally { [Console]::OutputEncoding = $prev }
}

Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -BriefDescription 'NeonHistory' -Description (NeonText 'key.history') -ScriptBlock {
    $line = $null; $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    $path = (Get-PSReadLineOption).HistorySavePath
    if (-not (Test-Path $path)) { return }

    # Ricompone le voci multilinea (le righe intermedie terminano con un backtick)
    $entries = [Collections.Generic.List[string]]::new()
    $buf = ''
    foreach ($l in [IO.File]::ReadAllLines($path)) {
        if ($l.EndsWith('`')) { $buf += $l.Substring(0, $l.Length - 1) + "`n"; continue }
        $entries.Add($buf + $l); $buf = ''
    }
    $seen = [Collections.Generic.HashSet[string]]::new()
    $items = for ($i = $entries.Count - 1; $i -ge 0; $i--) {
        $x = $entries[$i]
        if ($x.Trim() -and $seen.Add($x)) { $x }
    }

    $sel = Invoke-NeonFzf -InputText ($items -join "`0") -FzfArgs @(
        '--read0', '--print0', '--scheme=history', '--no-sort', '--highlight-line',
        "--border-label=$(NeonText 'fzf.history')", "--query=$line")
    $sel = ($sel -join "`n").Trim("`0", "`n", "`r", ' ')

    if ($sel) {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($sel)
    }
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}

Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -BriefDescription 'NeonFiles' -Description (NeonText 'key.files') -ScriptBlock {
    $fzfArgs = @('--walker=file,dir,follow,hidden', "--walker-skip=$NeonFzfSkip", '--scheme=path', '--multi', "--border-label=$(NeonText 'fzf.files')")
    if ($NeonHasBat) { $fzfArgs += '--preview=bat --color=always --style=numbers --line-range=:300 {} 2>nul || dir /b {}', '--preview-window=right,55%,border-left' }
    $sel = Invoke-NeonFzf -FzfArgs $fzfArgs
    if ($sel) {
        $text = ($sel | ForEach-Object { if ($_ -match '\s') { "'$_'" } else { $_ } }) -join ' '
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($text)
    }
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}

Set-PSReadLineKeyHandler -Chord 'Alt+c' -BriefDescription 'NeonCd' -Description (NeonText 'key.cd') -ScriptBlock {
    $sel = Invoke-NeonFzf -FzfArgs @('--walker=dir,follow,hidden', "--walker-skip=$NeonFzfSkip",
        '--scheme=path', "--border-label=$(NeonText 'fzf.cd')")
    if ($sel) { Set-Location -LiteralPath $sel }
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}

# rgf [testo]: ricerca live nel contenuto dei file (ripgrep) con anteprima evidenziata (bat);
# Invio apre il file alla riga esatta in VS Code (o in $env:EDITOR).
function rgf {
    param([string]$Query = '')
    if (-not (Get-Command rg -CommandType Application -ErrorAction SilentlyContinue)) { alert error (NeonText 'rgf.missing') -Detail 'winget install BurntSushi.ripgrep.MSVC'; return }
    $skip = ($NeonFzfSkip -split ',' | ForEach-Object { "--glob=!$_" }) -join ' '
    $rg = "rg --line-number --column --no-heading --color=always --smart-case --hidden $skip"
    $fzfArgs = @('--ansi', '--disabled', "--query=$Query", '--delimiter=:',
        "--bind=change:reload:$rg {q} || cd .", "--border-label=$(NeonText 'fzf.search')", '--prompt=rg ❯ ')
    if ($Query) { $fzfArgs += "--bind=start:reload:$rg {q} || cd ." }
    if ($NeonHasBat) { $fzfArgs += '--preview=bat --color=always --style=numbers --highlight-line {2} {1}', '--preview-window=right,55%,border-left,+{2}+3/3,~1' }
    $sel = Invoke-NeonFzf -FzfArgs $fzfArgs
    if (-not $sel) { return }
    $plain = "$sel" -replace "`e\[[\d;]*m", ''
    if ($plain -notmatch '^(?<file>.+?):(?<line>\d+):(?<col>\d+):') { return }
    $target = Resolve-Path -LiteralPath $Matches.file -ErrorAction SilentlyContinue
    if (-not $target) { return }
    if ($env:EDITOR -and $env:EDITOR -notmatch '^code') { & $env:EDITOR $target.Path }
    else { code -g "$($target.Path):$($Matches.line):$($Matches.col)" }
}

Remove-Variable e

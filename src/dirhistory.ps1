# ── NEON NOIR · cronologia contestuale ─────────────────────────────────────
# Le frecce ↑/↓ scorrono solo i comandi riusciti nella directory corrente (la lista live è disattivata).
# Anche le frecce ↑/↓ sono contestuali; Ctrl+R resta sulla cronologia completa.

# Il predittore viene compilato una sola volta e rigenerato solo se DirHistory.cs cambia
$neonCs = Join-Path $NeonHome 'DirHistory.cs'
if (-not ('Neon.DirHistory' -as [type])) {
    $neonHash = (Get-FileHash $neonCs -Algorithm SHA256).Hash.Substring(0, 12)
    $neonDll = Join-Path $env:LOCALAPPDATA "neon\cache\NeonDirHistory-$neonHash.dll"
    if (-not (Test-Path $neonDll)) {
        New-Item -ItemType Directory -Force (Split-Path $neonDll) | Out-Null
        Add-Type -Path $neonCs -OutputAssembly $neonDll -OutputType Library
    }
    if (-not ('Neon.DirHistory' -as [type])) { Add-Type -Path $neonDll }
}

[Neon.DirHistory]::Init((Join-Path $env:LOCALAPPDATA 'neon\dirhistory.tsv'))
[Neon.DirHistory]::SetCwd($PWD.ProviderPath)

$neonRegistered = [System.Management.Automation.Subsystem.SubsystemManager]::GetSubsystems(
    [System.Management.Automation.Subsystem.SubsystemKind]::CommandPredictor) | Where-Object Id -eq ([Neon.DirHistory]::PredictorId)
if (-not $neonRegistered) {
    [System.Management.Automation.Subsystem.SubsystemManager]::RegisterSubsystem(
        [System.Management.Automation.Subsystem.SubsystemKind]::CommandPredictor, [Neon.DirHistory]::new())
}
# Nessuna lista sotto la riga mentre si digita: la cronologia contestuale si naviga con ↑/↓.
# Per riattivare la lista: -PredictionSource Plugin
Set-PSReadLineOption -PredictionSource None

# Invio: memorizza comando + directory di partenza. Il filtro predefinito di PSReadLine decide
# cosa è salvabile (righe con password/token/secret restano solo in memoria e non vengono registrate).
Set-PSReadLineOption -AddToHistoryHandler {
    param([string]$line)
    $opt = [Microsoft.PowerShell.PSConsoleReadLine]::GetDefaultAddToHistoryOption($line)
    if ($opt -eq [Microsoft.PowerShell.AddToHistoryOption]::MemoryAndFile -and $line.Trim()) {
        $global:NeonPendingCommand = @{ Dir = $PWD.ProviderPath; Cmd = $line }
    }
    $opt
}

# Prima di ogni prompt (hook $NeonPromptHooks, alimentato da Set-PoshContext di Oh My Posh) riceve l'exit code:
# il comando viene registrato solo se è andato a buon fine.
function Update-NeonDirHistory($code) {
    if ($global:NeonPendingCommand) {
        if ($code -eq 0) { [Neon.DirHistory]::Record($global:NeonPendingCommand.Dir, $global:NeonPendingCommand.Cmd) }
        $global:NeonPendingCommand = $null
    }
    [Neon.DirHistory]::SetCwd($PWD.ProviderPath)
}
if ($null -ne $NeonPromptHooks) { $NeonPromptHooks.Add({ param($code) Update-NeonDirHistory $code }) }

# ── Frecce ↑/↓ contestuali ──
# Scorrono i comandi riusciti in questa directory che iniziano con il testo già digitato.
# Se la lista live è aperta sotto la riga, le frecce si muovono nella lista (anch'essa contestuale).
function Test-NeonListActive([string]$line) {
    $o = Get-PSReadLineOption
    if ($o.PredictionSource -eq 'None' -or $o.PredictionViewStyle -ne 'ListView') { return $false }
    [Neon.DirHistory]::Suggestions($PWD.ProviderPath, $line).Count -gt 0
}

Set-PSReadLineKeyHandler -Key UpArrow -BriefDescription 'NeonHistoryUp' -Description (NeonText 'key.up') -ScriptBlock {
    $line = $null; $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    $s = $global:NeonArrow
    $navigating = $s -and $line -ceq $s.Current
    if (-not $navigating) {
        if (Test-NeonListActive $line) { [Microsoft.PowerShell.PSConsoleReadLine]::HistorySearchBackward(); return }
        $s = $global:NeonArrow = @{ Prefix = $line; Items = [Neon.DirHistory]::History($PWD.ProviderPath, $line); Index = -1; Current = $line }
    }
    if ($s.Index + 1 -ge $s.Items.Count) { return }
    $s.Index++
    $s.Current = $s.Items[$s.Index]
    if ($line.Length) { [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $s.Current) } else { [Microsoft.PowerShell.PSConsoleReadLine]::Insert($s.Current) }
    [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
}

Set-PSReadLineKeyHandler -Key DownArrow -BriefDescription 'NeonHistoryDown' -Description (NeonText 'key.down') -ScriptBlock {
    $line = $null; $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    $s = $global:NeonArrow
    if (-not ($s -and $line -ceq $s.Current) -or $s.Index -lt 0) {
        if (Test-NeonListActive $line) { [Microsoft.PowerShell.PSConsoleReadLine]::HistorySearchForward() }
        return
    }
    $s.Index--
    $s.Current = if ($s.Index -ge 0) { $s.Items[$s.Index] } else { $s.Prefix }
    if ($line.Length) { [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $s.Current) } else { [Microsoft.PowerShell.PSConsoleReadLine]::Insert($s.Current) }
    [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
}

Remove-Variable neonCs, neonHash, neonDll, neonRegistered -ErrorAction Ignore

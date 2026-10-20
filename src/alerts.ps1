# ── NEON NOIR · errori, avvisi, info ───────────────────────────────────────
# Tre livelli visivi distinti:
#   errori  → pillola rossa piena con icona, barra laterale, riga e codice che l'hanno causato
#   avvisi  → fascia ambra in grassetto          (PowerShell accetta solo colori qui, non icone)
#   verbose → fascia ciano · debug → fascia viola
# Solo presentazione: stream, $Error, -ErrorAction e redirect funzionano come prima.

$PSStyle.Formatting.Error          = "`e[91m"
$PSStyle.Formatting.ErrorAccent    = "`e[1;31m"
$PSStyle.Formatting.Warning        = "`e[1;33m"
$PSStyle.Formatting.Verbose        = "`e[36m"
$PSStyle.Formatting.Debug          = "`e[95m"
$PSStyle.Formatting.FeedbackName   = "`e[1;36m"
$PSStyle.Formatting.FeedbackText   = "`e[39m"
$PSStyle.Formatting.FeedbackAction = "`e[32m"
$PSStyle.Formatting.TableHeader    = "`e[1;36m"
$PSStyle.Formatting.FormatAccent   = "`e[1;32m"

# Rendering di un ErrorRecord (usato da neon.format.ps1xml). Non deve mai lanciare eccezioni.
function Format-NeonError([System.Management.Automation.ErrorRecord]$e) {
    try {
        $x = "`e[0m"; $red = "`e[31m"; $soft = "`e[91m"; $dim = "`e[90m"

        # stderr dei programmi nativi catturato con 2>&1: testo semplice, senza riquadro
        if ($e.FullyQualifiedErrorId -in 'NativeCommandError', 'NativeCommandErrorMessage' -or
            $e.Exception -is [System.Management.Automation.RemoteException]) {
            return "$($PSStyle.Formatting.Error)$($e.Exception.Message)$x"
        }

        $msg = if ($e.ErrorDetails -and $e.ErrorDetails.Message) { $e.ErrorDetails.Message } else { $e.Exception.Message }
        $ii = $e.InvocationInfo

        # Le altre viste di $ErrorView restano disponibili in forma testuale
        if ($ErrorView -eq 'CategoryView') { return $e.CategoryInfo.GetMessage() }
        if ($ErrorView -in 'NormalView', 'DetailedView') {
            return (@($msg, $ii.PositionMessage, "    + CategoryInfo          : $($e.CategoryInfo)",
                "    + FullyQualifiedErrorId : $($e.FullyQualifiedErrorId)") | Where-Object { $_ }) -join "`n"
        }

        $reason = "$($e.CategoryInfo.Reason)" -replace 'Exception$', ''
        if ($reason -in 'WriteError', 'Runtime', 'RemoteException') { $reason = '' }
        $cmd = if ($ii -and $ii.MyCommand) { $ii.MyCommand.Name } else { '' }

        $head = "`e[1;30;41m $([char]0xf057) $(NeonText 'alert.error') $x"
        if ($reason) { $head += " $red$reason$x" }
        if ($cmd -and $cmd -ne $reason) { $head += " $dim·$x $soft$cmd$x" }

        $lines = [Collections.Generic.List[string]]::new()
        $lines.Add($head)
        foreach ($l in ($msg.TrimEnd() -split "`r?`n")) { $lines.Add("$red▌$x $soft$l$x") }

        if ($ii -and $ii.ScriptLineNumber -gt 0 -and $ii.Line -and $ii.Line.Trim()) {
            $where = if ($ii.ScriptName) { "$(Split-Path $ii.ScriptName -Leaf):$($ii.ScriptLineNumber)" } else { ((NeonText 'err.line') -f $ii.ScriptLineNumber, $ii.OffsetInLine) }
            $code = $ii.Line.Trim()
            $w = try { [Console]::WindowWidth } catch { 120 }
            $max = [math]::Max(20, $w - $where.Length - 10)
            if ($code.Length -gt $max) { $code = $code.Substring(0, $max - 1) + '…' }
            $lines.Add("$red▌$x $dim↳ $where  $code$x")
        }
        $lines -join "`n"
    } catch {
        "$($e.Exception.Message)"
    }
}

Update-FormatData -PrependPath (Join-Path $NeonHome 'neon.format.ps1xml')

# ── NEON NOIR · scheda di prova delle modalità cinema ──────────────────────
# Mostra tutte le categorie di testo in un'unica schermata. Uso:
#   & "$NeonHome\cinema-card.ps1"   poi   cinema --mode
# Con le frecce del menu ogni tema si applica dal vivo sopra la scheda. Per la selezione,
# seleziona con il mouse una delle righe: il testo selezionato deve restare leggibile.
$e = [char]27
[Console]::Write("$e[2J$e[3J$e[H")
"$e[90m# typed command (PSReadLine colors)$e[0m"
"$e[32mGet-ChildItem$e[0m $e[36m-Path$e[0m $e[33m'C:\Projects\app'$e[0m $e[35m|$e[0m $e[32mWhere-Object$e[0m $e[96m`$_$e[0m.Length $e[35m-gt$e[0m $e[95m1024$e[0m  $e[90m# comment$e[0m"
''
"$e[90m# normal output$e[0m"
'Mode   LastWriteTime        Length Name'
'----   -------------        ------ ----'
'-a---  20/10/2026 18:42      4 096 build.gradle.kts'
'-a---  20/10/2026 18:40     12 288 application.yml'
'This is a long output line that keeps going to check wrapping, clipping at the right edge and readability of dense text: 0123456789 ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz'
''
"$e[90m# git output$e[0m"
"On branch $e[32mmain$e[0m"
"	$e[31mmodified:   src/main/java/App.java$e[0m"
"	$e[32mnew file:   src/test/AppTest.java$e[0m"
''
"$e[90m# messages$e[0m"
Write-Warning 'Port 8080 is already in use'
Write-Error 'Cannot find path C:\nope because it does not exist.' 2>&1 | Out-Host
if (Get-Command alert -ErrorAction Ignore) { alert info 'Spring profile: dev'; alert ok 'Build completed in 12.4s' }
if (Get-Command hl -ErrorAction Ignore) { '2026-10-20 10:00:01  INFO  Started App in 3.21 seconds', '2026-10-20 10:00:02  WARN  Slow query (812 ms)', '2026-10-20 10:00:03 ERROR  Connection refused' | hl }
''
"$e[90m# select this line with the mouse: the selected text must stay clearly readable$e[0m"
''

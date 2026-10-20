# ── NEON NOIR · testi dell'interfaccia ─────────────────────────────────────
# Inglese di default; $NeonConfig.Language = 'it' nel profilo per l'italiano.
# Ogni chiave mancante in una lingua ricade sull'inglese. I testi con {0} {1} si usano con -f.

$NeonText = @{
    en = @{
        # banner
        'banner.clean' = 'clean'; 'banner.changed' = '{0} changed'; 'banner.untracked' = '{0} untracked'
        'banner.f.neon' = 'commands'; 'banner.f.history' = 'history'; 'banner.f.files' = 'files'; 'banner.f.jump' = 'jump'; 'banner.f.projects' = 'projects'
        'unit.day' = 'd'
        # avvisi ed errori
        'alert.error' = 'ERROR'; 'alert.warn' = 'WARNING'; 'err.line' = 'line {0}:{1}'
        'warn.dirhistory' = 'Contextual history unavailable: {0}'
        # porte
        'ports.none' = 'No ports listening (use -All to include system services)'
        'ports.h.port' = 'PORT'; 'ports.h.proc' = 'PROCESS'; 'ports.h.pid' = 'PID'; 'ports.h.link' = 'LINK'
        'killport.none' = 'No process listening on port {0}'
        # progetti
        'proj.none' = 'No project recognized here'
        'proj.none.detail' = 'looking for pom.xml, build.gradle, package.json, pyproject.toml, requirements.txt, manage.py'
        'proj.unavailable' = '{0} not available for {1} ({2})'
        'proj.mvn.norun' = 'pom.xml without Spring Boot: no standard "run" goal (use mvn exec:java)'
        'proj.node.noscript' = 'package.json has no {0} script (available: {1})'
        'proj.py.norun' = 'no manage.py, main.py or app.py in the project root'
        'proj.py.nobuild' = 'no pyproject.toml: nothing to build'
        'proj.done' = '{0} completed in {1}'; 'proj.failed' = '{0} failed (exit {1}) after {2}'
        'dirty.none' = 'No git repositories in {0}'; 'dirty.summary' = '{0} of {1} repositories with pending work'
        'dirty.changed' = '{0} modified'; 'dirty.untracked' = '{0} untracked'; 'dirty.ahead' = '↑{0} to push'; 'dirty.behind' = '↓{0} to pull'
        'dirty.noupstream' = 'no upstream'; 'dirty.clean' = 'clean'
        # notifiche
        'notify.ok' = '✔ Completed in {0}'; 'notify.fail' = '✘ Failed (exit {0}) after {1}'; 'notify.secret' = '(private command)'
        # fzf / ricerca
        'fzf.history' = ' history '; 'fzf.files' = ' files '; 'fzf.cd' = ' cd '; 'fzf.search' = ' search project '
        'rgf.missing' = 'ripgrep (rg) is not installed'
        'key.history' = 'Fuzzy search in history (fzf)'; 'key.files' = 'Insert a file/directory picked with fzf'; 'key.cd' = 'Enter a subdirectory picked with fzf'
        'key.banner' = 'Show the welcome screen again'; 'key.cinema' = 'Toggle cinema mode'
        'key.up' = 'Previous successful command in this directory'; 'key.down' = 'Next successful command in this directory'
        # cinema
        'cin.header' = 'CINEMA MODE'; 'cin.hint' = '↑/↓ live preview · Enter confirm · Esc cancel · ● current · ↻ animated'
        'cin.off' = 'off'; 'cin.offdesc' = 'no effect'; 'cin.disabled' = 'Cinema mode off'; 'cin.enabled' = 'Cinema mode: {0}'
        'cin.anim' = ' · animated: the GPU redraws continuously'; 'cin.nochange' = 'No changes'
        'cin.unknown' = 'Unknown option: {0}'; 'cin.usage' = 'cinema = toggle the default mode · cinema --mode = choose a mode'
        'cin.complete' = 'menu to choose the cinema mode'
        'cin.d.neon' = 'Neon CRT · phosphor glow and scanlines (default)'
        'cin.d.tv' = "'80s television · RGB phosphor mask, rounded bezel, glass reflection"
        'cin.d.matrix' = 'Green phosphor · digital code rain falling behind the text'
        'cin.d.amber' = "'80s amber terminal · phosphor persistence and a rolling sync bar"
        'cin.d.star-wars' = 'Opening crawl · older output tilts away into the stars, gold text, nebula'
        'cin.d.hologram' = 'Hologram · projector beam, glowing edges, sliced glitches, interlacing'
        'cin.d.blade-runner' = 'Neo-noir · cinemascope bars, anamorphic flares, slanted rain, teal & orange'
        'cin.d.tron' = 'The Grid · scrolling neon floor in perspective, glowing text edges'
        'cin.d.vhs' = 'Videotape · bleeding color, head-switching noise, worn tape'
        'cin.d.mr-robot' = 'fsociety · high-contrast black & white, only red survives, digital glitch blocks'
        'cin.d.synthwave' = 'Outrun · sunset sky, striped sun, magenta grid, pink and cyan text'
        'cin.d.noir' = "'40s film noir · black & white, film scratches and dust, flickering exposure"
        'cin.d.terminator' = 'T-800 vision · red HUD with grid, scan bar and crosshair'
        # guida `neon`
        'help.s.shell' = 'POWERSHELL'; 'help.s.cmd' = 'COMMANDS'; 'help.s.proj' = 'PROJECTS'; 'help.s.tools' = 'TOOLS'; 'help.s.look' = 'LOOK & FEEL'; 'help.s.wt' = 'WINDOWS TERMINAL'
        'help.ctrlr' = 'fuzzy history search (fzf)'; 'help.ctrlt' = 'insert a file/dir (fzf, with preview)'; 'help.altc' = 'cd into a subdirectory (fzf)'
        'help.arrows' = 'successful commands in this directory, filtered by prefix'; 'help.ctrlright' = 'accept the suggestion word by word'
        'help.z' = 'jump to frequent directories · zi interactive'
        'help.git' = 'status · diff · staged diff · graph log'; 'help.gsw' = 'switch branch · recent branches'; 'help.gpull' = 'pull --ff-only · push'
        'help.vs' = 'open in VS Code (or $env:EDITOR)'; 'help.open' = 'open in File Explorer'
        'help.ll' = 'list · create+enter · create file'; 'help.which' = 'where a command lives · PATH entries'
        'help.ports' = 'listening ports with links · kill process (asks first)'
        'help.run' = 'the right command for Maven/Gradle/npm/pnpm/yarn/Python'
        'help.dirty' = 'repos with changes, unpushed commits or no upstream'
        'help.rgf' = 'search project files → open VS Code at the line'
        'help.coding' = 'pick a project → VS Code + Claude Code'
        'help.top' = 'heaviest processes'; 'help.hl' = 'logs with level icons (error/warn/info/ok)'
        'help.alert' = 'styled message: error · warn · info · ok'; 'help.tailf' = 'follow a colored log'
        'help.cinema' = 'cinema mode on/off (default: neon)'; 'help.cinemamode' = 'arrow-key menu to pick the mode (live preview)'
        'help.banner' = 'show the welcome screen again'; 'help.clear' = 'clear the screen and show the welcome screen'
        'help.f12' = 'welcome screen without losing the typed line'
        'help.split' = 'split pane right / down'; 'help.focus' = 'move focus between panes'; 'help.zoom' = 'zoom pane'
        'help.marks' = 'previous / next prompt'; 'help.find' = 'search the buffer'; 'help.export' = 'export buffer to a file'
        'help.clearbuf' = 'clear buffer'; 'help.tabs' = 'new Dev / Admin / Clean tab'; 'help.focusmode' = 'focus mode'
        # neon title / neon config
        'help.title' = 'set the header text (neon title --reset = default)'; 'help.config' = 'show your preferences and where they are stored'
        'title.current' = 'Header text: {0}'; 'title.usage' = 'neon title "YOUR TEXT"  ·  neon title --reset'
        'title.saved' = 'Header text set to: {0}'; 'title.reset' = 'Header text back to default: {0}'
        'title.invalid' = 'Unsupported characters: {0}'; 'title.allowed' = 'allowed: letters A-Z, digits 0-9, space and - _ . /'
        'title.long' = 'Long header ({0} characters): narrow windows show a compact version'
        'config.path' = 'Preferences: {0}'; 'config.none' = '(not created yet: all defaults)'; 'config.yours' = 'yours'; 'config.default' = 'default'
        'neon.unknown' = 'Unknown command: neon {0}'; 'neon.usage' = 'neon · neon title <text> · neon title --reset · neon config'
    }
    it = @{
        'banner.clean' = 'pulito'; 'banner.changed' = '{0} modificati'; 'banner.untracked' = '{0} non tracciati'
        'banner.f.neon' = 'comandi'; 'banner.f.history' = 'cronologia'; 'banner.f.files' = 'file'; 'banner.f.jump' = 'salta'; 'banner.f.projects' = 'progetti'
        'unit.day' = 'g'
        'alert.error' = 'ERRORE'; 'alert.warn' = 'AVVISO'; 'err.line' = 'riga {0}:{1}'
        'warn.dirhistory' = 'Cronologia contestuale non disponibile: {0}'
        'ports.none' = 'Nessuna porta in ascolto (usa -All per includere i servizi di sistema)'
        'ports.h.port' = 'PORTA'; 'ports.h.proc' = 'PROCESSO'; 'ports.h.pid' = 'PID'; 'ports.h.link' = 'LINK'
        'killport.none' = 'Nessun processo in ascolto sulla porta {0}'
        'proj.none' = 'Nessun progetto riconosciuto qui'
        'proj.none.detail' = 'cerco pom.xml, build.gradle, package.json, pyproject.toml, requirements.txt, manage.py'
        'proj.unavailable' = '{0} non disponibile per {1} ({2})'
        'proj.mvn.norun' = 'pom.xml senza Spring Boot: nessun goal "run" standard (usa mvn exec:java)'
        'proj.node.noscript' = 'package.json non ha uno script {0} (disponibili: {1})'
        'proj.py.norun' = 'nessun manage.py, main.py o app.py nella radice del progetto'
        'proj.py.nobuild' = 'nessun pyproject.toml: niente da compilare'
        'proj.done' = '{0} completato in {1}'; 'proj.failed' = '{0} fallito (exit {1}) dopo {2}'
        'dirty.none' = 'Nessun repository git in {0}'; 'dirty.summary' = '{0} di {1} repository con lavoro in sospeso'
        'dirty.changed' = '{0} modificati'; 'dirty.untracked' = '{0} non tracciati'; 'dirty.ahead' = '↑{0} da pushare'; 'dirty.behind' = '↓{0} da scaricare'
        'dirty.noupstream' = 'nessun upstream'; 'dirty.clean' = 'pulito'
        'notify.ok' = '✔ Completato in {0}'; 'notify.fail' = '✘ Fallito (exit {0}) dopo {1}'; 'notify.secret' = '(comando riservato)'
        'fzf.history' = ' cronologia '; 'fzf.files' = ' file '; 'fzf.cd' = ' cd '; 'fzf.search' = ' cerca nel progetto '
        'rgf.missing' = 'ripgrep (rg) non installato'
        'key.history' = 'Ricerca fuzzy nella cronologia (fzf)'; 'key.files' = 'Inserisce un file/directory scelto con fzf'; 'key.cd' = 'Entra in una sottodirectory scelta con fzf'
        'key.banner' = 'Mostra di nuovo la schermata iniziale'; 'key.cinema' = 'Accende/spegne la modalità cinema'
        'key.up' = 'Comando riuscito precedente in questa directory'; 'key.down' = 'Comando riuscito successivo in questa directory'
        'cin.header' = 'MODALITÀ CINEMA'; 'cin.hint' = '↑/↓ anteprima dal vivo · Invio conferma · Esc annulla · ● attuale · ↻ animata'
        'cin.off' = 'spento'; 'cin.offdesc' = 'nessun effetto'; 'cin.disabled' = 'Modalità cinema disattivata'; 'cin.enabled' = 'Modalità cinema: {0}'
        'cin.anim' = ' · animata: la GPU ridisegna in continuo'; 'cin.nochange' = 'Nessuna modifica'
        'cin.unknown' = 'Opzione sconosciuta: {0}'; 'cin.usage' = 'cinema = on/off con la modalità predefinita · cinema --mode = scegli la modalità'
        'cin.complete' = 'menu per scegliere la modalità cinema'
        'cin.d.neon' = 'Neon CRT · bagliore al fosforo e scanline (predefinita)'
        'cin.d.tv' = "Televisore anni '80 · griglia RGB dei fosfori, cornice arrotondata, riflesso sul vetro"
        'cin.d.matrix' = 'Fosforo verde · pioggia di codice digitale che cade dietro al testo'
        'cin.d.amber' = "Terminale ambra anni '80 · persistenza del fosforo e banda di sincronismo che scorre"
        'cin.d.star-wars' = "Titoli d'apertura · l'output più vecchio si inclina verso le stelle, testo oro, nebulosa"
        'cin.d.hologram' = 'Ologramma · fascio del proiettore, contorni luminosi, glitch a fette, interlacciamento'
        'cin.d.blade-runner' = 'Neo-noir · barre cinemascope, riflessi anamorfici, pioggia obliqua, teal & orange'
        'cin.d.tron' = 'La Griglia · pavimento al neon in prospettiva che scorre, contorni del testo illuminati'
        'cin.d.vhs' = 'Videocassetta · colore che sbava, disturbo di head switching, nastro rovinato'
        'cin.d.mr-robot' = 'fsociety · bianco e nero contrastato, resta solo il rosso, blocchi glitch digitali'
        'cin.d.synthwave' = 'Outrun · cielo al tramonto, sole a strisce, griglia magenta, testo rosa e ciano'
        'cin.d.noir' = "Film noir anni '40 · bianco e nero, graffi e polvere della pellicola, esposizione che trema"
        'cin.d.terminator' = 'Visione T-800 · HUD rosso con griglia, barra di scansione e mirino'
        'help.s.shell' = 'POWERSHELL'; 'help.s.cmd' = 'COMANDI'; 'help.s.proj' = 'PROGETTI'; 'help.s.tools' = 'STRUMENTI'; 'help.s.look' = 'ESTETICA'; 'help.s.wt' = 'WINDOWS TERMINAL'
        'help.ctrlr' = 'cronologia fuzzy (fzf)'; 'help.ctrlt' = 'inserisci file/dir (fzf, con anteprima)'; 'help.altc' = 'cd in sottodirectory (fzf)'
        'help.arrows' = 'comandi riusciti qui, filtrati per prefisso'; 'help.ctrlright' = 'accetta il suggerimento parola per parola'
        'help.z' = 'salta a directory frequenti · zi interattivo'
        'help.git' = 'status · diff · diff staged · log a grafo'; 'help.gsw' = 'switch branch · branch recenti'; 'help.gpull' = 'pull --ff-only · push'
        'help.vs' = 'apri in VS Code (o $env:EDITOR)'; 'help.open' = 'apri in Esplora risorse'
        'help.ll' = 'lista · crea+entra · crea file'; 'help.which' = 'dove si trova un comando · voci di PATH'
        'help.ports' = 'porte in ascolto con link · termina processo (con conferma)'
        'help.run' = 'comando giusto per Maven/Gradle/npm/pnpm/yarn/Python'
        'help.dirty' = 'repository con modifiche, commit da pushare o senza upstream'
        'help.rgf' = 'cerca nei file del progetto → apre VS Code alla riga'
        'help.coding' = 'scegli un progetto → VS Code + Claude Code'
        'help.top' = 'processi più pesanti'; 'help.hl' = 'log con icone per livello (errore/avviso/info/ok)'
        'help.alert' = 'avviso grafico: error · warn · info · ok'; 'help.tailf' = 'segue un log colorato'
        'help.cinema' = 'modalità cinema on/off (predefinita: neon)'; 'help.cinemamode' = 'menu con le frecce per scegliere la modalità (anteprima dal vivo)'
        'help.banner' = 'mostra di nuovo la schermata iniziale'; 'help.clear' = 'pulisce lo schermo e ripropone la schermata iniziale'
        'help.f12' = 'schermata iniziale senza perdere la riga scritta'
        'help.split' = 'dividi pannello a destra / sotto'; 'help.focus' = 'sposta il focus tra pannelli'; 'help.zoom' = 'zoom pannello'
        'help.marks' = 'prompt precedente / successivo'; 'help.find' = 'cerca nel buffer'; 'help.export' = 'esporta buffer in file'
        'help.clearbuf' = 'pulisci buffer'; 'help.tabs' = 'nuova tab Dev / Admin / Clean'; 'help.focusmode' = 'modalità focus'
        'help.title' = 'cambia la scritta dell''intestazione (neon title --reset = predefinita)'; 'help.config' = 'mostra le tue preferenze e dove sono salvate'
        'title.current' = 'Scritta dell''intestazione: {0}'; 'title.usage' = 'neon title "IL TUO TESTO"  ·  neon title --reset'
        'title.saved' = 'Scritta dell''intestazione impostata: {0}'; 'title.reset' = 'Scritta dell''intestazione predefinita: {0}'
        'title.invalid' = 'Caratteri non supportati: {0}'; 'title.allowed' = 'ammessi: lettere A-Z, cifre 0-9, spazio e - _ . /'
        'title.long' = 'Intestazione lunga ({0} caratteri): nelle finestre strette viene mostrata in forma compatta'
        'config.path' = 'Preferenze: {0}'; 'config.none' = '(non ancora creato: tutti valori predefiniti)'; 'config.yours' = 'tua'; 'config.default' = 'predefinita'
        'neon.unknown' = 'Comando sconosciuto: neon {0}'; 'neon.usage' = 'neon · neon title <testo> · neon title --reset · neon config'
    }
}

function NeonText([string]$Key) {
    $lang = if ($NeonConfig.Language -and $NeonText.ContainsKey($NeonConfig.Language)) { $NeonConfig.Language } else { 'en' }
    $s = $NeonText[$lang][$Key]
    if ($null -eq $s) { $s = $NeonText.en[$Key] }
    if ($null -eq $s) { $Key } else { $s }
}

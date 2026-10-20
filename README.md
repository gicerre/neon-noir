# NEON // NOIR

A cyberpunk setup for **Windows Terminal + PowerShell 7**: two-line prompt, start-up banner, per-directory history on ↑/↓, error and warning styling, long-command notifications, project shortcuts (`run`, `test`, `build`, `dirty`), 13 "cinema" modes made of shaders and colour schemes, plus a matching **Claude Code** status line.

Text stays readable in every mode: all effects spare the text and every theme uses a full 16-colour palette.

![Start-up banner, git log, alerts and the two-line prompt in the default neon theme](docs/cinema/neon.gif)

12 more looks, from Matrix rain to a Star Wars crawl, are in [Cinema themes](#cinema-themes).

## Requirements

- Windows 10 1903+ or Windows 11, [Windows Terminal](https://aka.ms/terminal) 1.21+
- PowerShell 7 (the installer gets it with winget when started from Windows PowerShell 5.1)
- Optional: [Claude Code](https://claude.com/claude-code) and Node.js for the status line

## Install

```powershell
git clone https://github.com/gicerre/neon-noir.git
cd neon-noir
.\install.ps1                     # add -WhatIf to see every change first
```

| Option | Effect |
|---|---|
| `-Language it` | Italian texts (default `en`) |
| `-ProjectsRoot D:\code` | folder of the **Dev** tab and of `dirty` |
| `-SkipDependencies` | do not install anything with winget |
| `-NoTerminal` / `-NoClaude` | leave Windows Terminal / Claude Code alone |

Running `install.ps1` again updates an existing installation.

### What it changes

Nothing is replaced wholesale, and every file is backed up to `%LOCALAPPDATA%\neon\backup\<date>\` first.

| Where | Change |
|---|---|
| `Documents\PowerShell\neon\` | NEON scripts |
| PowerShell 7 profile | a 3-line block between `# >>> NEON NOIR >>>` markers; the rest is untouched |
| Windows Terminal `settings.json` | adds the *Neon Noir* scheme and theme, the **PowerShell 7 / Dev / Admin / Clean** profiles and `Neon.*` actions; sets only the keys listed in [`terminal/neon-noir.wt.json`](terminal/neon-noir.wt.json). Shortcuts already bound to something else are skipped and reported |
| `~/.claude/settings.json` | `statusLine`, only if you do not already have one |
| winget | PowerShell 7, Oh My Posh, zoxide, fzf, bat, ripgrep (user scope when possible) and JetBrainsMono Nerd Font |

Your preferences live in `~/.config/neon-noir/config.psd1` (only the keys you changed) and are never overwritten. `neon config` shows them.

## Use

| Command | |
|---|---|
| `neon` | command list |
| `cinema` · `Ctrl+Alt+C` | cinema mode on/off |
| `cinema --mode` | pick a mode with live preview |
| `neon title "TEXT"` | change the banner title |

## Cinema themes

Each theme is a pixel shader plus a matching colour scheme. `cinema` turns the default one (**neon**) on and off; `cinema --mode` opens a menu that previews every theme live while you move through it. Every theme is tuned to keep text readable: scanlines, grain, vignetting and flicker spare the characters, and animated backgrounds get a dark halo behind the text.

### neon
Neon CRT · phosphor glow and scanlines. The default.

![neon](docs/cinema/neon.gif)

### tv
'80s television · RGB phosphor mask, rounded bezel, glass reflection.

![tv](docs/cinema/tv.gif)

### matrix
Green phosphor · digital code rain falling behind the text.

![matrix](docs/cinema/matrix.gif)

### amber
'80s amber terminal · phosphor persistence and a rolling sync bar.

![amber](docs/cinema/amber.gif)

### star-wars
Opening crawl · older output tilts away into the stars, gold text, nebula. The lower half stays flat for the work you are doing.

![star-wars](docs/cinema/star-wars.gif)

### hologram
Hologram · projector beam, glowing edges, sliced glitches, interlacing.

![hologram](docs/cinema/hologram.gif)

### blade-runner
Neo-noir · cinemascope bars, anamorphic flares, slanted rain, teal & orange.

![blade-runner](docs/cinema/blade-runner.gif)

### tron
The Grid · scrolling neon floor in perspective, glowing text edges.

![tron](docs/cinema/tron.gif)

### vhs
Videotape · bleeding color, head-switching noise, worn tape.

![vhs](docs/cinema/vhs.gif)

### mr-robot
fsociety · high-contrast black & white, only red survives, digital glitch blocks.

![mr-robot](docs/cinema/mr-robot.gif)

### synthwave
Outrun · sunset sky, striped sun, magenta grid, pink and cyan text.

![synthwave](docs/cinema/synthwave.gif)

### noir
'40s film noir · black & white, film scratches and dust, flickering exposure.

![noir](docs/cinema/noir.gif)

### terminator
T-800 vision · red HUD with grid, scan bar and crosshair.

![terminator](docs/cinema/terminator.gif)

## Uninstall

```powershell
.\uninstall.ps1                   # -Purge also deletes preferences, history and backups
```

It removes the profile block, the NEON items in Windows Terminal and the status line, and puts back the values that were there before installing — unless you changed them since. Programs installed with winget are kept; the uninstall commands are printed at the end.

## Development

```powershell
Install-Module Pester -MinimumVersion 5.5 -Scope CurrentUser
Invoke-Pester ./tests
```

Tests never touch real files: install and uninstall run end to end in a temporary folder.

| Folder | |
|---|---|
| `src/` | what gets installed (`neon-noir.ps1` is the entry point) |
| `terminal/` | Windows Terminal fragment merged into `settings.json` |
| `claude/` | Claude Code status line |
| `tools/NeonInstall.psm1` | merge / undo logic shared by the scripts and the tests |

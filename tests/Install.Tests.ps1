# ── NEON NOIR · test dell'installer ────────────────────────────────────────
# Invoke-Pester ./tests   (Pester 5+). Nessun test tocca i file reali: tutto in cartelle temporanee.

BeforeAll {
    $script:Root = Split-Path $PSScriptRoot
    Import-Module (Join-Path $Root 'tools\NeonInstall.psm1') -Force
    $script:Fragment = ConvertFrom-NeonJson (Get-Content -Raw (Join-Path $Root 'terminal\neon-noir.wt.json'))

    # settings.json come lo crea Windows Terminal al primo avvio (valori sintetici)
    function New-StockSettings {
        ConvertFrom-NeonJson @'
{
    "$help": "https://aka.ms/terminal-documentation",
    "$schema": "https://aka.ms/terminal-profiles-schema",
    "actions": [],
    "copyFormatting": "none",
    "defaultProfile": "{61c54bbd-c2c6-5271-96e7-009a87ff44bf}",
    "keybindings": [ { "id": "Terminal.CopyToClipboard", "keys": "ctrl+c" } ],
    "profiles": {
        "defaults": {},
        "list": [
            { "guid": "{61c54bbd-c2c6-5271-96e7-009a87ff44bf}", "name": "Windows PowerShell", "hidden": false },
            { "guid": "{574e775e-4f2a-5b96-ac1e-a2962a402336}", "name": "PowerShell", "source": "Windows.Terminal.PowershellCore", "hidden": false }
        ]
    },
    "schemes": [ { "name": "Mine", "background": "#000000" } ],
    "themes": []
}
'@
    }
}

Describe 'Windows Terminal merge' {
    It 'adds NEON profiles, scheme, theme and globals' {
        $r = Merge-NeonTerminalSettings (New-StockSettings) $Fragment 'D:\code' $null
        $s = $r.Settings
        $s.defaultProfile | Should -Be '{6e0a1c11-7a3d-4f0e-9c1a-0e0e0de70001}'
        $s.theme | Should -Be 'Neon Noir'
        $s.profiles.defaults.colorScheme | Should -Be 'Neon Noir'
        @($s.profiles.list | ForEach-Object { $_.name })[0..3] | Should -Be @('PowerShell 7', 'Dev', 'Admin', 'Clean')
        ($s.profiles.list | Where-Object { $_.name -eq 'Dev' }).startingDirectory | Should -Be 'D:\code'
        ($s.profiles.list | Where-Object { $_['source'] -eq 'Windows.Terminal.PowershellCore' }).hidden | Should -BeTrue
        @($s.schemes | ForEach-Object { $_.name }) | Should -Contain 'Mine'
        @($s.schemes | ForEach-Object { $_.name }) | Should -Contain 'Neon Noir'
        @($s.actions | Where-Object { $_.id -like 'Neon.*' }).Count | Should -Be @($Fragment.actions).Count
        $r.Skipped | Should -BeNullOrEmpty
    }

    It 'uses %USERPROFILE% for Dev when no projects folder is set' {
        $s = (Merge-NeonTerminalSettings (New-StockSettings) $Fragment '' $null).Settings
        ($s.profiles.list | Where-Object { $_.name -eq 'Dev' }).startingDirectory | Should -Be '%USERPROFILE%'
    }

    It 'never steals a shortcut bound to another action' {
        $stock = New-StockSettings
        $stock.keybindings += [ordered]@{ id = 'User.Mine'; keys = 'ctrl+alt+d' }
        $r = Merge-NeonTerminalSettings $stock $Fragment '' $null
        $r.Skipped | Should -Contain 'ctrl+alt+d (Neon.NewDev)'
        @($r.Settings.keybindings | Where-Object { $_.keys -eq 'ctrl+alt+d' }).id | Should -Be 'User.Mine'
    }

    It 'uninstall restores the original settings exactly' {
        $stock = New-StockSettings
        $r = Merge-NeonTerminalSettings $stock $Fragment 'D:\code' $null
        $back = Undo-NeonTerminalSettings $r.Settings $r.Undo
        Test-NeonJsonEqual $back $stock | Should -BeTrue
    }

    It 'reinstalling keeps the values found before the first install' {
        $stock = New-StockSettings
        $first = Merge-NeonTerminalSettings $stock $Fragment '' $null
        $undo = ConvertFrom-NeonJson (ConvertTo-NeonJson $first.Undo)       # come se letto da install.json
        $second = Merge-NeonTerminalSettings $first.Settings $Fragment 'D:\code' $undo
        ($second.Settings.profiles.list | Where-Object { $_.name -eq 'Dev' }).startingDirectory | Should -Be 'D:\code'
        $back = Undo-NeonTerminalSettings $second.Settings $second.Undo
        Test-NeonJsonEqual $back $stock | Should -BeTrue
    }

    It 'removes NEON items found from a hand-made earlier setup' {
        $stock = New-StockSettings
        $old = (Merge-NeonTerminalSettings $stock $Fragment '' $null).Settings     # NEON già presente, nessun install.json
        $r = Merge-NeonTerminalSettings $old $Fragment '' $null
        $back = Undo-NeonTerminalSettings $r.Settings $r.Undo
        @($back.profiles.list | Where-Object { "$($_.guid)" -like '{6e0a1c11-*' }).Count | Should -Be 0
        @($back.actions | Where-Object { "$($_.id)" -like 'Neon.*' }).Count | Should -Be 0
        @($back.schemes | ForEach-Object { $_.name }) | Should -Be @('Mine')
    }

    It 'leaves values the user changed after installing' {
        $r = Merge-NeonTerminalSettings (New-StockSettings) $Fragment '' $null
        $r.Settings.profiles.defaults.opacity = 70
        $back = Undo-NeonTerminalSettings $r.Settings $r.Undo
        $back.profiles.defaults.opacity | Should -Be 70
        $back.profiles.defaults.Contains('colorScheme') | Should -BeFalse
    }

    It 'turns cinema mode off on uninstall' {
        $r = Merge-NeonTerminalSettings (New-StockSettings) $Fragment '' $null
        $s = $r.Settings
        $s.profiles.defaults.colorScheme = 'NEON Matrix'
        $s.profiles.defaults['experimental.pixelShaderPath'] = 'C:\Users\x\AppData\Local\neon\shaders\matrix-0123abcd.hlsl'
        $s.schemes.Add([ordered]@{ name = 'NEON Matrix'; background = '#020A04' })
        $back = Undo-NeonTerminalSettings $s $r.Undo
        $back.profiles.defaults.Count | Should -Be 0
        @($back.schemes | ForEach-Object { $_.name }) | Should -Be @('Mine')
    }
}

Describe 'PowerShell profile block' {
    BeforeAll { $script:Entry = 'C:\Users\x\Documents\PowerShell\neon\neon-noir.ps1' }

    It 'appends to an existing profile and removes cleanly' {
        $mine = "Set-Alias ll Get-ChildItem`r`nfunction hello { 'hi' }`r`n"
        $r = Add-NeonProfileBlock $mine $Entry
        $r.Mode | Should -Be 'appended'
        $r.Text.StartsWith($mine.TrimEnd()) | Should -BeTrue
        $r.Text | Should -Match "`r`n# <<< NEON NOIR <<<`r`n$"
        Remove-NeonProfileBlock $r.Text | Should -Be $mine
    }

    It 'is idempotent' {
        $once = (Add-NeonProfileBlock "a`n" $Entry).Text
        $twice = Add-NeonProfileBlock $once $Entry
        $twice.Mode | Should -Be 'updated'
        $twice.Text | Should -Be $once
    }

    It 'replaces the hand-written NEON profile of earlier versions' {
        $legacy = "# NEON`n`$NeonHome = Join-Path `$PSScriptRoot 'neon'`n. (Join-Path `$NeonHome 'config.ps1')`n"
        $r = Add-NeonProfileBlock $legacy $Entry
        $r.Mode | Should -Be 'migrated'
        $r.Text | Should -Not -Match 'NeonHome'
    }

    It 'quotes paths with apostrophes' {
        $block = Get-NeonProfileBlock "C:\Users\o'brien\neon\neon-noir.ps1"
        { [scriptblock]::Create($block) } | Should -Not -Throw
        $block | Should -Match "o''brien"
    }
}

Describe 'Claude Code status line' {
    It 'sets the NEON status line when none exists, and removes it' {
        $r = Set-NeonClaudeStatusLine ([ordered]@{ model = 'opus' }) 'C:\Users\x\.claude\neon-statusline.js' $null
        $r.Status | Should -Be 'set'
        $r.Settings.statusLine.command | Should -Be 'node "C:/Users/x/.claude/neon-statusline.js"'
        $back = Undo-NeonClaudeStatusLine $r.Settings $r.Undo
        Test-NeonJsonEqual $back ([ordered]@{ model = 'opus' }) | Should -BeTrue
    }

    It 'keeps a status line from someone else' {
        $other = [ordered]@{ statusLine = [ordered]@{ type = 'command'; command = 'starship' } }
        (Set-NeonClaudeStatusLine $other 'C:\x.js' $null).Status | Should -Be 'kept'
    }
}

Describe 'install.ps1 / uninstall.ps1 end to end' {
    BeforeAll {
        $script:Box = Join-Path ([IO.Path]::GetTempPath()) "neon-test-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
        $script:P = @{
            InstallDir       = "$Box\Documents\PowerShell\neon"
            ProfilePath      = "$Box\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
            TerminalSettings = "$Box\Terminal\settings.json"
            ClaudeDir        = "$Box\.claude"
            ConfigPath       = "$Box\.config\neon-noir\config.psd1"
            StateDir         = "$Box\state"
        }
        New-Item -ItemType Directory -Force (Split-Path $P.ProfilePath), (Split-Path $P.TerminalSettings), $P.ClaudeDir | Out-Null
        $script:OrigProfile = "Set-Alias g git`r`n"
        [IO.File]::WriteAllText($P.ProfilePath, $OrigProfile)
        $script:OrigTerminal = ConvertTo-NeonJson (New-StockSettings)
        [IO.File]::WriteAllText($P.TerminalSettings, $OrigTerminal)
        $script:OrigClaude = '{ "model": "opus" }'
        [IO.File]::WriteAllText("$($P.ClaudeDir)\settings.json", $OrigClaude)

        & (Join-Path $Root 'install.ps1') @P -SkipDependencies -Language it -ProjectsRoot "$Box\code" *> $null
    }
    AfterAll { Remove-Item -LiteralPath $Box -Recurse -Force -ErrorAction Ignore }

    It 'installs files, profile block, terminal settings, status line and preferences' {
        Test-Path "$($P.InstallDir)\neon-noir.ps1" | Should -BeTrue
        [IO.File]::ReadAllText($P.ProfilePath) | Should -BeLike "Set-Alias g git*# >>> NEON NOIR >>>*"
        $s = ConvertFrom-NeonJson ([IO.File]::ReadAllText($P.TerminalSettings))
        ($s.profiles.list | Where-Object { $_.name -eq 'Dev' }).startingDirectory | Should -Be "$Box\code"
        (ConvertFrom-NeonJson ([IO.File]::ReadAllText("$($P.ClaudeDir)\settings.json"))).statusLine.command | Should -Match 'neon-statusline'
        Test-Path "$($P.ClaudeDir)\neon-statusline.js" | Should -BeTrue
        $cfg = Import-PowerShellDataFile $P.ConfigPath
        $cfg.Language | Should -Be 'it'
        $cfg.ProjectsRoot | Should -Be "$Box\code"
        Test-Path "$($P.StateDir)\install.json" | Should -BeTrue
        @(Get-ChildItem "$($P.StateDir)\backup" -Directory).Count | Should -Be 1
    }

    It 'loads the installed profile in a clean pwsh without errors' {
        $cmd = "`$NeonConfigPath = '$($P.ConfigPath)'; . '$($P.ProfilePath)'; (Get-Command cinema, neon -ErrorAction Stop).Count; `$NeonConfig.Language"
        $out = pwsh -NoProfile -NonInteractive -Command $cmd 2>&1
        $LASTEXITCODE | Should -Be 0
        $out | Should -Be @('2', 'it')
    }

    It '-WhatIf writes nothing and still lists the files' {
        $before = Get-ChildItem $Box -Recurse -File | ForEach-Object { "$($_.FullName)|$($_.LastWriteTimeUtc.Ticks)" }
        $out = & (Join-Path $Root 'install.ps1') @P -SkipDependencies -WhatIf 6>&1 | Out-String
        $out | Should -Match "$(@(Get-ChildItem (Join-Path $Root 'src') -File).Count) file"
        Get-ChildItem $Box -Recurse -File | ForEach-Object { "$($_.FullName)|$($_.LastWriteTimeUtc.Ticks)" } | Should -Be $before
    }

    It 'is idempotent when run again' {
        $before = [IO.File]::ReadAllText($P.TerminalSettings)
        & (Join-Path $Root 'install.ps1') @P -SkipDependencies *> $null
        [IO.File]::ReadAllText($P.TerminalSettings) | Should -Be $before
    }

    It 'uninstall restores profile, terminal and Claude settings' {
        & (Join-Path $Root 'uninstall.ps1') -StateDir $P.StateDir *> $null
        [IO.File]::ReadAllText($P.ProfilePath) | Should -Be $OrigProfile
        Test-NeonJsonEqual (ConvertFrom-NeonJson ([IO.File]::ReadAllText($P.TerminalSettings))) (ConvertFrom-NeonJson $OrigTerminal) | Should -BeTrue
        Test-NeonJsonEqual (ConvertFrom-NeonJson ([IO.File]::ReadAllText("$($P.ClaudeDir)\settings.json"))) (ConvertFrom-NeonJson $OrigClaude) | Should -BeTrue
        Test-Path $P.InstallDir | Should -BeFalse
        Test-Path "$($P.ClaudeDir)\neon-statusline.js" | Should -BeFalse
        Test-Path $P.ConfigPath | Should -BeTrue      # preferenze conservate senza -Purge
    }
}

Describe 'sources' {
    BeforeDiscovery {
        $repo = Split-Path $PSScriptRoot
        $script:Scripts = @(Get-ChildItem (Join-Path $repo 'src'), $repo, (Join-Path $repo 'tools') -File |
            Where-Object { $_.Extension -in '.ps1', '.psm1' } | ForEach-Object FullName)
    }

    It '<_> parses without errors' -ForEach $Scripts {
        $errors = $null
        [void][Management.Automation.Language.Parser]::ParseFile($_, [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty
    }

    It 'install.ps1 parses in Windows PowerShell 5.1' -Skip:(-not (Get-Command powershell.exe -ErrorAction Ignore)) {
        $f = Join-Path $Root 'install.ps1'
        $out = powershell.exe -NoProfile -Command "`$e = `$null; [void][Management.Automation.Language.Parser]::ParseFile('$f', [ref]`$null, [ref]`$e); `$e.Count"
        $out | Should -Be '0'
    }

    It 'contains no personal paths' {
        $hits = Get-ChildItem $Root -Recurse -File -Include *.ps1, *.psm1, *.json, *.js, *.cs, *.hlsl |
            Where-Object { $_.FullName -notmatch '[\\/]tests[\\/]' } |
            Select-String -Pattern 'F:\\DEV', 'C:\\Users\\1\\', 'C:/Users/1/', 'GIACOMO'
        $hits | Should -BeNullOrEmpty
    }
}

# =========================
# Data
# =========================

$distros = @(
    [PSCustomObject]@{ Name='Ubuntu 24.04 LTS'; DistroName='Ubuntu-24.04'; InstallerScript='installUbuntuLTS.ps1'; LinuxUser='ubuntu'; Legacy=$false; TerminalTheme='Dark+' },
    [PSCustomObject]@{ Name='Fedora Linux 43'; DistroName='FedoraLinux-43'; InstallerScript='installFedoraLinux.ps1'; LinuxUser='fedora'; Legacy=$false; TerminalTheme='One Half Dark' },
    [PSCustomObject]@{ Name='NixOS';            DistroName='NixOS';            InstallerScript='installNixOS.ps1';     LinuxUser='nixos';  Legacy=$false; TerminalTheme='Campbell'}
    # I do not manage legacy distrib in WSL
    # [PSCustomObject]@{ Name='Oracle 9.5';       DistroName='OracleLinux_9_5'; InstallerScript='installOracle.ps1';    LinuxUser='oracle'; Legacy=$true;  TerminalTheme='One Half Dark'},
    # [PSCustomObject]@{ Name='Oracle 8.10';      DistroName='OracleLinux_8_10'; InstallerScript='installOracle.ps1';    LinuxUser='oracle'; Legacy=$true; TerminalTheme='One Half Dark' }
    )

# =========================
# UI Helpers
# =========================

function Select-InteractiveItem {
    param(
        [Parameter(Mandatory)][string]    $Title,
        [Parameter(Mandatory)][System.Collections.IDictionary] $Items,
        [string] $Footer,
        [scriptblock] $Preview,
        $KeyList  # <-- Remove [string[]] to allow mixed types (int and string)
    )

    if (-not $Items -or $Items.Count -eq 0) { return $null }

    if (-not $KeyList) {
        $KeyList = @($Items.Keys)
    }
    $index = 0

    while ($true) {
        Clear-Host
        Write-Host $Title -ForegroundColor Cyan
        Write-Host ""

        for ($i = 0; $i -lt $KeyList.Count; $i++) {
            $currentKey = $KeyList[$i]
            $displayValue = $Items[$currentKey]

            if ($i -eq $index) {
                Write-Host " > $displayValue" -ForegroundColor Yellow
            } else {
                Write-Host "   $displayValue"
            }
        }

        if ($Preview) {
            Write-Host ""
            & $Preview $KeyList[$index]
        }

        Write-Host ""
        Write-Host " [Up/Down] navigate / [Enter] select / [Esc] cancel" -ForegroundColor DarkGray

        if ($Footer) {
            Write-Host ""
            Write-Host $Footer -ForegroundColor DarkGray
        }

        $key = [Console]::ReadKey($true)

        switch ($key.Key) {
            'UpArrow'   { if ($index -gt 0) { $index-- } }
            'DownArrow' { if ($index -lt $KeyList.Count - 1) { $index++ } }
            'Escape'    { return $null }
            'Enter'     { return $KeyList[$index] }
        }
    }
}

function Get-StatusFooter {
    try {
        $wslCount = ((wsl.exe --list --quiet 2>$null) -replace '\x00', '' |
                    Where-Object { $_.Trim() }).Count
    } catch { $wslCount = 0 }
    try { $os = Get-CimInstance Win32_OperatingSystem; $win="$($os.Caption) ($($os.BuildNumber))" } catch { $win="Unknown" }
    return "WSL instances: $wslCount | $win"
}

function Get-WindowsTerminalSettingsPath {
    $terminalSettingsPaths = @(
        "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json",
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    )
    return $terminalSettingsPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
}

function Get-NearestConsoleColor {
    param([string]$HexColor)

    if ($HexColor -notmatch '^#?([0-9A-Fa-f]{6})$') { return [ConsoleColor]::Gray }

    $hex = $Matches[1]
    $red = [Convert]::ToInt32($hex.Substring(0, 2), 16)
    $green = [Convert]::ToInt32($hex.Substring(2, 2), 16)
    $blue = [Convert]::ToInt32($hex.Substring(4, 2), 16)
    $palette = @(
        @{ Name='Black'; R=0; G=0; B=0 }, @{ Name='DarkBlue'; R=0; G=0; B=128 },
        @{ Name='DarkGreen'; R=0; G=128; B=0 }, @{ Name='DarkCyan'; R=0; G=128; B=128 },
        @{ Name='DarkRed'; R=128; G=0; B=0 }, @{ Name='DarkMagenta'; R=128; G=0; B=128 },
        @{ Name='DarkYellow'; R=128; G=128; B=0 }, @{ Name='Gray'; R=192; G=192; B=192 },
        @{ Name='DarkGray'; R=128; G=128; B=128 }, @{ Name='Blue'; R=0; G=0; B=255 },
        @{ Name='Green'; R=0; G=255; B=0 }, @{ Name='Cyan'; R=0; G=255; B=255 },
        @{ Name='Red'; R=255; G=0; B=0 }, @{ Name='Magenta'; R=255; G=0; B=255 },
        @{ Name='Yellow'; R=255; G=255; B=0 }, @{ Name='White'; R=255; G=255; B=255 }
    )

    $nearest = 'Gray'
    $nearestDistance = [double]::PositiveInfinity
    foreach ($color in $palette) {
        $distance = [Math]::Pow(($red - $color.R), 2) +
                    [Math]::Pow(($green - $color.G), 2) +
                    [Math]::Pow(($blue - $color.B), 2)
        if ($distance -lt $nearestDistance) {
            $nearestDistance = $distance
            $nearest = $color.Name
        }
    }
    return [ConsoleColor]::$nearest
}

function Get-BuiltInTerminalSchemes {
    return @{
        'Campbell' = @{
            background='#0C0C0C'; foreground='#CCCCCC'; black='#0C0C0C'; red='#C50F1F'; green='#13A10E'; yellow='#C19C00'; blue='#0037DA'; purple='#881798'; cyan='#3A96DD'; white='#CCCCCC'
        }
        'Campbell Powershell' = @{
            background='#012456'; foreground='#EEEDF0'; black='#0C0C0C'; red='#C50F1F'; green='#13A10E'; yellow='#C19C00'; blue='#0037DA'; purple='#881798'; cyan='#3A96DD'; white='#CCCCCC'
        }
        'Dark+' = @{
            background='#1E1E1E'; foreground='#D4D4D4'; black='#000000'; red='#CD3131'; green='#0DBC79'; yellow='#E5E510'; blue='#2472C8'; purple='#BC3FBC'; cyan='#11A8CD'; white='#E5E5E5'
        }
        'One Half Dark' = @{
            background='#282C34'; foreground='#DCDFE4'; black='#282C34'; red='#E06C75'; green='#98C379'; yellow='#E5C07B'; blue='#61AFEF'; purple='#C678DD'; cyan='#56B6C2'; white='#DCDFE4'
        }
        'One Half Light' = @{
            background='#FAFAFA'; foreground='#383A42'; black='#383A42'; red='#E45649'; green='#50A14F'; yellow='#C18401'; blue='#0184BC'; purple='#A626A4'; cyan='#0997B3'; white='#FAFAFA'
        }
        'Solarized Dark' = @{
            background='#002B36'; foreground='#839496'; black='#073642'; red='#DC322F'; green='#859900'; yellow='#B58900'; blue='#268BD2'; purple='#D33682'; cyan='#2AA198'; white='#EEE8D5'
        }
        'Solarized Light' = @{
            background='#FDF6E3'; foreground='#657B83'; black='#073642'; red='#DC322F'; green='#859900'; yellow='#B58900'; blue='#268BD2'; purple='#D33682'; cyan='#2AA198'; white='#FDF6E3'
        }
        'Tango Dark' = @{
            background='#000000'; foreground='#D3D7CF'; black='#000000'; red='#CC0000'; green='#4E9A06'; yellow='#C4A000'; blue='#3465A4'; purple='#75507B'; cyan='#06989A'; white='#D3D7CF'
        }
        'Tango Light' = @{
            background='#FFFFFF'; foreground='#555753'; black='#000000'; red='#CC0000'; green='#4E9A06'; yellow='#C4A000'; blue='#3465A4'; purple='#75507B'; cyan='#06989A'; white='#D3D7CF'
        }
        'Vintage' = @{
            background='#000000'; foreground='#00BB00'; black='#000000'; red='#BB0000'; green='#00BB00'; yellow='#BBBB00'; blue='#0000BB'; purple='#BB00BB'; cyan='#00BBBB'; white='#BBBBBB'
        }
    }
}

function Get-TerminalFontChoices {
    $installedFonts = @()
    $fontRegistryPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts',
        'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    )
    foreach ($registryPath in $fontRegistryPaths) {
        if (Test-Path $registryPath) {
            $fontProperties = Get-ItemProperty $registryPath
            $installedFonts += $fontProperties.PSObject.Properties |
                Where-Object { $_.Name -notlike 'PS*' } |
                ForEach-Object { $_.Name -replace '\s+\((TrueType|OpenType)\)$', '' }
        }
    }

    $fontNames = @(
        'Cascadia Code',
        'Cascadia Mono',
        'Consolas',
        'Courier New',
        'Hack Nerd Font',
        'Hack Nerd Font Mono',
        'Hack Nerd Font Propo'
    )
    $fontNames += $installedFonts | Where-Object { $_ -match '(?i)Mono|Code|Consolas|Hack|Courier' }
    $fontNames = @($fontNames | Sort-Object -Unique)

    $choices = [ordered]@{}
    foreach ($fontName in $fontNames) {
        $isInstalled = $installedFonts | Where-Object {
            $_ -eq $fontName -or $_ -match ("(?i)^" + [regex]::Escape($fontName) + '\s')
        } | Select-Object -First 1
        $label = if ($isInstalled) { $fontName } else { "$fontName (not detected as installed)" }
        $choices[$fontName] = $label
    }
    return $choices
}

# =========================
# Installer / Uninstaller
# =========================

function Manage-Distrib {
    param(
        [Parameter(Mandatory=$true)][int]$Index
    )

    if ($Index -lt 0 -or $Index -ge $distros.Count) {
        Write-Warning "Invalid selection."
        return
    }

    $meta = $distros[$Index]

    # Prompt for WSL instance name if not legacy
    if ($meta.Legacy -eq $false) {
        $defaultName = $meta.DistroName
        $userInput = Read-Host "Enter WSL instance name [$defaultName]"
        $cleanInput = ($userInput -replace '[\u0000-\u001F\u007F]', '').Trim()
        $wslName = if ([string]::IsNullOrWhiteSpace($cleanInput)) { $defaultName } else { $cleanInput }

        if (-not $wslName) {
            Write-Warning "No valid WSL name provided. Aborting."
            Read-Host "Press Enter to continue..."
            return
        }
    } else {
        # Legacy: use DistroName as WSLName
        $wslName = $meta.DistroName
    }

    # Prompt for username
    $defaultUser = $meta.LinuxUser
    $userInput = Read-Host "Enter Linux username [$defaultUser]"
    $cleanInput = ($userInput -replace '[\u0000-\u001F\u007F]', '').Trim()
    $linuxUser = if ([string]::IsNullOrWhiteSpace($cleanInput)) { $defaultUser } else { $cleanInput }

    # Prompt for Terminal theme
    $defaultTheme = $meta.TerminalTheme
    $userTheme = Read-Host "Enter terminal theme [$defaultTheme]"
    $themeToUse = if ([string]::IsNullOrWhiteSpace($userTheme)) { $defaultTheme } else { $userTheme }

    # Check installer script
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    $altDir = Join-Path $scriptDir 'windows\manageDistrib'
    $fullPath = Join-Path $altDir $meta.InstallerScript
    $terminalScriptPath = Join-Path $altDir 'terminalSettings.ps1'

    if (-not $meta.InstallerScript) {
        Write-Warning "No installer configured for $($meta.Name)."
        Read-Host "Press Enter to continue..."
        return
    }
    if (-not (Test-Path $fullPath)) {
        Write-Warning "Installer script '$($meta.InstallerScript)' not found in $altDir."
        Read-Host "Press Enter to continue..."
        return
    }
    if (-not (Test-Path $terminalScriptPath)) {
        Write-Warning "Terminal settings script '$($terminalScriptPath)' not found in $altDir."
        Read-Host "Press Enter to continue..."
        return
    }

    Write-Host "Installing $($meta.Name) as WSL instance '$wslName'..."
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Install WSL distribution
    try {
        & $fullPath `
            -WSLName $wslName `
            -DistroName $meta.DistroName `
            -LinuxUser $linuxUser `
            -Legacy ([bool]$meta.Legacy) `
            -ErrorAction Stop
    }
    catch {
        Write-Warning "Installer failed: $_"
    }
    finally {
        $stopwatch.Stop()
        Write-Host ("Installation completed in {0:N2} seconds" -f $stopwatch.Elapsed.TotalSeconds)
    }

    # Update terminal profile
    try {
        & $terminalScriptPath -profileName $wslName -colorScheme $themeToUse -ErrorAction Stop
        Write-Host "Terminal profile updated successfully"
    }
    catch {
        Write-Warning "Terminal profile update failed: $_"
    }
    Start-Sleep -Seconds 2

    Read-Host "Press Enter to continue..."
}

function Uninstall-WSL {
    param(
        [Parameter(Mandatory)][string]$InstanceName
    )

    $InstanceName = ($InstanceName -replace '[\u0000-\u001F\u007F]', '').Trim()
    $confirm = Read-Host "Are you sure you want to uninstall '$InstanceName'? Type 'YES' to confirm"
    if ($confirm -ne 'YES') { Write-Host "Cancelled"; return }

    & wsl.exe --terminate $InstanceName 2>$null
    & wsl.exe --unregister $InstanceName 2>$null

    Write-Host "WSL instance '$InstanceName' removed."
    Read-Host "Press Enter to continue..."
}

# =========================
# Menus
# =========================

function Menu-Install {
    $items = [ordered]@{}
    for ($i = 0; $i -lt $distros.Count; $i++) {
        $items.Add($i, $distros[$i].Name)
    }

    $keys = @($items.Keys)
    $choice = Select-InteractiveItem -Title "Install Linux distribution" -Items $items -Footer (Get-StatusFooter) -KeyList $keys

    if ($null -eq $choice) { return }
    Manage-Distrib -Index $choice
}

function Menu-refreshTerminal {
    $instances = (wsl.exe --list --quiet 2>$null) -replace '\x00', '' |
                 ForEach-Object { $_.Trim() } |
                 Where-Object { $_ }
    if (-not $instances) { Write-Host "No WSL instances found."; Start-Sleep 2; return }

    $items = [ordered]@{}
    foreach ($name in $instances) { $items[$name] = $name }

    $instance = Select-InteractiveItem -Title "Refresh Terminal Profile for WSL Instance" -Items $items -Footer (Get-StatusFooter)
    if ($null -eq $instance) { return }

    $settingsPath = Get-WindowsTerminalSettingsPath
    $schemes = @{}
    if ($settingsPath) {
        try {
            $settingsContent = Get-Content $settingsPath -Raw
            $settingsContent = $settingsContent -replace '(?m)^\s*//.*$', ''
            $settingsContent = $settingsContent -replace '(?s)/\*.*?\*/', ''
            $settingsContent = $settingsContent -replace ',(\s*[}\]])', '$1'
            $terminalSettings = $settingsContent | ConvertFrom-Json
            foreach ($scheme in $terminalSettings.schemes) {
                if ($scheme.name) { $schemes[$scheme.name] = $scheme }
            }
        }
        catch {
            Write-Warning "Could not read Windows Terminal color schemes: $_"
        }
    }

    $previewSchemes = Get-BuiltInTerminalSchemes
    foreach ($schemeName in $schemes.Keys) { $previewSchemes[$schemeName] = $schemes[$schemeName] }
    $themeNames = @($previewSchemes.Keys | Sort-Object)
    $themeItems = [ordered]@{}
    foreach ($themeName in $themeNames) { $themeItems[$themeName] = $themeName }

    $themePreview = {
        param($selectedTheme)
        if ($previewSchemes.ContainsKey($selectedTheme)) {
            $scheme = $previewSchemes[$selectedTheme]
            $background = Get-NearestConsoleColor $scheme.background
            $foreground = Get-NearestConsoleColor $scheme.foreground
            Write-Host " Theme sample: WSL prompt  user@host:~$ " -ForegroundColor $foreground -BackgroundColor $background
            foreach ($colorKey in @('black', 'red', 'green', 'yellow', 'blue', 'purple', 'cyan', 'white')) {
                $color = Get-NearestConsoleColor $scheme.$colorKey
                Write-Host '   ' -NoNewline -BackgroundColor $color
            }
            Write-Host ""
        }
        else {
            Write-Host " No configured color preview is available for this theme." -ForegroundColor DarkGray
        }
    }
    $themeToUse = Select-InteractiveItem -Title "Choose a terminal theme" -Items $themeItems -Footer "Color swatches approximate the Windows Terminal palette." -Preview $themePreview
    if ($null -eq $themeToUse) { return }

    $fontItems = Get-TerminalFontChoices
    $fontToUse = Select-InteractiveItem -Title "Choose a terminal font" -Items $fontItems -Footer "Hack Nerd Font, Hack Nerd Font Mono, and Hack Nerd Font Propo are always listed."
    if ($null -eq $fontToUse) { return }


    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    $altDir = Join-Path $scriptDir 'windows\manageDistrib'
    $terminalScriptPath = Join-Path $altDir 'terminalSettings.ps1'

    if (-not (Test-Path $terminalScriptPath)) {
        Write-Warning "Terminal settings script not found."
        Start-Sleep 7
        return
    }

    try {
        & $terminalScriptPath -profileName $instance -colorScheme $themeToUse -fontFace $fontToUse -ErrorAction Stop
        Write-Host "Terminal profile refreshed successfully"
    }
    catch {
        Write-Warning "Terminal profile refresh failed: $_"
        Start-Sleep 7
    }
}

function Menu-Uninstall {
    $instances = (wsl.exe --list --quiet 2>$null) -replace '\x00', '' |
                 ForEach-Object { $_.Trim() } |
                 Where-Object { $_ }
    if (-not $instances) { Write-Host "No WSL instances found."; Start-Sleep 2; return }

    $items = [ordered]@{}
    foreach ($name in $instances) { $items[$name] = $name }

    $instance = Select-InteractiveItem -Title "Uninstall WSL distribution" -Items $items -Footer (Get-StatusFooter)
    if ($null -eq $instance) { return }

    Uninstall-WSL -InstanceName $instance
}

function Menu-LocalSettings {
    $base = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    $dir  = Join-Path $base 'windows\localSettings'

    if (-not (Test-Path $dir)) { Write-Host "Local settings directory not found: $dir"; Start-Sleep 2; return }

    $files = Get-ChildItem $dir -Filter '*.ps1' -File | Where-Object { -not $_.Name.StartsWith('_') }
    if (-not $files) { Write-Host "No local settings scripts found."; Start-Sleep 2; return }

    $items = [ordered]@{}
    foreach ($f in $files) {
        $name = [IO.Path]::GetFileNameWithoutExtension($f.Name) -replace '[-_]', ' '
        $items[$f.FullName] = (Get-Culture).TextInfo.ToTitleCase($name)
    }

    $script = Select-InteractiveItem -Title "Local Windows settings" -Items $items -Footer (Get-StatusFooter)
    if ($null -eq $script) { return }

    try { & $script } catch { Write-Warning "Local settings script failed: $_" }
    Read-Host "Press Enter to return to menu..."
}

# =========================
# Main Loop
# =========================
function Clear-ConsoleInputBuffer {
    while ([Console]::KeyAvailable) {
        [Console]::ReadKey($true) | Out-Null
    }
}

function Show-Menu {
    Clear-ConsoleInputBuffer
    
    while ($true) {
        $items = [ordered]@{
            Install   = "Install Linux distribution"
            Refresh   = "Refresh Terminal Profile"
            Uninstall = "Uninstall WSL distribution"
            Local     = "Local Windows settings"
            Exit      = "Exit"
        }

        $action = Select-InteractiveItem -Title "WSL Workstation Setup" -Items $items -Footer (Get-StatusFooter) -KeyList @('Install', 'Refresh', 'Uninstall', 'Local', 'Exit')
        if ($null -eq $action -or $action -eq 'Exit') { return }
        switch ($action) {
            'Install'   { Menu-Install }
            'Refresh'   { Menu-refreshTerminal }
            'Uninstall' { Menu-Uninstall }
            'Local'     { Menu-LocalSettings }
        }
    }
}

# =========================
# Start
# =========================

Show-Menu

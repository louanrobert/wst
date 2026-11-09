param(
    [Parameter(Mandatory = $true)]
    [string]$profileName,

    [Parameter(Mandatory = $true)]
    [string]$colorScheme,

    [string]$fontFace = "Consolas",
    [int]$fontSize = 14
)

# Handle old and new Windows Terminal settings paths
$terminalSettingsPaths = @(
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
)

$settingsPath = $terminalSettingsPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $settingsPath) {
    Write-Warning "Windows Terminal settings.json not found (Windows Terminal may not be installed)."
    return
}

# Backup before editing
$backupPath = "$settingsPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item $settingsPath $backupPath -Force
Write-Host "Backup created: $backupPath"

# Load settings
$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

# Windows Terminal can create renamed copies when a custom scheme is duplicated. Keep one
# canonical entry and repair profile references to any generated "modified" names.
$darkPlusPattern = '^Dark\+(?: \(modified(?: \d+)?\))?$'
$darkPlusEntries = @($settings.schemes | Where-Object { $_.name -match $darkPlusPattern })
if ($darkPlusEntries.Count -gt 0) {
    $darkPlusScheme = $darkPlusEntries | Where-Object { $_.name -eq 'Dark+' } | Select-Object -First 1
    if (-not $darkPlusScheme) { $darkPlusScheme = $darkPlusEntries[0] }
    $darkPlusScheme.name = 'Dark+'
    $settings.schemes = @($settings.schemes | Where-Object { $_.name -notmatch $darkPlusPattern }) + $darkPlusScheme

    if ($settings.profiles -and $settings.profiles.list) {
        foreach ($profile in $settings.profiles.list) {
            if ($profile.colorScheme -match $darkPlusPattern) {
                $profile.colorScheme = 'Dark+'
            }
        }
    }
}
elseif ($colorScheme -eq 'Dark+') {
    $darkPlusScheme = @{
        name = 'Dark+'
        background = '#1E1E1E'
        foreground = '#D4D4D4'
        cursorColor = '#FFFFFF'
        selectionBackground = '#264F78'
        black = '#000000'
        red = '#CD3131'
        green = '#0DBC79'
        yellow = '#E5E510'
        blue = '#2472C8'
        purple = '#BC3FBC'
        cyan = '#11A8CD'
        white = '#E5E5E5'
        brightBlack = '#666666'
        brightRed = '#F14C4C'
        brightGreen = '#23D18B'
        brightYellow = '#F5F543'
        brightBlue = '#3B8EEA'
        brightPurple = '#D670D6'
        brightCyan = '#29B8DB'
        brightWhite = '#E5E5E5'
    }
    if ($null -eq $settings.schemes) {
        $settings | Add-Member -MemberType NoteProperty -Name schemes -Value @()
    }
    $settings.schemes = @($settings.schemes) + $darkPlusScheme
}

# Make sure list exists
if (-not $settings.profiles.list) { $settings.profiles.list = @() }

# Find profile in list
$profile_terminal = $settings.profiles.list | Where-Object { $_.name -eq $profileName }

if ($null -ne $profile_terminal) {

    # Add missing properties if they don't exist
    $profile_terminal | Add-Member -MemberType NoteProperty -Name colorScheme -Value $colorScheme -Force
    $profile_terminal | Add-Member -MemberType NoteProperty -Name opacity -Value 80 -Force
    $profile_terminal | Add-Member -MemberType NoteProperty -Name useAcrylic -Value $false -Force

    if (-not $profile_terminal.font) {
        $profile_terminal | Add-Member -MemberType NoteProperty -Name font -Value (@{}) -Force
    }

    $profile_terminal.font.face = $fontFace
    $profile_terminal.font.size = $fontSize

    Write-Host "Updated Terminal profile '$profileName' (theme=$colorScheme, font=$fontFace, size=$fontSize)"
}
else {
    throw "Profile '$profileName' not found"
}

# Save settings
$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
Write-Host "Saved Windows Terminal settings to $settingsPath"

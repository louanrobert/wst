# Sets up a WSL instance OracleLinux called "workstation" and runs bootstrap scripts.

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$WSLName = "workstation",

    [Parameter(Mandatory=$false)]
    [string]$DistroName = "OracleLinux_9_5",

    [Parameter(Mandatory=$false)]
    [string]$LinuxUser = "oracle",

    [Parameter(Mandatory=$false)]
    [bool]$Legacy = $true
)

# You can run this script directly, e.g.:
#   .\installOracle.ps1 -WSLName workstation -DistroName Oracle -LinuxUser oracle -Legacy $true
# Or let `menu.ps1` invoke it with named parameters.

# Ensure we're running from a Windows path (avoid WSL UNC path translation problems when calling wsl.exe)
Set-Location -Path $env:USERPROFILE

# 1) Check if instance do not already exists before attempting installation
$existingDistros = wsl.exe --list --quiet
if ($Legacy -and ($existingDistros -contains $DistroName)) {
    Write-Host "❌ A WSL instance named '$DistroName' already exists. Please uninstall it first or choose a different name." -ForegroundColor Red
    exit 1
} elseif ($existingDistros -contains $WSLName) {
    Write-Host "❌ A WSL instance named '$WSLName' already exists. Please uninstall it first or choose a different name." -ForegroundColor Red
    exit 1
}

# 2) quick check whether distro appears in the online list
$online = @(wsl.exe --list --online 2>$null)
if ($online.Count -gt 0 -and -not ($online -contains $DistroName)) {
    Write-Warning "Distribution '$DistroName' not listed in 'wsl --list --online'. It may be a legacy distro or have a different id."
    Write-Host "Available distributions:"
    wsl.exe --list --online
}

# 2) Install new WSL instance from Oracle base
# capture current instances so we can detect any newly registered name
$before = @(wsl.exe --list --quiet 2>$null)

if ($Legacy) {
    Write-Host "Legacy distribution requested: installing without --name..."
    $installOut = & wsl.exe --install $DistroName --no-launch 2>&1
    $installCode = $LASTEXITCODE
} else {
    Write-Host "Installing a new WSL instance named '$WSLName' from $DistroName..."
    # Try installing with --name (works for modern distros)
    $installOut = & wsl.exe --install --distribution $DistroName --name $WSLName --no-launch 2>&1
    $installCode = $LASTEXITCODE

    # If installer rejects --name (legacy distro), retry without --name
    if ($installCode -ne 0 -and ($installOut -match "--name.+not supported" -or $installOut -match "legacy")) {
        Write-Host "Installer rejected --name; retrying without --name..."
        $installOut = & wsl.exe --install --distribution $DistroName --no-launch 2>&1
        $installCode = $LASTEXITCODE
    }
}

# Find what got registered
$after = @(wsl.exe --list --quiet 2>$null)
$added = $after | Where-Object { $_ -notin $before }

if ($added.Count -eq 1) {
    $WSLName = $added[0]
    Write-Host "Detected registered instance name: $WSLName"
} elseif (-not ($after -contains $WSLName)) {
    Write-Host "❌ Installation failed. Could not find any newly registered WSL instance." -ForegroundColor Red
    Write-Host $installOut
    exit 1
}

# 3) Create new Linux user with UID 1000
Write-Host "Creating user '$LinuxUser' with UID 1000..."
wsl.exe -d $WSLName -u root bash -ic "adduser --uid 1000 --disabled-password --gecos '' $LinuxUser"
wsl.exe -d $WSLName -u root bash -ic "usermod -aG sudo $LinuxUser"

# 4) Grant passwordless sudo
Write-Host "Granting passwordless sudo to '$LinuxUser'..."
wsl.exe -d $WSLName -u root bash -ic "echo '$LinuxUser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$LinuxUser"
wsl.exe -d $WSLName -u root bash -ic "chmod 0440 /etc/sudoers.d/$LinuxUser"

# 5) Set DNS and default user in /etc/wsl.conf
Write-Host "Configuring DNS and setting default user..."
$wslConf = @"
[network]
generateResolvConf = false

[user]
default = $LinuxUser
"@
wsl.exe -d $WSLName -u root bash -ic "echo '$wslConf' > /etc/wsl.conf"
wsl.exe -d $WSLName -u root bash -ic "rm -f /etc/resolv.conf && echo 'nameserver 8.8.8.8' > /etc/resolv.conf && chattr +i /etc/resolv.conf"

# 6) Display Oracle version
Write-Host "Detecting the installed Oracle version..."
$version = wsl.exe -d $WSLName -u root bash -ic "grep PRETTY_NAME /etc/os-release"
Write-Host "This is your current Oracle version: $version"

# 7) Copy workspace scripts into WSL instance and bootstrap it
Write-Host "Copying workspace scripts into the WSL instance..."
$installerDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition     
$workspaceRoot  = Split-Path -Parent (Split-Path -Parent $installerDir)     # ../../windows/manageDistrib
$destPath = Join-Path -Path ("\\wsl$\" + $WSLName + "\home\" + $LinuxUser) -ChildPath 'workstation'
if (-not (Test-Path $destPath)) { New-Item -ItemType Directory -Path $destPath -Force | Out-Null }

# Copy all linux directory to the WSL instance
Copy-Item -Path (Join-Path $workspaceRoot 'linux\justfile') -Destination $destPath -Force
Copy-Item -Path (Join-Path $workspaceRoot 'linux\bootstrap.sh') -Destination $destPath -Force
Copy-Item -Path (Join-Path $workspaceRoot 'linux\bootstrap') -Destination (Join-Path $destPath 'bootstrap') -Recurse -Force
$stagedDotfiles = Join-Path (Split-Path -Parent $destPath) 'dotfiles'
New-Item -ItemType Directory -Path $stagedDotfiles -Force | Out-Null
Get-ChildItem -LiteralPath (Join-Path $workspaceRoot 'dotfiles') -Force |
    Copy-Item -Destination $stagedDotfiles -Recurse -Force

# Set ownership and mark scripts executable (use explicit chmod +x and retry if necessary)
Write-Host "Setting ownership and permissions inside the instance..."
$chownCmd = "chown -R ${LinuxUser}:${LinuxUser} /home/${LinuxUser}/workstation /home/${LinuxUser}/dotfiles"
$chmodCmd = "chmod -R u+rwX /home/${LinuxUser}/workstation && find /home/${LinuxUser}/workstation -type f -name '*.sh' -exec chmod +x {} +"
# Run both commands as root inside the new instance
wsl.exe -d $WSLName -u root bash -lc "$chownCmd && $chmodCmd"

# Confirm permission bits for bootstrap.sh; retry chmod if necessary
$checkExec = wsl.exe -d $WSLName -u root bash -lc "test -x /home/${LinuxUser}/workstation/bootstrap.sh && echo OK || echo NOEXEC"
if ($checkExec.Trim() -ne 'OK') {
    Write-Warning "bootstrap.sh is not executable (retrying chmod inside instance)..."
    wsl.exe -d $WSLName -u root bash -lc "$chmodCmd"
}

# Run bootstrap commands inside the instance as the linux user
Write-Host "Running bootstrap scripts inside the instance (this may take some time)..."
$bootstrapCmd = 'cd ~/workstation && ./bootstrap.sh'
wsl.exe -d $WSLName -u $LinuxUser bash -lc $bootstrapCmd

# 8) Shut down WSL instance to apply changes
Write-Host "Shutting down the '$WSLName' instance to apply changes..."
wsl.exe --terminate $WSLName

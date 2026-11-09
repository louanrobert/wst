# Sets up a WSL instance Ubuntu

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$WSLName = "workstation",

    [Parameter(Mandatory=$false)]
    [string]$DistroName = "Ubuntu",

    [Parameter(Mandatory=$false)]
    [string]$LinuxUser = "ubuntu",

    [Parameter(Mandatory=$false)]
    [bool]$Legacy = $true
)

# You can run this script directly, e.g.:
#   .\installUbuntuLTS.ps1 -WSLName workstation -DistroName Ubuntu -LinuxUser ubuntu
# Or let `menu.ps1` invoke it with named parameters.

# Check if instance do not already exists before attempting installation
Write-Host "Check if instance '$WSLName' do not already exists..."
$existingDistros = wsl.exe --list --quiet
if ($existingDistros -contains $WSLName) {
    Write-Host "[ERROR] A WSL instance named '$WSLName' already exists. Please uninstall it first or choose a different name." -ForegroundColor Red
    exit 1
}

# Install new WSL instance from Ubuntu base
Write-Host "Installing a new WSL instance named '$WSLName' from $DistroName..."
wsl.exe --install --distribution $DistroName --name $WSLName --no-launch
# After attempting to install
$existingDistros = wsl.exe --list --quiet
if ($existingDistros -notcontains $WSLName) {
    Write-Host "[ERROR] Installation failed. Could not find WSL instance '$WSLName'." -ForegroundColor Red
    exit 1
}

# Create new Linux user with UID 1000
Write-Host "Creating user '$LinuxUser' with UID 1000..."
wsl.exe -d $WSLName -u root bash -ic "adduser --uid 1000 --disabled-password --gecos '' $LinuxUser"
wsl.exe -d $WSLName -u root bash -ic "usermod -aG sudo $LinuxUser"

# Grant passwordless sudo
Write-Host "Granting passwordless sudo to '$LinuxUser'..."
wsl.exe -d $WSLName -u root bash -ic "echo '$LinuxUser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$LinuxUser"
wsl.exe -d $WSLName -u root bash -ic "chmod 0440 /etc/sudoers.d/$LinuxUser"

# Set default user in /etc/wsl.conf
Write-Host "Set WSL configuration..."
$wslConfContent = @"
[boot]
systemd=true
[user]
default=$LinuxUser
"@

wsl.exe -d $WSLName -u root bash -c "cat <<EOF > /etc/wsl.conf
$wslConfContent
EOF"

# Copy workspace scripts into WSL instance and bootstrap it
Write-Host "Define paths for copying scripts and dotfiles into the WSL instance..."
$installerDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition     
$workspaceRoot  = Split-Path -Parent (Split-Path -Parent $installerDir)     # ../../windows/manageDistrib
$destHome = "\\wsl$\$WSLName\home\$LinuxUser"
$destPath = Join-Path -Path $destHome -ChildPath 'workstation'
if (-not (Test-Path $destPath)) { New-Item -ItemType Directory -Path $destPath -Force | Out-Null }

# Copy all linux directory to the WSL instance
Write-Host "Copying workstation scripts into the WSL instance..."
Copy-Item -Path (Join-Path $workspaceRoot 'linux\*') -Destination $destPath -Recurse -Force

Write-Host "Copying dotfiles into the WSL instance..."
$sourceDotfiles = Join-Path $workspaceRoot 'dotfiles'
$stagedDotfiles = Join-Path $destHome 'dotfiles'
New-Item -ItemType Directory -Path $stagedDotfiles -Force | Out-Null
Get-ChildItem -LiteralPath $sourceDotfiles -Force |
    Copy-Item -Destination $stagedDotfiles -Recurse -Force
# Shell files are installed and backed up by add_zsh.sh, not overwritten here.
Get-ChildItem -LiteralPath $sourceDotfiles -Force |
    Where-Object { $_.Name -notin @('.zshrc', '.zshenv', '.aliases') } |
    Copy-Item -Destination $destHome -Recurse -Force

# Set ownership and mark scripts executable (use explicit chmod +x and retry if necessary)
Write-Host "Setting ownership and permissions inside the instance..."
$chownCmd = "chown -R ${LinuxUser}:${LinuxUser} /home/${LinuxUser}"
$chmodCmd = "chmod -R u+rwX /home/${LinuxUser}/workstation && find /home/${LinuxUser}/workstation -type f -name '*.sh' -exec chmod +x {} +"
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

# Shut down WSL instance to apply changes
Write-Host "Shutting down the '$WSLName' instance to apply changes..."
wsl.exe --terminate $WSLName

# After successful WSL install
Write-Host "Waiting for WSL instance '$wslName' to fully register..."
Start-Sleep -Seconds 10

# Restart WSL instance
Write-Host "Restarting the '$WSLName' instance..."
wsl.exe -d $WSLName -u $LinuxUser bash -ic "sleep 10 && exit"
Start-Sleep -Seconds 10

# Refresh Terminal profile
Start-Process wt.exe -ArgumentList "wsl.exe -d $WSLName -e sh -c 'sleep 10 && exit'" -WindowStyle Hidden
Start-Sleep -Seconds 10

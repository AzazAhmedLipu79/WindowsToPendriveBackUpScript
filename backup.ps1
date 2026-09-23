# ============================================================
# IMPORTANT LAPTOP BACKUP - V4
# Realtime logging + smart exclusions
# ============================================================

$ErrorActionPreference = "Continue"

# ------------------------------------------------------------
# CONFIG
# ------------------------------------------------------------

$userProfile = $env:USERPROFILE
$username    = $env:USERNAME

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "       IMPORTANT FILE BACKUP V4" -ForegroundColor Cyan
Write-Host "       REALTIME LOGGING ENABLED" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# FIND REMOVABLE DRIVES
# ------------------------------------------------------------

$drives = Get-Volume |
    Where-Object {
        $_.DriveLetter -and
        $_.DriveType -eq "Removable"
    }

if (-not $drives) {
    Write-Host "No removable USB drive detected." -ForegroundColor Red
    exit
}

Write-Host "Available USB drives:"
Write-Host ""

foreach ($drive in $drives) {
    $sizeGB = [math]::Round($drive.Size / 1GB, 2)

    Write-Host "$($drive.DriveLetter):  $($drive.FileSystemLabel)  $sizeGB GB"
}

Write-Host ""

$usbLetter = Read-Host "Enter USB drive letter"

$usbLetter = $usbLetter.Trim().TrimEnd(":")

$usbRoot = "$usbLetter`:\"

if (-not (Test-Path $usbRoot)) {
    Write-Host "Drive $usbLetter`: not found." -ForegroundColor Red
    exit
}

$backupRoot = Join-Path $usbRoot "LaptopBackup"

New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

$logFile = Join-Path $backupRoot "backup-log.txt"

# ------------------------------------------------------------
# LOG FUNCTION
# ------------------------------------------------------------

function Log {
    param(
        [string]$Message,
        [string]$Color = "Gray"
    )

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $line = "[$time] $Message"

    Write-Host $line -ForegroundColor $Color

    Add-Content -Path $logFile -Value $line
}

# ------------------------------------------------------------
# START
# ------------------------------------------------------------

Log "Backup started." "Green"
Log "User: $username"
Log "Profile: $userProfile"
Log "Destination: $backupRoot"
Log ""

# ------------------------------------------------------------
# EXCLUSIONS
# ------------------------------------------------------------

$excludeDirs = @(
    "node_modules",
    ".git",
    "vendor",
    "target",
    "dist",
    "build",
    ".next",
    ".nuxt",
    "coverage",
    "__pycache__",
    ".cache",
    "Cache",
    "Caches",
    ".npm",
    ".pnpm-store",
    ".yarn",
    "venv",
    ".venv",
    "env",
    "bin",
    "obj",
    ".idea",
    ".gradle",
    ".cargo\registry",
    ".cargo\git"
)

$excludeFiles = @(
    "*.log",
    "*.tmp",
    "*.temp",
    "*.cache",
    "*.pyc",
    "Thumbs.db",
    "desktop.ini"
)

# ------------------------------------------------------------
# COPY FUNCTION
# ------------------------------------------------------------

function Copy-SmartFolder {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path $Source)) {
        Log "SKIP - Not found: $Source" "DarkYellow"
        return
    }

    New-Item -ItemType Directory -Force -Path $Destination | Out-Null

    Log ""
    Log "SOURCE:      $Source" "Cyan"
    Log "DESTINATION: $Destination" "Cyan"

    # Build exclusion arguments
    $xdArgs = @()

    foreach ($dir in $excludeDirs) {
        $xdArgs += "/XD"
        $xdArgs += $dir
    }

    $xfArgs = @()

    foreach ($file in $excludeFiles) {
        $xfArgs += "/XF"
        $xfArgs += $file
    }

    # Robocopy with visible output
    $args = @(
        $Source
        $Destination
        "/E"
        "/R:1"
        "/W:1"
        "/COPY:DAT"
        "/DCOPY:DAT"
        "/TEE"
        "/ETA"
        "/FP"
        "/NP"
        "/XJ"
    )

    $args += $xdArgs
    $args += $xfArgs

    Log "Starting copy..." "Yellow"

    & robocopy @args

    $exitCode = $LASTEXITCODE

    if ($exitCode -le 7) {
        Log "Completed: $Source" "Green"
    }
    else {
        Log "Robocopy returned error code $exitCode for $Source" "Red"
    }
}

# ============================================================
# PERSONAL FILES
# ============================================================

Log ""
Log "============================================" "Magenta"
Log "PERSONAL FILES" "Magenta"
Log "============================================" "Magenta"

$personalFolders = @(
    "Desktop",
    "Documents",
    "Downloads",
    "Pictures",
    "Videos",
    "Music"
)

foreach ($folder in $personalFolders) {

    $source = Join-Path $userProfile $folder
    $destination = Join-Path $backupRoot "Personal\$folder"

    Copy-SmartFolder `
        -Source $source `
        -Destination $destination
}

# ============================================================
# SSH
# ============================================================

Log ""
Log "============================================" "Magenta"
Log "SSH / DEVELOPMENT CREDENTIALS" "Magenta"
Log "============================================" "Magenta"

$sshSource = Join-Path $userProfile ".ssh"
$sshDestination = Join-Path $backupRoot "Credentials\.ssh"

Copy-SmartFolder `
    -Source $sshSource `
    -Destination $sshDestination

# ============================================================
# GIT
# ============================================================

Log ""
Log "Backing up Git configuration..." "Yellow"

$gitFiles = @(
    ".gitconfig",
    ".git-credentials"
)

foreach ($file in $gitFiles) {

    $source = Join-Path $userProfile $file

    if (Test-Path $source) {

        $destination = Join-Path $backupRoot "Credentials\$file"

        Copy-Item `
            -LiteralPath $source `
            -Destination $destination `
            -Force

        Log "COPIED: $source" "Green"
    }
}

# ============================================================
# GITHUB CLI
# ============================================================

$githubSource = Join-Path $userProfile "AppData\Local\GitHub CLI"
$githubDestination = Join-Path $backupRoot "Credentials\GitHub CLI"

Copy-SmartFolder `
    -Source $githubSource `
    -Destination $githubDestination

# ============================================================
# AWS
# ============================================================

$awsSource = Join-Path $userProfile ".aws"
$awsDestination = Join-Path $backupRoot "Credentials\.aws"

Copy-SmartFolder `
    -Source $awsSource `
    -Destination $awsDestination

# ============================================================
# AZURE
# ============================================================

$azureSource = Join-Path $userProfile ".azure"
$azureDestination = Join-Path $backupRoot "Credentials\.azure"

Copy-SmartFolder `
    -Source $azureSource `
    -Destination $azureDestination

# ============================================================
# GOOGLE CLOUD
# ============================================================

$gcloudSource = Join-Path $userProfile "AppData\Roaming\gcloud"
$gcloudDestination = Join-Path $backupRoot "Credentials\gcloud"

Copy-SmartFolder `
    -Source $gcloudSource `
    -Destination $gcloudDestination

# ============================================================
# DOCKER
# ============================================================

$dockerSource = Join-Path $userProfile ".docker"
$dockerDestination = Join-Path $backupRoot "Credentials\.docker"

Copy-SmartFolder `
    -Source $dockerSource `
    -Destination $dockerDestination

# ============================================================
# IMPORTANT CONFIG FILES
# ============================================================

Log ""
Log "============================================" "Magenta"
Log "IMPORTANT CONFIG FILES" "Magenta"
Log "============================================" "Magenta"

$configFiles = @(
    ".npmrc",
    ".yarnrc",
    ".pypirc",
    ".editorconfig"
)

foreach ($file in $configFiles) {

    $source = Join-Path $userProfile $file

    if (Test-Path $source) {

        $destination = Join-Path $backupRoot "Credentials\$file"

        Copy-Item `
            -LiteralPath $source `
            -Destination $destination `
            -Force

        Log "COPIED: $source" "Green"
    }
}

# ============================================================
# FIND SECRET / CERTIFICATE FILES
# ============================================================

Log ""
Log "============================================" "Magenta"
Log "SEARCHING FOR IMPORTANT SECRET FILES" "Magenta"
Log "============================================" "Magenta"

$secretExtensions = @(
    "*.env",
    "*.env.*",
    "*.pem",
    "*.key",
    "*.p12",
    "*.pfx",
    "*.ovpn",
    "*.crt",
    "*.cer"
)

$secretDestination = Join-Path $backupRoot "Credentials\Discovered"

New-Item -ItemType Directory -Force -Path $secretDestination | Out-Null

foreach ($extension in $secretExtensions) {

    Log "Searching for $extension ..." "Yellow"

    try {

        Get-ChildItem `
            -Path $userProfile `
            -Filter $extension `
            -File `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue |

        Where-Object {

            $_.FullName -notmatch "\\node_modules\\" -and
            $_.FullName -notmatch "\\\.git\\" -and
            $_.FullName -notmatch "\\vendor\\" -and
            $_.FullName -notmatch "\\target\\" -and
            $_.FullName -notmatch "\\AppData\\Local\\Temp\\"
        } |

        ForEach-Object {

            $relative = $_.FullName.Substring($userProfile.Length).TrimStart("\","/")

            $safeName = $relative -replace "[\\/:*?""<>|]", "_"

            $destination = Join-Path $secretDestination $safeName

            Copy-Item `
                -LiteralPath $_.FullName `
                -Destination $destination `
                -Force

            Log "SECRET FILE: $relative" "Green"
        }

    }
    catch {
        Log "Search error: $($_.Exception.Message)" "Red"
    }
}

# ============================================================
# SOFTWARE / SYSTEM INFORMATION
# ============================================================

Log ""
Log "============================================" "Magenta"
Log "SYSTEM INFORMATION" "Magenta"
Log "============================================" "Magenta"

$systemInfo = Join-Path $backupRoot "SystemInfo"

New-Item -ItemType Directory -Force -Path $systemInfo | Out-Null

Log "Saving Windows information..."

Get-ComputerInfo |
    Out-File "$systemInfo\computer-info.txt"

Get-CimInstance Win32_Processor |
    Format-List * |
    Out-File "$systemInfo\cpu.txt"

Get-CimInstance Win32_PhysicalMemory |
    Format-List * |
    Out-File "$systemInfo\memory.txt"

Get-CimInstance Win32_DiskDrive |
    Format-List * |
    Out-File "$systemInfo\disks.txt"

Get-CimInstance Win32_VideoController |
    Format-List * |
    Out-File "$systemInfo\gpu.txt"

# ============================================================
# INSTALLED SOFTWARE
# ============================================================

Log "Saving installed software list..."

try {

    Get-ItemProperty `
        HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
        HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
        HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |

    Where-Object DisplayName |

    Select-Object DisplayName, DisplayVersion, Publisher |

    Sort-Object DisplayName |

    Format-Table -AutoSize |

    Out-File "$systemInfo\installed-software.txt"

}
catch {
    Log "Could not read installed software." "DarkYellow"
}

# ============================================================
# DEVELOPMENT VERSIONS
# ============================================================

Log ""
Log "Checking development tools..." "Yellow"

$devVersions = Join-Path $systemInfo "development-tools.txt"

"Development tool versions" | Out-File $devVersions
"==========================" | Out-File $devVersions -Append

$commands = @(
    "git --version",
    "node --version",
    "npm --version",
    "pnpm --version",
    "python --version",
    "pip --version",
    "php --version",
    "composer --version",
    "docker --version",
    "docker compose version",
    "rustc --version",
    "cargo --version",
    "go version",
    "java -version",
    "code --version"
)

foreach ($command in $commands) {

    try {

        Log "Checking: $command"

        $result = Invoke-Expression $command 2>&1

        $result | Out-File $devVersions -Append

    }
    catch {
        "NOT AVAILABLE: $command" | Out-File $devVersions -Append
    }
}

# ============================================================
# WSL
# ============================================================

Log ""
Log "Checking WSL..." "Yellow"

try {
    wsl --list --verbose |
        Out-File "$systemInfo\wsl.txt"

    Log "WSL information saved." "Green"
}
catch {
    Log "WSL not available." "DarkYellow"
}

# ============================================================
# BACKUP MANIFEST
# ============================================================

Log ""
Log "============================================" "Magenta"
Log "CREATING MANIFEST" "Magenta"
Log "============================================" "Magenta"

$manifest = Join-Path $backupRoot "MANIFEST.txt"

@"
IMPORTANT LAPTOP BACKUP
=======================

Date:
$(Get-Date)

Windows User:
$username

Original Profile:
$userProfile

Backup Location:
$backupRoot

Contents:

Personal/
    Desktop
    Documents
    Downloads
    Pictures
    Videos
    Music

Credentials/
    .ssh
    Git
    GitHub CLI
    AWS
    Azure
    Google Cloud
    Docker
    discovered .env / certificate / key files

SystemInfo/
    Windows information
    CPU
    RAM
    Disks
    GPU
    Installed software
    Development tools
    WSL

Excluded development/generated directories:

node_modules
.git
vendor
target
dist
build
.next
.nuxt
coverage
__pycache__
.cache
Cache
Caches
.npm
.pnpm-store
.yarn
venv
.venv
env
bin
obj

"@ | Out-File $manifest -Encoding UTF8

Log "Manifest created." "Green"

# ============================================================
# FINISH
# ============================================================

Log ""
Log "============================================" "Green"
Log "BACKUP FINISHED" "Green"
Log "============================================" "Green"

Log "Backup location: $backupRoot" "Green"

try {

    $backupSize = Get-ChildItem `
        $backupRoot `
        -Recurse `
        -File `
        -ErrorAction SilentlyContinue |
        Measure-Object Length -Sum

    $sizeGB = [math]::Round($backupSize.Sum / 1GB, 2)

    Log "Files backed up: $($backupSize.Count)" "Green"
    Log "Backup size: $sizeGB GB" "Green"

}
catch {
    Log "Could not calculate final backup size." "DarkYellow"
}

Log ""
Log "IMPORTANT: Your backup contains credentials and private keys."
Log "Keep the USB drive secure."
Log ""

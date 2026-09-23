# WindowsToPendriveBackUpScript 
A PowerShell script for backing up important files, development credentials, configuration files and system information before performing a fresh Windows installation.

## What This Script Does

The script creates a structured backup on a USB drive.

```text
LaptopBackup/
├── Personal/
│   ├── Desktop/
│   ├── Documents/
│   ├── Downloads/
│   ├── Pictures/
│   ├── Videos/
│   └── Music/
│
├── Credentials/
│   ├── .ssh/
│   ├── .aws/
│   ├── .azure/
│   ├── .docker/
│   ├── GitHub CLI/
│   └── Discovered/
│
├── SystemInfo/
│   ├── computer-info.txt
│   ├── cpu.txt
│   ├── memory.txt
│   ├── disks.txt
│   ├── gpu.txt
│   ├── installed-software.txt
│   ├── development-tools.txt
│   └── wsl.txt
│
├── MANIFEST.txt
└── backup-log.txt
```

## Main Features

### 1. Realtime Backup Output

The script shows Robocopy's progress directly in PowerShell.

You can see:

* Current source folder
* Destination folder
* Files being copied
* Copy progress
* Errors
* Completion status

The script also writes the activity to:

```text
LaptopBackup\backup-log.txt
```

### 2. Personal Files

The following folders are backed up:

```text
Desktop
Documents
Downloads
Pictures
Videos
Music
```

### 3. Development Credentials

The script backs up common developer configuration and credential locations:

```text
~\.ssh
~\.gitconfig
~\.git-credentials
~\.aws
~\.azure
~\AppData\Roaming\gcloud
~\.docker
```

It also checks for GitHub CLI configuration.

### 4. Secret and Certificate Files

The script searches for:

```text
*.env
*.env.*
*.pem
*.key
*.p12
*.pfx
*.ovpn
*.crt
*.cer
```

Discovered files are copied to:

```text
Credentials\Discovered\
```

The original relative path is included in the filename to help identify where the file came from.

### 5. Development Folder Exclusions

The script intentionally skips common generated or unnecessarily large directories:

```text
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
```

This prevents the backup from becoming unnecessarily large.

### 6. System Information

The script saves information useful when rebuilding the machine after Windows installation.

It records:

* Windows information
* CPU
* RAM
* Disks
* GPU
* Installed software
* Development tool versions
* WSL information

Development tools checked include:

```text
Git
Node.js
npm
pnpm
Python
pip
PHP
Composer
Docker
Docker Compose
Rust
Cargo
Go
Java
VS Code
```

If a tool is not installed, it is recorded as unavailable.

## Requirements

* Windows 10 or Windows 11
* PowerShell
* USB drive
* Administrator PowerShell is recommended
* Enough free space on the USB drive

## How to Run

Place the script somewhere convenient, for example:

```text
C:\Users\<username>\Desktop\back.ps1
```

Open **PowerShell as Administrator**.

Run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

Then run:

```powershell
& "$env:USERPROFILE\Desktop\back.ps1"
```

The script will detect removable drives and ask:

```text
Enter USB drive letter:
```

For example:

```text
D
```

The backup will then be created at:

```text
D:\LaptopBackup
```

## Before Running

Make sure the USB drive is connected.

Also make sure it has enough free space.

You can check it with:

```powershell
Get-Volume
```

## After the Backup

Check:

```text
D:\LaptopBackup
```

Important files to inspect:

```text
MANIFEST.txt
backup-log.txt
Credentials\
Personal\
SystemInfo\
```

You should manually verify that your important files are present before wiping the internal SSD.

For example:

```powershell
Get-ChildItem D:\LaptopBackup -Recurse -File |
    Measure-Object Length -Sum
```

## Important Security Warning

The backup may contain highly sensitive information, including:

* SSH private keys
* `.env` files
* API credentials
* Cloud credentials
* Docker credentials
* Git credentials
* Certificates
* Private keys

Treat the USB drive as sensitive.

Do **not** upload the backup publicly or share the `Credentials` directory.

After the fresh Windows installation, copy credentials back only when they are actually needed.

## What Is NOT Guaranteed to Be Backed Up

This script does not guarantee preservation of:

* Browser saved passwords
* Windows Credential Manager entries
* Windows Hello credentials
* Installed applications themselves
* Application licenses
* Microsoft Store application state
* Hardware-specific drivers
* Encrypted Windows data that requires the old Windows installation

Browser passwords should be handled through the browser's supported sync/export mechanism before formatting the old Windows installation.

## Why Generated Folders Are Excluded

Development projects often contain very large generated directories.

For example:

```text
node_modules/
target/
vendor/
dist/
build/
```

These can usually be regenerated from project manifests.

Examples:

```text
npm install
pnpm install
cargo build
composer install
```

The source code and configuration are more important to preserve.

## Safety

The script is designed to **copy** files.

It does not intentionally delete files from the Windows installation.

Stopping the script with:

```text
Ctrl+C
```

will stop the backup process. It does not delete the original files.

However, always verify the backup before formatting the internal drive.

## Backup Checklist

Before reinstalling Windows:

* [ ] Backup completed
* [ ] `backup-log.txt` checked
* [ ] `MANIFEST.txt` checked
* [ ] Desktop checked
* [ ] Documents checked
* [ ] Downloads checked
* [ ] Projects/source code checked
* [ ] `.ssh` checked
* [ ] Git configuration checked
* [ ] Cloud credentials checked
* [ ] `.env` files checked
* [ ] Private keys/certificates checked
* [ ] Important browser accounts synchronized
* [ ] Important 2FA/recovery methods available
* [ ] USB backup opens correctly
* [ ] Backup size looks reasonable

Only after verifying the backup should you proceed with deleting the old Windows/Linux partitions.

## License

Personal utility script. Modify and use as needed.

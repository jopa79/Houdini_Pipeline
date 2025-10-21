# Windows Setup Guide
**Houdini Pipeline v3.0 for Windows 10/11**

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Detailed Installation](#detailed-installation)
4. [Configuration](#configuration)
5. [Usage](#usage)
6. [Troubleshooting](#troubleshooting)
7. [FAQ](#faq)

---

## Prerequisites

### Required Software

| Software | Minimum Version | Download Link | Purpose |
|----------|----------------|---------------|---------|
| **Windows** | 10 (1809) or 11 | N/A | Operating system |
| **PowerShell** | 5.1 | Included with Windows 10/11 | Script execution |
| **Houdini** | 17.5+ | [Download](https://www.sidefx.com/download/) | Target application |

### Recommended Software

| Software | Purpose | Download Link |
|----------|---------|---------------|
| **Git for Windows** | Package management | [Download](https://git-scm.com/download/win) |
| **PowerShell 7.4+** | Better performance (optional) | [Download](https://github.com/PowerShell/PowerShell/releases) |
| **Windows Terminal** | Better terminal experience (optional) | Microsoft Store |

### System Requirements

- **RAM:** 8 GB minimum, 16 GB recommended
- **Disk Space:** 500 MB for pipeline + packages, 5+ GB for Houdini
- **Network:** Internet connection for initial package download
- **Permissions:** User-level (no admin required for basic operation)

---

## Quick Start

**For users who just want to get started quickly:**

### 1. Download the Pipeline

**Option A: Using Git (Recommended)**
```cmd
cd %USERPROFILE%\Documents
git clone https://github.com/jopa79/Houdini_Pipeline.git
cd Houdini_Pipeline
```

**Option B: Download ZIP**
1. Download from: https://github.com/jopa79/Houdini_Pipeline/archive/refs/heads/main.zip
2. Extract to: `C:\Users\<YourName>\Documents\Houdini_Pipeline`

### 2. Run Diagnostic Check

```cmd
cd Houdini_Pipeline
powershell -ExecutionPolicy Bypass -File windows\Test-Pipeline.ps1
```

This will check if everything is configured correctly.

### 3. Launch Houdini

**Double-click:**
```
windows\Houdini_Launcher.bat
```

Or from command line:
```cmd
cd windows
Houdini_Launcher.bat
```

Done! Houdini should launch with the pipeline configured.

---

## Detailed Installation

### Step 1: Install Prerequisites

#### Install Houdini

1. Download Houdini from [SideFX](https://www.sidefx.com/download/)
2. Run the installer
3. Default installation path: `C:\Program Files\Side Effects Software\Houdini <version>`
4. Note your version number (e.g., `19.5.640`)

#### Install Git for Windows (Optional but Recommended)

1. Download from [git-scm.com](https://git-scm.com/download/win)
2. Run the installer
3. **Important settings during installation:**
   - Git Bash: Yes (recommended)
   - Add to PATH: Yes
   - Line ending conversion: Checkout as-is, commit as-is
4. Verify installation:
   ```cmd
   git --version
   ```

### Step 2: Download Houdini Pipeline

#### Method 1: Git Clone (Recommended)

Open Command Prompt or PowerShell:

```powershell
# Navigate to where you want to install
cd $env:USERPROFILE\Documents

# Clone the repository
git clone https://github.com/jopa79/Houdini_Pipeline.git

# Enter the directory
cd Houdini_Pipeline
```

#### Method 2: Download ZIP

1. Visit: https://github.com/jopa79/Houdini_Pipeline
2. Click "Code" → "Download ZIP"
3. Extract to a permanent location, e.g.:
   - `C:\Users\<YourName>\Documents\Houdini_Pipeline`
   - Or `C:\Pipeline\Houdini_Pipeline`

**Important:** Do not place in a temporary location!

### Step 3: Run Diagnostic Tests

Open PowerShell in the Houdini_Pipeline directory:

```powershell
# Navigate to pipeline directory
cd C:\Users\<YourName>\Documents\Houdini_Pipeline

# Run diagnostic script
.\windows\Test-Pipeline.ps1
```

The diagnostic script will check:
- ✓ PowerShell version
- ✓ Windows version
- ✓ Pipeline file structure
- ✓ Houdini installation
- ✓ Git installation
- ✓ Network connectivity
- ✓ Package repositories
- ✓ System resources

**If all tests pass**, you're ready to go!

**If tests fail**, see [Troubleshooting](#troubleshooting) below.

### Step 4: First Launch

#### Option A: Double-Click (Easiest)

1. Navigate to: `Houdini_Pipeline\windows\`
2. Double-click: `Houdini_Launcher.bat`
3. Follow the prompts

#### Option B: Command Line

Open Command Prompt:

```cmd
cd C:\Users\<YourName>\Documents\Houdini_Pipeline\windows
Houdini_Launcher.bat
```

Or PowerShell:

```powershell
cd C:\Users\<YourName>\Documents\Houdini_Pipeline\windows
.\Houdini_Launcher.ps1
```

#### First Launch Checklist

On first launch, the script will:
1. Auto-detect pipeline path ✓
2. Ask if you want to download/update packages (recommend: Yes)
3. Clone external packages (MOPS, qLib, etc.) - **this takes time!**
4. Create project folder structure
5. Generate jump.pref file
6. Launch Houdini

**Be patient during first launch** - downloading packages can take 5-10 minutes depending on your internet connection.

---

## Configuration

### Environment Variables (Optional)

You can customize behavior using environment variables:

#### Set Houdini Version

```powershell
# PowerShell
$env:HOUDINI_VERSION = "19.5.640"
.\windows\Houdini_Launcher.ps1

# OR set permanently (User level)
[Environment]::SetEnvironmentVariable("HOUDINI_VERSION", "19.5.640", "User")
```

```cmd
REM Command Prompt
set HOUDINI_VERSION=19.5.640
windows\Houdini_Launcher.bat

REM OR set permanently
setx HOUDINI_VERSION "19.5.640"
```

#### Control Repository Updates

```powershell
# Always update repositories (non-interactive)
$env:HOUDINI_UPDATE_REPOS = "1"
.\windows\Houdini_Launcher.ps1

# Never update repositories (non-interactive)
$env:HOUDINI_UPDATE_REPOS = "0"
.\windows\Houdini_Launcher.ps1
```

#### Custom Library Paths

```powershell
# Override default library paths
$env:L_HDRI = "D:\Assets\HDRI"
$env:L_TEXTURES = "D:\Assets\Textures"
$env:L_3DMODELS = "D:\Assets\Models"
.\windows\Houdini_Launcher.ps1
```

#### Custom Pipeline Path

```powershell
# If auto-detection doesn't work
$env:HOUDINI_PIPELINE = "C:\Pipeline\Houdini_Pipeline"
.\windows\Houdini_Launcher.ps1
```

### Command-Line Options

The PowerShell launcher supports parameters:

```powershell
# Update repositories (non-interactive)
.\windows\Houdini_Launcher.ps1 -UpdateRepos

# Skip repository checks (non-interactive)
.\windows\Houdini_Launcher.ps1 -SkipRepos

# Override Houdini version
.\windows\Houdini_Launcher.ps1 -Version "19.5.640"

# Combine options
.\windows\Houdini_Launcher.ps1 -UpdateRepos -Version "19.5.640"
```

### PowerShell Execution Policy

If you get an execution policy error:

```powershell
# Option 1: Set policy for current user (recommended)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Option 2: Bypass for single script (temporary)
powershell -ExecutionPolicy Bypass -File windows\Houdini_Launcher.ps1
```

**The batch wrapper handles this automatically!**

---

## Usage

### Basic Usage

**Launch Houdini with pipeline:**
```cmd
windows\Houdini_Launcher.bat
```

**Check pipeline health:**
```cmd
powershell -ExecutionPolicy Bypass -File windows\Test-Pipeline.ps1
```

### Advanced Usage

**Non-Interactive Mode (for automation/scripts):**
```powershell
# Set environment variables for non-interactive mode
$env:HOUDINI_UPDATE_REPOS = "1"
$env:HOUDINI_VERSION = "19.5.640"

# Launch
.\windows\Houdini_Launcher.ps1 -UpdateRepos
```

**Launch from specific project folder:**
```cmd
cd C:\Projects\MyHoudiniProject
C:\Users\<YourName>\Documents\Houdini_Pipeline\windows\Houdini_Launcher.bat
```

The launcher will:
- Set `HIP` and `JOB` to current directory
- Create project folders in current directory
- Launch Houdini with current directory as project

**View logs:**
```cmd
cd logs
type houdini_launch_<timestamp>.log
```

### Creating Desktop Shortcuts

**Right-click method:**
1. Right-click `windows\Houdini_Launcher.bat`
2. "Send to" → "Desktop (create shortcut)"
3. Rename shortcut to "Houdini Pipeline"

**Or manually:**
1. Right-click desktop → New → Shortcut
2. Target: `C:\Users\<YourName>\Documents\Houdini_Pipeline\windows\Houdini_Launcher.bat`
3. Name: "Houdini Pipeline"
4. Optional: Change icon to Houdini icon

---

## Troubleshooting

### Common Issues

#### 1. "PowerShell script not running"

**Error:**
```
File cannot be loaded because running scripts is disabled on this system
```

**Solution:**
```powershell
# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Or use the batch wrapper which bypasses this automatically.

---

#### 2. "Git not found"

**Error:**
```
Git is not installed or not in PATH
```

**Solution:**
1. Download Git for Windows: https://git-scm.com/download/win
2. Install with default settings
3. Restart PowerShell/Command Prompt
4. Verify: `git --version`

---

#### 3. "Houdini executable not found"

**Error:**
```
ERROR: Houdini installation not found
```

**Solution:**

**Check Houdini version:**
```powershell
# Set correct version
$env:HOUDINI_VERSION = "19.5.640"  # Use YOUR version
.\windows\Houdini_Launcher.ps1
```

**Or set custom path:**
```powershell
$env:HOUDINI_INSTALL_PATH = "C:\Custom\Path\To\Houdini"
.\windows\Houdini_Launcher.ps1
```

---

#### 4. "Package download failed"

**Error:**
```
Failed to update/install package
```

**Solution:**

**Check network:**
```powershell
# Test connectivity
Test-NetConnection github.com -Port 443
```

**Check firewall/proxy:**
- Ensure Git can access GitHub
- Configure proxy if needed:
  ```cmd
  git config --global http.proxy http://proxy.example.com:8080
  ```

**Retry manually:**
```powershell
# Navigate to packages directory
cd C:\Users\<YourName>\Documents\Houdini_Pipeline\PACKAGES

# Clone manually
git clone https://github.com/toadstorm/MOPS.git
```

---

#### 5. "Permission denied"

**Error:**
```
Access to the path is denied
```

**Solution:**

**Check folder permissions:**
1. Right-click pipeline folder → Properties → Security
2. Ensure your user has "Full control"

**Or move to user directory:**
```cmd
# Move pipeline to Documents folder
move C:\Pipeline\Houdini_Pipeline %USERPROFILE%\Documents\
```

---

#### 6. "Path too long"

**Error:**
```
The specified path, file name, or both are too long
```

**Solution:**

**Enable long paths in Windows 10/11:**
1. Open Group Policy Editor: `gpedit.msc`
2. Navigate to: Computer Configuration → Administrative Templates → System → Filesystem
3. Enable: "Enable Win32 long paths"
4. Restart computer

**Or use registry:**
```powershell
# Run as Administrator
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
```

**Or install pipeline in shorter path:**
```cmd
# Instead of: C:\Users\<LongUsername>\Documents\My Projects\VFX\Houdini\Pipeline
# Use:        C:\Pipeline\Houdini_Pipeline
```

---

### Checking Logs

All operations are logged to files in the `logs/` directory:

```cmd
cd C:\Users\<YourName>\Documents\Houdini_Pipeline
cd logs
dir

REM View latest log
type houdini_launch_*.log
```

Look for `[ERROR]` and `[WARNING]` entries for troubleshooting.

---

## FAQ

### Q: Do I need administrator rights?

**A:** No! The pipeline works at user-level. However, you need admin rights if:
- Installing Houdini to `C:\Program Files`
- Enabling long paths in Windows
- Installing Git for Windows system-wide

### Q: Can I use this with multiple Houdini versions?

**A:** Yes! Set the version before launching:
```powershell
$env:HOUDINI_VERSION = "19.5.640"
.\windows\Houdini_Launcher.ps1
```

Or create multiple shortcuts with different versions:
```cmd
REM Houdini 19.bat
set HOUDINI_VERSION=19.5.640
windows\Houdini_Launcher.bat
```

### Q: Does this work with Houdini Apprentice/Indie?

**A:** Yes! The launcher works with all Houdini versions:
- Houdini FX (commercial)
- Houdini Core (commercial)
- Houdini Indie (indie license)
- Houdini Apprentice (free learning version)

The executable name is detected automatically.

### Q: Can I use this without Git?

**A:** Yes, but you'll miss automatic package management. Packages must be downloaded manually:
1. Download from GitHub as ZIP files
2. Extract to `PACKAGES/` directory
3. Launch normally

### Q: Where are my library paths?

**A:** Default Windows library paths:
```
%USERPROFILE%\Documents\Library\HDRI
%USERPROFILE%\Documents\Library\TEXTURES
%USERPROFILE%\Documents\Library\3DMODELS
%USERPROFILE%\Documents\Library\FOOTAGE
%USERPROFILE%\Documents\Library\IES_LIGHTS
```

These folders are created automatically and added to Houdini's file browser (jump.pref).

### Q: Can I run this from a network drive?

**A:** Yes, but performance may be slower. UNC paths are supported:
```cmd
\\server\share\Pipeline\Houdini_Pipeline\windows\Houdini_Launcher.bat
```

### Q: How do I update the pipeline?

**A:** If installed via Git:
```cmd
cd Houdini_Pipeline
git pull
```

If downloaded as ZIP, re-download and extract (your project files are safe).

### Q: Can I customize the folder structure?

**A:** Yes! Edit `Folderlist.txt` to add/remove folders:
```
assets/abc
assets/textures
my_custom_folder
another_folder/subfolder
```

### Q: How do I uninstall?

**A:** Simply delete the Houdini_Pipeline folder. No system modifications are made.

---

## Next Steps

- **Read the main README:** `../README.md`
- **View changelog:** `../CHANGELOG.md`
- **Check troubleshooting:** See above section
- **Configure custom paths:** See [Configuration](#configuration)

---

## Getting Help

**Issues with the pipeline?**
- Check logs in `logs/` directory
- Run diagnostic: `.\windows\Test-Pipeline.ps1`
- Report issues: https://github.com/jopa79/Houdini_Pipeline/issues

**Houdini-specific questions?**
- SideFX Documentation: https://www.sidefx.com/docs/
- SideFX Forum: https://www.sidefx.com/forum/

---

**Version:** 3.0.0
**Last Updated:** 2025-10-21
**Platform:** Windows 10/11

# Windows 11 Support Implementation Plan
**Houdini Pipeline v3.0**

---

## Executive Summary

This document outlines the complete implementation plan for adding Windows 11 support to the Houdini Pipeline. The goal is to create a robust, production-ready Windows version while maintaining full backward compatibility with existing macOS and Linux installations.

**Target Timeline:** 4-5 days
**Approach:** PowerShell + Batch Wrapper + WSL Support
**Compatibility:** Windows 10 (1809+) and Windows 11

---

## Table of Contents

1. [Implementation Approach](#implementation-approach)
2. [Architecture Overview](#architecture-overview)
3. [Phase-by-Phase Implementation](#phase-by-phase-implementation)
4. [Technical Requirements](#technical-requirements)
5. [File Structure](#file-structure)
6. [Key Adaptation Points](#key-adaptation-points)
7. [Testing Strategy](#testing-strategy)
8. [Documentation Requirements](#documentation-requirements)
9. [Risk Assessment](#risk-assessment)
10. [Success Criteria](#success-criteria)

---

## Implementation Approach

### Chosen Strategy: **Triple Support (PowerShell + WSL + Hybrid)**

We will implement Windows support using a **three-pronged approach**:

1. **PowerShell Scripts** (Primary) - Native Windows 11 support
   - Full PowerShell implementations of all scripts
   - Batch wrappers for easy double-click execution
   - Modern, maintainable code with proper error handling
   - **Best for:** Windows-native users, production environments

2. **WSL Support** (Alternative) - Minimal changes to bash scripts
   - Enhanced bash scripts with WSL detection
   - Path translation for Windows/WSL interop
   - Leverages existing codebase
   - **Best for:** Linux-familiar users, development workflows

3. **Hybrid Detection** - Automatic environment detection
   - Single launcher that detects OS and execution environment
   - Seamlessly switches between PowerShell, bash, and WSL
   - **Best for:** Multi-platform teams

### Why This Approach?

| Aspect | Justification |
|--------|---------------|
| **User Choice** | Users can choose their preferred execution environment |
| **Compatibility** | Covers all Windows usage scenarios |
| **Maintainability** | PowerShell as primary, bash as fallback |
| **Migration Path** | Gradual adoption for existing users |
| **Future-Proof** | PowerShell is Microsoft's strategic direction |

---

## Architecture Overview

### Current Architecture (v2.0)

```
┌─────────────────────────────────────────┐
│          User Launches Script           │
└───────────────┬─────────────────────────┘
                │
        ┌───────▼────────┐
        │ Houdini_Launcher│
        │     .sh         │
        └───────┬─────────┘
                │
        ┌───────▼─────────┐
        │   OS Detection  │
        │   (uname)       │
        └───────┬─────────┘
                │
        ┌───────▼─────────┐
        │Houdini_Globals  │
        │     .sh         │
        └───────┬─────────┘
                │
    ┌───────────┴───────────┐
    │                       │
┌───▼──────┐        ┌──────▼───┐
│  macOS   │        │  Linux   │
│  Config  │        │  Config  │
└──────────┘        └──────────┘
```

### New Architecture (v3.0 with Windows)

```
┌──────────────────────────────────────────────────────────┐
│              User Launches Script                        │
│   (Double-click .bat, .ps1, .sh, or .command)           │
└────────────────────┬─────────────────────────────────────┘
                     │
        ┌────────────▼────────────┐
        │  Platform Detector      │
        │  (Auto-detect OS/Shell) │
        └────────────┬────────────┘
                     │
         ┌───────────┼───────────┐
         │           │           │
    ┌────▼───┐  ┌───▼────┐  ┌──▼─────┐
    │Windows │  │  WSL   │  │Unix-like│
    │Native  │  │(Linux) │  │(Mac/Lnx)│
    └────┬───┘  └───┬────┘  └──┬─────┘
         │          │           │
    ┌────▼───────┐  │      ┌───▼──────┐
    │PowerShell  │  │      │   Bash   │
    │Scripts     │  │      │  Scripts │
    │(.ps1)      │  │      │  (.sh)   │
    └────┬───────┘  │      └───┬──────┘
         │          │           │
    ┌────▼──────────┴───────────▼──────┐
    │      Houdini_Globals             │
    │  (Platform-Specific Config)      │
    └────────────┬─────────────────────┘
                 │
    ┌────────────┴────────────┐
    │                         │
┌───▼──────┐  ┌──────▼───┐  ┌▼────────┐
│ Windows  │  │  macOS   │  │  Linux  │
│  Config  │  │  Config  │  │  Config │
└──────────┘  └──────────┘  └─────────┘
```

---

## Phase-by-Phase Implementation

### **Phase 1: PowerShell Core Scripts (Days 1-2)**

#### **Day 1 Morning: Houdini_Globals.ps1**

**Tasks:**
1. Create `Houdini_Globals.ps1` with full functionality
2. Implement Windows-specific path detection
3. Port all global configuration settings
4. Implement Git retry functions in PowerShell
5. Add Windows path normalization functions

**Deliverables:**
- `Houdini_Globals.ps1` (complete)
- Unit tests for path detection
- Documentation comments in script

**Key Functions to Implement:**
```powershell
# Core functions needed
function Write-Log { }
function Test-HoudiniInstallation { }
function ConvertTo-HoudiniPath { }
function Update-GitRepo { }
function Invoke-GitRetry { }
function Set-WindowsEnvironment { }
```

**Implementation Checklist:**
- [ ] Log function with timestamp and file output
- [ ] OS detection ($IsWindows)
- [ ] Houdini version management with env var override
- [ ] Windows installation path detection
- [ ] Package path configuration
- [ ] Git retry logic with exponential backoff
- [ ] Repository update/clone functions
- [ ] Path normalization (backslash → forward slash)
- [ ] HOUDINI_PATH construction with semicolons
- [ ] Environment variable validation
- [ ] Error handling for all operations

#### **Day 1 Afternoon: Houdini_Launcher.ps1**

**Tasks:**
1. Create `Houdini_Launcher.ps1` with full functionality
2. Implement pipeline path auto-detection
3. Add comprehensive logging
4. Port folder creation logic
5. Implement jump.pref generation

**Deliverables:**
- `Houdini_Launcher.ps1` (complete)
- Log file output validation
- Cross-reference with bash version

**Key Functions to Implement:**
```powershell
# Core functions needed
function Initialize-Logging { }
function Get-PipelinePath { }
function Test-Prerequisites { }
function New-ProjectFolders { }
function New-JumpPreferences { }
function Start-Houdini { }
```

**Implementation Checklist:**
- [ ] Script parameter handling
- [ ] Auto-detect HOUDINI_PIPELINE path
- [ ] Initialize logging system
- [ ] Validate pipeline path and files
- [ ] Source Houdini_Globals.ps1
- [ ] Set HIP/JOB variables
- [ ] Create project folder structure
- [ ] Generate jump.pref file
- [ ] Launch Houdini with error handling
- [ ] Non-interactive mode support
- [ ] Help/usage information

#### **Day 2 Morning: Batch Wrappers & Testing**

**Tasks:**
1. Create `Houdini_Launcher.bat` wrapper
2. Create `Houdini_Globals.bat` (if needed for legacy)
3. Test PowerShell execution policy handling
4. Test double-click execution
5. Test command-line execution

**Deliverables:**
- `Houdini_Launcher.bat` (complete)
- Execution tested on Windows 11
- Desktop shortcut template

**Batch Wrapper Template:**
```batch
@echo off
REM Houdini Pipeline Launcher - Windows Wrapper
REM Version 3.0

setlocal enabledelayedexpansion

echo ==========================================
echo Houdini Pipeline Launcher (Windows)
echo ==========================================
echo.

REM Check PowerShell availability
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PowerShell not found
    echo Please ensure PowerShell 5.1+ is installed
    pause
    exit /b 1
)

REM Get PowerShell version
for /f "tokens=*" %%v in ('powershell -Command "$PSVersionTable.PSVersion.Major"') do set PS_VERSION=%%v

if %PS_VERSION% LSS 5 (
    echo ERROR: PowerShell version %PS_VERSION% is too old
    echo Please upgrade to PowerShell 5.1 or later
    pause
    exit /b 1
)

echo PowerShell version: %PS_VERSION%
echo.

REM Launch PowerShell script with bypass
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0Houdini_Launcher.ps1" %*

REM Check exit code
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ==========================================
    echo ERROR: Launcher failed with code %ERRORLEVEL%
    echo Check the log file for details
    echo ==========================================
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Launcher completed successfully
```

**Implementation Checklist:**
- [ ] PowerShell availability check
- [ ] PowerShell version check (5.1+)
- [ ] Execution policy bypass
- [ ] Error code propagation
- [ ] User-friendly error messages
- [ ] Pause on error for debugging
- [ ] Pass command-line arguments
- [ ] Silent mode support

#### **Day 2 Afternoon: Windows-Specific Features**

**Tasks:**
1. Implement Windows library path defaults
2. Add Windows jump.pref generation
3. Create desktop shortcut creation script
4. Add Start Menu integration (optional)
5. Test with different Houdini versions

**Deliverables:**
- Windows library path configuration
- Jump preferences working on Windows
- Shortcut creation utility

**Windows Library Paths:**
```powershell
# Default Windows library paths
$defaultLibraryPaths = @{
    L_HDRI = "$env:USERPROFILE\Documents\Library\HDRI"
    L_TEXTURES = "$env:USERPROFILE\Documents\Library\TEXTURES"
    L_3DMODELS = "$env:USERPROFILE\Documents\Library\3DMODELS"
    L_3DScans = "$env:USERPROFILE\Documents\Library\3DScans"
    L_FOOTAGE = "$env:USERPROFILE\Documents\Library\FOOTAGE"
    L_IES_Lights = "$env:USERPROFILE\Documents\Library\IES_LIGHTS"
}

# Override with environment variables if set
foreach ($key in $defaultLibraryPaths.Keys) {
    if (-not (Test-Path env:$key)) {
        Set-Item -Path "env:$key" -Value $defaultLibraryPaths[$key]
    }
}
```

**Implementation Checklist:**
- [ ] Windows-specific library paths
- [ ] Path existence validation
- [ ] Create library folders on first run
- [ ] Jump.pref with Windows paths
- [ ] Desktop shortcut creation
- [ ] Icon association (optional)
- [ ] File type association (optional)

---

### **Phase 2: WSL Support Enhancement (Day 3)**

#### **Day 3 Morning: WSL Detection in Bash**

**Tasks:**
1. Add WSL detection to `Houdini_Globals.sh`
2. Implement path translation functions
3. Configure Windows-specific settings in WSL
4. Test launching Windows Houdini from WSL

**Deliverables:**
- Enhanced `Houdini_Globals.sh` with WSL support
- Path translation utilities
- WSL-specific configuration

**WSL Detection Code:**
```bash
#!/bin/bash

# Detect if running in WSL
detect_wsl() {
    WSL=false
    WSL_VERSION=""

    # Method 1: Check WSL environment variable
    if [[ -n "$WSL_DISTRO_NAME" ]]; then
        WSL=true
        log "Running in WSL: $WSL_DISTRO_NAME"

        # Detect WSL version
        if [[ -n "$WSL_INTEROP" ]]; then
            WSL_VERSION="2"
        else
            WSL_VERSION="1"
        fi
        log "WSL Version: $WSL_VERSION"
        return 0
    fi

    # Method 2: Check /proc/version
    if [[ -f /proc/version ]]; then
        if grep -qi microsoft /proc/version; then
            WSL=true
            log "Running in WSL (detected via /proc/version)"

            # Try to determine WSL version
            if grep -qi "microsoft-standard" /proc/version; then
                WSL_VERSION="2"
            else
                WSL_VERSION="1"
            fi
            log "WSL Version: $WSL_VERSION"
            return 0
        fi
    fi

    # Method 3: Check kernel release
    if uname -r | grep -qi microsoft; then
        WSL=true
        log "Running in WSL (detected via uname)"
        return 0
    fi

    return 1
}

# Path translation functions
win_to_wsl() {
    local winpath="$1"
    # Convert C:\path\to\file to /mnt/c/path/to/file
    echo "$winpath" | sed -e 's|^\([A-Za-z]\):|/mnt/\L\1|' -e 's|\\|/|g'
}

wsl_to_win() {
    local wslpath="$1"
    # Convert /mnt/c/path to C:/path
    if [[ "$wslpath" =~ ^/mnt/([a-z])(/.*)?$ ]]; then
        local drive="${BASH_REMATCH[1]^^}"
        local path="${BASH_REMATCH[2]}"
        echo "${drive}:${path}"
    else
        # UNC path: \\wsl$\distro\path
        echo "\\\\wsl\$\\${WSL_DISTRO_NAME}${wslpath}"
    fi
}

# Main OS detection with WSL support
OSNAME=$(uname)

if [ "$OSNAME" = "Linux" ]; then
    if detect_wsl; then
        # WSL-specific configuration
        OSNAME="WSL"

        # Set Houdini path (Windows installation accessed from WSL)
        export HOUDINI_WIN="C:/Program Files/Side Effects Software/Houdini $HOUDINI_VERSION"
        export HOUDINI=$(win_to_wsl "$HOUDINI_WIN")

        # Use Windows executable
        HOUDINI_EXEC="$HOUDINI/bin/houdinifx.exe"

        log "WSL Mode: Houdini at $HOUDINI_WIN (WSL: $HOUDINI)"
    else
        # Native Linux
        export HOUDINI="/opt/hfs17.5"
        HOUDINI_EXEC="$HOUDINI/bin/houdini"
        log "Native Linux: Houdini at $HOUDINI"
    fi
elif [ "$OSNAME" = "Darwin" ]; then
    # macOS configuration
    export HOUDINI="/Applications/Houdini/Houdini$HOUDINI_VERSION/Frameworks/Houdini.framework/Versions/Current/Resources"
    HOUDINI_EXEC="$HOUDINI/bin/houdini"
    log "macOS: Houdini at $HOUDINI"
fi
```

**Implementation Checklist:**
- [ ] WSL detection function
- [ ] WSL version detection (1 vs 2)
- [ ] Path translation utilities (win_to_wsl, wsl_to_win)
- [ ] Windows path configuration for WSL
- [ ] Launch Windows Houdini from WSL
- [ ] Handle mixed path scenarios
- [ ] Environment variable translation
- [ ] Test with WSL 1 and WSL 2

#### **Day 3 Afternoon: Hybrid Launcher**

**Tasks:**
1. Create unified launcher that detects execution environment
2. Implement automatic script selection (PowerShell vs bash)
3. Test all execution scenarios
4. Create installation guide for each method

**Deliverables:**
- Universal launcher script
- Execution environment detection
- Installation documentation

**Universal Launcher Concept:**
```batch
@echo off
REM Universal Houdini Pipeline Launcher
REM Detects environment and launches appropriate script

echo Houdini Pipeline Launcher v3.0
echo.

REM Detect WSL availability
wsl --status >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set WSL_AVAILABLE=1
    echo WSL detected
) else (
    set WSL_AVAILABLE=0
)

REM Check for bash script in WSL
if %WSL_AVAILABLE% EQU 1 (
    wsl test -f "$PWD/Houdini_Launcher.sh" 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo Found bash script, launching in WSL...
        wsl bash ./Houdini_Launcher.sh
        exit /b %ERRORLEVEL%
    )
)

REM Fall back to PowerShell
echo Launching PowerShell version...
powershell -ExecutionPolicy Bypass -File "%~dp0Houdini_Launcher.ps1"
exit /b %ERRORLEVEL%
```

**Implementation Checklist:**
- [ ] Detect WSL availability
- [ ] Detect Git Bash availability
- [ ] Check for script existence
- [ ] Automatic fallback mechanism
- [ ] User preference override
- [ ] Environment variable hints
- [ ] Clear messaging about which script is running

---

### **Phase 3: Testing & Documentation (Day 4)**

#### **Day 4 Morning: Comprehensive Testing**

**Test Scenarios:**

1. **Clean Windows 11 Installation**
   - [ ] Fresh install, no Git
   - [ ] Fresh install, Git installed
   - [ ] Fresh install, Houdini installed
   - [ ] All components installed

2. **Different Houdini Versions**
   - [ ] Houdini 17.5.229 (current default)
   - [ ] Houdini 19.5.640 (recent version)
   - [ ] Houdini 20.0+ (latest)
   - [ ] Multiple versions side-by-side

3. **Different Execution Methods**
   - [ ] Double-click .bat file
   - [ ] Run from CMD
   - [ ] Run from PowerShell
   - [ ] Run from Git Bash
   - [ ] Run from WSL
   - [ ] Run from VS Code terminal

4. **Path Scenarios**
   - [ ] Standard installation (C:\Program Files)
   - [ ] Custom installation path
   - [ ] Network drive (UNC path)
   - [ ] OneDrive/cloud storage
   - [ ] Paths with spaces
   - [ ] Long paths (>260 chars)

5. **Git Operations**
   - [ ] Clone new repositories
   - [ ] Update existing repositories
   - [ ] Network failure recovery
   - [ ] Git not installed scenario

6. **Environment Variables**
   - [ ] Override HOUDINI_VERSION
   - [ ] Override library paths
   - [ ] Non-interactive mode
   - [ ] Custom GPU configuration

7. **Edge Cases**
   - [ ] No admin rights
   - [ ] Restricted execution policy
   - [ ] Firewall blocking Git
   - [ ] Houdini not installed
   - [ ] Corrupted package directory

**Testing Checklist:**
- [ ] All scripts pass syntax validation
- [ ] Logging works correctly
- [ ] Error messages are clear and actionable
- [ ] Folder structure created correctly
- [ ] Jump preferences generated correctly
- [ ] Houdini launches with correct environment
- [ ] Packages downloaded/updated successfully
- [ ] Works on clean Windows 11 VM
- [ ] Works with Windows 10 (1809+)
- [ ] Performance acceptable (launch < 10 seconds)

#### **Day 4 Afternoon: Documentation**

**Documents to Create/Update:**

1. **README.md Updates**
   - Add Windows installation instructions
   - Add Windows usage examples
   - Add Windows-specific configuration
   - Update badges (add Windows badge)

2. **WINDOWS_SETUP_GUIDE.md** (NEW)
   - Prerequisites (Git, Houdini)
   - PowerShell execution policy setup
   - Step-by-step installation
   - Troubleshooting guide
   - FAQ section

3. **CHANGELOG.md Updates**
   - Document v3.0 release
   - List all Windows features
   - Migration guide for Windows users

4. **Architecture Diagrams**
   - Update with Windows support
   - Show execution flow
   - Document decision tree

**Documentation Checklist:**
- [ ] Installation guide (3 methods: PowerShell, WSL, Hybrid)
- [ ] Configuration guide (paths, versions, preferences)
- [ ] Troubleshooting guide (common issues and solutions)
- [ ] FAQ section (at least 10 Q&A)
- [ ] Screenshot/video tutorial (optional)
- [ ] Code comments in all scripts
- [ ] API documentation for functions
- [ ] Migration guide from v2.0

---

### **Phase 4: Polish & Release (Day 5)**

#### **Day 5 Morning: Code Review & Refinement**

**Tasks:**
1. Code review of all PowerShell scripts
2. Optimize performance bottlenecks
3. Improve error messages
4. Add usage examples
5. Create helper utilities

**Deliverables:**
- Polished, production-ready code
- Performance optimization report
- Helper utility scripts

**Helper Utilities to Create:**

1. **Install-HoudiniPipeline.ps1**
   ```powershell
   # One-click installer for Windows
   # - Downloads pipeline from GitHub
   # - Installs to standard location
   # - Creates desktop shortcuts
   # - Configures execution policy
   # - Validates Houdini installation
   ```

2. **Update-HoudiniPipeline.ps1**
   ```powershell
   # Updates pipeline to latest version
   # - Backs up current configuration
   # - Pulls latest from GitHub
   # - Migrates settings
   # - Reports changes
   ```

3. **Test-HoudiniPipeline.ps1**
   ```powershell
   # Diagnostic script
   # - Checks all prerequisites
   # - Validates configuration
   # - Tests Git connectivity
   # - Reports issues
   ```

**Code Review Checklist:**
- [ ] All functions documented with comment-based help
- [ ] Error handling comprehensive
- [ ] Performance optimized (no unnecessary operations)
- [ ] Code style consistent
- [ ] No hardcoded values (use variables)
- [ ] Logging appropriate (not too verbose)
- [ ] Security considerations addressed
- [ ] PowerShell best practices followed

#### **Day 5 Afternoon: Release Preparation**

**Tasks:**
1. Create release notes
2. Tag version 3.0
3. Create Windows installation package
4. Update GitHub README
5. Create demo video (optional)

**Deliverables:**
- Release notes
- Git tag v3.0.0
- Installation package
- Updated repository

**Release Checklist:**
- [ ] All tests passing
- [ ] Documentation complete
- [ ] CHANGELOG updated
- [ ] Version numbers updated
- [ ] Git tag created
- [ ] Release notes published
- [ ] GitHub release created
- [ ] Installation package tested
- [ ] Demo video/screenshots prepared
- [ ] Community announcement drafted

---

## Technical Requirements

### Software Prerequisites

| Software | Minimum Version | Recommended Version | Purpose |
|----------|----------------|---------------------|---------|
| **Windows** | 10 (1809) | 11 (22H2+) | Operating system |
| **PowerShell** | 5.1 | 7.4+ (Core) | Script execution |
| **Git for Windows** | 2.30 | Latest | Package management |
| **Houdini** | 17.5+ | 19.5+ | Target application |
| **.NET Framework** | 4.7.2 | 4.8+ | PowerShell dependency |

### Optional Components

| Component | Purpose | Installation |
|-----------|---------|--------------|
| **WSL 2** | Bash script compatibility | `wsl --install` |
| **Git Bash** | Alternative bash environment | Included with Git for Windows |
| **PowerShell Core** | Cross-platform PowerShell | `winget install Microsoft.PowerShell` |
| **Windows Terminal** | Better terminal experience | `winget install Microsoft.WindowsTerminal` |

### System Requirements

- **RAM:** 8 GB minimum (16 GB recommended for Houdini)
- **Disk Space:** 500 MB for pipeline + packages
- **Network:** Internet connection for initial package download
- **Permissions:** User-level (no admin required for basic operation)

---

## File Structure

### Proposed Directory Structure (v3.0)

```
Houdini_Pipeline/
│
├── README.md                      # Main documentation (updated)
├── CHANGELOG.md                   # Version history (updated)
├── LICENSE                        # License file
├── .gitignore                     # Git ignore (updated for Windows)
│
├── docs/                          # Documentation directory (NEW)
│   ├── WINDOWS_SETUP_GUIDE.md    # Windows installation guide
│   ├── WINDOWS_TROUBLESHOOTING.md # Windows troubleshooting
│   ├── API_REFERENCE.md          # Function documentation
│   └── ARCHITECTURE.md           # System architecture
│
├── windows/                       # Windows-specific files (NEW)
│   ├── Houdini_Launcher.ps1      # PowerShell launcher
│   ├── Houdini_Globals.ps1       # PowerShell globals
│   ├── Houdini_Launcher.bat      # Batch wrapper
│   ├── Install-Pipeline.ps1      # Installation script
│   ├── Update-Pipeline.ps1       # Update script
│   ├── Test-Pipeline.ps1         # Diagnostic script
│   └── Create-Shortcut.ps1       # Shortcut creator
│
├── unix/                          # Unix-specific files (NEW, moved)
│   ├── Houdini_Launcher.sh       # Bash launcher (moved from root)
│   └── Houdini_Globals.sh        # Bash globals (moved from root)
│
├── Houdini_Launcher.sh            # Universal launcher (bash)
├── Houdini_Launcher.bat           # Universal launcher (Windows)
├── Houdini_Globals.sh             # Enhanced with WSL support
├── Folderlist.txt                 # Project folder template
│
├── JoPa/                          # Custom tools (unchanged)
│   ├── hda/
│   ├── toolbar/
│   ├── desktop/
│   ├── presets/
│   └── icons/
│
├── lut/                           # Color LUTs (unchanged)
│   └── linear-to-srgb_14bit.lut
│
├── PACKAGES/                      # External packages (git ignored)
│   ├── GameDevelopmentToolset/
│   ├── qLib/
│   ├── MOPS/
│   ├── VFX-LYNX/
│   └── batch_textures_convert/
│
└── tests/                         # Test scripts (NEW)
    ├── test_windows.ps1          # Windows tests
    ├── test_unix.sh              # Unix tests
    └── test_wsl.sh               # WSL tests
```

### File Naming Conventions

| Platform | Launcher | Globals | Extension |
|----------|----------|---------|-----------|
| **Windows (Native)** | `Houdini_Launcher.ps1` | `Houdini_Globals.ps1` | `.ps1` |
| **Windows (Wrapper)** | `Houdini_Launcher.bat` | N/A | `.bat` |
| **Unix (macOS/Linux)** | `Houdini_Launcher.sh` | `Houdini_Globals.sh` | `.sh` |
| **Universal** | `Houdini_Launcher.[bat\|sh]` | Auto-detected | Multi |

---

## Key Adaptation Points

### 1. Path Handling

**Challenge:** Windows uses backslashes, Unix uses forward slashes

**Solution:**
```powershell
# PowerShell path normalization function
function ConvertTo-HoudiniPath {
    param([string]$path)

    # Get absolute path
    $path = [System.IO.Path]::GetFullPath($path)

    # Convert backslashes to forward slashes for Houdini
    $path = $path -replace '\\', '/'

    return $path
}

# Usage
$env:HOUDINI = ConvertTo-HoudiniPath $env:HOUDINI
$env:HOUDINI_PATH = ConvertTo-HoudiniPath $env:HOUDINI_PATH
```

### 2. Environment Variables

**Challenge:** Different path separators (`:` vs `;`)

**Solution:**
```powershell
# Windows uses semicolons
$env:HOUDINI_PATH = @(
    $env:EXPREDITOR
    $env:PIPELINE
    $env:GAMEDEVTOOLSET
    $env:MOPS
    $env:QLIB
    $env:LYNX
    $env:BATCH
    $env:JOPA
) -join ';'

# Append Houdini's default path
$env:HOUDINI_PATH += ";&"
```

### 3. Git Operations

**Challenge:** Ensure Git for Windows is installed and accessible

**Solution:**
```powershell
# Check Git availability
function Test-GitInstallation {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "Git is not installed. Please install Git for Windows from https://git-scm.com/download/win"
        return $false
    }

    $gitVersion = git --version
    Write-Log "Git detected: $gitVersion"
    return $true
}

# Call before any Git operations
if (-not (Test-GitInstallation)) {
    exit 1
}
```

### 4. Logging

**Challenge:** PowerShell doesn't have `tee` command

**Solution:**
```powershell
# PowerShell logging function
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet('INFO', 'WARNING', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Output to console
    switch ($Level) {
        'ERROR'   { Write-Host $logEntry -ForegroundColor Red }
        'WARNING' { Write-Host $logEntry -ForegroundColor Yellow }
        default   { Write-Host $logEntry }
    }

    # Append to log file
    Add-Content -Path $script:LOG_FILE -Value $logEntry -ErrorAction SilentlyContinue
}
```

### 5. Directory Creation

**Challenge:** Different syntax for creating directories

**Solution:**
```powershell
# PowerShell equivalent of mkdir -p
function New-DirectoryIfNotExists {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        try {
            New-Item -ItemType Directory -Force -Path $Path | Out-Null
            Write-Log "Created directory: $Path"
            return $true
        } catch {
            Write-Log "Failed to create directory: $Path - $_" -Level ERROR
            return $false
        }
    }
    return $true
}

# Create project folders from Folderlist.txt
$folderList = Get-Content "$env:FOLDERLIST"
foreach ($folder in $folderList) {
    if ($folder.Trim()) {
        New-DirectoryIfNotExists $folder
    }
}
```

### 6. Sourcing Scripts

**Challenge:** PowerShell uses dot-sourcing, bash uses `source`

**Solution:**
```powershell
# PowerShell dot-sourcing
. "$env:HOUDINI_PIPELINE\windows\Houdini_Globals.ps1"

# Check if sourcing was successful
if (-not $?) {
    Write-Error "Failed to source Houdini_Globals.ps1"
    exit 1
}
```

### 7. Launching Houdini

**Challenge:** Different executable names and paths

**Solution:**
```powershell
# Windows Houdini executable
$houdiniExe = "$env:HOUDINI/bin/houdinifx.exe"

# Validate executable exists
if (-not (Test-Path $houdiniExe)) {
    Write-Log "ERROR: Houdini executable not found: $houdiniExe" -Level ERROR
    Write-Log "Please check HOUDINI_VERSION and installation path" -Level ERROR
    exit 1
}

Write-Log "Launching Houdini..."

# Launch and capture output
try {
    & $houdiniExe 2>&1 | Tee-Object -FilePath $LOG_FILE -Append
} catch {
    Write-Log "ERROR: Failed to launch Houdini: $_" -Level ERROR
    exit 1
}
```

---

## Testing Strategy

### Unit Testing

**PowerShell Pester Tests:**
```powershell
# tests/Houdini_Launcher.Tests.ps1

Describe "Houdini Launcher Tests" {
    Context "Path Detection" {
        It "Should detect pipeline path from environment" {
            $env:HOUDINI_PIPELINE = "C:\Test\Pipeline"
            # Test detection logic
        }

        It "Should detect pipeline path from script location" {
            # Test auto-detection
        }

        It "Should fail gracefully when path not found" {
            # Test error handling
        }
    }

    Context "Logging" {
        It "Should create log file" {
            # Test log file creation
        }

        It "Should write log entries with timestamp" {
            # Test log format
        }
    }

    Context "Git Operations" {
        It "Should detect Git installation" {
            # Test Git detection
        }

        It "Should retry failed operations" {
            # Test retry logic
        }
    }
}
```

### Integration Testing

**Test Matrix:**

| Test Scenario | Windows 10 | Windows 11 | WSL 1 | WSL 2 |
|---------------|-----------|-----------|-------|-------|
| Fresh install | ✓ | ✓ | ✓ | ✓ |
| Update existing | ✓ | ✓ | ✓ | ✓ |
| Custom paths | ✓ | ✓ | ✓ | ✓ |
| Network drive | ✓ | ✓ | - | - |
| Multiple Houdini versions | ✓ | ✓ | ✓ | ✓ |
| No admin rights | ✓ | ✓ | ✓ | ✓ |
| Offline mode | ✓ | ✓ | ✓ | ✓ |

### User Acceptance Testing

**Test Users:**
1. **Windows-native artist** (no Linux experience)
2. **Technical artist** (familiar with PowerShell)
3. **Pipeline TD** (Linux background, using WSL)
4. **Studio IT** (deploying to multiple machines)

**Feedback Criteria:**
- Ease of installation (1-10)
- Clarity of documentation (1-10)
- Error message helpfulness (1-10)
- Performance (launch time in seconds)
- Overall satisfaction (1-10)

---

## Documentation Requirements

### 1. Installation Guide (WINDOWS_SETUP_GUIDE.md)

**Sections:**
- Prerequisites
  - System requirements
  - Software dependencies
  - Permissions needed
- Installation Methods
  - Method 1: PowerShell (recommended)
  - Method 2: WSL
  - Method 3: Hybrid
- Configuration
  - Environment variables
  - Library paths
  - Houdini version selection
- Verification
  - Test installation
  - Check logs
  - Troubleshoot issues

### 2. Troubleshooting Guide (WINDOWS_TROUBLESHOOTING.md)

**Common Issues:**

| Issue | Cause | Solution |
|-------|-------|----------|
| "PowerShell script not running" | Execution policy | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| "Git not found" | Git not in PATH | Install Git for Windows, restart shell |
| "Houdini executable not found" | Wrong version or path | Set `HOUDINI_VERSION` env var |
| "Package download failed" | Network/firewall | Check internet, configure proxy |
| "Permission denied" | File permissions | Run as administrator (if needed) |
| "Path too long" | Windows 260 char limit | Enable long paths in registry |

### 3. API Reference (API_REFERENCE.md)

**PowerShell Functions:**

```markdown
## Write-Log

Writes a timestamped log entry to console and file.

**Syntax:**
```powershell
Write-Log [-Message] <string> [[-Level] <string>]
```

**Parameters:**
- `-Message` (required): The message to log
- `-Level` (optional): Log level (INFO, WARNING, ERROR)

**Example:**
```powershell
Write-Log "Starting pipeline launcher"
Write-Log "Configuration file missing" -Level WARNING
Write-Log "Fatal error occurred" -Level ERROR
```

---

## ConvertTo-HoudiniPath

Converts Windows path to Houdini-compatible format (forward slashes).

**Syntax:**
```powershell
ConvertTo-HoudiniPath [-Path] <string>
```

**Parameters:**
- `-Path` (required): Windows path to convert

**Example:**
```powershell
$houdiniPath = ConvertTo-HoudiniPath "C:\Program Files\Houdini"
# Returns: C:/Program Files/Houdini
```
```

### 4. Architecture Documentation (ARCHITECTURE.md)

**Sections:**
- System overview
- Component diagram
- Execution flow
- Decision tree (OS/environment detection)
- Data flow
- Error handling strategy
- Extension points

---

## Risk Assessment

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| PowerShell execution policy blocks scripts | High | High | Provide batch wrapper with bypass |
| Git not installed | Medium | High | Check in script, provide clear error |
| Long path issues (260 char limit) | Low | Medium | Detect and warn, enable long paths |
| Path translation errors (WSL) | Medium | Medium | Comprehensive testing, helper functions |
| Network firewall blocks Git | Medium | Medium | Support offline mode, cache packages |
| Houdini version mismatch | Low | High | Auto-detect, allow override |
| Performance degradation | Low | Low | Optimize startup, lazy loading |

### Process Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Testing insufficient | Medium | High | Comprehensive test matrix, multiple testers |
| Documentation incomplete | Medium | High | Peer review, user testing |
| Breaking changes to existing users | Low | High | Maintain backward compatibility |
| Timeline overrun | Medium | Medium | Phased approach, prioritize critical features |

---

## Success Criteria

### Functional Requirements

- [ ] **FR1:** PowerShell launcher successfully launches Houdini on Windows 11
- [ ] **FR2:** All packages (MOPS, qLib, etc.) successfully cloned and updated
- [ ] **FR3:** Project folder structure created correctly
- [ ] **FR4:** Jump preferences generated and functional
- [ ] **FR5:** Logging captures all operations with timestamps
- [ ] **FR6:** Error handling provides clear, actionable messages
- [ ] **FR7:** WSL support allows running bash scripts from Windows
- [ ] **FR8:** Non-interactive mode works for CI/CD
- [ ] **FR9:** Version override via environment variables works
- [ ] **FR10:** Path auto-detection succeeds in standard scenarios

### Non-Functional Requirements

- [ ] **NFR1:** Launcher startup time < 10 seconds (excluding Git operations)
- [ ] **NFR2:** Documentation is clear and comprehensive
- [ ] **NFR3:** Installation is possible without admin rights
- [ ] **NFR4:** Code is maintainable (comments, functions, clear structure)
- [ ] **NFR5:** Cross-platform compatibility maintained (no breaking changes)
- [ ] **NFR6:** Security best practices followed (no credential storage, etc.)
- [ ] **NFR7:** User satisfaction ≥ 8/10 in UAT
- [ ] **NFR8:** All tests passing on Windows 10 and 11

### Acceptance Criteria

**Stakeholder:** VFX Artists
- Can double-click batch file to launch Houdini
- Clear error messages if something goes wrong
- Folder structure matches their workflow

**Stakeholder:** Technical Directors
- Can customize paths and versions easily
- Can integrate with studio pipeline
- Can troubleshoot issues using logs

**Stakeholder:** IT/DevOps
- Can deploy silently (non-interactive)
- Can configure via environment variables
- Can integrate with existing tools

---

## Next Steps

### Immediate Actions

1. **Create Windows branch:**
   ```bash
   git checkout -b feature/windows-support
   ```

2. **Set up test environment:**
   - Provision Windows 11 VM
   - Install Houdini
   - Install Git for Windows
   - Install WSL 2 (Ubuntu)

3. **Begin Phase 1 implementation:**
   - Start with `Houdini_Globals.ps1`
   - Implement logging and path functions first
   - Test incrementally

### Long-Term Roadmap

**v3.0.0** (Current plan)
- Windows 11 support (PowerShell + WSL)
- Enhanced logging and error handling
- Comprehensive documentation

**v3.1.0** (Future)
- GUI launcher (optional)
- Configuration wizard
- Health check diagnostics
- Auto-update functionality

**v3.2.0** (Future)
- Multi-Houdini-version support
- Cloud storage integration
- Docker containerization
- Web-based dashboard

---

## Appendix

### A. PowerShell Learning Resources

- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [PowerShell Gallery](https://www.powershellgallery.com/)
- [PowerShell Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/best-practices)

### B. Windows Path Reference

| Special Folder | Environment Variable | Default Path |
|---------------|---------------------|--------------|
| User Profile | `%USERPROFILE%` | `C:\Users\<username>` |
| Documents | `%USERPROFILE%\Documents` | `C:\Users\<username>\Documents` |
| Program Files | `%ProgramFiles%` | `C:\Program Files` |
| Program Files (x86) | `%ProgramFiles(x86)%` | `C:\Program Files (x86)` |
| AppData Roaming | `%APPDATA%` | `C:\Users\<username>\AppData\Roaming` |
| AppData Local | `%LOCALAPPDATA%` | `C:\Users\<username>\AppData\Local` |
| Temp | `%TEMP%` | `C:\Users\<username>\AppData\Local\Temp` |

### C. Houdini Windows Defaults

| Component | Default Path |
|-----------|-------------|
| Installation | `C:\Program Files\Side Effects Software\Houdini <version>\` |
| Executable | `<install>\bin\houdinifx.exe` |
| Setup Script | `<install>\bin\houdini_setup.bat` |
| User Preferences | `%USERPROFILE%\Documents\houdini<version>\` |
| Environment File | `<prefs>\houdini.env` |
| Packages | `<prefs>\packages\` |

### D. Git for Windows Details

| Component | Path/Command |
|-----------|-------------|
| Installation | `C:\Program Files\Git\` |
| Git Bash | `"C:\Program Files\Git\bin\bash.exe"` |
| Git CMD | `git` (in PATH) |
| Configuration | `%USERPROFILE%\.gitconfig` |

---

**Document Version:** 1.0
**Last Updated:** 2025-10-21
**Author:** Houdini Pipeline Development Team
**Status:** Planning Phase Complete, Ready for Implementation

#Requires -Version 5.1
<#
.SYNOPSIS
    Houdini Pipeline Launcher for Windows

.DESCRIPTION
    Launches Houdini with the configured pipeline environment. This script:
    - Auto-detects pipeline path or uses HOUDINI_PIPELINE environment variable
    - Initializes comprehensive logging
    - Validates all prerequisites
    - Sources global configuration
    - Creates project folder structure
    - Generates jump.pref for quick file access
    - Launches Houdini with proper environment

.PARAMETER SkipRepos
    Skip repository update check (non-interactive mode)

.PARAMETER UpdateRepos
    Force repository updates (non-interactive mode)

.PARAMETER Version
    Override Houdini version (e.g., "19.5.640")

.EXAMPLE
    .\Houdini_Launcher.ps1
    Launch with interactive prompts

.EXAMPLE
    .\Houdini_Launcher.ps1 -UpdateRepos
    Launch and update all package repositories

.EXAMPLE
    .\Houdini_Launcher.ps1 -SkipRepos
    Launch without checking repositories

.EXAMPLE
    .\Houdini_Launcher.ps1 -Version "19.5.640"
    Launch with specific Houdini version

.NOTES
    Version:        3.0.0
    Author:         Houdini Pipeline Team
    Compatible:     Windows 10 (1809+), Windows 11
    PowerShell:     5.1+
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$SkipRepos,

    [Parameter(Mandatory=$false)]
    [switch]$UpdateRepos,

    [Parameter(Mandatory=$false)]
    [string]$Version
)

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#region Helper Functions

<#
.SYNOPSIS
    Writes a timestamped log entry to console and file
#>
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Color-coded console output
    switch ($Level) {
        'ERROR'   { Write-Host $logEntry -ForegroundColor Red }
        'WARNING' { Write-Host $logEntry -ForegroundColor Yellow }
        'SUCCESS' { Write-Host $logEntry -ForegroundColor Green }
        default   { Write-Host $logEntry }
    }

    # Append to log file
    if ($script:LOG_FILE -and (Test-Path (Split-Path $script:LOG_FILE -Parent))) {
        Add-Content -Path $script:LOG_FILE -Value $logEntry -ErrorAction SilentlyContinue
    }
}

<#
.SYNOPSIS
    Converts Windows path to Houdini-compatible format
#>
function ConvertTo-HoudiniPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Path
    )

    if ([string]::IsNullOrEmpty($Path)) {
        return $Path
    }

    try {
        # Get absolute path
        if (Test-Path $Path) {
            $Path = (Resolve-Path $Path).Path
        }
        else {
            $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        }

        # Convert backslashes to forward slashes
        return $Path -replace '\\', '/'
    }
    catch {
        return $Path -replace '\\', '/'
    }
}

#endregion

#region Banner

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   Houdini Pipeline Launcher (Windows)  " -ForegroundColor Cyan
Write-Host "            Version 3.0.0                " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

#endregion

#region Initialize Logging

# Get current directory (project directory)
$script:CURRENTDIR = $PSScriptRoot
if (-not $script:CURRENTDIR) {
    $script:CURRENTDIR = (Get-Location).Path
}

Write-Host "Project Path: $script:CURRENTDIR"

# Create logs directory
$script:LOG_DIR = Join-Path $script:CURRENTDIR "logs"
if (-not (Test-Path $script:LOG_DIR)) {
    New-Item -ItemType Directory -Force -Path $script:LOG_DIR | Out-Null
}

# Create timestamped log file
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$script:LOG_FILE = Join-Path $script:LOG_DIR "houdini_launch_$timestamp.log"

Write-Log "========================================="
Write-Log "Houdini Pipeline Launcher Started"
Write-Log "Project Path: $script:CURRENTDIR"
Write-Log "Log File: $script:LOG_FILE"
Write-Log "========================================="

#endregion

#region Auto-Detect Pipeline Path

Write-Log "Detecting pipeline path..."

# Priority: 1) Environment variable, 2) Script directory, 3) Default path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not $scriptDir) {
    # If script path is not available, use current directory parent
    $scriptDir = Split-Path -Parent $PSScriptRoot
}

if (-not $env:HOUDINI_PIPELINE) {
    # Check if we're in the windows subdirectory
    $parentDir = Split-Path -Parent $scriptDir

    if (Test-Path (Join-Path $parentDir "Houdini_Globals.sh")) {
        $env:HOUDINI_PIPELINE = $parentDir
        Write-Log "Auto-detected pipeline path (from parent): $env:HOUDINI_PIPELINE" -Level SUCCESS
    }
    elseif (Test-Path (Join-Path $scriptDir "Houdini_Globals.sh")) {
        $env:HOUDINI_PIPELINE = $scriptDir
        Write-Log "Auto-detected pipeline path (from script dir): $env:HOUDINI_PIPELINE" -Level SUCCESS
    }
    elseif (Test-Path (Join-Path $env:USERPROFILE "GitHub\Houdini_Pipeline\Houdini_Globals.sh")) {
        $env:HOUDINI_PIPELINE = Join-Path $env:USERPROFILE "GitHub\Houdini_Pipeline"
        Write-Log "Auto-detected pipeline path (default location): $env:HOUDINI_PIPELINE" -Level SUCCESS
    }
    else {
        Write-Log "ERROR: Cannot auto-detect HOUDINI_PIPELINE path" -Level ERROR
        Write-Log "Please set HOUDINI_PIPELINE environment variable to point to the pipeline directory" -Level ERROR
        Write-Log "Example: `$env:HOUDINI_PIPELINE = 'C:\Path\To\Houdini_Pipeline'" -Level ERROR
        exit 1
    }
}
else {
    Write-Log "Using HOUDINI_PIPELINE from environment: $env:HOUDINI_PIPELINE"
}

# Normalize pipeline path
$env:HOUDINI_PIPELINE = ConvertTo-HoudiniPath $env:HOUDINI_PIPELINE

#endregion

#region Validate Pipeline Path

Write-Log "Validating pipeline configuration..."

if (-not (Test-Path $env:HOUDINI_PIPELINE)) {
    Write-Log "ERROR: HOUDINI_PIPELINE directory not found: $env:HOUDINI_PIPELINE" -Level ERROR
    exit 1
}

# Check for PowerShell globals script
$globalsScript = Join-Path $env:HOUDINI_PIPELINE "windows\Houdini_Globals.ps1"
if (-not (Test-Path $globalsScript)) {
    Write-Log "ERROR: Houdini_Globals.ps1 not found at: $globalsScript" -Level ERROR
    Write-Log "Please ensure the pipeline is properly installed" -Level ERROR
    exit 1
}

Write-Log "Pipeline path validated: $env:HOUDINI_PIPELINE" -Level SUCCESS

#endregion

#region Handle Parameters

# Set environment variables based on parameters
if ($UpdateRepos) {
    $env:HOUDINI_UPDATE_REPOS = "1"
    Write-Log "Repository updates enabled (command-line parameter)"
}
elseif ($SkipRepos) {
    $env:HOUDINI_UPDATE_REPOS = "0"
    Write-Log "Repository updates skipped (command-line parameter)"
}

if ($Version) {
    $env:HOUDINI_VERSION = $Version
    Write-Log "Houdini version override: $Version"
}

#endregion

#region Source Global Configuration

Write-Log "Loading global configuration..."

try {
    # Dot-source the globals script
    . $globalsScript

    Write-Log "Global configuration loaded successfully" -Level SUCCESS
}
catch {
    Write-Log "ERROR: Failed to load Houdini_Globals.ps1: $_" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level ERROR
    exit 1
}

#endregion

#region Set HIP and JOB Variables

Write-Log "Setting project variables..."

# Set current directory as HIP and JOB
$env:HIP = ConvertTo-HoudiniPath $script:CURRENTDIR
$env:JOB = $env:HIP

Write-Log "HIP/JOB set to: $env:HIP" -Level SUCCESS

# Set Houdini temp and backup directories
$env:HOUDINI_TEMP_DIR = "$env:HIP/tmp"
$env:HOUDINI_BACKUP_DIR = "$env:HIP/backup"

#endregion

#region Validate Folderlist

if (-not $env:FOLDERLIST) {
    Write-Log "ERROR: FOLDERLIST variable not set by Houdini_Globals.ps1" -Level ERROR
    exit 1
}

if (-not (Test-Path $env:FOLDERLIST)) {
    Write-Log "WARNING: Folderlist.txt not found at: $env:FOLDERLIST" -Level WARNING
    Write-Log "Skipping project folder creation" -Level WARNING
    $createFolders = $false
}
else {
    $createFolders = $true
}

#endregion

#region Create Project Directories

if ($createFolders) {
    Write-Log "Creating project directories..."

    try {
        $folderList = Get-Content $env:FOLDERLIST -ErrorAction Stop

        foreach ($folder in $folderList) {
            $folderTrimmed = $folder.Trim()

            if ([string]::IsNullOrEmpty($folderTrimmed)) {
                continue
            }

            $fullPath = Join-Path $env:HIP $folderTrimmed

            if (-not (Test-Path $fullPath)) {
                try {
                    New-Item -ItemType Directory -Force -Path $fullPath | Out-Null
                    Write-Log "  Created: $folderTrimmed"
                }
                catch {
                    Write-Log "  WARNING: Failed to create directory: $folderTrimmed - $_" -Level WARNING
                }
            }
        }

        Write-Log "Project directories created" -Level SUCCESS
    }
    catch {
        Write-Log "ERROR: Failed to read Folderlist.txt: $_" -Level ERROR
    }
}

#endregion

#region Create Jump Preferences

Write-Log "Creating jump.pref file..."

$jumpPrefPath = Join-Path $env:HIP "jump.pref"

# Remove existing jump.pref
if (Test-Path $jumpPrefPath) {
    Remove-Item -Path $jumpPrefPath -Force
}

if ($env:JUMP) {
    try {
        # Write jump.pref with line endings
        $env:JUMP | Out-File -FilePath $jumpPrefPath -Encoding ASCII
        Write-Log "Jump preferences created" -Level SUCCESS
    }
    catch {
        Write-Log "WARNING: Failed to create jump.pref: $_" -Level WARNING
    }
}
else {
    Write-Log "WARNING: JUMP variable not set, jump.pref will be empty" -Level WARNING
    # Create empty file
    New-Item -ItemType File -Path $jumpPrefPath -Force | Out-Null
}

#endregion

#region Launch Houdini

Write-Log "========================================="
Write-Log "Launching Houdini..."
Write-Log "========================================="

# Determine Houdini executable
$houdiniExe = Join-Path $env:HOUDINI "bin\houdinifx.exe"

# Check if executable exists
if (-not (Test-Path $houdiniExe)) {
    Write-Log "ERROR: Houdini executable not found: $houdiniExe" -Level ERROR
    Write-Log "Please ensure Houdini $env:HOUDINI_VERSION is properly installed" -Level ERROR
    exit 1
}

Write-Log "Houdini executable: $houdiniExe"

# Change to HIP directory
Set-Location $env:HIP

try {
    # Launch Houdini and capture output
    Write-Log "Starting Houdini FX $env:HOUDINI_VERSION..."

    # Start Houdini process
    $process = Start-Process -FilePath $houdiniExe -PassThru -WorkingDirectory $env:HIP

    Write-Log "Houdini launched successfully (PID: $($process.Id))" -Level SUCCESS
    Write-Log "========================================="
    Write-Log "Log file saved to: $script:LOG_FILE"
    Write-Log "========================================="
}
catch {
    Write-Log "ERROR: Failed to launch Houdini: $_" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level ERROR
    exit 1
}

#endregion

# Script completed successfully
exit 0

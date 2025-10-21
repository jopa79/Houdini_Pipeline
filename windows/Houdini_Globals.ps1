#Requires -Version 5.1
<#
.SYNOPSIS
    Houdini Pipeline Global Configuration for Windows

.DESCRIPTION
    This script sets up the Houdini environment for Windows including:
    - OS detection and version management
    - Path configuration and normalization
    - Package management (Git operations)
    - Environment variables setup
    - Windows-specific settings

.NOTES
    Version:        3.0.0
    Author:         Houdini Pipeline Team
    Compatible:     Windows 10 (1809+), Windows 11
    PowerShell:     5.1+
#>

[CmdletBinding()]
param()

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#region Core Functions

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

    # Append to log file (if LOG_FILE is set)
    if ($script:LOG_FILE -and (Test-Path (Split-Path $script:LOG_FILE -Parent))) {
        Add-Content -Path $script:LOG_FILE -Value $logEntry -ErrorAction SilentlyContinue
    }
}

<#
.SYNOPSIS
    Converts Windows path to Houdini-compatible format (forward slashes)
#>
function ConvertTo-HoudiniPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Path
    )

    process {
        if ([string]::IsNullOrEmpty($Path)) {
            return $Path
        }

        try {
            # Get absolute path if it exists
            if (Test-Path $Path) {
                $Path = (Resolve-Path $Path).Path
            } else {
                # Convert to absolute path even if it doesn't exist
                $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
            }

            # Convert backslashes to forward slashes
            $Path = $Path -replace '\\', '/'

            return $Path
        }
        catch {
            Write-Log "Warning: Could not normalize path: $Path" -Level WARNING
            return $Path -replace '\\', '/'
        }
    }
}

<#
.SYNOPSIS
    Tests if Git is installed and accessible
#>
function Test-GitInstallation {
    [CmdletBinding()]
    param()

    try {
        $gitCommand = Get-Command git -ErrorAction Stop
        $gitVersion = git --version 2>&1
        Write-Log "Git detected: $gitVersion" -Level SUCCESS
        return $true
    }
    catch {
        Write-Log "Git is not installed or not in PATH" -Level ERROR
        Write-Log "Please install Git for Windows from: https://git-scm.com/download/win" -Level ERROR
        return $false
    }
}

<#
.SYNOPSIS
    Executes a Git command with retry logic and exponential backoff
#>
function Invoke-GitRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory=$false)]
        [int]$MaxRetries = 4,

        [Parameter(Mandatory=$false)]
        [int]$InitialWaitSeconds = 2
    )

    $retryCount = 0
    $waitTime = $InitialWaitSeconds

    while ($retryCount -lt $MaxRetries) {
        try {
            & $ScriptBlock
            return $true
        }
        catch {
            $retryCount++
            if ($retryCount -lt $MaxRetries) {
                Write-Log "Git operation failed, retrying in ${waitTime}s (attempt $($retryCount + 1)/$MaxRetries)..." -Level WARNING
                Start-Sleep -Seconds $waitTime
                $waitTime = $waitTime * 2  # Exponential backoff
            }
            else {
                Write-Log "Git operation failed after $MaxRetries attempts: $_" -Level ERROR
                return $false
            }
        }
    }

    return $false
}

<#
.SYNOPSIS
    Updates an existing Git repository or clones a new one
#>
function Update-GitRepository {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$RepoPath,

        [Parameter(Mandatory=$true)]
        [string]$GitUrl,

        [Parameter(Mandatory=$true)]
        [string]$RepoName
    )

    if (Test-Path $RepoPath) {
        Write-Log "Updating $RepoName..."

        $success = Invoke-GitRetry -ScriptBlock {
            Push-Location $RepoPath
            try {
                git pull 2>&1 | Out-Null
            }
            finally {
                Pop-Location
            }
        }

        if ($success) {
            Write-Log "  ✓ $RepoName updated successfully" -Level SUCCESS
        }
        else {
            Write-Log "  ✗ Failed to update $RepoName (continuing anyway)" -Level WARNING
        }
    }
    else {
        Write-Log "Installing $RepoName..."

        # Ensure parent directory exists
        $parentDir = Split-Path $RepoPath -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Force -Path $parentDir | Out-Null
        }

        $success = Invoke-GitRetry -ScriptBlock {
            git clone $GitUrl $RepoPath 2>&1 | Out-Null
        }

        if ($success) {
            Write-Log "  ✓ $RepoName installed successfully" -Level SUCCESS
        }
        else {
            Write-Log "  ✗ Failed to install $RepoName" -Level ERROR
            return $false
        }
    }

    return $true
}

<#
.SYNOPSIS
    Detects Houdini installation on Windows
#>
function Find-HoudiniInstallation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Version
    )

    # Standard installation paths to check
    $possiblePaths = @(
        "${env:ProgramFiles}\Side Effects Software\Houdini $Version",
        "${env:ProgramFiles(x86)}\Side Effects Software\Houdini $Version",
        "C:\Program Files\Side Effects Software\Houdini $Version",
        "C:\Houdini\Houdini $Version"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path "$path\bin\houdinifx.exe") {
            Write-Log "Found Houdini installation at: $path" -Level SUCCESS
            return $path
        }
    }

    # Not found in standard locations
    Write-Log "Houdini $Version not found in standard locations" -Level WARNING
    return $null
}

#endregion

#region OS Detection and Version Management

# Detect operating system
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $script:OSNAME = "Windows"
    Write-Log "Detected OS: Windows"

    # Get Windows version
    $osVersion = [System.Environment]::OSVersion.Version
    Write-Log "Windows Version: $($osVersion.Major).$($osVersion.Minor) (Build $($osVersion.Build))"
}
else {
    Write-Log "ERROR: This script is designed for Windows only" -Level ERROR
    Write-Log "For Unix systems (macOS/Linux), use Houdini_Globals.sh instead" -Level ERROR
    exit 1
}

# Set Houdini version (with environment variable override support)
if (-not $env:HOUDINI_VERSION) {
    $env:HOUDINI_VERSION = "17.5.229"
}

if (-not $env:REDSHIFT_VERSION) {
    $env:REDSHIFT_VERSION = "17.5.173"
}

Write-Log "Houdini Version: $env:HOUDINI_VERSION"
Write-Log "Redshift Version: $env:REDSHIFT_VERSION"

#endregion

#region Path Configuration

# Validate HOUDINI_PIPELINE is set
if (-not $env:HOUDINI_PIPELINE) {
    Write-Log "ERROR: HOUDINI_PIPELINE environment variable is not set" -Level ERROR
    Write-Log "This variable should be set by Houdini_Launcher.ps1" -Level ERROR
    exit 1
}

# Set global paths
$env:PIPELINE = ConvertTo-HoudiniPath $env:HOUDINI_PIPELINE
$env:PACKAGES = ConvertTo-HoudiniPath (Join-Path $env:PIPELINE "PACKAGES")

# Set package paths
$env:GAMEDEVTOOLSET = ConvertTo-HoudiniPath (Join-Path $env:PACKAGES "GameDevelopmentToolset")
$env:QLIB = ConvertTo-HoudiniPath (Join-Path $env:PACKAGES "qLib")
$env:MOPS = ConvertTo-HoudiniPath (Join-Path $env:PACKAGES "MOPS")
$env:LYNX = ConvertTo-HoudiniPath (Join-Path $env:PACKAGES "VFX-LYNX")
$env:BATCH = ConvertTo-HoudiniPath (Join-Path $env:PACKAGES "batch_textures_convert")
$env:EXPREDITOR = ConvertTo-HoudiniPath (Join-Path $env:PACKAGES "HoudiniExprEditor_v1_2_1")
$env:ALICEVISION_PATH = ConvertTo-HoudiniPath (Join-Path $env:PACKAGES "Alicevision-2.1.0")
$env:JOPA = ConvertTo-HoudiniPath (Join-Path $env:HOUDINI_PIPELINE "JoPa")

# Set global defaults
$env:FOLDERLIST = ConvertTo-HoudiniPath (Join-Path $env:PIPELINE "Folderlist.txt")

Write-Log "Pipeline path: $env:PIPELINE"
Write-Log "Packages path: $env:PACKAGES"

#endregion

#region Houdini Configuration

# Set Houdini environment variables
$env:HOUDINI_NO_ENV_FILE = "1"
$env:HOUDINI_NO_SPLASH = "1"
$env:HOUDINI_NO_START_PAGE_SPLASH = "1"
$env:HOUDINI_ANONYMOUS_STATISTICS = "0"
$env:HOUDINI_IMAGE_DISPLAY_GAMMA = "1"
$env:HOUDINI_IMAGE_DISPLAY_LUT = ConvertTo-HoudiniPath (Join-Path $env:PIPELINE "lut\linear-to-srgb_14bit.lut")
$env:HOUDINI_IMAGE_DISPLAY_OVERRIDE = "1"
$env:HOUDINI_EXTERNAL_HELP_BROWSER = "1"

# Set Houdini temp and backup directories (will be set by launcher based on HIP)
# $env:HOUDINI_TEMP_DIR = "$env:HIP/tmp"
# $env:HOUDINI_BACKUP_DIR = "$env:HIP/backup"

Write-Log "Houdini configuration set"

#endregion

#region Git Repository Management

# Git repository URLs
$script:GITMOPS = "https://github.com/toadstorm/MOPS.git"
$script:GITQLIB = "https://github.com/qLab/qLib.git"
$script:GITGAMEDEVTOOLSET = "https://github.com/sideeffects/GameDevelopmentToolset.git"
$script:GITLYNX = "https://github.com/LucaScheller/VFX-LYNX.git"
$script:GITBATCH = "https://github.com/jtomori/batch_textures_convert.git"

# Check if repository updates are requested
# Support environment variable or parameter
$updateRepos = $false

if ($env:HOUDINI_UPDATE_REPOS -eq "1") {
    $updateRepos = $true
    Write-Log "Repository update enabled (environment variable)" -Level INFO
}
elseif ($env:HOUDINI_UPDATE_REPOS -eq "0") {
    $updateRepos = $false
    Write-Log "Repository update skipped (environment variable)" -Level INFO
}
else {
    # Interactive mode - ask user (with timeout)
    Write-Host ""
    Write-Host "=================================" -ForegroundColor Cyan
    $response = Read-Host "Do you want to check/update package repositories? (y/N)"

    if ($response -match '^[Yy]') {
        $updateRepos = $true
        Write-Log "Repository update enabled" -Level INFO
    }
    else {
        $updateRepos = $false
        Write-Log "Repository update skipped" -Level INFO
    }
}

# Update or clone repositories if requested
if ($updateRepos) {
    Write-Log "Checking repositories..."

    # Check if Git is installed
    if (-not (Test-GitInstallation)) {
        Write-Log "Skipping repository updates (Git not available)" -Level WARNING
    }
    else {
        # Create packages directory if it doesn't exist
        if (-not (Test-Path $env:PACKAGES)) {
            New-Item -ItemType Directory -Force -Path $env:PACKAGES | Out-Null
            Write-Log "Created packages directory: $env:PACKAGES"
        }

        # Update or clone each repository
        Update-GitRepository -RepoPath $env:MOPS -GitUrl $GITMOPS -RepoName "MOPS"
        Update-GitRepository -RepoPath $env:QLIB -GitUrl $GITQLIB -RepoName "qLib"
        Update-GitRepository -RepoPath $env:GAMEDEVTOOLSET -GitUrl $GITGAMEDEVTOOLSET -RepoName "GameDevelopmentToolset"
        Update-GitRepository -RepoPath $env:LYNX -GitUrl $GITLYNX -RepoName "VFX-LYNX"
        Update-GitRepository -RepoPath $env:BATCH -GitUrl $GITBATCH -RepoName "batch_textures_convert"

        Write-Log "Repository check complete" -Level SUCCESS
    }
}

#endregion

#region Windows-Specific Configuration

Write-Log "Configuring for Windows..."

# Detect Houdini installation
$houdiniPath = Find-HoudiniInstallation -Version $env:HOUDINI_VERSION

if ($houdiniPath) {
    $env:HOUDINI = ConvertTo-HoudiniPath $houdiniPath
}
else {
    # Try environment variable override
    if ($env:HOUDINI_INSTALL_PATH) {
        $env:HOUDINI = ConvertTo-HoudiniPath $env:HOUDINI_INSTALL_PATH
        Write-Log "Using HOUDINI_INSTALL_PATH: $env:HOUDINI"
    }
    else {
        # Default fallback
        $env:HOUDINI = "C:/Program Files/Side Effects Software/Houdini $env:HOUDINI_VERSION"
        Write-Log "Using default path (may not exist): $env:HOUDINI" -Level WARNING
    }
}

# Validate Houdini installation
if (-not (Test-Path $env:HOUDINI)) {
    Write-Log "ERROR: Houdini installation not found at: $env:HOUDINI" -Level ERROR
    Write-Log "Please install Houdini $env:HOUDINI_VERSION or set HOUDINI_VERSION environment variable" -Level ERROR
    Write-Log "Download from: https://www.sidefx.com/download/" -Level ERROR
    exit 1
}

Write-Log "Houdini installation validated: $env:HOUDINI" -Level SUCCESS

# Set Windows-specific library paths (with environment variable override)
$defaultLibraryPaths = @{
    L_HDRI = Join-Path $env:USERPROFILE "Documents\Library\HDRI"
    L_TEXTURES = Join-Path $env:USERPROFILE "Documents\Library\TEXTURES"
    L_3DMODELS = Join-Path $env:USERPROFILE "Documents\Library\3DMODELS"
    L_3DScans = Join-Path $env:USERPROFILE "Documents\Library\3DScans"
    L_FOOTAGE = Join-Path $env:USERPROFILE "Documents\Library\FOOTAGE"
    L_IES_Lights = Join-Path $env:USERPROFILE "Documents\Library\IES_LIGHTS"
}

foreach ($key in $defaultLibraryPaths.Keys) {
    if (-not (Test-Path "env:$key")) {
        $path = ConvertTo-HoudiniPath $defaultLibraryPaths[$key]
        Set-Item -Path "env:$key" -Value $path
    }
    else {
        # Normalize existing path
        $existingPath = (Get-Item "env:$key").Value
        Set-Item -Path "env:$key" -Value (ConvertTo-HoudiniPath $existingPath)
    }
}

# Generate jump.pref content for Windows
$jumpPaths = @(
    "'$env:L_HDRI'"
    "'$env:L_TEXTURES'"
    "'$env:L_3DMODELS'"
    "'$env:L_3DScans'"
    "'$env:L_FOOTAGE'"
    "'$env:L_IES_Lights'"
)

$env:JUMP = $jumpPaths -join "`n"

Write-Log "Windows library paths configured"
Write-Log "  HDRI: $env:L_HDRI"
Write-Log "  Textures: $env:L_TEXTURES"
Write-Log "  3D Models: $env:L_3DMODELS"

# Optional: Redshift configuration (if installed)
if ($env:REDSHIFT_ROOT) {
    $env:REDSHIFT_HOUDINI_ROOT = "$env:REDSHIFT_ROOT/redshift4houdini/$env:REDSHIFT_VERSION"
    Write-Log "Redshift configured: $env:REDSHIFT_HOUDINI_ROOT"
}

#endregion

#region Build HOUDINI_PATH

# Build HOUDINI_PATH (Windows uses semicolons as separator)
$houdiniPathParts = @(
    $env:EXPREDITOR
    $env:PIPELINE
    $env:GAMEDEVTOOLSET
    $env:MOPS
    $env:QLIB
    $env:LYNX
    $env:BATCH
    $env:JOPA
)

# Filter out null/empty values and join with semicolons
$houdiniPathParts = $houdiniPathParts | Where-Object { $_ }
$env:HOUDINI_PATH = ($houdiniPathParts -join ';') + ';&'

Write-Log "HOUDINI_PATH configured"

#endregion

#region Houdini Setup

# Source Houdini setup script
$houdiniSetup = Join-Path $env:HOUDINI "bin\houdini_setup.bat"

if (Test-Path $houdiniSetup) {
    Write-Log "Running Houdini setup script..."

    try {
        # Execute houdini_setup.bat in current session
        # Note: This modifies environment variables in current PowerShell session
        cmd /c "`"$houdiniSetup`" && set" | ForEach-Object {
            if ($_ -match '^([^=]+)=(.*)$') {
                $varName = $matches[1]
                $varValue = $matches[2]

                # Update environment variable
                Set-Item -Path "env:$varName" -Value $varValue -ErrorAction SilentlyContinue
            }
        }

        Write-Log "Houdini environment setup complete" -Level SUCCESS
    }
    catch {
        Write-Log "Warning: Failed to source houdini_setup.bat: $_" -Level WARNING
        Write-Log "Continuing with manual configuration..." -Level WARNING
    }
}
else {
    Write-Log "ERROR: houdini_setup.bat not found at: $houdiniSetup" -Level ERROR
    Write-Log "Please check Houdini installation" -Level ERROR
    exit 1
}

#endregion

Write-Log "========================================="
Write-Log "Global configuration loaded successfully" -Level SUCCESS
Write-Log "========================================="

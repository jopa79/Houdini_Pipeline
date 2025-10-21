#Requires -Version 5.1
<#
.SYNOPSIS
    Houdini Pipeline Diagnostic Script for Windows

.DESCRIPTION
    Tests and validates the Houdini Pipeline installation on Windows.
    Checks for:
    - PowerShell version compatibility
    - Houdini installation
    - Git installation
    - Pipeline file structure
    - Environment variables
    - Package repositories
    - Network connectivity

.EXAMPLE
    .\Test-Pipeline.ps1
    Run all diagnostic tests

.EXAMPLE
    .\Test-Pipeline.ps1 -Verbose
    Run tests with detailed output

.NOTES
    Version:        3.0.0
    Author:         Houdini Pipeline Team
    Compatible:     Windows 10 (1809+), Windows 11
#>

[CmdletBinding()]
param()

# Color scheme for output
$script:Colors = @{
    Pass = 'Green'
    Fail = 'Red'
    Warn = 'Yellow'
    Info = 'Cyan'
}

# Test results
$script:TestResults = @{
    Passed = 0
    Failed = 0
    Warnings = 0
}

#region Helper Functions

function Write-TestHeader {
    param([string]$Title)
    Write-Host "`n========================================" -ForegroundColor $script:Colors.Info
    Write-Host " $Title" -ForegroundColor $script:Colors.Info
    Write-Host "========================================" -ForegroundColor $script:Colors.Info
}

function Write-TestResult {
    param(
        [string]$Test,
        [bool]$Passed,
        [string]$Message = "",
        [bool]$IsWarning = $false
    )

    if ($IsWarning) {
        Write-Host "  [WARN] $Test" -ForegroundColor $script:Colors.Warn
        if ($Message) { Write-Host "         $Message" -ForegroundColor $script:Colors.Warn }
        $script:TestResults.Warnings++
    }
    elseif ($Passed) {
        Write-Host "  [PASS] $Test" -ForegroundColor $script:Colors.Pass
        if ($Message) { Write-Host "         $Message" -ForegroundColor Gray }
        $script:TestResults.Passed++
    }
    else {
        Write-Host "  [FAIL] $Test" -ForegroundColor $script:Colors.Fail
        if ($Message) { Write-Host "         $Message" -ForegroundColor $script:Colors.Fail }
        $script:TestResults.Failed++
    }
}

#endregion

#region Diagnostic Tests

Write-TestHeader "Houdini Pipeline Diagnostics - Windows"
Write-Host "Version: 3.0.0"
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# Test 1: PowerShell Version
Write-TestHeader "1. PowerShell Environment"

$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -ge 5) {
    Write-TestResult -Test "PowerShell Version" -Passed $true -Message "Version $($psVersion.Major).$($psVersion.Minor)"
}
else {
    Write-TestResult -Test "PowerShell Version" -Passed $false -Message "Version $($psVersion.Major).$($psVersion.Minor) (5.1+ required)"
}

# Test Windows version
$osVersion = [System.Environment]::OSVersion.Version
$osName = (Get-CimInstance Win32_OperatingSystem).Caption
Write-TestResult -Test "Operating System" -Passed $true -Message "$osName (Build $($osVersion.Build))"

# Test 2: Pipeline Installation
Write-TestHeader "2. Pipeline Installation"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pipelineDir = Split-Path -Parent $scriptDir

if (Test-Path $pipelineDir) {
    Write-TestResult -Test "Pipeline Directory" -Passed $true -Message $pipelineDir
}
else {
    Write-TestResult -Test "Pipeline Directory" -Passed $false -Message "Not found at $pipelineDir"
}

# Check for required files
$requiredFiles = @(
    "windows\Houdini_Launcher.ps1"
    "windows\Houdini_Globals.ps1"
    "windows\Houdini_Launcher.bat"
    "Folderlist.txt"
    "lut\linear-to-srgb_14bit.lut"
)

foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $pipelineDir $file
    if (Test-Path $fullPath) {
        Write-TestResult -Test "Required file: $file" -Passed $true
    }
    else {
        Write-TestResult -Test "Required file: $file" -Passed $false -Message "Missing: $fullPath"
    }
}

# Test 3: Houdini Installation
Write-TestHeader "3. Houdini Installation"

# Check for environment variable
if ($env:HOUDINI_VERSION) {
    Write-TestResult -Test "HOUDINI_VERSION env var" -Passed $true -Message $env:HOUDINI_VERSION
    $houdiniVersion = $env:HOUDINI_VERSION
}
else {
    Write-TestResult -Test "HOUDINI_VERSION env var" -Passed $false -Message "Not set (will use default: 17.5.229)" -IsWarning $true
    $houdiniVersion = "17.5.229"
}

# Check for Houdini installation
$possiblePaths = @(
    "${env:ProgramFiles}\Side Effects Software\Houdini $houdiniVersion"
    "${env:ProgramFiles(x86)}\Side Effects Software\Houdini $houdiniVersion"
    "C:\Program Files\Side Effects Software\Houdini $houdiniVersion"
)

$houdiniFound = $false
$houdiniPath = $null

foreach ($path in $possiblePaths) {
    if (Test-Path "$path\bin\houdinifx.exe") {
        $houdiniFound = $true
        $houdiniPath = $path
        break
    }
}

if ($houdiniFound) {
    Write-TestResult -Test "Houdini $houdiniVersion Installation" -Passed $true -Message $houdiniPath
    Write-TestResult -Test "Houdini FX Executable" -Passed $true -Message "$houdiniPath\bin\houdinifx.exe"
}
else {
    Write-TestResult -Test "Houdini $houdiniVersion Installation" -Passed $false -Message "Not found in standard locations"
}

# Test 4: Git Installation
Write-TestHeader "4. Git for Windows"

try {
    $gitCommand = Get-Command git -ErrorAction Stop
    $gitVersion = git --version 2>&1
    Write-TestResult -Test "Git Installation" -Passed $true -Message $gitVersion
    Write-TestResult -Test "Git Executable Path" -Passed $true -Message $gitCommand.Source
}
catch {
    Write-TestResult -Test "Git Installation" -Passed $false -Message "Git not found in PATH. Download from: https://git-scm.com/download/win"
}

# Test 5: Network Connectivity
Write-TestHeader "5. Network Connectivity"

$testUrls = @{
    "GitHub (HTTPS)" = "https://github.com"
    "GitHub API" = "https://api.github.com"
    "MOPS Repository" = "https://github.com/toadstorm/MOPS.git"
}

foreach ($name in $testUrls.Keys) {
    $url = $testUrls[$name]
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        Write-TestResult -Test "Connectivity: $name" -Passed $true -Message "HTTP $($response.StatusCode)"
    }
    catch {
        Write-TestResult -Test "Connectivity: $name" -Passed $false -Message "Failed to connect" -IsWarning $true
    }
}

# Test 6: Package Repositories
Write-TestHeader "6. Package Repositories"

$packagesDir = Join-Path $pipelineDir "PACKAGES"

if (Test-Path $packagesDir) {
    Write-TestResult -Test "Packages Directory" -Passed $true -Message $packagesDir
}
else {
    Write-TestResult -Test "Packages Directory" -Passed $false -Message "Not found (will be created on first run)" -IsWarning $true
}

$packages = @(
    "GameDevelopmentToolset"
    "qLib"
    "MOPS"
    "VFX-LYNX"
    "batch_textures_convert"
)

foreach ($package in $packages) {
    $packagePath = Join-Path $packagesDir $package
    if (Test-Path $packagePath) {
        # Check if it's a git repository
        $gitDir = Join-Path $packagePath ".git"
        if (Test-Path $gitDir) {
            Write-TestResult -Test "Package: $package" -Passed $true -Message "Installed (Git repository)"
        }
        else {
            Write-TestResult -Test "Package: $package" -Passed $false -Message "Directory exists but not a Git repository" -IsWarning $true
        }
    }
    else {
        Write-TestResult -Test "Package: $package" -Passed $false -Message "Not installed (will be cloned on first run)" -IsWarning $true
    }
}

# Test 7: Custom Assets
Write-TestHeader "7. Custom Assets"

$joPaDir = Join-Path $pipelineDir "JoPa"

if (Test-Path $joPaDir) {
    Write-TestResult -Test "JoPa Directory" -Passed $true -Message $joPaDir

    # Check subdirectories
    $subDirs = @("hda", "toolbar", "desktop", "presets", "icons")
    foreach ($dir in $subDirs) {
        $fullPath = Join-Path $joPaDir $dir
        if (Test-Path $fullPath) {
            $itemCount = (Get-ChildItem $fullPath -File -Recurse).Count
            Write-TestResult -Test "JoPa\$dir" -Passed $true -Message "$itemCount files"
        }
        else {
            Write-TestResult -Test "JoPa\$dir" -Passed $false -Message "Directory not found"
        }
    }
}
else {
    Write-TestResult -Test "JoPa Directory" -Passed $false -Message "Custom assets directory not found"
}

# Test 8: Disk Space
Write-TestHeader "8. System Resources"

$drive = (Get-Item $pipelineDir).PSDrive.Name
$driveInfo = Get-PSDrive $drive
$freeSpaceGB = [math]::Round($driveInfo.Free / 1GB, 2)
$totalSpaceGB = [math]::Round(($driveInfo.Used + $driveInfo.Free) / 1GB, 2)

if ($freeSpaceGB -gt 10) {
    Write-TestResult -Test "Disk Space ($drive`:)" -Passed $true -Message "$freeSpaceGB GB free of $totalSpaceGB GB"
}
else {
    Write-TestResult -Test "Disk Space ($drive`:)" -Passed $false -Message "Only $freeSpaceGB GB free (10+ GB recommended)" -IsWarning $true
}

# Memory
$totalMemoryGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
if ($totalMemoryGB -ge 8) {
    Write-TestResult -Test "System Memory" -Passed $true -Message "$totalMemoryGB GB"
}
else {
    Write-TestResult -Test "System Memory" -Passed $false -Message "$totalMemoryGB GB (8+ GB recommended)" -IsWarning $true
}

#endregion

#region Summary

Write-TestHeader "Diagnostic Summary"

$totalTests = $script:TestResults.Passed + $script:TestResults.Failed + $script:TestResults.Warnings

Write-Host ""
Write-Host "  Total Tests:    $totalTests" -ForegroundColor White
Write-Host "  Passed:         $($script:TestResults.Passed)" -ForegroundColor $script:Colors.Pass
Write-Host "  Failed:         $($script:TestResults.Failed)" -ForegroundColor $script:Colors.Fail
Write-Host "  Warnings:       $($script:TestResults.Warnings)" -ForegroundColor $script:Colors.Warn
Write-Host ""

if ($script:TestResults.Failed -eq 0) {
    Write-Host "  Status: READY ✓" -ForegroundColor $script:Colors.Pass
    Write-Host ""
    Write-Host "  Your Houdini Pipeline is properly configured!" -ForegroundColor $script:Colors.Pass
    Write-Host "  You can launch Houdini using:" -ForegroundColor Gray
    Write-Host "    - Double-click: windows\Houdini_Launcher.bat" -ForegroundColor Gray
    Write-Host "    - PowerShell:   .\windows\Houdini_Launcher.ps1" -ForegroundColor Gray
    Write-Host ""

    if ($script:TestResults.Warnings -gt 0) {
        Write-Host "  Note: There are $($script:TestResults.Warnings) warning(s) that should be addressed." -ForegroundColor $script:Colors.Warn
    }
}
else {
    Write-Host "  Status: ISSUES FOUND ✗" -ForegroundColor $script:Colors.Fail
    Write-Host ""
    Write-Host "  Please address the failed tests above before running the launcher." -ForegroundColor $script:Colors.Fail
    Write-Host ""
    Write-Host "  Common fixes:" -ForegroundColor White
    Write-Host "    - Install Houdini from: https://www.sidefx.com/download/" -ForegroundColor Gray
    Write-Host "    - Install Git from: https://git-scm.com/download/win" -ForegroundColor Gray
    Write-Host "    - Check pipeline file structure is intact" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor $script:Colors.Info
Write-Host ""

#endregion

# Exit with appropriate code
if ($script:TestResults.Failed -eq 0) {
    exit 0
}
else {
    exit 1
}

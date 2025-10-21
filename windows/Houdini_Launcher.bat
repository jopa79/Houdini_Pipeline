@echo off
REM ===============================================================================
REM Houdini Pipeline Launcher - Windows Batch Wrapper
REM Version 3.0.0
REM
REM This batch file launches the PowerShell version of the Houdini Pipeline
REM Launcher with proper execution policy bypass for seamless double-click execution.
REM
REM Usage:
REM   Double-click this file, or run from command line:
REM   Houdini_Launcher.bat [options]
REM
REM Options are passed through to the PowerShell script:
REM   -UpdateRepos    : Force repository updates
REM   -SkipRepos      : Skip repository checks
REM   -Version <ver>  : Override Houdini version
REM ===============================================================================

setlocal enabledelayedexpansion

REM Clear screen for clean output
cls

echo.
echo =========================================
echo   Houdini Pipeline Launcher (Windows)
echo             Version 3.0.0
echo =========================================
echo.

REM ===============================================================================
REM Check PowerShell Availability
REM ===============================================================================

echo [INFO] Checking PowerShell installation...

where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] PowerShell not found in PATH
    echo.
    echo PowerShell 5.1 or later is required to run this launcher.
    echo PowerShell is included with Windows 10 and 11 by default.
    echo.
    echo If you're on an older Windows version, please install PowerShell:
    echo https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows
    echo.
    pause
    exit /b 1
)

echo [SUCCESS] PowerShell found

REM ===============================================================================
REM Check PowerShell Version
REM ===============================================================================

echo [INFO] Checking PowerShell version...

for /f "tokens=*" %%v in ('powershell -NoProfile -Command "$PSVersionTable.PSVersion.Major"') do set PS_VERSION=%%v

if not defined PS_VERSION (
    echo [WARNING] Could not determine PowerShell version
    echo [INFO] Attempting to launch anyway...
    set PS_VERSION=Unknown
) else (
    echo [SUCCESS] PowerShell version: %PS_VERSION%

    if %PS_VERSION% LSS 5 (
        echo.
        echo [ERROR] PowerShell version %PS_VERSION% is too old
        echo.
        echo PowerShell 5.1 or later is required.
        echo Please upgrade PowerShell from:
        echo https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows
        echo.
        pause
        exit /b 1
    )
)

REM ===============================================================================
REM Locate PowerShell Script
REM ===============================================================================

echo [INFO] Locating PowerShell launcher script...

set SCRIPT_DIR=%~dp0
set PS_SCRIPT=%SCRIPT_DIR%Houdini_Launcher.ps1

if not exist "%PS_SCRIPT%" (
    echo.
    echo [ERROR] PowerShell script not found at:
    echo %PS_SCRIPT%
    echo.
    echo Please ensure Houdini_Launcher.ps1 is in the same directory as this batch file.
    echo.
    pause
    exit /b 1
)

echo [SUCCESS] Found script: %PS_SCRIPT%

REM ===============================================================================
REM Launch PowerShell Script
REM ===============================================================================

echo.
echo =========================================
echo   Launching Houdini Pipeline...
echo =========================================
echo.

REM Execute PowerShell script with execution policy bypass
REM This allows the script to run without modifying system-wide execution policy
powershell -ExecutionPolicy Bypass -NoProfile -File "%PS_SCRIPT%" %*

REM Capture exit code
set LAUNCHER_EXIT_CODE=%ERRORLEVEL%

REM ===============================================================================
REM Handle Exit Code
REM ===============================================================================

if %LAUNCHER_EXIT_CODE% EQU 0 (
    echo.
    echo =========================================
    echo   Launcher completed successfully
    echo =========================================
    echo.

    REM Don't pause on success - let window close naturally
    REM Uncomment the line below if you want to pause on success:
    REM pause

    exit /b 0
) else (
    echo.
    echo =========================================
    echo   ERROR: Launcher failed
    echo   Exit code: %LAUNCHER_EXIT_CODE%
    echo =========================================
    echo.
    echo Check the log file in the 'logs' directory for details.
    echo.
    echo Common issues:
    echo   - Houdini not installed or wrong version
    echo   - Git not installed (required for package management)
    echo   - Network connectivity issues
    echo   - Missing pipeline files
    echo.
    echo For troubleshooting, see documentation at:
    echo %SCRIPT_DIR%\..\docs\WINDOWS_TROUBLESHOOTING.md
    echo.
    pause
    exit /b %LAUNCHER_EXIT_CODE%
)

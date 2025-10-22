@echo off
REM ===============================================================================
REM Houdini Pipeline Universal Launcher for Windows
REM Version 3.0.0
REM
REM This launcher automatically detects the execution environment and launches
REM the appropriate script:
REM   - PowerShell (native Windows)
REM   - Bash (WSL if available and preferred)
REM   - Git Bash (if available and no WSL)
REM
REM Usage:
REM   Double-click this file, or:
REM   Launch-Houdini.bat [--powershell|--wsl|--bash]
REM ===============================================================================

setlocal enabledelayedexpansion

cls

echo.
echo ================================================
echo   Houdini Pipeline Universal Launcher
echo              Version 3.0.0
echo ================================================
echo.

REM Get script directory
set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%

REM ===============================================================================
REM Parse command-line arguments for forced mode
REM ===============================================================================

set FORCE_MODE=
set EXTRA_ARGS=

:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="--powershell" (
    set FORCE_MODE=powershell
    shift
    goto parse_args
)
if /i "%~1"=="--wsl" (
    set FORCE_MODE=wsl
    shift
    goto parse_args
)
if /i "%~1"=="--bash" (
    set FORCE_MODE=bash
    shift
    goto parse_args
)
REM Unknown argument, save for later
set EXTRA_ARGS=!EXTRA_ARGS! %~1
shift
goto parse_args

:args_done

REM ===============================================================================
REM Detect Available Launchers
REM ===============================================================================

echo [INFO] Detecting available launchers...
echo.

REM Check for PowerShell
set PS_AVAILABLE=0
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set PS_AVAILABLE=1
    echo   [x] PowerShell - Available
) else (
    echo   [ ] PowerShell - Not found
)

REM Check for WSL
set WSL_AVAILABLE=0
where wsl >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    REM Check if WSL is actually installed and working
    wsl --status >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        set WSL_AVAILABLE=1
        echo   [x] WSL - Available
    ) else (
        echo   [ ] WSL - Installed but not configured
    )
) else (
    echo   [ ] WSL - Not found
)

REM Check for Git Bash
set BASH_AVAILABLE=0
if exist "C:\Program Files\Git\bin\bash.exe" (
    set BASH_AVAILABLE=1
    set BASH_PATH=C:\Program Files\Git\bin\bash.exe
    echo   [x] Git Bash - Available
) else if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    set BASH_AVAILABLE=1
    set BASH_PATH=C:\Program Files (x86)\Git\bin\bash.exe
    echo   [x] Git Bash - Available
) else (
    echo   [ ] Git Bash - Not found
)

echo.

REM ===============================================================================
REM Determine Launch Method
REM ===============================================================================

if not "%FORCE_MODE%"=="" (
    echo [INFO] Forced mode: %FORCE_MODE%
    echo.
    goto launch_%FORCE_MODE%
)

REM Automatic detection - prefer PowerShell, then WSL, then Git Bash

REM Priority 1: PowerShell (native Windows, best compatibility)
if %PS_AVAILABLE% EQU 1 (
    echo [INFO] Using PowerShell launcher (native Windows)
    goto launch_powershell
)

REM Priority 2: WSL (Linux environment on Windows)
if %WSL_AVAILABLE% EQU 1 (
    echo [INFO] Using WSL launcher (Windows Subsystem for Linux)
    goto launch_wsl
)

REM Priority 3: Git Bash (minimal bash environment)
if %BASH_AVAILABLE% EQU 1 (
    echo [INFO] Using Git Bash launcher
    goto launch_bash
)

REM No launcher available
echo [ERROR] No suitable launcher found!
echo.
echo Please install one of the following:
echo   - PowerShell 5.1+ (included with Windows 10/11)
echo   - WSL (Windows Subsystem for Linux)
echo   - Git for Windows (includes Git Bash)
echo.
pause
exit /b 1

REM ===============================================================================
REM Launch PowerShell Script
REM ===============================================================================

:launch_powershell

set PS_SCRIPT=%SCRIPT_DIR%\windows\Houdini_Launcher.ps1

if not exist "%PS_SCRIPT%" (
    echo [ERROR] PowerShell script not found: %PS_SCRIPT%
    pause
    exit /b 1
)

echo Launching: %PS_SCRIPT%
echo.

powershell -ExecutionPolicy Bypass -NoProfile -File "%PS_SCRIPT%" %EXTRA_ARGS%
set LAUNCHER_EXIT=%ERRORLEVEL%

if %LAUNCHER_EXIT% EQU 0 (
    echo.
    echo [SUCCESS] Launcher completed successfully
    exit /b 0
) else (
    echo.
    echo [ERROR] Launcher failed with exit code %LAUNCHER_EXIT%
    pause
    exit /b %LAUNCHER_EXIT%
)

REM ===============================================================================
REM Launch WSL Script
REM ===============================================================================

:launch_wsl

set BASH_SCRIPT=%SCRIPT_DIR%\Houdini_Launcher.sh

REM Check if bash script exists
if not exist "%BASH_SCRIPT%" (
    echo [ERROR] Bash script not found: %BASH_SCRIPT%
    pause
    exit /b 1
)

echo Launching: wsl bash %BASH_SCRIPT%
echo.

REM Convert Windows path to WSL path
REM WSL can access Windows files via /mnt/c/...
wsl bash "%BASH_SCRIPT%" %EXTRA_ARGS%
set LAUNCHER_EXIT=%ERRORLEVEL%

if %LAUNCHER_EXIT% EQU 0 (
    echo.
    echo [SUCCESS] Launcher completed successfully
    exit /b 0
) else (
    echo.
    echo [ERROR] Launcher failed with exit code %LAUNCHER_EXIT%
    pause
    exit /b %LAUNCHER_EXIT%
)

REM ===============================================================================
REM Launch Git Bash Script
REM ===============================================================================

:launch_bash

set BASH_SCRIPT=%SCRIPT_DIR%\Houdini_Launcher.sh

if not exist "%BASH_SCRIPT%" (
    echo [ERROR] Bash script not found: %BASH_SCRIPT%
    pause
    exit /b 1
)

echo Launching: "%BASH_PATH%" %BASH_SCRIPT%
echo.

"%BASH_PATH%" "%BASH_SCRIPT%" %EXTRA_ARGS%
set LAUNCHER_EXIT=%ERRORLEVEL%

if %LAUNCHER_EXIT% EQU 0 (
    echo.
    echo [SUCCESS] Launcher completed successfully
    exit /b 0
) else (
    echo.
    echo [ERROR] Launcher failed with exit code %LAUNCHER_EXIT%
    pause
    exit /b %LAUNCHER_EXIT%
)

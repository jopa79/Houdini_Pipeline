# Testing Guide for Houdini Pipeline v3.0
**Windows 10/11, WSL, macOS, and Linux Testing**

---

## Table of Contents

1. [Overview](#overview)
2. [Pre-Testing Setup](#pre-testing-setup)
3. [Windows PowerShell Testing](#windows-powershell-testing)
4. [WSL Testing](#wsl-testing)
5. [macOS/Linux Testing](#macoslinux-testing)
6. [Cross-Platform Testing](#cross-platform-testing)
7. [Regression Testing](#regression-testing)
8. [Test Reporting](#test-reporting)

---

## Overview

This guide provides comprehensive testing procedures for Houdini Pipeline v3.0 across all supported platforms:

- **Windows 10/11** (PowerShell)
- **WSL 1/2** (Windows Subsystem for Linux)
- **macOS** 10.14+
- **Linux** (Ubuntu 18.04+, CentOS 7+)

### Testing Goals

- ✅ Verify Windows PowerShell scripts work correctly
- ✅ Verify WSL support functions properly
- ✅ Ensure backward compatibility with macOS/Linux
- ✅ Validate auto-detection across all platforms
- ✅ Test error handling and edge cases
- ✅ Confirm documentation accuracy

### Test Environments

| Platform | Priority | Status |
|----------|----------|--------|
| Windows 10 | High | ⏳ Needs Testing |
| Windows 11 | High | ⏳ Needs Testing |
| WSL 2 (Ubuntu) | High | ⏳ Needs Testing |
| WSL 1 | Medium | ⏳ Needs Testing |
| Linux (Ubuntu 22.04) | High | ✅ Tested |
| macOS | Medium | ✅ Tested |
| Git Bash | Low | ⏳ Needs Testing |

---

## Pre-Testing Setup

### Prerequisites

Before testing, ensure you have:

**For Windows Testing:**
- [ ] Windows 10 (version 1903+) or Windows 11
- [ ] PowerShell 5.1 or later (check: `$PSVersionTable.PSVersion`)
- [ ] Houdini installed (any version 17.5+)
- [ ] Git for Windows installed
- [ ] Fresh clone of Houdini_Pipeline repository

**For WSL Testing:**
- [ ] WSL 2 installed (WSL 1 also acceptable)
- [ ] Ubuntu 20.04+ or other Linux distribution
- [ ] Git installed in WSL (`sudo apt install git`)
- [ ] Windows Houdini installation (not Linux Houdini)

**For macOS/Linux Testing:**
- [ ] macOS 10.14+ or Linux Ubuntu 18.04+
- [ ] Houdini installed
- [ ] Git installed
- [ ] Bash 4.0+

### Setup Test Environment

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/Houdini_Pipeline.git
   cd Houdini_Pipeline
   ```

2. **Create test project directory:**
   ```bash
   # Windows
   mkdir %USERPROFILE%\Documents\TestProject

   # macOS/Linux/WSL
   mkdir ~/TestProject
   ```

3. **Note your Houdini version:**
   ```bash
   # Check installed Houdini version
   # Windows: C:\Program Files\Side Effects Software\
   # macOS: /Applications/Houdini/
   # Linux: /opt/hfs*
   ```

---

## Windows PowerShell Testing

### Test Suite 1: Diagnostic Tool

**Purpose:** Verify the diagnostic tool correctly identifies system configuration.

**Location:** `windows/Test-Pipeline.ps1`

**Steps:**

1. Open PowerShell (regular user, not admin)
2. Navigate to pipeline directory:
   ```powershell
   cd C:\path\to\Houdini_Pipeline
   ```

3. Run diagnostic:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\windows\Test-Pipeline.ps1
   ```

**Expected Results:**

- ✅ **PowerShell Version**: Shows version 5.1 or later with ✓
- ✅ **Windows Version**: Shows Windows 10/11 with ✓
- ✅ **Houdini Installation**: Detects installed version with ✓
- ✅ **Git**: Detects Git with version number
- ✅ **Network**: Successfully connects to github.com
- ⏳ **Packages**: May show ✗ if not yet cloned (expected on first run)
- ⏳ **Resources**: Shows disk and memory info

**Pass Criteria:**
- All critical tests (PowerShell, Windows, Houdini, Git) show ✓
- No critical errors displayed
- Recommendations are helpful if any test fails

**Record:**
- [ ] Diagnostic tool runs without errors
- [ ] All detections are accurate
- [ ] Output is readable and helpful

---

### Test Suite 2: Batch Launcher

**Purpose:** Verify batch wrapper works and launches PowerShell script.

**Location:** `windows/Houdini_Launcher.bat`

**Steps:**

1. Copy launcher to test project:
   ```cmd
   copy windows\Houdini_Launcher.bat %USERPROFILE%\Documents\TestProject\
   ```

2. Double-click `Houdini_Launcher.bat` in File Explorer

**Expected Results:**

- ✅ Console window opens
- ✅ Shows "Houdini Pipeline Launcher" header
- ✅ Detects PowerShell is available
- ✅ Shows "Launching PowerShell script"
- ✅ Transitions to PowerShell output
- ✅ Logs operations to `logs/` directory
- ✅ Creates project folders
- ✅ Asks about repository updates (first run)
- ✅ Houdini launches successfully

**Pass Criteria:**
- Houdini launches without errors
- Log file created in `TestProject/logs/`
- Project folders created (assets/, backup/, render/, etc.)
- No error messages in console

**Record:**
- [ ] Batch file executes
- [ ] PowerShell script is called
- [ ] Houdini launches
- [ ] Log file created

---

### Test Suite 3: PowerShell Direct Launch

**Purpose:** Test PowerShell script directly without batch wrapper.

**Location:** `windows/Houdini_Launcher.ps1`

**Steps:**

1. Navigate to test project:
   ```powershell
   cd $env:USERPROFILE\Documents\TestProject
   ```

2. Set pipeline path (if not auto-detected):
   ```powershell
   $env:HOUDINI_PIPELINE = "C:\path\to\Houdini_Pipeline"
   ```

3. Launch Houdini:
   ```powershell
   C:\path\to\Houdini_Pipeline\windows\Houdini_Launcher.ps1
   ```

**Expected Results:**

- ✅ Pipeline path auto-detected or uses environment variable
- ✅ Globals script sourced successfully
- ✅ Project directories created
- ✅ Houdini launches

**Pass Criteria:**
- No errors during execution
- Houdini environment configured correctly

**Record:**
- [ ] Auto-detection works
- [ ] Manual path override works
- [ ] Houdini launches

---

### Test Suite 4: Non-Interactive Mode

**Purpose:** Test automated/CI mode without prompts.

**Steps:**

1. **Test skip repos flag:**
   ```powershell
   .\windows\Houdini_Launcher.ps1 -SkipRepos
   ```
   - Should not ask about repository updates
   - Should skip cloning/updating packages

2. **Test update repos flag:**
   ```powershell
   .\windows\Houdini_Launcher.ps1 -UpdateRepos
   ```
   - Should automatically update all repositories
   - No prompts for confirmation

3. **Test version override:**
   ```powershell
   .\windows\Houdini_Launcher.ps1 -Version "19.5.640"
   ```
   - Should use specified version instead of default

**Expected Results:**

- ✅ No interactive prompts when flags are used
- ✅ Behavior matches flag intent
- ✅ Can be run in automated scripts

**Pass Criteria:**
- Flags work as documented
- No hanging prompts
- Suitable for automation

**Record:**
- [ ] `-SkipRepos` works
- [ ] `-UpdateRepos` works
- [ ] `-Version` works

---

### Test Suite 5: Repository Management

**Purpose:** Test Git operations and package management.

**Steps:**

1. **First run (clone):**
   ```powershell
   .\windows\Houdini_Launcher.ps1 -UpdateRepos
   ```
   - Watch for Git clone operations
   - All packages should clone successfully

2. **Second run (update):**
   ```powershell
   .\windows\Houdini_Launcher.ps1 -UpdateRepos
   ```
   - Watch for Git pull operations
   - All packages should update successfully

3. **Test retry logic** (simulate network issue):
   - Temporarily disconnect network
   - Run launcher with `-UpdateRepos`
   - Reconnect network during retry
   - Should eventually succeed

**Expected Results:**

- ✅ Packages clone on first run:
  - GameDevelopmentToolset
  - qLib
  - MOPS
  - VFX-LYNX
  - batch_textures_convert
- ✅ Packages update on subsequent runs
- ✅ Retry logic works (waits 2s, 4s, 8s, 16s)
- ✅ Success/failure logged clearly

**Pass Criteria:**
- All 5 packages download successfully
- Updates work on second run
- Retry logic demonstrates exponential backoff
- Failures are logged with helpful messages

**Record:**
- [ ] All packages clone
- [ ] Updates work
- [ ] Retry logic functions
- [ ] Errors are clear

---

### Test Suite 6: Error Handling

**Purpose:** Test edge cases and error conditions.

**Test Cases:**

1. **Missing Houdini:**
   - Rename Houdini folder temporarily
   - Run launcher
   - Should show clear error: "Houdini installation not found"
   - Restore Houdini folder

2. **Invalid version:**
   ```powershell
   .\windows\Houdini_Launcher.ps1 -Version "99.99.999"
   ```
   - Should show error about version not found

3. **Missing pipeline path:**
   - Don't set `HOUDINI_PIPELINE`
   - Run from a location without `Houdini_Globals.ps1`
   - Should show clear error message

4. **Missing Git:**
   - Temporarily rename Git installation folder
   - Run launcher with `-UpdateRepos`
   - Should show error about Git not found
   - Restore Git folder

**Expected Results:**

- ✅ Clear error messages for all failure cases
- ✅ No cryptic PowerShell errors
- ✅ Helpful suggestions for resolution
- ✅ Script exits gracefully (doesn't crash)

**Pass Criteria:**
- Error messages are user-friendly
- Errors don't cause script to hang
- Guidance provided for fixing issues

**Record:**
- [ ] Missing Houdini handled
- [ ] Invalid version handled
- [ ] Missing pipeline path handled
- [ ] Missing Git handled

---

## WSL Testing

### Test Suite 7: WSL Detection

**Purpose:** Verify WSL environment is correctly detected.

**Location:** `Houdini_Globals.sh`

**Steps:**

1. Open WSL terminal (Ubuntu or other distro)

2. Check WSL variables:
   ```bash
   echo $WSL_DISTRO_NAME  # Should show "Ubuntu" or distro name
   cat /proc/version | grep -i microsoft  # Should show Microsoft
   ```

3. Source globals script:
   ```bash
   cd ~/Houdini_Pipeline
   source ./Houdini_Globals.sh
   ```

4. Check detection:
   ```bash
   echo $WSL           # Should be "true"
   echo $WSL_VERSION   # Should be "1" or "2"
   echo $OSNAME        # Should be "WSL"
   ```

**Expected Results:**

- ✅ WSL detected automatically
- ✅ Correct WSL version identified
- ✅ OSNAME set to "WSL" not "Linux"

**Pass Criteria:**
- All WSL variables set correctly
- No errors during detection

**Record:**
- [ ] WSL detected
- [ ] WSL version correct
- [ ] OSNAME is "WSL"

---

### Test Suite 8: Path Translation

**Purpose:** Test Windows ↔ WSL path conversion.

**Steps:**

1. Source globals:
   ```bash
   source ./Houdini_Globals.sh
   ```

2. Test Windows to WSL:
   ```bash
   win_to_wsl "C:\Users\YourName\Documents"
   # Expected: /mnt/c/Users/YourName/Documents

   win_to_wsl "D:\Projects\MyProject"
   # Expected: /mnt/d/Projects/MyProject
   ```

3. Test WSL to Windows:
   ```bash
   wsl_to_win "/mnt/c/Users/YourName/Documents"
   # Expected: C:/Users/YourName/Documents

   wsl_to_win "/mnt/d/Projects"
   # Expected: D:/Projects
   ```

4. Test edge cases:
   ```bash
   win_to_wsl "C:"
   # Expected: /mnt/c

   wsl_to_win "/home/user"
   # Expected: /home/user (no translation for non-/mnt paths)
   ```

**Expected Results:**

- ✅ Windows paths convert to `/mnt/` paths
- ✅ WSL paths convert to Windows drive letters
- ✅ Forward slashes used in Windows paths (for Houdini)
- ✅ Non-/mnt paths returned unchanged

**Pass Criteria:**
- All conversions produce correct paths
- No errors during conversion
- Edge cases handled properly

**Record:**
- [ ] win_to_wsl works
- [ ] wsl_to_win works
- [ ] Edge cases handled

---

### Test Suite 9: WSL Houdini Launch

**Purpose:** Test launching Windows Houdini from WSL.

**Steps:**

1. Navigate to test project:
   ```bash
   cd ~/TestProject
   # or
   cd /mnt/c/Users/YourName/Documents/TestProject
   ```

2. Run launcher:
   ```bash
   ~/Houdini_Pipeline/Houdini_Launcher.sh
   ```

**Expected Results:**

- ✅ Detects WSL environment
- ✅ Finds Windows Houdini installation
- ✅ Converts HIP path to Windows format
- ✅ Launches Windows Houdini successfully
- ✅ Houdini opens with correct project path

**Pass Criteria:**
- Houdini launches without errors
- Project path is correct in Houdini
- Logs show WSL mode was used

**Record:**
- [ ] WSL mode activated
- [ ] Windows Houdini found
- [ ] Houdini launches
- [ ] Project path correct

---

### Test Suite 10: Universal Launcher

**Purpose:** Test auto-detection and launcher selection.

**Location:** `Launch-Houdini.bat`

**Steps:**

1. Run universal launcher:
   ```cmd
   Launch-Houdini.bat
   ```
   - Should auto-detect available launchers
   - Should show which launcher it chose
   - Should launch successfully

2. Force PowerShell:
   ```cmd
   Launch-Houdini.bat --powershell
   ```
   - Should use PowerShell launcher

3. Force WSL:
   ```cmd
   Launch-Houdini.bat --wsl
   ```
   - Should use WSL launcher (if WSL installed)

4. Force Git Bash:
   ```cmd
   Launch-Houdini.bat --bash
   ```
   - Should use Git Bash (if installed)

**Expected Results:**

- ✅ Detects PowerShell availability
- ✅ Detects WSL availability
- ✅ Detects Git Bash availability
- ✅ Shows detection results clearly
- ✅ Chooses appropriate launcher (Priority: PS > WSL > Git Bash)
- ✅ Force modes work as expected

**Pass Criteria:**
- Auto-detection works correctly
- Manual selection works
- Fallback works if preferred method unavailable

**Record:**
- [ ] Auto-detection works
- [ ] `--powershell` works
- [ ] `--wsl` works
- [ ] `--bash` works

---

## macOS/Linux Testing

### Test Suite 11: Backward Compatibility

**Purpose:** Ensure v3.0 doesn't break existing macOS/Linux functionality.

**Steps:**

1. **Fresh test on Linux/macOS:**
   ```bash
   cd ~/TestProject
   ~/Houdini_Pipeline/Houdini_Launcher.sh
   ```

2. **Verify all v2.0 features still work:**
   - [ ] Auto-detection of pipeline path
   - [ ] Logging to logs/ directory
   - [ ] Repository clone/update
   - [ ] Project folder creation
   - [ ] Jump preferences creation
   - [ ] Houdini launches

3. **Test environment variables:**
   ```bash
   export HOUDINI_VERSION="19.5.640"
   export HOUDINI_UPDATE_REPOS=1
   ./Houdini_Launcher.sh
   ```

4. **Test flags:**
   ```bash
   ./Houdini_Launcher.sh --update-repos
   ./Houdini_Launcher.sh --skip-repos
   ```

**Expected Results:**

- ✅ All v2.0 functionality preserved
- ✅ No regressions introduced
- ✅ macOS/Linux not affected by Windows changes

**Pass Criteria:**
- No errors on macOS/Linux
- All features work as in v2.0
- Logs show correct OS detection (not WSL)

**Record:**
- [ ] macOS: All features work
- [ ] Linux: All features work
- [ ] No WSL false positives

---

## Cross-Platform Testing

### Test Suite 12: Documentation Accuracy

**Purpose:** Verify all documentation is accurate and complete.

**Steps:**

1. **Follow Windows Setup Guide:**
   - Use `docs/WINDOWS_SETUP_GUIDE.md`
   - Follow quick start exactly as written
   - Verify all commands work
   - Check troubleshooting section matches actual errors

2. **Follow WSL Setup Guide:**
   - Use `docs/WSL_SETUP_GUIDE.md`
   - Install WSL following the guide
   - Verify all commands work
   - Test path translation examples

3. **Follow README:**
   - Use `README.md`
   - Test all installation methods
   - Test all usage examples
   - Verify troubleshooting applies

**Expected Results:**

- ✅ All commands in docs work as written
- ✅ Troubleshooting matches actual errors
- ✅ Examples are accurate
- ✅ No outdated information

**Pass Criteria:**
- Can set up successfully following docs alone
- No confusing or incorrect information
- All code examples work

**Record:**
- [ ] Windows guide accurate
- [ ] WSL guide accurate
- [ ] README accurate

---

### Test Suite 13: Package Integration

**Purpose:** Verify all external packages work correctly.

**Steps:**

1. Launch Houdini with packages:
   ```bash
   # After successful repository clone
   ./Houdini_Launcher.sh
   ```

2. **In Houdini, verify packages loaded:**
   - Check shelf: Should see "MOPS", "qLib", "Game Dev" tools
   - Check TAB menu: Should see qLib nodes, MOPS nodes
   - Check assets: GameDevelopmentToolset, VFX-LYNX available

3. **Test a package feature:**
   - Create a geometry node
   - TAB → search "mops"
   - Create a MOPS node
   - Should work without errors

**Expected Results:**

- ✅ All 5 packages visible in Houdini
- ✅ Shelf tools appear
- ✅ Nodes work correctly
- ✅ No load errors in console

**Pass Criteria:**
- Packages integrated successfully
- Can use tools without errors

**Record:**
- [ ] All packages loaded
- [ ] Shelf tools work
- [ ] Nodes work

---

## Regression Testing

### Test Suite 14: Upgrade Test

**Purpose:** Test upgrading from v2.0 to v3.0.

**Steps:**

1. **Simulate v2.0 environment:**
   - Checkout v2.0 tag: `git checkout v2.0.0`
   - Run launcher: `./Houdini_Launcher.sh`
   - Note configuration

2. **Upgrade to v3.0:**
   - Checkout v3.0: `git checkout v3.0.0`
   - Run launcher: `./Houdini_Launcher.sh`

3. **Verify:**
   - [ ] Existing logs preserved
   - [ ] Existing folders preserved
   - [ ] Existing packages preserved
   - [ ] No errors during upgrade
   - [ ] Everything still works

**Expected Results:**

- ✅ Seamless upgrade
- ✅ No data loss
- ✅ All features work

**Pass Criteria:**
- v2.0 project works in v3.0
- No breaking changes

**Record:**
- [ ] Upgrade successful
- [ ] No data loss

---

## Test Reporting

### Test Results Template

Use this template to report test results:

```markdown
## Test Report: [Test Suite Name]

**Date:** YYYY-MM-DD
**Tester:** [Your Name]
**Platform:** [Windows 10/11, WSL 1/2, macOS, Linux]
**Houdini Version:** [e.g., 19.5.640]

### Environment
- OS Version: [e.g., Windows 11 Build 22000]
- PowerShell Version: [e.g., 5.1.19041]
- Git Version: [e.g., 2.39.0]
- WSL Distribution: [e.g., Ubuntu 22.04]

### Test Results

| Test | Status | Notes |
|------|--------|-------|
| Test Case 1 | ✅ PASS | |
| Test Case 2 | ❌ FAIL | Error: ... |
| Test Case 3 | ⚠️ WARN | Works but slow |

### Issues Found

1. **Issue Title**
   - **Severity:** Critical/High/Medium/Low
   - **Description:** [Describe the issue]
   - **Steps to Reproduce:** [List steps]
   - **Expected:** [What should happen]
   - **Actual:** [What actually happened]
   - **Logs:** [Attach or paste relevant logs]

### Summary

- Tests Passed: X / Y
- Tests Failed: X / Y
- Overall Status: PASS / FAIL

### Recommendations

[Any suggestions for improvements]
```

### Where to Report

- **GitHub Issues:** https://github.com/yourusername/Houdini_Pipeline/issues
- **Pull Request Comments:** For testing related to specific PR
- **Email:** [your email] for private reports

---

## Success Criteria

The v3.0 release is considered **production-ready** when:

### Critical (Must Pass)
- ✅ Windows PowerShell launcher works on Windows 10 and 11
- ✅ WSL launcher works on WSL 2
- ✅ macOS/Linux launchers show no regressions
- ✅ All documentation is accurate
- ✅ No critical bugs found

### Important (Should Pass)
- ✅ Diagnostic tool passes all checks
- ✅ Universal launcher works correctly
- ✅ Repository management works
- ✅ Error messages are helpful
- ✅ All packages load in Houdini

### Nice to Have (May Pass)
- ✅ WSL 1 support works
- ✅ Git Bash support works
- ✅ Performance is acceptable

---

## Quick Test Checklist

For a rapid test of core functionality:

**Windows (5 minutes):**
- [ ] Run `windows\Test-Pipeline.ps1` → All critical tests pass
- [ ] Double-click `windows\Houdini_Launcher.bat` → Houdini launches
- [ ] Check `logs/` folder → Log file created

**WSL (5 minutes):**
- [ ] Run `./Houdini_Launcher.sh` from WSL → Houdini launches
- [ ] Check `echo $WSL` → Returns "true"
- [ ] Check Houdini project path → Correct path

**macOS/Linux (5 minutes):**
- [ ] Run `./Houdini_Launcher.sh` → Houdini launches
- [ ] Check logs → No new errors vs v2.0
- [ ] Verify packages → All load correctly

**Total: 15 minutes for smoke test across all platforms**

---

## Automated Testing

### Future: CI/CD Pipeline

Consider implementing automated tests:

```yaml
# .github/workflows/test.yml
name: Test Houdini Pipeline

on: [push, pull_request]

jobs:
  test-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2
      - name: Test PowerShell Scripts
        run: |
          powershell -File windows/Test-Pipeline.ps1

  test-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Test Bash Scripts
        run: |
          bash -n Houdini_Launcher.sh
          bash -n Houdini_Globals.sh
```

**Note:** Full testing requires Houdini installation, which may not be available in CI.

---

## Contact

For testing questions or to report results:

- **GitHub Issues:** [Repository URL]/issues
- **Discussions:** [Repository URL]/discussions
- **Email:** [Maintainer email]

---

**Version:** 3.0.0
**Last Updated:** 2025-10-22
**Maintained By:** Houdini Pipeline Team

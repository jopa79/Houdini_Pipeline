# Changelog

All notable changes to the Houdini Pipeline project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [2.0.0] - 2025-10-21

### Added

#### 🚀 Auto-Detection Features
- **Auto-detect pipeline path**: No longer requires manual editing of `HOUDINI_PIPELINE` path
  - Checks for `Houdini_Globals.sh` in script directory first
  - Falls back to `$HOME/GitHub/Houdini_Pipeline` if not found
  - Shows clear error message if auto-detection fails
- **Environment variable override support**: All major settings can be overridden via environment variables

#### 📝 Logging System
- **Comprehensive logging** with timestamped log files in `logs/` directory
- **Log function** available throughout launcher and globals scripts
- **Detailed operation tracking**: Every step is logged with timestamps
- **Error and warning messages** captured for troubleshooting
- **Houdini output** redirected to log files for complete session history

#### 🔄 Git Operations
- **Retry logic with exponential backoff** (2s, 4s, 8s, 16s)
- **Automatic retry** for up to 4 attempts on network failures
- **Refactored repository management** using `update_or_clone_repo()` function
- **Better error handling** for Git operations with meaningful messages
- **Success indicators** (✓) and failure warnings (✗) in logs

#### 🎯 Non-Interactive Mode
- **Command-line flags**: `--update-repos` and `--skip-repos`
- **Environment variables**: `HOUDINI_UPDATE_REPOS=1` or `HOUDINI_UPDATE_REPOS=0`
- **CI/CD friendly**: Can run without user interaction
- **Timeout handling**: Defaults to safe values when prompts timeout

#### 🍎 macOS Improvements
- **Jump Preferences for macOS**: Now includes library path quick access
  - Default paths: `~/Library/HDRI`, `~/Library/TEXTURES`, etc.
  - Fully customizable via environment variables
- **Trackpad configuration via environment variable**: `HOUDINI_MMB_PAN=0` or `1`
- **Better timeout handling** for interactive prompts

#### ✅ Validation & Error Handling
- **Pipeline path validation**: Checks if `HOUDINI_PIPELINE` directory exists
- **Globals script validation**: Verifies `Houdini_Globals.sh` is present
- **Houdini installation validation**: Confirms Houdini is installed at expected path
- **Folderlist validation**: Checks for folder template file
- **houdini_setup validation**: Ensures Houdini environment script exists
- **Command validation**: Checks if `houdini` command is available in PATH
- **Bash strict mode**: `set -e` and `set -u` for safer execution

#### 🎨 Configuration Flexibility
- **Houdini version override**: `export HOUDINI_VERSION="19.5.640"`
- **Redshift version override**: `export REDSHIFT_VERSION="..."`
- **GPU device configuration**: Environment variables for OpenCL and OptiX device numbers
- **Custom library paths**: All library paths can be overridden

### Changed

#### 🔧 Script Improvements
- **Refactored repository check logic** from long if/elif chain to clean function calls
- **Improved interactive prompts** with better defaults and timeout handling
- **Enhanced error messages** with actionable solutions
- **Cleaner output** with better formatting and status indicators
- **Removed screen clearing** (`printf "\033c"`) that hid errors

#### 📖 Documentation
- **Completely rewritten README** with comprehensive usage guide
- **Added badges** for platform compatibility
- **Added troubleshooting section** with common issues and solutions
- **Added environment variables reference table**
- **Added usage examples** for all major features
- **Added system requirements** section
- **Added contributing guidelines**

#### 🗂️ Project Organization
- **Enhanced .gitignore** with log files, temporary files, and additional packages
- **Better code comments** explaining complex sections
- **Consistent code style** throughout both scripts
- **Function-based architecture** for better maintainability

### Fixed

- **Missing error handling** for all critical operations
- **No logging** for debugging issues
- **Interactive prompts blocking automation**
- **Short timeouts** (3s → 5s) for user responses
- **No retry logic** for Git network failures
- **Hardcoded paths** requiring manual editing
- **No validation** of paths and configurations
- **Silent failures** in directory creation
- **macOS missing Jump Preferences** feature
- **GPU device numbers** not configurable

### Security

- No security vulnerabilities introduced
- Maintained safe defaults (commented out `umask 0000`)
- Added input validation for paths and variables
- Better error handling prevents unexpected behavior

### Breaking Changes

⚠️ **None** - All changes are backward compatible. Existing installations will continue to work.

**Optional Migration**: To take advantage of auto-detection, you can remove the manual `HOUDINI_PIPELINE` export from your launcher copies, but it's not required.

## Migration Guide

### From v1.x to v2.0

**No action required!** All changes are backward compatible.

**Optional optimizations:**

1. **Enable auto-detection** (optional):
   ```bash
   # Remove or comment out this line in Houdini_Launcher.sh:
   # export HOUDINI_PIPELINE="$HOME/GitHub/Houdini_Pipeline"
   ```

2. **Use non-interactive mode** for scripts:
   ```bash
   HOUDINI_UPDATE_REPOS=1 ./Houdini_Launcher.sh
   ```

3. **Check logs** for troubleshooting:
   ```bash
   tail -f logs/houdini_launch_*.log
   ```

## [1.0.0] - Initial Release

### Features
- Multi-OS support (macOS and Linux)
- OS detection and platform-specific configuration
- Package management (MOPS, qLib, GameDevelopmentToolset, VFX-LYNX, batch_textures_convert)
- Custom HDAs and shelf tools
- Desktop layouts for different screen sizes
- Project folder structure automation
- Jump preferences for Linux
- GPU configuration for Linux (Redshift, NVIDIA OpenCL/OptiX)
- Render farm integration (Deadline)

---

## Upcoming Features

See [README.md](README.md) for the full roadmap.

### Planned for v2.1
- [ ] Better Windows support (PowerShell script or WSL compatibility)
- [ ] Configuration file (JSON/YAML) instead of hardcoded values
- [ ] Health check command: `./Houdini_Launcher.sh --check`
- [ ] Dry-run mode: `./Houdini_Launcher.sh --dry-run`

### Under Consideration
- Web-based configuration GUI
- Docker container support
- Multiple Houdini versions simultaneously
- Cloud render farm integration
- Package version locking

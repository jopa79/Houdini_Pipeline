# Houdini Pipeline
**Multi-OS Houdini Environment Management System**

[![macOS](https://img.shields.io/badge/macOS-Compatible-brightgreen.svg)]()
[![Linux](https://img.shields.io/badge/Linux-Compatible-brightgreen.svg)]()
[![Windows](https://img.shields.io/badge/Windows_10/11-Compatible-brightgreen.svg)]()

## Introduction

A robust, production-ready Houdini environment management system that automates installation, configuration, and project initialization across **Windows, macOS, and Linux** platforms. The pipeline intelligently detects your OS and configures platform-specific settings, manages external packages, and provides custom tools for VFX workflows.

**Key Features:**
- 🚀 **Auto-detection** of pipeline path and OS configuration
- 📝 **Comprehensive logging** with timestamped log files
- 🔄 **Automated package management** with Git retry logic
- ✅ **Error handling** and validation throughout
- 🎨 **Custom HDAs** and shelf tools for TD workflows
- 🖥️ **Desktop layouts** optimized for different screen sizes
- 🎯 **Jump preferences** for quick file browser access (all platforms)
- 💻 **Windows 10/11 support** with PowerShell and batch scripts

## What's New (Latest Updates)

### 🎉 v3.0 - Windows 10/11 & WSL Support (NEW!)
- **Windows PowerShell scripts**: Native Windows support with `.ps1` launcher
- **Batch wrapper**: Double-click `.bat` file for easy execution
- **WSL support**: Full Windows Subsystem for Linux compatibility
- **Universal launcher**: Auto-detects and uses PowerShell, WSL, or Git Bash
- **Path translation**: Automatic Windows ↔ WSL path conversion
- **Auto-detection**: Finds Houdini installation on Windows or via WSL
- **Windows library paths**: Default paths in Documents folder
- **Diagnostic tool**: `Test-Pipeline.ps1` checks configuration
- **Comprehensive documentation**: Windows, WSL, and troubleshooting guides

### ✨ v2.0 - Enhanced Features
- **Auto-path detection**: No more manual path editing! Pipeline path is auto-detected
- **Comprehensive logging**: All operations logged to `logs/` directory with timestamps
- **Non-interactive mode**: Run with flags or environment variables for CI/CD
- **Git retry logic**: Automatic retry with exponential backoff for network failures
- **Version flexibility**: Override Houdini version via environment variables
- **macOS Jump Preferences**: Library path quick access for macOS
- **Configuration validation**: Validates Houdini installation and required files

### 🛡️ Robustness Improvements
- Error handling for all critical operations
- Path validation before execution
- GPU device number configuration via environment variables
- Timeout handling for interactive prompts
- Detailed error messages for troubleshooting

## Installation

### Quick Start (Recommended)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/Houdini_Pipeline.git
   cd Houdini_Pipeline
   ```

2. **Copy launcher to your project:**
   ```bash
   cp Houdini_Launcher.sh /path/to/your/project/
   cd /path/to/your/project/
   ```

3. **Run the launcher:**
   ```bash
   ./Houdini_Launcher.sh
   ```

   The pipeline path will be auto-detected! 🎉

### Advanced Installation

If auto-detection doesn't work, set the pipeline path manually:

```bash
export HOUDINI_PIPELINE="/path/to/Houdini_Pipeline"
./Houdini_Launcher.sh
```

### GUI Execution (macOS)

Rename the launcher to make it double-clickable:
```bash
mv Houdini_Launcher.sh Houdini_Launcher.command
chmod +x Houdini_Launcher.command
```

### Windows Installation

**Quick Start:**

1. **Download/Clone the repository:**
   ```cmd
   cd %USERPROFILE%\Documents
   git clone https://github.com/yourusername/Houdini_Pipeline.git
   cd Houdini_Pipeline
   ```

2. **Run diagnostic check:**
   ```cmd
   powershell -ExecutionPolicy Bypass -File windows\Test-Pipeline.ps1
   ```

3. **Launch Houdini:**

   **Option A - Double-click:** `windows\Houdini_Launcher.bat`

   **Option B - Command line:**
   ```cmd
   windows\Houdini_Launcher.bat
   ```

   **Option C - PowerShell:**
   ```powershell
   .\windows\Houdini_Launcher.ps1
   ```

**Detailed Windows Setup:**

See the comprehensive [Windows Setup Guide](docs/WINDOWS_SETUP_GUIDE.md) for:
- Prerequisites and system requirements
- Step-by-step installation
- Configuration options
- Troubleshooting
- FAQ

### WSL (Windows Subsystem for Linux)

**For Linux/bash users on Windows:**

WSL allows you to use the same bash scripts as macOS/Linux:

1. **Install WSL 2:**
   ```powershell
   wsl --install
   ```
   (Restart computer when prompted)

2. **Setup Ubuntu and install Git:**
   ```bash
   sudo apt update && sudo apt install git -y
   ```

3. **Clone pipeline in WSL:**
   ```bash
   cd ~
   git clone https://github.com/yourusername/Houdini_Pipeline.git
   cd Houdini_Pipeline
   ```

4. **Launch Houdini:**
   ```bash
   ./Houdini_Launcher.sh
   ```

**Or use the Universal Launcher from Windows:**
```cmd
Launch-Houdini.bat --wsl
```

**Detailed WSL Setup:**

See the comprehensive [WSL Setup Guide](docs/WSL_SETUP_GUIDE.md) for:
- What is WSL and why use it
- Installation and configuration
- Path translation between Windows and WSL
- Troubleshooting WSL-specific issues
- FAQ and advanced topics

## Usage

### Basic Usage

```bash
./Houdini_Launcher.sh
```

### Non-Interactive Mode (for CI/CD)

**Enable repository updates:**
```bash
HOUDINI_UPDATE_REPOS=1 ./Houdini_Launcher.sh
# or
./Houdini_Launcher.sh --update-repos
```

**Skip repository updates:**
```bash
HOUDINI_UPDATE_REPOS=0 ./Houdini_Launcher.sh
# or
./Houdini_Launcher.sh --skip-repos
```

### Custom Houdini Version

```bash
export HOUDINI_VERSION="19.5.640"
./Houdini_Launcher.sh
```

### Custom GPU Configuration (Linux)

```bash
export HOUDINI_OCL_DEVICENUMBER=1
export HOUDINI_NVIDIA_OPTIX_DEVICENUMBER=0
./Houdini_Launcher.sh
```

### macOS Trackpad Configuration

```bash
# Force trackpad mode (middle-mouse button pan disabled)
export HOUDINI_MMB_PAN=0
./Houdini_Launcher.sh

# Force mouse mode (middle-mouse button pan enabled)
export HOUDINI_MMB_PAN=1
./Houdini_Launcher.sh
```

## Features

### Automated Package Management

The pipeline automatically manages these external repositories:
- **GameDevelopmentToolset** (SideFX official tools)
- **qLib** (Community utility library)
- **MOPS** (Motion graphics toolkit)
- **VFX-LYNX** (VFX framework)
- **batch_textures_convert** (Texture automation)

Packages are cloned on first run and updated on subsequent runs (if enabled).

### Custom Tools & Assets

**7 Houdini Digital Assets (HDAs):**
- JoPa_Infection.hda - Infection/growth simulation
- set_pivot_to_Y0.hda - Pivot manipulation utility
- curvature.hda - Surface curvature analysis
- density_noise.hda - Procedural noise generation
- remove_points.hda - Point filtering utility
- volume_noise.hda - Volume noise generation
- JoPa_RGB_to_Luma.hdalc - Color space conversion

**12+ Shelf Tools:**
- Versioning system with auto-increment
- Scene import/export utilities
- Batch texture conversion
- Background switching
- Attribute wrangling tools
- And more...

**Desktop Layouts:**
- JoPa_Wide.desk - Optimized for wide monitors
- JoPa_MacBook.desk - Optimized for laptop screens

### Project Structure

The launcher automatically creates this folder structure:
```
project/
├── assets/
│   ├── abc/          # Alembic cache
│   ├── fbx_obj/      # Model imports
│   ├── textures/     # Texture assets
│   └── export/       # Scene exports
├── backup/           # Automatic backups
├── flip/             # FLIP simulation cache
├── sim/              # General simulation cache
├── geo/              # Geometry files
├── hda/              # Custom digital assets
├── render/           # Render outputs
├── scripts/          # Custom scripts
├── logs/             # Launcher logs
└── ...
```

### Logging

All launcher operations are logged to:
```
<project>/logs/houdini_launch_YYYYMMDD_HHMMSS.log
```

Logs include:
- Timestamp for each operation
- Configuration detection results
- Repository update status
- Error messages and warnings
- Houdini launch status

## Platform-Specific Features

### macOS
- Retina display support with UI scaling
- Trackpad middle-mouse button configuration
- Library paths: `~/Library/HDRI`, `~/Library/TEXTURES`, etc.
- Desktop layout optimized for MacBook screens

### Linux
- GPU configuration (NVIDIA OpenCL and OptiX)
- Redshift renderer support
- Deadline render farm integration
- RAID cache configuration
- Library paths: `/mnt/DATA/LIBRARY/*`

## Configuration

### Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `HOUDINI_PIPELINE` | Auto-detected | Pipeline installation path |
| `HOUDINI_VERSION` | 17.5.229 | Houdini version to use |
| `REDSHIFT_VERSION` | 17.5.173 | Redshift version (Linux) |
| `HOUDINI_UPDATE_REPOS` | Interactive | 1=update, 0=skip repos |
| `HOUDINI_MMB_PAN` | Interactive | 0=trackpad, 1=mouse |
| `HOUDINI_OCL_DEVICENUMBER` | 0 | OpenCL GPU device (Linux) |
| `HOUDINI_NVIDIA_OPTIX_DEVICENUMBER` | 1 | OptiX GPU device (Linux) |

### Custom Library Paths

Override default library paths:
```bash
export L_HDRI="/custom/path/to/hdri"
export L_TEXTURES="/custom/path/to/textures"
export L_3DMODELS="/custom/path/to/models"
./Houdini_Launcher.sh
```

## Troubleshooting

### Pipeline path not found
**Error:** `ERROR: Cannot auto-detect HOUDINI_PIPELINE path`

**Solution:** Set the path manually:
```bash
export HOUDINI_PIPELINE="/path/to/Houdini_Pipeline"
```

### Houdini installation not found
**Error:** `ERROR: Houdini installation not found`

**Solution:**
- Verify Houdini is installed
- Check version matches: `/Applications/Houdini/Houdini17.5.229/` (macOS) or `/opt/hfs17.5` (Linux)
- Override version: `export HOUDINI_VERSION="19.5.640"`

### Git operations failing
The pipeline automatically retries Git operations up to 4 times with exponential backoff (2s, 4s, 8s, 16s). If still failing:
- Check network connectivity
- Verify firewall settings
- Check Git repository accessibility

### Check the logs
All operations are logged. Check the latest log file:
```bash
ls -lt logs/
tail -f logs/houdini_launch_*.log
```

## System Requirements

- **OS:** macOS 10.14+ or Linux (Ubuntu 18.04+, CentOS 7+)
- **Houdini:** 17.5+ (tested with 17.5.229)
- **Git:** For package management
- **Bash:** 4.0+

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes with clear commit messages
4. Test on both macOS and Linux if possible
5. Submit a pull request

## ToDo / Roadmap

- [ ] Windows support (PowerShell or WSL compatibility)
- [ ] Web-based configuration GUI
- [ ] Support for multiple Houdini versions simultaneously
- [ ] Cloud render farm integration
- [ ] Docker container support
- [ ] Houdini Engine integration helpers

## License

This project is provided as-is for the Houdini community.

## Credits

**Packages Included:**
- [GameDevelopmentToolset](https://github.com/sideeffects/GameDevelopmentToolset) by SideFX
- [qLib](https://github.com/qLab/qLib) by qLab
- [MOPS](https://github.com/toadstorm/MOPS) by Toadstorm
- [VFX-LYNX](https://github.com/LucaScheller/VFX-LYNX) by Luca Scheller
- [batch_textures_convert](https://github.com/jtomori/batch_textures_convert) by Juraj Tomori

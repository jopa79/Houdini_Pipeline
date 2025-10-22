# WSL Setup Guide
**Using Houdini Pipeline with Windows Subsystem for Linux**

---

## Table of Contents

1. [What is WSL?](#what-is-wsl)
2. [Why Use WSL?](#why-use-wsl)
3. [Prerequisites](#prerequisites)
4. [Installation](#installation)
5. [Usage](#usage)
6. [Path Translation](#path-translation)
7. [Troubleshooting](#troubleshooting)
8. [FAQ](#faq)

---

## What is WSL?

**Windows Subsystem for Linux (WSL)** is a compatibility layer that allows you to run Linux distributions directly on Windows without virtualization. WSL 2 provides a full Linux kernel for better performance and compatibility.

**For Houdini Pipeline:**
- WSL allows you to use the **exact same bash scripts** as macOS/Linux
- Minimal changes to existing workflows
- Access Windows Houdini from Linux environment
- Best of both worlds: Linux tools + Windows applications

---

## Why Use WSL?

### Advantages

✅ **Native bash support** - Run Linux scripts without modification
✅ **Familiar Linux environment** - Same commands as Linux/macOS
✅ **Package management** - Use apt/dnf instead of Windows package managers
✅ **Git integration** - Native Linux Git tools
✅ **Performance** - WSL 2 provides near-native Linux performance
✅ **Interoperability** - Access Windows files from Linux and vice versa

### When to Use WSL vs Native PowerShell

| Use Case | WSL | PowerShell |
|----------|-----|------------|
| **Linux background** | ✅ Best | ❌ Learning curve |
| **Windows native user** | ❌ Extra complexity | ✅ Best |
| **Cross-platform team** | ✅ Consistency | ❌ Platform-specific |
| **Automation/CI/CD** | ✅ Good | ✅ Good |
| **Simplicity** | ❌ Requires setup | ✅ Built-in |

**Recommendation:**
- **PowerShell** for most Windows users (easier, built-in)
- **WSL** for users comfortable with Linux or requiring bash compatibility

---

## Prerequisites

### System Requirements

- **Windows 10** version 1903 or higher (Build 18362+)
- **Windows 11** (any version)
- **64-bit system**
- **Virtualization enabled** in BIOS

### Required Software

| Software | Purpose | Required |
|----------|---------|----------|
| **WSL 2** | Linux environment | Yes |
| **Ubuntu** (or other distro) | Linux distribution | Yes |
| **Houdini for Windows** | Target application | Yes |
| **Git for Linux** | Package management | Yes (installed in WSL) |

---

## Installation

### Step 1: Install WSL 2

**Quick Install (Windows 11 or Windows 10 2004+):**

Open PowerShell as Administrator:

```powershell
wsl --install
```

This command will:
- Enable WSL feature
- Enable Virtual Machine Platform
- Download and install Ubuntu (default)
- Set WSL 2 as default

**Restart your computer** when prompted.

---

**Manual Install (Older Windows 10):**

1. Enable WSL feature:
   ```powershell
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   ```

2. Enable Virtual Machine Platform:
   ```powershell
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

3. Restart computer

4. Download and install WSL 2 kernel update:
   https://aka.ms/wsl2kernel

5. Set WSL 2 as default:
   ```powershell
   wsl --set-default-version 2
   ```

6. Install Ubuntu from Microsoft Store:
   https://www.microsoft.com/store/apps/9pdxgncfsczv

---

### Step 2: Set Up Ubuntu

1. **Launch Ubuntu** from Start Menu

2. **Create user account:**
   ```
   Enter new UNIX username: your_username
   New password: ********
   Retype new password: ********
   ```

3. **Update package lists:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

4. **Install Git:**
   ```bash
   sudo apt install git -y
   ```

5. **Verify installation:**
   ```bash
   git --version
   uname -r  # Should show "microsoft" in kernel version
   ```

---

### Step 3: Install Houdini Pipeline in WSL

**Option A: Clone from WSL**

```bash
# Navigate to WSL home directory
cd ~

# Clone pipeline
git clone https://github.com/yourusername/Houdini_Pipeline.git

# Enter directory
cd Houdini_Pipeline
```

**Option B: Access Windows Installation**

If you already have the pipeline on Windows:

```bash
# Navigate to Windows filesystem
# Windows C: drive is mounted at /mnt/c/
cd /mnt/c/Users/YOUR_USERNAME/Documents/Houdini_Pipeline

# Or create symlink in WSL home
ln -s /mnt/c/Users/YOUR_USERNAME/Documents/Houdini_Pipeline ~/Houdini_Pipeline
```

---

### Step 4: Install Houdini on Windows

**Important:** Houdini must be installed on **Windows**, not in WSL!

1. Download Houdini for Windows from https://www.sidefx.com/download/
2. Install to default location: `C:\Program Files\Side Effects Software\Houdini <version>`
3. Note your version number (e.g., 19.5.640)

---

## Usage

### Basic Usage

**From WSL (Ubuntu) terminal:**

```bash
cd ~/Houdini_Pipeline
./Houdini_Launcher.sh
```

The launcher will:
1. Detect WSL environment ✓
2. Find Windows Houdini installation ✓
3. Convert paths automatically ✓
4. Launch Windows Houdini from WSL ✓

---

### Setting Houdini Version

```bash
export HOUDINI_VERSION="19.5.640"
./Houdini_Launcher.sh
```

Or set in your `~/.bashrc` for persistence:

```bash
echo 'export HOUDINI_VERSION="19.5.640"' >> ~/.bashrc
source ~/.bashrc
```

---

### From Windows Command Prompt

**Using the Universal Launcher:**

```cmd
cd C:\Users\YOUR_USERNAME\Documents\Houdini_Pipeline
Launch-Houdini.bat --wsl
```

This will automatically detect WSL and use bash scripts.

---

### Environment Variables

**WSL-specific variables:**

```bash
# These are set automatically by Houdini_Globals.sh
echo $WSL              # "true"
echo $WSL_VERSION      # "1" or "2"
echo $OSNAME           # "WSL"
echo $HOUDINI_WIN      # Windows path (C:/Program Files/...)
echo $HOUDINI          # WSL path (/mnt/c/Program Files/...)
```

---

## Path Translation

### Understanding Path Formats

| Location | Windows Path | WSL Path |
|----------|-------------|----------|
| C: drive | `C:\Users\Name` | `/mnt/c/Users/Name` |
| D: drive | `D:\Projects` | `/mnt/d/Projects` |
| WSL home | `\\wsl$\Ubuntu\home\user` | `/home/user` |

### Automatic Path Translation

The pipeline includes helper functions:

**Convert Windows to WSL:**
```bash
# In bash
win_to_wsl "C:\Users\Name\Documents"
# Returns: /mnt/c/Users/Name/Documents
```

**Convert WSL to Windows:**
```bash
# In bash
wsl_to_win "/mnt/c/Users/Name/Documents"
# Returns: C:/Users/Name/Documents
```

### Accessing Files

**From WSL (access Windows files):**
```bash
# Windows C: drive
cd /mnt/c/Users/YOUR_USERNAME/Documents

# Windows D: drive
cd /mnt/d/Projects

# List Windows drives
ls /mnt/
```

**From Windows (access WSL files):**
```
\\wsl$\Ubuntu\home\your_username\
```

Or in File Explorer address bar:
```
\\wsl$\Ubuntu\home\
```

---

## Troubleshooting

### Issue: "Houdini executable not found"

**Error:**
```
ERROR: Houdini executable not found at: /mnt/c/Program Files/Side Effects Software/Houdini X.X.XXX/bin/houdinifx.exe
```

**Solutions:**

1. **Check Windows Houdini installation:**
   ```bash
   ls "/mnt/c/Program Files/Side Effects Software/"
   ```

2. **Set correct version:**
   ```bash
   export HOUDINI_VERSION="19.5.640"  # Use YOUR version
   ```

3. **Check if Houdini is installed:**
   ```bash
   explorer.exe "C:\Program Files\Side Effects Software"
   ```

---

### Issue: "WSL not detected"

**Error:**
```
Detected OS: Linux
```
(Should show "WSL" instead)

**Solutions:**

1. **Check WSL environment variables:**
   ```bash
   echo $WSL_DISTRO_NAME
   cat /proc/version | grep -i microsoft
   ```

2. **Update Houdini_Globals.sh:**
   ```bash
   cd ~/Houdini_Pipeline
   git pull
   ```

---

### Issue: Path access denied

**Error:**
```
Permission denied: /mnt/c/...
```

**Solutions:**

1. **Check Windows folder permissions:**
   - Right-click folder → Properties → Security
   - Ensure your Windows user has "Full control"

2. **Use sudo (if needed):**
   ```bash
   sudo ./Houdini_Launcher.sh
   ```
   (Not recommended for Houdini)

3. **Change folder ownership:**
   ```bash
   # In Windows (as Administrator)
   icacls "C:\path\to\folder" /grant YOUR_USERNAME:F
   ```

---

### Issue: Git in WSL doesn't work

**Error:**
```
git: command not found
```

**Solution:**

```bash
# Install Git in WSL
sudo apt update
sudo apt install git -y

# Verify
git --version
```

---

### Issue: Slow file access

**Problem:** Files on Windows drives (/mnt/c/) are slow to access from WSL

**Solutions:**

1. **Move pipeline to WSL filesystem:**
   ```bash
   # Clone to WSL home directory instead of /mnt/c/
   cd ~
   git clone https://github.com/yourusername/Houdini_Pipeline.git
   ```

2. **Use WSL 2 (faster than WSL 1):**
   ```powershell
   wsl --set-version Ubuntu 2
   ```

3. **Keep projects on Windows but pipeline in WSL:**
   ```bash
   # Pipeline in WSL (fast)
   cd ~/Houdini_Pipeline

   # Projects on Windows (accessible)
   cd /mnt/c/Projects/MyProject
   ~/Houdini_Pipeline/Houdini_Launcher.sh
   ```

---

### Issue: Can't access WSL from Windows

**Problem:** Can't find WSL files in Windows Explorer

**Solution:**

Use the special UNC path:
```
\\wsl$\Ubuntu\home\your_username\
```

Or from Command Prompt:
```cmd
explorer.exe \\wsl$\Ubuntu\home\your_username
```

---

## FAQ

### Q: Do I need WSL if I use PowerShell?

**A:** No! PowerShell is the recommended method for most Windows users. WSL is optional for users who:
- Prefer Linux/bash environment
- Need exact cross-platform script compatibility
- Are familiar with Linux workflows

### Q: Can I use both PowerShell and WSL?

**A:** Yes! The universal launcher (`Launch-Houdini.bat`) can use either method. Choose with:
```cmd
Launch-Houdini.bat --powershell  # Use PowerShell
Launch-Houdini.bat --wsl         # Use WSL
```

### Q: Which is faster, WSL or PowerShell?

**A:** Both are roughly equivalent for launching Houdini. PowerShell may be slightly faster to start since it doesn't need to initialize a Linux environment.

### Q: Do I need to install Houdini in WSL?

**A:** No! Houdini should be installed on **Windows**. WSL will call the Windows executable.

### Q: Can I use WSL 1 or do I need WSL 2?

**A:** Both work! WSL 2 is recommended for better performance and compatibility.

Check your version:
```bash
wsl -l -v
```

Upgrade to WSL 2:
```powershell
wsl --set-version Ubuntu 2
```

### Q: How do I uninstall WSL?

**A:**
```powershell
# Unregister Ubuntu (removes all data!)
wsl --unregister Ubuntu

# Disable WSL feature
dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux
```

### Q: Can I use a different Linux distribution?

**A:** Yes! The pipeline works with any WSL distribution (Ubuntu, Debian, Fedora, etc.)

Install from Microsoft Store or:
```powershell
wsl --list --online
wsl --install -d Debian
```

### Q: What happens to my Windows PATH in WSL?

**A:** Windows PATH is automatically appended to WSL PATH, allowing you to call Windows executables from WSL (like `houdini fx.exe`).

---

## Advanced Topics

### Using Windows Git from WSL

To use Windows Git instead of Linux Git:

```bash
# Create alias in ~/.bashrc
echo 'alias git="/mnt/c/Program Files/Git/cmd/git.exe"' >> ~/.bashrc
source ~/.bashrc
```

### Accessing Windows Environment Variables

```bash
# From WSL, call cmd.exe
cmd.exe /c echo %USERNAME%
cmd.exe /c echo %USERPROFILE%
```

### Running GUI Applications

With WSL 2 + WSLg (Windows 11 or Windows 10 with updates):

```bash
# Launch Linux GUI apps directly
firefox &
gedit &
```

Houdini is a Windows app called from WSL, so it uses Windows GUI.

---

## Next Steps

- **Review PowerShell option:** [Windows Setup Guide](WINDOWS_SETUP_GUIDE.md)
- **Compare launchers:** Try both PowerShell and WSL to see which you prefer
- **Optimize workflow:** Choose one method for consistency

---

## Getting Help

**WSL Issues:**
- Microsoft WSL Documentation: https://docs.microsoft.com/en-us/windows/wsl/
- WSL GitHub Issues: https://github.com/microsoft/WSL/issues

**Houdini Pipeline Issues:**
- Report at: https://github.com/jopa79/Houdini_Pipeline/issues

**Houdini Support:**
- SideFX Forum: https://www.sidefx.com/forum/

---

**Version:** 3.0.0
**Last Updated:** 2025-10-21
**Compatible With:** WSL 1, WSL 2, Windows 10/11

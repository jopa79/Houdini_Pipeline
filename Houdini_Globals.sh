#!/bin/bash
#umask 0000

##### LOG FUNCTION (if not already defined by launcher)
if ! type log >/dev/null 2>&1; then
    log() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    }
fi

##### WSL DETECTION FUNCTIONS

# Detect if running in Windows Subsystem for Linux
detect_wsl() {
    # Method 1: Check WSL environment variable (WSL 2)
    if [[ -n "$WSL_DISTRO_NAME" ]]; then
        export WSL=true
        export WSL_VERSION="2"
        log "Running in WSL 2: $WSL_DISTRO_NAME"
        return 0
    fi

    # Method 2: Check /proc/version for Microsoft
    if [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
        export WSL=true

        # Determine WSL version
        if grep -qi "microsoft-standard" /proc/version; then
            export WSL_VERSION="2"
        else
            export WSL_VERSION="1"
        fi

        log "Running in WSL $WSL_VERSION (detected via /proc/version)"
        return 0
    fi

    # Method 3: Check kernel release
    if uname -r | grep -qi microsoft; then
        export WSL=true
        export WSL_VERSION="1"
        log "Running in WSL (detected via uname)"
        return 0
    fi

    # Not running in WSL
    export WSL=false
    return 1
}

# Convert Windows path to WSL path
# Usage: win_to_wsl "C:\Users\Name\Documents"
# Returns: /mnt/c/Users/Name/Documents
win_to_wsl() {
    local winpath="$1"

    if [[ -z "$winpath" ]]; then
        echo ""
        return
    fi

    # Convert C:\path to /mnt/c/path
    # Handle both forward and backslashes
    echo "$winpath" | sed -e 's|^\([A-Za-z]\):|/mnt/\L\1|' -e 's|\\|/|g'
}

# Convert WSL path to Windows path
# Usage: wsl_to_win "/mnt/c/Users/Name/Documents"
# Returns: C:/Users/Name/Documents
wsl_to_win() {
    local wslpath="$1"

    if [[ -z "$wslpath" ]]; then
        echo ""
        return
    fi

    # Convert /mnt/c/path to C:/path
    if [[ "$wslpath" =~ ^/mnt/([a-z])(/.*)?$ ]]; then
        local drive="${BASH_REMATCH[1]^^}"
        local path="${BASH_REMATCH[2]}"
        echo "${drive}:${path}"
    else
        # For paths not in /mnt, return UNC path
        echo "\\\\wsl\$\\${WSL_DISTRO_NAME}${wslpath}" | sed 's|/|\\|g'
    fi
}

# Execute Windows command from WSL
# Usage: wsl_exec "program.exe" args...
wsl_exec() {
    if [[ "$WSL" = true ]]; then
        # In WSL, we can call Windows executables directly if they're in PATH
        # or via /mnt/c/... paths
        "$@"
    else
        log "ERROR: wsl_exec called but not running in WSL"
        return 1
    fi
}

##### CHECK OS
OSNAME=$(uname)

# Detect if running in WSL
if [ "$OSNAME" = "Linux" ]; then
    if detect_wsl; then
        OSNAME="WSL"
    fi
fi

log "Detected OS: $OSNAME"

##### SET HOUDINI VERSION (with environment variable override support)
export HOUDINI_VERSION="${HOUDINI_VERSION:-17.5.229}"
export REDSHIFT_VERSION="${REDSHIFT_VERSION:-17.5.173}"
log "Houdini Version: $HOUDINI_VERSION"
log "Redshift Version: $REDSHIFT_VERSION"

##### SET GLOBAL PATHS
export PIPELINE="$HOUDINI_PIPELINE"
export PACKAGES="$PIPELINE/PACKAGES"

##### SET PACKAGES
export GAMEDEVTOOLSET="$PACKAGES/GameDevelopmentToolset"
export QLIB="$PACKAGES/qLib"
export MOPS="$PACKAGES/MOPS"
export LYNX="$PACKAGES/VFX-LYNX"
export BATCH="$PACKAGES/batch_textures_convert"

export EXPREDITOR="$PACKAGES/HoudiniExprEditor_v1_2_1"
export ALICEVISION_PATH="$PACKAGES/Alicevision-2.1.0"
export JOPA="$HOUDINI_PIPELINE/JOPA"

##### SET GLOBAL DEFAULTS
export FOLDERLIST="$PIPELINE/Folderlist.txt"

export HOUDINI_NO_ENV_FILE=1
export HOUDINI_NO_SPLASH=1
export HOUDINI_NO_START_PAGE_SPLASH=1
export HOUDINI_ANONYMOUS_STATISTICS=0
export HOUDINI_IMAGE_DISPLAY_GAMMA=1
export HOUDINI_IMAGE_DISPLAY_LUT="$PIPELINE/lut/linear-to-srgb_14bit.lut"
export HOUDINI_IMAGE_DISPLAY_OVERRIDE=1
export HOUDINI_EXTERNAL_HELP_BROWSER=1
#export EDITOR="$EXT_EDITOR"

##### DEFINE HOUDINI DIRECTORYS
export HOUDINI_TEMP_DIR="$HIP/tmp"
export HOUDINI_BACKUP_DIR="$HIP/backup"

##### REPO SOURCES
GITMOPS="https://github.com/toadstorm/MOPS.git"
GITQLIB="https://github.com/qLab/qLib.git"
GITGAMEDEVTOOLSET="https://github.com/sideeffects/GameDevelopmentToolset.git"
GITLYNX="https://github.com/LucaScheller/VFX-LYNX.git"
GITBATCH="https://github.com/jtomori/batch_textures_convert.git"

##### CHECK THE REPOS FOR UPDATE OR DOWNLOAD IF NOT INSTALLED
# Support non-interactive mode via environment variable or command-line flag
# Usage: HOUDINI_UPDATE_REPOS=1 ./Houdini_Launcher.sh
#    or: ./Houdini_Launcher.sh --update-repos
if [ "${HOUDINI_UPDATE_REPOS:-}" = "1" ] || [[ "${*}" == *"--update-repos"* ]]; then
    export CHECK="1"
    log "Repository update enabled (non-interactive mode)"
elif [ "${HOUDINI_UPDATE_REPOS:-}" = "0" ] || [[ "${*}" == *"--skip-repos"* ]]; then
    export CHECK="0"
    log "Repository update skipped (non-interactive mode)"
else
    # Interactive mode with timeout
    echo "_________________________________"
    if read -p "| Do you want to check the REPOS? (y/N) |" -n 1 -r -t 5; then
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            export CHECK="1"
            log "Repository update enabled"
        else
            export CHECK="0"
            log "Repository update skipped"
        fi
    else
        # Timeout or no input - default to check repos
        echo ""
        export CHECK="1"
        log "No response (timeout) - defaulting to repository check"
    fi
fi

##### GIT OPERATIONS WITH RETRY LOGIC
# Retry git operations with exponential backoff
# Usage: git_retry <max_retries> <command> [args...]
git_retry() {
    local max_retries=$1
    shift
    local retry_count=0
    local wait_time=2

    while [ $retry_count -lt $max_retries ]; do
        if "$@"; then
            return 0
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                log "Git operation failed, retrying in ${wait_time}s (attempt $((retry_count + 1))/$max_retries)..."
                sleep $wait_time
                wait_time=$((wait_time * 2))
            fi
        fi
    done

    log "ERROR: Git operation failed after $max_retries attempts: $*"
    return 1
}

# Update or clone a repository
# Usage: update_or_clone_repo <repo_path> <git_url> <repo_name>
update_or_clone_repo() {
    local repo_path=$1
    local git_url=$2
    local repo_name=$3

    if [ -d "$repo_path" ]; then
        log "Updating $repo_name..."
        if (cd "$repo_path" && git_retry 4 git pull); then
            log "  ✓ $repo_name updated successfully"
        else
            log "  ✗ WARNING: Failed to update $repo_name (continuing anyway)"
        fi
    else
        log "Installing $repo_name..."
        mkdir -p "$PACKAGES"
        if (cd "$PACKAGES" && git_retry 4 git clone "$git_url"); then
            log "  ✓ $repo_name installed successfully"
        else
            log "  ✗ ERROR: Failed to install $repo_name"
            return 1
        fi
    fi
}

##### REPO CHECK AND INSTALLATION
if [ "$CHECK" = "1" ]; then
    log "Checking repositories..."

    # Create packages directory if it doesn't exist
    mkdir -p "$PACKAGES"

    # Update or clone each repository
    update_or_clone_repo "$MOPS" "$GITMOPS" "MOPS"
    update_or_clone_repo "$QLIB" "$GITQLIB" "qLib"
    update_or_clone_repo "$GAMEDEVTOOLSET" "$GITGAMEDEVTOOLSET" "GameDevelopmentToolset"
    update_or_clone_repo "$LYNX" "$GITLYNX" "VFX-LYNX"
    update_or_clone_repo "$BATCH" "$GITBATCH" "batch_textures_convert"

    log "Repository check complete"
fi

##### SET ENVIRONMENT VARIABLE FOR WSL (Windows Subsystem for Linux)
if [ "$OSNAME" = "WSL" ]; then
	log "Configuring for WSL (Windows Subsystem for Linux)..."

	# Detect Windows username
	if command -v cmd.exe >/dev/null 2>&1; then
		WINDOWS_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
		log "Windows user: $WINDOWS_USER"
	fi

	# Set Windows-based Houdini path
	# Try to find Houdini in common Windows installation locations
	WIN_PROGRAM_FILES="/mnt/c/Program Files/Side Effects Software"
	WIN_PROGRAM_FILES_X86="/mnt/c/Program Files (x86)/Side Effects Software"

	HOUDINI_FOUND=false

	for base_path in "$WIN_PROGRAM_FILES" "$WIN_PROGRAM_FILES_X86"; do
		if [ -d "$base_path/Houdini $HOUDINI_VERSION" ]; then
			export HOUDINI="$base_path/Houdini $HOUDINI_VERSION"
			HOUDINI_FOUND=true
			log "Found Houdini at: $HOUDINI"
			break
		fi
	done

	if [ "$HOUDINI_FOUND" = false ]; then
		# Fallback to default path
		export HOUDINI="/mnt/c/Program Files/Side Effects Software/Houdini $HOUDINI_VERSION"
		log "Using default Houdini path: $HOUDINI (may not exist)"
	fi

	# Convert to Windows path for Windows executables
	export HOUDINI_WIN=$(wsl_to_win "$HOUDINI")
	log "Houdini Windows path: $HOUDINI_WIN"

	# Set Houdini executable (Windows .exe that can be called from WSL)
	export HOUDINI_EXEC="$HOUDINI/bin/houdinifx.exe"

	# Check if Houdini executable exists
	if [ ! -f "$HOUDINI_EXEC" ]; then
		log "WARNING: Houdini executable not found at: $HOUDINI_EXEC"

		# Try houdini.exe as fallback
		if [ -f "$HOUDINI/bin/houdini.exe" ]; then
			export HOUDINI_EXEC="$HOUDINI/bin/houdini.exe"
			log "Using fallback: $HOUDINI_EXEC"
		fi
	fi

	##### SET JUMP PREFERENCES FOR WSL
	# Use Windows paths accessible from WSL
	if [ -n "$WINDOWS_USER" ]; then
		WIN_DOCUMENTS="/mnt/c/Users/$WINDOWS_USER/Documents"

		export L_HDRI="${L_HDRI:-$WIN_DOCUMENTS/Library/HDRI}"
		export L_TEXTURES="${L_TEXTURES:-$WIN_DOCUMENTS/Library/TEXTURES}"
		export L_3DMODELS="${L_3DMODELS:-$WIN_DOCUMENTS/Library/3DMODELS}"
		export L_3DScans="${L_3DScans:-$WIN_DOCUMENTS/Library/3DScans}"
		export L_FOOTAGE="${L_FOOTAGE:-$WIN_DOCUMENTS/Library/FOOTAGE}"
		export L_IES_Lights="${L_IES_Lights:-$WIN_DOCUMENTS/Library/IES_LIGHTS}"
	else
		# Fallback to /mnt/c paths
		export L_HDRI="${L_HDRI:-/mnt/c/Library/HDRI}"
		export L_TEXTURES="${L_TEXTURES:-/mnt/c/Library/TEXTURES}"
		export L_3DMODELS="${L_3DMODELS:-/mnt/c/Library/3DMODELS}"
		export L_3DScans="${L_3DScans:-/mnt/c/Library/3DScans}"
		export L_FOOTAGE="${L_FOOTAGE:-/mnt/c/Library/FOOTAGE}"
		export L_IES_Lights="${L_IES_Lights:-/mnt/c/Library/IES_LIGHTS}"
	fi

	# Generate jump.pref content (convert to Windows paths for Houdini)
	export JUMP="'$(wsl_to_win "$L_HDRI")'"$'\n'"'$(wsl_to_win "$L_TEXTURES")'"$'\n'"'$(wsl_to_win "$L_3DMODELS")'"$'\n'"'$(wsl_to_win "$L_3DScans")'"$'\n'"'$(wsl_to_win "$L_FOOTAGE")'"$'\n'"'$(wsl_to_win "$L_IES_Lights")'"

	log "WSL configuration complete"
	log "  WSL Version: $WSL_VERSION"
	log "  Houdini path (WSL): $HOUDINI"
	log "  Houdini path (Windows): $HOUDINI_WIN"
	log "  Houdini executable: $HOUDINI_EXEC"

	# Note: We don't source houdini_setup in WSL since we're calling Windows Houdini
	# The Windows Houdini will handle its own environment setup
	SKIP_HOUDINI_SETUP=true

##### SET ENVIRONMENT VARIABLE FOR OS X (MacBook)
elif [ "$OSNAME" = "Darwin" ]; then
	log "Configuring for macOS..."

	# Check for trackpad mode (non-interactive mode via env var)
	if [ "${HOUDINI_MMB_PAN:-}" = "" ]; then
		# Interactive prompt with timeout
		if read -p "Are you using a trackpad without a third mouse button? (y/N) " -n 1 -r -t 5; then
			echo ""
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				export HOUDINI_MMB_PAN=0
				log "Trackpad mode enabled (MMB_PAN=0)"
			else
				export HOUDINI_MMB_PAN=1
				log "Mouse mode enabled (MMB_PAN=1)"
			fi
		else
			# Timeout - default to trackpad mode for MacBooks
			echo ""
			export HOUDINI_MMB_PAN=0
			log "No response (timeout) - defaulting to trackpad mode"
		fi
	else
		log "Using HOUDINI_MMB_PAN from environment: $HOUDINI_MMB_PAN"
	fi

	# Set Houdini paths
	export HOUDINI="/Applications/Houdini/Houdini$HOUDINI_VERSION/Frameworks/Houdini.framework/Versions/Current/Resources"
	export HOUDINI_UISCALE=180
	export HOUDINI_ENABLE_RETINA=1

	##### SET EXTERNAL EDITOR FOR OS X
	# export EXT_EDITOR="/Applications/Atom.app/Contents/MacOS/Atom"
	# export EDITOR="$EXT_EDITOR"

	##### SET JUMP PREFERENCES FOR macOS
	# Default library paths for macOS (customize as needed)
	export L_HDRI="${L_HDRI:-$HOME/Library/HDRI}"
	export L_TEXTURES="${L_TEXTURES:-$HOME/Library/TEXTURES}"
	export L_3DMODELS="${L_3DMODELS:-$HOME/Library/3DMODELS}"
	export L_3DScans="${L_3DScans:-$HOME/Library/3DMODELS/3DScans}"
	export L_FOOTAGE="${L_FOOTAGE:-$HOME/Library/FOOTAGE}"
	export L_IES_Lights="${L_IES_Lights:-$HOME/Library/IES_LIGHTS}"

	# Generate jump.pref content
	export JUMP="'$L_HDRI'"$'\n'"'$L_TEXTURES'"$'\n'"'$L_3DMODELS'"$'\n'"'$L_3DScans'"$'\n'"'$L_FOOTAGE'"$'\n'"'$L_IES_Lights'"

	log "macOS configuration complete"
	log "  Houdini path: $HOUDINI"
	log "  UI Scale: $HOUDINI_UISCALE"
	log "  Retina: $HOUDINI_ENABLE_RETINA"
fi

##### SET ENVIRONMENT VARIABLE FOR LINUX
if [ "$OSNAME" = "Linux" ]; then
	log "Configuring for Linux..."

	##### SET GLOBAL VARIABLES FOR LINUX
	export HOUDINI="/opt/hfs17.5"
	export DEADLINE="$HOME/Thinkbox/Deadline10/submitters/HoudiniSubmitter"
	export HOUDINI_OCL_VENDOR="NVIDIA Corporation"
	export HOUDINI_OCL_DEVICENUMBER="${HOUDINI_OCL_DEVICENUMBER:-0}"  # GTX1080TI
	export HOUDINI_NVIDIA_OPTIX_DEVICENUMBER="${HOUDINI_NVIDIA_OPTIX_DEVICENUMBER:-1}"  # RTX2080TI
	export HOUDINI_NVIDIA_OPTIX_DSO_PATH="$HOME/houdini17.5/optix"

	##### SET EXTERNAL EDITOR FOR LINUX
	# export EXT_EDITOR="/opt/sublime_text/sublime_text -w"
	# export EDITOR="$EXT_EDITOR"

	##### SET Jump Preferences LINUX
	export L_HDRI="${L_HDRI:-/mnt/DATA/LIBRARY/HDRI}"
	export L_TEXTURES="${L_TEXTURES:-/mnt/DATA/LIBRARY/TEXTURES}"
	export L_3DMODELS="${L_3DMODELS:-/mnt/DATA/LIBRARY/3DMODELS/}"
	export L_3DScans="${L_3DScans:-/mnt/DATA/LIBRARY/3DMODELS/3DScans}"
	export L_FOOTAGE="${L_FOOTAGE:-/mnt/DATA/LIBRARY/FOOTAGE}"
	export L_IES_Lights="${L_IES_Lights:-/mnt/DATA/LIBRARY/IES_LIGHTS}"

	##### REDSHIFT LINUX ONLY
	export HOUDINI_DSO_ERROR=2
	export REDSHIFT_ROOT="/usr/redshift/"
	export REDSHIFT_HOUDINI_ROOT="$REDSHIFT_ROOT/redshift4houdini/$REDSHIFT_VERSION"

	##### RAID CACHE LINUX ONLY
	export RAID="/mnt/RAID/HOUDINI_CACHE"
	export HOUDINI_MENU_PATH="$HOUDINI_MENU_PATH:$DEADLINE"

	# Generate jump.pref content
	export JUMP="'$L_HDRI'"$'\n'"'$L_TEXTURES'"$'\n'"'$L_3DMODELS'"$'\n'"'$L_3DScans'"$'\n'"'$L_FOOTAGE'"$'\n'"'$L_IES_Lights'"

	log "Linux configuration complete"
	log "  Houdini path: $HOUDINI"
	log "  GPU: $HOUDINI_OCL_DEVICENUMBER (OpenCL), $HOUDINI_NVIDIA_OPTIX_DEVICENUMBER (OptiX)"
fi

##### VALIDATE HOUDINI INSTALLATION
if [ "$OSNAME" != "WSL" ]; then
	# For native Linux and macOS, validate Houdini directory exists
	if [ ! -d "$HOUDINI" ]; then
		log "ERROR: Houdini installation not found at: $HOUDINI"
		log "Please install Houdini or set the correct path in Houdini_Globals.sh"
		exit 1
	fi
	log "Houdini installation validated: $HOUDINI"
else
	# For WSL, check if Windows Houdini executable exists
	if [ ! -f "$HOUDINI_EXEC" ]; then
		log "ERROR: Houdini executable not found at: $HOUDINI_EXEC"
		log "Please install Houdini on Windows or set HOUDINI_VERSION environment variable"
		exit 1
	fi
	log "Houdini executable validated: $HOUDINI_EXEC"
fi

##### BUILD HOUDINI PATH
export HOUDINI_PATH="$HOUDINI_PATH:$EXPREDITOR:$PIPELINE:$GAMEDEVTOOLSET:$MOPS:$QLIB:$LYNX:$BATCH:$DEADLINE:$REDSHIFT_HOUDINI_ROOT:$JOPA:&"

##### SETUP HOUDINI ENVIRONMENT
if [ "$SKIP_HOUDINI_SETUP" = true ]; then
	log "Skipping houdini_setup (WSL mode - Windows Houdini will handle environment)"
else
	log "Setting up Houdini environment..."
	if [ -f "$HOUDINI/houdini_setup" ]; then
		cd "$HOUDINI" || exit 1
		source ./houdini_setup
		cd - > /dev/null || exit 1
		log "Houdini environment setup complete"
	else
		log "ERROR: houdini_setup script not found at: $HOUDINI/houdini_setup"
		exit 1
	fi
fi

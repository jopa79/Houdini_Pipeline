#!/bin/bash
#umask 0000

##### LOG FUNCTION (if not already defined by launcher)
if ! type log >/dev/null 2>&1; then
    log() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    }
fi

##### CHECK OS
OSNAME=$(uname)
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

##### SET ENVIRONMENT VARIABLE FOR OS X (MacBook)
if [ "$OSNAME" = "Darwin" ]; then
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
if [ ! -d "$HOUDINI" ]; then
	log "ERROR: Houdini installation not found at: $HOUDINI"
	log "Please install Houdini or set the correct path in Houdini_Globals.sh"
	exit 1
fi

log "Houdini installation validated: $HOUDINI"

##### BUILD HOUDINI PATH
export HOUDINI_PATH="$HOUDINI_PATH:$EXPREDITOR:$PIPELINE:$GAMEDEVTOOLSET:$MOPS:$QLIB:$LYNX:$BATCH:$DEADLINE:$REDSHIFT_HOUDINI_ROOT:$JOPA:&"

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

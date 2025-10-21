#!/bin/bash
#########################################################################################
#####                                                                               #####
#####  HOUDINI PIPELINE LAUNCHER                                                    #####
#####  Auto-detects pipeline path or uses HOUDINI_PIPELINE environment variable    #####
#####                                                                               #####
#########################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

##### AUTO-DETECT PIPELINE PATH
# Priority: 1) Environment variable, 2) Script directory, 3) Default path
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -z "${HOUDINI_PIPELINE:-}" ]; then
    # Check if script is in pipeline root (has Houdini_Globals.sh)
    if [ -f "$SCRIPT_DIR/Houdini_Globals.sh" ]; then
        export HOUDINI_PIPELINE="$SCRIPT_DIR"
    elif [ -f "$HOME/GitHub/Houdini_Pipeline/Houdini_Globals.sh" ]; then
        export HOUDINI_PIPELINE="$HOME/GitHub/Houdini_Pipeline"
    else
        echo "ERROR: Cannot auto-detect HOUDINI_PIPELINE path"
        echo "Please set HOUDINI_PIPELINE environment variable to point to the pipeline directory"
        echo "Example: export HOUDINI_PIPELINE=\"/path/to/Houdini_Pipeline\""
        exit 1
    fi
fi

#################################################################################

##### INITIALIZE LOGGING
CURRENTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_DIR="$CURRENTDIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/houdini_launch_$(date +%Y%m%d_%H%M%S).log"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "========================================="
log "Houdini Pipeline Launcher Started"
log "Pipeline Path: $HOUDINI_PIPELINE"
log "Project Path: $CURRENTDIR"
log "========================================="

##### VALIDATE PIPELINE PATH
if [ ! -d "$HOUDINI_PIPELINE" ]; then
    log "ERROR: HOUDINI_PIPELINE directory not found: $HOUDINI_PIPELINE"
    exit 1
fi

##### VALIDATE GLOBALS SCRIPT
GLOBALS_SCRIPT="$HOUDINI_PIPELINE/Houdini_Globals.sh"
if [ ! -f "$GLOBALS_SCRIPT" ]; then
    log "ERROR: Houdini_Globals.sh not found at: $GLOBALS_SCRIPT"
    exit 1
fi

##### SOURCE ALL VARIABLES FROM PIPELINE
log "Sourcing global configuration..."
cd "$HOUDINI_PIPELINE" || exit 1

if ! source ./Houdini_Globals.sh 2>&1 | tee -a "$LOG_FILE"; then
    log "ERROR: Failed to source Houdini_Globals.sh"
    exit 1
fi

cd "$CURRENTDIR" || exit 1
log "Global configuration loaded successfully"

##### DEFINE THE CURRENT DIRECTORY AS HIP/JOB VARIABLE
export HIP="$(pwd)"
export JOB="$HIP"
log "HIP/JOB set to: $HIP"

##### VALIDATE FOLDERLIST
if [ -z "${FOLDERLIST:-}" ]; then
    log "ERROR: FOLDERLIST variable not set by Houdini_Globals.sh"
    exit 1
fi

if [ ! -f "$FOLDERLIST" ]; then
    log "WARNING: Folderlist.txt not found at: $FOLDERLIST"
    log "Skipping project folder creation"
else
    ##### CREATE DIRECTORIES
    log "Creating project directories..."
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            if mkdir -p "$line" 2>/dev/null; then
                log "  Created: $line"
            else
                log "  WARNING: Failed to create directory: $line"
            fi
        fi
    done <"$FOLDERLIST"
    log "Project directories created"
fi

##### CREATE JUMP PREFERENCES
log "Creating jump.pref file..."
cd "$HIP" || exit 1
rm -f jump.pref

if [ -n "${JUMP:-}" ]; then
    echo -e "$JUMP" > jump.pref
    log "Jump preferences created"
else
    log "WARNING: JUMP variable not set, jump.pref will be empty"
    touch jump.pref
fi

##### START HOUDINI
log "Launching Houdini..."
log "========================================="

if command -v houdini >/dev/null 2>&1; then
    houdini 2>&1 | tee -a "$LOG_FILE"
else
    log "ERROR: houdini command not found in PATH"
    log "Please ensure Houdini is properly installed and configured"
    exit 1
fi
#!/bin/bash
#umask 0000

##### CHECK OS
OSNAME=`uname`

##### SET HOUDINI VERSION
export HOUDINI_VERSION="17.5.229"
export REDSHIFT_VERSION="17.5.173"

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
printf "\033c"
echo "_________________________________"
read -p "| Do you want to check the REPOS? |" -n 1 -r -t 3
if [[ $REPLY =~ ^[Yy]$ ]]
then
	export CHECK="1"
	echo "| This will take a while.|"
else
	export CHECK="0"
	echo "| NO?! well, it's up to you! |"
fi

##### MESSAGES
MSG_REPO="but it looks like you don't have it. Let me install it for you!"

##### REPO CHECK AND INSTALLATION
printf "\033c"
if [ "$CHECK" == "1" ];
	then
	for i in $MOPS $QLIB $GAMEDEVTOOLSET $LYNX $BATCH
	do
		if [ -d $i ];
		then
			echo "$i repo already exist but will check for updates"
			cd $i && git pull && cd -
		elif [ "$i" == "$MOPS" ]
		then
			echo "CHECK FOR $i $MSG_REPO"
			cd $PACKAGES && git clone $GITMOPS && cd -
			elif [ "$i" == "$QLIB" ]
		then
			echo "CHECK FOR $i $MSG_REPO"
			cd $PACKAGES && git clone $GITQLIB && cd -
		elif [ "$i" == "$GAMEDEVTOOLSET" ]
		then
			echo "CHECK FOR $i $MSG_REPO"
			cd $PACKAGES && git clone $GITGAMEDEVTOOLSET && cd -
		elif [ "$i" == "$LYNX" ]
		then
			echo "CHECK FOR $i $MSG_REPO"
			cd $PACKAGES && git clone $GITLYNX && cd -
		elif [ "$i" == "$BATCH" ]
		then
			echo "CHECK FOR $i $MSG_REPO"
			cd $PACKAGES && git clone $GITBATCH && cd -
		fi
	done
fi

##### SET ENVIRONMENT VARIABLE FOR OS X (MacBook)
printf "\033c"
if [ "$OSNAME" == "Darwin" ];
then
	echo "It looks like you're running houdini on a mac."
	read -p "Are you using a trackpad without a third mouse button ?" -n 1 -r -t 3
	if [[ $REPLY =~ ^[Yy]$ ]]
	then 
		HOUDINI_MMB_PAN=0
	else
		HOUDINI_MMB_PAN=1
	fi
	
	export HOUDINI="/Applications/Houdini/Houdini$HOUDINI_VERSION/Frameworks/Houdini.framework/Versions/Current/Resources"
	export HOUDINI_UISCALE=180
	export HOUDINI_ENABLE_RETINA=1

	##### SET EXTERNAL EDITOR FOR OS X
	# export EXT_EDITOR="/Applications/Atom.app/Contents/MacOS/Atom"
	# export EDITOR="$EXT_EDITOR"
fi

##### SET ENVIRONMENT VARIABLE FOR LINUX
printf "\033c"
if [ "$OSNAME" == "Linux" ];
	then
	##### SET GLOBAL VARIABLES FOR LINUX
	export HOUDINI="/opt/hfs17.5"
	export DEADLINE="$HOME/Thinkbox/Deadline10/submitters/HoudiniSubmitter"
	export HOUDINI_OCL_VENDOR="NVIDIA Corporation"
	export HOUDINI_OCL_DEVICENUMBER="0" # GTX1080TI
	export HOUDINI_NVIDIA_OPTIX_DEVICENUMBER="1" # RTX2080TI
	export HOUDINI_NVIDIA_OPTIX_DSO_PATH="$HOME/houdini17.5/optix"

	##### SET EXTERNAL EDITOR FOR LINUX
	# export EXT_EDITOR="/opt/sublime_text/sublime_text -w"
	# export EDITOR="$EXT_EDITOR"

	##### SET Jump Preferences LINUX ONLY
	export L_HDRI="/mnt/DATA/LIBRARY/HDRI"
	export L_TEXTURES="/mnt/DATA/LIBRARY/TEXTURES"
	export L_3DMODELS="/mnt/DATA/LIBRARY/3DMODELS/"
	export L_3DScans="/mnt/DATA/LIBRARY/3DMODELS/3DScans"
	export L_FOOTAGE="/mnt/DATA/LIBRARY/FOOTAGE"
	export L_IES_Lights="/mnt/DATA/LIBRARY/IES_LIGHTS"

	##### REDSHIFT LINUX ONLY
	export HOUDINI_DSO_ERROR=2
	export REDSHIFT_ROOT="/usr/redshift/"
	export REDSHIFT_HOUDINI_ROOT="$REDSHIFT_ROOT/redshift4houdini/$REDSHIFT_VERSION"

	##### RAID CACHE LINUX ONLY
	export RAID="/mnt/RAID/HOUDINI_CACHE"
	export HOUDINI_MENU_PATH="$HOUDINI_MENU_PATH:$DEADLINE:&"

	export JUMP="'$L_HDRI'"\n"'$L_TEXTURES'"\n"'$L_3DMODELS'"\n"'$L_3DScans'"\n"'$L_FOOTAGE'"\n"'$L_IES_Lights'"
fi

export HOUDINI_PATH="$HOUDINI_PATH:$EXPREDITOR:$PIPELINE:$GAMEDEVTOOLSET:$MOPS:$QLIB:$LYNX:$BATCH:$DEADLINE:$REDSHIFT_HOUDINI_ROOT:$JOPA:&"

cd $HOUDINI && source ./houdini_setup && cd -

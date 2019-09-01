#!/bin/bash
HOUDINI_PIPELINE="$HOME/GitHub/Houdini_Pipeline"

##### STORES THE CURRENT DIRECTORY
CURRENTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

##### DEFINE THE PATH TO THE PIPELINE
CALLCOMMAND="$HOUDINI_PIPELINE"

##### SOURCES ALL VARIABLES FROM PIPELINE
cd $CALLCOMMAND && source ./Houdini_Globals.sh && cd $CURRENTDIR

##### DEFINE THE JOB VARIABLE
#export JOB="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd ../.. && pwd )"

##### DEFINE THE CURRENT DIRECTORY AS HIP/JOB VARIABLE
cd $CURRENTDIR
export HIP="$(pwd)"
export JOB="$HIP"
##### CREATE DIRECTORYS
while IFS= read -r line
do
	mkdir -p "$line"
done <"$FOLDERLIST"

##### DEBUG


##### START HOUDINI
cd $HIP
rm -f jump.pref
echo -e '$L_HDRI'"\n"'$L_TEXTURES'"\n"'$L_3DMODELS'"\n"'$L_3DScans'"\n"'$L_FOOTAGE'"\n"'$L_IES_Lights'>jump.pref
houdini
# Houdini_Pipeline
Multi OS Houdini Pipeline 

**Introduction**

I was looking for a nice and easy way to setup my enviornment variables to run houdini on Mac and Linux.
The idea is to have one launcher which detects your current OS and set the different environment variables.
e.g. i use redshift on linux but not on mac os and some cache drive are only avaiable on linux, on mac i need to deactivate the third mouse button....
This pre-defined setup will clone or update all necessary repositories from Github like: 
Gamedevelopertools, batch_textures_convert, MOPs, qLib, Lynx.

It comes with some custom hda's and my own desktop configuration for mac and linux. It will also setup all the typical folders.

**Installation for OS X and Linux:**

 1. clone or download this repository to your server
 2. edit the *Houdini_Launcher.sh* and change the path from line 8 to your installation directory e.g." *export HOUDINI_PIPELINE="yourpath/Houdini_Pipeline*"
 3. copy the edited *Houdini_Launcher.sh* to all of your Project folder where you want to start Houdini. 
 4. if you like to run it without commandline, rename the launcher from *Houdini_Launcher.sh* to *Houdini_Launcher.command* which makes the file executable with a double click.

**Installation for Windows**

TBA


**ToDo**

-support for windows and our internal pipeline stucture.

-better implementation for the *jump.pref* 

-setup project launcher

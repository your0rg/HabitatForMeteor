#!/bin/bash
#

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 
   exit 1;
fi;

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

cd ${SCRIPTPATH};
echo "Working in ${SCRIPTPATH}";
echo "Configure environment variables...";

. ./ManageShellVars.sh;

loadShellVars;

PARM_NAMES=("GITHUB_PERSONAL_TOKEN" "TARGET_OPERATING_SYSTEM");
askUserForParameters PARM_NAMES[@];


echo "Installing Habitat for ${TARGET_OPERATING_SYSTEM} ...";
. ./DownloadHabitatToPathDir.sh  ${TARGET_OPERATING_SYSTEM};
downloadHabToPathDir;



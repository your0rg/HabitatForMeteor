#!/usr/bin/env bash
#

set -e;

echo "Some tasks need to be run as root...";
sudo ls -l &>/dev/null;

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

if [[ "X${1}X" == "XX" ]]; then
    echo "Usage :: ${0} absolutPathOfTargetMeteorProject";
	exit;
fi;

PRTY="XRSZ :: ";

echo "${PRTY} Stepping into target directory...";
cd ${1};
declare TARGET_PROJECT=$(pwd);
declare HABITAT_WORK=${TARGET_PROJECT}/.habitat;

if [ ! -d ${TARGET_PROJECT}/.meteor ]; then
	echo "Quitting!  Found no directory ${TARGET_PROJECT}/.meteor.";
    exit;
fi;

echo "${PRTY} Purging previous HabitatForMeteor files from target...";
sudo rm -fr ${HABITAT_WORK};

echo "${PRTY} Copying HabitatForMeteor files to target...";
cp -r ${SCRIPTPATH}/.habitat ${TARGET_PROJECT};

echo "${PRTY} Preparing for using Habitat...";
${HABITAT_WORK}/utils/PrepareForHabitat.sh;

echo "${PRTY} Building Meteor app package with Habitat and upload to depot...";
${HABITAT_WORK}/BuildAndUpload.sh;

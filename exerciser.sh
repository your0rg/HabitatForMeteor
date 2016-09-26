#!/usr/bin/env bash
#


set -e;

if [[ "X${1}X" == "XX" || "X${2}X" == "XX" ]]; then
  echo "Usage :: ${0} absolutPathOfTargetMeteorProject releaseTag";
  exit;
fi;

echo "Some tasks need to be run as root...";
sudo ls -l &>/dev/null;

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
PRTY="XRSZ :: ";

RELEASE_TAG=0.1.12;
echo "${PRTY} Stepping into target directory...";
cd ${1};
declare TARGET_PROJECT=$(pwd);
declare HABITAT_WORK=${TARGET_PROJECT}/.habitat;

if [ ! -d ${TARGET_PROJECT}/.meteor ]; then
	echo "Quitting!  Found no directory ${TARGET_PROJECT}/.meteor.";
    exit;
fi;

echo "${PRTY} Purging previous HabitatForMeteor files from target...";
sudo rm -fr ${HABITAT_WORK}/utils;
sudo rm -fr ${HABITAT_WORK}/BuildAndUpload.sh;
sudo rm -fr ${HABITAT_WORK}/plan.sh;

echo "${PRTY} Copying HabitatForMeteor files to target...";
cp -r ${SCRIPTPATH}/.habitat ${TARGET_PROJECT};
mv ${HABITAT_WORK}/target_gitignore ${HABITAT_WORK}/.gitignore ;

echo -e "${PRTY} Preparing for using Habitat...\n\n      *** Yoo Hoo don't forget me ***\n\n";
# ${HABITAT_WORK}/scripts/PrepareForHabitat.sh;

set +e;
git checkout -- package.json;
git checkout -- plan.sh;
git status;
git tag -d ${RELEASE_TAG};
set -e;

echo -e "${PRTY} Building application with Meteor,
         packaging with Habitat and
         uploading to Habitat depot...";
${HABITAT_WORK}/BuildAndUpload.sh ${RELEASE_TAG};

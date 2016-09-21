#!/usr/bin/env bash
#

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

PRTY="XRSZ :: ";
echo "${PRTY} Stepping into target directory...";
cd ${1};
declare TARGET_PROJECT=$(pwd);
declare HABITAT_WORK=${TARGET_PROJECT}/.habitat;

echo "${PRTY} Purging previous HabitatForMeteor files from target...";
rm -fr ${HABITAT_WORK};

echo "${PRTY} Copying HabitatForMeteor files to target...";
cp -r ${SCRIPTPATH}/.habitat ${TARGET_PROJECT};

echo "${PRTY} Preparing for using Habitat...";
${HABITAT_WORK}/utils/PrepareForHabitat.sh;
exit;

echo "${PRTY} Building Meteor app package with Habitat and upload to depot...";
${HABITAT_WORK}/BuildAndUpload.sh;

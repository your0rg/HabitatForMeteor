#!/usr/bin/env bash
#

. ./habitat/scripts/utils.sh;

set -e;

TARGET_PROJECT="${1}";
RELEASE_TAG="${2}";

TARGET_PROJECT="../todos";
RELEASE_TAG="0.0.8";
TARGET_HOST="192.168.122.143";

echo "Some tasks need to be run as root...";
sudo ls -l &>/dev/null;

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
PRTY="XRSZ :: ";

echo "${PRTY} Matching plan.sh settings to release level...";
HABITAT_PLAN_FILE="habitat/plan.sh";
HABITAT_FIELD="pkg_version";
sed -i "0,/${HABITAT_FIELD}/ s|.*${HABITAT_FIELD}.*|${HABITAT_FIELD}=${RELEASE_TAG}|" ${HABITAT_PLAN_FILE};
echo -e "\nPlan Metadata\n";
head -n 5 ${HABITAT_PLAN_FILE};
echo -e "\n";


echo "${PRTY} Stepping into target directory...";
cd ${TARGET_PROJECT};
declare TARGET_PROJECT_PATH=$(pwd);
declare HABITAT_WORK=${TARGET_PROJECT_PATH}/.habitat;
mkdir -p ${HABITAT_WORK};


if [ ! -d ${TARGET_PROJECT_PATH}/.meteor ]; then
  echo "Quitting!  Found no directory ${TARGET_PROJECT_PATH}/.meteor.";
  exit;
fi;

if [ -d ${TARGET_PROJECT_PATH}/.habitat ]; then

    echo "${PRTY} Purging previous HabitatForMeteor files from target...";
    sudo rm -fr ${HABITAT_WORK}/scripts;
    sudo rm -fr ${HABITAT_WORK}/BuildAndUpload.sh;
    sudo rm -fr ${HABITAT_WORK}/plan.sh;

fi;

echo "${PRTY} Copying HabitatForMeteor files to target...";
cp -r ${SCRIPTPATH}/habitat/* ${HABITAT_WORK};


echo -e "${PRTY} Preparing for using Habitat...\n\n";
${HABITAT_WORK}/scripts/PrepareForHabitatBuild.sh;

# set +e;
# git checkout -- package.json &>/dev/null;
# git checkout -- .habitat/plan.sh &>/dev/null;
# git status;
# git tag -d ${RELEASE_TAG} &>/dev/null;

set -e;
TARGET_USER="you";
TARGET_USER_PWD="okok";
HABITAT_USER_PWD_FILE_PATH="${HOME}/.ssh/HabUserPwd";
HABITAT_USER_SSH_KEY_PATH="${HOME}/.ssh/id_rsa.pub";

echo -e "${PRTY} Pushing deployment scripts to target,
         server '${TARGET_HOST}' ready for RPC to upgrade to
         project version ${RELEASE_TAG}...";
${HABITAT_WORK}/scripts/PushInstallerScriptsToTarget.sh \
                   ${TARGET_HOST} \
                   ${TARGET_USER} \
                   ${TARGET_USER_PWD} \
                   ${HABITAT_USER_PWD_FILE_PATH} \
                   ${HABITAT_USER_SSH_KEY_PATH} \
                   ${RELEASE_TAG};

# echo -e "${PRTY} Pushing deployment scripts to target,
#          server '' ready for RPC to upgrade to
#          project version ${RELEASE_TAG}...";
# ${HABITAT_WORK}/scripts/PushInstallerScriptsToTarget.sh ${RELEASE_TAG};

echo -e "${PRTY} Building application with Meteor,
         packaging with Habitat and
         uploading to Habitat depot...";
${HABITAT_WORK}/BuildAndUpload.sh ${RELEASE_TAG};

# --------------------------------------------------------------------------
hidden() {
  "name": "todos",
  "version": "0.0.1",
  "license": "MIT",
  "repository": "https://github.com/FleetingClouds/todos",

}

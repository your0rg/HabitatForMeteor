#!/bin/bash
#

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

PRTY="PREP >> ";
ENVVARSDIRTY=false;
ENVVARSDIRTY=true;

function prepareGitIgnoreFiles() {
  pushd .habitat;
    mv target_gitignore .gitignore; # >/dev/null;
    pushd release_notes >/dev/null;
      mv target_gitignore .gitignore; # >/dev/null;
    popd >/dev/null;
  popd >/dev/null;
}

function addHabitatFilesToGit() {
  git add .habitat/.gitignore;
  git add .habitat/release_notes/.gitignore;
  git add .habitat/.gitignore;
  git add .habitat/default.toml
  git add .habitat/director.toml
  git add .habitat/hooks/
  git add .habitat/plan.sh
}

METEOR_VERSION="";
METEOR_VERSION_MEMORY=${HOME}/.meteorVersion;
if [ -f ${METEOR_VERSION_MEMORY} ]; then
  METEOR_VERSION=$(cat ${METEOR_VERSION_MEMORY});
  echo "${PRTY}Previously, found ${METEOR_VERSION} installed.";
else

  echo "${PRTY}Verifying installed Meteor version (give us a minute...).";
  # METEOR_VERSION=$(meteor --version);
  METEOR_VERSION=$(meteor --version)  &>/dev/null;
  echo "${PRTY}Detected version : '${METEOR_VERSION}'";
  if [[ "X${METEOR_VERSION}X" == "XX" ]]; then
  	echo "${PRTY} ** A Meteor JS installation was expected. **";
    echo "${PRTY}Please install Meteor using ...";
  	echo "${PRTY}    curl https://install.meteor.com/ | sh;    ";
    echo "${PRTY}...then rerun this script ('${0}').";
    exit 1;
  else
    echo "${PRTY}Found ${METEOR_VERSION} installed already..";
    echo ${METEOR_VERSION} > ${METEOR_VERSION_MEMORY};
  fi;

fi;


prepareGitIgnoreFiles;
addHabitatFilesToGit;

cd ${SCRIPTPATH};
echo "${PRTY}Working in ${SCRIPTPATH}";
echo "${PRTY}Configure environment variables...";

. ./ManageShellVars.sh "";

loadShellVars;

PARM_NAMES=("GITHUB_PERSONAL_TOKEN" "TARGET_OPERATING_SYSTEM" "TARGET_ARCHITECTURE");
[ "${ENVVARSDIRTY}" = "true" ] && askUserForParameters PARM_NAMES[@];

echo "${PRTY}Installing script dependencies";

##         'jq'         parses JSON data   "ORIGIN_KEY_ID" 
sudo apt -y install jq;

##     'semver_bash'    parses and compares version numbers
SEMVER_UTIL="semver_bash";
SU_VERSION="0.1.0-beta.03";
SEMVER_TAR="${SEMVER_UTIL}-${SU_VERSION}";
#                                https://github.com/warehouseman/semver_bash/archive/v0.1.0-beta.03.tar.gz
wget -nc -O ${SEMVER_TAR}.tar.gz https://github.com/warehouseman/${SEMVER_UTIL}/archive/v${SU_VERSION}.tar.gz;
tar zxvf ${SEMVER_TAR}.tar.gz ${SEMVER_TAR}/semver.sh;
mv ${SEMVER_TAR}/semver.sh .;
rm -fr ${SEMVER_TAR}*;
# source ./semver.sh
# semverLT 0.0.5 0.0.2; echo $?;
# semverLT 0.0.5 0.0.5; echo $?;
# semverLT 0.0.5 0.0.8; echo $?;
# exit 1;



echo "${PRTY}Verifying installed Habitat version.";
# HABITAT_VERSION=$(hab --version);
HABITAT_VERSION=$(hab --version); &>/dev/null;
echo "${PRTY}Detected Habitat version : '${HABITAT_VERSION}'";
HAB_ALREADY="";
if [[ "X${HABITAT_VERSION}X" == "XX" ]]; then
  HAB_ALREADY="now ";
  echo "${PRTY}Installing Habitat for ${TARGET_OPERATING_SYSTEM} ...";
  . ./DownloadHabitatToPathDir.sh  ${TARGET_OPERATING_SYSTEM};
  downloadHabToPathDir;
else
  echo "${PRTY}Found ${HABITAT_VERSION} installed already..";
fi;

sudo hab install core/hab-sup;
sudo hab pkg binlink core/hab-sup hab-sup;

echo -e "\n\n ** 'Habitat' is ${HAB_ALREADY}installed and ready for use. **\n\n";
exit 0;

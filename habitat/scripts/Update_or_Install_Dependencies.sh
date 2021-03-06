#!/usr/bin/env bash
#
set -e;

TARGET_PROJECT="${1}";

# echo "Some tasks need to be run as root...";
# sudo ls -l &>/dev/null;

SCRIPT=$(readlink -f "$0");
SCRIPTPATH=$(dirname "$SCRIPT");
SCRIPTNAME=$(basename "$SCRIPT");
PRTY="UPINDP :: ";

ENVVARSDIRTY=false;
ENVVARSDIRTY=true;

declare HAB_DIR=${HOME}/.ssh/hab_vault;
mkdir -p ${HAB_DIR};

echo "Some tasks need to be run as root...";
sudo ls -l &>/dev/null;

function prepareGitIgnoreFiles() {
  set +e;
  pushd .habitat >/dev/null;
    mv target_gitignore .gitignore 2>/dev/null;
    pushd release_notes >/dev/null;
      mv target_gitignore .gitignore 2>/dev/null;
    popd >/dev/null;
  popd >/dev/null;
  set -e;
}

function addHabitatFilesToGit() {
  git add .habitat/.gitignore;
  git add .habitat/release_notes/.gitignore;
  git add .habitat/.gitignore;
  git add .habitat/default.toml;
  git add .habitat/hooks/;
  git add .habitat/plan.sh;
}

function isMeteorInstalled() {

	METEOR_VERSION="";
	METEOR_VERSION_MEMORY=${HOME}/.meteorVersion;
	if [ -f ${METEOR_VERSION_MEMORY} ]; then

	  METEOR_VERSION=$(cat ${METEOR_VERSION_MEMORY});
	  echo -e "${PRTY}Previously, found ${METEOR_VERSION} installed.";

	else

	  echo -e "${PRTY}Verifying installed Meteor version (give us a minute...).";
	  # METEOR_VERSION=$(meteor --version);
    set +e;
	  METEOR_VERSION=$(meteor --version 2>/dev/null);
    set -e;
#	  echo -e "${PRTY}Detected version : '${METEOR_VERSION}'";
	  if [[ "X${METEOR_VERSION}X" == "XX" ]]; then
      echo -e "${PRTY} ** A Meteor JS installation was expected. **";
      echo -e "${PRTY}Please install Meteor using ...";
      echo -e "${PRTY}    curl https://install.meteor.com/ | sh;    ";
      echo -e "${PRTY}...then rerun this script ('${0}').

      ";
	    exit 1;
	  else
	    echo -e "${PRTY}Found ${METEOR_VERSION} installed already..";
	    echo ${METEOR_VERSION} > ${METEOR_VERSION_MEMORY};
	  fi;

	fi;

}

cd ${SCRIPTPATH}/../..;
echo -e "${PRTY}Working in ${SCRIPTPATH}/../..";

prepareGitIgnoreFiles;
addHabitatFilesToGit;

cd ${SCRIPTPATH};
echo -e "${PRTY}Working in ${SCRIPTPATH}";

echo -e "${PRTY}Configure environment variables...";
export USER_VARS_FILE_NAME="${HAB_DIR}/envVars.sh";

declare SVs="false";
[ "${NON_STOP}" = "YES" ] || SVs="true";
[ -f ${USER_VARS_FILE_NAME} ] || SVs="true";

[ $(cat ${USER_VARS_FILE_NAME} | \
grep GITHUB_PERSONAL_TOKEN | \
cut -d "'" -f 2 | \
grep -ocwE '^[[:alnum:]]{40}') -gt 0 ] || \
SVs="true";

if [[ "${SVs}" = "true" ]]; then
  echo -e "User vars need to be set...";
  export TARGET_ARCHITECTURE="x86_64";
  export TARGET_OPERATING_SYSTEM="linux";
  . ./ManageShellVars.sh "";
  loadShellVars;
  PARM_NAMES=("GITHUB_PERSONAL_TOKEN" "TARGET_OPERATING_SYSTEM" "TARGET_ARCHITECTURE");
  [ "${ENVVARSDIRTY}" = "true" ] && askUserForParameters PARM_NAMES[@];

else
  echo -e "${PRTY}User vars seem ready.";
fi;

echo -e "\n${PRTY}Installing script dependencies";

##         'jq'         parses JSON data   "ORIGIN_KEY_ID"
sudo apt -y install jq;
sudo apt -y install expect;
sudo apt -y install curl;

##     'semver_shell'    parses and compares version numbers
SEMVER_UTIL="semver_shell";
SU_VERSION="0.2.0";
SEMVER_TAR="${SEMVER_UTIL}-${SU_VERSION}";
#                                https://github.com/warehouseman/semver_shell/archive/v0.2.0.tar.gz
wget -nc -O ${SEMVER_TAR}.tar.gz https://github.com/warehouseman/${SEMVER_UTIL}/archive/v${SU_VERSION}.tar.gz;
tar zxvf ${SEMVER_TAR}.tar.gz ${SEMVER_TAR}/semver.sh;
mv ${SEMVER_TAR}/semver.sh .;
rm -fr ${SEMVER_TAR}*;
# source ./semver.sh
# semverLT 0.0.5 0.0.2; echo $?;
# semverLT 0.0.5 0.0.5; echo $?;
# semverLT 0.0.5 0.0.8; echo $?;
# exit 1;

isMeteorInstalled;

echo -e "\n${PRTY}Verifying installed Habitat version.";
# HABITAT_VERSION=$(hab --version);
set +e; HABITAT_VERSION=$(hab --version 2>/dev/null);set -e;
echo -e "\n${PRTY}Detected Habitat version : '${HABITAT_VERSION}'";
HAB_ALREADY="";
if [[ "X${HABITAT_VERSION}X" == "XX" ]]; then
  HAB_ALREADY="now ";
  echo -e "\n${PRTY}Installing Habitat for ${TARGET_OPERATING_SYSTEM} ...";
  . ./DownloadHabitatToPathDir.sh  ${TARGET_OPERATING_SYSTEM};
  downloadHabToPathDir;
else
  echo -e "\n${PRTY}Found ${HABITAT_VERSION} installed already..";
fi;

sudo hab install core/hab-sup;
sudo hab pkg binlink core/hab-sup hab-sup;

echo -e "'Habitat' is ${HAB_ALREADY}installed and ready.\n";

pushd ${SCRIPTPATH}/../..;
echo -e "\n${PRTY} Your development environment is ready for HabitatForMeteor.
            Next step : switch to your application root directory...

              cd $(pwd);

            ...and run...

              ./.habitat/BuildAndUpload.sh \${ a release tag };

done
.  .  .  .  .  .  .  .  .  .  .  .
";
popd;

#!/bin/bash
#

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

METEOR_VERSION="";
METEOR_VERSION_MEMORY=${HOME}/.meteorVersion;
if [ -f ${METEOR_VERSION_MEMORY} ]; then
  METEOR_VERSION=$(cat ${METEOR_VERSION_MEMORY});
  echo "Previously, found ${METEOR_VERSION} installed.";
else

  echo "Verifying installed Meteor version (give us a minute...).";
  METEOR_VERSION=$(meteor --version);
  # METEOR_VERSION=$(meteor --version)  &>/dev/null;
  echo "Detected version : '${METEOR_VERSION}'";
  if [[ "X${METEOR_VERSION}X" == "XX" ]]; then
  	echo " ** A Meteor JS installation was expected. **";
  	echo "Please install Meteor and run this script again.";
  	echo "    curl https://install.meteor.com/ | sh;    ";
    exit 1;
  else
    echo "Found ${METEOR_VERSION} installed already..";
    echo ${METEOR_VERSION} > ${METEOR_VERSION_MEMORY};
  fi;

fi;

cd ${SCRIPTPATH};
echo "Working in ${SCRIPTPATH}";
echo "Configure environment variables...";
exit;

. ./ManageShellVars.sh;

loadShellVars;

PARM_NAMES=("GITHUB_PERSONAL_TOKEN" "TARGET_OPERATING_SYSTEM" "ORIGIN_KEY_ID");
askUserForParameters PARM_NAMES[@];

echo "Installing script dependencies";
sudo apt -y install jq;

echo "Installing Habitat for ${TARGET_OPERATING_SYSTEM} ...";
. ./DownloadHabitatToPathDir.sh  ${TARGET_OPERATING_SYSTEM};
downloadHabToPathDir;

sudo hab install core/hab-sup;
sudo hab pkg binlink core/hab-sup hab-sup;

echo -e "\n\n ** 'Habitat' is now installed and ready for use. **\n\n";
exit 0;

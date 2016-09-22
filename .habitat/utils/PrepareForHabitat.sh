#!/bin/bash
#

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

echo ${METEOR_VERSION};
METEOR_VERSION=$(meteor --version)  &>/dev/null;

if [[ "X${METEOR_VERSION}X" == "XX" ]]; then
	echo " ** A Meteor JS installation was expected. **";
	echo "Please install Meteor and run this script again.";
	echo "    curl https://install.meteor.com/ | sh;    ";
    exit;
# else
	# echo "Found ${METEOR_VERSION} installed already..";
fi;

cd ${SCRIPTPATH};
echo "Working in ${SCRIPTPATH}";
echo "Configure environment variables...";

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

#!/usr/bin/env bash
#
set -e;

TARGET_PROJECT="${1}";

# echo "Some tasks need to be run as root...";
# sudo ls -l &>/dev/null;

SCRIPT=$(readlink -f "$0");
SCRIPTPATH=$(dirname "$SCRIPT");
SCRIPTFULLPATH=$(pwd);
SCRIPTNAME=$(basename "$SCRIPT");
PRTY="UPINDP :: ";

ENVVARSDIRTY=false;
ENVVARSDIRTY=true;

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

function installMeteor() {

	METEOR_VERSION="";
	METEOR_VERSION_MEMORY=${HOME}/.meteorVersion;
	if [ -f ${METEOR_VERSION_MEMORY} ]; then

	  METEOR_VERSION=$(cat ${METEOR_VERSION_MEMORY});
	  echo "${PRTY}Previously, found ${METEOR_VERSION} installed.";

	else

	  echo "${PRTY}Verifying installed Meteor version (give us a minute...).";
	  # METEOR_VERSION=$(meteor --version);
    set +e;
	  METEOR_VERSION=$(meteor --version 2>/dev/null);
    set -e;
#	  echo "${PRTY}Detected version : '${METEOR_VERSION}'";
	  if [[ "X${METEOR_VERSION}X" == "XX" ]]; then
	  	echo "${PRTY} ** A Meteor JS installation was expected. **";
	    echo "${PRTY}Please install Meteor using ...";
	  	echo "${PRTY}    curl https://install.meteor.com/ | sh;    ";
	    echo -e "${PRTY}...then rerun this script ('${0}').

      ";
	    exit 1;
	  else
	    echo "${PRTY}Found ${METEOR_VERSION} installed already..";
	    echo ${METEOR_VERSION} > ${METEOR_VERSION_MEMORY};
	  fi;

	fi;


}


prepareGitIgnoreFiles;
addHabitatFilesToGit;
installMeteor;

echo -e "Update_or_Install_Dependencies.sh";


echo -e "\n${PRTY} Your development environment is ready for HabitatForMeteor.
            Next step : switch to your application root directory...

              cd ${TARGET_PROJECT};

            ...and run...

              ./.habitat/scrpts/Update_or_Install_Dependencies.sh;

done
.  .  .  .  .  .  .  .  .  .  .  .  
";
date;

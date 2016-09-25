#!/usr/bin/env bash
#
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

PRTY="  ==>  ";

if [[ "X${1}X" == "XX" ]]; then
    echo "Usage :: ${0} releaseTag";
  exit;
fi;
RELEASE_TAG=${1};

echo -e "\n${PRTY} Changing working location to ${SCRIPTPATH}.";
cd ${SCRIPTPATH};

echo "${PRTY} Preparing absolute path names...";
declare HABITAT_WORK=$(pwd);
declare BUILD_ARTIFACTS=${HABITAT_WORK}/results;
declare RELEASE_NOTES=${HABITAT_WORK}/release_notes;
declare RELEASE_NOTE_SUFFIX="_note.txt";
declare METEOR_BUNDLE=${BUILD_ARTIFACTS}/bundle;
declare METEOR_VERSION_FLAG=${METEOR_BUNDLE}/version.txt;
declare SERVER_EXECUTABLES=${METEOR_BUNDLE}/programs/server;

. ./scripts/utils.sh;

# echo "Release tag is :: ${1}";
mkdir -p ./${RELEASE_NOTES};
if [[ ! -f ${RELEASE_NOTES}/${RELEASE_TAG}${RELEASE_NOTE_SUFFIX} ]]; then
  echo -e "\n\nERR: No release note file found for release tag '${RELEASE_TAG}'.
        A distinct release note file is required for each deployment.
        Expected the file...
            '${RELEASE_NOTES}/${RELEASE_TAG}${RELEASE_NOTE_SUFFIX}'
        ...to be a simple text file explaining the changes of this release.
        \n";
  exit 1;
else
  echo -e "${PRTY} Will create, commit and push tag '${RELEASE_TAG}' 
          with commit message from
            '${RELEASE_NOTES}/${RELEASE_TAG}${RELEASE_NOTE_SUFFIX}'
  ";
fi;

echo "${PRTY} Confirming version semantics agreement...";
. ./scripts/VersionControl.sh;
checkSourceVersionsMatch;

getTOMLValueFromName HABITAT_PKG_NAME ${HABITAT} pkg_name;
getTOMLValueFromName HABITAT_PKG_VERSION ${HABITAT} pkg_version;

LATEST_LOCAL_VERSION_TAG=$(git describe 2> /dev/null);
LATEST_REMOTE_VERSION_TAG=$(git ls-remote --refs --tags -t origin \
                          | awk '{print $2}' \
                          | cut -d '/' -f 3 \
                          | cut -d '^' -f 1 \
                          | uniq \
                          | sort \
                          | tail -1);

. ./scripts/semver.sh
COHERENT_VERSIONS=0;
ERMSG="";
set +e;






echo " R ${LATEST_REMOTE_VERSION_TAG}, L ${LATEST_LOCAL_VERSION_TAG}";

if semverGT ${LATEST_REMOTE_VERSION_TAG} ${LATEST_LOCAL_VERSION_TAG}; then
  ERMSG=${ERMSG}"\n - Remote revision tag '${LATEST_REMOTE_VERSION_TAG}' is greater than local revision tag '${LATEST_LOCAL_VERSION_TAG}'!";
  ((COHERENT_VERSIONS++));
fi;

if semverGT ${LATEST_LOCAL_VERSION_TAG} ${HABITAT_PKG_VERSION}; then
  ERMSG=${ERMSG}"\n - Local revision tag '${LATEST_LOCAL_VERSION_TAG}' is greater than application revision tag '${HABITAT_PKG_VERSION}'!";
  ((COHERENT_VERSIONS++));
fi;

if semverGT ${HABITAT_PKG_VERSION} ${RELEASE_TAG}; then
  ERMSG=${ERMSG}"\n - Application revision tag '${HABITAT_PKG_VERSION}' is greater than specified tag '${RELEASE_TAG}'!";
  ((COHERENT_VERSIONS++));
fi;

if (( COHERENT_VERSIONS > 0 )); then
  PLRL=""; (( COHERENT_VERSIONS > 0 )) && PLRL="s";
  echo -e "${PRTY} Revision coherence error${PLRL}${ERMSG}";
  echo -e "      ***  Unsafe to proceed. Revision numbers are out of order ***";
  echo -e "\n${PRTY} Quitting now.\nDone.";
  exit 1;
fi;
set -e;

USER_VARS_FILE_NAME="${HOME}/.userVars.sh";
. ${USER_VARS_FILE_NAME};

HART_FILE_PREFIX="${ORIGIN_KEY_ID}-${HABITAT_PKG_NAME}-${RELEASE_TAG}";
HART_FILE_SUFFIX="${TARGET_ARCHITECTURE}-${TARGET_OPERATING_SYSTEM}.hart";
HART_FILE="${HART_FILE_PREFIX}-*-${HART_FILE_SUFFIX}";
HART_FILE_MSG="${HART_FILE_PREFIX}-yyyymmddhhmmss-${HART_FILE_SUFFIX}";

echo -e "${PRTY} Ready to start building.
                  *** Please confirm the following ***
         -->  Previous deployed application revision tag : ${HABITAT_PKG_VERSION}
         -->          Most recent previous local Git tag : ${LATEST_LOCAL_VERSION_TAG}
         -->         Most recent previous remote Git tag : ${LATEST_REMOTE_VERSION_TAG}
         -->                   Specified new release tag : ${RELEASE_TAG}

              *** If you proceed now you will ***
         1) Set Meteor application revision number to ${RELEASE_TAG}
         2) Rebuild Meteor application for deployment
         3) Set Habitat package plan revision number to ${RELEASE_TAG}
         4) Rebuild Habitat package for deployment
         5) Push a new Git tag '${RELEASE_TAG}' to GitHub
         6) Push the Habitat package to the Habitat public depot unique name:
               '${HART_FILE_MSG}''

            ";

read -r -p "Proceed? [y/N] " response;
case ${response} in
    [yY][eE][sS]|[yY]) 
        echo "${PRTY} Continuing...";
        ;;
    *)
        echo -e "${PRTY} Quitting now.\nDone.";
        exit 1;
        ;;
esac


if [[ -f ${METEOR_VERSION_FLAG} ]]; then
  FLAG_VAL=$(cat ${METEOR_VERSION_FLAG});
  if [[  "${FLAG_VAL}" = "${HABITAT_PKG_VERSION}"  ]]; then
    echo -e "\n\nWARN: *NOT* rebuilding Meteor project.
            Bundle '${FLAG_VAL}' exists already.
            See '${METEOR_VERSION_FLAG}'\n";
  else

    echo "${PRTY} Stepping out to Meteor project directory";
    pushd .. &>/dev/null;

      echo "${PRTY} Ensuring Meteor directory has all necessary node_modules...";
      meteor npm install;

      echo "${PRTY} Building Meteor and putting bundle in results directory...";
      echo "         ** The 'source tree' WARNING can be safely ignored ** ";
      meteor build ./.habitat/results --directory --server-only;
      echo ${HABITAT_PKG_VERSION} > ${METEOR_VERSION_FLAG};

    popd;

  fi;
fi;

HABITAT_REBUILD=true;
for OLD_HART in ${BUILD_ARTIFACTS}/${HART_FILE}; do
    [ -e "${OLD_HART}" ] && HABITAT_REBUILD=false;
    break;
done

if [[ "${HABITAT_REBUILD}" = "false" ]]; then
  echo -e "\nWARN: *NOT* rebuilding Habitat package.
          A file exists already :
           - ${OLD_HART}
          See '${BUILD_ARTIFACTS}/${HART_FILE}'\n\n";
else

  echo "${PRTY} Beginning building '${BUILD_ARTIFACTS}/${HART_FILE_MSG}'...";
  echo "${PRTY} Stepping into the server executables sub-dir of the bundle dir...";
  pushd ${SERVER_EXECUTABLES};

    echo "${PRTY} Ensuring Meteor bundle has all necessary node_modules...";
    meteor npm install;

  popd;

  echo "${PRTY} Building Meteor bundle into Habitat package '${HABITAT_FILE_PREFIX}-yyyymmddhhmmss.hart'...";
  sudo hab pkg build .

fi;
echo "${PRTY} We won't upload yet";
echo "${PRTY} Quitting.";
exit 1;

echo "${PRTY} Uploading Habitat package to default depot...";
sudo hab pkg upload --auth ${GITHUB_AUTH_TOKEN};

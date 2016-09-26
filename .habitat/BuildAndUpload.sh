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


function getNewestHabitatBuildPackage() {
  HART_FILE_TIMESTAMP="";
  HABITAT_REBUILD=true;
  for OLD_HART in "${BUILD_ARTIFACTS}"/*; do
    THE_FILE="${OLD_HART#${BUILD_ARTIFACTS}}";
    [ $(echo ${THE_FILE} | grep -c hart) -lt 1 ] && continue;
    THE_FILE="${THE_FILE#/${HART_FILE_PREFIX}}";
    HART_FILE_TIMESTAMP="${THE_FILE%${HART_FILE_SUFFIX}}";
  done

  set +e;
  HART_FILE="${HART_FILE_PREFIX}${HART_FILE_TIMESTAMP}${HART_FILE_SUFFIX}";
  if ls -l ${BUILD_ARTIFACTS}/${HART_FILE} &>/dev/null; then
    HABITAT_REBUILD=false;
  fi;

  echo -e "HART_FILE_TIMESTAMP ==> ${HART_FILE_TIMESTAMP}";
};

echo -e "\n${PRTY} Changing working location to ${SCRIPTPATH}.";
cd ${SCRIPTPATH};

echo -e "${PRTY} Checking current project commit status.";
pushd .. >/dev/null;
git status --porcelain -uno -b;

GIT_STATUS=$( git status --porcelain -uno -b | wc -l );
if (( ${GIT_STATUS} != 1 )); then
  echo -e "
  ERROR : You have uncommitted changes
      This script will perform a version bump commit only.
      All other changes *must* have been committed previously.
    ";

        echo -e "${PRTY} Quitting now.\nDone.";
        exit 1;
fi;
popd >/dev/null;

. ./scripts/ManageShellVars.sh "scripts/";

loadShellVars;

echo "${PRTY} Preparing absolute path names...";
declare HABITAT_WORK=$(pwd);
declare HABITAT_PLAN=${HABITAT_WORK}/plan.sh;
declare BUILD_ARTIFACTS=${HABITAT_WORK}/results;
declare RELEASE_NOTES=${HABITAT_WORK}/release_notes;
declare RELEASE_NOTE_SUFFIX="_note.txt";

declare METEOR_METADATA=${HABITAT_WORK}/../package.json;
declare METEOR_BUNDLE=${BUILD_ARTIFACTS}/bundle;
declare METEOR_VERSION_FLAG=${METEOR_BUNDLE}/version.txt;
declare SERVER_EXECUTABLES=${METEOR_BUNDLE}/programs/server;

# echo "Release tag is :: ${1}";
mkdir -p ./${RELEASE_NOTES};
RELEASE_NOTE_FILE_NAME=${RELEASE_TAG}${RELEASE_NOTE_SUFFIX};
RELEASE_NOTE_PATH=${RELEASE_NOTES}/${RELEASE_NOTE_FILE_NAME};

if [[ ! -f ${RELEASE_NOTES}/${RELEASE_NOTE_FILE_NAME} ]]; then
  echo -e "\n\nERR: No release note file found for release tag '${RELEASE_TAG}'.
        A distinct release note file is required for each deployment.
        Expected the file...
            '${RELEASE_NOTES}/${RELEASE_NOTE_FILE_NAME}'
        ...to be a simple text file explaining the changes of this release.
        \n";
  exit 1;
else
  echo -e "${PRTY} Will create, commit and push tag '${RELEASE_TAG}' 
          with commit message from
            '${RELEASE_NOTES}/$${RELEASE_NOTE_FILE_NAME}'
  ";
fi;

echo "${PRTY} Confirming version semantics agreement...";
. ./scripts/VersionControl.sh;
checkSourceVersionsMatch;

getTOMLValueFromName HABITAT_PKG_NAME ${HABITAT} pkg_name;
getTOMLValueFromName HABITAT_PKG_VERSION ${HABITAT} pkg_version;

LATEST_LOCAL_VERSION_TAG=$(git describe 2> /dev/null);
if [[ "X${LATEST_LOCAL_VERSION_TAG}X" = "XX" ]]; then
  LATEST_LOCAL_VERSION_TAG="0.0.0";
fi;

LATEST_REMOTE_VERSION_TAG=$(git ls-remote --refs --tags -t origin \
                          | awk '{print $2}' \
                          | cut -d '/' -f 3 \
                          | cut -d '^' -f 1 \
                          | uniq \
                          | sort \
                          | tail -1);

echo "Project metadata revision unique id     : '${HABITAT_PKG_NAME}-${HABITAT_PKG_VERSION}'";
echo "Latest version tag locally              : '${LATEST_LOCAL_VERSION_TAG}'";
echo "Latest version tag on remote repository : '${LATEST_REMOTE_VERSION_TAG}'";


. ./scripts/semver.sh
COHERENT_VERSIONS=0;
ERMSG="";
set +e;






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

echo "${PRTY} Set Meteor app metadata '${METEOR_METADATA}' version record 'version' to '${RELEASE_TAG}'...";
setJSONNameValuePair ${METEOR_METADATA} version ${RELEASE_TAG} >/dev/null;

FLAG_VAL="";
if [[ -f ${METEOR_VERSION_FLAG} ]]; then
  FLAG_VAL=$(cat ${METEOR_VERSION_FLAG});
fi;

echo "Existing Meteor bundle revision level '${FLAG_VAL}'. Build '${RELEASE_TAG}'?";
if [[  "${FLAG_VAL}" == "${RELEASE_TAG}"  ]]; then
  echo -e "\nWARN: *NOT* rebuilding Meteor project.
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

    echo -e "${PRTY} Meteor project rebuilt.  Setting '${METEOR_VERSION_FLAG}'
    to contain '${RELEASE_TAG}.'";
    echo ${RELEASE_TAG} > ${METEOR_VERSION_FLAG};

  popd;

fi;




echo "${PRTY} Set Habitat plan '${HABITAT_PLAN}' version record 'pkg_version' to '${RELEASE_TAG}'...";
setTOMLNameValuePair ${HABITAT_PLAN} pkg_version ${RELEASE_TAG} >/dev/null;
# unset HABITAT_PKG_VERSION;
# getTOMLValueFromName HABITAT_PKG_VERSION ${HABITAT} pkg_version;


HART_FILE_PREFIX="${ORIGIN_KEY_ID}-${HABITAT_PKG_NAME}-${RELEASE_TAG}-";
HART_FILE_SUFFIX="-${TARGET_ARCHITECTURE}-${TARGET_OPERATING_SYSTEM}.hart";
HART_FILE="${HART_FILE_PREFIX}*${HART_FILE_SUFFIX}";
HART_FILE_MSG="${HART_FILE_PREFIX}yyyymmddhhmmss${HART_FILE_SUFFIX}";

getNewestHabitatBuildPackage;

set -e;
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

getNewestHabitatBuildPackage;



USER_VARS_FILE_NAME="${HOME}/.userVars.sh";
. ${USER_VARS_FILE_NAME};

echo -e "${PRTY} Ready to commit changes.

              *** Please confirm the following ***
     -->  Previous deployed application revision tag : ${HABITAT_PKG_VERSION}
     -->          Most recent previous local Git tag : ${LATEST_LOCAL_VERSION_TAG}
     -->         Most recent previous remote Git tag : ${LATEST_REMOTE_VERSION_TAG}
     -->                   Specified new release tag : ${RELEASE_TAG}

          *** If you proceed now, you will ***
     1) Set Habitat package plan revision number to ${RELEASE_TAG}
     2) Push the Habitat package to the Habitat public depot as :
             ${ORIGIN_KEY_ID} / ${HABITAT_PKG_NAME}
             ${RELEASE_TAG} / ${HART_FILE_TIMESTAMP}
     3) Set the project metadata revision number to ${RELEASE_TAG}
     4) Commit all uncommitted app changes (not including untracked files!)
     5) Tag the commit and push all to the remote repository

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


set -e;
echo -e "${PRTY} Uploading Habitat package '${BUILD_ARTIFACTS}/${HART_FILE}' to default depot...
           using ${GITHUB_PERSONAL_TOKEN}";
# ls -l ${BUILD_ARTIFACTS}/${HART_FILE};

        # echo -e "${PRTY} Quitting now.\nDone.\n\n\n\n";
        # exit 1;
sudo hab pkg upload ${BUILD_ARTIFACTS}/${HART_FILE} --auth ${GITHUB_PERSONAL_TOKEN};
git remote update;
git status -uno;






echo "git commit --porcelain --all --file ${RELEASE_NOTE_PATH};";
git commit --all --file ${RELEASE_NOTE_PATH};
git tag --annotate --force --file=${RELEASE_NOTE_PATH} ${RELEASE_TAG};
git push && git push origin ${RELEASE_TAG};

        echo -e "${PRTY} Finishing now.\nDone.\n\n\n\n";
        exit 1;

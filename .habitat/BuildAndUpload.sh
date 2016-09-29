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


function getNewestHabitatBuildPackageIfAny() {

  HART_FILE_TIMESTAMP="";
  export HABITAT_REBUILD=true;
  for OLD_HART in "${BUILD_ARTIFACTS}"/*; do
    THE_FILE="${OLD_HART#${BUILD_ARTIFACTS}}";
    [ $(echo ${THE_FILE} | grep -c "${HART_FILE_PREFIX}") -lt 1 ] && continue;
    THE_FILE="${THE_FILE#/${HART_FILE_PREFIX}}";
    HART_FILE_TIMESTAMP="${THE_FILE%${HART_FILE_SUFFIX}}";
  done

  set +e;
  HART_FILE="${HART_FILE_PREFIX}${HART_FILE_TIMESTAMP}${HART_FILE_SUFFIX}";
  if ls -l ${BUILD_ARTIFACTS}/${HART_FILE} &>/dev/null; then
    HABITAT_REBUILD=false;
  fi;

};

# function detectUncommittedChanges() {

#   echo -e "${PRTY} Checking current project commit status.";
#   pushd .. >/dev/null;

#     # git status --porcelain -uno -b;

#     GIT_STATUS=$( git status --porcelain -uno -b | wc -l );
#     if (( ${GIT_STATUS} != 1 )); then
#       echo -e "
#       ERROR : You have uncommitted changes
#           This script will perform a version bump commit only.
#           All other changes *must* have been committed previously.
#         ";

#             echo -e "${PRTY} Quitting now.\nDone.";
#             exit 1;
#     fi;

#   popd >/dev/null;

# }

function allFilesTracked() {

  echo -e "${PRTY} Checking for untracked files.";
  pushd .. >/dev/null;
    RET=$(git ls-files --others --exclude-standard | wc -l);
  popd >/dev/null;
  return ${RET};

}

function allFilesCommitted() {

  echo -e "${PRTY} Checking for uncommitted files.";
  pushd .. >/dev/null;
    RET=$( expr $( git status --porcelain -uno -b | wc -l ) - 1 );
  popd >/dev/null;
  return ${RET};

}

function detectGitRepoProblem() {

  echo -e "${PRTY} Checking current project commit status.";

  allFilesCommitted || appendToDefectReport "Uncommitted changes
  This script will perform a version bump commit only.
  All other changes *must* have been committed previously.
        ";

  allFilesTracked || appendToDefectReport "Untracked files
  This script will perform a version bump commit only.
  All other changes *must* have been committed previously.
  If those files are required to present, but not
  archived, add them to .gitignore
        ";

};

function prepareAbsolutePathNames() {

  echo "${PRTY} Preparing absolute path names...";
  export HABITAT_WORK=$(pwd);
  export RELEASE_NOTES=${HABITAT_WORK}/release_notes;
  export RELEASE_NOTE_SUFFIX="_note.txt";

  export BUILD_ARTIFACTS=${HABITAT_WORK}/results;

  export METEOR_BUNDLE=${BUILD_ARTIFACTS}/bundle;
  export SERVER_EXECUTABLES=${METEOR_BUNDLE}/programs/server;

  mkdir -p ./${RELEASE_NOTES};

  export RELEASE_NOTE_FILE_NAME=${RELEASE_TAG}${RELEASE_NOTE_SUFFIX};
  export RELEASE_NOTE_PATH=${RELEASE_NOTES}/${RELEASE_NOTE_FILE_NAME};

  export METEOR_METADATA=${HABITAT_WORK}/../package.json;
  export METEOR_VERSION_FLAG=${METEOR_BUNDLE}/version.txt;

  export HABITAT_PLAN=${HABITAT_WORK}/plan.sh;
};


function detectMissingReleaseDescriptorFile() {

  MSG="${PRTY} This release, '${RELEASE_TAG}', will be described by the note : 
       '${RELEASE_NOTE_PATH}'";
  [ -f ${RELEASE_NOTE_PATH} ] && echo -e "${MSG}" && return;

  appendToDefectReport "No release note file found for release tag '${RELEASE_TAG}'.
          A distinct release note file is required for each deployment.
          Expected a simple text file explaining the changes of this release at :
              '${RELEASE_NOTE_PATH}'
          \n";

  # if [[ ! -f ${RELEASE_NOTE_PATH} ]]; then
  #   echo -e "\n\nERR: No release note file found for release tag '${RELEASE_TAG}'.
  #         A distinct release note file is required for each deployment.
  #         Expected the file...
  #             '${RELEASE_NOTE_PATH}'
  #         ...to be a simple text file explaining the changes of this release.
  #         \n";
  #   exit 1;
  # else
  #   echo -e "${PRTY} This release '${RELEASE_TAG}' will be described by the note : 
  #     '${RELEASE_NOTE_PATH}'
  #   ";
  # fi;

}

function detectIncompletePackageJSON() {

  echo "${PRTY} Confirming '${METEOR_METADATA}' has all required fields.";
  MSGB="In the file,'";
  MSGM="', missing field : '";
  MSGE="'.\n";

  jsonFILE=${METEOR_METADATA};
  JSN=$(cat ${jsonFILE});

  FLD=name;
  jsonLacksElement "${JSN}" ${FLD} && appendToDefectReport "${MSGB}${jsonFILE}${MSGM}${FLD}${MSGE}";

  FLD=version;
  jsonLacksElement "${JSN}" ${FLD} && appendToDefectReport "${MSGB}${jsonFILE}${MSGM}${FLD}${MSGE}";

  FLD=license;
  jsonLacksElement "${JSN}" ${FLD} && appendToDefectReport "${MSGB}${jsonFILE}${MSGM}${FLD}${MSGE}";

  FLD=repository;
  jsonLacksElement "${JSN}" ${FLD} && appendToDefectReport "${MSGB}${jsonFILE}${MSGM}${FLD}${MSGE}";

}

detectSourceVersionsMismatch() {

  HABITAT=${1-${HABITAT_PLAN_SH}};
  METEOR=${2-${METEOR_PACKAGE_JSON}};

  getTOMLValueFromName HABITAT_PKG_NAME ${HABITAT} pkg_name;
  getTOMLValueFromName HABITAT_PKG_VERSION ${HABITAT} pkg_version;
  getTOMLValueFromName HABITAT_PKG_ORIGIN ${HABITAT} pkg_origin;

  getJSONValueFromName METEOR_NAME ${METEOR} name;
  getJSONValueFromName METEOR_VERSION ${METEOR} version;

  # echo "Got ${HABITAT_PKG_VERSION}";
  # echo "Got ${METEOR_VERSION}";

  # echo "Got ${HABITAT_PKG_NAME}";
  # echo "Got ${METEOR_NAME}";

  MSGA="Version Mismatch.
  The version semantics of '${HABITAT}'' and '${METEOR}'' must match exactly.";

  [ "${HABITAT_PKG_NAME}" = "${METEOR_NAME}" ] || appendToDefectReport "${MSGA}
         Please correct the names and try again.
    >> ${HABITAT} :: ${HABITAT_PKG_NAME}
    >> ${METEOR} :: ${METEOR_NAME}
  ";

  [ "${HABITAT_PKG_VERSION}" = "${METEOR_VERSION}" ] || appendToDefectReport "${MSGA}
    Please correct the version numbers and try again.
    >> ${HABITAT} :: ${HABITAT_PKG_VERSION}
    >> ${METEOR} :: ${METEOR_VERSION}
  ";




  # getTOMLValueFromName HABITAT_PKG_ORIGIN ${HABITAT} pkg_origin;

  # [ "${HABITAT_PKG_ORIGIN}" = "${ORIGIN_KEY_ID}" ] || appendToDefectReport "Origin Identifier Error
  #   Please correct the origin identifiers and try again.
  #   >> ${HABITAT} :: ${HABITAT_PKG_ORIGIN}
  #   >> ${HOME}/.userVars.sh :: ${ORIGIN_KEY_ID}
  # ";



  # OK=true;
  # if [[ "${HABITAT_PKG_NAME}" != "${METEOR_NAME}" ]]; then
  #   echo "Please correct the names and try again.";
  #   echo "${HABITAT} :: ${HABITAT_PKG_NAME}";
  #   echo "${METEOR} :: ${METEOR_NAME}";
  #   OK=false;
  # else
  #   echo "           Version names match.";
  # fi;

#   if [[ "${HABITAT_PKG_VERSION}" != "${METEOR_VERSION}" ]]; then
#     echo "Please correct version numbers and try again.";
#     echo "${HABITAT} :: ${HABITAT_PKG_VERSION}";
#     echo "${METEOR} :: ${METEOR_VERSION}";
#     OK=false;
#   else
#     echo "           Version numbers match.";
#   fi;

#   if [[ "${OK}" == "false" ]]; then
#     echo "ERROR: Version Mismatch.
#  The version semantics of '${HABITAT}'' and '${METEOR}'' must match exactly.";
# #    exit 1;
#   fi;
}


function detectIncoherentVersionSemantics() {

  echo "${PRTY} Confirming version semantics agreement...";

  . ./scripts/VersionControl.sh;
  detectSourceVersionsMismatch;

  getTOMLValueFromName HABITAT_PKG_NAME ${HABITAT} pkg_name;
  getTOMLValueFromName HABITAT_PKG_VERSION ${HABITAT} pkg_version;

  LATEST_LOCAL_VERSION_TAG=$(git describe 2> /dev/null);
  if [[ "X${LATEST_LOCAL_VERSION_TAG}X" = "XX" ]]; then
    LATEST_LOCAL_VERSION_TAG="0.0.0";
  fi;
  git remote update >/dev/null;
  LATEST_REMOTE_VERSION_TAG=$(git ls-remote --refs --tags -t origin \
                            | awk '{print $2}' \
                            | cut -d '/' -f 3 \
                            | cut -d '^' -f 1 \
                            | uniq \
                            | sort \
                            | tail -1);

  if [[ "X${LATEST_REMOTE_VERSION_TAG}X" = "XX" ]]; then
    LATEST_REMOTE_VERSION_TAG="0.0.0";
  fi;

  # echo "           Project metadata revision unique id     : '${HABITAT_PKG_NAME}-${HABITAT_PKG_VERSION}'";
  # echo "           Latest version tag locally              : '${LATEST_LOCAL_VERSION_TAG}'";
  # echo "           Latest version tag on remote repository : '${LATEST_REMOTE_VERSION_TAG}'";





  . ./scripts/semver.sh
  # COHERENT_VERSIONS=0;
  # ERMSG="";
  # set +e;


  local iGT="is greater than";
  local MSGA="Revision Incoherence.
  ***  Unsafe to proceed. Revision numbers are out of order ***";

  semverGT ${LATEST_REMOTE_VERSION_TAG} ${LATEST_LOCAL_VERSION_TAG} && appendToDefectReport "${MSGA}
    Remote revision tag '${LATEST_REMOTE_VERSION_TAG}' ${iGT} local revision tag '${LATEST_LOCAL_VERSION_TAG}'!
  ";

  semverGT ${LATEST_LOCAL_VERSION_TAG} ${HABITAT_PKG_VERSION} && appendToDefectReport "${MSGA}
    Local revision tag '${LATEST_LOCAL_VERSION_TAG}' ${iGT} application revision tag '${HABITAT_PKG_VERSION}'!
  ";

  semverGT ${HABITAT_PKG_VERSION} ${RELEASE_TAG} && appendToDefectReport "${MSGA}
    Application revision tag '${HABITAT_PKG_VERSION}' ${iGT} specified tag '${RELEASE_TAG}'!
  ";


  # if semverGT ${LATEST_REMOTE_VERSION_TAG} ${LATEST_LOCAL_VERSION_TAG}; then
  #   ERMSG=${ERMSG}"\n - Remote revision tag '${LATEST_REMOTE_VERSION_TAG}' 
  #    is greater than local revision tag '${LATEST_LOCAL_VERSION_TAG}'!";
  #   ((COHERENT_VERSIONS++));
  # fi;

  # if semverGT ${LATEST_LOCAL_VERSION_TAG} ${HABITAT_PKG_VERSION}; then
  #   ERMSG=${ERMSG}"\n - Local revision tag '${LATEST_LOCAL_VERSION_TAG}' 
  #    is greater than application revision tag '${HABITAT_PKG_VERSION}'!";
  #   ((COHERENT_VERSIONS++));
  # fi;

  # if semverGT ${HABITAT_PKG_VERSION} ${RELEASE_TAG}; then
  #   ERMSG=${ERMSG}"\n - Application revision tag '${HABITAT_PKG_VERSION}'
  #    is greater than specified tag '${RELEASE_TAG}'!";
  #   ((COHERENT_VERSIONS++));
  # fi;

  # if (( COHERENT_VERSIONS > 0 )); then
  #   PLRL=""; (( COHERENT_VERSIONS > 0 )) && PLRL="s";
  #   echo -e "${PRTY} Revision coherence error${PLRL}${ERMSG}";
  #   echo -e "      ***  Unsafe to proceed. Revision numbers are out of order ***";
  #   echo -e "\n${PRTY} Quitting now.\nDone.";
  #   exit 1;
  # fi;
  # set -e;

}

function detectMissingHabitatOriginKey() {
  sudo hab origin key export your0rg --type public 2>/dev/null || appendToDefectReport "Missing Habitat Origin Key.
    A Habitat origin key must be generated or imported.
    Eg; 
        'sudo hab setup;  # First time use only!'
    or
        'echo \"\${yourHabitatOrigin}-yyyymmddhhmmss.pub\" > sudo hab origin key import';
        'echo \"\${yourHabitatOrigin}-yyyymmddhhmmss.sig.key\" > sudo hab origin key import';
  ";
#     TEMPORARY NOTE: An unresolved issue means that the key must

}

function buildMeteorProjectBundleIfNotExist() {

  echo "${PRTY} Set Meteor app metadata '${METEOR_METADATA}' version record 'version' to '${RELEASE_TAG}'...";
  setJSONNameValuePair ${METEOR_METADATA} version ${RELEASE_TAG} >/dev/null;

  FLAG_VAL=" none ";
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

      echo -e "${PRTY} Meteor project rebuilt.
      Setting '${METEOR_VERSION_FLAG}' to contain '${RELEASE_TAG}.'";
      echo ${RELEASE_TAG} > ${METEOR_VERSION_FLAG};

    popd &>/dev/null;

  fi;

}


function buildHabitatArchivePackageIfNotExist() {

  echo "${PRTY} Set Habitat plan '${HABITAT_PLAN}' version record 'pkg_version' to '${RELEASE_TAG}'...";
  setTOMLNameValuePair ${HABITAT_PLAN} pkg_version ${RELEASE_TAG} >/dev/null;

  HART_FILE_PREFIX="${HABITAT_PKG_ORIGIN}-${HABITAT_PKG_NAME}-${RELEASE_TAG}-";
  HART_FILE_SUFFIX="-${TARGET_ARCHITECTURE}-${TARGET_OPERATING_SYSTEM}.hart";
  HART_FILE="${HART_FILE_PREFIX}*${HART_FILE_SUFFIX}";
  HART_FILE_MSG="${HART_FILE_PREFIX}yyyymmddhhmmss${HART_FILE_SUFFIX}";

  getNewestHabitatBuildPackageIfAny;

  set -e;
  if [[ "${HABITAT_REBUILD}" = "false" ]]; then
    echo -e "\nWARN: *NOT* rebuilding Habitat package.
            A file exists already :
             - ${OLD_HART}
            See '${BUILD_ARTIFACTS}/${HART_FILE}'\n\n";
  else

    echo "${PRTY} Beginning building '${BUILD_ARTIFACTS}/${HART_FILE_MSG}'...";
    echo -e "${PRTY} Stepping into the server executables sub-directory
         of the Meteor bundle directory... 
         ${HART_FILE_PREFIX}*${HART_FILE_SUFFIX}";

    pushd ${SERVER_EXECUTABLES} >/dev/null;

      echo "${PRTY} Ensuring Meteor bundle has all necessary node_modules...";
      meteor npm install;

    popd >/dev/null;

    echo "${PRTY} Building Meteor bundle into Habitat package '${HART_FILE_PREFIX}-yyyymmddhhmmss.hart'...";
    sudo hab pkg build --keys "${HABITAT_PKG_ORIGIN}" .

  fi;

  getNewestHabitatBuildPackageIfAny;

}


function uploadHabitatArchiveFileToDepot() {

  set -e;
  echo -e "${PRTY} Uploading Habitat package '${BUILD_ARTIFACTS}/${HART_FILE}' to default depot...
             using ${GITHUB_PERSONAL_TOKEN}";
  # ls -l ${BUILD_ARTIFACTS}/${HART_FILE};

          # echo -e "${PRTY} Quitting now.\nDone.\n\n\n\n";
          # exit 1;
  sudo hab pkg upload ${BUILD_ARTIFACTS}/${HART_FILE} --auth ${GITHUB_PERSONAL_TOKEN};
  set +e;

}


HABITAT_PKG_NAME="";
HABITAT_PKG_VERSION="";
HABITAT_PKG_ORIGIN="";
LATEST_LOCAL_VERSION_TAG="";
LATEST_REMOTE_VERSION_TAG="";


echo -e "\n${PRTY} Changing working location to ${SCRIPTPATH}.";
cd ${SCRIPTPATH};

. ./scripts/utils.sh;

set +e;

detectMissingHabitatOriginKey;

detectGitRepoProblem;

. ./scripts/ManageShellVars.sh "scripts/";   loadShellVars;

prepareAbsolutePathNames;

detectIncompletePackageJSON;

detectMissingReleaseDescriptorFile;

detectIncoherentVersionSemantics;

showDefectReport;


buildMeteorProjectBundleIfNotExist;

buildHabitatArchivePackageIfNotExist;

echo -e "${PRTY} Ready to commit changes.

              *** Please confirm the following ***
     -->  Previous deployed application revision tag : ${HABITAT_PKG_VERSION}
     -->          Most recent previous local Git tag : ${LATEST_LOCAL_VERSION_TAG}
     -->         Most recent previous remote Git tag : ${LATEST_REMOTE_VERSION_TAG}
     -->                   Specified new release tag : ${RELEASE_TAG}

          *** If you proceed now, you will ***
     1) Set Habitat package plan revision number to ${RELEASE_TAG}
     2) Push the Habitat package to the Habitat public depot as :
             ${HABITAT_PKG_ORIGIN} / ${HABITAT_PKG_NAME}
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

uploadHabitatArchiveFileToDepot;

git remote update;
GIT_DIFF_COUNT=$(git diff origin/master --name-only  | wc -l)
if [[ "${GIT_DIFF_COUNT}" != "0" ]]; then
  echo -e "ERROR ::  Unexpected change in remote repository.
     Don't know how to resolve.
     The following file(s) have changed : ";
  git diff origin/master --name-only | sed "/plan.sh\|package.json/d";
  echo -e "${PRTY} Finishing now.\nDone.\n\n\n\n";
  exit 1;
fi;

git status -uno;

echo "git commit --porcelain --all --file ${RELEASE_NOTE_PATH};";
git commit --all --file ${RELEASE_NOTE_PATH};
git tag --annotate --force --file=${RELEASE_NOTE_PATH} ${RELEASE_TAG};
git push && git push origin ${RELEASE_TAG};

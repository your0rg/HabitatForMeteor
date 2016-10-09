#!/usr/bin/env bash
#

. ./.habitat/scripts/utils.sh;

# declare -a DEFECT_REPORT;
# function appendToDefectReport() {
#   DEFECT_REPORT+=($1);
# }

# function freeOfDefects() {
#   return ${#DEFECT_REPORT[@]};
# }

# function showDefectReport() {

#   freeOfDefects && return 0;

#   CNT=1;
#   SEP="";
#   for DEFECT in "${DEFECT_REPORT[@]}"
#   do
#     echo -e "${SEP};
#     Fix #${CNT} - ${DEFECT}";
#     CNT=$(expr $CNT + 1);
#     SEP=" ­­­°  °  °  °  °  °  °  °  °  °  °  °  °  °   ";
#   done

# }

      # function jsonHasElement() {
      #   echo ${1} | jq ".${2}"  | grep -c null >/dev/null;
      #   return $?;
      # }

      # FLD=name;
      # FLE="/home/you/projects/vTodos/package.json";
      # JSN=$(cat ${FLE});
      # jsonHasElement "${JSN}" ${FLD} && appendToDefectReport "In the file,'${FLE}', missing field : ${FLD}";
      # showDefectReport;
      # echo -e "


      # ";
      # exit 0;


      # echo "go";
      # showDefectReport;
      # appendToDefectReport "asdfasdf";
      # showDefectReport;
      # appendToDefectReport "wertwert";
      # showDefectReport;


      # echo "end";

      # exit;

set -e;

# if [[ "X${1}X" == "XX" || "X${2}X" == "XX" ]]; then
#   echo "Usage :: ${0} absolutPathOfTargetMeteorProject releaseTag";
#   exit;
# fi;

TARGET_PROJECT="${1}";
RELEASE_TAG="${2}";

TARGET_PROJECT="../todos";
RELEASE_TAG="0.0.1";


echo "Some tasks need to be run as root...";
sudo ls -l &>/dev/null;

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
PRTY="XRSZ :: ";

echo "${PRTY} Matching plan.sh settings to release level...";
HABITAT_PLAN_FILE=".habitat/plan.sh";
HABITAT_FIELD="pkg_version";
sed -i "0,/${HABITAT_FIELD}/ s|.*${HABITAT_FIELD}.*|${HABITAT_FIELD}=${RELEASE_TAG}|" ${HABITAT_PLAN_FILE}; 
echo -e "\nPlan Metadata\n"; 
head -n 5 ${HABITAT_PLAN_FILE};
echo -e "\n";


echo "${PRTY} Stepping into target directory...";
cd ${TARGET_PROJECT};
declare TARGET_PROJECT_PATH=$(pwd);
declare HABITAT_WORK=${TARGET_PROJECT_PATH}/.habitat;

if [ ! -d ${TARGET_PROJECT_PATH}/.meteor ]; then
   echo "Quitting!  Found no directory ${TARGET_PROJECT_PATH}/.meteor.";
    exit;
fi;

if [ ! -d ${TARGET_PROJECT_PATH}/.habitat ]; then

   echo "${PRTY} Purging previous HabitatForMeteor files from target...";
   sudo rm -fr ${HABITAT_WORK}/utils;
   sudo rm -fr ${HABITAT_WORK}/BuildAndUpload.sh;
   sudo rm -fr ${HABITAT_WORK}/plan.sh;

   echo "${PRTY} Copying HabitatForMeteor files to target...";
   cp -r ${SCRIPTPATH}/.habitat ${TARGET_PROJECT_PATH};

   echo -e "${PRTY} Preparing for using Habitat...\n\n      *** Yoo Hoo don't forget me ***\n\n";
   ${HABITAT_WORK}/scripts/PrepareForHabitat.sh;

fi;

set +e;
git checkout -- package.json &>/dev/null;
git checkout -- .habitat/plan.sh &>/dev/null;
git status;
git tag -d ${RELEASE_TAG} &>/dev/null;
set -e;

echo -e "${PRTY} Building application with Meteor,
         packaging with Habitat and
         uploading to Habitat depot...";
${HABITAT_WORK}/BuildAndUpload.sh ${RELEASE_TAG};

hidden() {
  "name": "todos",
  "version": "0.0.1",
  "license": "MIT",
  "repository": "https://github.com/FleetingClouds/todos",

}
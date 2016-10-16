#!/usr/bin/env bash
#
# . ./habitat/scripts/utils.sh;

set -e;

TARGET_PROJECT="${1}";

# echo "Some tasks need to be run as root...";
# sudo ls -l &>/dev/null;

SCRIPT=$(readlink -f "$0");
SCRIPTPATH=$(dirname "$SCRIPT");
SCRIPTFULLPATH=$(pwd);
SCRIPTNAME=$(basename "$SCRIPT");
HABITAT_PATH=${SCRIPTPATH}/habitat;
PRTY="UPINH4M :: ";

# echo "${PRTY} Matching plan.sh settings to release level...";
# HABITAT_PLAN_FILE="habitat/plan.sh";
# HABITAT_FIELD="pkg_version";
# sed -i "0,/${HABITAT_FIELD}/ s|.*${HABITAT_FIELD}.*|${HABITAT_FIELD}=${RELEASE_TAG}|" ${HABITAT_PLAN_FILE};
# echo -e "\nPlan Metadata\n";
# head -n 5 ${HABITAT_PLAN_FILE};
# echo -e "\n";

function usage() {
  echo -e "    Usage ::
     ${SCRIPTPATH}/${SCRIPTNAME} \${TARGET_PROJECT};
      Where :
        TARGET_PROJECT is the path to the project into which HabitatForMeteor should be installed.
  ";
  exit 1;
}

declare -a CHANGES_ARRAY=();
function collectChanges() {
#  if [[ ${#CHANGES_ARRAY[@]} -lt 1 ]]; then echo "make"; fi;
  CHANGES_ARRAY=("${CHANGES_ARRAY[@]}" "${1}");
}

FILE="XYZ";
function listChanges() {
  if [[ ${#CHANGES_ARRAY[@]} -gt 0 ]]; then
    if [[ ${#CHANGES_ARRAY[@]} -gt 1 ]]; then
      echo -e "${PRTY} Some files have changed.
          Consider reviewing the changes with 'diff' for possible upgrades.";
      for FILE in "${CHANGES_ARRAY[@]}"
      do
        echo "            diff ${HABITAT_PATH}/${FILE} ${HABITAT_WORK}/${FILE};"
        # do something on $var
      done

    else
      FILE=${CHANGES_ARRAY[@]}
      echo -e "${PRTY} The file, '${FILE}', has changed.
          Consider reviewing the changes with 'diff' for possible upgrades.
            diff ${HABITAT_PATH}/${FILE} ${HABITAT_WORK}/${FILE};
      ";
      for var in "${CHANGES_ARRAY[@]}"
      do
        echo "Changed ${var}"
        # do something on $var
      done
    fi;

  else
    echo -e "${PRTY} No changes";
  fi;
}

if [ ! -d ${TARGET_PROJECT}/.meteor ]; then
  echo "Quitting!  Found no directory ${TARGET_PROJECT}/.meteor.";
  usage;
fi;

echo "${PRTY} Stepping into target directory, ${TARGET_PROJECT}...";
cd ${TARGET_PROJECT};
declare TARGET_PROJECT_PATH=$(pwd);
declare HABITAT_WORK=${TARGET_PROJECT_PATH}/.habitat;
mkdir -p ${HABITAT_WORK};

if [ -f ${HABITAT_WORK}/plan.sh ]; then

  echo "${PRTY} Updating previous HabitatForMeteor files of target...";
  cp -p  ${HABITAT_PATH}/BuildAndUpload.sh ${HABITAT_WORK};
  cp -pr ${HABITAT_PATH}/scripts ${HABITAT_WORK};

  echo "${PRTY} Detecting changes ...";
  set +e;
  FILE="plan.sh";
  diff ${HABITAT_PATH}/${FILE} ${HABITAT_WORK}/${FILE} >/dev/null || collectChanges ${FILE};
  FILE="default.toml";
  diff ${HABITAT_PATH}/${FILE} ${HABITAT_WORK}/${FILE} >/dev/null || collectChanges ${FILE};
  FILE="hooks/init";
  diff ${HABITAT_PATH}/${FILE} ${HABITAT_WORK}/${FILE} >/dev/null || collectChanges ${FILE};
  FILE="hooks/run";
  diff ${HABITAT_PATH}/${FILE} ${HABITAT_WORK}/${FILE} >/dev/null || collectChanges ${FILE};
  set -e;

  listChanges;

else

  echo "${PRTY} Copying HabitatForMeteor files to target...";
  cp -r ${HABITAT_PATH}/* ${HABITAT_WORK};
  mv ${HABITAT_WORK}/target_gitignore ${HABITAT_WORK}/.gitignore;
  mv ${HABITAT_WORK}/release_notes/target_gitignore ${HABITAT_WORK}/release_notes/.gitignore;

fi;



echo -e "\n${PRTY} Your application is ready for HabitatForMeteor.
            If you change your mind, just delete the directory '.habitat'.
            If you choose to continue you can delete this directory '${SCRIPTFULLPATH}'.
            Next step : switch to your application root directory...

              cd ${TARGET_PROJECT};

            ...and run...

              ./.habitat/scripts/Update_or_Install_Dependencies.sh;

done
.  .  .  .  .  .  .  .  .  .  .  .  
";

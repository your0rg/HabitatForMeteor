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

echo -e "${PRTY}\nCopying HabitatForMeteor files to target...";
SCRIPTS_PATH='scripts';
SEMVER_SHELL_PATH='semver-shell';
SEMVER_SH='semver.sh';
pushd ${HABITAT_PATH} >/dev/null;
  cp -p  BuildAndUpload.sh ${HABITAT_WORK};
  rsync -a --exclude="${SCRIPTS_PATH}/${SEMVER_SHELL_PATH}" . ${HABITAT_WORK};

  mkdir -p ${HABITAT_WORK}/${SCRIPTS_PATH}/${SEMVER_SHELL_PATH};

  cp                 ${SCRIPTS_PATH}/${SEMVER_SHELL_PATH}/${SEMVER_SH} \
     ${HABITAT_WORK}/${SCRIPTS_PATH}/${SEMVER_SHELL_PATH};

popd >/dev/null;

mv ${HABITAT_WORK}/target_gitignore ${HABITAT_WORK}/.gitignore;
mv ${HABITAT_WORK}/release_notes/target_gitignore ${HABITAT_WORK}/release_notes/.gitignore;

if [ -f ${HABITAT_WORK}/plan.sh ]; then

  echo "${PRTY} Detecting changes ...";
  set +e;
  # FILE="plan.sh";
  # diff ${HABITAT_PATH}/${FILE} ${HABITAT_WORK}/${FILE} >/dev/null || collectChanges ${FILE};
  FILE="default.toml";
  diff ${HABITAT_PATH}/${FILE} ${HABITAT_WORK}/${FILE} >/dev/null || collectChanges ${FILE};
  FILE="hooks/init";
  diff ${HABITAT_PATH}/${FILE} ${HABITAT_WORK}/${FILE} >/dev/null || collectChanges ${FILE};
  FILE="hooks/run";
  diff ${HABITAT_PATH}/${FILE} ${HABITAT_WORK}/${FILE} >/dev/null || collectChanges ${FILE};
  set -e;

  listChanges;

fi;

echo -e "\n${PRTY} Your application is ready for HabitatForMeteor.

            If you change your mind, just delete the directory '${TARGET_PROJECT}.habitat'.
            If you choose to continue you can delete this directory '${SCRIPTFULLPATH}'.

            Next steps :

            1/. switch to your application root directory...

              cd ${TARGET_PROJECT};

            2/. copy the file...
                  ./.habitat/plan.sh.example'
                            ... to ...
                  ./.habitat/plan.sh'
                                   ... and configure as needed.
            3/. run the script...

              ./.habitat/scripts/Update_or_Install_Dependencies.sh;

done
.  .  .  .  .  .  .  .  .  .  .  .
";

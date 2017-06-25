#!/usr/bin/env bash
#
function loadSemVerScript() {

  SEMVER_SCRIPT_NAME="semver.sh";
  if [[ ! -x ${SEMVER_SCRIPT_NAME} ]]; then
    ##     'semver_shell'    parses and compares version numbers
    SEMVER_UTIL="semver_shell";
    SU_VERSION="0.2.0";
    SEMVER_TAR="${SEMVER_UTIL}-${SU_VERSION}";

    #                                https://github.com/warehouseman/semver_shell/archive/v0.2.0.tar.gz
    wget -nc -O ${SEMVER_TAR}.tar.gz https://github.com/warehouseman/${SEMVER_UTIL}/archive/v${SU_VERSION}.tar.gz;
    tar zxvf ${SEMVER_TAR}.tar.gz ${SEMVER_TAR}/${SEMVER_SCRIPT_NAME};
    mv ${SEMVER_TAR}/${SEMVER_SCRIPT_NAME} .;
    rm -fr ${SEMVER_TAR}*;
    # source ./${SEMVER_SCRIPT_NAME}
    # semverLT 0.0.5 0.0.2; echo $?;
    # semverLT 0.0.5 0.0.5; echo $?;
    # semverLT 0.0.5 0.0.8; echo $?;
    # exit 1;
  fi;
}

declare -a DEFECT_REPORT;
function appendToDefectReport() {
  DEFECT_REPORT+=("$1");
}

function freeOfDefects() {
  return ${#DEFECT_REPORT[@]};
}

function showDefectReport() {

  freeOfDefects && return 0;

  CNT=1;
  SEP="";
  for DEFECT in "${DEFECT_REPORT[@]}"
  do
    echo -e "${SEP}
    Fix #${CNT} - ${DEFECT}";
    CNT=$(expr $CNT + 1);
    SEP=" ­­­°  °  °  °  °  °  °  °  °  °  °  °  °  °   ";
  done
  echo -e "${SEP}";
  exit 1;

}

function jsonDoesHaveElement() {
  if [[ "1" -gt $(echo ${1} | jq ".${2}"  | grep -c null >/dev/null) ]]; then return 0; fi;
  return 1;
}

# echo "go";
# showDefectReport;
# appendToDefectReport "asdfasdf";
# showDefectReport;
# appendToDefectReport "wertwert";
# showDefectReport;

# echo "end";

# exit;

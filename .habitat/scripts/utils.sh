#!/usr/bin/env bash
#

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

function jsonLacksElement() {
  echo ${1} | jq ".${2}"  | grep -c null >/dev/null;
  return $?;
}

# echo "go";
# showDefectReport;
# appendToDefectReport "asdfasdf";
# showDefectReport;
# appendToDefectReport "wertwert";
# showDefectReport;

# echo "end";

# exit;

#!/usr/bin/env bash
#
getTOMLValueFromName() {

  local __TOMLVALUE=$1;
  local FILE=$2;
  local gNAME=$3;
  [[ "X${FILE}X" != "XX" && -f ${FILE} ]] || { echo "getTOMLValueFromName expected a file name." >&2; exit 1; }
  [[ "X${gNAME}X" != "XX"          ]] || { echo "getTOMLValueFromName expected a mapping key name." >&2; exit 1; }
  local TOMLRESULT=$(cat ${FILE} | grep "${gNAME} *=" | cut -d= -f2);
  eval $__TOMLVALUE="'$TOMLRESULT'";

}

getJSONValueFromName() {
  local __JSONVALUE=$1;
  local FILE=$2;
  local gNAME=$3;
  [[ "X${FILE}X" != "XX" && -f ${FILE} ]] || { echo "getJSONValueFromName expected a file name." >&2; exit 1; }
  [[ "X${gNAME}X" != "XX"          ]] || { echo "getJSONValueFromName expected a mapping key name." >&2; exit 1; }
  local JSONRESULT=$(jq -r ".${gNAME}" < ${FILE});
  eval $__JSONVALUE="'$JSONRESULT'";
}


HABITAT_PLAN_SH="plan.sh";
METEOR_PACKAGE_JSON="../package.json";

checkVersionsMatch(){

  HABITAT=${1-${HABITAT_PLAN_SH}};
  METEOR=${2-${METEOR_PACKAGE_JSON}};

  getTOMLValueFromName HABITAT_PKG_VERSION ${HABITAT} pkg_version;
  getJSONValueFromName METEOR_VERSION ${METEOR} version;

  # echo "Got ${HABITAT_PKG_VERSION}";
  # echo "Got ${METEOR_VERSION}";
  if [[ "${HABITAT_PKG_VERSION}" != "${METEOR_VERSION}" ]]; then
    echo "ERROR: Versioning Mismatch.  The version semantics of '${HABITAT}'' and '${METEOR}'' must match exactly.";
    echo "Please correct that and try again.";
    echo "${HABITAT} :: ${HABITAT_PKG_VERSION}";
    echo "${METEOR} :: ${METEOR_VERSION}";
    exit 1;
  else
    echo "Versions match.";
  fi;
}

updateTOMLNameValuePair() {
  sed -i "/${2}/c${2}=${3}" ${1};
  echo "Updated ${2}";
}

updateJSONNameValuePair() {
  jVAL="   ggggggggg";
#  sed -i "/${2}/c${jVAL}" ${1};
  sed -i "/${2}/c\ \ \"${2}\": \"${3}\"," ${1};
  echo "Updated ${2}";
}

insertTOMLNameValuePair() {
  echo "insertTOMLNameValuePair not implemented";
  echo "File '$1' must contain mapping key '$2'.";
  exit 1;
}

insertJSONNameValuePair() {
  echo "insertJSONNameValuePair not implemented";
  echo "File '$1' must contain mapping key '$2'.";
  exit 1;
}

setJSONNameValuePair() {
  sjFILE=$1;
  sjNAME=$2;
  sjVALUE=$3;
  [[ "X${sjFILE}X"  != "XX" && -f $1 ]] || { echo "setJSONNameValuePair expected a file name." >&2; exit 1; }
  [[ "X${sjNAME}X"  != "XX"          ]] || { echo "setJSONNameValuePair expected a mapping key name." >&2; exit 1; }
  [[ "X${sjVALUE}X" != "XX"          ]] || { echo "setJSONNameValuePair expected a mapped value." >&2; exit 1; }

  jEXISTS=$(jq -r ".${sjNAME}" < ${sjFILE});
  if [[ "X${jEXISTS}X" != "XX" ]]; then
    updateJSONNameValuePair ${sjFILE} ${sjNAME} ${sjVALUE};
  else
    insertJSONNameValuePair ${sjFILE} ${sjNAME};
  fi;
}

setTOMLNameValuePair() {
  stFILE=$1;
  stNAME=$2;
  stVALUE=$3;
  [[ "X${stFILE}X"  != "XX" && -f $1 ]] || { echo "setTOMLNameValuePair expected a file name." >&2; exit 1; }
  [[ "X${stNAME}X"  != "XX"          ]] || { echo "setTOMLNameValuePair expected a mapping key name." >&2; exit 1; }
  [[ "X${stVALUE}X" != "XX"          ]] || { echo "setTOMLNameValuePair expected a mapped value." >&2; exit 1; }

  tEXISTS=$(cat ${stFILE} | grep -c "${stNAME} *=");
  if [[ ${tEXISTS} -gt 0 ]]; then
    updateTOMLNameValuePair ${stFILE} ${stNAME} ${stVALUE};
  else
    insertTOMLNameValuePair ${stFILE} ${stNAME};
  fi;
}

PLAN_SH="tmpxxx.toml";
cat << TEOF > ${PLAN_SH}
pkg_origin=your0rg
pkg_name=tutorial
pkg_version=0.01.05
pkg_maintainer="Warehouseman <mhb.warehouseman@gmail.com>"
pkg_license=('MIT')
pkg_upstream_url=https://github.com/warehouseman/stocker
TEOF

PACKAGE_JSON="tmpxxx.json";
cat << JEOF > ${PACKAGE_JSON}
{
  "repository": "https://github.com/your0rg/todos",
  "version": "0.01.05",
  "license": "MIT",
  "name": "todos"
}
JEOF

getTOMLValueFromName RSLT ${PLAN_SH} pkg_version;
echo "From habitat plan :: ${RSLT}";

getJSONValueFromName RSLT ${PACKAGE_JSON} version;
echo "From Meteor plan :: ${RSLT}";

checkVersionsMatch ${PLAN_SH} ${PACKAGE_JSON};
#checkVersionsMatch ../todos/.habitat/plan.sh ../todos/package.json;

setJSONNameValuePair ${PACKAGE_JSON} version 0.1.1;
setTOMLNameValuePair ${PLAN_SH} pkg_version 0.1.1;

echo -e "...."
cat ${PLAN_SH};
echo -e "...."
cat ${PACKAGE_JSON};
echo -e "::::"
rm -f tmpxxx.*;

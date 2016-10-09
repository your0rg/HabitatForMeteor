#!/usr/bin/env bash
#
getTOMLValueFromName() {

  local __TOMLVALUE=$1;
  local FILE=$2;
  local gNAME=$3;
  
  [[ "X${FILE}X" != "XX" && -f ${FILE} ]] || { echo "getTOMLValueFromName expected a file name." >&2; exit 1; }
  [[ "X${gNAME}X" != "XX"          ]] || { echo "getTOMLValueFromName expected a mapping key name." >&2; exit 1; }
  local TOMLRESULT=$(cat ${FILE} | grep -m1 "${gNAME} *=" | cut -d= -f2);
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

# checkSourceVersionsMatch() {

#   HABITAT=${1-${HABITAT_PLAN_SH}};
#   METEOR=${2-${METEOR_PACKAGE_JSON}};

#   getTOMLValueFromName HABITAT_PKG_NAME ${HABITAT} pkg_name;
#   getTOMLValueFromName HABITAT_PKG_VERSION ${HABITAT} pkg_version;
#   getJSONValueFromName METEOR_NAME ${METEOR} name;
#   getJSONValueFromName METEOR_VERSION ${METEOR} version;

#   # echo "Got ${HABITAT_PKG_VERSION}";
#   # echo "Got ${METEOR_VERSION}";
#   OK=true;
#   if [[ "${HABITAT_PKG_NAME}" != "${METEOR_NAME}" ]]; then
#     echo "Please correct the names and try again.";
#     echo "${HABITAT} :: ${HABITAT_PKG_NAME}";
#     echo "${METEOR} :: ${METEOR_NAME}";
#     OK=false;
#   else
#     echo "           Version names match.";
#   fi;

#   if [[ "${HABITAT_PKG_VERSION}" != "${METEOR_VERSION}" ]]; then
#     echo "Please correct version numbers and try again.";
#     echo "${HABITAT} :: ${HABITAT_PKG_VERSION}";
#     echo "${METEOR} :: ${METEOR_VERSION}";
#     OK=false;
#   else
#     echo "           Version numbers match.";
#   fi;

#   if [[ "${OK}" == "false" ]]; then
#     echo "ERROR: Version Mismatch.  The version semantics of '${HABITAT}'' and '${METEOR}'' must match exactly.";
#     exit 1;
#   fi;
# }

updateTOMLNameValuePair() {
  sed -i "0,/${2}/ s|.*${2}.*|${2}=${3}|" ${1};
  echo "Updated ${2}";
}

updateJSONNameValuePair() {
  sed -i "/\"${2}\"/c\ \ \"${2}\": \"${3}\"," ${1};
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

  tEXISTS=$(cat ${stFILE} | grep -c -m1 "${stNAME} *=");
  if [[ ${tEXISTS} -gt 0 ]]; then
    updateTOMLNameValuePair ${stFILE} ${stNAME} ${stVALUE};
  else
    insertTOMLNameValuePair ${stFILE} ${stNAME};
  fi;
}

# PLAN_SH="tmpxxx.toml";
# cat << TEOF > ${PLAN_SH}
# pkg_origin=your0rg
# pkg_name=tutorial
# pkg_version=0.01.06
# pkg_maintainer="Warehouseman <mhb.warehouseman@gmail.com>"
# pkg_license=('MIT')
# pkg_upstream_url=https://github.com/warehouseman/stocker
# TEOF

# PACKAGE_JSON="tmpxxx.json";
# cat << JEOF > ${PACKAGE_JSON}
# {
#   "repository": "https://github.com/your0rg/todos",
#   "version": "0.01.05",
#   "license": "MIT",
#   "name": "todos"
# }
# JEOF

# getTOMLValueFromName RSLT ${PLAN_SH} pkg_version;
# echo "From habitat plan :: ${RSLT}";

# getJSONValueFromName RSLT ${PACKAGE_JSON} version;
# echo "From Meteor plan :: ${RSLT}";

# checkSourceVersionsMatch ${PLAN_SH} ${PACKAGE_JSON};
# #checkSourceVersionsMatch ../todos/.habitat/plan.sh ../todos/package.json;

# setJSONNameValuePair ${PACKAGE_JSON} version 0.1.1;
# setTOMLNameValuePair ${PLAN_SH} pkg_version 0.1.1;

# echo -e "...."
# cat ${PLAN_SH};
# echo -e "...."
# cat ${PACKAGE_JSON};
# echo -e "::::"
# rm -f tmpxxx.*;

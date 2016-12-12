#!/usr/bin/env bash
###################

export step0_BEGIN=0;
export step1_ONCE_ONLY_INITIALIZATIONS=$((${step0_BEGIN}+1));
export step2_PROJECT_INITIALIZATIONS=$((${step1_ONCE_ONLY_INITIALIZATIONS}+1));
export step3_BUILD_AND_UPLOAD=$((${step2_PROJECT_INITIALIZATIONS}+1));
export step4_PREPARE_FOR_SSH_RPC=$((${step3_BUILD_AND_UPLOAD}+1));
export step5_INSTALL_SERVER_SCRIPTS=$((${step4_PREPARE_FOR_SSH_RPC}+1));


# export EXECUTION_STAGE="step0_BEGIN";
export EXECUTION_STAGE="step0_BEGIN";

## Preparing file of test variables for getting started with Habitat For Meteor

TEST_VARS_FILE="${HOME}/.testVars.sh";
if [ ! -f ${TEST_VARS_FILE} ]; then
  cat << EOSVARS > ${TEST_VARS_FILE}
  # Test variables for getting started with Habitat For Meteor

  # Location of your developer tools
  export HABITA4METEOR_PARENT_DIR="\${HOME}/tools";

  # Name of your HabitatForMeteorFork
  export HABITA4METEOR_FORK_NAME="HabitatForMeteor";

  # Organization of your HabitatForMeteorFork
  export HABITA4METEOR_FORK_ORG="HabitatForMeteor";

  # Location of your projects
  export TARGET_PROJECT_PARENT_DIR="\${HOME}/projects";

  # Location of your target project
  export TARGET_PROJECT_NAME="todos";

  # Your full name
  export YOUR_NAME="You Yourself";

  # Your github organization or user name
  export YOUR_ORG="yourse1f-yourorg";

  # Your email address
  export YOUR_EMAIL="yourse1f-yourorg@gmail.com";

  # The release tag you want to attach to the above project. It must be the
  # newest release anywhere locally or on GitHub or on apps.habitat.sh
  export RELEASE_TAG="0.0.14";

  # Domain name of the server where the project will be deployed
  export TARGET_SRVR="hab4metsrv";

  # Domain name of the server where the project will be deployed
  export NON_STOP="YES";

  # The SSH secret key of the current user, for ssh-add
  export SSH_KEY_PATH="\${HOME}/.ssh";
  export SSH_CONFIG_FILE="\${SSH_KEY_PATH}/config";

  export CURRENT_USER_SSH_KEY_PRIV="\${SSH_KEY_PATH}/id_rsa";
  export CURRENT_USER_SSH_KEY_PUBL="\${SSH_KEY_PATH}/id_rsa.pub";

  # Habitat for Meteor secrets directory
  export HABITAT_FOR_METEOR_SECRETS_DIR="\${SSH_KEY_PATH}/hab_vault";
  export SOURCE_SECRETS_FILE="\${HABITAT_FOR_METEOR_SECRETS_DIR}/secrets.sh";
  export METEOR_SETTINGS_FILE="\${HABITAT_FOR_METEOR_SECRETS_DIR}/settings.json";

  # Habitat for Meteor user secrets directory
  export HABITAT_FOR_METEOR_USER_SECRETS_DIR=\${HABITAT_FOR_METEOR_SECRETS_DIR}/habitat_user;

  # Parameters for creating a SSH key pair for the 'hab' user.
  export HABITAT_USER_SSH_KEY_COMMENT="DevopsTeamLeader";
  export HABITAT_USER_SSH_PASS_PHRASE="memorablegobbledygook";
  export HABITAT_USER_SSH_KEY_PATH="\${HABITAT_FOR_METEOR_SECRETS_DIR}/habitat_user";
  export HABITAT_USER_SSH_KEY_PRIV="\${HABITAT_USER_SSH_KEY_PATH}/id_rsa";
  export HABITAT_USER_SSH_KEY_PUBL="\${HABITAT_USER_SSH_KEY_PATH}/id_rsa.pub";

  # SSL certificate parameters of the server where the project will be deployed
  export VHOST_DOMAIN="moon.planet.sun";
  export VHOST_CERT_PATH="\${HABITAT_FOR_METEOR_SECRETS_DIR}/\${VHOST_DOMAIN}";
  export VHOST_CERT_PASSPHRASE="memorablegibberish";

EOSVARS
fi;


## Sourcing test variables file ....
source ${TEST_VARS_FILE};
source habitat/scripts/target/secrets.sh.example;

# echo "SETUP_USER_PWD = ${SETUP_USER_PWD}";
#
export THE_PROJECT_ROOT=${TARGET_PROJECT_PARENT_DIR}/${TARGET_PROJECT_NAME};
export PROJECT_UUID=${YOUR_ORG}/${TARGET_PROJECT_NAME};
export PROJECT_HABITAT_DIR=${THE_PROJECT_ROOT}/.habitat;
export PROJECT_RELEASE_NOTES_DIR=${PROJECT_HABITAT_DIR}/release_notes;
echo -e "

Test variables are ready for use:
  * edit with 'nano ${TEST_VARS_FILE};'
  * then re-source with 'source ${TEST_VARS_FILE};'
";

function startSSHAgent() {

  echo -e "${PRTY} Starting 'ssh-agent' ...";
  if [ -z "${SSH_AUTH_SOCK}" ]; then
    eval $(ssh-agent -s);
    echo -e "${PRTY} Started 'ssh-agent' ...";
  fi;

};

function PrepareDependencies() {

    #
    # Get dependencies
    sudo apt -y install expect
    sudo apt -y install curl
    sudo apt -y install git
    #
    # Prepare 'git'
    git config --global user.email "${YOUR_EMAIL}";
    git config --global user.name "${YOUR_NAME}";
    git config --global push.default simple;
    #

};

function RefreshHabitatOriginKeys() {

  if [ ! -d ${HABITAT_FOR_METEOR_USER_SECRETS_DIR} ]; then
    echo -e "Cannot find Habitat Origin Keys in '${HABITAT_FOR_METEOR_USER_SECRETS_DIR}'!";
    mkdir -p ${HABITAT_FOR_METEOR_USER_SECRETS_DIR};
    exit 1;
  fi;

  pushd ${HABITAT_FOR_METEOR_USER_SECRETS_DIR} >/dev/null;

    if [ ! -f ${YOUR_ORG}-*.sig.key ]; then
      echo -e "Cannot find Habitat Origin Keys!";
      exit 1;
    fi;

    cat ${YOUR_ORG}-*.pub | sudo hab origin key import; echo ;
    cat ${YOUR_ORG}-*.sig.key | sudo hab origin key import; echo ;

  popd >/dev/null;

};

function GetHabitatForMeteor() {

    mkdir -p ${HABITA4METEOR_PARENT_DIR};
    pushd ${HABITA4METEOR_PARENT_DIR} >/dev/null;
    git clone https://github.com/${HABITA4METEOR_FORK_ORG}/${HABITA4METEOR_FORK_NAME};
    popd >/dev/null;

};


function GetMeteor() {

    curl https://install.meteor.com/ | sh;

};



function GetMeteorProject() {

    # Prepare directory
    mkdir -p ${TARGET_PROJECT_PARENT_DIR};
    pushd ${TARGET_PROJECT_PARENT_DIR} >/dev/null;
    #
    # Install example project
    rm -fr ${TARGET_PROJECT_NAME};
    git clone git@github.com:${PROJECT_UUID}.git;
    popd >/dev/null;

};


function FixGitPrivileges() {

  pushd .git >/dev/null;

  local OLD_URL_PATTERN="url = git";
  local NEW_URL_LINE="  url = git@${YOUR_ORG}.github.com:${YOUR_ORG}/${TARGET_PROJECT_NAME}.git";
  sed -i "s|.*url = git.*|${NEW_URL_LINE}|" ./config;

  popd >/dev/null;


};


function TrialBuildMeteorProject() {

    pushd ${THE_PROJECT_ROOT} >/dev/null;
    # Install all NodeJS packages dependencies
    meteor npm install
    #
    # Also install the one that change since the last release of 'meteor/todos'
    meteor npm install --save bcrypt;
    #
    # Start it up, look for any other issues and test on URL :: http://localhost:3000/.
    meteor;
    popd >/dev/null;

};


function PerformanceFix() {

    # Optimize file change responsivity
    echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p;

};


function PrepareMeteorProject() {
    
    pushd ${HABITA4METEOR_PARENT_DIR}/${HABITA4METEOR_FORK_NAME} >/dev/null;
    ./Update_or_Install_H4M_into_Meteor_App.sh ${THE_PROJECT_ROOT};
    popd >/dev/null;

};


function PreparePlanFile() {
    
    pushd ${THE_PROJECT_ROOT}/.habitat >/dev/null;
    cp plan.sh.example plan.sh;
    sed -i "/^pkg_origin/c\pkg_origin=${YOUR_ORG}" plan.sh;
    sed -i "/^pkg_name/c\pkg_name=${TARGET_PROJECT_NAME}" plan.sh;
    sed -i "/^pkg_version/c\pkg_version=${RELEASE_TAG}" plan.sh;
    sed -i "/^pkg_maintainer/c\pkg_maintainer=\"${YOUR_NAME} <${YOUR_EMAIL}>\"" plan.sh;
    sed -i "/^pkg_upstream_url/c\pkg_upstream_url=https://github.com/${PROJECT_UUID};" plan.sh;
    popd >/dev/null;
    

};


function InitializeMeteorProject() {

    pushd ${THE_PROJECT_ROOT} >/dev/null;
    ./.habitat/scripts/Update_or_Install_Dependencies.sh;
    popd >/dev/null;

};


function PatchPkgJson() {

  local REPLACEMENT="";
  REPLACEMENT+="  \"name\": \"${TARGET_PROJECT_NAME}\",";
  REPLACEMENT+="\n  \"version\": \"0.1.4\",";
  REPLACEMENT+="\n  \"license\": \"MIT\",";
  REPLACEMENT+="\n  \"repository\": \"https://github.com/${PROJECT_UUID}\",";
  REPLACEMENT+="\n  \"scripts\": {";

  sed -i "s|.*scripts.*|${REPLACEMENT}|" ./package.json;


};


function FixPkgJson() {

  # Be sure we even have package.json
  if [[ ! -f package.json ]]; then
    echo "Project has no file : 'package.json'";
    exit 1;
  fi;

  # Adding required fields if missing
  grep -c repository ./package.json >/dev/null || PatchPkgJson;

  local REPLACEMENT="  \"version\": \"${RELEASE_TAG}\",";
  sed -i "s|.*\"version\":.*|${REPLACEMENT}|" ./package.json;


};


function FixPlanSh() {

  local PLAN="./.habitat/plan.sh";
  # Be sure we even have plan.sh
  if [[ ! -f package.json ]]; then
    echo "Project has no file : 'package.json'";
    exit 1;
  fi;

  local REPLACEMENT="pkg_version=${RELEASE_TAG}";
  sed -i "s|^version.*|${REPLACEMENT}|" ${PLAN};

};


function FixReleaseNote() {

  pushd ${PROJECT_RELEASE_NOTES_DIR} >/dev/null;
  if [ ! -f ./${RELEASE_TAG}_note.txt ]; then
    cp ./0.0.0_note.txt.example ./${RELEASE_TAG}_note.txt;
    sed -i "s|0.0.0|${RELEASE_TAG}|g" ./${RELEASE_TAG}_note.txt;
  fi;
  popd >/dev/null;
  git add ${PROJECT_RELEASE_NOTES_DIR}/${RELEASE_TAG}_note.txt;

};


function CommitAndPush() {

  echo -e "    - Commit ";
  git status | \
    grep -c "nothing to commit" >/dev/null || \
    git commit -a -m "Release version v${RELEASE_TAG}";

  echo -e "    - Push ";
  git push;

  echo -e "   Clean";

};


function BuildAndUploadMeteorProject() {

  pushd ${THE_PROJECT_ROOT} >/dev/null;

    echo "${PRTY} Fixing package.json version ";
    FixPkgJson;

    echo "${PRTY} Fixing plan.sh version ";
    FixPlanSh;

    echo "${PRTY} Fixing release notes ";
    FixReleaseNote;

    echo "${PRTY} Fixing git privileges ";
    FixGitPrivileges;

    echo "${PRTY} Refreshing Habitat Origin keys ";
    RefreshHabitatOriginKeys;

    echo "${PRTY} Committing and pushing project ";
    CommitAndPush;

    echo "${PRTY} Building and uploading ";
    ./.habitat/BuildAndUpload.sh ${RELEASE_TAG};

  popd >/dev/null;

};


function VerifyHostsFile() {
  local HSTS="/etc/hosts";
  echo -e "Check '${HSTS}' file mappings ";
  FAIL=0;
  cat ${HSTS} | grep -c "${TARGET_SRVR}" >/dev/null || FAIL=1;
  cat ${HSTS} | grep -c "${VHOST_DOMAIN}" >/dev/null || FAIL=1;

  ping -c 1 "${TARGET_SRVR}" >/dev/null || FAIL=1;
  ping -c 1 "${VHOST_DOMAIN}" >/dev/null  || FAIL=1;
  if [[ "${FAIL}" = "1" ]]; then
    echo "You need to correct your file: ${HSTS}.  Quitting ....";
    exit 1;
  fi;
};


function VerifyHostsAccess() {

  #  Starting SSH Agent if not already started
  startSSHAgent;

  # Add user key to agent;
  ssh-add ${CURRENT_USER_SSH_KEY_PRIV};

  #
  echo -e "Attempting connection to server.";
  local RES=$(ssh -tq -oStrictHostKeyChecking=no -oBatchMode=yes -l $(whoami) ${TARGET_SRVR} whoami);
  echo -e "Server user is :
  ${RES}";

};


function GenerateHabUserSSHKeysIfNotExist() {

    mkdir -p ${HABITAT_USER_SSH_KEY_PATH};
    if [[ ! -f ${HABITAT_USER_SSH_KEY_PRIV} ]]; then
    #  rm -f ${HABITAT_USER_SSH_KEY_PATH}/id_rsa*;
      echo -e "Generating SSH key pair for 'hab' user.";
      ssh-keygen \
        -t rsa \
        -C "${HABITAT_USER_SSH_KEY_COMMENT}" \
        -f "${HABITAT_USER_SSH_KEY_PRIV}" \
        -P "${HABITAT_USER_SSH_PASS_PHRASE}" \
        && cat ${HABITAT_USER_SSH_KEY_PUBL};
    else
      echo -e "SSH key pair for 'hab' user seems to exist already.";
    fi;
    chmod go-rwx ${HABITAT_USER_SSH_KEY_PRIV};
    chmod go-wx ${HABITAT_USER_SSH_KEY_PUBL};
    chmod go-w ${HABITAT_USER_SSH_KEY_PATH};

};


function ConfigureSSHConfigIfNotDone() {

    echo -e "Preparing SSH config file.";

    CURRENT_USER=$(whoami);
    #
    export PTRN="# ${CURRENT_USER} account on ${TARGET_SRVR}";
    export PTRNB="${PTRN} «begins»";
    export PTRNE="${PTRN} «ends»";
    #

    mkdir -p ${SSH_KEY_PATH};
    touch ${SSH_CONFIG_FILE};
    if [[ ! -f ${SSH_CONFIG_FILE}_BK ]]; then
      cp ${SSH_CONFIG_FILE} ${SSH_CONFIG_FILE}_BK;
      chmod ugo-w ${SSH_CONFIG_FILE}_BK;
    fi;
    sed -i "/${PTRNB}/,/${PTRNE}/d" ${SSH_CONFIG_FILE};
    #
    echo -e "
    ${PTRNB}
    Host ${TARGET_SRVR}
        HostName ${TARGET_SRVR}
        User ${CURRENT_USER}
        PreferredAuthentications publickey
        IdentityFile ${CURRENT_USER_SSH_KEY_PRIV}
    ${PTRNE}
    " >> ${SSH_CONFIG_FILE}

    HABITAT_USER="hab";
    HABITAT_USER_SSH_KEY_PRIV="${SSH_KEY_PATH}/hab_vault/habitat_user/id_rsa";
    #
    export PTRN="# ${HABITAT_USER} account on ${TARGET_SRVR}";
    export PTRNB="${PTRN} «begins»";
    export PTRNE="${PTRN} «ends»";
    #
    sed -i "/${PTRNB}/,/${PTRNE}/d" ${SSH_CONFIG_FILE};
    #
    echo -e "
    ${PTRNB}
    Host ${TARGET_SRVR}
        HostName ${TARGET_SRVR}
        User ${HABITAT_USER}
        PreferredAuthentications publickey
        IdentityFile ${HABITAT_USER_SSH_KEY_PRIV}
    ${PTRNE}
    " >> ${SSH_CONFIG_FILE}
    #
    sed -i "/^$/N;/^\n$/D" ${SSH_CONFIG_FILE}
    echo -e "Done preparing SSH config file.";

};


function GenerateSiteCertificateIfNotExist() {

    echo -e "Generating site certificates if none exist already.";

    SUBJ="/C=ZZ/ST=Planet/L=Moon/O=YouGuyz/CN=${VHOST_DOMAIN}";
    #
    mkdir -p ${VHOST_CERT_PATH};
    if [[ ! -f ${VHOST_CERT_PATH}/server.pp ]]; then
      # rm -f ${VHOST_CERT_PATH}/server.*;
      echo ${VHOST_CERT_PASSPHRASE} > ${VHOST_CERT_PATH}/server.pp;
      openssl req \
      -new \
      -newkey rsa:4096 \
      -days 1825 \
      -x509 \
      -subj "${SUBJ}" \
      -passout file:${VHOST_CERT_PATH}/server.pp \
      -keyout ${VHOST_CERT_PATH}/server.key \
      -out ${VHOST_CERT_PATH}/server.crt
      echo -e "Done generating site certificates.";
    else
      echo -e "Found existing site certificates.";
    fi;

};


function PrepareSecretsFile() {

  echo -e "Preparing secrets file, '${SOURCE_SECRETS_FILE}', if not done.";
  if [ -f ${SOURCE_SECRETS_FILE} ]; then
    echo -e "Secrets file found.";
    source ${SOURCE_SECRETS_FILE};
    if [[ "${NON_STOP}" = "YES" ]]; then return 0; fi;
  fi;

  echo -e "Verifying secrets file.";
  cp habitat/scripts/target/secrets.sh.example ${SOURCE_SECRETS_FILE};

  local CHOICE="n";
  local SETUP_USER_UID="";
  local SETUP_USER_PWD="";
  while [[ ! "X${CHOICE}X" == "XyX" ]]
  do
    SETUP_USER_UID=$(cat ${SOURCE_SECRETS_FILE} | grep SETUP_USER_UID | cut -d '"' -f 2);
    SETUP_USER_PWD=$(cat ${SOURCE_SECRETS_FILE} | grep SETUP_USER_PWD | cut -d '"' -f 2);

    echo -e "   -----------------------------------------

    According to the file '${SOURCE_SECRETS_FILE}'
    your user ID and password on the remote server are : '${SETUP_USER_UID}' and '${SETUP_USER_PWD}'.
    ".

    read -ep "Is this correct? (y/n/q) ::  " -n 1 -r USER_ANSWER
    CHOICE=$(echo ${USER_ANSWER:0:1} | tr '[:upper:]' '[:lower:]')
    if [[ "X${CHOICE}X" == "XqX" ]]; then
      echo "Skipping this operation."; exit 1;
    elif [[ ! "X${CHOICE}X" == "XyX" ]]; then

      read -p "Your server side user ID : " -r SETUP_USER_UID
      if [ ! "X${SETUP_USER_UID}X" == "XX" ]; then
        sed -i "s|.*SETUP_USER_UID.*|export SETUP_USER_UID=\"${SETUP_USER_UID}\";|" ${SOURCE_SECRETS_FILE}
      fi;

      read -p "Your server side password : " -r SETUP_USER_PWD
      if [ ! "X${SETUP_USER_PWD}X" == "XX" ]; then
        sed -i "s|.*SETUP_USER_PWD.*|export SETUP_USER_PWD=\"${SETUP_USER_PWD}\";|" ${SOURCE_SECRETS_FILE}
      fi;

    fi;
  done;
  source ${SOURCE_SECRETS_FILE};
  echo -e "The most changeable secrets have been verified. Review the file directly for others.";

};


function VerifySSHasHabUser() {
    echo "VerifySSHasHabUser";

    startSSHAgent;
    expect << EOF
      spawn ssh-add ${HABITAT_USER_SSH_KEY_PRIV}
      expect "Enter passphrase"
      send "${HABITAT_USER_SSH_PASS_PHRASE}\r"
      expect eof
EOF
    ssh -t -oStrictHostKeyChecking=no -oBatchMode=yes -l ${HABITAT_USER} ${TARGET_SRVR} whoami;

};

function PrepareMeteorSettingsFile() {
  echo -e "PrepareMeteorSettingsFile";
  if [ ! -f ${THE_PROJECT_ROOT}/settings.json ]; then
    echo '{ "public": { "DUMMY": "dummy" } }' > ${THE_PROJECT_ROOT}/settings.json;
  fi;

  cp ${THE_PROJECT_ROOT}/settings.json ${HABITAT_FOR_METEOR_SECRETS_DIR};
};

function IncrementReleaseTag() {

  echo -e "Increment release number...";

  # THE_TAG=$(grep ${RELEASE_TAG} ${TEST_VARS_FILE}| cut -d '.' -f 3);
  THE_TAG=$( grep RELEASE_TAG ${TEST_VARS_FILE}  | cut -d '"' -f 2 );
  A=(${THE_TAG//./ })
  (( A[2]++ ));
  NEW_TAG="${A[0]}.${A[1]}.${A[2]}";
  echo ${NEW_TAG};

  sed -i "s|.*RELEASE_TAG.*|export RELEASE_TAG=\"${A[0]}.${A[1]}.${A[2]}\";|"  ${TEST_VARS_FILE};

};

# function V() {
#   echo -e ""
# };

set -e;

echo "Some tasks need to be run as root...";
sudo ls -l &>/dev/null;

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
PRTY="XRSZ :: ";

echo -e "${PRTY} Processing from execution stage '${EXECUTION_STAGE}' ...

";

PrepareSecretsFile;

if [[ "step1_ONCE_ONLY_INITIALIZATIONS" -ge "${EXECUTION_STAGE}" ]]; then


  echo "${PRTY} Installing Git";
  PrepareDependencies;

  
  echo "${PRTY} Installing Meteor";
  GetMeteor;

  
  echo "${PRTY} Installing sample project";
  GetMeteorProject;


  echo "${PRTY} Building sample project";
  TrialBuildMeteorProject;


  echo "${PRTY} Fixing performance";
  PerformanceFix;

  echo "${PRTY} Preparing Habitat Origin Keys";
  RefreshHabitatOriginKeys;


fi;


if [[ "step2_PROJECT_INITIALIZATIONS" -ge "${EXECUTION_STAGE}" ]]; then

  echo "${PRTY} Pushing Habitat script subset to the target project directory ...";
  PrepareMeteorProject;

  echo "${PRTY} Putting shell variables into Habitat plan file ...";
  PreparePlanFile;

  echo "${PRTY} Initialize example project ...";
  InitializeMeteorProject;

fi;


if [[ "step3_BUILD_AND_UPLOAD" -ge "${EXECUTION_STAGE}" ]]; then

  echo "${PRTY} Build project and upload ...";
  BuildAndUploadMeteorProject;

fi;


if [[ "step4_PREPARE_FOR_SSH_RPC" -ge "${EXECUTION_STAGE}" ]]; then

  echo "${PRTY} Prepare for SCP & SSH RPC calls ...";
  VerifyHostsFile;
  VerifyHostsAccess;
  GenerateHabUserSSHKeysIfNotExist;
  ConfigureSSHConfigIfNotDone;
  GenerateSiteCertificateIfNotExist;
  PrepareSecretsFile;
  PrepareMeteorSettingsFile;

fi;

if [[ "step5_INSTALL_SERVER_SCRIPTS" -ge "${EXECUTION_STAGE}" ]]; then

  IncrementReleaseTag;
  echo "${PRTY} Pushing Installer Scripts To Target ...";
  ./habitat/scripts/PushInstallerScriptsToTarget.sh ${TARGET_SRVR} ${SETUP_USER_UID} ${METEOR_SETTINGS_FILE} ${SOURCE_SECRETS_FILE};
  VerifySSHasHabUser;
  ./habitat/scripts/PushSiteCertificateToTarget.sh \
               ${TARGET_SRVR} \
               ${SOURCE_SECRETS_FILE} \
               ${HABITAT_FOR_METEOR_SECRETS_DIR} \
               ${VHOST_DOMAIN};

fi;








##############################  ?????????????????   source ./habitat/scripts/utils.sh;
echo -e "


Rinse and repeat...."
exit;

# echo "${PRTY} Matching plan.sh settings to release level...";
# HABITAT_PLAN_FILE="habitat/plan.sh";
# HABITAT_FIELD="pkg_version";
# sed -i "0,/${HABITAT_FIELD}/ s|.*${HABITAT_FIELD}.*|${HABITAT_FIELD}=${RELEASE_TAG}|" ${HABITAT_PLAN_FILE};
# echo -e "\nPlan Metadata\n";
# head -n 5 ${HABITAT_PLAN_FILE};
# echo -e "\n";


# echo "${PRTY} Stepping into target directory...";
# cd ${TARGET_PROJECT};
# declare TARGET_PROJECT_PATH=$(pwd);
# declare HABITAT_WORK=${TARGET_PROJECT_PATH}/.habitat;
# mkdir -p ${HABITAT_WORK};


# if [ ! -d ${TARGET_PROJECT_PATH}/.meteor ]; then
#   echo "Quitting!  Found no directory ${TARGET_PROJECT_PATH}/.meteor.";
#   exit;
# fi;

# if [ -d ${TARGET_PROJECT_PATH}/.habitat ]; then

#     echo "${PRTY} Purging previous HabitatForMeteor files from target...";
#     sudo rm -fr ${HABITAT_WORK}/scripts;
#     sudo rm -fr ${HABITAT_WORK}/BuildAndUpload.sh;
#     sudo rm -fr ${HABITAT_WORK}/plan.sh;

# fi;

# echo "${PRTY} Copying HabitatForMeteor files to target...";
# cp -r ${SCRIPTPATH}/habitat/* ${HABITAT_WORK};


# echo -e "${PRTY} Preparing for using Habitat...\n\n";
# ${HABITAT_WORK}/scripts/PrepareForHabitatBuild.sh;

# # set +e;
# # git checkout -- package.json &>/dev/null;
# # git checkout -- .habitat/plan.sh &>/dev/null;
# # git status;
# # git tag -d ${RELEASE_TAG} &>/dev/null;

# set -e;
# SETUP_USER="you";
# SETUP_USER_PWD="okok";
# HABITAT_USER_PWD_FILE_PATH="${HOME}/.ssh/HabUserPwd";
# HABITAT_USER_SSH_KEY_FILE="${HOME}/.ssh/id_rsa.pub";

# echo -e "${PRTY} Pushing deployment scripts to target,
#          server '${TARGET_SRVR}' ready for RPC to upgrade to
#          project version ${RELEASE_TAG}...";
# ${HABITAT_WORK}/scripts/PushInstallerScriptsToTarget.sh \
#                    ${TARGET_SRVR} \
#                    ${SETUP_USER} \
#                    ${SETUP_USER_PWD} \
#                    ${HABITAT_USER_PWD_FILE_PATH} \
#                    ${HABITAT_USER_SSH_KEY_FILE} \
#                    ${RELEASE_TAG};

# # echo -e "${PRTY} Pushing deployment scripts to target,
# #          server '' ready for RPC to upgrade to
# #          project version ${RELEASE_TAG}...";
# # ${HABITAT_WORK}/scripts/PushInstallerScriptsToTarget.sh ${RELEASE_TAG};

# echo -e "${PRTY} Building application with Meteor,
#          packaging with Habitat and
#          uploading to Habitat depot...";
# ${HABITAT_WORK}/BuildAndUpload.sh ${RELEASE_TAG};

# # --------------------------------------------------------------------------
# hidden() {
#   "name": "todos",
#   "version": "0.0.1",
#   "license": "MIT",
#   "repository": "https://github.com/FleetingClouds/todos",

# }

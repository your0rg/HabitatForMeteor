#!/bin/bash
#
downloadHabToPathDir() {

  INST_HOST="https://api.bintray.com";
  INST_STABLE="content/habitat/stable";
  INST_PATH="${INST_HOST}/${INST_STABLE}";

  INST_MAC="darwin";
  INST_LNX="linux";

  INST_SFX_MAC="zip";
  INST_SFX_LNX="tar.gz";
  INST_SFX="${INST_SFX_LNX}";

  INST_FILE="hab-%24latest";

  INST_PARM="bt_package";

  ARCH="x86_64";

  OS="darwin";
  OS="linux";
  OS="${1:-linux}";

  DEST_DIR="${2:-/usr/local/bin}";

  if [ "${OS}" = "${INST_MAC}" ]; then
    INST_SFX="${INST_SFX_MAC}";
    # echo -e "APPLE https://api.bintray.com/content/habitat/stable/darwin/x86_64/hab-%24latest-x86_64-darwin.zip   ?bt_package=hab-x86_64-darwin";
  else
    INST_SFX="${INST_SFX_LNX}";
    # echo -e "LINUX https://api.bintray.com/content/habitat/stable/linux/x86_64/hab-%24latest-x86_64-linux.tar.gz?bt_package=hab-x86_64-linux";
  fi;

  INST_BUNDLE="${INST_FILE}-${ARCH}-${OS}.${INST_SFX}";
  INST_TRGT="hab-${ARCH}-${OS}.${INST_SFX}";
  INST_URL="${INST_PATH}/${OS}/${ARCH}/${INST_BUNDLE}?${INST_PARM}=hab-${ARCH}-${OS}";

  PATTERN="hab-*-${ARCH}-${OS}";

  echo -e "${PRTY} Getting ${INST_URL} ...";
  set +e; wget --quiet --no-clobber -O ${INST_TRGT} ${INST_URL} > /dev/null;  set -e;
  rm -fr ${PATTERN};
  echo -e "${PRTY} Unpacking ${INST_TRGT} ...";
  tar zxf ${INST_TRGT};

  INST_DIR=$( ls -d ${PATTERN} );
  # echo -e "Install from ${INST_DIR}/hab to ${DEST_DIR}";

  echo -e "${PRTY} Relocating '${INST_DIR}/hab' to '${DEST_DIR}' ...";
  sudo -A mv ${INST_DIR}/hab ${DEST_DIR};
  DEST_FILE=${DEST_DIR}/hab;
  sudo -A chmod 755 ${DEST_FILE};
  sudo -A chown root:root ${DEST_FILE};

  rm -fr ${PATTERN};

}

function usage() {
  echo -e "USAGE : ./PrepareChefHabitat.sh HABITAT_USER_NAME HABITAT_USER_PASSWORD";
}

PASSWORD_MINIMUM_LENGTH=4;
function errorUnsuitablePassword() {
  echo -e "\n\n    *** '${1}' is not a viable password***
                   -- Minimum size is ${PASSWORD_MINIMUM_LENGTH} chars --"  | tee -a ${LOG};
  usage;
}

set -e;

PRTY=" TGTSRV  --> ";

SCRIPT=$(readlink -f "$0");
SCRIPTPATH=$(dirname "$SCRIPT");
export LOG=/tmp/HabitatPreparation.log;
echo -e "Habitat Preparation Log :: $(date)
=======================================================" > ${LOG};
echo -e "\n${PRTY} Changing working location to ${SCRIPTPATH}."  | tee -a ${LOG};
pushd ${SCRIPTPATH};

HAB_USER='hab';
# HABITAT_USER_PWD=$(cat ./HabUserPwd.txt);

HAB_DIR=/home/${HAB_USER};
HAB_SSH_DIR=${HAB_DIR}/.ssh;
HAB_SSH_AXS=${HAB_SSH_DIR}/authorized_keys;
HAB_SSH_KEY_NAME=authorized_key;

source secrets.sh;
# echo -e "${PRTY} MONGODB_PWD=${MONGODB_PWD}";
# echo -e "${PRTY} SETUP_USER_PWD=${SETUP_USER_PWD}";
# echo -e "${PRTY} HABITAT_USER_PWD=${HABITAT_USER_PWD}";
# echo -e "${PRTY} HABITAT_USER_SSH_KEY_FILE=${HABITAT_USER_SSH_KEY_FILE}";


BUNDLE_DIRECTORY_NAME="HabitatPkgInstallerScripts";
BUNDLE_NAME="${BUNDLE_DIRECTORY_NAME}.tar.gz";

# GOOD_PWD=$(echo -e "${HABITAT_USER_PWD}" | grep -cE "^.{8,}$"  2>/dev/null);
# if [ "${GOOD_PWD}" -lt "1" ]; then
#   echo -e "ERROR : Password must be 8 chars minimum."  | tee -a ${LOG};
#   usage;
#   exit 1;
# fi;
# ----------------
echo -e "${PRTY} Validating user's sudo password... ";
[[ 0 -lt $(echo ${HABITAT_USER_PWD} | grep -cE "^.{${PASSWORD_MINIMUM_LENGTH},}$") ]] ||  errorUnsuitablePassword ${HABITAT_USER_PWD};

HABITAT_USER_SSH_KEY_NAME="authorized_key";
if [ ! -f "${HABITAT_USER_SSH_KEY_NAME}" ]; then
  echo -e "ERROR : A ssh certificate is required.  Found no file : '$(pwd)/${HABITAT_USER_SSH_KEY_NAME}'"  | tee -a ${LOG};
  usage;
  exit 1;
fi;


export SUDO_ASKPASS=${HOME}/.ssh/.supwd.sh;

echo -e "${PRTY} Testing SUDO_ASKPASS and sudo password for '$(whoami)'.  "  | tee -a ${LOG};
if [[ $(sudo -A touch "/root/$(date)"  &>/dev/null; echo $?;) -gt 0 ]]; then
  echo -e "ERROR : SUDO_ASKPASS doesn't work.  Is the password correct for : '$(whoami)'"  | tee -a ${LOG};
fi;

echo -e "${PRTY} Ensuring mongo-shell is installed.  "  | tee -a ${LOG};

sudo -A apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927;
# sudo -A apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927 &>/dev/null;
echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.2 multiverse" \
         | sudo -A tee /etc/apt/sources.list.d/mongodb-org-3.2.list >>  ${LOG};
sudo -A DEBIAN_FRONTEND=noninteractive apt-get update >>  ${LOG};
sudo -A DEBIAN_FRONTEND=noninteractive apt-get install -y mongodb-org-shell=3.2.10 >>  ${LOG};

echo -e "${PRTY} Purging any existing user '${HAB_USER}' . . .  " | tee -a ${LOG};
set +e; sudo -A deluser --quiet --remove-home ${HAB_USER}  >>  ${LOG}; set -e;
sudo -A rm -fr "/etc/sudoers.d/${HAB_USER}" >>  ${LOG};

echo -e "${PRTY} Creating user '${HAB_USER}' . . .  " | tee -a ${LOG};
sudo -A adduser --disabled-password --gecos "" ${HAB_USER} >>  ${LOG};

echo -e "${PRTY} Ensuring command 'mkpassword' exists . . .  " | tee -a ${LOG};
sudo -A DEBIAN_FRONTEND=noninteractive apt-get install -y whois  >>  ${LOG};

echo -e "${PRTY} Setting password for user '${HAB_USER}' . . .  " | tee -a ${LOG};
sudo -A usermod --password $( mkpasswd ${HABITAT_USER_PWD} ) ${HAB_USER};

echo -e "${PRTY} Adding user '${HAB_USER}' to sudoers . . .  " | tee -a ${LOG};
sudo -A usermod -aG sudo ${HAB_USER};

echo -e "${PRTY} Adding caller's credentials to authorized SSH keys of '${HAB_USER}' . . .  " | tee -a ${LOG};
sudo -A mkdir -p ${HAB_SSH_DIR};
# sudo -A touch ${HAB_SSH_DIR}/${HAB_SSH_AXS};
sudo -A cp ${HABITAT_USER_SSH_KEY_NAME} ${HAB_SSH_AXS};
sudo -A chown -R ${HAB_USER}:${HAB_USER} ${HAB_SSH_DIR};
# cat ${HAB_SSH_AXS};

echo -e "${PRTY} Making SUDO_ASK_PASS for '${HAB_USER}' user  ...";
sudo -A -sHu ${HAB_USER} bash -c "source askPassMaker.sh; makeAskPassService ${HAB_USER} ${HABITAT_USER_PWD};";

popd;
echo -e "${PRTY} Moving bundle directory, '${BUNDLE_DIRECTORY_NAME}' to '/home/${HAB_USER}'";
rm -fr ${BUNDLE_NAME};
sudo -A mv ${BUNDLE_DIRECTORY_NAME} /home/${HAB_USER};
sudo -A chown -R ${HAB_USER}:${HAB_USER} /home/${HAB_USER}/${BUNDLE_DIRECTORY_NAME};

# KY_SUDO_ASK_PASS="SUDO_ASKPASS";
# VL_SUDO_ASK_PASS=".supwd.sh";
# EXPORT_SUDO_ASK_PASS="export ${KY_SUDO_ASK_PASS}=\"\${HOME}/.ssh/${VL_SUDO_ASK_PASS}\"";
# export BASH_LOGIN="${HOME}/.bash_login";
# touch ${BASH_LOGIN};
# # cat ${BASH_LOGIN};
# set +e; CNTSAP=$(cat ${BASH_LOGIN} | grep ${KY_SUDO_ASK_PASS} | grep -c ${VL_SUDO_ASK_PASS}); set -e;
# if [[ "${CNTSAP}" -lt "1" ]]; then
#   echo ${EXPORT_SUDO_ASK_PASS} > ${BASH_LOGIN};
# # else
# #   echo -e "Already is : $(cat ${BASH_LOGIN})";
# fi;

echo -e "${PRTY} Obtaining 'Habitat'.";

DEST_DIR="/usr/local/bin";
downloadHabToPathDir linux ${DEST_DIR};
echo -e "${PRTY} Installed 'hab' to '${DEST_DIR}'.\n\n";

echo -e "
                    Quitting target RPC... :: $(date)";
exit;

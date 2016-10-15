#!/bin/bash
#
PRETTY="TGTSRV ==> ";

SCRIPT=$(readlink -f "$0");
SCRIPTPATH=$(dirname "$SCRIPT");
export LOG=/tmp/HabitatPreparation.log;
echo -e "Habitat Preparation Log :: $(date)
=======================================================" > ${LOG};
echo -e "\n${PRETTY} Changing working location to ${SCRIPTPATH}."  | tee -a ${LOG};
cd ${SCRIPTPATH};

HAB_USER='hab';
HAB_PASSWD=$(cat ./HabUserPwd.txt);

HAB_DIR=/home/${HAB_USER};
HAB_SSH_DIR=${HAB_DIR}/.ssh;
HAB_SSH_AXS=${HAB_SSH_DIR}/authorized_keys;
HAB_SSH_KEY_NAME=authorized_key;

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

  # echo -e "DWNLD ${INST_URL}";
  wget --quiet --no-clobber -O ${INST_TRGT} ${INST_URL} > /dev/null;
  rm -fr ${PATTERN};
  tar zxf ${INST_TRGT};

  INST_DIR=$( ls -d ${PATTERN} );
  # echo -e "Install from ${INST_DIR}/hab to ${DEST_DIR}";

  sudo -A mv ${INST_DIR}/hab ${DEST_DIR};
  DEST_FILE=${DEST_DIR}/hab;
  sudo -A chmod 755 ${DEST_FILE};
  sudo -A chown root:root ${DEST_FILE};

  rm -fr ${PATTERN};

}

function usage() {
  echo -e "USAGE : ./PrepareChefHabitat.sh HABITAT_USER_NAME HABITAT_USER_PASSWORD";
}

GOOD_PWD=$(echo -e "${HAB_PASSWD}" | grep -cE "^.{8,}$"  2>/dev/null);
if [ "${GOOD_PWD}" -lt "1" ]; then
  echo -e "ERROR : Password must be 8 chars minimum."  | tee -a ${LOG};
  usage;
  exit 1;
fi;

HABITAT_USER_SSH_KEY_NAME="authorized_key";
if [ ! -f "${HABITAT_USER_SSH_KEY_NAME}" ]; then
  echo -e "ERROR : A ssh certificate is required.  Found no file : '$(pwd)/${HABITAT_USER_SSH_KEY_NAME}'"  | tee -a ${LOG};
  usage;
  exit 1;
fi;

export SUDO_ASKPASS=${HOME}/.supwd.sh;

echo -e "${PRETTY} ensuring mongo-shell is installed.  "  | tee -a ${LOG};
sudo -A apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927 &>/dev/null;
echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.2 multiverse" \
         | sudo -A tee /etc/apt/sources.list.d/mongodb-org-3.2.list >>  ${LOG};
# echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.2 multiverse" \
#          | sudo -A tee /etc/apt/sources.list.d/mongodb-org-3.2.list >>  ${LOG};
sudo -A apt-get update >>  ${LOG};
sudo -A apt-get install -y mongodb-org-shell=3.2.10 >>  ${LOG};

echo -e "${PRETTY} purging any existing user '${HAB_USER}' . . .  " | tee -a ${LOG};
sudo -A deluser --quiet --remove-home ${HAB_USER}  >>  ${LOG};
sudo -A rm -fr "/etc/sudoers.d/${HAB_USER}" >>  ${LOG};

echo -e "${PRETTY} creating user '${HAB_USER}' . . .  " | tee -a ${LOG};
sudo -A adduser --disabled-password --gecos "" ${HAB_USER} >>  ${LOG};

echo -e "${PRETTY} ensuring command 'mkpassword' exists . . .  " | tee -a ${LOG};
sudo -A apt-get install -y whois  >>  ${LOG};

echo -e "${PRETTY} setting password for user '${HAB_USER}' . . .  " | tee -a ${LOG};
sudo -A usermod --password $( mkpasswd ${HAB_PASSWD} ) ${HAB_USER};

echo -e "${PRETTY} adding user '${HAB_USER}' to sudoers . . .  " | tee -a ${LOG};
sudo -A usermod -aG sudo ${HAB_USER};

echo -e "${PRETTY} let '${HAB_USER}' account use sudo without password . . .  " | tee -a ${LOG};
echo -e "${HAB_USER} ALL=(ALL) NOPASSWD:ALL" | (sudo -A su -c "EDITOR='tee' visudo -f /etc/sudoers.d/${HAB_USER}") > /dev/null;

echo -e "${PRETTY} adding caller's credentials to authorized SSH keys of '${HAB_USER}' . . .  " | tee -a ${LOG};
sudo -A mkdir -p ${HAB_SSH_DIR};
sudo -A cp ${HAB_SSH_KEY_NAME} ${HAB_SSH_AXS};
sudo -A chown -R ${HAB_USER}:${HAB_USER} ${HAB_SSH_DIR};
# cat ${HAB_SSH_AXS};

echo -e "${PRETTY} obtaining 'hab'.";

DEST_DIR="/usr/local/bin";
downloadHabToPathDir linux ${DEST_DIR};
echo -e "${PRETTY} installed 'hab' to '${DEST_DIR}'.\n\n";


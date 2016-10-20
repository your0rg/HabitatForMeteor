#!/usr/bin/env bash
#
SCRIPT=$(readlink -f "$0");
SCRIPTPATH=$(dirname "$SCRIPT");
SCRIPTNAME=$(basename "${SCRIPT}");

source ${HOME}/.bash_login;

function usage() {
  echo -e "USAGE : ./${SCRIPTNAME} \${USER_TOML_FILE_PATH} \${YOUR_ORG} \${YOUR_PKG} [\${YOUR_PKG_VERSION}] [\${YOUR_PKG_TIMESTAMP}]
  Where : * The four arguments correspond to the four parts of a Habitat package UUID.
          * The first and second are obligatory.  Three and four are optional.
          * All must be lowercase letting.
  ${1}";
  exit 1;
}

export YOUR_ORG=${1};
export YOUR_PKG=${2};
export YOUR_PKG_VERSION=${3};
export YOUR_PKG_TIMESTAMP=${4};

# #################################
#     settings
# export YOUR_ORG=fleetingclouds;
# export YOUR_PKG=todos;
# export YOUR_PKG_VERSION=;
# export YOUR_PKG_TIMESTAMP=;
# #################################

# if [[ "X${USER_TOML_FILE_PATH}X" = "XX" ]]; then usage "USER_TOML_FILE_PATH=${USER_TOML_FILE_PATH}"; fi;
TARGET_SECRETS_FILE=${SCRIPTPATH}/secrets.sh;

if [[ "X${YOUR_ORG}X" = "XX" ]]; then usage "YOUR_ORG=${YOUR_ORG}"; fi;
if [[ "X${YOUR_PKG}X" = "XX" ]]; then usage "YOUR_PKG=${YOUR_PKG}"; fi;

echo -e "${PRTY} Testing secrets file availability... [   ls \"${TARGET_SECRETS_FILE}\"  ]";
if [[ "X${TARGET_SECRETS_FILE}X" = "XX" ]]; then errorNoSecretsFileSpecified "null"; fi;
if [ ! -f "${TARGET_SECRETS_FILE}" ]; then errorNoSecretsFileSpecified "${TARGET_SECRETS_FILE}"; fi;
source ${TARGET_SECRETS_FILE};

VERSION_PATH="/${YOUR_PKG_VERSION}";
if [[ "X${YOUR_PKG_VERSION}X" = "XX" ]]; then unset VERSION_PATH; fi;

TIMESTAMP_PATH="/${YOUR_PKG_TIMESTAMP}";
if [[ "X${YOUR_PKG_TIMESTAMP}X" = "XX" ]]; then unset TIMESTAMP_PATH; fi;

SERVICE_UID=${YOUR_ORG}_${YOUR_PKG};
SERVICE_PATH=${YOUR_ORG}/${YOUR_PKG};
PACKAGE_PATH=${SERVICE_PATH}${VERSION_PATH}${TIMESTAMP_PATH};

UNIT_FILE=${SERVICE_UID}.service;

WORK_DIR=/hab/svc/${YOUR_PKG};
META_DIR=/hab/svc/${PACKAGE_PATH};
DNLD_DIR=/hab/pkgs/${SERVICE_PATH};

USER_TOML_FILE="user.toml";
USER_TOML_FILE_PATH=${WORK_DIR}/${USER_TOML_FILE};
DIRECTOR_TOML_FILE=${SERVICE_UID}.toml;
DIRECTOR_TOML_FILE_PATH=${META_DIR}/${DIRECTOR_TOML_FILE};


PRETTY="\n  ==> Runner ::";
LOG="/tmp/${SCRIPTNAME}.log";
touch ${LOG};
echo "Logging '${SCRIPTNAME}' execution to '${LOG}'." | tee ${LOG};
echo -e "${PRETTY} Stopping the '${SERVICE_UID}' systemd service, in case it's running . . ." | tee -a ${LOG};
sudo -A systemctl stop ${UNIT_FILE} >> ${LOG} 2>&1;

echo -e "${PRETTY} Disabling the '${SERVICE_UID}' systemd service, in case it's enabled . . ." | tee -a ${LOG};
sudo -A systemctl disable ${UNIT_FILE} >> ${LOG} 2>&1;

echo -e "${PRETTY} Deleting the '${SERVICE_UID}' systemd unit file, in case there's one already . . ." | tee -a ${LOG};
sudo -A rm /etc/systemd/system/${UNIT_FILE} >> ${LOG} 2>&1;

echo -e "${PRETTY} Deleting director toml file '${DIRECTOR_TOML_FILE_PATH}', in case there's one already . . ." | tee -a ${LOG};
sudo -A rm -fr ${DIRECTOR_TOML_FILE_PATH} >> ${LOG};

echo -e "${PRETTY} Ensuring Habitat Supervisor is available" | tee -a ${LOG};
sudo -A hab install core/hab-sup >> ${LOG} 2>&1;
sudo -A hab pkg binlink core/hab-sup hab-sup;

echo -e "${PRETTY} Ensuring Habitat Director is available" | tee -a ${LOG};
sudo -A hab install core/hab-director; # > /dev/null 2>&1;
sudo -A hab pkg binlink core/hab-director hab-director;

echo -e "${PRETTY} Ensuring package '${PACKAGE_PATH}' is available" | tee -a ${LOG};

echo -e "${PRETTY}  --> sudo -A hab pkg install '${PACKAGE_PATH}'" | tee -a ${LOG};
sudo -A hab pkg install ${PACKAGE_PATH};

PACKAGE_ABSOLUTE_PATH=$(sudo -A hab pkg path ${PACKAGE_PATH});

PACKAGE_UUID=${PACKAGE_ABSOLUTE_PATH#$DNLD_DIR/};
YOUR_PKG_VERSION=$(echo ${PACKAGE_UUID} | cut -d / -f 1);
YOUR_PKG_TIMESTAMP=$(echo ${PACKAGE_UUID} | cut -d / -f 2);

echo -e "${PRETTY} Package universal unique ID is :: '${SERVICE_PATH}/${YOUR_PKG_VERSION}/${YOUR_PKG_TIMESTAMP}'" >>  ${LOG};
if [[ "X${YOUR_PKG_VERSION}X" = "XX" ]]; then
  echo "Invalid package version '${YOUR_PKG_VERSION}'."  | tee -a ${LOG};
  exit 1;
fi;
if [[ "${#YOUR_PKG_TIMESTAMP}" != "14" ]]; then
  echo "Invalid package timestamp '${YOUR_PKG_TIMESTAMP}'."  | tee -a ${LOG};
  exit 1;
fi;



MONGO_ORIGIN="billmeyer";
# MONGO_ORIGIN="core";
MONGO_PKG="mongodb";
MONGO_INSTALLER="${MONGO_ORIGIN}/${MONGO_PKG}";
echo -e "${PRETTY}  --> sudo -A hab pkg install '${MONGO_INSTALLER}'" | tee -a ${LOG};
sudo -A hab pkg install ${MONGO_INSTALLER};

echo -e "${PRETTY} Starting '${MONGO_INSTALLER}' momentarily to set permissions." | tee -a ${LOG};
sudo -A hab start ${MONGO_INSTALLER} &

sleep 3;
echo -e "${PRETTY} Creating mongo admin user" | tee -a ${LOG};
mongo >> ${LOG} <<EOFA
use admin
db.createUser({user: "admin",pwd:"password",roles:[{role:"root",db:"admin"}]})
EOFA

echo -e "${PRETTY} Creating '${YOUR_PKG}' db and owner 'meteor'" | tee -a ${LOG};
mongo -u admin -p password admin >> ${LOG} <<EOFM
use ${YOUR_PKG}
db.createUser({user: "meteor",pwd:"coocoo4cocoa",roles:[{role:"dbOwner",db:"${YOUR_PKG}"},"readWrite"]})
EOFM

# ps aux | grep mongo;
sudo -A pkill hab-sup;
wait;

### ${YOUR_ORG}/${YOUR_PKG}/${YOUR_PKG_VERSION}/${YOUR_PKG_TIMESTAMP}/



sudo -A mkdir -p ${META_DIR};
sudo -A mkdir -p ${WORK_DIR};

echo -e "${PRETTY} Creating director toml file '${DIRECTOR_TOML_FILE_PATH}' from template" | tee -a ${LOG};
${SCRIPTPATH}/director.toml.template.sh > ${SCRIPTPATH}/${DIRECTOR_TOML_FILE};
echo -e "${PRETTY} Copying director toml file to '${META_DIR}' directory" | tee -a ${LOG};
sudo -A cp ${SCRIPTPATH}/${DIRECTOR_TOML_FILE} ${META_DIR} >> ${LOG};

echo -e "${PRETTY} Creating systemd unit file to 'systemd' directory" | tee -a ${LOG};
${SCRIPTPATH}/systemd.service.template.sh | sudo -A tee ${SCRIPTPATH}/${UNIT_FILE};
echo -e "${PRETTY} Copying unit file to 'systemd' directory" | tee -a ${LOG};
sudo -A cp ${SCRIPTPATH}/${UNIT_FILE} /etc/systemd/system >> ${LOG};

echo -e "${PRETTY} Creating user toml file '${USER_TOML_FILE_PATH}' from template" | tee -a ${LOG};
${SCRIPTPATH}/user.toml.template.sh > ${SCRIPTPATH}/${USER_TOML_FILE};
echo -e "${PRETTY} Copying user toml file to '${WORK_DIR}' directory" | tee -a ${LOG};
sudo -A cp ${SCRIPTPATH}/${USER_TOML_FILE} ${WORK_DIR} >> ${LOG};


echo -e "${PRETTY} Enabling the '${SERVICE_UID}' systemd service . . ." | tee -a ${LOG};
sudo -A systemctl enable ${UNIT_FILE};

echo -e "${PRETTY} Ensuring there is a directory available for '${SERVICE_UID}' logs" | tee -a ${LOG};
sudo -A mkdir -p ${META_DIR}/var/logs; # > /dev/null;

#  SET UP STUFF THAT HAB PACKAGE OUGHT TO DO FOR ITSELF
#  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# sudo -A mkdir -p ${META_DIR}/data; # > /dev/null;
# sudo -A touch ${META_DIR}/data/index.html;
# sudo -A find ${META_DIR} -type d -print0 | sudo -A xargs -0 chmod 770; # > /dev/null;
# sudo -A find ${META_DIR} -type f -print0 | sudo -A xargs -0 chmod 660; # > /dev/null;
# whoami;
# sudo -A chown -R hab:hab ${META_DIR};
# sudo -A ls -l ${META_DIR};
# sudo -A ls -l ${META_DIR}/data;
# sudo -A ls -l ${META_DIR}/data/index.html;
# sudo -A echo -e "nginx is ready" >> ${META_DIR}/data/index.html;

echo -e "${PRETTY} Start up the '${SERVICE_UID}' systemd service . . ." | tee -a ${LOG};
sudo -A systemctl start ${UNIT_FILE};


sudo -A ls -l ${META_DIR}/var/logs;
# sudo -A ls -l ${META_DIR}/data/index.html;

echo -e "";
echo -e "";
echo -e "  * * *  Some commands you might find you need  * * *  ";
echo -e "         .  .  .  .  .  .  .  .  .  .  .  .  .  ";
echo -e "";
echo -e "  Status of services :      systemctl list-unit-files --type=service |  grep ${SERVICE_UID}  ";
echo -e "          Enable  it : sudo systemctl  enable ${UNIT_FILE}  ";
echo -e "          Disable it : sudo systemctl disable ${UNIT_FILE}  ";
echo -e "";
echo -e "  #  Controlling it  ";
echo -e "  systemctl status ${UNIT_FILE}  ";
echo -e "  sudo systemctl stop ${UNIT_FILE}  ";
echo -e "  sudo systemctl start ${UNIT_FILE}  ";
echo -e "  sudo systemctl restart ${UNIT_FILE}  ";

echo -e "";
echo -e "  sudo journalctl -fb -u ${UNIT_FILE}  ";
echo -e "";
echo -e "";

exit 0;



# sudo -A rm -f  /etc/systemd/system/nginx.service;
# sudo -A rm -f  /etc/systemd/system/todos.service;
# # sudo -A rm -f  /etc/systemd/system/multi-user.target.wants/nginx.service;
# sudo -A rm -f  /hab/cache/artifacts/core-nginx-1.10.1-20160902203245-x86_64-linux.hart;
# sudo -A rm -f  /hab/cache/artifacts/fleetingclouds-todos-*.hart;
# sudo -A rm -fr /hab/pkgs/core/nginx;
# sudo -A rm -fr /hab/pkgs/fleetingclouds;
# sudo -A rm -fr /hab/svc/nginx;
# sudo -A rm -fr /hab/svc/todos;
# sudo -A rm -fr /home/hab/nginx;

# sudo -A updatedb && locate nginx;

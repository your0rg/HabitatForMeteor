#!/usr/bin/env bash
#
SCRIPT=$(readlink -f "$0");
SCRIPTPATH=$(dirname "$SCRIPT");
SCRIPTNAME=$(basename "${SCRIPT}");

source ${HOME}/.bash_login;

function errorNoSettingsFileSpecified() {
  echo -e "\n\n    *** A valid path to a Meteor settings.json file needs to be specified, not '${1}'  ***";
  usage;
}

function errorNoSecretsFileSpecified() {
  echo -e "\n\n    *** A valid path to a file of secrets for the remote server needs to be specified, not '${1}'  ***";
  usage;
}


function usage() {
  echo -e "USAGE :

   ./${SCRIPTNAME} \${VIRTUAL_HOST_DOMAIN_NAME} \${YOUR_ORG} \${YOUR_PKG} [\${YOUR_PKG_VERSION}] [\${YOUR_PKG_TIMESTAMP}]

  Where : * The first argument identifies URL by which the application will be found.
          * The last four arguments correspond to the four parts of a Habitat package UUID.
          * Of those, the first and second are obligatory.  The third and fourth are optional.
          * All must be lowercase letting.
  ${1}";
  exit 1;
}

export VIRTUAL_HOST_DOMAIN_NAME=${1};
export YOUR_ORG=${2};
export YOUR_PKG=${3};
export YOUR_PKG_VERSION=${4};
export YOUR_PKG_TIMESTAMP=${5};

# #################################
#     settings
# export YOUR_ORG=fleetingclouds;
# export YOUR_PKG=todos;
# export YOUR_PKG_VERSION=;
# export YOUR_PKG_TIMESTAMP=;
# #################################

# if [[ "X${USER_TOML_FILE_PATH}X" = "XX" ]]; then usage "USER_TOML_FILE_PATH=${USER_TOML_FILE_PATH}"; fi;
TARGET_SECRETS_FILE=${SCRIPTPATH}/secrets.sh;
TARGET_SETTINGS_FILE=${SCRIPTPATH}/settings.json;

if [[ "X${VIRTUAL_HOST_DOMAIN_NAME}X" = "XX" ]]; then usage "VIRTUAL_HOST_DOMAIN_NAME=${VIRTUAL_HOST_DOMAIN_NAME}"; fi;
if [[ "X${YOUR_ORG}X" = "XX" ]]; then usage "YOUR_ORG=${YOUR_ORG}"; fi;
if [[ "X${YOUR_PKG}X" = "XX" ]]; then usage "YOUR_PKG=${YOUR_PKG}"; fi;

echo -e "${PRTY} Testing secrets file availability... [   ls \"${TARGET_SECRETS_FILE}\"  ]";
if [[ "X${TARGET_SECRETS_FILE}X" = "XX" ]]; then errorNoSecretsFileSpecified "null"; fi;
if [ ! -f "${TARGET_SECRETS_FILE}" ]; then errorNoSecretsFileSpecified "${TARGET_SECRETS_FILE}"; fi;
source ${TARGET_SECRETS_FILE};

echo -e "${PRTY} Testing settings file availability... [   ls \"${TARGET_SETTINGS_FILE}\"  ]";
if [[ "X${TARGET_SETTINGS_FILE}X" = "XX" ]]; then errorNoSettingsFileSpecified "null"; fi;
if [ ! -f "${TARGET_SETTINGS_FILE}" ]; then errorNoSettingsFileSpecified "${TARGET_SETTINGS_FILE}"; fi;

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
NGINX_DIR=/hab/svc/nginx;

USER_TOML_FILE="user.toml";
USER_TOML_FILE_PATH=${WORK_DIR}/${USER_TOML_FILE};
DIRECTOR_TOML_FILE=${SERVICE_UID}.toml;
DIRECTOR_TOML_FILE_PATH=${META_DIR}/${DIRECTOR_TOML_FILE};

NGINX_TOML_FILE_PATH=${NGINX_DIR}/${USER_TOML_FILE};

NGINX_WORK_DIRECTORY="/etc/nginx";
NGINX_VHOSTS_DEFINITIONS="${NGINX_WORK_DIRECTORY}/sites-available";
NGINX_VHOSTS_PUBLICATIONS="${NGINX_WORK_DIRECTORY}/sites-enabled";
NGINX_VHOSTS_CERTIFICATES="${NGINX_WORK_DIRECTORY}/tls";
NGINX_ROOT_DIRECTORY="${NGINX_WORK_DIRECTORY}/www-data";
NGINX_VIRTUAL_HOST_FILE_PATH=${NGINX_VHOSTS_DEFINITIONS}/${VIRTUAL_HOST_DOMAIN_NAME};


pushd HabitatPkgInstallerScripts >/dev/null;

echo -e "${PRETTY} Creating Nginx virtual host directory structure." | tee -a ${LOG};
sudo -A mkdir -p ${NGINX_VHOSTS_DEFINITIONS};
sudo -A mkdir -p ${NGINX_VHOSTS_PUBLICATIONS};
sudo -A mkdir -p ${NGINX_VHOSTS_CERTIFICATES};
sudo -A mkdir -p ${NGINX_ROOT_DIRECTORY};
sh ${SCRIPTPATH}/index.html.template.sh > index.html;
sudo -A cp index.html ${NGINX_ROOT_DIRECTORY};

declare CP=$(echo "${VIRTUAL_HOST_DOMAIN_NAME}_CERT_PATH" | tr '[:lower:]' '[:upper:]' | tr '.' '_' ;)
declare CERT_PATH=$(echo ${!CP});
# sudo -A mkdir -p ${CERT_PATH};
# sudo -A chown -R hab:hab ${CERT_PATH};
# ls -l "${CERT_PATH}";

echo -e "${PRETTY} Moving '${VIRTUAL_HOST_DOMAIN_NAME}' site certificate from '${CERT_PATH}'
                                    to ${NGINX_VHOSTS_CERTIFICATES}/${VIRTUAL_HOST_DOMAIN_NAME}." | tee -a ${LOG};
sudo -A mkdir -p ${NGINX_VHOSTS_CERTIFICATES}/${VIRTUAL_HOST_DOMAIN_NAME};
sudo -A cp ${CERT_PATH}/server.* ${NGINX_VHOSTS_CERTIFICATES}/${VIRTUAL_HOST_DOMAIN_NAME};
sudo -A chown -R hab:hab ${NGINX_VHOSTS_CERTIFICATES}/${VIRTUAL_HOST_DOMAIN_NAME}/server.*;
sudo -A chmod -R go-rwx,u+rw ${NGINX_VHOSTS_CERTIFICATES}/${VIRTUAL_HOST_DOMAIN_NAME}/server.*;

echo -e "${PRETTY} Creating Nginx virtual host file '${NGINX_VIRTUAL_HOST_FILE_PATH}' from template." | tee -a ${LOG};
sh ${SCRIPTPATH}/virtual.host.conf.template.sh > ${VIRTUAL_HOST_DOMAIN_NAME};
sudo -A cp ${VIRTUAL_HOST_DOMAIN_NAME} ${NGINX_VHOSTS_DEFINITIONS};

echo -e "${PRETTY} Enabling Nginx virtual host ${VIRTUAL_HOST_DOMAIN_NAME}." | tee -a ${LOG};
sudo -A ln -sf ${NGINX_VIRTUAL_HOST_FILE_PATH} ${NGINX_VHOSTS_PUBLICATIONS}/${VIRTUAL_HOST_DOMAIN_NAME};

LOG_DIR="/var/log/nginx";
VHOST_LOG_DIR="${LOG_DIR}/${VIRTUAL_HOST_DOMAIN_NAME}";
echo -e "${PRETTY} Creating logging destinations for virtual host : ${VHOST_LOG_DIR}." | tee -a ${LOG};
sudo -A mkdir -p ${VHOST_LOG_DIR};
sudo -A touch ${VHOST_LOG_DIR}/access.log;
sudo -A touch ${VHOST_LOG_DIR}/error.log;


echo -e "${PRETTY} Creating Nginx user toml file '${NGINX_TOML_FILE_PATH}' from template." | tee -a ${LOG};
sudo -A mkdir -p ${NGINX_DIR};
sh ${SCRIPTPATH}/nginx.user.toml.template.sh > nginx.user.toml;
sudo -A cp nginx.user.toml ${NGINX_TOML_FILE_PATH};

echo -e "${PRETTY} Preparing site certificates passphrase file." | tee -a ${LOG};
export GLOBAL_CERT_PASSWORD_PATH=$( dirname "${GLOBAL_CERT_PASSWORD_FILE}");
export GLOBAL_CERT_PWD_FILE=$(basename "${GLOBAL_CERT_PASSWORD_FILE}");

mkdir -p ${GLOBAL_CERT_PASSWORD_PATH};
sudo -A touch ${GLOBAL_CERT_PASSWORD_PATH}/${GLOBAL_CERT_PWD_FILE};
TMP=$(sudo -A cat ${CERT_PATH}/server.pp);
CNT=$(sudo -A cat ${GLOBAL_CERT_PASSWORD_PATH}/${GLOBAL_CERT_PWD_FILE} | grep -c ${TMP});
if [[ ${CNT} -lt 1 ]]; then
  echo ${TMP} | sudo -A tee --append ${GLOBAL_CERT_PASSWORD_PATH}/${GLOBAL_CERT_PWD_FILE} >/dev/null;
fi;

# echo -e "~~~~~~~~~~~~~~~~~~
# Quitting  ...
# ";
# popd;
# exit;

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

echo -e "${PRETTY} Ensuring Habitat Supervisor is available (installing if necessary...)" | tee -a ${LOG};
sudo -A hab install core/hab-sup >> ${LOG} 2>&1;
sudo -A hab pkg binlink core/hab-sup hab-sup;

echo -e "${PRETTY} Ensuring Habitat Director is available (installing if necessary...)" | tee -a ${LOG};
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
db.createUser({user: "meteor",pwd:"${MONGODB_PWD}",roles:[{role:"dbOwner",db:"${YOUR_PKG}"},"readWrite"]})
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
${SCRIPTPATH}/app.user.toml.template.sh > ${SCRIPTPATH}/${USER_TOML_FILE};
echo -e "${PRETTY} Copying user toml file to '${WORK_DIR}' directory" | tee -a ${LOG};
sudo -A cp ${SCRIPTPATH}/${USER_TOML_FILE} ${WORK_DIR} >> ${LOG};

echo -e "${PRETTY} Copying Meteor settings file to '${WORK_DIR}/var' directory" | tee -a ${LOG};
sudo -A mkdir -p ${WORK_DIR}/var >> ${LOG};
sudo -A cp ${TARGET_SETTINGS_FILE} ${WORK_DIR}/var >> ${LOG};
sudo -A chown -R hab:hab ${WORK_DIR}/var >> ${LOG};

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

# declare NGINX_CONF="/hab/svc/nginx/config/nginx.conf";
declare NGINX_CONF="/hab/pkgs/${YOUR_ORG}/nginx/1.10.1/20161105150115/config/nginx.conf";

declare EXISTING_SETTING="keepalive_timeout";
declare MISSING_SETTING="server_names_hash_bucket_size";
declare REPLACEMENT="    ${MISSING_SETTING} 64;\n    ${EXISTING_SETTING} 60;";

if ! sudo -A grep "${MISSING_SETTING}" ${NGINX_CONF} >/dev/null; then
  echo -e "
  FIXME : This hack should not be necessary when Habitat accepts my PR.
  ";
  sudo -A sed -i "s|.*${EXISTING_SETTING}.*|${REPLACEMENT}|" ${NGINX_CONF};
fi;

echo -e "${PRETTY} Start up the '${SERVICE_UID}' systemd service . . ." | tee -a ${LOG};
sudo -A systemctl start ${UNIT_FILE};


sudo -A ls -l ${META_DIR}/var/logs;
# sudo -A ls -l ${META_DIR}/data/index.html;

echo -e "";
echo -e "";
echo -e "  * * *  Some commands you might find you need  * * *  ";
echo -e "         .  .  .  .  .  .  .  .  .  .  .  .  .  ";
echo -e "";
echo -e "# Strategic";
echo -e "     It's state  :      systemctl list-unit-files --type=service |  grep ${SERVICE_UID}  ";
echo -e "     Enable  it  : sudo systemctl  enable ${UNIT_FILE}  ";
echo -e "     Disable it  : sudo systemctl disable ${UNIT_FILE}  ";
echo -e "";
echo -e "# Tactical";
echo -e "                        systemctl status ${UNIT_FILE}  ";
echo -e "                   sudo systemctl stop ${UNIT_FILE}  ";
echo -e "                   sudo systemctl start ${UNIT_FILE}  ";
echo -e "                   sudo systemctl restart ${UNIT_FILE}  ";

echo -e "# Surveillance";
echo -e "                   sudo journalctl -fb -u ${UNIT_FILE}  ";
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
# ----

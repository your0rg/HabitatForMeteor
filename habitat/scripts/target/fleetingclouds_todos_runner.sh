#!/usr/bin/env bash
#
SCRIPT=$(readlink -f "$0");
SCRIPTPATH=$(dirname "$SCRIPT");
SCRIPTNAME=$(basename "${SCRIPT}");


# #################################
#     settings
export YOUR_ORG=fleetingclouds;
export YOUR_PKG=todos;
export YOUR_PKG_VERSION=;
export YOUR_PKG_TIMESTAMP=;
# #################################


VERSION_PATH="/${YOUR_PKG_VERSION}";
if [[ "X${YOUR_PKG_VERSION}X" = "XX" ]]; then unset VERSION_PATH; fi;


TIMESTAMP_PATH="/${YOUR_PKG_TIMESTAMP}";
if [[ "X${YOUR_PKG_TIMESTAMP}X" = "XX" ]]; then unset TIMESTAMP_PATH; fi;

SERVICE_UID=${YOUR_ORG}_${YOUR_PKG};
SERVICE_PATH=${YOUR_ORG}/${YOUR_PKG};
PACKAGE_PATH=${SERVICE_PATH}${VERSION_PATH}${TIMESTAMP_PATH};

UNIT_FILE=${SERVICE_UID}.service;
TOML_FILE=${SERVICE_UID}.toml;

WORK_DIR=/hab/svc/${PACKAGE_PATH};
DNLD_DIR=/hab/pkgs/${SERVICE_PATH};

TOML_FILE_PATH=${WORK_DIR}/${YOUR_ORG}_${YOUR_PKG}.toml;


PRETTY="\n  ==> Runner ::";
LOG="/tmp/${SCRIPTNAME}.log";
touch ${LOG};
echo "Logging '${SCRIPTNAME}' execution to '${LOG}'." | tee ${LOG};


echo -e "${PRETTY} Stopping the '${SERVICE_UID}' systemd service, in case it's running . . ." | tee -a ${LOG};
sudo systemctl stop ${UNIT_FILE} >> ${LOG} 2>&1;

echo -e "${PRETTY} Disabling the '${SERVICE_UID}' systemd service, in case it's enabled . . ." | tee -a ${LOG};
sudo systemctl disable ${UNIT_FILE} >> ${LOG} 2>&1;

echo -e "${PRETTY} Deleting the '${SERVICE_UID}' systemd unit file, in case there's one already . . ." | tee -a ${LOG};
sudo rm /etc/systemd/system/${UNIT_FILE} >> ${LOG} 2>&1;

echo -e "${PRETTY} Deleting director toml file from '${TOML_FILE_PATH}', in case there's one already . . ." | tee -a ${LOG};
sudo mkdir -p ${TOML_FILE_PATH};
sudo rm -fr ${TOML_FILE_PATH}/${TOML_FILE} >> ${LOG};

echo -e "${PRETTY} Ensuring Habitat Supervisor is available" | tee -a ${LOG};
sudo hab install core/hab-sup >> ${LOG} 2>&1;
sudo hab pkg binlink core/hab-sup hab-sup;

echo -e "${PRETTY} Ensuring Habitat Director is available" | tee -a ${LOG};
sudo hab install core/hab-director; # > /dev/null 2>&1;
sudo hab pkg binlink core/hab-director hab-director;

echo -e "${PRETTY} Ensuring package '${PACKAGE_PATH}' is available" | tee -a ${LOG};

echo -e "${PRETTY}  --> sudo hab pkg install '${PACKAGE_PATH}'" | tee -a ${LOG};
sudo hab pkg install ${PACKAGE_PATH};

PACKAGE_ABSOLUTE_PATH=$(sudo hab pkg path ${PACKAGE_PATH});

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



echo -e "${PRETTY}  --> sudo hab pkg install 'core/mongodb'" | tee -a ${LOG};
sudo hab pkg install core/mongodb;

echo -e "${PRETTY} Starting 'core/mongodb' momentarily to set permissions." | tee -a ${LOG};
sudo hab start core/mongodb &

sleep 3;
echo -e "${PRETTY} Creating mongo admin user" | tee -a ${LOG};
mongo >> ${LOG} <<EOFA
use admin
db.createUser({user: "admin",pwd:"password",roles:[{role:"root",db:"admin"}]})
EOFA

echo -e "${PRETTY} Creating 'todos' db and owner 'meteor'" | tee -a ${LOG};
mongo -u admin -p password admin >> ${LOG} <<EOFM
use todos
db.createUser({user: "meteor",pwd:"coocoo4cocoa",roles:[{role:"dbOwner",db:"todos"},"readWrite"]})
EOFM

# ps aux | grep mongo;
sudo pkill hab-sup;
wait;


echo -e "${PRETTY} Creating director toml file '${TOML_FILE_PATH}' from template" | tee -a ${LOG};
${SCRIPTPATH}/package.toml.template.sh > ${SCRIPTPATH}/${TOML_FILE};
echo -e "${PRETTY} Copying director toml file to '${TOML_FILE_PATH}' directory" | tee -a ${LOG};
sudo cp ${SCRIPTPATH}/${TOML_FILE} ${TOML_FILE_PATH} >> ${LOG};

echo -e "${PRETTY} Creating systemd unit file to 'systemd' directory" | tee -a ${LOG};
${SCRIPTPATH}/package.service.template.sh > ${SCRIPTPATH}/${UNIT_FILE};
echo -e "${PRETTY} Copying unit file to 'systemd' directory" | tee -a ${LOG};
sudo cp ${SCRIPTPATH}/${UNIT_FILE} /etc/systemd/system >> ${LOG};



echo -e "${PRETTY} Enabling the '${SERVICE_UID}' systemd service . . ." | tee -a ${LOG};
sudo systemctl enable ${UNIT_FILE};

echo -e "${PRETTY} Ensuring there is a directory available for '${SERVICE_UID}' logs" | tee -a ${LOG};
sudo mkdir -p ${WORK_DIR}/var/logs; # > /dev/null;

#  SET UP STUFF THAT HAB PACKAGE OUGHT TO DO FOR ITSELF
#  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# sudo mkdir -p ${WORK_DIR}/data; # > /dev/null;
# sudo touch ${WORK_DIR}/data/index.html;
# sudo find ${WORK_DIR} -type d -print0 | sudo xargs -0 chmod 770; # > /dev/null;
# sudo find ${WORK_DIR} -type f -print0 | sudo xargs -0 chmod 660; # > /dev/null;
# whoami;
# sudo chown -R hab:hab ${WORK_DIR};
# sudo ls -l ${WORK_DIR};
# sudo ls -l ${WORK_DIR}/data;
# sudo ls -l ${WORK_DIR}/data/index.html;
# sudo echo -e "nginx is ready" >> ${WORK_DIR}/data/index.html;

echo -e "${PRETTY} Start up the '${SERVICE_UID}' systemd service . . ." | tee -a ${LOG};
sudo systemctl start ${UNIT_FILE};


sudo ls -l ${WORK_DIR}/var/logs;
# sudo ls -l ${WORK_DIR}/data/index.html;

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

sudo rm -f  /etc/systemd/system/nginx.service;
sudo rm -f  /etc/systemd/system/todos.service;
# sudo rm -f  /etc/systemd/system/multi-user.target.wants/nginx.service;
sudo rm -f  /hab/cache/artifacts/core-nginx-1.10.1-20160902203245-x86_64-linux.hart;
sudo rm -f  /hab/cache/artifacts/fleetingclouds-todos-*.hart;
sudo rm -fr /hab/pkgs/core/nginx;
sudo rm -fr /hab/pkgs/fleetingclouds;
sudo rm -fr /hab/svc/nginx;
sudo rm -fr /hab/svc/todos;
sudo rm -fr /home/hab/nginx;

sudo updatedb && locate nginx;

#!/usr/bin/env bash
#

function usage() {
  echo -e "    Usage ::
     ${SCRIPTPATH}/PushSiteCertificateToTarget.sh \\
                   \${TARGET_SRVR} \\
                   \${SOURCE_SECRETS_FILE} \\
                   \${VIRTUAL_HOST_DOMAIN_NAME}
      Where :
        TARGET_SRVR is the host where the project will be installed.
        SOURCE_SECRETS_FILE is the path to a file of required passwords and keys for '\${TARGET_SRVR}'.
        VIRTUAL_HOST_DOMAIN_NAME identifies the target server domain name
            ( example source secrets file : ${SCRIPTPATH}/target/secrets.sh.example )

  ";
  exit 1;
}

function errorNoRemoteHostSpecified() {
  echo -e "\n\n    *** The domain name, or IP address, of the remote server needs to be specified  ***";
  usage;
}

function errorCannotPingRemoteServer() {
  echo -e "\n\n    *** Cannot ping remote server : '${1}' ***";
  usage;
}

function errorNoSecretsFileSpecified() {
  echo -e "\n\n    *** A valid path to a file of secrets for the remote server needs to be specified, not '${1}'  ***";
  usage;
}


set +e;

SCRIPT=$(readlink -f "$0");
SCRIPTPATH=$(dirname "$SCRIPT");
echo -e "\n${PRTY} Changing working location to ${SCRIPTPATH}.";
cd ${SCRIPTPATH};


PRTY="PSCtT  ==> ";

export TARGET_SRVR=${1};
export SOURCE_SECRETS_FILE=${2};
export VIRTUAL_HOST_DOMAIN_NAME=${3};

export HABITAT_USER=hab;
export BUNDLE_DIRECTORY_NAME="HabitatPkgInstallerScripts";

echo -e "${PRTY} TARGET_SRVR=${TARGET_SRVR}";
echo -e "${PRTY} HABITAT_USER=${HABITAT_USER}";
echo -e "${PRTY} SOURCE_SECRETS_FILE=${SOURCE_SECRETS_FILE}";
echo -e "${PRTY} VIRTUAL_HOST_DOMAIN_NAME=${VIRTUAL_HOST_DOMAIN_NAME}";


# ----------------
echo -e "${PRTY} Testing server presence using... [   ping -c 1 ${TARGET_SRVR};   ]";
if [[ "X${TARGET_SRVR}X" = "XX" ]]; then errorNoRemoteHostSpecified "null"; fi;
ping -c 1 ${TARGET_SRVR} >/dev/null || errorCannotPingRemoteServer "${TARGET_SRVR}";



# ----------------
declare CNT_AGENTS=$(ps au -u $(whoami) | grep -v grep | grep -c ssh-agent);
if [[ ${CNT_AGENTS} -lt 1  ]]; then
  echo -e "${PRTY} Start up SSH agent... [   exec ssh-agent bash; ssh-add;  ]";
  eval $(ssh-agent) > /dev/null;
  ssh-add > /dev/null;
fi;


# ----------------
echo -e "${PRTY} Testing SSH connection using... [   ssh ${HABITAT_USER}@${TARGET_SRVR} 'whoami';  ]";
REMOTE_USER=$(ssh -qt -oBatchMode=yes -l ${HABITAT_USER} ${TARGET_SRVR} whoami) || errorCannotCallRemoteProcedure "${HABITAT_USER}@${TARGET_SRVR}";
[[ 0 -lt $(echo "${REMOTE_USER}" | grep -c "${HABITAT_USER}") ]] ||  errorUnexpectedRPCResult;



# ----------------
echo -e "${PRTY} Testing secrets file availability... [   ls \"${SOURCE_SECRETS_FILE}\"  ]";
if [[ "X${SOURCE_SECRETS_FILE}X" = "XX" ]]; then errorNoSecretsFileSpecified "null"; fi;
if [ ! -f "${SOURCE_SECRETS_FILE}" ]; then errorNoSecretsFileSpecified "${SOURCE_SECRETS_FILE}"; fi;
source ${SOURCE_SECRETS_FILE};

declare CP=$(echo "${VIRTUAL_HOST_DOMAIN_NAME}_CERT_PATH" | tr '[:lower:]' '[:upper:]' | tr '.' '_' ;)
# echo ${CP}
declare CERT_PATH=$(echo ${!CP});
# echo ${CERT_PATH};

declare TARGET_CERT_PATH="/home/hab/.ssh/habitat/${VIRTUAL_HOST_DOMAIN_NAME}";
echo -e "${PRTY} Copying '${VIRTUAL_HOST_DOMAIN_NAME}' site certificate 
               from ${CERT_PATH}
                 to ${TARGET_SRVR}:${TARGET_CERT_PATH}";
ssh hab@${TARGET_SRVR} mkdir -p ${TARGET_CERT_PATH};
# scp ${HOME}/.ssh/habitat/${VIRTUAL_HOST_DOMAIN_NAME}/* ${HABITAT_USER}@${TARGET_SRVR}:${CERT_PATH} >/dev/null;
scp ${CERT_PATH}/* ${HABITAT_USER}@${TARGET_SRVR}:${TARGET_CERT_PATH} >/dev/null;


# SCRIPTPATH=$(dirname "$SCRIPT");

# ssh hab@${TARGET_SRVR} mkdir -p ${CERT_PATH};


echo -e "\n${PRTY} If you already executed './PushInstallerScriptsToTarget.sh' then server '${TARGET_SRVR}' is ready for HabitatForMeteor.
            Next step : From any machine with passwordless SSH access to the
                        the server '${TARGET_SRVR}' you can now run...

      ssh ${HABITAT_USER}@${TARGET_SRVR} "~${BUNDLE_DIRECTORY_NAME}/HabitatPackageRunner.sh \${VIRTUAL_HOST_DOMAIN_NAME} \${YOUR_ORG} \${YOUR_PKG} \${semver} \${timestamp}";
      # The first three arguments are obligatory. The last two permit specifying older releases.

Quitting...
$(date);
Done.
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
";

exit 0;


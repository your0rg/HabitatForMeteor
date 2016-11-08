#!/usr/bin/env bash
#

function usage() {
  echo -e "    Usage ::
     ${SCRIPTPATH}/PushSiteCertificateToTarget.sh \\
                   \${TARGET_HOST} \\
                   \${SOURCE_SECRETS_FILE} \\
                   \${VIRTUAL_HOST_DOMAIN_NAME}
      Where :
        TARGET_HOST is the host where the project will be installed.
        SOURCE_SECRETS_FILE is the path to a file of required passwords and keys for '\${TARGET_HOST}'.
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

export TARGET_HOST=${1};
export SOURCE_SECRETS_FILE=${2};
export VIRTUAL_HOST_DOMAIN_NAME=${3};

export HABITAT_USER=hab;
export BUNDLE_DIRECTORY_NAME="HabitatPkgInstallerScripts";

echo -e "${PRTY} TARGET_HOST=${TARGET_HOST}";
echo -e "${PRTY} HABITAT_USER=${HABITAT_USER}";
echo -e "${PRTY} SOURCE_SECRETS_FILE=${SOURCE_SECRETS_FILE}";
echo -e "${PRTY} VIRTUAL_HOST_DOMAIN_NAME=${VIRTUAL_HOST_DOMAIN_NAME}";


# ----------------
echo -e "${PRTY} Testing server presence using... [   ping -c 1 ${TARGET_HOST};   ]";
if [[ "X${TARGET_HOST}X" = "XX" ]]; then errorNoRemoteHostSpecified "null"; fi;
ping -c 1 ${TARGET_HOST} >/dev/null || errorCannotPingRemoteServer "${TARGET_HOST}";



# ----------------
declare CNT_AGENTS=$(ps au -u $(whoami) | grep -v grep | grep -c ssh-agent);
if [[ ${CNT_AGENTS} -lt 1  ]]; then
  echo -e "${PRTY} Start up SSH agent... [   exec ssh-agent bash; ssh-add;  ]";
  eval $(ssh-agent) > /dev/null;
  ssh-add > /dev/null;
fi;


# ----------------
echo -e "${PRTY} Testing SSH using... [   ssh ${HABITAT_USER}@${TARGET_HOST} 'whoami';  ]";
REMOTE_USER=$(ssh -qt -oBatchMode=yes -l ${HABITAT_USER} ${TARGET_HOST} whoami) || errorCannotCallRemoteProcedure "${HABITAT_USER}@${TARGET_HOST}";
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

echo -e "${PRTY} Copying '${VIRTUAL_HOST_DOMAIN_NAME}' site certificate 
               from ${HOME}/.ssh/habitat/${VIRTUAL_HOST_DOMAIN_NAME}
                 to ${TARGET_HOST}:${CERT_PATH}";
ssh hab@${TARGET_HOST} mkdir -p ${CERT_PATH};
scp ${HOME}/.ssh/habitat/${VIRTUAL_HOST_DOMAIN_NAME}/* ${HABITAT_USER}@${TARGET_HOST}:${CERT_PATH} >/dev/null;


SCRIPTPATH=$(dirname "$SCRIPT");

ssh hab@${TARGET_HOST} mkdir -p ${CERT_PATH};


echo -e "\n${PRTY} If you already executed './PushInstallerScriptsToTarget.sh' then server '${TARGET_HOST}' is ready for HabitatForMeteor.
            Next step : From any machine with passwordless SSH access to the
                        the server '${TARGET_HOST}' you can now run...

      ssh ${TARGET_USER}@${TARGET_HOST} "~${BUNDLE_DIRECTORY_NAME}/HabitatPackageRunner.sh \${VIRTUAL_HOST_DOMAIN_NAME} \${YOUR_ORG} \${YOUR_PKG} \${semver} \${timestamp}";
      # The first three arguments are obligatory. The last two permit specifying older releases.

Quitting...
$(date);
Done.
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
";

exit 0;


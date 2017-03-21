#!/usr/bin/env bash
#
function usage() {
  echo -e "    Usage ::
     ${SCRIPTPATH}/PushSiteCertificateToTarget.sh \\
       \${TARGET_SRVR} \\
       \${SOURCE_SECRETS_FILE} \\
       \${SOURCE_CERTS_DIR} \\
       \${VIRTUAL_HOST_DOMAIN_NAME} \\
       \${VHOST_ENV_VARS}
      Where :
        TARGET_SRVR is the host where the project will be installed.
        SOURCE_SECRETS_FILE is the path to a file of required passwords and keys for '\${TARGET_SRVR}'.
        SOURCE_CERTS_DIR is the path to the directory that holds the SSL certificate of '\${VIRTUAL_HOST_DOMAIN_NAME}'.
        VIRTUAL_HOST_DOMAIN_NAME identifies the target server domain name
            ( example source secrets file : ${SCRIPTPATH}/target/secrets.sh.example )
        VHOST_ENV_VARS is the path to a file of environment variables for '\${TARGET_SRVR}'

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

function errorCannotCallRemoteProcedure() {
  echo -e "\n\n    *** Cannot call remote procedure. Is '${1}' correct? ***";
  usage;
}


function errorNoCertificatesFoundToCopy() {
  echo -e "\n\n    *** A valid path to a directory of certificate folders needs to be specified, not '${1}'  ***";
  usage;
}

function startSSHAgent() {
  echo -e "${PRTY} Starting 'ssh-agent' ...";
  if [ -z "${SSH_AUTH_SOCK}" ]; then
    eval $(ssh-agent -s);
    echo -e "${PRTY} Started 'ssh-agent' ...";
  fi;
};

# set -e;

SCRIPT=$(readlink -f "$0");
SCRIPTPATH=$(dirname "$SCRIPT");
echo -e "\n${PRTY} Changing working location to ${SCRIPTPATH}.";
cd ${SCRIPTPATH};


PRTY="PSCtT  ==> ";

export TARGET_SRVR=${1};
export SOURCE_SECRETS_FILE=${2};
export SOURCE_CERTS_DIR=${3};
export VIRTUAL_HOST_DOMAIN_NAME=${4};
export VHOST_ENV_VARS=${5};

export HABITAT_USER=hab;
export BUNDLE_DIRECTORY_NAME="HabitatPkgInstallerScripts";

echo -e "${PRTY} TARGET_SRVR=${TARGET_SRVR}";
echo -e "${PRTY} HABITAT_USER=${HABITAT_USER}";
echo -e "${PRTY} SOURCE_SECRETS_FILE=${SOURCE_SECRETS_FILE}";
echo -e "${PRTY} VIRTUAL_HOST_DOMAIN_NAME=${VIRTUAL_HOST_DOMAIN_NAME}";
echo -e "${PRTY} VHOST_ENV_VARS=${VHOST_ENV_VARS}";

# ----------------
echo -e "${PRTY} Testing secrets file availability... [   ls \"${SOURCE_SECRETS_FILE}\"  ]";
if [[ "X${SOURCE_SECRETS_FILE}X" = "XX" ]]; then errorNoSecretsFileSpecified "null"; fi;
if [ ! -f "${SOURCE_SECRETS_FILE}" ]; then errorNoSecretsFileSpecified "${SOURCE_SECRETS_FILE}"; fi;

source ${SOURCE_SECRETS_FILE};

# ----------------
echo -e "${PRTY} Testing server presence using... [   ping -c 1 ${TARGET_SRVR};   ]";
if [[ "X${TARGET_SRVR}X" = "XX" ]]; then errorNoRemoteHostSpecified "null"; fi;
ping -c 1 ${TARGET_SRVR} >/dev/null || errorCannotPingRemoteServer "${TARGET_SRVR}";


# ----------------
echo -e "${PRTY} Testing environment vars file availability... [   ls \"${VHOST_ENV_VARS}\"  ]";
if [[ "X${VHOST_ENV_VARS}X" = "XX" ]]; then errorNoEnvVarsFileSpecified "null"; fi;
if [ ! -f "${VHOST_ENV_VARS}" ]; then errorNoEnvVarsFileSpecified "${VHOST_ENV_VARS}"; fi;

source ${VHOST_ENV_VARS};

ssh-add -l | grep "${HABITAT_USER_SSH_KEY_PUBL%.pub}";
echo -e "# ----------------";
if ! ssh-add -l | grep "${HABITAT_USER_SSH_KEY_PUBL%.pub}" &>/dev/null; then
  echo -e "${PRTY} Activating ssh-agent for hab user's ssh key passphrase";
  startSSHAgent;
  expect << EOF
    spawn ssh-add ${HABITAT_USER_SSH_KEY_PUBL%.pub}
    expect "Enter passphrase"
    send "${HABITAT_USER_SSH_PASS}\r"
    expect eof
EOF
fi;



# ----------------
echo -e "${PRTY} Testing SSH connection using... [   ssh ${HABITAT_USER}@${TARGET_SRVR} 'whoami';  ]";
REMOTE_USER=$(ssh -qt -oBatchMode=yes -l ${HABITAT_USER} ${TARGET_SRVR} whoami) || errorCannotCallRemoteProcedure "${HABITAT_USER}@${TARGET_SRVR}";
[[ 0 -lt $(echo "${REMOTE_USER}" | grep -c "${HABITAT_USER}") ]] ||  errorUnexpectedRPCResult;



# ----------------
echo -e "${PRTY} Verifying certificates directory.";
if [ ! -d "${SOURCE_CERTS_DIR}" ]; then
  errorNoCertificatesFoundToCopy "${SOURCE_CERTS_DIR}";
fi;

if [ ! -f "${SOURCE_CERTS_DIR}/cert.pem" ]; then
  errorNoCertificatesFoundToCopy "${SOURCE_CERTS_DIR}/cert.pem";
fi;

echo "${VIRTUAL_HOST_DOMAIN_NAME}_CERT_PATH";
declare CP=$(echo "${VIRTUAL_HOST_DOMAIN_NAME}_CERT_PATH" | tr '[:lower:]' '[:upper:]' | tr '.' '_' ;)
echo "CP = ${CP} --> ${!CP}";
declare CERT_PATH=$(echo ${!CP}); # Indirect reference returns nothing if no such variable has been declared.
echo "~~~~~~~~~~~~~~~~~~~~~~ ${CERT_PATH} ~~~~~~~~~~~~";
if [[ -z "${CERT_PATH}" ]]; then
  echo -e "No environment variable, '${CP}', could be sourced. Indirect variable failure."  ;
  exit;
fi;

# declare TARGET_CERT_PATH="/home/hab/.ssh/hab_vault/${VIRTUAL_HOST_DOMAIN_NAME}";
echo -e "${PRTY} Copying '${VIRTUAL_HOST_DOMAIN_NAME}' site certificate
               from ${SOURCE_CERTS_DIR}
                 to ${TARGET_SRVR}:${CERT_PATH}";
ssh ${HABITAT_USER}@${TARGET_SRVR} mkdir -p ${CERT_PATH};
scp ${SOURCE_CERTS_DIR}/* ${HABITAT_USER}@${TARGET_SRVR}:${CERT_PATH} >/dev/null;

if [[ "${NON_STOP}" = "YES" ]]; then exit 0; fi;

echo -e "\n${PRTY} If you already executed './PushInstallerScriptsToTarget.sh' then server '${TARGET_SRVR}' is ready for HabitatForMeteor.
            Next step : From any machine with passwordless SSH access to the
                        the server '${TARGET_SRVR}' you can now run...

      ssh ${HABITAT_USER}@${TARGET_SRVR} \". ~/.bash_login && ~/${BUNDLE_DIRECTORY_NAME}/HabitatPackageRunner.sh \${VIRTUAL_HOST_DOMAIN_NAME} \${YOUR_ORG} \${YOUR_PKG} \${semver} \${timestamp}\";
      # The first three arguments are obligatory. The last two permit specifying older releases.

Quitting...
$(date);
Done.
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
";

exit 0;


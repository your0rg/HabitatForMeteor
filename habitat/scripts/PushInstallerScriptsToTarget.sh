#!/usr/bin/env bash
#

function usage() {
  echo -e "    Usage ::
     ${SCRIPTPATH}/PushInstallerScriptsToTarget.sh \\
                   \${TARGET_SRVR} \\
                   \${SETUP_USER_UID} \\
                   \${METEOR_SETTINGS_FILE} \\
                   \${SOURCE_SECRETS_FILE}
      Where :
        TARGET_SRVR is the host where the project will be installed.
        SETUP_USER_UID is a previously prepared 'sudoer' account on '\${TARGET_SRVR}'.
        METEOR_SETTINGS_FILE typically called 'settings.json', contains your app's internal settings,
        SOURCE_SECRETS_FILE is the path to a file of required passwords and keys for '\${TARGET_SRVR}'.
            ( example file : ${SCRIPTPATH}/target/secrets.sh.example )

  ";
  exit 1;
}

function errorInvalidReleaseTag() {
  echo -e "\n\n    *** Invalid release tag ***";
  usage;
}

function errorCannotPingRemoteServer() {
  echo -e "\n\n    *** Cannot ping remote server : '${1}' ***";
  usage;
}

function errorNoUserAccountSpecified() {
  echo -e "\n\n    *** The user account for the remote server needs to be specified  ***";
  usage;
}

function errorNoSettingsFileSpecified() {
  echo -e "\n\n    *** A valid path to a Meteor settings.json file needs to be specified, not '${1}'  ***";
  usage;
}

function warningEmptySettingsFileSpecified() {
  echo -e "\n\n    *** An empty Meteor settings.json file was detected at, '${1}'  ***

  ";
  read -ep "Do you wish to (q)uit or fix that and (c)ontinue? (q/c) ::  " -n 1 -r USER_ANSWER
  CHOICE=$(echo ${USER_ANSWER:0:1} | tr '[:upper:]' '[:lower:]')
  if [[ "X${CHOICE}X" == "XqX" ]]; then
    echo "Skipping this operation."; exit 1;
  fi;
  echo -e " Continuing... ";

}

function errorNoSecretsFileSpecified() {
  echo -e "\n\n    *** A valid path to a file of secrets for the remote server needs to be specified, not '${1}'  ***";
  usage;
}


function errorCannotCallRemoteProcedure() {
  echo -e "\n\n    *** Cannot call remote procedure. Is '${1}' correct? ***";
  usage;
}

function errorBadPathToSSHKey() {
  echo -e "\n\n    *** No valid SSH key found at '${1}' ***";
  usage;
}

function errorUnexpectedRPCResult() {
  echo -e "\n\n    *** Remote procedure call could not complete ***";
  usage;
}

function errorFailedToPushBundle() {
  echo -e "\n\n    *** Secure CoPy could not push bundle to remote user account ***";
  usage;
}

function errorUnsuitablePassword() {
  echo -e "\n\n    *** '${1}' is not a viable password***
                   -- Minimum size is ${PASSWORD_MINIMUM_LENGTH} chars --";
  usage;
}

function errorNoSuitablePasswordInFile() {
  echo -e "\n\n    *** No viable password found in the file, '${1}' ***
                   -- Minimum size is ${PASSWORD_MINIMUM_LENGTH} chars --";
  usage;
}

function startSSHAgent() {
  echo -e "${PRTY} Starting 'ssh-agent' ...";
  if [ -z "${SSH_AUTH_SOCK}" ]; then
    eval $(ssh-agent -s);
    echo -e "${PRTY} Started 'ssh-agent' ...";
  fi;
};



declare MKR_SCRPT="";
function makeMakerScriptMaker() {
  cat <<SAPMF
#!/usr/bin/env bash
#
export SUPWD="\${HOME}/.ssh/.supwd.sh";
echo -e '#!/usr/bin/env bash' > \${SUPWD};
echo -e "echo '${1}';" >> \${SUPWD};
chmod a+x,go-rwx \${SUPWD};
echo "Created ${SUPWD}";
SAPMF
}

set -e;

CURR_DIR=$(pwd);
SCRIPT=$(readlink -f "$0");
SCRIPTPATH=$(dirname "$SCRIPT");
echo -e "\n${PRTY} Changing working location to ${SCRIPTPATH}.";
cd ${SCRIPTPATH};

. ./utils.sh;
loadSemVerScript;
. ./semver.sh


PRTY="PIStT  ==> ";

TARGET_SRVR=${1};
SETUP_USER_UID=${2};
METEOR_SETTINGS_FILE=${3};
SOURCE_SECRETS_FILE=${4};

HABITAT_USER='hab';


PASSWORD_MINIMUM_LENGTH=4;

echo -e "${PRTY} TARGET_SRVR=${TARGET_SRVR}";
echo -e "${PRTY} SETUP_USER_UID=${SETUP_USER_UID}";
echo -e "${PRTY} METEOR_SETTINGS_FILE=${METEOR_SETTINGS_FILE}";
echo -e "${PRTY} SOURCE_SECRETS_FILE=${SOURCE_SECRETS_FILE}";

SCRIPTS_DIRECTORY="target";
BUNDLE_DIRECTORY_NAME="HabitatPkgInstallerScripts";
BUNDLE_NAME="${BUNDLE_DIRECTORY_NAME}.tar.gz";

set -e;



# ----------------
echo -e "${PRTY} Testing server presence using... [   ping -c 1 ${TARGET_SRVR};   ]";
ping -c 1 ${TARGET_SRVR} >/dev/null || errorCannotPingRemoteServer "${TARGET_SRVR}";



# ----------------
# declare CNT_AGENTS=$(ps au -u $(whoami) | grep -v grep | grep -c ssh-agent);
# if [[ ${CNT_AGENTS} -lt 1  ]]; then
#   echo -e "${PRTY} Start up SSH agent... [   exec ssh-agent bash; ssh-add;  ]";
#   eval $(ssh-agent) > /dev/null;
# fi;

startSSHAgent;
echo -e "${PRTY} Adding keys to ssh-agent";
export KEYPAIR="${HOME}/.ssh/id_rsa";
ssh-add -l | grep -c ${KEYPAIR} >/dev/null || ssh-add ${KEYPAIR};

# # echo ${HABITAT_USER_SSH_PASS_PHRASE} ${HABITAT_USER_SSH_KEY_FILE};
# expect << EOF
#   spawn ssh-add ${HABITAT_USER_SSH_KEY_FILE}
#   expect "Enter passphrase"
#   send "${HABITAT_USER_SSH_PASS_PHRASE}\r"
#   expect eof
# EOF
echo -e "${PRTY} Added keys to ssh-agent";


# ----------------
echo -e "${PRTY} Testing settings file availability... [   ls \"${METEOR_SETTINGS_FILE}\"  ]";
if [[ "X${METEOR_SETTINGS_FILE}X" = "XX" ]]; then errorNoSettingsFileSpecified "null"; fi;
if [ "${METEOR_SETTINGS_FILE:0:1}" != "/" ]; then
  METEOR_SETTINGS_FILE="${CURR_DIR}/${METEOR_SETTINGS_FILE}";
fi;
if [ ! -f "${METEOR_SETTINGS_FILE}" ]; then errorNoSettingsFileSpecified "${METEOR_SETTINGS_FILE}"; fi;
if [ ! -s "${METEOR_SETTINGS_FILE}" ]; then warningEmptySettingsFileSpecified "${METEOR_SETTINGS_FILE}"; fi;

# ----------------
echo -e "${PRTY} Testing secrets file availability... [   ls \"${SOURCE_SECRETS_FILE}\"  ]";
if [[ "X${SOURCE_SECRETS_FILE}X" = "XX" ]]; then errorNoSecretsFileSpecified "null"; fi;
if [ ! -f "${SOURCE_SECRETS_FILE}" ]; then errorNoSecretsFileSpecified "${SOURCE_SECRETS_FILE}"; fi;
source ${SOURCE_SECRETS_FILE};


echo -e "${PRTY} SETUP_USER_PWD=${SETUP_USER_PWD}";
echo -e "${PRTY} HABITAT_USER_PWD=${HABITAT_USER_PWD}";
echo -e "${PRTY} HABITAT_USER_SSH_KEY_PUBL=${HABITAT_USER_SSH_KEY_PUBL}";

# ----------------
echo -e "${PRTY} Validating target host's user's sudo password... ";
if [[ "X${SETUP_USER_PWD}X" = "XX" ]]; then errorNoSuitablePasswordInFile "null"; fi;
[[ 0 -lt $(echo ${SETUP_USER_PWD} | grep -cE "^.{${PASSWORD_MINIMUM_LENGTH},}$") ]] ||  errorNoSuitablePasswordInFile ${SETUP_USER_PWD};


# ----------------
echo -e "${PRTY} Validating target host's habitat user's sudo password... ";
if [[ "X${HABITAT_USER_PWD}X" = "XX" ]]; then errorNoSuitablePasswordInFile "null"; fi;
[[ 0 -lt $(echo ${HABITAT_USER_PWD} | grep -cE "^.{${PASSWORD_MINIMUM_LENGTH},}$") ]] ||  errorNoSuitablePasswordInFile ${HABITAT_USER_PWD};



# ----------------
echo -e "${PRTY} Validating target host's MongoDB user's password... ";
if [[ "X${MONGODB_PWD}X" = "XX" ]]; then errorNoSuitablePasswordInFile "null"; fi;
[[ 0 -lt $(echo ${MONGODB_PWD} | grep -cE "^.{${PASSWORD_MINIMUM_LENGTH},}$") ]] ||  errorNoSuitablePasswordInFile ${MONGODB_PWD};


# ----------------
echo -e "${PRTY} Validating target host's PostgreSql user's password... ";
if [[ "X${PGRESQL_PWD}X" = "XX" ]]; then errorNoSuitablePasswordInFile "null"; fi;
[[ 0 -lt $(echo ${PGRESQL_PWD} | grep -cE "^.{${PASSWORD_MINIMUM_LENGTH},}$") ]] ||  errorNoSuitablePasswordInFile ${PGRESQL_PWD};



# ----------------
HABITAT_USER_SSH_KEY_FILE_NAME="authorized_key";
echo -e "${PRTY} Validating target host's user's SSH ${HABITAT_USER_SSH_KEY_FILE_NAME}... ";
if [[ "X${HABITAT_USER_SSH_KEY_PUBL}X" = "XX" ]]; then errorBadPathToSSHKey "null"; fi;
ssh-keygen -lvf ${HABITAT_USER_SSH_KEY_PUBL} > /tmp/kyfp.txt || errorBadPathToSSHKey ${HABITAT_USER_SSH_KEY_PUBL};
echo -e "${PRTY} Target's user's SSH key fingerprint...";
cat /tmp/kyfp.txt;


echo -e "${PRTY} Ready to push HabitatForMeteor deployment scripts to the target server,
       '${TARGET_SRVR}' prior to placing a RPC to install our Meteor project....";

echo -e "${PRTY} Inserting secrets and keys in, '${BUNDLE_NAME}'...";

chmod u-x,go-xrw ${METEOR_SETTINGS_FILE};
cp -p ${METEOR_SETTINGS_FILE} ${SCRIPTS_DIRECTORY};
chmod u+x,go-xrw ${SOURCE_SECRETS_FILE};
cp -p ${SOURCE_SECRETS_FILE} ${SCRIPTS_DIRECTORY};
cp -p ${HABITAT_USER_SSH_KEY_PUBL} ${SCRIPTS_DIRECTORY}/${HABITAT_USER_SSH_KEY_FILE_NAME};

echo -e "${PRTY} Bundling up the scripts as, '${BUNDLE_NAME}'...";
tar zcf ${BUNDLE_NAME}  --exclude='*.example' ${SCRIPTS_DIRECTORY};
chmod go-xrw ${BUNDLE_NAME};

TARGET_SETTINGS_FILE=$(basename "$METEOR_SETTINGS_FILE");
rm -f ./${SCRIPTS_DIRECTORY}/${TARGET_SETTINGS_FILE};

TARGET_SECRETS_FILE=$(basename "$SOURCE_SECRETS_FILE");
rm -f ./${SCRIPTS_DIRECTORY}/${TARGET_SECRETS_FILE};

echo -e "${PRTY} Pushing the bundle to account name '${SETUP_USER_UID}' on
      host '${TARGET_SRVR}' using SSH key...
       '~/.ssh/id_rsa'...";

scp -p ${BUNDLE_NAME} ${SETUP_USER_UID}@${TARGET_SRVR}:/home/${SETUP_USER_UID} >/dev/null || errorFailedToPushBundle;
rm -fr ${BUNDLE_NAME};

echo -e "${PRTY} Decompressing the bundle...";
ssh ${SETUP_USER_UID}@${TARGET_SRVR} tar zxf ${BUNDLE_NAME} --transform "s/target/${BUNDLE_DIRECTORY_NAME}/" >/dev/null || errorUnexpectedRPCResult;

echo -e "${PRTY} Setting up SUDO_ASK_PASS on the target...";
# echo "scp ./target/askPassMaker.sh ${SETUP_USER_UID}@${TARGET_SRVR}:~ >/dev/null || errorUnexpectedRPCResult;";
scp ./target/askPassMaker.sh ${SETUP_USER_UID}@${TARGET_SRVR}:~ >/dev/null || errorUnexpectedRPCResult;
# echo "ssh ${SETUP_USER_UID}@${TARGET_SRVR} \"source askPassMaker.sh; makeAskPassService '${SETUP_USER_UID}' '${SETUP_USER_PWD}';\" >/dev/null || errorUnexpectedRPCResult;";
ssh ${SETUP_USER_UID}@${TARGET_SRVR} "source askPassMaker.sh; makeAskPassService '${SETUP_USER_UID}' '${SETUP_USER_PWD}';" >/dev/null || errorUnexpectedRPCResult;

echo -e "${PRTY} Installing Habitat on the target...";
echo -e "ssh ${SETUP_USER_UID}@${TARGET_SRVR} \". .bash_login && ./${BUNDLE_DIRECTORY_NAME}/PrepareChefHabitatTarget.sh\" || errorUnexpectedRPCResult;";
# echo -e "PushInst line 276";
# exit 1;
ssh ${SETUP_USER_UID}@${TARGET_SRVR} ". .bash_login && ./${BUNDLE_DIRECTORY_NAME}/PrepareChefHabitatTarget.sh" || errorUnexpectedRPCResult;

# ----------------
if ! ssh-add -l | grep "${HABITAT_USER_SSH_KEY_PUBL%.pub}" &>/dev/null; then
  echo -e "${PRTY} Adding 'hab' user SSH key passphrase to ssh-agent";
  startSSHAgent;
  expect << EOF
    spawn ssh-add ${HABITAT_USER_SSH_KEY_PUBL%.pub}
    expect "Enter passphrase"
    send "${HABITAT_USER_SSH_PASS_PHRASE}\r"
    expect eof
EOF
fi;

# ----------------
echo -e "${PRTY} Testing SSH connection using... [   ssh ${HABITAT_USER}@${TARGET_SRVR} 'whoami';  ]";
if [[ "X${HABITAT_USER}X" = "XX" ]]; then errorNoUserAccountSpecified "null"; fi;
REMOTE_USER=$(ssh -qt -oBatchMode=yes -l ${HABITAT_USER} ${TARGET_SRVR} whoami) || errorCannotCallRemoteProcedure "${HABITAT_USER}@${TARGET_SRVR}";
[[ 0 -lt $(echo "${REMOTE_USER}" | grep -c "${HABITAT_USER}") ]] ||  errorUnexpectedRPCResult;

if [[ "${NON_STOP}" = "YES" ]]; then exit 0; fi;

pushd ${SCRIPTPATH}/../.. >/dev/null;
echo -e "\n${PRTY} Now you can upload your site certificates to a secure location in the 'hab' user's account.

     $(pwd)/habitat/scripts/PushSiteCertificateToTarget.sh \\
       \${TARGET_SRVR} \\
       \${SOURCE_SECRETS_FILE} \\
       \${SOURCE_CERTS_DIR} \\
       \${VIRTUAL_HOST_DOMAIN_NAME}
      Where :
        TARGET_SRVR is the host where the project will be installed.
        SOURCE_SECRETS_FILE is the path to a file of required passwords and keys for '${TARGET_SRVR}'.
        SOURCE_CERTS_DIR is the path to a directory of certificates holding the one for '${VIRTUAL_HOST_DOMAIN_NAME}'.
        VIRTUAL_HOST_DOMAIN_NAME identifies the target server domain name
            ( example source secrets file : /home/you/tools/HabitatForMeteor/habitat/scripts/target/secrets.sh.example )
Quitting...
$(date);
Done.
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
";

popd >/dev/null;
exit 0;

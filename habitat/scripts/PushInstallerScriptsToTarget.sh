#!/usr/bin/env bash
#

function usage() {
  echo -e "    Usage ::
     ${SCRIPTPATH}/PushInstallerScriptsToTarget.sh \\
                   \${TARGET_HOST} \\
                   \${TARGET_USER} \\
                   \${TARGET_SECRETS_FILE} \\
      Where :
        TARGET_HOST is the host where the project will be installed.
        TARGET_USER is a previously prepared 'sudoer' account on '\${TARGET_HOST}'.
        TARGET_SECRETS_FILE is the path to a file of required passwords and keys for '\${TARGET_HOST}'.
            ( example file : ${SCRIPTPATH}/target/secrest.sh.example )

  ";
  exit 1;
}

                  # \${RELEASE_TAG};
                  # \${TARGET_USER_PWD} \\
                  # \${HABITAT_USER_PWD} \\
                  # \${HABITAT_USER_SSH_KEY_PATH} \\
        # TARGET_USER_PWD is required for 'sudo' operations by '\${TARGET_USER}' account.
        # HABITAT_USER_PWD points to a file containing the password for the (to be created) Habitat user
        # HABITAT_USER_SSH_KEY_PATH  points to a file containing a SSH key to be used for future deployments.
        # RELEASE_TAG is the release to be installed on \${TARGET_HOST}.

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

declare MKR_SCRPT="";
function makeMakerScriptMaker() {
read -r -d '' MKR_SCRPT <<SAPMF
#!/usr/bin/env bash
#
export SUPWD="\${HOME}/.ssh/.supwd.sh";
echo -e '#!/usr/bin/env bash' > \${SUPWD};
echo -e "echo '${TARGET_USER_PWD}'" >> \${SUPWD};
chmod a+x,go-rwx \${SUPWD};
echo "Created ${SUPWD}";
SAPMF

}

set +e;

SCRIPT=$(readlink -f "$0");
SCRIPTPATH=$(dirname "$SCRIPT");
echo -e "\n${PRTY} Changing working location to ${SCRIPTPATH}.";
cd ${SCRIPTPATH};

. ./utils.sh;
loadSemVerScript;
. ./semver.sh


PRTY="PDStT  ==> ";

TARGET_SERVER=${1};
TARGET_USER=${2};
TARGET_SECRETS_FILE=${3};


PASSWORD_MINIMUM_LENGTH=4;
# TARGET_USER_PWD=${3};
# HABITAT_USER_PWD=${4};
# HABITAT_USER_SSH_KEY_PATH=${5};
# RELEASE_TAG=${6};

echo -e "${PRTY} TARGET_SERVER=${TARGET_SERVER}";
echo -e "${PRTY} TARGET_USER=${TARGET_USER}";
echo -e "${PRTY} TARGET_SECRETS_FILE=${TARGET_SECRETS_FILE}";

# echo -e "${PRTY} RELEASE_TAG=${RELEASE_TAG}";

SCRIPTS_DIRECTORY="target";
BUNDLE_DIRECTORY_NAME="HabitatPkgInstallerScripts";
BUNDLE_NAME="${BUNDLE_DIRECTORY_NAME}.tar.gz";

set +e;



# ----------------
echo -e "${PRTY} Testing server presence using... [   ping -c 1 ${TARGET_SERVER};   ]";
ping -c 1 ${TARGET_SERVER} >/dev/null || errorCannotPingRemoteServer "${TARGET_SERVER}";



# ----------------
echo -e "${PRTY} Start up SSH agent... [   exec ssh-agent bash; ssh-add;  ]";
eval $(ssh-agent) > /dev/null;
ssh-add > /dev/null;


# ----------------
echo -e "${PRTY} Testing SSH using... [   ssh ${TARGET_USER}@${TARGET_SERVER} 'whoami';  ]";
if [[ "X${TARGET_USER}X" = "XX" ]]; then errorNoUserAccountSpecified "null"; fi;
REMOTE_USER=$(ssh -qt -oBatchMode=yes -l ${TARGET_USER} ${TARGET_SERVER} whoami) || errorCannotCallRemoteProcedure "${TARGET_USER}@${TARGET_SERVER}";
[[ 0 -lt $(echo "${REMOTE_USER}" | grep -c "${TARGET_USER}") ]] ||  errorUnexpectedRPCResult;



# ----------------
echo -e "${PRTY} Testing secrets file availability... [   ls \"${TARGET_SECRETS_FILE}\"  ]";
if [[ "X${TARGET_SECRETS_FILE}X" = "XX" ]]; then errorNoSecretsFileSpecified "null"; fi;
if [ ! -f "${TARGET_SECRETS_FILE}" ]; then errorNoSecretsFileSpecified "${TARGET_SECRETS_FILE}"; fi;
source ${TARGET_SECRETS_FILE};


echo -e "${PRTY} TARGET_USER_PWD=${TARGET_USER_PWD}";
echo -e "${PRTY} HABITAT_USER_PWD=${HABITAT_USER_PWD}";
echo -e "${PRTY} HABITAT_USER_SSH_KEY_PATH=${HABITAT_USER_SSH_KEY_PATH}";



# ----------------
echo -e "${PRTY} Validating target host's user's sudo password... ";
if [[ "X${TARGET_USER_PWD}X" = "XX" ]]; then errorNoSuitablePasswordInFile "null"; fi;
[[ 0 -lt $(echo ${TARGET_USER_PWD} | grep -cE "^.{${PASSWORD_MINIMUM_LENGTH},}$") ]] ||  errorNoSuitablePasswordInFile ${TARGET_USER_PWD};



# ----------------
echo -e "${PRTY} Validating target host's habitat user's sudo password... ";
if [[ "X${HABITAT_USER_PWD}X" = "XX" ]]; then errorNoSuitablePasswordInFile "null"; fi;
[[ 0 -lt $(echo ${HABITAT_USER_PWD} | grep -cE "^.{${PASSWORD_MINIMUM_LENGTH},}$") ]] ||  errorNoSuitablePasswordInFile ${HABITAT_USER_PWD};


# ----------------
echo -e "${PRTY} Validating target host's MongoDB user's password... ";
if [[ "X${MONGODB_PWD}X" = "XX" ]]; then errorNoSuitablePasswordInFile "null"; fi;
[[ 0 -lt $(echo ${MONGODB_PWD} | grep -cE "^.{${PASSWORD_MINIMUM_LENGTH},}$") ]] ||  errorNoSuitablePasswordInFile ${MONGODB_PWD};

# DEFAULT_SSH_KEY="${HOME}/.ssh/id_rsa.pub";
# ssh-keygen -lvf ${DEFAULT_SSH_KEY} > /tmp/kyfp.txt || errorBadPathToSSHKey ${DEFAULT_SSH_KEY};
# echo -e "${PRTY} Default SSH key fingerprint...";
# cat /tmp/kyfp.txt;



# ----------------
HABITAT_USER_SSH_KEY_FILE_NAME="authorized_key";
echo -e "${PRTY} Validating target host's user's SSH ${HABITAT_USER_SSH_KEY_FILE_NAME}... ";
if [[ "X${HABITAT_USER_SSH_KEY_PATH}X" = "XX" ]]; then errorBadPathToSSHKey "null"; fi;
ssh-keygen -lvf ${HABITAT_USER_SSH_KEY_PATH} > /tmp/kyfp.txt || errorBadPathToSSHKey ${HABITAT_USER_SSH_KEY_PATH};
echo -e "${PRTY} Target's user's SSH key fingerprint...";
cat /tmp/kyfp.txt;


# semverGT ${RELEASE_TAG}  "0.0.0a0" || errorInvalidReleaseTag;


echo -e "${PRTY} Ready to push HabitatForMeteor deployment scripts to the target server,
       '${TARGET_SERVER}' prior to placing a RPC to install our Meteor project....";
# version ${RELEASE_TAG}...";

# HABITAT_USER_PWD_FILE_NAME="HabUserPwd.txt";
# echo ${HABITAT_USER_PWD} > ${SCRIPTS_DIRECTORY}/${HABITAT_USER_PWD_FILE_NAME};
# TARGET_SECRETS_FILE_NAME=$(basename "$TARGET_SECRETS_FILE");

echo -e "${PRTY} Inseting secrets and keys in, '${BUNDLE_NAME}'...";
chmod u+x,go-xrw ${TARGET_SECRETS_FILE};
cp -p ${TARGET_SECRETS_FILE} ${SCRIPTS_DIRECTORY};
cp -p ${HABITAT_USER_SSH_KEY_PATH} ${SCRIPTS_DIRECTORY}/${HABITAT_USER_SSH_KEY_FILE_NAME};


echo -e "${PRTY} Bundling up the scripts as, '${BUNDLE_NAME}'...";
tar zcf ${BUNDLE_NAME} ${SCRIPTS_DIRECTORY};
chmod go-xrw ${BUNDLE_NAME};

rm -f ${SCRIPTS_DIRECTORY}/${TARGET_SECRETS_FILE};

echo -e "${PRTY} Pushing the bundle to account name '${TARGET_USER}' on
      host '${TARGET_SERVER}' using SSH key...
       '~/.ssh/id_rsa'...";

scp -p ${BUNDLE_NAME} ${TARGET_USER}@${TARGET_SERVER}:/home/${TARGET_USER} >/dev/null || errorFailedToPushBundle;


echo -e "${PRTY} Decompressing the bundle...";
ssh ${TARGET_USER}@${TARGET_SERVER} tar zxf ${BUNDLE_NAME} --transform "s/target/${BUNDLE_DIRECTORY_NAME}/" >/dev/null || errorUnexpectedRPCResult;

echo -e "${PRTY} Setting up SUDO_ASK_PASS on the target...";
# SUDO_ASK_PASS_MAKER_SCRIPT="/tmp/PrepareSudoAskPass.sh";

makeMakerScriptMaker;
ssh ${TARGET_USER}@${TARGET_SERVER} "${MKR_SCRPT}" >/dev/null || errorUnexpectedRPCResult;

echo -e "${PRTY} Installing Habitat on the target...";
ssh ${TARGET_USER}@${TARGET_SERVER} "./${BUNDLE_DIRECTORY_NAME}/PrepareChefHabitatTarget.sh" || errorUnexpectedRPCResult;

pushd ${SCRIPTPATH}/../.. >/dev/null;
echo -e "\n${PRTY} Your server is ready for HabitatForMeteor.
            Next step : from any machine with passwordless SSH access to the 
            the server '${TARGET_SERVER}' you can now run...

      ssh ${TARGET_USER}@${TARGET_SERVER} "~/${BUNDLE_DIRECTORY_NAME}/habitat_package_runner.sh \${YOUR_ORG} \${YOUR_PKG} \${semver} \${timestamp}";
      # Only the first two arguments are obligatory. The last two permit specifying older releases.

Quitting...
$(date);
Done.
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
";

popd >/dev/null;
exit;

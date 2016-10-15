#!/usr/bin/env bash
#

function usage() {
  echo -e "    Usage ::
     ${SCRIPTPATH}/PushInstallerScriptsToTarget.sh \\
                   \${TARGET_HOST} \\
                   \${TARGET_USER} \\
                   \${TARGET_USER_PWD} \\
                   \${HABITAT_USER_PWD_FILE_PATH} \\
                   \${HABITAT_USER_SSH_KEY_PATH} \\
                   \${RELEASE_TAG};
      Where :
        TARGET_SERVER is the host where the project will be installed.
        TARGET_USER is a previously prepared 'sudoer' account on '\${TARGET_HOST}'.
        TARGET_USER_PWD is required for 'sudo' operations by '\${TARGET_USER}' account.
        HABITAT_USER_PWD_FILE_PATH points to a file containing the password for the Habitat user, which will be created,
        HABITAT_USER_SSH_KEY_PATH  points to a file containing a SSH key to be used for future deployments.
        RELEASE_TAG is the release to be installed on \${TARGET_HOST}.
  ";
  exit 1;
}

function errorInvalidReleaseTag() {
  echo -e "\n\n    *** Invalid release tag ***";
  usage;
}

function errorCannotPingRemoteServer() {
  echo -e "\n\n    *** Cannot ping remote server ***";
  usage;
}

function errorCannotCallRemoteProcedure() {
  echo -e "\n\n    *** Cannot call remote procedure ***";
  usage;
}

function errorBadPathToSSHKey() {
  echo -e "\n\n    *** No valid SSH key found at ${1} ***";
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
  echo -e "\n\n    *** No viable password found in the file, ${1} ***
                   -- Minimum size is 8 chars --";
  usage;
}

function makeMakerScriptMaker() {
  cat << SAPMF > ${1}
#!/usr/bin/env bash
#
echo -e '#!/usr/bin/env bash' > \${HOME}/.supwd.sh;
echo -e "echo '${TARGET_USER_PWD}'" >> \${HOME}/.supwd.sh;
chmod a+x,go-rw \${HOME}/.supwd.sh;
echo "Created ${HOME}/.supwd.sh";
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
TARGET_USER_PWD=${3};
HABITAT_USER_PWD_FILE_PATH=${4};
HABITAT_USER_SSH_KEY_PATH=${5};
RELEASE_TAG=${6};

echo -e "${PRTY} TARGET_SERVER=${TARGET_SERVER}";
echo -e "${PRTY} TARGET_USER=${TARGET_USER}";
echo -e "${PRTY} TARGET_USER_PWD=${TARGET_USER_PWD}";
echo -e "${PRTY} HABITAT_USER_PWD_FILE_PATH=${HABITAT_USER_PWD_FILE_PATH}";
echo -e "${PRTY} HABITAT_USER_SSH_KEY_PATH=${HABITAT_USER_SSH_KEY_PATH}";
echo -e "${PRTY} RELEASE_TAG=${RELEASE_TAG}";

SCRIPTS_DIRECTORY="target";
BUNDLE_NAME="HabitatPkgInstallerScripts.tar.gz";

## [[ 0 -lt $(cat ${TARGET_USER_PWD} | grep -cE "^.{8,}$") ]] ||  errorUnsuitablePassword ${TARGET_USER_PWD};

[[ 0 -lt $(cat ${HABITAT_USER_PWD_FILE_PATH} | grep -cE "^.{8,}$") ]] ||  errorUnsuitablePassword ${HABITAT_USER_PWD_FILE_PATH};

semverGT ${RELEASE_TAG}  "0.0.0a0" || errorInvalidReleaseTag;

ping -c 1 ${TARGET_SERVER} >/dev/null || errorCannotPingRemoteServer;

# DEFAULT_SSH_KEY="${HOME}/.ssh/id_rsa.pub";
# ssh-keygen -lvf ${DEFAULT_SSH_KEY} > /tmp/kyfp.txt || errorBadPathToSSHKey ${DEFAULT_SSH_KEY};
# echo -e "${PRTY} Default SSH key fingerprint...";
# cat /tmp/kyfp.txt;

ssh-keygen -lvf ${HABITAT_USER_SSH_KEY_PATH} > /tmp/kyfp.txt || errorBadPathToSSHKey ${HABITAT_USER_SSH_KEY_PATH};
echo -e "${PRTY} Habitat user's SSH key fingerprint...";
cat /tmp/kyfp.txt;


REMOTE_USER=$(ssh -qt ${TARGET_USER}@${TARGET_SERVER} whoami) || errorCannotCallRemoteProcedure;
[[ 0 -lt $(echo "${REMOTE_USER}" | grep -c "${TARGET_USER}") ]] ||  errorUnexpectedRPCResult;

echo -e "${PRTY} Ready to push deployment scripts to target server,
       '${TARGET_SERVER}' prior to placing a RPC to install
       project version ${RELEASE_TAG}...";

echo -e "${PRTY} Bundling up the scripts as, '${BUNDLE_NAME}'...";
HABITAT_USER_PWD_FILE_NAME="HabUserPwd.txt";
HABITAT_USER_SSH_KEY_NAME="authorized_key";
cp ${HABITAT_USER_PWD_FILE_PATH} ${SCRIPTS_DIRECTORY}/${HABITAT_USER_PWD_FILE_NAME};
cp ${HABITAT_USER_SSH_KEY_PATH} ${SCRIPTS_DIRECTORY}/${HABITAT_USER_SSH_KEY_NAME};
chmod go-rw ${SCRIPTS_DIRECTORY}/${HABITAT_USER_PWD_FILE_NAME};


tar zcf ${BUNDLE_NAME} ${SCRIPTS_DIRECTORY};
rm -f ${SCRIPTS_DIRECTORY}/${HABITAT_USER_PWD_FILE_NAME};

echo -e "${PRTY} Pushing the bundle to account name '${TARGET_USER}' on
      host '${TARGET_SERVER}' using SSH key...
       '~/.ssh/id_rsa'...";
scp ${BUNDLE_NAME} ${TARGET_USER}@${TARGET_SERVER}:/home/${TARGET_USER} >/dev/null || errorFailedToPushBundle;

echo -e "${PRTY} Decompressing the bundle...";
ssh ${TARGET_USER}@${TARGET_SERVER} tar zxf ${BUNDLE_NAME} --transform 's/target/HabitatPkgInstallerScripts/' >/dev/null || errorUnexpectedRPCResult;

echo -e "${PRTY} Setting up SUDO_ASK_PASS on the target...";
SUDO_ASK_PASS_MAKER_SCRIPT="/tmp/PrepareSudoAskPass.sh";
makeMakerScriptMaker ${SUDO_ASK_PASS_MAKER_SCRIPT};
ssh ${TARGET_USER}@${TARGET_SERVER} 'bash -s' < ${SUDO_ASK_PASS_MAKER_SCRIPT} >/dev/null || errorUnexpectedRPCResult;

echo -e "${PRTY} Installing Habitat on the target...";
ssh ${TARGET_USER}@${TARGET_SERVER} ./HabitatPkgInstallerScripts/PrepareChefHabitatTarget.sh || errorUnexpectedRPCResult;




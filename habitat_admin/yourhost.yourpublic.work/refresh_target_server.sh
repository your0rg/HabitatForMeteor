#!/usr/bin/env bash
#
SCRIPT=$(readlink -f "$0");
SCRIPTPATH=$(dirname "$SCRIPT");  # Where this script resides
SCRIPTNAME=$(basename "$SCRIPT"); # This script's name

source ${SCRIPTPATH}/env_vars.sh;
source ${SCRIPTPATH}/../standard_env_vars.sh;
source ${HABITAT4METEOR_SCRIPTS}/admin_utils.sh;
source ${SOURCE_SECRETS_FILE};

startSSHAgent;
AddSSHkeyToAgent "${HABITAT_USER_SSH_KEY_FILE}" "${HABITAT_USER_SSH_PASS_PHRASE}";
ssh ${HABITAT_USER}@${TARGET_SRVR} ". ~/.bash_login && ~/HabitatPkgInstallerScripts/HabitatPackageRunner.sh \"${VIRTUAL_HOST_DOMAIN_NAME}\" \"${YOUR_ORG}\" \"${YOUR_PKG}\" \"${semver}\" \"${timestamp}\"";

echo -e "

______________________________________________________________________
";
exit 0;

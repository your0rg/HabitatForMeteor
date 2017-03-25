#!/usr/bin/env bash
#
SCRIPT=$(readlink -f "$0");
SCRIPTPATH=$(dirname "$SCRIPT");  # Where this script resides
SCRIPTNAME=$(basename "$SCRIPT"); # This script's name

export VHOST_ENV_VARS="${SCRIPTPATH}/vhost_env_vars.sh";

source ${SCRIPTPATH}/env_vars.sh;
source ${SCRIPTPATH}/../standard_env_vars.sh;
source ${HABITAT4METEOR_SCRIPTS}/admin_utils.sh;
source ${SOURCE_SECRETS_FILE};

which expect  >/dev/null || sudo apt-get -y install expect;

PRETTY="PRP_SRV :: ";

startSSHAgent;

makeTargetAuthorizedHostSshKeyIfNotExist \
     "${HABITAT_USER_SSH_KEY_COMMENT}" \
     "${HABITAT_USER_SSH_PASS_PHRASE}" \
     "${HABITAT_USER_SSH_KEY_PATH}" \
     "${HABITAT_USER_SSH_KEY_FILE}";
AddSSHkeyToAgent "${HABITAT_USER_SSH_KEY_FILE}" "${HABITAT_USER_SSH_PASS_PHRASE}";


echo -e "${PRETTY}Verifying target server rear access : ${TARGET_SRVR}.";
ping -c 4 ${TARGET_SRVR};

echo -e "${PRETTY}Verifying target server rear access : ${VIRTUAL_HOST_DOMAIN_NAME}.";
ping -c 4 ${VIRTUAL_HOST_DOMAIN_NAME};

#
makeSSH_Config_File;
addSSH_Config_Identity "${SETUP_USER_UID}" "${TARGET_SRVR}" "${YOUR_TARGET_SRVR_SSH_KEY_FILE}";
addSSH_Config_Identity "${HABITAT_USER}" "${TARGET_SRVR}" "${HABITAT_USER_SSH_KEY_FILE}";
echo -e "${PRETTY}SSH config file prepared.";

echo -e "${PRETTY}Testing SSH to host '${SETUP_USER_UID}' '${TARGET_SRVR}'."
ssh -t -oStrictHostKeyChecking=no -oBatchMode=yes -l "${SETUP_USER_UID}" "${TARGET_SRVR}" whoami || exit 1;
echo -e "${PRETTY}Success: SSH to host '${SETUP_USER_UID}' '${TARGET_SRVR}'.";

# sh template.settings.json.sh > ${METEOR_SETTINGS_FILE};
# echo -e "${PRETTY}Generated Meteor settings file.";
# cat ${METEOR_SETTINGS_FILE};

${HABITAT4METEOR_SCRIPTS}/PushInstallerScriptsToTarget.sh \
    "${TARGET_SRVR}" \
    "${SETUP_USER_UID}" \
    "${SOURCE_SECRETS_FILE}" \
    "${VHOST_ENV_VARS}";
#     "${METEOR_SETTINGS_FILE}" \
echo -e "${PRETTY}Pushed installer scripts to host :: '${TARGET_SRVR}'.";

ssh -t -oStrictHostKeyChecking=no -oBatchMode=yes -l "${HABITAT_USER}" "${TARGET_SRVR}" whoami;
echo -e "${PRETTY}Tested 'hab' user SSH to host '${HABITAT_USER}' '${TARGET_SRVR}'.";

ssh ${HABITAT_USER}@${TARGET_SRVR} ". ~/.bash_login && sudo -A touch /opt/delete_me" || exit 1;
echo -e "${PRETTY}Tested sudo ASK_PASS for '${HABITAT_USER}'@'${TARGET_SRVR}'.";


makeImitation_LetsEncrypt_Cert \
    "${VHOST_CERT_PASSPHRASE}" \
    "${VHOST_SUBJECT}" \
    "${SOURCE_CERTS_DIR}"; #  Includes the VHost Domain Name !!!

echo -e "${PRETTY}Created new site cert for  :: '${VIRTUAL_HOST_DOMAIN_NAME}'.";

${HABITAT4METEOR_SCRIPTS}/PushSiteCertificateToTarget.sh \
    "${TARGET_SRVR}" \
    "${SOURCE_SECRETS_FILE}" \
    "${SOURCE_CERTS_DIR}" \
    "${VIRTUAL_HOST_DOMAIN_NAME}" \
    "${VHOST_ENV_VARS}";

ssh ${HABITAT_USER}@${TARGET_SRVR} ". ~/.bash_login && ~/HabitatPkgInstallerScripts/HabitatPackageRunner.sh \"${VIRTUAL_HOST_DOMAIN_NAME}\" \"${YOUR_ORG}\" \"${YOUR_PKG}\" \"${semver}\" \"${timestamp}\"";


echo -e "      ** Done **

ssh ${HABITAT_USER}@${TARGET_SRVR} \". .bash_login && sudo -A journalctl -n 1000 -fb -u ${YOUR_ORG}_${YOUR_PKG}.service\";
ssh ${HABITAT_USER}@${TARGET_SRVR} \". .bash_login && sudo -A systemctl stop ${YOUR_ORG}_${YOUR_PKG}.service\";

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";
echo -e "${PRETTY} SOURCE_CERTS_DIR : ${SOURCE_CERTS_DIR}.";
echo -e "${PRETTY} VHOST_SUBJECT : ${VHOST_SUBJECT}.";
echo -e "${PRETTY} VHOST_CERT_PASSPHRASE : ${VHOST_CERT_PASSPHRASE}.";
echo -e "${PRETTY}  : ${PRETTY}.";
# echo -e "${PRETTY} METEOR_SETTINGS_FILE : ${METEOR_SETTINGS_FILE}.";
echo -e "${PRETTY} VHOST_ENV_VARS : ${VHOST_ENV_VARS}.";
echo -e "${PRETTY} TARGET_SRVR : ${TARGET_SRVR}.";
echo -e "${PRETTY} VIRTUAL_HOST_DOMAIN_NAME : ${VIRTUAL_HOST_DOMAIN_NAME}.";
echo -e "${PRETTY} HABITAT_USER_SSH_KEY_PATH : ${HABITAT_USER_SSH_KEY_PATH}.";
echo -e "${PRETTY} HABITAT_USER_SSH_KEY_COMMENT : ${HABITAT_USER_SSH_KEY_COMMENT}.";
echo -e "${PRETTY} HABITAT_USER_SSH_PASS_PHRASE : ${HABITAT_USER_SSH_PASS_PHRASE}.";
echo -e "${PRETTY} HABITAT_USER_SSH_KEY_FILE : ${HABITAT_USER_SSH_KEY_FILE}.";
echo -e "${PRETTY} HABITAT_USER : ${HABITAT_USER}.";
echo -e "${PRETTY} SOURCE_SECRETS_FILE : ${SOURCE_SECRETS_FILE}.";
echo -e "${PRETTY} YOUR_TARGET_SRVR_SSH_KEY_FILE : ${YOUR_TARGET_SRVR_SSH_KEY_FILE}.";
echo -e "${PRETTY} SETUP_USER_UID : ${SETUP_USER_UID}.";
echo -e "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";
exit;

#!/usr/bin/env bash
#

export SSH_PATH="${HOME}/.ssh";
export SECRETS_PATH="${SSH_PATH}/hab_vault";
export HAB_USER_SECRETS_DIR="habitat_user";
export YOUR_TARGET_SRVR_SSH_KEY_FILE="${SSH_PATH}/id_rsa";

export SSH_CONF_FILE="${SSH_PATH}/config";

export HABITAT_USER="hab";

export HABITAT4METEOR="${HOME}/tools/HabitatForMeteor";
export HABITAT4METEOR_SCRIPTS="${HABITAT4METEOR}/habitat/scripts";

export VHOSTS_SECRETS_PATH="${SECRETS_PATH}/${VIRTUAL_HOST_DOMAIN_NAME}";
export SOURCE_SECRETS_FILE="${VHOSTS_SECRETS_PATH}/secrets.sh";
export METEOR_SETTINGS_FILE="${VHOSTS_SECRETS_PATH}/settings.json";

export HAB_USER_SECRETS_PATH="${VHOSTS_SECRETS_PATH}/${HAB_USER_SECRETS_DIR}";
export HABITAT_USER_SSH_KEY_PATH="${HAB_USER_SECRETS_PATH}";
export HABITAT_USER_SSH_KEY_FILE="${HABITAT_USER_SSH_KEY_PATH}/id_rsa";
export HABITAT_USER_SSH_KEY_PUBL="${HABITAT_USER_SSH_KEY_PATH}/id_rsa.pub";

export SOURCE_CERTS_DIR="${VHOSTS_SECRETS_PATH}";
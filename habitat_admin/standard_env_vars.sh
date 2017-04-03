#!/usr/bin/env bash
#

export SSH_PATH="${HOME}/.ssh";
export SECRETS_PATH="${SSH_PATH}/hab_vault";
export HAB_USER_SECRETS_DIR="habitat_user";
export YOUR_TARGET_SRVR_SSH_KEY_FILE="${SSH_PATH}/id_rsa";

export SSH_CONF_FILE="${SSH_PATH}/config";

export HABITAT_USER="hab";

export HABITAT4METEOR="/home/yourself/tools/HabitatForMeteor";
export HABITAT4METEOR_SCRIPTS="${HABITAT4METEOR}/habitat/scripts";

export VHOST_SECRETS_PATH="${SECRETS_PATH}/${VIRTUAL_HOST_DOMAIN_NAME}";
export VHOST_SECRETS_FILE="${VHOST_SECRETS_PATH}/secrets.sh";

export HAB_USER_SECRETS_PATH="${VHOST_SECRETS_PATH}/${HAB_USER_SECRETS_DIR}";
export HABITAT_USER_SSH_KEY_PATH="${HAB_USER_SECRETS_PATH}";
export HABITAT_USER_SSH_KEY_FILE="${HABITAT_USER_SSH_KEY_PATH}/id_rsa";
export HABITAT_USER_SSH_KEY_PUBL="${HABITAT_USER_SSH_KEY_PATH}/id_rsa.pub";

export SOURCE_CERTS_DIR="${VHOST_SECRETS_PATH}/tls";

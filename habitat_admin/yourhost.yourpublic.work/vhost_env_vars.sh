## Nginx certificate dependencies
export HAB_VAULT="/home/hab/.ssh/hab_vault";

export SECRETS="${HAB_VAULT}/${VIRTUAL_HOST_DOMAIN_NAME}";
export CERT_EMAIL="yourself@yourpublic.work";
export DIFFIE_HELLMAN_DIR="/etc/ssl/private";

export ENABLE_GLOBAL_CERT_PASSWORD_FILE="global_ssl_password_file = \"\"";

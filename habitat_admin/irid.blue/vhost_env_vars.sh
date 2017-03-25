## Nginx certificate dependencies
# the path on the remote server where Nginx should look for SSL cert passwords
export GLOBAL_CERT_PASSWORD_FILE="/home/hab/.ssh/hab_vault/global.pass";

# A string to insert in the Nginx config that will enable
export ENABLE_GLOBAL_CERT_PASSWORD_FILE="global_ssl_password_file = \"ssl_password_file ${GLOBAL_CERT_PASSWORD_FILE};\"";

export IRID_BLUE_CERT_PATH="/home/hab/.ssh/hab_vault/irid.blue"
export YOUR_2ND_DOMAIN_CERT_PATH="/home/hab/.ssh/hab_vault/your.2nd.domain";
export YOUR_3RD_DOMAIN_CERT_PATH="/home/hab/.ssh/hab_vault/your.3rd.domain";

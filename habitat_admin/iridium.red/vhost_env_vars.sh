## Nginx certificate dependencies
# the path on the remote server where Nginx should look for SSL cert passwords
export GLOBAL_CERT_PASSWORD_FILE="/home/hab/.ssh/hab_vault/global.pass";

# A string to insert in the Nginx config that will enable
export ENABLE_GLOBAL_CERT_PASSWORD_FILE="global_ssl_password_file = \"ssl_password_file ${GLOBAL_CERT_PASSWORD_FILE};\"";

# The paths to the location of your signed site certificates.
# This is not intended for production use, but for simplifying initial start up and testing
#   example ::
#     export IRIDIUM_BLUE_CERT_PATH="/home/hab/.ssh/hab_vault/iridium.red"
#   where ::
#     The shell variable name must be the domain name in upper case, with 'dot' replaced by 'underscore' and must have the suffix "CERT_PATH".
#     The directory "/home/hab/.ssh/hab_vault/iridium.red" must contain three files named exactly :
#       - server.crt -- the certificate
#       - server.key -- the certificate decryption key
#       -  server.pp -- the certificate decryption key pass phrase in plain text
#
# To be clear, all the files, in each directory, will be named server.(suffix), so only the
# directory name will distinguish them.   Obviously a hack.  Should change in the future.

export IRIDIUM_RED_CERT_PATH="/home/hab/.ssh/hab_vault/iridium.red"
export YOUR_2ND_DOMAIN_CERT_PATH="/home/hab/.ssh/hab_vault/your.2nd.domain";
export YOUR_3RD_DOMAIN_CERT_PATH="/home/hab/.ssh/hab_vault/your.3rd.domain";

## Nginx certificate dependencies
export HAB_VAULT="/home/hab/.ssh/hab_vault";

# the path on the remote server where Nginx should look for SSL cert passwords
export GLOBAL_CERT_PASSWORD_FILE="${HAB_VAULT}/global.pass";

# A string to insert in the Nginx config that will enable
export ENABLE_GLOBAL_CERT_PASSWORD_FILE="global_ssl_password_file = \"ssl_password_file ${GLOBAL_CERT_PASSWORD_FILE};\"";

# The paths to the location of your signed site certificates.
# This is not intended for production use, but for simplifying initial start up and testing
#   example ::
#     export MOON_PLANET_SUN_CERT_PATH="${HAB_VAULT}/moon.planet.sun/tls/"
#   where ::
#     The shell variable name must be the domain name in upper case, with 'dot' replaced by 'underscore' and must have the suffix "CERT_PATH".
#     The directory "${HAB_VAULT}/moon.planet.sun" must contain three files named exactly :
#       - cert.pem    -- the certificate
#       - privkey.pem -- the certificate decryption key
#       - cert.pp     -- the certificate decryption key pass phrase in plain text
#
# To be clear, all the files, in each directory, will be named as above, so only the
# directory name will distinguish them.

export MOON_PLANET_SUN_SECRETS="${HAB_VAULT}/moon.planet.sun";
export MOON_PLANET_SUN_CERT_PATH="${MOON_PLANET_SUN_SECRETS}/tls";

export YOUR_2ND_DOMAIN_SECRETS="${HAB_VAULT}/your.2nd.domain";
export YOUR_2ND_DOMAIN_CERT_PATH="${YOUR_2ND_DOMAIN_SECRETS}/tls";

export YOUR_3RD_DOMAIN_SECRETS="${HAB_VAULT}/your.3rd.domain";
export YOUR_3RD_DOMAIN_CERT_PATH="${YOUR_3RD_DOMAIN_SECRETS}/tls";

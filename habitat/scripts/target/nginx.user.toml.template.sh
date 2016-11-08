#!/bin/bash

cat <<EONUTT
[http]
www-data = "/usr/share/nginx/www/"
${ENABLE_GLOBAL_CERT_PASSWORD_FILE}

[http.include]
additional_servers = "include /etc/nginx/sites-enabled/*;"
EONUTT

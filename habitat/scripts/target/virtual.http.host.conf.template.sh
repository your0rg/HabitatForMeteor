#!/bin/bash

cat <<EOVHCT
server {
  listen 80 default_server;
  server_name ${VIRTUAL_HOST_DOMAIN_NAME};

  access_log /var/log/nginx/${VIRTUAL_HOST_DOMAIN_NAME}/access.log;
  error_log  /var/log/nginx/${VIRTUAL_HOST_DOMAIN_NAME}/error.log warn;

  server_name_in_redirect off;

  root  /etc/nginx/www-data;
}
EOVHCT

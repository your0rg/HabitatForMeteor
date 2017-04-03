#!/bin/bash

cat <<EOVHSCT
## Virtual host configuration file

server {

  listen   80;
  server_name ${VIRTUAL_HOST_DOMAIN_NAME};
  return   301 https://\$server_name\$request_uri;
}

server {

  listen   443;
  server_name ${VIRTUAL_HOST_DOMAIN_NAME};

  access_log /var/log/nginx/${VIRTUAL_HOST_DOMAIN_NAME}/access.log;
  error_log  /var/log/nginx/${VIRTUAL_HOST_DOMAIN_NAME}/error.log warn;

  root /usr/share/nginx/org/www;  # IGNORED
  index index.html index.htm;     # IGNORED

  ssl on;
  ssl_certificate     /etc/letsencrypt/live/${VIRTUAL_HOST_DOMAIN_NAME}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${VIRTUAL_HOST_DOMAIN_NAME}/privkey.pem;

  ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_prefer_server_ciphers on;
  ssl_session_cache shared:SSL:10m;
  ssl_dhparam /etc/ssl/private/dhparams_4096.pem;

  location ^~ /public/ {
    autoindex on;
    root /etc/nginx/www-data;
  }

  location / {

    proxy_pass http://localhost:3000;              # How Nginx finds Meteor app
#                                  see -- http://wiki.nginx.org/HttpProxyModule#proxy_pass

    add_header Cache-Control no-cache;

    proxy_set_header X-Real-IP \$remote_addr;       # http://wiki.nginx.org/HttpProxyModule
    proxy_set_header Host \$host;                   # pass the host header
    proxy_http_version 1.1;                        # recommended with keepalive connections -
#                                  see -- http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_http_version

    # WebSocket proxying - from http://nginx.org/en/docs/http/websocket.html
    proxy_set_header Upgrade \$http_upgrade;        # allow websockets
    proxy_set_header Connection "upgrade";
#  FIXME:::  proxy_set_header X-Forwarded-For \$realip_remote_addr; # preserve client IP


  }

}
EOVHSCT

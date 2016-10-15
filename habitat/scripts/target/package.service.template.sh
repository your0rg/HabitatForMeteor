#!/bin/bash

cat <<END
[Unit]
Description=A Habitat Execution for MongoDB, Meteor (under NodeJS) and Nginx.
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Environment="LC_ALL=C"
Type=simple
PIDFile=/run/habitat_${YOUR_ORG}_${YOUR_PKG}.pid
ExecStart=/bin/hab-director start -c /hab/svc/${YOUR_ORG}/${YOUR_PKG}/${YOUR_ORG}_${YOUR_PKG}.toml
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true
User=root
Group=hab

[Install]
WantedBy=multi-user.target
END

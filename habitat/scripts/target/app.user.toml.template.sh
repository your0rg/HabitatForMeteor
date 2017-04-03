#!/bin/bash

cat <<EOAUTT
mongo_url = "mongodb://meteor:${MONGODB_PWD}@localhost:27017/${YOUR_PKG}"
root_protocol = "https"
root_port = ""
root_domain = "${VIRTUAL_HOST_DOMAIN_NAME}"
root_url = "https://${VIRTUAL_HOST_DOMAIN_NAME}/"
EOAUTT

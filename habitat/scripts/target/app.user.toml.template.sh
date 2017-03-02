#!/bin/bash

cat <<EOAUTT
mongo_url = "mongodb://meteor:${MONGODB_PWD}@localhost:27017/${YOUR_PKG}"
root_url = "https://${VIRTUAL_HOST_DOMAIN_NAME}/"
EOAUTT

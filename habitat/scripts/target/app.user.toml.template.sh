#!/bin/bash

cat <<EOAUTT
mongo_url = "mongodb://meteor:${MONGODB_PWD}@localhost:27017/${YOUR_PKG}"

EOAUTT

#!/usr/bin/env bash
#
export TARGET_SRVR="iriredsrv";

# The sudoer password for the account that will install Habitat
export SETUP_USER_UID="you";

export VIRTUAL_HOST_DOMAIN_NAME="iridium.red";
export HABITAT_USER_SSH_KEY_COMMENT="IridiumRed Habitat User Key";

export VHOST_SUBJECT="/C=US/ST=OR/L=Grant's Pass/O=Iridium Red/CN=${VIRTUAL_HOST_DOMAIN_NAME}";

export YOUR_ORG="yourse1f-yourorg";
export YOUR_PKG="mmks";

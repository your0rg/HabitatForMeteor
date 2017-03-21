#!/usr/bin/env bash
#
export TARGET_SRVR="hmsrv";

# The sudoer password for the account that will install Habitat
export SETUP_USER_UID="you";

export VIRTUAL_HOST_DOMAIN_NAME="irid.blue";
export HABITAT_USER_SSH_KEY_COMMENT="IridBlue Habitat User Key";

export VHOST_SUBJECT="/C=US/ST=OR/L=Grant's Pass/O=Irid Blue/CN=${VIRTUAL_HOST_DOMAIN_NAME}";

export YOUR_ORG="yourse1f-yourorg";
export YOUR_PKG="mmks";

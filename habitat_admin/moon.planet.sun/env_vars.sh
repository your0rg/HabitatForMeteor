#!/usr/bin/env bash
#
export TARGET_SRVR="hab4metsrv";

# The sudoer password for the account that will install Habitat
export SETUP_USER_UID="you";

export VIRTUAL_HOST_DOMAIN_NAME="moon.planet.sun";
export HABITAT_USER_SSH_KEY_COMMENT="MoonPlanetSun Habitat User Key";

export VHOST_SUBJECT="/C=CA/ST=Planet/L=Moon/O=mmks/CN=${VIRTUAL_HOST_DOMAIN_NAME}";

export YOUR_ORG="yourse1f-yourorg";
export YOUR_PKG="todos";

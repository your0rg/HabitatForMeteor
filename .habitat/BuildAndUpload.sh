#!/usr/bin/env bash
#
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

PRTY="  ==>  ";

echo "${PRTY} Changing location to ${SCRIPTPATH}";
cd ${SCRIPTPATH};

echo "${PRTY} Preparing absolute path names...";
declare HABITAT_WORK=$(pwd);
declare BUILD_ARTIFACTS=${HABITAT_WORK}/results;
declare METEOR_BUNDLE=${BUILD_ARTIFACTS}/bundle;
declare SERVER_EXECUTABLES=${METEOR_BUNDLE}/programs/server;

echo "${PRTY} Stepping out to Meteor project directory";
pushd .. &>/dev/null;

  echo "${PRTY} Ensuring Meteor directory has all necessary node_modules...";
  meteor npm install;

  echo "${PRTY} Building Meteor and putting bundle in results directory...";
  echo "         ** The 'source tree' WARNING can be safely ignored ** ";
  meteor build ./.habitat/results --directory --server-only;

popd;

echo "${PRTY} Stepping into the server executables sub-dir of the bundle dir...";
pushd ${SERVER_EXECUTABLES};

  echo "${PRTY} Ensuring Meteor bundle has all necessary node_modules...";
  meteor npm install;

popd;

echo "${PRTY} Building Meteor bundle into Habitat package...";
sudo hab pkg build .
echo "won't do upload yet";
exit 1;

echo "${PRTY} Uploading Habitat package to default depot...";
sudo hab pkg upload --auth ${GITHUB_AUTH_TOKEN};

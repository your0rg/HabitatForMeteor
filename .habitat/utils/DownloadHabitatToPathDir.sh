#!/bin/sh
#

downloadHabToPathDir() {

  INST_HOST="https://api.bintray.com";
  INST_STABLE="content/habitat/stable";
  INST_PATH="${INST_HOST}/${INST_STABLE}";

  INST_MAC="darwin";
  INST_LNX="linux";

  INST_SFX_MAC="zip";
  INST_SFX_LNX="tar.gz";
  INST_SFX="${INST_SFX_LNX}";

  INST_FILE="hab-%24latest";

  INST_PARM="bt_package";

  ARCH="x86_64";

  OS="darwin";
  OS="linux";
  OS="${1:-linux}";

  DEST_DIR="${2:-/usr/bin}";

  if [ "${OS}" = "${INST_MAC}" ]; then
    INST_SFX="${INST_SFX_MAC}";
    # echo "APPLE https://api.bintray.com/content/habitat/stable/darwin/x86_64/hab-%24latest-x86_64-darwin.zip   ?bt_package=hab-x86_64-darwin";
  else
    INST_SFX="${INST_SFX_LNX}";
    # echo "LINUX https://api.bintray.com/content/habitat/stable/linux/x86_64/hab-%24latest-x86_64-linux.tar.gz?bt_package=hab-x86_64-linux";
  fi;

  INST_BUNDLE="${INST_FILE}-${ARCH}-${OS}.${INST_SFX}";
  INST_TRGT="hab-${ARCH}-${OS}.${INST_SFX}";
  INST_URL="${INST_PATH}/${OS}/${ARCH}/${INST_BUNDLE}?${INST_PARM}=hab-${ARCH}-${OS}";

  PATTERN="hab-*-${ARCH}-${OS}";


  # echo "TRGT  ${INST_TRGT}";
  # echo "DWNLD ${INST_URL}";
  # echo "TOWRD ${DEST_DIR}";

  wget --quiet --no-clobber -O ${INST_TRGT} ${INST_URL} > /dev/null;
  rm -fr ${PATTERN};
  tar zxf ${INST_TRGT};

  INST_DIR=$( ls -d ${PATTERN} );
  echo "Install from ${INST_DIR}/hab to ${DEST_DIR}";

  sudo mv ${INST_DIR}/hab ${DEST_DIR};
  DEST_FILE=${DEST_DIR}/hab;
  sudo chmod 755 ${DEST_FILE};
  sudo chown root:root ${DEST_FILE};

  rm -fr ${PATTERN};

}


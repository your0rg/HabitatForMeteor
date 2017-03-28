#!/usr/bin/env bash
#
# . ./habitat/scripts/utils.sh;

set -e;

TARGET_DIRECTORY="${1}";

# echo "Some tasks need to be run as root...";
# sudo ls -l &>/dev/null;

SCRIPT=$(readlink -f "$0");
SCRIPTPATH=$(dirname "$SCRIPT");
SCRIPTFULLPATH=$(pwd);
SCRIPTNAME=$(basename "$SCRIPT");
HABITAT_ADMIN_PATH=${SCRIPTPATH}/habitat_admin;
EXAMPLE_VHOST="moon.planet.sun";
HAB_VAULT="hab_vault";
EXAMPLE_VAULT="${HAB_VAULT}_EXAMPLE";
STANDARD_SHELL_VARIABLES="standard_env_vars.sh";
STANDARD_SHELL_VARIABLES_TEMPLATE="template.standard_env_vars.sh";

PRTY="PrAdSk :: ";

function usage() {
  echo -e "  Usage ::
    ${SCRIPTPATH}/${SCRIPTNAME} \${TARGET_DIRECTORY};
      Where :
        TARGET_DIRECTORY specifies the path to, and name of, the Habitat for Meteor 
            work directory you wish to create.

      Creates an example admininstrator toolkit in the directory you specify.
      The structure is:

      You will need to decide on your own version control for it, IF you choose to
      place the directory outside of the version control of any related project.

      Also note that, currently, your secret information will be kept in your '.ssh' directory
      with the following structure:
      
        .ssh/${HAB_VAULT}/
		├── habitat_user
		│   ├── yourse1f-yourorg-20161031014505.pub
		│   └── yourse1f-yourorg-20161031014505.sig.key
		├── ${EXAMPLE_VHOST}
		    ├── habitat_user
		    │   ├── id_rsa
		    │   └── id_rsa.pub
		    ├── secrets.sh
		    └── tls
		        ├── cert.pem
		        ├── cert.pp
		        └── privkey.pem

  ";

  echo "H4M dir ${SCRIPTPATH}";
  exit 1;
}

[ -z ${TARGET_DIRECTORY} ] && usage;

export HABITAT4METEOR_HOME=${SCRIPTPATH};

mkdir -p ${TARGET_DIRECTORY};
cp -nr ${HABITAT_ADMIN_PATH}/${EXAMPLE_VHOST} ${TARGET_DIRECTORY};
${HABITAT_ADMIN_PATH}/${STANDARD_SHELL_VARIABLES_TEMPLATE} > \
            ${TARGET_DIRECTORY}/${STANDARD_SHELL_VARIABLES};
mkdir -p ${HOME}/.ssh/${HAB_VAULT};
cp -nr ${HABITAT_ADMIN_PATH}/${EXAMPLE_VAULT}/* ${HOME}/.ssh/${HAB_VAULT};
chmod go-rwx ${HOME}/.ssh/${HAB_VAULT};

echo -e "
  Your administrator tools are ready.

  Secrets directory :
";

tree -L 3 ${HOME}/.ssh/${HAB_VAULT};
echo -e "

  Tools directory :
";
tree -L 3 ${TARGET_DIRECTORY};

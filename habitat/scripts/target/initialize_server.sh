#!/usr/bin/env bash
#
# set -eu;

SCRIPT=$(readlink -f "$0");
SCRIPTPATH=$(dirname "$SCRIPT");

declare PRTY=" DBINI  --> ";
function initialize_server() {

  export LOG=/tmp/databaseInit.log;
  if [[ -f ${LOG} ]]; then
    chmod ugo+rw ${LOG};
  else
    touch ${LOG};
  fi;

  pushd ${SCRIPTPATH} >/dev/null;

    if [[ -f ./settings.json ]]; then
      local  pgDB=$(cat ./settings.json | jq -r .PG_DB);
      local pgUID=$(cat ./settings.json | jq -r .PG_UID);
      local pgPWD=$(cat ./settings.json | jq -r .PG_PWD);
      local pgHST=$(cat ./settings.json | jq -r .PG_HST);
      local pgBKP=$(cat ./settings.json | jq -r .PG_BKP);
    else
      local  pgDB="circle_test";
      local pgUID="ubuntu";
      local pgPWD="memorablecacaphony";
      local pgHST="localhost";
      local pgBKP="http://bit.ly/mmks170317G";
    fi;

    local  PG_DB="${PG_DB:-$pgDB}";
    local PG_UID="${PG_UID:-$pgUID}";
    local PG_PWD="${PG_PWD:-$pgPWD}";
    local PG_HST="${PG_HST:-$pgHST}";
    local PG_BKP="${PG_BKP:-$pgBKP}";


    echo -e "Server Preparations Log :: $(date)
    ========================================================" > ${LOG};
    echo -e "\n${PRTY} Perform your server initializations here.

        PG_BKP -- ${PG_BKP}
        PG_UID -- ${PG_UID}
        PG_PWD -- ${PG_PWD}
         PG_DB -- ${PG_DB}
  "  | tee -a ${LOG};

    local DATABASE_NAME=${PG_DB};

    if [[ -z ${PG_BKP} ]]; then
      echo -e "${PRTY} No PostgreSQL seed URL was specified. Skipping ..."  | tee -a ${LOG};
    else

      declare SEED_FILE="pgres_seed.sql";
      echo -e "${PRTY} Downloading and restoring PostgreSQL seed from URL ...
                         ${PG_BKP}
           ... to have internal standard name '${SEED_FILE}'"  | tee -a ${LOG};

      curl -sz ${SEED_FILE} -L -o ${SEED_FILE} ${PG_BKP};

      echo -e "${PRTY} Have seed file, '$(stat -c "%n %s bytes" ${SEED_FILE})'."  | tee -a ${LOG};

      declare SCHEMA_NAME=$(cat ${SEED_FILE} \
        | grep -m 1 -Poh "(?<=\bSCHEMA\s)(\w+)" );

      declare SCHEMA_OWNER=$(cat ${SEED_FILE} \
        | grep "ALTER .* OWNER TO .*;"  \
        | grep -m 1 -oh "TO .*;"  \
        | cut -d " " -f 2  \
        | cut -d ";" -f 1);

      export PSQL="psql -h localhost -d ${DATABASE_NAME}";

      if [[ -z ${SCHEMA_NAME} ]]; then
        echo -e "No schema name specified... >${SCHEMA_NAME}<"  | tee -a ${LOG};
        SCHEMA_NAME="public";
      else
        echo -e "${PRTY} Seed file specified schema, '${SCHEMA_NAME}'."  | tee -a ${LOG};
        ${PSQL} -tc "CREATE SCHEMA IF NOT EXISTS ${SCHEMA_NAME}";
      fi;

      export SCHEMA_USER="";
      if [[ -z ${SCHEMA_OWNER} ]]; then
        echo -e "${PRTY} No schema owner specified... >${SCHEMA_OWNER}<"  | tee -a ${LOG};
      else
        local CNT=$(${PSQL} -tc "SELECT count(usename) FROM pg_user WHERE usename = '${SCHEMA_OWNER}'");
        (( ${CNT} < 1 )) && (
          echo "${PRTY} 'Creating user and giving schema ownership" | tee -a ${LOG}
          ${PSQL} -tc "CREATE USER ${SCHEMA_OWNER}";
          ${PSQL} -tc "GRANT ALL PRIVILEGES ON SCHEMA ${SCHEMA_NAME} TO  ${SCHEMA_OWNER}";
        );
      fi;

      declare COUNT_SCHEMA_TABLES="SELECT count(table_name) FROM information_schema.tables WHERE table_schema = '${SCHEMA_NAME}'";
      declare NUM_SCHEMA_TABLES=$(${PSQL} -tc "${COUNT_SCHEMA_TABLES}" | xargs);
      if [[ 0 < ${NUM_SCHEMA_TABLES} ]]; then
        echo -e "${PRTY} Schema, '${SCHEMA_NAME}', has tables already. Skipping..."  | tee -a ${LOG};
      else
        echo -e "${PRTY} Restoring PostgreSQL from seed file, '${SEED_FILE}'."  | tee -a ${LOG};

          ${PSQL} -qf ${SEED_FILE}
          #  &>/dev/null;

        echo -e "${PRTY} Database sown ..."  | tee -a ${LOG};
      fi;

      echo -e "${PRTY} Creating Meteor app user '${PG_UID}' if not exists"  | tee -a ${LOG};
      SCHEMA_USER=$(${PSQL} -tc "SELECT usename FROM pg_user WHERE usename = '${PG_UID}'" | xargs);
      if [[ -z  ${SCHEMA_USER} ]]; then
        ${PSQL} -tc "CREATE USER ${PG_UID} WITH PASSWORD '${PG_PWD}'";
      fi;

      ${PSQL} -tc "GRANT ALL PRIVILEGES ON DATABASE ${DATABASE_NAME} TO  ${PG_UID}";
      ${PSQL} -tc "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ${SCHEMA_NAME} TO ${PG_UID}";
      ${PSQL} -tc "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA ${SCHEMA_NAME} TO ${PG_UID}";

    fi;

    echo -e "\n${PRTY} Server initialized."  | tee -a ${LOG};

  popd >/dev/null;

};

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

  initialize_server;

fi;


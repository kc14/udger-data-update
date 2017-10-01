#! /usr/bin/env bash

SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")
PROJECT_BASEDIR=$(dirname "${SCRIPT_DIR}")

source "${PROJECT_BASEDIR}/etc/script-settings.rc"
source "${PROJECT_BASEDIR}/etc/script-functions.rc"

startofscript

# Business Code

source "${PROJECT_BASEDIR}/etc/udger-subscription-key.rc"

# Constants
UDGER_DATABASE_DIRECTORY="${PROJECT_BASEDIR}/var/data"

# Open alternative fd for stdout on 3
exec 3>&1

# Udger Updater

source "${PROJECT_BASEDIR}/etc/proxy.rc"
source "${PROJECT_BASEDIR}/etc/udger-datafile-names.rc"

for DATA_FILE in "${UDGER_DATAFILE_NAME[@]}"; do
  echo "Checking udger datafile [${DATA_FILE}] ..." >&3
  export DATA_FILE
  "${PROJECT_BASEDIR}/bin/udger-additional-data-updater.sh" -d "${UDGER_DATABASE_DIRECTORY}"
done

endofscript

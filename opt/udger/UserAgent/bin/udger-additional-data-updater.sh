#!/bin/bash

SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")
PROJECT_BASEDIR=$(dirname "${SCRIPT_DIR}")

source "${PROJECT_BASEDIR}/etc/script-settings.rc"
source "${PROJECT_BASEDIR}/etc/script-functions.rc"

startofscript

display_usage(){
    cat <<EOT
Usage: $(basename "$0") [-h] [-d <string>] -k <string>
Download a fresh Udger user agent database file

  -k   Set subscription key
       (or set the UDGER_SUBSCRIPTION_KEY environment variable)
  -d   Set download directory
  -h   Show this help text

EOT
}

SUBSCRIPTION_KEY="${UDGER_SUBSCRIPTION_KEY:?is not set\!}"
DATA_FILE="${DATA_FILE:?is not set\!}"

CURL=$(which curl 2> /dev/null)
CMP=$(which cmp 2> /dev/null)
CP=$(which cp 2> /dev/null)
LN=$(which ln 2> /dev/null)
RM=$(which rm 2> /dev/null)
GZIP=$(which gzip 2> /dev/null)

while getopts ":hk:d:" opt; do
  case $opt in
    k)
      SUBSCRIPTION_KEY=${OPTARG}
      ;;
    d)
      DOWNLOAD_DIR=${OPTARG}
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
    h | *) # Display help.
      display_usage
      exit 0
      ;;
  esac
done

if [ -z "$SUBSCRIPTION_KEY" ]; then
    display_usage
    exit 1
fi

DOWNLOAD_DIR="${DOWNLOAD_DIR:?is not set\!}"
VERSION="$(date --iso-8601=seconds)"
SNAPSHOT_URL="https://data.udger.com/"$SUBSCRIPTION_KEY

echo "";
echo "SUBSCRIPTION_KEY: ${SUBSCRIPTION_KEY}"
echo "DOWNLOAD_DIR: ${DOWNLOAD_DIR}"
echo "DATA_FILE: ${DATA_FILE}"
echo "VERSION: ${VERSION}"
echo "";

if [ ! -d "${DOWNLOAD_DIR}" ]; then
    echo "Download direcory does not exist"
    exit 1;
fi

echo "Base URL: ${SNAPSHOT_URL}"

mytmpdir="/var/tmp"
downloadsdir="Downloads"

jobtmpdir=$( mktemp -d --tmpdir="${mytmpdir}" "udger-additional-data-updater.sh.XXXXXXXXXX" )
echo "Using tmp directory [${jobtmpdir}]" >&3

tmpdownloadsdir="${jobtmpdir}/${downloadsdir}"
mkdir -p "${tmpdownloadsdir}"

# cd "${tmpdownloadsdir}"

NEW_FILENAME="${tmpdownloadsdir}/${DATA_FILE}"
NEW_FILENAME_GZ="${NEW_FILENAME}.gz"
LNK_FILENAME_GZ="${DOWNLOAD_DIR}/${DATA_FILE}.gz"
ACT_FILENAME_GZ="${DOWNLOAD_DIR}/${DATA_FILE}.gz.${VERSION}"
VERSION_FILE="${LNK_FILENAME_GZ}.version"

## start file download and update versions
start_download() {

  "${CURL}" -sSfR -o "${NEW_FILENAME}" "${SNAPSHOT_URL}/${DATA_FILE}"
  "${GZIP}" "${NEW_FILENAME}"

  if "${CMP}" "${NEW_FILENAME_GZ}" "${LNK_FILENAME_GZ}"; then
    echo "Unchanged: ${LNK_FILENAME_GZ}"
  else
    echo "Updating: ${LNK_FILENAME_GZ}"
    echo "${VERSION}" > "${VERSION_FILE}"
    "${CP}" "${NEW_FILENAME_GZ}" "${ACT_FILENAME_GZ}"
    "${LN}" -sf "${ACT_FILENAME_GZ}" "${LNK_FILENAME_GZ}"
  fi
}

start_download

## Print version
if [ -f "${VERSION_FILE}" ]; then
    echo "Current version is $(cat "${VERSION_FILE}")"
else
    echo "No previous version found"
fi

# Clean up

"${RM}" -fr "${jobtmpdir}"

endofscript

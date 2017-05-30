#!/bin/bash -
# -*- indent-tabs-mode: 1; tab-width: 4; -*-
if ((UID)); then
  err 'This script should be run as root.'
  exit 1
fi

PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
IFS=$'\t\n'
set -e

REPO="vps-secure-config-deploy-debian"
MASTER="https://github.com/CynicalSystems/$REPO"

if [ ! -d "${REPO}" ] && [ "$(pwd)" != "${REPO}" ]; then
  	if hash git 2>/dev/null; then 
  		# Download and verify scripts.
  		git clone ${MASTER}
	else 
		apt-get update
		apt-get install git
		if git clone ${MASTER} 2>/dev/null; then continue; else echo "error!"; exit 1; fi
	fi
fi

if [ ! -d "${REPO}" ]; then cd "${REPO}"; fi

cp bashrc /etc/bashrc

. /etc/bashrc 

./deploy.sh

exit 0

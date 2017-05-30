#!/bin/bash
REQUIRE="./deploy.conf;./prereq.sh;./kernel.sh;./netops.sh;./netsec.sh;./server.sh;./audits.sh"
PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
IFS=$'\t\n'
set -e

if ((UID)); then
  err 'This script should be run as root.'
  exit 1
fi

source ./functs.sh

report "Executing deployment."
echo
hostnamectl | report

require ${REQUIRE} | report

pkgdeps "apt-transport-https; ca-certificates; jq; curl; wget; netselect; netselect-apt;" | report

sources | report

pkgdeps "sysstat; conntrack; conntrackd; iproute2; iptables; ipset; auditd;" | report

prereq | report
netops | report
netsec | report



exit 0

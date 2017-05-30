#!/bin/bash

function otherpkgs()
{
  step "Installating additional packages: "
  try apt-get update 1>/dev/null
  try apt-get install whois iputils-traceroute iputils-ping dnsutils arpwatch netcat socat nmap ngrep tcpdump --force-yes 1>/dev/null
  try apt-get install git htop sudo nano --force-yes 1>/dev/null
  next
}

function sources()
{
  step "Setting up apt sources"
  try mkdir ./backup
  try mv /etc/apt/sources.list ./backup/sources.list

  try cat >/etc/apt/sources.list <<EOL
# Main
deb  https://deb.debian.org/debian jessie main
deb-src  https://deb.debian.org/debian jessie main
# Updates
deb  https://deb.debian.org/debian jessie-updates main
deb-src  https://deb.debian.org/debian jessie-updates main
# Security
deb https://security.debian.org/ jessie/updates main
deb-src https://security.debian.org/ jessie/updates main
EOL

  try netselect-apt 1>/dev/null
  try apt-get update 1>/dev/null
  next
}



# Source Check 
_LOADED_PREREQ=1

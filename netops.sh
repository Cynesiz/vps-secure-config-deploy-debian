#!/bin/bash

function clientinfo()
{
	CIP=$(echo $SSH_CLIENT | awk '{print $1}')
	echo "You are connected from: ${CIP}"
}


function getpubnet()
{
	step "Obtaining network settings for primary public interface: "
	try ETHPUBLIC=$(ip -4 route show default | sed -nr 's/.*dev ([^\ ]+).*/\1/p')
	try ROUTERIP=$(ip -4 route show dev ${ETHPUBLIC} | sed -nr 's/.*via ([^\ ]+).*/\1/p')
	ping -c1 -w1 ${ROUTERIP} >> /dev/null 2>&1
	try ROUTERMAC=$(arp -ai ${ETHPUBLIC} -i ${ROUTERIP} | sed -nr 's/.*at ([[:xdigit:]{2}:]+).*/\1/p')
	try PUBLICIP=$(ip -4 addr show dev ${ETHPUBLIC} | sed -nr 's/.*inet ([^\ ]+)\/.*/\1/p')
	try PUBLICBRD=$(ip -4 addr show dev ${ETHPUBLIC} | sed -nr 's/.*brd ([^\ ]+).*/\1/p')
	try PUBSUBNET=$(ip -4 addr show dev ${ETHPUBLIC} | sed -nr 's/.*inet ([^\ ]+).*/\1/p')
	next
	echo ""
	echo "Public Network Information Acquired"
	echo "-----------------------------------"
	echo "Device: ${ETHPUBLIC}"
	echo "IPv4: ${PUBLICIP}"
	echo "Subnet: ${PUBSUBNET}"
	echo "Broadcast: ${PUBLICBRD}"
	echo "Router IP: ${ROUTERIP}"
	echo "Router MAC: ${ROUTERMAC}"
	echo "-----------------------------------"
	echo ""
}

function setpubnet() {
	cat >/etc/network/interface_ <<EOL
auto lo 
iface lo inet loopback 

auto ${ETHPUBLIC}
iface ${ETHPUBLIC} inet static
	address ${PUBLICIP}
	network ${PUBSUBNET}
	gateway ${ROUTERIP}
	broadcast ${PUBLICBRD}

EOL
}

function netops()
{
	clientinfo
	getpubnet
	setpubnet
}


# Source Check 
_LOADED_NETOPS=1

#!/bin/bash

function fwpolicy()
{
  step "Setting firewall default policies: "
    try ip6tables -t filter -P INPUT ${IP6_POLICY[INPUT]}
    try ip6tables -t filter -P OUTPUT ${IP6_POLICY[OUTPUT]}
    try ip6tables -t filter -P FORWARD ${IP6_POLICY[FORWARD]}
    try iptables -t filter -P INPUT ${IP4_POLICY[INPUT]}
    try iptables -t filter -P OUTPUT ${IP4_POLICY[OUTPUT]}
    try iptables -t filter -P FORWARD ${IP4_POLICY[FORWARD]}    
  next
}

function hashsets()
{
    step "Creating nethash for bogons: "
      try ipset --create bogons nethash
      try ipset --add bogons 0.0.0.0/8
      try ipset --add bogons 10.0.0.0/8
      try ipset --add bogons 100.64.0.0/10
      try ipset --add bogons 169.254.0.0/16
      try ipset --add bogons 172.16.0.0/12
      try ipset --add bogons 192.0.0.0/24
      try ipset --add bogons 192.0.2.0/24
      try ipset --add bogons 192.168.0.0/16
      try ipset --add bogons 198.18.0.0/15
      try ipset --add bogons 198.51.100.0/24
      try ipset --add bogons 203.0.113.0/24
      try ipset --add bogons 224.0.0.0/3  
    next
}

function fwblock()
{
    step "Blocking invalid traffic: "
      try iptables -t filter -A INPUT -i ${ETHPUBLIC} -s ${PUBLICIP} -j DROP
      try iptables -t filter -A INPUT -i ${ETHPUBLIC} -m set --match-set bogons src -j DROP
      try iptables -t filter -A INPUT -i ${ETHPUBLIC} -m set --match-set bogons dst -j DROP
      try iptables -t filter -A FORWARD -i ${ETHPUBLIC} -m set --match-set bogons src -j DROP
      try iptables -t filter -A FORWARD -i ${ETHPUBLIC} -m set --match-set bogons dst -j DROP
      try iptables -t filter -A OUTPUT -o ${ETHPUBLIC} -m set --match-set bogons src -j REJECT
      try iptables -t filter -A OUTPUT -o ${ETHPUBLIC} -m set --match-set bogons dst -j REJECT
      try iptables -t filter -A INPUT -i ${ETHPUBLIC} -m state --state INVALID -j DROP
      try iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP
      try iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
      try iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP
      try iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP 
      try iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP 
      try iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP 
      try iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP 
      try iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP 
      try iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP 
      try iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP 
      try iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP 
      try iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP 
      try iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP 
      try iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP 
      try iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP 
      try iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
      try iptables -t raw -A PREROUTING -p tcp -m tcp --syn -j CT --notrack 
      try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp -m tcp -m conntrack --ctstate INVALID,UNTRACKED -j SYNPROXY --sack-perm --timestamp --wscale 7 --mss 1460 
      try iptables -t filter -A INPUT -i ${ETHPUBLIC} -m conntrack --ctstate INVALID -j DROP
    next

    step "Setting connection limits: " 
      try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp -m connlimit --connlimit-above ${TCP_LIMIT_CON} -j REJECT --reject-with tcp-reset
      try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp -m conntrack --ctstate NEW -m limit --limit 100/s --limit-burst 200 -j ACCEPT 
      try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp -m conntrack --ctstate NEW -j DROP
      try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --tcp-flags RST RST -m limit --limit 2/s --limit-burst 2 -j ACCEPT 
      try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --tcp-flags RST RST -j DROP
      try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p icmp -m icmp --icmp-type address-mask-request -j DROP
      try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p icmp -m icmp --icmp-type timestamp-request -j DROP
    next
}

function whitelist()
{
	echo "Whitelist has been enabled."
	echo "This will allow all traffic from: ${CIP}."
	echo "This is usually accompanied by a default drop polcy."
	countdown 10
	step "Enabling whitelist for ${CIP} : "
		try iptables -I INPUT -i ${ETHPUBLIC} -s ${CIP} -j ACCEPT
		try iptables -I OUTPUT -o ${ETHPUBLIC} -d ${CIP} -j ACCEPT
	next
}

function fwallow()
{
    step "Setting common firewall allow rules: "
      try iptables -A INPUT -i lo -j ACCEPT
      try iptables -A OUTPUT -i lo -j ACCEPT
      try ip6tables -A INPUT -A lo -j ACCEPT
      try ip6tables -A OUTPUT -o lo -j ACCEPT

      try iptables -A INPUT -i ${ETHPUBLIC} -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

      try iptables -A OUTPUT -o ${ETHPUBLIC} -p icmp --icmp-type echo-request -j ACCEPT
      try iptables -A INPUT -i ${ETHPUBLIC} -p icmp --icmp-type echo-reply -j ACCEPT

      try iptables -A INPUT -i ${ETHPUBLIC} -p icmp -m icmp --icmp-type 8 -m limit --limit 1/s --limit-burst 1 -j REJECT --reject-with icmp-net-prohibited
      try iptables -A INPUT -i ${ETHPUBLIC} -p icmp --icmp-type fragmentation-needed -m limit --limit 1/s --limit-burst 1 -m state  --state NEW -j ACCEPT
      try iptables -A INPUT -i ${ETHPUBLIC} -p icmp --icmp-type source-quench -m limit --limit 1/s --limit-burst 1 -m state --state NEW -j ACCEPT

      try iptables -A OUTPUT -o ${ETHPUBLIC} -s ${PUBLICIP} -p tcp -m multiport --dports 11025,20,21,22,80,443 -j ACCEPT
      try iptables -A INPUT -i ${ETHPUBLIC} -p udp --dport 67:68 --sport 67:68 -j ACCEPT
    next

	  case "$_DEPLOY_TYPE" in
        'webhost')
          step "Setting Web Server Deployment standard allow ruleset: "
            try iptables -t filter -A OUTPUT -o ${ETHPUBLIC} -p tcp --sport 80 -j ACCEPT
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --dport 80 -j ACCEPT
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --dport 80 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --syn --dport 80 -m connlimit --connlimit-above 10 --connlimit-mask 32 -j DROP
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --syn --dport 80 -m connlimit --connlimit-above 150 -j DROP        
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --dport 443 -j ACCEPT
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --dport 443 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --syn --dport 443 -m connlimit --connlimit-above 10 --connlimit-mask 32 -j DROP
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --syn --dport 443 -m connlimit --connlimit-above 150 -j DROP   
          next
          ;;
        'tunnel')
          step "Setting Tunnel Server Deployment provisional allow ruleset: "
            try iptables -t filter -A OUTPUT -o ${ETHPUBLIC} -p tcp --sport 443 -j ACCEPT
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --dport 443 -j ACCEPT
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --dport 443 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --syn --dport 443 -m connlimit --connlimit-above 5 --connlimit-mask 32 -j DROP
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --syn --dport 443 -m connlimit --connlimit-above 150 -j DROP   
            try iptables -t filter -A OUTPUT -o ${ETHPUBLIC} -p tcp --sport 5060 -j ACCEPT       
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --dport 5060 -j ACCEPT
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --dport 5060 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --syn --dport 5060 -m connlimit --connlimit-above 5 --connlimit-mask 32 -j DROP
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --syn --dport 5060 -m connlimit --connlimit-above 150 -j DROP   
          next
          ;;
        'vdesk')
		  step "Setting Virtual Desktop Deployment provisional allow ruleset: "
            try iptables -t filter -A OUTPUT -o ${ETHPUBLIC} -p tcp --sport 443 -j ACCEPT
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --dport 443 -j ACCEPT
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --dport 443 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --syn --dport 443 -m connlimit --connlimit-above 5 --connlimit-mask 32 -j DROP
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --syn --dport 443 -m connlimit --connlimit-above 150 -j DROP   
            try iptables -t filter -A OUTPUT -o ${ETHPUBLIC} -p tcp --sport 5061 -j ACCEPT       
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --dport 5061 -j ACCEPT
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --dport 5061 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --syn --dport 5061 -m connlimit --connlimit-above 5 --connlimit-mask 32 -j DROP
            try iptables -t filter -A INPUT -i ${ETHPUBLIC} -p tcp --syn --dport 5061 -m connlimit --connlimit-above 150 -j DROP   
		  next
		  ;;
		  *)

		  ;;
      esac
}


function netsec()
{
	hashsets
	fwallow
	fwblock
	whitelist
	fwpolicy
}





# Source Check 
_LOADED_NETSEC=1

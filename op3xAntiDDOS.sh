#!/bin/bash
printf "\033c"

echo -e "         ___                _   _      _   _         \n  ___ ___|_  |_ _    ___ ___| |_|_|   _| |_| |___ ___ \n | . | . |_  |_'_|  | .'|   |  _| |  | . | . | . |_ -|\n | . | . |_  |_'_|  | .'|   |  _| |  | . | . | . |_ -|\n     |_|                                              \n"

echo """+-+-+-+-+-+-+-+-+-+-+
  op3xm8AntiDDOS.sh
+-+-+-+-+-+-+-+-+-+-+"""


if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


if [[ $1 == "-s" || $1 == "-S" ]]; then
	echo "Setting rules..."
	### 1: Drop invalid packets ### 
	/sbin/iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP  

	### 2: Drop TCP packets that are new and are not SYN ### 
	/sbin/iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP 
	 
	### 3: Drop SYN packets with suspicious MSS value ### 
	/sbin/iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP  

	### 4: Block packets with bogus TCP flags ### 
	/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
	/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
	/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
	/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP
	/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP
	/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP
	/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP

	### 5: Block spoofed packets ### 
	#/sbin/iptables -t mangle -A PREROUTING -s 224.0.0.0/3 -j DROP 
	#/sbin/iptables -t mangle -A PREROUTING -s 169.254.0.0/16 -j DROP 
	#/sbin/iptables -t mangle -A PREROUTING -s 172.16.0.0/12 -j DROP 
	#/sbin/iptables -t mangle -A PREROUTING -s 192.0.2.0/24 -j DROP 
	#/sbin/iptables -t mangle -A PREROUTING -s 192.168.0.0/16 -j DROP 
	#/sbin/iptables -t mangle -A PREROUTING -s 10.0.0.0/8 -j DROP 
	#/sbin/iptables -t mangle -A PREROUTING -s 0.0.0.0/8 -j DROP 
	#/sbin/iptables -t mangle -A PREROUTING -s 240.0.0.0/5 -j DROP 
	#/sbin/iptables -t mangle -A PREROUTING -s 127.0.0.0/8 ! -i lo -j DROP  

	### 6: Drop ICMP (you usually don't need this protocol) ### 
	/sbin/iptables -t mangle -A PREROUTING -p icmp -j DROP  

	### 7: Drop fragments in all chains ### 
	/sbin/iptables -t mangle -A PREROUTING -f -j DROP  

	### 8: Limit connections per source IP ### 
	/sbin/iptables -A INPUT -p tcp -m connlimit --connlimit-above 111 -j REJECT --reject-with tcp-reset  

	### 9: Limit RST packets ### 
	/sbin/iptables -A INPUT -p tcp --tcp-flags RST RST -m limit --limit 2/s --limit-burst 2 -j ACCEPT 
	/sbin/iptables -A INPUT -p tcp --tcp-flags RST RST -j DROP  

	### 10: Limit new TCP connections per second per source IP ### 
	/sbin/iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT 
	/sbin/iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP  

elif [[ $1 == "-c" || $1 == "-C" ]]; then
	echo "Clearing Rules..."
	# Accept all traffic first to avoid ssh lockdown  via iptables firewall rules #
	iptables -P INPUT ACCEPT
	iptables -P FORWARD ACCEPT
	iptables -P OUTPUT ACCEPT
	 
	# Flush All Iptables Chains/Firewall rules #
	iptables -F
	 
	# Delete all Iptables Chains #
	iptables -X
	 
	# Flush all counters too #
	iptables -Z 
	# Flush and delete all nat and  mangle #
	iptables -t nat -F
	iptables -t nat -X
	iptables -t mangle -F
	iptables -t mangle -X
	iptables -t raw -F
	iptables -t raw -X

else
echo """
- Set Rules [-s / -S]

- Clear Rules [-c / -C]

+-+-+-+-+-+-+-+-+-+-+"""
fi
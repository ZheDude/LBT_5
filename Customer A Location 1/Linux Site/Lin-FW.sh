#! /bin/bash

sudo apt update
sudo apt install iptables-persistent
#sudo apt install 



iptables -F
iptables -X

iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE
###################################################
# Flush all existing rules and custom chains
iptables -F
iptables -X

# Set default policies
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

# Allow established and related connections
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Create custom chain for LAN and DMZ traffic
iptables -N LAN_DMZ-DMZ_LAN   # For traffic between LAN and DMZ

# Forwarding rules between LAN and DMZ
iptables -A FORWARD -i LAN -o DMZ -j LAN_DMZ-DMZ_LAN
iptables -A FORWARD -i DMZ -o LAN -j LAN_DMZ-DMZ_LAN

# Forwarding rules for LAN and DMZ to OUT
iptables -A FORWARD -i LAN -o OUT -j ACCEPT
iptables -A FORWARD -i DMZ -o OUT -j ACCEPT

# Port-specific rules for traffic between LAN and DMZ
iptables -A LAN_DMZ-DMZ_LAN -p tcp --dport 53 -j ACCEPT   # Allow DNS (TCP)
iptables -A LAN_DMZ-DMZ_LAN -p udp --dport 53 -j ACCEPT   # Allow DNS (UDP)
iptables -A LAN_DMZ-DMZ_LAN -p tcp --dport 22 -j ACCEPT   # Allow SSH
iptables -A LAN_DMZ-DMZ_LAN -p udp --dport 123 -j ACCEPT  # Allow NTP
iptables -A LAN_DMZ-DMZ_LAN -p icmp -j ACCEPT             # Allow ICMP

# NAT masquerading for outbound traffic (LAN and DMZ to OUT)
iptables -t nat -A POSTROUTING -o OUT -j MASQUERADE

sudo netfilter-persistent save

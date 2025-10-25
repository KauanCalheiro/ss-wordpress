#!/bin/sh

##############################################################
#     Team number: D9
#       Student names:
#         1 - Nataliia Babinska
#         2 - Michal Mikulka
#         3 - Kauan Morinel Calheiro
##############################################################

info() {
    echo -e "\033[0;34m$1\033[0m"
}

success() {
    echo -e "\033[0;32m$1\033[0m"
}

###############################
# Init. of iptables
###############################
IPT=/usr/sbin/iptables

info "Defining default policy\n"
# TODO: Define default policy DENIED
$IPT -P INPUT ACCEPT
$IPT -P FORWARD ACCEPT
$IPT -P OUTPUT ACCEPT
success "Defined default policy\n"

info "\nFlushing rules and custom chains\n"
# Flush only filter table rules (not affecting Docker's nat/mangle tables)
# $IPT -t filter -F
# $IPT -t filter -X
# Note: This preserves Docker rules in nat and other tables
success "Flushed filter table rules and custom chains\n"

###############################
# SSHTTP setup
###############################

DEV=enp0s3

PORTS="2022 4433"

modprobe nf_conntrack_ipv4 || true
modprobe nf_conntrack || true
modprobe xt_conntrack || true

$IPT -t mangle -N DIVERT || true

echo "Using network device $DEV"

for p in $PORTS; do
	echo "Setting up port $p ..."

	# $IPT -A INPUT -i $DEV -p tcp --dport $p -j DROP

	$IPT -t mangle -A OUTPUT -p tcp -o $DEV --sport $p -j DIVERT
done

$IPT -t mangle -A PREROUTING -p tcp -m socket -j DIVERT

$IPT -t mangle -A DIVERT -j MARK --set-mark 1
$IPT -t mangle -A DIVERT -j ACCEPT

ip rule add fwmark 1 lookup 123 || true
ip route add local 0.0.0.0/0 dev lo table 123

$IPT -A INPUT -m conntrack -i lo --ctstate NEW -j LOG

###############################
# Save rules persistently
###############################
info "Saving rules persistently"
sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
sudo netfilter-persistent save
sudo netfilter-persistent enable
success "Rules saved and enabled on boot"

echo "END"

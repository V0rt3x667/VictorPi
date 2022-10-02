#!/bin/bash

# Network Variables
: "${BRIDGE:=rasp-br0}"
: "${TAP:=rasp-tap0}"
: "${GATEWAY:=192.168.66.1}"
FIRSTIP="${GATEWAY%.1}.2"
LASTIP="${GATEWAY%.1}.254"
BROADCAST="${GATEWAY%.1}.255"

function genMAC() {
    # Generate Random MAC ADDRESS to avoid collisions
    printf "52:54:%02x:%02x:%02x:%02x" $(( RANDOM & 0xff)) $(( RANDOM & 0xff )) $(( RANDOM & 0xff)) $(( RANDOM & 0xff ))
}

function getInternetIf() {
    iface=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
    echo "$iface"
}

function checkTap() {
    if [ -d "/sys/class/net/$TAP" ]; then
        while [[ -d "/sys/class/net/$TAP" ]]; do
            TAPON=1
            TAP=rasp-tap$(( ${TAP##rasp-tap} + 1 ))
        done
    else
        TAPON=0
    fi
}

function checkDnsmasq() {
    DNSMASQPID=$(pgrep -f $GATEWAY)
}

function setupDnsmasq() {
    local nameservers
    local searchdomains

    DNSMASQ_OPTS="--listen-address=$GATEWAY --interface=$BRIDGE --bind-interfaces --dhcp-range=$FIRSTIP,$LASTIP"

    # Build DNS options from container /etc/resolv.conf
    mapfile -t nameservers < <(grep nameserver /etc/resolv.conf | head -n 2 | sed 's/nameserver //')
    mapfile -t searchdomains < <(grep search /etc/resolv.conf | sed 's/search //' | sed 's/ /,/g')

    domainname=$(echo "${searchdomains[@]}" | awk -F"," '{print $1}')

    if [[ -n $domainname  ]]; then
        DNSMASQ_OPTS+=" --dhcp-option=option:domain-name,$domainname"
    fi

    for nameserver in "${nameservers[@]}"; do
        [[ -z $DNS_SERVERS ]] && DNS_SERVERS=$nameserver || DNS_SERVERS="$DNS_SERVERS,$nameserver"
    done

    if [ -z "$DNSMASQPID" ] && ! ss -ntl | grep -q :53; then
        echo -e "[$PASS] Turning up dnsmasq for guest IP assignment ..."
        DNSMASQ_OPTS+=" --dhcp-option=option:dns-server,$DNS_SERVERS --dhcp-option=option:router,$GATEWAY"
        eval "sudo -E $DNSMASQ $DNSMASQ_OPTS"
    elif [ -z "$DNSMASQPID" ] && ss -ntl | grep -q :53; then
        echo -e "[$WARN] Port 53 is busy"
        echo -e "[$WARN] Trying to use local dns service ( maybe offline )"
        DNSMASQ_OPTS="$DNSMASQ_OPTS --dhcp-option=option:dns-server,127.0.0.1 --port=0"
        eval "sudo -E $DNSMASQ $DNSMASQ_OPTS"
    else
        echo -e "[$WARN] Another instance of $DNSMASQ is running ..."
    fi
}

function killDnsmasq() {
    if [[ -n "$DNSMASQPID" ]]; then
        sudo -E kill -9 "$DNSMASQPID"
    fi
}

function killNetwork() {
    echo -e "[$PASS] Shutting down present network for QEMU ..."
    checkDnsmasq
    killDnsmasq

    while [[ -d "/sys/class/net/$BRIDGE" ]] || [[ -d "/sys/class/net/$TAP" ]]; do
        sudo -E "$IP" link set "$TAP" nomaster > /dev/null 2>&1 # Enslave tap
        sudo -E "$IP" tuntap del dev "$TAP" mode tap > /dev/null  2>&1 # Remove tap
        sudo -E "$IP" link delete "$BRIDGE" type bridge > /dev/null 2>&1 # Remove bridge
        sudo -E su -c "echo 0 > /proc/sys/net/ipv4/ip_forward"
    done
}

function fkillNetwork() {
    echo -e "[$PASS] Forced network shutdown for QEMU ..."
    checkDnsmasq
    killDnsmasq

    while [[ -d "/sys/class/net/$BRIDGE" ]] || [[ -n "$(find /sys/class/net/ -name "rasp*")" ]]; do
        for i in /sys/class/net/rasp-tap*; do
            # Enslave tap
            sudo -E "$IP" link set "${i##*/}" nomaster > /dev/null 2>&1
            # Remove tap
            sudo -E "$IP" tuntap del dev "${i##*/}" mode tap > /dev/null  2>&1
        done
        # Remove bridge
        sudo -E "$IP" link delete "$BRIDGE" type bridge > /dev/null 2>&1
    done
}

function bridgeUp() {
    # Add bridge
    sudo -E "$IP" link add "$BRIDGE" type bridge
    # Set ip to bridge interface
    sudo -E "$IP" addr add "$GATEWAY"/24 broadcast "$BROADCAST" dev "$BRIDGE"
    sudo -E "$IP" link set "$BRIDGE" up

    sleep 0.5s
}

function setNat() {
    iface=$(getInternetIf)
    sudo -E "$IPTABLES" -t nat -A POSTROUTING -o "$iface" -j MASQUERADE
    sudo -E "$IPTABLES" -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    sudo -E "$IPTABLES" -A FORWARD -i "$TAP" -o "$iface" -j ACCEPT
}

function setTap() {
    # Add tap interface
    sudo -E "$IP" tuntap add dev "$TAP" mode tap user "$(checkUser)"
    sudo -E "$IP" link set "$TAP" up promisc on

    sleep 0.5s
    # Bind tap to bridge
    sudo -E "$IP" link set $TAP master "$BRIDGE"
}

function createNetwork() {
    echo -e "[$PASS] Turning up a network for QEMU ..."
    if [ "$IPFORWARD" != "1" ]; then
        sudo -E su -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
    fi

    if [ $TAPON -eq 0 ]; then
        bridgeUp
    fi

    setTap
    checkDnsmasq
    setupDnsmasq
    setNat
    echo -e "[$PASS] Gateway address: $G$GATEWAY$RST"
}

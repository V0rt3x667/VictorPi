#!/bin/bash

function addPackages() {
    local packages=(
        'binutils'
        'coreutils'
        'cpio'
        'curl'
        'dnsmasq'
        'dosfstools'
        'e2fsprogs'
        'file'
        'grep'
        'iproute2'
        'iptables'
        'libarchive-tools'
        'qemu-img'
        'qemu-system-aarch64'
        'qemu-system-arm'
        'sudo'
        'unzip'
        'util-linux'
    )
    apk add --no-cache "${packages[@]}"
}

function addNetworking() {
    # Create the KVM node (required --privileged)
    if [ ! -e /dev/kvm ]; then
        set +e
        mknod /dev/kvm c 10 232
        set -e
    fi

    # Add BRIDGE_IF to /etc/qemu/bridge.conf
    mkdir -p /etc/qemu
    echo "allow raspi-br0" >>/etc/qemu/bridge.conf

    # Make sure we have the TUN device node
    if [ ! -e /dev/net/tun ]; then
        set +e
        mkdir -p /dev/net
        mknod /dev/net/tun c 10 200
        set -e
    fi
}

function addVictorpi() {
    local vpi="https://github.com/V0rt3x667/victorpi/archive/refs/heads/master.zip"

    mkdir /tmp && cd /tmp
    download "$vpi"
    unzip master.zip

    cd victorpi-master
    install -Dm755 victorpi -t /usr/bin/
    install -Dm755 victorpi/* -t /opt/victorpi/
    sed -i "s|OPT=.|OPT=\/opt|g" /usr/bin/victorpi
    rm -rf /tmp/*
}

echo "===> Networking Settings ..."
addNetworking

echo "===> Update & Install Required Packages"
addPackages

echo "===> Installing VictorPi"
addVictorpi

echo "===> DONE $0 $*"

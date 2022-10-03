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
    # Create KVM Node (required --privileged)
    if [ ! -e /dev/kvm ]; then
        set +e
        mknod /dev/kvm c 10 232
        set -e
    fi

    # Add BRIDGE_IF to /etc/qemu/bridge.conf
    mkdir -p /etc/qemu
    echo "allow rasp-br0" >>/etc/qemu/bridge.conf

    # Create TUN Device Node
    if [ ! -e /dev/net/tun ]; then
        set +e
        mkdir -p /dev/net
        mknod /dev/net/tun c 10 200
        set -e
    fi
}

echo "===> Update & Install Required Packages"
addPackages

echo "===> Configuring Network Settings"
addNetworking

echo "===> DONE $0 $*"

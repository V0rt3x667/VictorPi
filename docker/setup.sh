#!/bin/bash

function download() {
    curl -sL -O -C - "$1"
}

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

function addKernels() {
    local kver
    local kurl="https://api.github.com/repos/M0Rf30/qemu-kernel-$MODEL/releases"

    mkdir /tmp && cd /tmp
    kver="$(download $kurl/latest | grep -m 1 tag_name | cut -d\" -f4)"

    download "$kurl/download/$kver/qemu_kernel_$MODEL-$kver"
    install -Dm644 "/tmp/qemu_kernel_rpi_$MODEL-$kver" -t "/opt/victorpi/kernel/qemu-kernel-$MODEL"

    rm -rf /tmp/*
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

function addAAVFM() {
    local arch
    local fedurl="https://kojipkgs.fedoraproject.org//packages/edk2"
    local fedver=38
    local pkgrel=1
    local pkgver=20220826gitba0e0e4c6a17

    if [[ -d "$OVMFPATH" ]]; then
        return
    else
        mkdir -p "$OVMFPATH"
    fi

    if [[ "$MODEL" = "rpi-2" ]]; then
        cd "$OVMFPATH"
        arch=arm
        download "$fedurl/$pkgver/$pkgrel.fc$fedver/noarch/edk2-$arch-$pkgver-$pkgrel.fc$fedver.noarch.rpm"
        rpm2cpio ./*.noarch.rpm | cpio -idmv
        cd /usr/share/AAVMF
        ln -sf ../edk2/arm/vars-template-pflash.raw AAVMF32_VARS.fd
    elif [[ "$MODEL" = "rpi-3" ]]; then
        cd "$OVMFPATH"
        arch=aarch64
        download "$fedurl/$pkgver/$pkgrel.fc$fedver/noarch/edk2-$arch-$pkgver-$pkgrel.fc$fedver.noarch.rpm"
        rpm2cpio ./*.noarch.rpm | cpio -idmv
        cd /usr/share/AAVMF
        ln -sf ../edk2/arm/vars-template-pflash.raw AAVMF32_VARS.fd
    fi
}

echo "===> Download & Copy RPi Kernels"
addKernels

echo "===> Networking Settings ..."
addNetworking

echo "===> Update & Install Required Packages"
addPackages

echo "===> Installing VictorPi"
addVictorpi

echo "===> Installing AVMF ARM & AARCH64"
addAAVFM

echo "===> DONE $0 $*"

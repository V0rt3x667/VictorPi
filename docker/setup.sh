#!/bin/bash

echo "===> Update & Install Required Packages"
apk add --no-cache \
binutils \
coreutils \
cpio \
curl \
dnsmasq \
dosfstools \
e2fsprogs \
file \
grep \
iproute2 \
iptables \
libarchive-tools \
qemu-img \
qemu-system-aarch64 \
qemu-system-arm \
rpm2cpio \
sudo \
unzip \
util-linux

echo "===> Download & Copy RPi Kernels"
kver="$(download https://api.github.com/repos/M0Rf30/qemu-kernel-rpi-2/releases/latest | grep -m 1 tag_name | cut -d\" -f4)"
for model in 2 3; do
    download "https://github.com/M0Rf30/qemu-kernel-rpi-$model/releases/download/$kver/qemu_kernel_rpi_$model-$kver" -P /tmp
    install -Dm644 "/tmp/qemu_kernel_rpi_$model-$kver" -t "/opt/victorpi/kernel/qemu-kernel-rpi-$model"
done

rm -rf /tmp/*

echo "===> Networking Settings ..."
# Create the kvm node (required --privileged)
if [ ! -e /dev/kvm ]; then
    set +e
    mknod /dev/kvm c 10 232
    set -e
fi

# If we have a BRIDGE_IF set, add it to /etc/qemu/bridge.conf
mkdir -p /etc/qemu
echo "allow raspi-br0" >> /etc/qemu/bridge.conf

# Make sure we have the tun device node
if [ ! -e /dev/net/tun ]; then
    set +e
    mkdir -p /dev/net
    mknod /dev/net/tun c 10 200
    set -e
fi

## download
download() {
    curl -sL -O -C - "$1"
}

function install_from_git() {
    cd /home
    download https://github.com/V0rt3x667/victorpi/archive/refs/heads/master.zip
    unzip master.zip
    cd victorpi-master
    install -Dm755 victorpi -t /usr/bin/
    install -Dm755 victorpi/* -t /opt/victorpi/
    sed -i "s|OPT=.|OPT=\/opt|g" /usr/bin/victorpi
    cd ..
    rm -rf victorpi-master victorpi-master.zip
}

function install_ovmf() {
    local arch
    local fedurl="https://kojipkgs.fedoraproject.org//packages/edk2"
    local fedver=38
    local pkgrel=1
    local pkgver=20220826gitba0e0e4c6a17

    : "${OVMFFOLDER:=$victorpi/$MODEL/ovmf}"

    if [[ -d "${OVMFFOLDER}" ]]; then
        return
    else
        mkdir -p "${OVMFFOLDER}"
    fi

    if [[ "$MODEL" = "rpi-2" ]]; then
        cd "${OVMFFOLDER}"
        arch=arm
        download "$fedurl/$pkgver/$pkgrel.fc$fedver/noarch/edk2-$arch-$pkgver-$pkgrel.fc$fedver.noarch.rpm"
        rpm2cpio ./*.noarch.rpm | cpio -idmv
        checkDocker
        if [[ "$DOCKER" = "1" ]]; then
            cp -av usr /
            cd /usr/share/AAVMF
            ln -sf ../edk2/arm/vars-template-pflash.raw AAVMF32_VARS.fd
        else
            cd /usr/share/AAVMF
            ln -sf ../edk2/arm/vars-template-pflash.raw AAVMF32_VARS.fd
        fi
    elif [[ "$MODEL" = "rpi-3" ]]; then
        download "$fedurl/$pkgver/$pkgrel.fc$fedver/noarch/edk2-$arch-$pkgver-$pkgrel.fc$fedver.noarch.rpm"
        rpm2cpio ./*.noarch.rpm | cpio -idmv
        checkDocker
        if [[ "$DOCKER" = "1" ]]; then
            cp -av usr /
            cd /usr/share/AAVMF
            ln -sf ../edk2/arm/vars-template-pflash.raw AAVMF32_VARS.fd
        else
            cd /usr/share/AAVMF
            ln -sf ../edk2/arm/vars-template-pflash.raw AAVMF32_VARS.fd
        fi
    fi
}

echo "===> Installing VictorPi"
install_from_git

echo "===> Installing AVMF ARM & AARCH64"
install_ovmf

echo "===> DONE $0 $*"

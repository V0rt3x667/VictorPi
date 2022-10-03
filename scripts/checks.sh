#!/bin/bash

ARCH=
: "${GUESTPORT0:=22}"
: "${EXTERPORT0:=2222}"
: "${GUESTPORT1:=80}"
: "${EXTERPORT1:=8080}"

# Must be root for some ops
function checkRoot() {
    if [[ $(sudo whoami) != "root" ]]; then
        echo -e "[$FAIL] VictorPi will not continue"
        echo -e "[$FAIL] Please type your user password or run this script as root"
        exit 1
    fi
}

function checkUser() {
    whoami
}

function checkArch() {
    case $MODEL in
        rpi-2) ARCH="armv7" ;;
        rpi-3) ARCH="aarch64" ;;
        rpi-4) ARCH="aarch64" ;;
    esac
}

function finalizeIt() {
    umountParts
    umountImg
    checkQemu

    if [[ "$DOCKER" = "0" ]] && [[ "$QEMUISRUNNING" = "0" ]]; then
        killNetwork
    fi
}

function initChecks() {
     if [ "$SNDARG" != "-i" ]; then
         CMD=" -initrd $BOOTPATH/initramfs-linux.img"
     fi

    NETWORKCMD="$CMD -device virtio-net-device,mac=$(genMAC),netdev=net0 -netdev user,id=net0,hostfwd=tcp::$EXTERPORT0-:$GUESTPORT0,hostfwd=tcp::$EXTERPORT1-:$GUESTPORT1"
}

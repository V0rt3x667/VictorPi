#!/bin/bash

# Enable This For Debug Purpose Only
#set -x
VERSION=1.0.0
OPT=.

# You Can Overwrite Paths Using: VARNAME=value ./victorpi

# Software used in this script.
: "${BSDTAR:=bsdtar}"
: "${DNSMASQ:=dnsmasq}"
: "${EXT4:=mkfs.ext4}"
: "${EXT4CHK:=fsck.ext4}"
: "${FDISK:=fdisk}"
: "${FILE:=file}"
: "${GREP:=grep}"
: "${IP:=ip}"
: "${IPTABLES:=iptables}"
: "${PS:=ps}"
: "${QEMUARM:=qemu-system-arm}"
: "${QEMUARM64:=qemu-system-aarch64}"
: "${QEMUIMG:=qemu-img}"
: "${SUDO:=sudo}"
: "${VFAT:=mkfs.vfat}"
: "${VFATCHK:=fsck.vfat}"
: "${CURL:=curl}"
PROGS=("$BSDTAR" "$DNSMASQ" "$EXT4" "$FDISK" "$FILE" "$GREP" "$IPTABLES" \
"$PS" "$QEMUARM" "$QEMUARM64" "$QEMUIMG" "$SUDO" "$VFAT" "$CURL")

# Parameters, Folders and Files
: "${VICTORPI:=$HOME/.victorpi}"
USER=$(whoami)
SNDARG=$2
MODEL=$1
FAMILIES=4
: "${FILENAME:=sd-arch-$MODEL-qemu.img}"
ARCHIMGPATH=$VICTORPI/$FILENAME

# Import External Scripts
. $OPT/victorpi/scripts/checks.sh
. $OPT/victorpi/scripts/docker.sh
. $OPT/victorpi/scripts/storage.sh
. $OPT/victorpi/scripts/custom.sh
. $OPT/victorpi/scripts/images.sh
. $OPT/victorpi/scripts/network.sh
. $OPT/victorpi/scripts/qemu.sh
. $OPT/victorpi/scripts/runemu.sh

# Text Colors
FAIL='\e[0;31mFAILED\e[0m'
PASS='\e[0;32m  OK  \e[0m'
WARN='\e[0;33m WARN \e[0m'
G='\e[0;32m'
RST='\e[0m'

checkModel() {
    if [[ ${MODEL##*-} = 1 ]] || [[ ${MODEL##*-} -gt ${FAMILIES} ]] || [[ ${#MODEL} -gt 5 ]]; then
        echo "Please Select the RPI Model"
        echo "Available: rpi-2 rpi-3 rpi-4"
        exit 1
    fi
}

checkDeps() {
    for i in "${PROGS[@]}"; do
        if command -v "$i" > /dev/null; then
            echo -e "[$PASS] $i executable found"
        else
            echo -e "[$FAIL] $i executable not found. Please install it on your distro"
            exit 1;
        fi
    done
}

version() {
echo -e "\e[38;5;$((RANDOM%257))m" && cat << '_EOF_'
 ▄▄   ▄▄ ▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄   ▄▄▄▄▄▄▄ ▄▄▄ 
█  █ █  █   █       █       █       █   ▄  █ █       █   █
█  █▄█  █   █       █▄     ▄█   ▄   █  █ █ █ █    ▄  █   █
█       █   █     ▄▄█ █   █ █  █ █  █   █▄▄█▄█   █▄█ █   █
█       █   █    █    █   █ █  █▄█  █    ▄▄  █    ▄▄▄█   █
 █     ██   █    █▄▄  █   █ █       █   █  █ █   █   █   █
  █▄▄▄█ █▄▄▄█▄▄▄▄▄▄▄█ █▄▄▄█ █▄▄▄▄▄▄▄█▄▄▄█  █▄█▄▄▄█   █▄▄▄█

_EOF_

echo v$VERSION
echo "Created by V0rt3x667"

exit 0
}

help () {
    echo "Emulate a Raspberry Pi SBC on an x86-64 Machine."
    echo ""
    echo -e "Default Storage Location: $G$VICTORPI$RST"
    echo ""
    echo "Usage: ./victorpi MODEL [<opts>]"
    echo "Available MODELs: rpi-2 rpi-3 rpi-4"
    echo "<opts>  -h                     Print this message"
    echo "        -c                     Check Filesystem Integrity of Disk Image"
    echo "        -e                     Purge Everything in the Storage Folder"
    echo "        -k                     Kill Every Instance and Network Virtual Interface"
    echo "        -i    <path/to/img>    Run a Custom Disk Image"
    echo "        -l                     List Files in the Storage Folder"
    echo "        -m                     Mount ${MOUNTFOLDERS[0]} and ${MOUNTFOLDERS[1]} Partitions"
    echo "        -p                     Purge Everything Except for Downloaded Archives"
    echo "        -r                     Run an Instance of QEMU for the Defined Model"
    echo "        -s    <size in GB>     Write a Partitioned RAW Image Disk with Arch Linux ARM Installed"
    echo "        -u                     Unmount ${MOUNTFOLDERS[0]} and ${MOUNTFOLDERS[1]} Partitions"
    echo "Examples:"
    echo "        ./victorpi rpi-3 -s 2   Create a 2GB SD Card .img for the rpi-3"
    echo "        ./victorpi rpi-2 -p     Purge Everything Related to rpi-2 Image Creation"
    exit 0
}

process_args () {
    # Process other arguments.
    case "$1" in
        rpi*   ) checkModel ;;
        -h     ) help ;;
        -v     ) version ;;
        *      ) checkModel ;;
    esac
    
    case "$2" in
        -c    ) isMounted && checkMount ;;
        -e    ) isMounted && checkMount && purge && purgeEverything ;;
        -i    ) runCustomImg "$3" && isMounted && checkMount && run_emu ;;
        -k    ) checkQemu && killQemu && fkillNetwork ;;
        -l    ) checkFolders && listStorage ;;
        -m    ) isMounted && checkMount ;;
        -p    ) isMounted && checkMount && purge ;;
        -r    ) isMounted && checkMount && run_emu ;;
        -s    ) checkFolders && createArchImg "$3" ;;
        -u    ) isMounted && checkMount ;;
        *     ) help ;;
    esac
}

process_args "$@";

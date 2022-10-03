#!/bin/bash

checkArch

ARCHISO="ArchLinuxARM-rpi-$ARCH-latest.tar.gz"
FILES=("$ARCHISO" "$ARCHISO.md5")

function integrityCheck() {
    cd "$VICTORPI/$MODEL" || exit

    if md5sum --status -c "$ARCHISO.md5"; then
        echo -e "[$PASS] Integrity check successfully completed"
    else
        echo -e "[$FAIL] Integrity check failed, please retry to download"
        purgeEverything
        exit 1
    fi
}

function downloadKernel() {
    local kver
    local apiurl="https://api.github.com/repos/M0Rf30/qemu-kernel-$MODEL/releases/latest"
    local giturl="https://github.com/M0Rf30/qemu-kernel-$MODEL/releases/download"

    if [[ -d "$KERNELPATH" ]]; then
        return
    else
        mkdir -p "$KERNELPATH"
    fi

    cd "$KERNELPATH" || exit
    kver=$(curl --silent --no-buffer $apiurl | grep -m 1 tag_name | cut -d\" -f4)
    curl -sL -# -O -C - "$giturl/$kver/qemu_kernel_${MODEL/-/_}-$kver"
}

function downloadOVFM() {
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
        arch=arm
    else
        arch=aarch64
    fi

    cd "$OVMFPATH" || exit
    curl -sL -# -O -C - "$fedurl/$pkgver/$pkgrel.fc$fedver/noarch/edk2-$arch-$pkgver-$pkgrel.fc$fedver.noarch.rpm"
    bsdtar xf ./*.noarch.rpm --strip-components=3
    ln -sf ./edk2/$arch/vars-template-pflash.raw ./AAVMF/AAVMF32_VARS.fd
    rm ./*.noarch.rpm
}

function downloadArchImage() {
    for i in "${FILES[@]}"; do
        if [ -f "$VICTORPI/$MODEL/$i" ]; then
            echo -e "[$WARN] $i is present";
        else
            echo -e "[$PASS] Downloading ..."
            curl -# -L -C - "http://os.archlinuxarm.org/os/$i" -o "$VICTORPI/$MODEL/$i"
        fi
    done

    integrityCheck
}

function createArchImg() {
    GIGA="$1"
    isaNumber='^[0-9]+$'

    if ! [[ "$GIGA" =~ $isaNumber ]] || [ -z "$GIGA" ]; then
        echo -e "[$FAIL] Please specify a size in GB"
        exit 1
        elif [ "$GIGA" -lt 2 ]; then
        echo -e "[$FAIL] Please specify a size >= 2 GB"
        exit 1
    fi

    downloadKernel
    downloadOVFM
    isMounted
    downloadArchImage

    if [ -e "$ARCHIMGPATH" ]; then
        echo -e "[$WARN] An ${ARCHIMGPATH##*/} file already exists. Please delete it"
        exit 1
    else
        echo -e "[$PASS] Creating a $GIGA GB disk image named ${ARCHIMGPATH##*/} ..."
        $QEMUIMG create -f raw "$ARCHIMGPATH" "$GIGA"G > /dev/null
        echo -e "[$PASS] Creating partition table on ${ARCHIMGPATH##*/} ..."
        (echo o; echo n; echo p; echo 1; echo 8192; echo +100M; echo t; echo c; \
        echo n; echo p; echo 2; echo 8192; echo ; echo ; echo w) | \
        $FDISK "$ARCHIMGPATH" >/dev/null 2>&1
    fi

    sync
    mapImg
    checkRoot
    checkLoop
    mountImg
    formatLoDevices
    mountParts
    echo -e "[$PASS] Extracting $ARCHISO to ${ARCHIMGPATH##*/} ..."
    sudo "$BSDTAR" --exclude=^boot -xpf "$VICTORPI/$MODEL/$ARCHISO" -C "$ROOTPATH"
    sudo "$BSDTAR" -xpf "$VICTORPI/$MODEL/$ARCHISO" boot/* -C "$BOOTPATH" > /dev/null 2>&1
    customContent
    sync
    umountParts
    umountImg
    sudo chown "$USER:$USER" "$ARCHIMGPATH"
    echo -e "[$PASS] DONE"
}

function runCustomImg() {
    CUSTOMIMG="$1"

    if [ -z "$CUSTOMIMG" ]; then
        echo -e "[$FAIL] Please specify an image path"
        exit 1
        elif [ ! -f "$CUSTOMIMG" ]; then
        echo -e "[$FAIL] File not found"
        exit 1
        elif [ "$(file "$CUSTOMIMG" | cut -d  ' ' -f 2)" != "DOS/MBR" ]; then
        echo -e "[$FAIL] Please specify a valid disk image"
        exit 1
    else
        echo -e "[$PASS] Running with disk image named ${CUSTOMIMG##*/}"
    fi
}

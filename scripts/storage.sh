#!/bin/bash

MOUNTFOLDERS=("boot" "root")
BOOTPATH="$VICTORPI/$MODEL/${MOUNTFOLDERS[0]}"
ROOTPATH="$VICTORPI/$MODEL/${MOUNTFOLDERS[1]}"
IMGMOUNTED=
PMOUNTED=
START1=
START2=
LENGTH1=
LENGTH2=
LOOPFLAG=$(losetup -l | cut -d " " -f 15 | tail -n +2 | head -n +1)

function checkFolders() {
    for i in "${MOUNTFOLDERS[@]}"; do
        if [ -d "$VICTORPI/$MODEL/$i" ]; then
            echo -e "[$WARN] $MODEL/$i folder is present"
        else
            echo -e "[$PASS] Creating $MODEL/$i folder ..."
            mkdir -p "$VICTORPI/$MODEL/$i"
            chown -R "$USER:$USER" "$VICTORPI/$MODEL/$i"
        fi
    done
}

function checkFs() {
    echo -e "[$PASS] Checking partitions to prevent failures ..."
    sudo -E "$VFATCHK" -fp "$DEVICE1" > /dev/null 2>&1
    sudo -E "$EXT4CHK" -fp "$DEVICE2" > /dev/null 2>&1
    sync
}

function checkLoop() {
    DEVICE1=$(sudo -E losetup -f)
    DEVICE2=/dev/loop$(( ${DEVICE1##*/loop} + 1 ))
    
    if [[ ${DEVICE2##*/loop} -gt 5 ]]; then
        echo -e "[$WARN] You are using more than 3 instances"
    fi
}

function checkMount() {
    if [ "$SNDARG" = "-c" ]; then
        if [[ "$IMGMOUNTED" = "0" ]] && [[ "$PMOUNTED" = "0" ]]; then
            mapImg
            checkRoot
            checkLoop
            mountImg
            checkFs
            umountImg
        elif [[ "$IMGMOUNTED" = "1" ]] && [[ "$PMOUNTED" = "0" ]]; then
            checkRoot
            checkFs
            umountImg
        elif [[ "$PMOUNTED" = "1" ]]; then
            checkRoot
            umountParts
            checkFs
            umountImg
        else
            exit 1
        fi
    fi

    if [[ "$SNDARG" = "-e" ]] || [[ "$SNDARG" = "-p" ]]; then
        if [[ "$IMGMOUNTED" = "0" ]] && [[ "$PMOUNTED" = "0" ]]; then
            return
        elif [[ "$IMGMOUNTED" = "1" ]] && [[ "$PMOUNTED" = "0" ]]; then
            checkRoot
            umountImg
        elif [[ "$PMOUNTED" = "1" ]]; then
            checkRoot
            umountParts
            umountImg
        fi
    fi

    if [[ "$SNDARG" = "-m" ]]; then
        if [[ "$IMGMOUNTED" = "0" ]] && [[ "$PMOUNTED" = "0" ]]; then
            mapImg
            checkRoot
            checkLoop
            mountImg
            checkFs
            checkFolders
            mountParts
        elif [[ "$IMGMOUNTED" = "1" ]] && [[ "$PMOUNTED" = "0" ]]; then
            checkRoot
            checkLoop
            checkFs
            checkFolders
            mountParts
        elif [[ "$PMOUNTED" = "1" ]]; then
            return
        else
            exit 1
        fi
    fi

    if [[ "$SNDARG" = "-r" ]] || [[ "$SNDARG" = "-i" ]]; then
        if [[ "$IMGMOUNTED" = "0" ]] && [[ "$PMOUNTED" = "0" ]]; then
            mapImg
            checkRoot
            checkLoop
            mountImg
            checkFs
            checkFolders
            mountParts
        elif [[ "$IMGMOUNTED" = "1" ]] && [[ "$PMOUNTED" = "0" ]]; then
            checkRoot
            checkLoop
            checkFolders
            mountParts
        elif [[ "$PMOUNTED" = "1" ]]; then
            return
        else
            exit 1
        fi
    fi

    if [[ "$SNDARG" = "-u" ]]; then
        if [[ "$IMGMOUNTED" = "0" ]] && [[ "$PMOUNTED" = "0" ]]; then
            echo -e "[$WARN] ${ARCHIMGPATH##*/} disk image not mounted"
        elif [[ "$IMGMOUNTED" = "1" ]] && [[ "$PMOUNTED" = "0" ]]; then
            checkRoot
            umountImg
        elif [[ "$PMOUNTED" = "1" ]]; then
            checkRoot
            umountParts
            umountImg
        else
            exit 1
        fi
    fi
}

function isMounted() {
    if [[ -n "$CUSTOMIMG" ]] && [[ "$ARCHIMGPATH" != "$CUSTOMIMG" ]]; then
        ARCHIMGPATH="$CUSTOMIMG"
    fi

    if mount | grep "$VICTORPI/$MODEL" > /dev/null; then
        IMGMOUNTED=1
        PMOUNTED=1
    elif ! mount | grep "$VICTORPI/$MODEL" > /dev/null && [ -n "${LOOPFLAG}" ]; then
        IMGMOUNTED=1
        PMOUNTED=0
    elif [[ ! -f "$ARCHIMGPATH" ]]; then
        echo -e "[$WARN] No sd image to use on QEMU. Perhaps you have purged ${ARCHIMGPATH##*/}"
        IMGMOUNTED=2
        PMOUNTED=2
    else
        IMGMOUNTED=0
        PMOUNTED=0
    fi
}

function formatLoDevices() {
    echo -e "[$PASS] Creating partitions on disk image named ${ARCHIMGPATH##*/} ..."
    sudo -E "$VFAT" -n boot -F 32 "$DEVICE1" > /dev/null 2>&1
    sudo -E "$EXT4" -L rootfs "$DEVICE2" > /dev/null 2>&1
    sync
}

function mountParts() {
    echo -e "[$PASS] Mounting partitions of ${ARCHIMGPATH##*/} ..."
    sudo -E mount "$DEVICE1" "$BOOTPATH"
    sudo -E mount "$DEVICE2" "$ROOTPATH"
}

function umountParts() {
    echo -e "[$PASS] Umounting partitions: ${ARCHIMGPATH##*/} ..."
    sudo -E umount "$BOOTPATH"
    sudo -E umount "$ROOTPATH"
}

function listStorage() {
    checkFolders
    echo -e "[$WARN] Content of $VICTORPI/$MODEL"
    ls "$VICTORPI/$MODEL"
}

function mapImg() {
    echo -e "[$PASS] Mapping partition lengths ..."
    START1=$(fdisk -lo Start "$ARCHIMGPATH" | tail -n 2 | head -n -1)
    START2=$(fdisk -lo Start "$ARCHIMGPATH" | tail -n 1)
    LENGTH1=$(fdisk -lo Sectors "$ARCHIMGPATH" | tail -n 2 | head -n -1)
    LENGTH2=$(fdisk -lo Sectors "$ARCHIMGPATH" | tail -n 1)
}

function mountImg() {
    echo -e "[$PASS] Mounting disk image: ${ARCHIMGPATH##*/} ..."
    sudo -E losetup -o $(( START1*512 )) --sizelimit $(( LENGTH1*512 )) \
    "$DEVICE1" "$ARCHIMGPATH" > /dev/null 2>&1
    sudo -E losetup -o $(( START2*512 )) --sizelimit $(( LENGTH2*512 )) \
    "$DEVICE2" "$ARCHIMGPATH" > /dev/null 2>&1
}

function umountImg() {
    echo -e "[$PASS] Unmounting disk image named ${ARCHIMGPATH##*/} ..."
    sudo -E losetup -D
}

function purge () {
    if [[ "$IMGMOUNTED" != "2" ]]; then
        echo -e "[$PASS] Soft cleaning ..."
        rm -rf "$ARCHIMGPATH"
    fi
}

function purgeEverything() {
    echo -e "[$PASS] Hard cleaning ..."
    rm -rf "${VICTORPI:?}/$MODEL/"
}

#!/bin/bash

: "${CUSTOMDATAFOLDER:=$VICTORPI/$MODEL/data}"
: "${EXTPKGSFOLDER:=$VICTORPI/$MODEL/pkgs}"

function customContent() {
    if [ -d "$CUSTOMDATAFOLDER" ]; then
        echo -e "[$WARN] $CUSTOMDATAFOLDER folder is present"
        if [ "$(ls "$CUSTOMDATAFOLDER")" ]; then
            echo -e "[$WARN] Copying custom content to ${ARCHIMGPATH##*/} ..."
            for i in "$CUSTOMDATAFOLDER"/*; do
                echo -e "	[$PASS] Copying ${i##*/} in /home/alarm ..."
                sudo -E cp "$i" "$ROOTPATH/home/alarm"
                sync
            done
        else
            echo -e "[$WARN] $CUSTOMDATAFOLDER is empty"
        fi
    else
        echo -e "[$WARN] $CUSTOMDATAFOLDER folder not present. Creating ..."
        mkdir -p "$CUSTOMDATAFOLDER"
        echo -e "[$WARN] You could add custom content on img copying it under $CUSTOMDATAFOLDER"
    fi
    
    if [ -d "$EXTPKGSFOLDER" ]; then
        echo -e "[$WARN] $EXTPKGSFOLDER folder is present"
        if [ "$(ls "$EXTPKGSFOLDER")" ]; then
            echo -e "[$WARN] Installing packages on ${ARCHIMGPATH##*/} ..."
            for i in "$EXTPKGSFOLDER"/*; do
                echo -e "	[$PASS] Installing ${i##*/} with pacman ..."
                checkArch
                sudo -E pacman --arch "$ARCH" -U "$i"  --root "$ROOTPATH" \
                --dbpath "$ROOTPATH/var/lib/pacman" --noconfirm > /dev/null 2>&1
                sync
            done
        else
            echo -e "[$WARN] $EXTPKGSFOLDER is empty"
        fi
    else
        echo -e "[$WARN] $EXTPKGSFOLDER folder not present. Creating ..."
        mkdir -p "$EXTPKGSFOLDER"
        echo -e "[$WARN] Pacman compliant packages under $EXTPKGSFOLDER will be automatically installed"
    fi
}

#!/bin/bash

function run_rpi2() {
    QEMURPI2="$QEMUARM -nographic \
        -M virt,accel=tcg \
        -cpu cortex-a7 \
        -smp 4 \
        -m 1024 \
        -device virtio-blk-device,drive=hd0 \
        -device virtio-blk-device,drive=hd1 \
        -drive file=$OVMFPATH/edk2/${ARCH/v7/}/QEMU_EFI-pflash.raw,if=pflash,format=raw,readonly=on \
        -drive file=$OVMFPATH/edk2/${ARCH/v7/}/vars-template-pflash.raw,if=pflash,format=raw \
        -drive file=fat:rw:$KERNELPATH,if=none,format=raw,cache=none,id=hd0 \
        -drive file=$ARCHIMGPATH,if=none,format=raw,cache=none,id=hd1 \
        -kernel $KERNELPATH/qemu_kernel_${MODEL/-/_}-5.19.11 \
        -append \"root=/dev/vda2 fstab=no rootfstype=ext4 rw audit=0 console=ttyAMA0 loglevel=0 panic=1 quiet\""

    QEMURPI2+="$NETWORKCMD"
    eval "$QEMURPI2"
}

function run_rpi3() {
    QEMURPI3="$QEMUARM64 -nographic \
        -M virt,accel=tcg \
        -cpu cortex-a57 \
        -smp 4 \
        -m 2048 \
        -device virtio-blk-device,drive=hd0 \
        -device virtio-blk-device,drive=hd1 \
        -drive file=$OVMFPATH/edk2/$ARCH/QEMU_EFI-pflash.raw,if=pflash,format=raw,readonly=on \
        -drive file=$OVMFPATH/edk2/$ARCH/vars-template-pflash.raw,if=pflash,format=raw \
        -drive file=fat:rw:$KERNELPATH,if=none,format=raw,cache=none,id=hd0 \
        -drive file=$ARCHIMGPATH,if=none,format=raw,cache=none,id=hd1 \
        -kernel $KERNELPATH/qemu_kernel_${MODEL/-/_}-5.19.11 \
        -append \"root=/dev/vda2 fstab=no rootfstype=ext4 rw audit=0 console=ttyAMA0 loglevel=0 panic=1 quiet\""

    QEMURPI3+=$NETWORKCMD
    eval "$QEMURPI3"
}

function run_emu() {
    case $MODEL in
        rpi-2  ) initChecks && run_rpi2 && finalizeIt ;;
        rpi-3  ) initChecks && run_rpi3 && finalizeIt ;;
        rpi-4  ) initChecks && run_rpi3 && finalizeIt ;;
    esac
}

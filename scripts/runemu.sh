#!/bin/bash

run_rpi2() {
    QEMURPI2="$QEMUARM -nographic \
        -M virt \
        -cpu cortex-a7 \
        -smp 4 \
        -m 1024 \
        -device virtio-blk-device,drive=hd0 \
        -device virtio-blk-device,drive=hd1 \
        -drive file=/home/aaron/Projects/virtual-pi/rpi2/edk2/QEMU_EFI-pflash.raw,if=pflash,format=raw,readonly=on \
        -drive file=/home/aaron/Projects/virtual-pi/rpi2/edk2/vars-template-pflash.raw,if=pflash,format=raw \
        -drive file=fat:rw:/home/aaron/Projects/virtual-pi/rpi2/kernel,if=none,format=raw,cache=none,id=hd0 \
        -drive file=/home/aaron/Projects/virtual-pi/rpi2/sd-arch-rpi-2-qemu.img,if=none,format=raw,cache=none,id=hd1 \
        -kernel /home/aaron/Projects/virtual-pi/rpi2/kernel/qemu_kernel_rpi_2-5.19.11 \
        -append "root=/dev/vda2 fstab=no rootfstype=ext4 rw audit=0 console=ttyAMA0 loglevel=0 panic=1 quiet""

    QEMURPI2+="$NETWORKCMD"
    eval "$QEMURPI2"
}

run_rpi3() {
    QEMURPI3="$QEMUARM64 -nographic \
    -machine virt-5.0,accel=tcg,gic-version=3 \
    -cpu cortex-a57 \
    -m 2048 \
    -drive file=$VICTORPI/edk2/aarch64/QEMU_EFI-pflash.raw,if=pflash,format=raw,readonly=on \
    -drive file=$VICTORPI/edk2/aarch64/vars-template-pflash.raw,if=pflash,format=raw \
    -drive file=fat:rw:$OPT/victorpi/kernels/$MODEL,if=none,format=raw,cache=none,id=hd0 \
    -device virtio-blk-device,drive=hd0 \
    -drive file=$ARCHIMGPATH,if=none,format=raw,cache=none,id=hd1 \
    -device virtio-blk-device,drive=hd1 \
    -kernel $OPT/victorpi/kernels/$MODEL/Image \
    -append \"root=/dev/vda2 fstab=no rootfstype=ext4 rw audit=0 console=ttyAMA0\""
    
    QEMURPI3+=$NETWORKCMD
    eval "$QEMURPI3"
}

run_emu() {
    case $MODEL in
        rpi-2  ) initChecks && run_rpi2 && finalizeIt ;;
        rpi-3  ) initChecks && run_rpi3 && finalizeIt ;;
        rpi-4  ) initChecks && run_rpi3 && finalizeIt ;;
    esac
}

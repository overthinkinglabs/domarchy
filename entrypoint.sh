#!/bin/bash

DISK=/data/omarchy.qcow2
ISO=/data/omarchy.iso
MEMORY=${MEMORY:-8G}
CPUS=${CPUS:-4}

if [[ ! -f "$ISO" ]]; then
    echo "Downloading Omarchy ISO..."
    wget -O "$ISO" "https://iso.omarchy.org/omarchy-3.5.1-2.iso" || echo "Download failed"
fi

# Check if this is first boot (disk doesn't exist)
if [[ ! -f "$DISK" ]]; then
    echo "Creating disk image..."
    qemu-img create -f qcow2 "$DISK" 50G
    CDROM_OPTION="-cdrom $ISO"
    BOOT_ORDER="dc"
else
    echo "Starting Omarchy..."
    CDROM_OPTION=""
    BOOT_ORDER="d"
fi

exec qemu-system-x86_64 \
    -m $MEMORY -smp $CPUS -machine q35,accel=kvm:tcg \
    -drive file="$DISK",format=qcow2 \
    $CDROM_OPTION \
    -boot order=$BOOT_ORDER \
    -display vnc=:0 \
    -device VGA,edid=on,xres=1760,yres=990,vgamem_mb=32 \
    -audiodev pa,id=audio0,server=unix:/tmp/pulse.socket \
    -device ich9-intel-hda \
    -device hda-output,audiodev=audio0 \
    -net user,smb=/shared \
    -net nic

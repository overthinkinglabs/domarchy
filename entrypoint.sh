#!/bin/bash

DISK=/data/omarchy.qcow2
ISO=/data/omarchy.iso
MEMORY=${MEMORY:-8G}
CPUS=${CPUS:-4}

if [[ ! -f "$ISO" ]]; then
    echo "Downloading Omarchy ISO..."
    wget -O "$ISO" "https://iso.omarchy.org/omarchy-4.0.0.iso" || echo "Download failed"
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

# Only wire up audio when the host actually passed a PulseAudio socket through.
# QEMU aborts at startup if the pa backend cannot reach the socket, which is
# what happens on hosts that have no PulseAudio to bind mount (macOS, Windows).
AUDIO_ARGS=()
if [[ -S /tmp/pulse.socket ]]; then
    AUDIO_ARGS=(
        -audiodev pa,id=audio0,server=unix:/tmp/pulse.socket
        -device ich9-intel-hda
        -device hda-output,audiodev=audio0
    )
else
    echo "No PulseAudio socket at /tmp/pulse.socket, starting without audio."
fi

websockify --web /opt/novnc 8900 localhost:5900 &

exec qemu-system-x86_64 \
    -m $MEMORY -smp $CPUS -machine q35,accel=kvm:tcg \
    -drive file="$DISK",format=qcow2 \
    $CDROM_OPTION \
    -boot order=$BOOT_ORDER \
    -display vnc=:0 \
    -device VGA,edid=on,xres=1920,yres=1080,vgamem_mb=32 \
    "${AUDIO_ARGS[@]}" \
    -net user,smb=/shared \
    -net nic

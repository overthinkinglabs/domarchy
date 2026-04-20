FROM archlinux:latest

RUN pacman -Syu --noconfirm --needed qemu-system-x86 qemu-img edk2-ovmf wget qemu-audio-pa samba

EXPOSE 5900

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]

#!/bin/bash

read -p "Enter the disk device (e.g., /dev/vda or /dev/sda): " DISK

# ライブ環境

# パーティションの作成
create_partitions() {
    parted $DISK mklabel msdos
    parted $DISK mkpart primary ext4 1MiB 551MiB       # /boot
    parted $DISK mkpart primary ext4 551MiB 100%      # /
}

# ファイルシステムの作成
create_filesystems() {
    mkfs.ext4 ${DISK}1   # /boot
    mkfs.ext4 ${DISK}2   # /
}

# マウントポイントの設定
mount_partitions() {
    mount ${DISK}2 /mnt
    mkdir /mnt/boot
    mount ${DISK}1 /mnt/boot
}

# ベースシステムのインストール
install_base_system() {
    pacstrap /mnt base linux linux-firmware
    genfstab -U /mnt >> /mnt/etc/fstab
}

# 新しいシステムにchroot
enter_chroot() {
    arch-chroot /mnt
}

# chroot環境の設定
configure_chroot() {
    pacman -S --noconfirm syslinux networkmanager

    # Syslinuxの設定
    mkdir /boot/syslinux
    cp -r /usr/lib/syslinux/bios/* /boot/syslinux/
    syslinux-install_update -i -a -m

    # /boot/syslinux/syslinux.cfgの編集
    sed -i "s|/dev/sda3|${DISK}2|g" /boot/syslinux/syslinux.cfg

    # rootパスワードの設定
    echo -e "password\npassword" | passwd
}

# スクリプト実行の流れ
main() {
    create_partitions
    create_filesystems
    mount_partitions
    install_base_system
    enter_chroot
    configure_chroot
    exit  # chrootから出る

    # システム再起動
    read -p "The system is about to reboot. Press any key to continue or Ctrl+C to cancel." -n 1 -s
    reboot
}

# 実行
main

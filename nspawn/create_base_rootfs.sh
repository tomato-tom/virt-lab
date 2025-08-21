#!/bin/bash
#
# nspawnで使うベースイメージ作成
# カスタム設定するには引数でファイル指定
# ./create_rootfs.sh [ <custom config> ]

set -euo pipefail

if [ -f ../lib/logger.sh ]; then
    source ../lib/logger.sh $0
else
    echo This script neads logger.sh
    exit 1
fi

# Install debootstrap if not exists
if ! [ -x "/usr/sbin/debootstrap" ]; then
    log warn "debootstrap not found, installing..."
    sudo apt-get update && sudo apt-get install -y debootstrap
fi

# Load configuration
if [ -f ./default.conf ]; then
    source ./default.conf
    log info "Load default.conf"
else
    log error "This script neads default.conf"
    exit 1
fi

[ "${1:-}" ] && source "$1"

WORK_DIR="/tmp/$DISTRO-base-rootfs"
SIZE=1G
IMAGE_DIR="/srv/nspawn_images"
TARBALL="$IMAGE_DIR/$DISTRO-base-rootfs.tar.gz"
HOSTNAME=$DISTRO

log info "Creating rootfs..."

if [ -d $WORK_DIR ]; then
    sudo umount $WORK_DIR && rm -rf $WORK_DIR/* || exit 1
else
    mkdir $WORK_DIR
fi

sudo mount -t tmpfs -o size=$SIZE tmpfs $WORK_DIR

sudo debootstrap \
    --include=$INCLUDE_PACKAGES \
    --variant=minbase \
    $DISTRO \
    $WORK_DIR

log info "Initial settings..."
echo "root:root" | sudo chroot $WORK_DIR chpasswd
sudo chroot $WORK_DIR bash -c "echo $HOSTNAME > /etc/hostname"

log info "Creating tarball..."

sudo mkdir -p $IMAGE_DIR
[ -f $TARBALL ] && sudo rm $TARBALL

sudo tar -czf $TARBALL -C $WORK_DIR . && \
log info "Base rootfs created: $TARBALL"

# Cleanup
sudo umount "$WORK_DIR" || log error "Error: Failed to unmount $WORK_DIR" >&2
sudo rm -rf "$WORK_DIR" || log error "Error: Failed to remove $WORK_DIR" >&2


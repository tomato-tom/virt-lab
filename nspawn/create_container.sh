#!/bin/bash

# base-rootfsよりコンテナ作成

if [ $# -eq 0 ]; then
    echo "Usage: $0 <container_name> [base_tar]"
    exit 1
fi

CONTAINER_NAME=$1
BASE_TAR=${2:-"/srv/nspawn_images/stable-base-rootfs.tar.gz"}
CONTAINER_DIR="/var/lib/machines/$CONTAINER_NAME"

if [ ! -f "$BASE_TAR" ]; then
    echo "Base rootfs tar not found: $BASE_TAR"
    ./create_rootfs.sh
fi

echo "Creating container $CONTAINER_NAME from $BASE_TAR"

sudo mkdir -p $CONTAINER_DIR
sudo tar -xzf "$BASE_TAR" -C "$CONTAINER_DIR"

# Update hostname
sudo chroot $CONTAINER_DIR bash -c "echo $CONTAINER_NAME > /etc/hostname"

echo "Container $CONTAINER_NAME created at $CONTAINER_DIR"


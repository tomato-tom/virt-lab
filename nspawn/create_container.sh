#!/bin/bash

# base-rootfsよりコンテナ作成
# ./create_container.sh c1

LOGGER="../lib/logger.sh"

if [ -f "$LOGGER" ];then
    source "$LOGGER" $0
else
    echo This script neads logger.sh
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "Usage: $0 <container_name> [base_tar][description]"
    exit 1
fi

CONTAINER_NAME=$1
# OS_TYPE: jammy, bookwormのようなのがやりやすいか
BASE_TAR=${2:-"/srv/nspawn_images/stable-base-rootfs.tar.gz"}
DESCRIPTION=$3
CONTAINER_DIR="/var/lib/machines/$CONTAINER_NAME"

if [ ! -f "$BASE_TAR" ]; then
    log warn "Base rootfs tar not found: $BASE_TAR"
    ./create_rootfs.sh
fi

log info "Creating container $CONTAINER_NAME from $BASE_TAR"

sudo mkdir -p $CONTAINER_DIR
sudo tar -xzf "$BASE_TAR" -C "$CONTAINER_DIR"

# Update hostname
sudo chroot $CONTAINER_DIR bash -c "echo $CONTAINER_NAME > /etc/hostname"

#
# メタデータ作成
META_DIR="/var/lib/machines/.meta"
sudo mkdir -p "$META_DIR"

sudo bash -c "cat > \"$META_DIR/$CONTAINER_NAME.conf\" <<EOL
CONTAINER_NAME=\"$CONTAINER_NAME\"
OS_TYPE=\"$OS_TYPE\"
DESCRIPTION=\"$DESCRIPTION\"
CREATED_DATE=\"$(date +%Y-%m-%d)\"
EOL"

log info "Container $CONTAINER_NAME created at $CONTAINER_DIR"


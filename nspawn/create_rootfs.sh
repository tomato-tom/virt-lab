#!/bin/bash
#
# nspawnで使うベースイメージ作成
# カスタム設定するには引数でファイル指定
# ./create_rootfs.sh [ <custom config> ]

# Install debootstrap if not exists
if ! command -v debootstrap &> /dev/null; then
    echo "debootstrap not found, installing..."
    sudo apt-get update && sudo apt-get install -y debootstrap
fi

# Load configuration
[ -f ./default.conf ] && source ./default.conf || exit 1
[ $1 ] && source $1

WORK_DIR="/tmp/$DISTRO-base-rootfs"
SIZE=1G
TARBALL="$DISTRO-base-rootfs.tar.gz"
IMAGE_DIR="/srv/nspawn_images"
HOSTNAME=$DISTRO

echo Creating rootfs...

[ -d $WORK_DIR ] && rm -rf $WORK_DIR
mkdir $WORK_DIR
sudo mount -t tmpfs -o size=$SIZE tmpfs $WORK_DIR

sudo debootstrap \
    --arch=$ARCH \
    --include=$INCLUDE_PACKAGES \
    $DISTRO \
    $WORK_DIR \
    $MIRROR

echo Initial settings...
echo "root:root" | sudo chroot $WORK_DIR chpasswd
sudo chroot $WORK_DIR bash -c "echo $HOSTNAME > /etc/hostname"

echo Creating tarball...

sudo mkdir -p $IMAGE_DIR
cd $IMAGE_DIR
[ -f $TARBALL ] && sudo rm $TARBALL

sudo tar -czf $TARBALL -C $WORK_DIR . && \
echo "Base rootfs created: $TARBALL"

# Cleanup
sudo umount $WORK_DIR
sudo rm -rf $WORK_DIR


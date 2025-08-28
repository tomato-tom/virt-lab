#!/bin/bash
#
# nspawnで使うベースイメージ作成
# デフォルトで'config/default.conf'読み込み
# カスタム設定するには、その後設定ファイル'config/custom.conf'で適宜変数上書き
# 例:
# ./create_rootfs.sh config/custom.conf

cd $(dirname ${BASH_SOURCE:-$0})

[ -f lib/common.sh ] && source lib/common.sh || {
    echo "Failed to source common.sh" >&2
    exit 1
}

load_logger $0
check_root || exit 1

# setup
bash lib/setup_nspawn.sh || exit 1

# Load default configuration
log info "Load default.conf"
load_config || {
    log error "This script neads default.conf"
    exit 1
}

# カスタム設定ファイルが引数渡されてたら読み込み
[ "${1:-}" ] && load_config $1 || {
    log warn "Failed to load custom config: $1"
    log info "Create default base rootfs: $1"
}

WORK_DIR="/tmp/$DISTRO-base-rootfs"
SIZE=1G
IMAGE_DIR="/srv/nspawn_images"
TARBALL="$IMAGE_DIR/$DISTRO-base-rootfs.tar.gz"
HOSTNAME=$DISTRO

log info "Creating rootfs..."

if [ -d $WORK_DIR ]; then
    umount $WORK_DIR && rm -rf $WORK_DIR/* || exit 1
else
    mkdir $WORK_DIR
fi

mount -t tmpfs -o size=$SIZE tmpfs $WORK_DIR

debootstrap \
    --include=$INCLUDE_PACKAGES \
    --variant=minbase \
    $DISTRO \
    $WORK_DIR

log info "Initial settings..."
echo "root:root" | chroot $WORK_DIR chpasswd
chroot $WORK_DIR bash -c "echo $HOSTNAME > /etc/hostname"

log info "Creating tarball..."

mkdir -p $IMAGE_DIR
[ -f $TARBALL ] && rm $TARBALL

tar -czf $TARBALL -C $WORK_DIR . && \
log info "Base rootfs created: $TARBALL"

# Cleanup
umount "$WORK_DIR" || log error "Error: Failed to unmount $WORK_DIR" >&2
rm -rf "$WORK_DIR" || log error "Error: Failed to remove $WORK_DIR" >&2


#!/bin/bash
# 指定のテンプレートがなければdebootstrapで作成
# 更新

set -e

NAME="$1"
TEMPLATE="$NAME-template"
TEMPLATE_DIR="/mnt/virt"
UBUNTU=("noble" "jammy" "focal")

cd $TEMPLATE_DIR

# 引数チェック
if [ $NAME == "bookworm" ]
  MIRROR="http://ftp.jp.debian.org/debian/"
elif [[ " $UBUNTU[*]} " =~ " $NAME " ]];then
  MIRROR="http://archive.ubuntu.com/ubuntu/"
else
  echo "usage: ./deboot_template.sh <name>"
  echo "name: bookworm"
  echo "      noble"
  echo "      jammy"
  echo "      focal"
  exit
fi

# テンプレートのダウンロードあるいは更新
if [ -e "$TEMPLATE" ]; then
  echo template exist
else
  sudo debootstrap --variant=minbase $TEMPLATE $MIRROR
fi

# 更新
sudo chroot $TEMPLATE apt update
sudo chroot $TEMPLATE apt upgrade -y
sudo chroot $TEMPLATE apt autoremove -y
sudo chroot $TEMPLATE apt autoclean -y


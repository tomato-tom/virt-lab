#!/bin/bash
# テンプレートからコンテナ作成して起動
# すでにある場合はそのまま起動
#
# ./run_conteiner.sh myct
# ./run_conteiner.sh myct jammy

set -e

NAME="$1"
TEMPLATE="$2"
DIR="/mnt/virt"

# 引数がない場合は終了
if [ ! $1 ]
  echo "usage:"
  echo "run existing conteiner ./run_conteiner.sh <name>"
  echo "run new conteiner ./run_conteiner.sh <name> <template>"
  exit
fi

# 作業ディレクトリに移動
cd $DIR

# 起動
run() {
  sudo unshare --pid --mount-proc --net --uts --ipc --fork chroot $NAME bash -c "
    mount -t proc proc /proc &&
    mount -t sysfs sysfs /sys &&
    mount -t devtmpfs devtmpfs /dev &&
    hostname $NAME &&
    export PS1='\u@\h:\w\$ ' &&
    exec bash"
}

create() {
  sudo mkdir $NAME
  cp -a "$TEMPLATE-template" $NAME
}

cleanup() {
  sudo rm -rf $NAME/boot
  sudo rm -rf $NAME/tmp/*
  sudo rm -rf $NAME/var/log/*
  sudo rm -rf $NAME/usr/share/doc
  sudo rm -rf $NAME/usr/share/man
  echo "" > sudo $NAME/root/.bash_history
}


# 既存のコンテナがあったら起動
# なければテンプレートからコピー
# テンプレートなければ作成
if [ -e "$NAME" ]; then
  run
elif [ -e "$TEMPLATE-template" ]; then
  create
  run
else
  ./deboot_template.sh $TEMPLATE
  create
  run
fi



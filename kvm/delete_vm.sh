#!/bin/bash

usage() {
  if [ -z "$1" ]; then
    echo "Usage: $0 <vm-name>"
    exit 1
  fi
}

# 引数のチェック
if [ -z "$1" ]; then
  echo "VM name is required."
  usage
  exit 1
fi
NAME=$1

# VM の存在確認
if ! virsh list --all --name | grep -qw "$NAME"; then
  echo "NAME '$NAME' does not exist."
  usage
  exit 1
fi

# 起動中の場合は停止
if [ "$(virsh domstate "$NAME" 2>/dev/null)" == "running" ]; then
  virsh destroy "$NAME" || echo "Failed to stop NAME '$NAME'" && exit 1
fi

# VMの削除
if virsh undefine $NAME; then
  rm -f /srv/kvm-qemu/images/${NAME}.qcow2
  echo "VM $NAME has been deleted."
else
  echo "Failed to delete NAME '$NAME'."
fi


#!/bin/bash

# Create VM from tmplate qcow2 image

# デフォルト値の設定
DEFAULT_RAM=2048
DEFAULT_VCPUS=2
DEFAULT_OS_VARIANT="debian12"
DEFAULT_TEMPLATE="debian-template.qcow2"
DEFAULT_NETWORK="default"
IMAGES_PATH="/srv/kvm-qemu/images"
TEMPLATES_PATH="/srv/kvm-qemu/template"

# CentOS 9
# ./script/create_vm.sh -o centos-stream9 -t centos9-template.qcow2

# 既存のVM名を取得
EXISTING_VMS=$(virsh list --all --name)

# 新しいVM名を生成
VM_NAME="vm-1"
while [[ $EXISTING_VMS =~ (^|[[:space:]])$VM_NAME($|[[:space:]]) ]]; do
  VM_NUMBER=$((${VM_NAME##*-} + 1))
  VM_NAME="vm-${VM_NUMBER}"
done

# 引数の解析
while getopts "n:r:c:o:t:p:h" OPTION
do
  case $OPTION in
    n) VM_NAME=$OPTARG ;;
    r) RAM=$OPTARG ;;
    c) VCPUS=$OPTARG ;;
    o) OS_VARIANT=$OPTARG ;;
    t) TEMPLATE=$OPTARG ;;
    p) NETWORK=$OPTARG ;;
    h) echo "Usage: $0 [-n name] [-r ram] [-c vcpus] [-o os-variant] [-t template] [-p network]"
       exit 0 ;;
    *) echo "Invalid option: -$OPTARG" >&2
       exit 1 ;;
  esac
done

# デフォルト値の適用
RAM=${RAM:-$DEFAULT_RAM}
VCPUS=${VCPUS:-$DEFAULT_VCPUS}
OS_VARIANT=${OS_VARIANT:-$DEFAULT_OS_VARIANT}
TEMPLATE=${TEMPLATE:-$DEFAULT_TEMPLATE}
NETWORK=${NETWORK:-$DEFAULT_NETWORK}

# ディスクイメージのパス
DISK_PATH="${IMAGES_PATH}/${VM_NAME}.qcow2"

# テンプレートの存在確認
if [ ! -f "${TEMPLATES_PATH}/${TEMPLATE}" ]; then
  echo "Template file not found: ${TEMPLATES_PATH}/${TEMPLATE}" >&2
  exit 1
fi

# ディスクイメージの作成
sudo qemu-img create \
  -f qcow2 -b "${TEMPLATES_PATH}/${TEMPLATE}" \
  -F qcow2 "$DISK_PATH"

# VMの作成
virt-install --name "$VM_NAME" \
  --ram "$RAM" \
  --vcpus "$VCPUS" \
  --os-variant "$OS_VARIANT" \
  --disk path="${DISK_PATH}",format=qcow2 \
  --import \
  --network network="${NETWORK}" \
  --graphics none \
  --console pty,target_type=serial \
  --noautoconsole

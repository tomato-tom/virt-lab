#!/bin/bash
#
# vm_clone: KVM仮想マシンをクローン
# 使用例:
#   vm_clone vm1             # vm1 を vm1-clone としてクローン
#   vm_clone vm1 vm1-test    # vm1 を vm1-test としてクローン

# デフォルトのディスク保存先
IMAGES="/srv/kvm-qemu/images"

# ヘルプメッセージ
usage() {
  echo "Usage: $0 <original_vm_name> [new_vm_name]"
  exit 0
}

# エラーメッセージを表示して終了
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# 引数のチェック
if [ -z "$1" ]; then
  "Original VM name is required."
  usage
fi

VM="$1"
if [ "$2" ]; then
  CLONE="$2"
else
  CLONE="${VM}-clone"
fi

# VM の存在確認
if ! virsh list --all --name | grep -qw "$VM"; then
  "VM '$VM' does not exist."
  usage
fi

# VM が起動中の場合は停止
if [ "$(virsh domstate "$VM" 2>/dev/null)" == "running" ]; then
  virsh destroy "$VM" || error_exit "Failed to stop VM '$VM'."
fi

# クローン先のディスクイメージが既に存在するか確認
IMAGE_PATH="${IMAGES}/${CLONE}.qcow2"
if [ -f "$IMAGE_PATH" ]; then
  echo "Disk image '$IMAGE_PATH' already exists."
  usage
fi

# 実際にコマンドを実行
echo "Cloning VM '$VM' to '$CLONE'..."
virt-clone --original "$VM" --name "$CLONE" --file "$IMAGE_PATH"

# 結果を確認
if [ $? -eq 0 ]; then
  echo "Successfully cloned VM '$VM' to '$CLONE'."
else
  error_exit "Failed to clone VM '$VM'."
fi


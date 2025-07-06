#!/bin/bash
# 指定のテンプレートがなければdebootstrapで作成
# 更新

set -euo pipefail
trap 'echo "Error occurred at line $LINENO"' ERR

# 変数設定
NAME="$1"
TEMPLATE="$NAME-template"
TEMPLATE_DIR="/mnt/virt"
UBUNTU=("noble" "jammy" "focal")
LOG_FILE="/var/log/deboot_template.log"
SCRIPT_DIR="$HOME/script"

# ログ出力設定
exec > >(sudo tee -a "$LOG_FILE") 2>&1
echo "[$(date)] Starting template creation for $NAME"

# 引数チェック
if [[ "$NAME" == "bookworm" ]]; then
  MIRROR="http://ftp.jp.debian.org/debian/"
elif [[ " ${UBUNTU[@]} " =~ " $NAME " ]]; then
  MIRROR="http://archive.ubuntu.com/ubuntu/"
else
  echo "Usage: $0 <name>"
  echo "Supported names:"
  echo "  bookworm (Debian)"
  echo "  noble, jammy, focal (Ubuntu)"
  exit 1
fi

# テンプレートのダウンロードあるいは更新
if [ -d "$TEMPLATE_DIR/$TEMPLATE" ]; then
  echo "[$(date)] Template already exists: $TEMPLATE_DIR/$TEMPLATE"
else
  echo "[$(date)] Creating new template: $TEMPLATE_DIR/$TEMPLATE"
  sudo debootstrap --variant=minbase "$NAME" "$TEMPLATE_DIR/$TEMPLATE" "$MIRROR"
fi

# 更新
echo "[$(date)] Updating template..."
sudo cp "$SCRIPT_DIR/ubuntu_update.sh" "$TEMPLATE_DIR/$TEMPLATE/usr/bin/ubuntu_update"
sudo chroot "$TEMPLATE_DIR/$TEMPLATE" ubuntu_update
sudo rm "$TEMPLATE_DIR/$TEMPLATE/usr/bin/ubuntu_update"

# ubuntu_update debianでもつかえるかな？？

# 不要なキャッシュを削除
echo "[$(date)] Cleaning up cache..."
sudo rm -rf "$TEMPLATE_DIR/$TEMPLATE/var/cache/apt/archives/*"
sudo rm -rf "$TEMPLATE_DIR/$TEMPLATE/var/lib/apt/lists/*"

# 圧縮
echo "[$(date)] Compressing template..."
sudo tar -czf "$TEMPLATE_DIR/$TEMPLATE.tar.gz" \
  -C "$TEMPLATE_DIR" "$TEMPLATE" \
  --warning=no-file-changed \
  --ignore-failed-read
echo "[$(date)] Template compressed to $TEMPLATE_DIR/$TEMPLATE.tar.gz"

echo "[$(date)] Template creation completed successfully."


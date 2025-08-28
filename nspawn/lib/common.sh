#!/bin/bash -e
# 共通設定とユーティリティ関数
# lib/common.sh

# スクリプトのディレクトリ設定
LIB_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

# lib/logger.sh の読み込み
if [ -f ${LIB_DIR}/logger.sh ]; then
  source ${LIB_DIR}/logger.sh
else
  echo "Error: logger.sh not found in ${LIB_DIR}/"
  exit 1
fi

# root権限チェック
check_root() {
  if [ "$(id -u)" != "0" ]; then
    log error "Must be run with root privileges"
    return 1
  fi
}

# 設定読み込み
load_config() {
    local config_file="${1:-../config/default.conf}"
    [ -f "$config_file" ] && source "$config_file" || return 1
}


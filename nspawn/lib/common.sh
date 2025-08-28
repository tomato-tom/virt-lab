#!/bin/bash -e
# 共通設定とユーティリティ関数
# lib/common.sh

# スクリプトのディレクトリ設定

# lib/logger.sh の読み込み
load_logger() {
    if [ -f lib/logger.sh ]; then
      source lib/logger.sh $1
    else
      echo "Error: logger.sh not found in lib"
      exit 1
    fi
}

# root権限チェック
check_root() {
  if [ "$(id -u)" != "0" ]; then
    log error "Must be run with root privileges"
    return 1
  fi
}

# 設定読み込み
load_config() {
    local config_file="${1:-config/default.conf}"
    [ -f "$config_file" ] && source "$config_file" || return 1
}


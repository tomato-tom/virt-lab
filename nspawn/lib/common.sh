#!/bin/bash
# 共通設定とユーティリティ関数

# 設定読み込み
load_config() {
    local config_file="${1:-config/default.conf}"
    [ -f "$config_file" ] && source "$config_file"
}



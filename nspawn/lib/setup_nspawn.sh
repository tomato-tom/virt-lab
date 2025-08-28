#!/bin/bash
# lib/setup_nspawn.sh

cd $(dirname ${BASH_SOURCE:-$0})
cd ..

[ -f lib/common.sh ] && source lib/common.sh || {
    echo "Failed to source common.sh" >&2
    exit 1
}

loard_logger $0
check_root

# パッケージインストール関数
install_packages() {
    local packages=("$@")
    local to_install=()
    
    for pkg in "${packages[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done
    
    if [ ${#to_install[@]} -gt 0 ]; then
        log info "Installing packages: ${to_install[*]}"
        apt-get update || log error "apt update failed"
        apt-get install -y "${to_install[@]}" || log error "apt install failed"
    fi
}

# 基本nspawnパッケージ
install_base() {
    local packages=(
        debootstrap
        systemd-container
    )
    install_packages "${packages[@]}"
}

# ユーティリティパッケージ
install_utils() {
    local packages=(
        iproute2
        nftables
        iputils-ping
        jq
    )
    install_packages "${packages[@]}"
    install_yq
}

# yqのインストール
install_yq() {
    if ! [ -f /usr/local/bin/yq ]; then
        log info "Installing yq..."
        wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
            -O /usr/local/bin/yq && \
            chmod +x /usr/local/bin/yq || log error "Failed to install yq"
    fi
}

# 必要に応じて呼び出し元で関数を呼び出す
# install_base
# install_utils
# install_yq

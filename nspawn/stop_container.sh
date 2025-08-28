#!/bin/bash
# コンテナ停止スクリプト
# root権限必要
# sudo ./stop_container.sh <name>

NAME=$1
SERVICE="container-${NAME}"

cd $(dirname ${BASH_SOURCE:-$0})

[ -f lib/common.sh ] && source lib/common.sh || {
    echo "Failed to source common.sh" >&2
    exit 1
}

cd $(dirname ${BASH_SOURCE:-$0})
check_root || exit 1

if [ -z "$NAME" ]; then
    echo "Usage: $0 <name>"
    exit 1
fi

is_running() {
    machinectl status "$NAME" >/dev/null 2>&1
}

is_exists() {
    machinectl image-status "$NAME" >/dev/null 2>&1
}

# コンテナ停止関数（段階的停止）
stop_container() {
    local max_wait=5  # 最大待機時間（秒）
    
    if ! is_running "$NAME"; then
        return 0  # 既に停止しているか存在しない
    fi

    log info "Stopping $NAME gracefully..."
    machinectl stop "$NAME"
    
    # 優雅な停止を待つ
    local waited=0
    while [ $waited -lt $max_wait ] && is_running "$NAME"; do
        sleep 1
        waited=$((waited + 1))
        log info "Waiting for graceful stop... ($waited/$max_wait)s"
    done
    
    if is_running "$NAME"; then
        log warn "Graceful stop failed, terminating..."
        machinectl terminate "$NAME"
        sleep 2
        
        # 終了を待つ
        waited=0
        max_wait=3
        while [ $waited -lt $max_wait ] && is_running "$NAME"; do
            sleep 1
            waited=$((waited + 1))
            log info "Waiting for terminate... ($waited/$max_wait)s"
        done
    fi
    
    if is_running "$NAME"; then
        log warn "Terminate failed, killing..."
        machinectl kill "$NAME"
        sleep 1
        
        # 最終確認
        if is_running "$NAME"; then
            log error "Warning: Container $NAME may still be running"
            return 1
        else
            log info "Container killed successfully"
            return 0
        fi
    fi
    
    log info "Container stopped successfully"
    return 0
}

# クリーンアップ関数
cleanup() {
    log info "Cleaning up..."
    # サービスが実行中なら停止
    if systemctl is-active --quiet "$SERVICE.service"; then
        log info "Stopping: $SERVICE.service"
        sudo systemctl stop "$SERVICE.service"
    fi
    
    # サービスユニットのクリーンアップ
    if systemctl status "$SERVICE.service" >/dev/null 2>&1; then
        log info "Resetting service unit: $SERVICE.service"
        sudo systemctl reset-failed "$SERVICE.service" 2>/dev/null || true
    fi

    if ip netns list | grep -qx "$NAME"; then
        log info "Removing network namespace: $NAME"
        sudo ip netns delete "$NAME" 2>/dev/null || true
    fi
}

if is_running; then
    if stop_container; then
        log info "Container stopped: $NAME"
        cleanup
    else
        log error "Container stop failed: $NAME"
        cleanup
        exsit 1
    fi
else
    log warn "$NAME is stopped or does not exist, but clean it just in case"
    cleanup
fi


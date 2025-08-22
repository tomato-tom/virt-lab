#!/bin/bash
# コンテナ停止スクリプト
# root権限必要
# sudo ./stop_container.sh <name>

NAME=$1
SERVICE="container-${NAME}"

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run with root" 1>&2
   exit 1
fi

if [ -z "$NAME" ]; then
    echo "Usage: $0 <name>"
    exit 1
fi

# コンテナ停止関数（段階的停止）
stop_container() {
    local max_wait=5  # 最大待機時間（秒）
    
    if ! machinectl | grep -q "$NAME"; then
        return 0  # 既に停止している
    fi

    echo "Stopping $NAME gracefully..."
    machinectl stop "$NAME"
    
    # 優雅な停止を待つ
    local waited=0
    while [ $waited -lt $max_wait ] && machinectl | grep -q "$NAME"; do
        sleep 1
        waited=$((waited + 1))
        echo "Waiting for graceful stop... ($waited/$max_wait)s"
    done
    
    if machinectl | grep -q "$NAME"; then
        echo "Graceful stop failed, terminating..."
        machinectl terminate "$NAME"
        sleep 2
        
        # 終了を待つ
        waited=0
        while [ $waited -lt 3 ] && machinectl | grep -q "$NAME"; do
            sleep 1
            waited=$((waited + 1))
        done
    fi
    
    if machinectl | grep -q "$NAME"; then
        echo "Terminate failed, killing..."
        machinectl kill "$NAME"
        sleep 1
        
        # 最終確認
        if machinectl | grep -q "$NAME"; then
            echo "Warning: Container $NAME may still be running"
            return 1
        else
            echo "Container killed successfully"
            return 0
        fi
    fi
    
    echo "Container stopped successfully"
    return 0
}

# クリーンアップ関数
cleanup() {
    echo "Cleaning up..."
    # サービスが実行中なら停止
    if systemctl is-active --quiet "$SERVICE.service"; then
        echo "Stopping: $SERVICE.service"
        sudo systemctl stop "$SERVICE.service"
    fi
    
    # サービスユニットのクリーンアップ
    if systemctl status "$SERVICE.service" >/dev/null 2>&1; then
        echo "Resetting service unit: $SERVICE.service"
        sudo systemctl reset-failed "$SERVICE.service" 2>/dev/null || true
    fi

    if ip netns list | grep -q "$NAME"; then
        echo "Removing network namespace: $NAME"
        sudo ip netns delete "$NAME" 2>/dev/null || true
    fi
}

stop_container
cleanup


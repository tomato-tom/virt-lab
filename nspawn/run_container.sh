#!/bin/bash
#
#コンテナ起動スクリプト
# root権限必要
# sudo ./run_container.sh <name>

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

if ! machinectl list-images | grep $NAME; then
    echo "Create container $NAME..."
    ./create_container.sh $NAME
fi

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

# トラップの設定 (スクリプトが中断された場合もクリーンアップ)
trap cleanup INT TERM

create_netns() {
    echo "Creating network namespace: $NAME"
    ip netns add $NAME
}
# stop_containerで削除する

run_container() {
    # コンテナをバックグラウンド起動
    systemd-run --unit=${SERVICE} \
        --property=Type=notify \
        --property=NotifyAccess=all \
        --property=DeviceAllow='char-/dev/net/tun rw' \
        --property=DeviceAllow='char-/dev/vhost-net rw' \
        systemd-nspawn \
            --boot \
            --machine=${NAME} \
            --network-namespace-path=/run/netns/${NAME} \
            --directory=/var/lib/machines/${NAME}
}

cleanup
./stop_container.sh $NAME
create_netns
run_container

echo "Successfully started container $NAME"
echo "Service name: $NAME.service"


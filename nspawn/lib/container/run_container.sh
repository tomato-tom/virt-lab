#!/bin/bash
#
#コンテナ起動スクリプト
# sudo ./run_container.sh <name>

NAME=$1
SERVICE="container-${NAME}"
LOGGER="lib/logger.sh"

cd $(dirname ${BASH_SOURCE:-$0})

# 共通設定読み込み
[ -f lib/common.sh ] && source lib/common.sh || {
    echo "Failed to source common.sh" >&2
    exit 1
}
load_logger $0
check_root || exit 1

# setup
/bin/bash lib/setup_nspawn.sh || exit 1

if [ -z "$NAME" ]; then
    echo "Usage: $0 <name>"
    exit 1
fi

# コンテナなければ作成
if ! machinectl image-status $NAME >/dev/null 2>&1; then
    log info "Create container $NAME..."
    ./create_container.sh $NAME
fi

# クリーンアップ関数
cleanup() {
    log info "Cleaning up..."
    # 既存のコンテナを停止
    if machinectl status "$NAME" >/dev/null 2>&1; then
        log info "Cleaning existing container $NAME"
        ./stop_container.sh "$NAME"
    fi
    # コンテナ停止中

    if ip netns list | grep -q "$NAME"; then
        log info "Removing existing network namespace: $NAME"
        ip netns delete "$NAME" 2>/dev/null || true
    fi
}

# トラップの設定 
trap cleanup INT TERM

create_netns() {
    log info "Creating network namespace: $NAME"
    ip netns add $NAME
}
# stop_containerで削除する

run_container() {
    log info "Start the container in background"
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

# main
cleanup
./stop_container.sh $NAME
create_netns
run_container

log info "Successfully started container $NAME"
log info "Service name: $SERVICE.service"
echo "Check status: systemctl status $SERVICE.service"
echo "View logs:"
echo "  journalctl -u $SERVICE.service -f"
echo "  cat logs/script.log"

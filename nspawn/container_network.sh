#!/bin/bash
# container_network.sh

NETNS_DIR="/var/run/netns"
BRIDGE_DIR="/sys/class/net"

usage() {
    echo "Usage: $0 {create|attach|detach|list} [bridge] [container]"
    echo "  create <bridge>          - ブリッジとネットワーク名前空間を作成"
    echo "  attach <bridge> <container> - コンテナをブリッジに接続"
    echo "  detach <bridge> <container> - コンテナをブリッジから切断"
    echo "  list [bridge]            - ブリッジと接続状況を表示"
    exit 1
}

create_bridge() {
    local bridge="$1"
    
    # ブリッジ作成
    if ! ip link show "$bridge" >/dev/null 2>&1; then
        ip link add name "$bridge" type bridge
        ip link set "$bridge" up
        echo "ブリッジ $bridge を作成しました"
    else
        echo "ブリッジ $bridge は既に存在します"
    fi
    
    # ネットワーク名前空間ディレクトリ作成
    mkdir -p "$NETNS_DIR"
    echo "ネットワーク名前空間の準備が完了しました"
}

attach_container() {
    local bridge="$1"
    local container="$2"
    local netns_name="${container}_ns"
    
    # ブリッジの存在確認
    if ! ip link show "$bridge" >/dev/null 2>&1; then
        echo "エラー: ブリッジ $bridge が存在しません"
        exit 1
    fi
    
    # コンテナのPID取得
    local pid=$(machinectl show -p Leader "$container" 2>/dev/null | cut -d= -f2)
    if [ -z "$pid" ]; then
        echo "エラー: コンテナ $container が見つかりませんまたは実行中ではありません"
        exit 1
    fi
    
    # ネットワーク名前空間を作成（既存の場合は再利用）
    mkdir -p "$NETNS_DIR"
    ln -sf "/proc/$pid/ns/net" "$NETNS_DIR/$netns_name"
    
    # vethペアの作成
    local host_veth="veth-${container}"
    local container_veth="eth0"
    
    ip link add "$host_veth" type veth peer name "$container_veth"
    
    # ホスト側をブリッジに接続
    ip link set "$host_veth" up
    ip link set "$host_veth" master "$bridge"
    
    # コンテナ側をコンテナのネットワーク名前空間に移動
    ip link set "$container_veth" netns "$netns_name"
    
    # コンテナ内でネットワーク設定
    ip netns exec "$netns_name" ip link set lo up
    ip netns exec "$netns_name" ip link set "$container_veth" up
    ip netns exec "$netns_name" ip addr add 192.168.100.$(echo $pid | tail -c 3)/24 dev "$container_veth"
    ip netns exec "$netns_name" ip route add default via 192.168.100.1
    
    echo "コンテナ $container をブリッジ $bridge に接続しました"
    echo "IPアドレス: 192.168.100.$(echo $pid | tail -c 3)"
}

detach_container() {
    local bridge="$1"
    local container="$2"
    local netns_name="${container}_ns"
    local host_veth="veth-${container}"
    
    # vethインターフェースの削除
    if ip link show "$host_veth" >/dev/null 2>&1; then
        ip link delete "$host_veth"
        echo "vethインターフェース $host_veth を削除しました"
    fi
    
    # ネットワーク名前空間のリンク削除
    if [ -L "$NETNS_DIR/$netns_name" ]; then
        rm -f "$NETNS_DIR/$netns_name"
        echo "ネットワーク名前空間 $netns_name のリンクを削除しました"
    fi
    
    echo "コンテナ $container をブリッジ $bridge から切断しました"
}

list_connections() {
    local bridge="$1"
    
    if [ -n "$bridge" ]; then
        echo "=== ブリッジ $bridge の接続状況 ==="
        bridge link show dev "$bridge" 2>/dev/null || echo "ブリッジ $bridge は存在しません"
    else
        echo "=== 利用可能なブリッジ ==="
        find "$BRIDGE_DIR" -type l -name "br*" -o -name "veth*" | while read link; do
            dev=$(basename "$link")
            if [ -d "$BRIDGE_DIR/$dev/brif" ]; then
                echo "ブリッジ: $dev"
                ls "$BRIDGE_DIR/$dev/brif/" 2>/dev/null | while read iface; do
                    echo "  ├─ $iface"
                done
            fi
        done
    fi
}

# メイン処理
case "$1" in
    create)
        [ $# -lt 2 ] && usage
        create_bridge "$2"
        ;;
    attach)
        [ $# -lt 3 ] && usage
        attach_container "$2" "$3"
        ;;
    detach)
        [ $# -lt 3 ] && usage
        detach_container "$2" "$3"
        ;;
    list)
        list_connections "$2"
        ;;
    *)
        usage
        ;;
esac

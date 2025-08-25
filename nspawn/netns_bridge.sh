#!/bin/bash

# 関数の関連性
# create_bridge
# delete_bridge
# attach_ns
#     check_state
#     create_ns
#     create_veth
#     networking_ns
#     routing_ns
# detach_ns
# delete_ns
# clean
# list_connections
#
# 命名規則
# bridge
# ns-br0, ns-br1, ns-br2...
# bridge IP addresss
# 10.0.<brnum>.1/24
# 例; ns-br1 10.0.1.1/24
#
# netns
# ns1, ns2, ns3...
# netns IP address
# 10.0.1.<nsnum + 10>/24
# 例: ns-br1, ns2 10.0.1.12/24
#

set -e

usage() {
    echo "Usage: $0 {create|attach|detach|list} [bridge] [ns]"
    echo "  create <bridge>          - ブリッジ作成"
    echo "  attach <bridge> <ns>     - netnsをブリッジに接続"
    echo "  detach <bridge> <ns>     - netnsをブリッジから切断"
    echo "  delete <bridge>          - ブリッジとネットワーク名前空間を削除"
    echo "  rmns <ns>                - ネットワーク名前空間を削除"
    echo "  addns <ns>               - ネットワーク名前空間を追加"
    echo "  clean                    - 全て削除"  # 修正: 閉じ引用符追加
    echo "  list [bridge]            - ブリッジと接続状況を表示"
    exit 1
}

create_bridge() {
    local bridge="$1"
    
    # ブリッジ作成
    if ! ip link show "$bridge" >/dev/null 2>&1; then
        ip link add name "$bridge" type bridge
        echo "ブリッジ $bridge を作成しました"
    else
        echo "ブリッジ $bridge は既に存在します"
    fi

    local num="${bridge#ns-br}"
    local address="10.1.${num}.1"

    ip addr flush $bridge
    ip addr add "${address}/24" dev $bridge
}

delete_bridge() {
    local bridge="$1"
    
    # ブリッジ削除
    if ip link show "$bridge" >/dev/null 2>&1; then
        ip link delete name "$bridge" type bridge
        echo "ブリッジ $bridge を削除しました"
    else
        echo "ブリッジ $bridge は存在しません"
    fi
}

create_ns() {
    local name="$1"

    if ip netns add "$name" 2>/dev/null; then  # 修正: リダイレクト修正
        echo "netns $name を作成しました"
    else 
        echo "netns $name はすでに存在します"  # 修正: メッセージ修正
    fi
}

remove_ns() {
    local name="$1"

    if ip netns del "$name" 2>/dev/null; then  # 修正: リダイレクト修正
        echo "netns $name を削除しました"
    else 
        echo "netns $name はすでに存在しません"
    fi
}

networking_ns() {
    local name="$1"
    local bridge="$2"
    local ifname="en0"
    local address

    # netns名の数字をIPアドレスの末尾に
    # bridge名の数字をIPアドレスの一部に
    local num="${name#ns}"
    local brnum="${bridge#ns-br}"
    num=$((num + 10))
    address="10.1.${brnum}.${num}/24"

    # 既存の設定をクリーンアップ
    ip netns exec $name ip link set $ifname down 2>/dev/null || true
    ip netns exec $name ip addr flush $ifname 2>/dev/null || true

    # 設定
    ip netns exec $name ip addr add $address dev $ifname
    ip netns exec $name ip link set $ifname up
    ip netns exec $name ip link set lo up
    echo "netns $name にIPアドレス $address を設定"
}

routing_ns() {
    local name="$1"
    local gateway="$2"

    # 既存の設定をクリーンアップ
    ip netns exec $name ip route flush default 2>/dev/null || true

    ip netns exec $name ip route add default via $gateway
    echo "netns $name のデフォルトルートを$gatewayに設定"
}

create_veth() {
    # vethペアの作成
    local ns="$1"

    # vethペアの作成
    local host_veth="ve-${ns}"
    local ns_veth="en0"

    # 既存のvethペア削除
    if ip link show $host_veth 2>/dev/null; then
        ip link del $host_veth
    fi

    ip link add "$host_veth" type veth peer name $ns_veth netns $ns
    echo "vethペア作成: [$host_veth]---[$ns_veth@$ns]"  # 修正: 変数名修正
}

check_state() {
    local name="$1"
    local state="$(ip -j link show $name 2>/dev/null | jq -r '.[] | .operstate')"

    echo $state
}

attach_ns() {
    local bridge="$1"
    local ns="$2"
    local host_veth="ve-${ns}"  # 修正: 変数定義追加
    local ns_veth="en0"
    
    # ブリッジの存在確認
    if ! ip link show "$bridge" >/dev/null 2>&1; then
        create_bridge $bridge
        echo "info: ブリッジ $bridge 作成中..."
    fi

    # とりあえずブリッジをdownに
    if [ "$(check_state $bridge)" == "UP" ]; then
        ip link set $bridge down
    fi

    # netnsの存在確認
    if ! ip netns pids $ns >/dev/null 2>&1; then  # 修正: pids使用、リダイレクト追加
        create_ns $ns
        echo "info: $ns 作成中..."
    fi 
    
    create_veth $ns
    networking_ns $ns $bridge
    
    # ホスト側をブリッジに接続
    ip link set "$host_veth" master "$bridge"
    ip link set "$host_veth" up   # ポートUP

    # bridgeもUP --- これはポートUPの後でやるほうがいいみたい
    ip link set "$bridge" up

    echo "ブリッジ接続: $bridge[$host_veth]---[$ns_veth@$ns]"

    local num="${bridge#ns-br}"
    local address="10.1.${num}.1"
    routing_ns $ns "$address"
}

detach_ns() {
    local bridge="$1"
    local ns="$2"
    local host_veth="ve-${ns}"
    
    # vethインターフェースの削除
    if ip link show "$host_veth" >/dev/null 2>&1; then
        ip link delete "$host_veth"
        echo "vethインターフェース $host_veth を削除しました"
    fi
    
    echo "netns $ns をブリッジ $bridge から切断しました"
}

clean_all() {
    local names="$(ip -j link show type bridge 2>/dev/null | jq -r '.[] | .ifname' | grep '^ns-br' || true)"
    for name in $names; do 
        ip link del $name 
    done
    
    ip --all netns del
}

list_connections() {
    local bridge="$1"
    
    if [ -n "$bridge" ]; then
        if ip link show "$bridge" 2>/dev/null; then
            echo "=== ブリッジ $bridge の接続状況 ==="
            ip link show "$bridge"
            ip link show type veth | grep "master $bridge" || echo "接続されたvethペアはありません"
        else
            echo "ブリッジ $bridge は存在しません"
            echo "=== 全ブリッジ ==="  # 修正: メッセージ修正
            ip link show type bridge
        fi
    else
        echo "=== 全ブリッジ ==="  # 修正: メッセージ修正
        ip link show type bridge
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
        attach_ns "$2" "$3"
        ;;
    detach)
        [ $# -lt 3 ] && usage
        detach_ns "$2" "$3"
        ;;
    delete)
        [ $# -lt 2 ] && usage
        delete_bridge "$2"
        ;;
    rmns)
        [ $# -lt 2 ] && usage
        remove_ns "$2"
        ;;
    list)
        list_connections "$2"
        ;;
    clean)
        clean_all
        ;;
    *)
        usage
        ;;
esac


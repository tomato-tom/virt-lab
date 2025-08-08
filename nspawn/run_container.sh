#!/bin/bash
#
#コンテナ起動スクリプト
# root権限必要
# ./run_container.sh c1
#
# bridge, veth作成ライブラリに依存

if [ "$(id -u)" != "0" ]; then
   echo "このスクリプトはroot権限で実行する必要があります" 1>&2
   exit 1
fi

run_container() {
    local name="$1"
    find /var/lib/machines -name "$name" || return
    # tmuxセッションでコンテナを起動
    tmux new-session -d -s "$name" \
        "systemd-nspawn -M $name --network-namespace-path=/run/netns/$name --boot"
}

# クリーンアップ関数
cleanup() {
    for name in ct1 ct2; do
        tmux kill-session -t "$name" 2>/dev/null || true
        machinectl terminate "$name" 2>/dev/null || true
        ip netns del "$name" 2>/dev/null || true
    done
}

# トラップ設定（スクリプト終了時クリーンアップ）
trap cleanup EXIT

# メイン処理
# bridge作成
if create_bridge; then
    bridge="$BRIDGE"
else
    exit 1
fi

# ct1
create_veth  "ct1" "en0" "10.1.1.101/24" $bridge
run_container "ct1"

# ct2
create_veth  "ct2" "en0" "10.1.1.102/24" $bridge
run_container "ct2"
 
# 確認
machinectl list
machinectl shell ct1 /bin/bash -c "ping -q -c 1 -w 1 10.1.1.102 && echo ok"

# ユーザー入力待ち（スクリプト終了を防ぐ）
read -p "Press Enter to terminate containers..."

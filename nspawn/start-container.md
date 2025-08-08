# コンテナ起動とネットワーク

`systemd-nspawn` コンテナ用のネットワーク自動設定関数をより体系的に設計しましょう。以下の提案は、シンプルながら拡張可能な構造を目指しています。

## ネットワーク命名規則と自動化のアイデア

### 基本版

1. **命名規則の統一化**
   - ブリッジ: `br<番号>` (デフォルト)
   - ホスト側veth: `ve-<コンテナ名>-<コンテナ側ポート番号>` --- bonding対応可
   - コンテナ側veth: `eth0, eth1, eth2...`

2. **IPアドレス自動割当**
   - サブネット: `10.<ブリッジ番号>.<vlan番号>.0/24`
   - ホスト側: `10.<ブリッジ番号>.<vlan番号>.1`
   - コンテナ側: `10.<ブリッジ番号>.<vlan番号>.<コンテナ番号+ポート番号>`

10.0.1.0/24    ネットワーク,デフォルトvlan 1
10.0.1.1/24    ホストのブリッジポート br0
10.0.1.10/24   コンテナ, c1 eth0
10.0.1.249/24   コンテナ, c24 eth9  --- コンテナ２４個、ゲストポート９個まで対応可
10.0.0.0/16    親ネットワーク、L3ブリッジのトランクポートなど
> とりあえずコンテナ２４個、ポート９個で十分だろう。
> 実際ルーターコンテナでもブリッジ接続すると２〜３ポートで十分
> サブネットの計算処理入れるとめんどうだから、/16, /24を使う

3. **改良版スクリプト例**

```bash
#!/bin/bash

# ブリッジ作成・管理
create_bridge() {
    local bridge="${1:-auto}"
    
    # 自動命名モード
    if [[ "$bridge" == "auto" ]]; then
        for i in {0..255}; do
            bridge="br$i"
            if ! ip link show "$bridge" >/dev/null 2>&1; then
                break
            fi
        done
    fi

    if ip link show "$bridge" >/dev/null 2>&1; then
        echo "[INFO] Bridge $bridge already exists"
        return 0
    fi

    ip link add "$bridge" type bridge
    ip link set "$bridge" up
    echo "[INFO] Created bridge: $bridge"
}

# vethペア作成と接続
connect_container() {
    local container_name="$1"
    local bridge="${2:-br0}"
    local ip_prefix="${3:-10.0.0}"
    local container_ip="${ip_prefix}.$((10 + ${container_name##*-}))/24"

    # ブリッジ存在確認 (なければ作成)
    create_bridge "$bridge"

    # ネットワーク名前空間作成
    if ! ip netns show "$container_name" >/dev/null 2>&1; then
        ip netns add "$container_name"
    fi

    # vethペア作成
    local host_veth="ve-$container_name"
    local guest_veth="eth0"

    if ip link show "$host_veth" >/dev/null 2>&1; then
        echo "[WARN] veth pair already exists: $host_veth"
    else
        ip link add "$host_veth" type veth peer name "$guest_veth" netns "$container_name"
        ip link set "$host_veth" master "$bridge"
        ip link set "$host_veth" up
        
        # コンテナ側設定
        ip -n "$container_name" addr add "$container_ip" dev "$guest_veth"
        ip -n "$container_name" link set "$guest_veth" up
        ip -n "$container_name" link set lo up
        
        echo "[INFO] Connected $container_name to $bridge with IP $container_ip"
    fi
}

# コンテナ起動用ラッパー
start_container() {
    local name="$1"
    local bridge="${2:-br0}"
    
    # ネットワーク設定
    connect_container "$name" "$bridge"
    
    # systemd-nspawnで起動
    systemd-nspawn -M "$name" \
        --network-namespace-path="/run/netns/$name" \
        --boot
}

# 使用例:
# create_bridge br0  # 明示的にブリッジ作成
# start_container testvm1  # 自動設定(br0, 10.0.0.11/24)
# start_container testvm2 br1  # 別ブリッジ使用(br1, 10.0.1.12/24)
```

### 拡張機能のアイデア

1. **コンテナ間接続機能**
   ```bash
   connect_containers() {
       local vm1="$1"
       local vm2="$2"
       local bridge="br-peer-${vm1}-${vm2}"
       
       create_bridge "$bridge"
       connect_container "$vm1" "$bridge" "10.100.100"
       connect_container "$vm2" "$bridge" "10.100.100"
   }
   ```

2. **DNS設定自動追加**
   ```bash
   setup_dns() {
       local container="$1"
       mkdir -p "/etc/netns/$container"
       echo "nameserver 8.8.8.8" > "/etc/netns/$container/resolv.conf"
   }
   ```

3. **ファイアウォールルール自動設定**
   ```bash
   setup_firewall() {
       local bridge="$1"
       iptables -A FORWARD -i "$bridge" -j ACCEPT
       iptables -t nat -A POSTROUTING -s "${ip_prefix}.0/24" -j MASQUERADE
   }
   ```

4. **ネットワークテンプレート**
   ```bash
   create_network_profile() {
       local profile="$1"
       case "$profile" in
           "isolated")
               create_bridge "br-$profile"
               ;;
           "shared")
               connect_container "$container" "br0"
               ;;
           "custom")
               # カスタム設定
               ;;
       esac
   }
   ```

この設計の利点:
- 命名規則を統一することで管理が容易
- 自動IP割当で設定ミスを防止
- 関数を組み合わせて複雑なネットワークも構築可能
- systemd-networkdやnetplanとの連携も可能な構造

必要に応じて、さらに高度なネットワーク設定（VLAN、VPN、複数NICなど）に対応する関数を追加できます。


## 拡張版

VLAN対応と複数ポートを考慮したより実践的な命名規則とIPアドレス割当 scheme を提案します。以下の設計は、コンテナ24個・各コンテナ最大9ポートまでを想定した体系的なものです。

### ネットワークアーキテクチャ設計

```bash
# IPアドレス体系 (10.<bridge>.<vlan>.<host/container>)
10.0.0.0/16      # 全体の親ネットワーク (ルーティング用)
├─ 10.0.1.0/24   # VLAN1 (デフォルト)
│   ├─ 10.0.1.1      # ホスト側ブリッジインターフェイス (br0)
│   ├─ 10.0.1.10     # コンテナ1 eth0 (c1)
│   └─ 10.0.1.249    # コンテナ24 eth9 (c24)
└─ 10.0.100.0/24 # VLAN100 (例)
```

### 改良版スクリプト実装

```bash
#!/bin/bash

# 共通設定
MAX_CONTAINERS=24
MAX_PORTS=9
BASE_IP="10"

# ブリッジ作成 (VLAN対応)
create_bridge() {
    local bridge="${1:-br0}"
    local vlan="${2:-1}"

    # VLANタグ付きブリッジの作成
    if [[ "$vlan" != "1" ]]; then
        bridge="$bridge.$vlan"
        ip link add link "${bridge%%.*}" name "$bridge" type vlan id "$vlan"
    fi

    if ! ip link show "$bridge" >/dev/null 2>&1; then
        ip link add name "$bridge" type bridge
        ip link set "$bridge" up
        echo "[INFO] Created bridge: $bridge (VLAN $vlan)"
    fi

    # ホスト側IP設定
    local host_ip="${BASE_IP}.${bridge#br}.${vlan}.1"
    if ! ip addr show "$bridge" | grep -q "$host_ip"; then
        ip addr add "$host_ip/24" dev "$bridge"
    fi
}

# コンテナ接続 (複数ポート対応)
connect_container() {
    local container="$1"       # コンテナ名 (c1-c24)
    local port="${2:-0}"       # ポート番号 (0-9)
    local bridge="${3:-br0}"   # ブリッジ名
    local vlan="${4:-1}"       # VLAN ID

    # コンテナ番号抽出 (c1 → 1)
    local container_num=${container#c}
    if (( container_num < 1 || container_num > MAX_CONTAINERS )); then
        echo "[ERROR] Invalid container number (1-$MAX_CONTAINERS)"
        return 1
    fi

    # ポート番号検証
    if (( port < 0 || port > MAX_PORTS )); then
        echo "[ERROR] Invalid port number (0-$MAX_PORTS)"
        return 1
    fi

    # ネットワークインターフェイス名生成
    local host_veth="ve-${container}-p${port}"
    local guest_veth="eth${port}"
    local bridge_if="$bridge"
    
    # VLAN対応ブリッジ名調整
    if [[ "$vlan" != "1" ]]; then
        bridge_if="$bridge.$vlan"
    fi

    # IPアドレス計算
    local container_ip="${BASE_IP}.${bridge#br}.${vlan}.$((10 + container_num * MAX_PORTS + port))"

    # vethペア作成
    if ! ip link show "$host_veth" >/dev/null 2>&1; then
        ip link add "$host_veth" type veth peer name "$guest_veth" netns "$container"
        ip link set "$host_veth" master "$bridge_if"
        ip link set "$host_veth" up
        
        # コンテナ側設定
        ip -n "$container" addr add "${container_ip}/24" dev "$guest_veth"
        ip -n "$container" link set "$guest_veth" up
        ip -n "$container" link set lo up
        
        echo "[INFO] Connected $container:$guest_veth to $bridge_if (IP: $container_ip)"
    else
        echo "[WARN] Interface $host_veth already exists"
    fi
}

# コンテナ起動ラッパー
start_container() {
    local name="$1"
    local bridge="${2:-br0}"
    local vlan="${3:-1}"

    # ネットワーク名前空間作成
    if ! ip netns show "$name" >/dev/null 2>&1; then
        ip netns add "$name"
    fi

    # ブリッジ作成
    create_bridge "$bridge" "$vlan"

    # デフォルト接続 (eth0)
    connect_container "$name" 0 "$bridge" "$vlan"

    # systemd-nspawnで起動
    systemd-nspawn -M "$name" \
        --network-namespace-path="/run/netns/$name" \
        --boot
}

# 使用例:
# start_container c1 br0 1     # デフォルトVLAN
# start_container c2 br0 100   # VLAN100
# connect_container c1 1 br0 1 # 追加ポート接続
```

### 拡張機能の実装例

1. **ルーターコンテナ向けマルチポート設定**
```bash
setup_router() {
    local router="r1"
    
    # 各ネットワークセグメントに接続
    connect_container "$router" 0 br0 1    # LAN1
    connect_container "$router" 1 br0 100  # LAN100 (VLAN100)
    connect_container "$router" 2 br1 1    # WAN側
    
    # ルーティング有効化
    ip netns exec "$router" sysctl -w net.ipv4.ip_forward=1
}
```

2. **ネットワーク設定の自動保存/復元**
```bash
save_network_config() {
    local config_dir="/etc/container-networks"
    mkdir -p "$config_dir"
    ip -j link | jq > "$config_dir/interfaces.json"
    ip -j addr | jq > "$config_dir/addresses.json"
    ip -j route | jq > "$config_dir/routes.json"
}

restore_network_config() {
    local config_dir="/etc/container-networks"
    # JSONから設定を復元する処理
}
```

3. **DHCPサーバー自動設定**
```bash
setup_dhcp() {
    local bridge="$1"
    local vlan="$2"
    local range_start="${BASE_IP}.${bridge#br}.${vlan}.100"
    local range_end="${BASE_IP}.${bridge#br}.${vlan}.200"
    
    dnsmasq --interface="$bridge" \
        --dhcp-range="$range_start,$range_end,12h" \
        --dhcp-option=option:router,"${BASE_IP}.${bridge#br}.${vlan}.1"
}
```

この設計の特徴:
1. **体系的なIPアドレス管理**
   - ブリッジ番号、VLAN ID、コンテナ番号、ポート番号から自動計算
   - `10.<bridge>.<vlan>.<host/container>` の階層構造

2. **柔軟なネットワーク構成**
   - 最大24コンテナ×9ポートまで対応
   - VLANタグ付け対応
   - マルチホーミング可能

3. **実用的な拡張性**
   - ルーターコンテナ設定用のヘルパー関数
   - 設定の永続化機能
   - DHCPサーバー連携

4. **エラーチェック強化**
   - コンテナ番号/ポート番号の範囲検証
   - 重複接続の防止

この方式を使えば、複雑なネットワーク環境でも一貫性のある設定が可能になります。必要に応じて、さらに高度な機能（ファイアウォールルール自動生成、ネットワークモニタリングなど）を追加できます。


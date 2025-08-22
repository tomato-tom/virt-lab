#!/bin/bash
# systemd-networkdの設定ファイルを解析したり

section_name="${1:-Match}"

echo $@ | grep debug >/dev/null && debug=1 || debug=0

CONFIG_CONTENT=$(sudo cat /run/systemd/network/10-netplan-eth0.network 2>/dev/null)
# ubuntu serverデフォルトの設定ファイル

parse_section() {
    local section="$1"
    awk -v section="$section" -v debug="$debug" '
        BEGIN { in_section=0; line_num=0 }
        { line_num++ }
        
        /^\[.*\]$/ {
            if (debug) printf "行%2d: セクション行 [%s] ", line_num, $0
            if ($0 == "[" section "]") {
                in_section=1
                if (debug) printf "→ ターゲットセクション! in_section=1\n"
                next
            } else {
                in_section=0
                if (debug) printf "→ 別のセクション in_section=0\n"
                next
            }
        }
        
        in_section {
            if (/^[[:space:]]*#/ || /^[[:space:]]*$/) {
                if (debug) printf "行%2d: コメント/空行 → スキップ\n", line_num
                next
            }
            if (/=/) {
                if (debug) printf "行%2d: 設定項目 → 出力: %s\n", line_num, $0
                print $0
            } else {
                if (debug) printf "行%2d: 不明な形式 → スキップ: %s\n", line_num, $0
            }
        }
        
        !in_section && debug && !/^\[/ && !/^[[:space:]]*#/ && !/^[[:space:]]*$/ {
            printf "行%2d: セクション外 → スキップ: %s\n", line_num, $0
        }
    ' <<< "$CONFIG_CONTENT"
}

for sect in $@; do
    if [ $sect == debug ]; then
        :
    elif echo "$CONFIG_CONTENT" | grep "$sect"; then
        echo "=== セクション: $sect の解析 ==="
        parse_section "$sect"
    else
        echo "不明なセクション: $sect"
    fi
done


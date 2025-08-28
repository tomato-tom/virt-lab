#!/bin/bash
# Bridge management functions

cd $(dirname ${BASH_SOURCE:-$0})
cd ../

source lib/query.sh
source lib/logger.sh

create_bridge() {
    local bridge="$1"
    local ip_addr="$2"
    
    if bridge_exists "$bridge"; then
        log info "Bridge $bridge already exists"
    fi

    ip link add "$bridge" type bridge || {
        log error "Failed to create bridge: $bridge"
        return 1
    }

    ip addr flush $bridge
    ip addr add "$ip_addr" dev "$bridge"
    log info "Bridge $bridge created (IP: $ip_addr)"
}

delete_bridge() {
    local bridge="$1"
    
    # ブリッジ削除
    if bridge_exists; then
        ip link delete "$bridge" type bridge
        log info "Bridge $bridge deleted"
    else
        log worn "Bridge $bridge does not exists"
    fi
}

bridge_exists() {
    local bridge="$1"
    ip link show $1 >/dev/nul || return 1
}

bridge_up() {
    local bridge="$1"
    ip link set "$bridge" up
    log debug "Bridge $bridge set to UP"
}

bridge_down() {
    local bridge="$1"
    ip link set "$bridge" down
    log debug "Bridge $bridge set to DOWN"
}

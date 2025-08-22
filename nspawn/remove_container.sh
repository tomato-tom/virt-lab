#!/bin/bash
#
#コンテナを削除

# sudo ./remove_container.sh <name>

NAME=$1
SERVICE="container-${NAME}"
LOGGER="../lib/logger.sh"

# ログスクリプトの存在確認
if [ -f "$LOGGER" ]; then
    source "$LOGGER" $0
else
    echo This script neads logger.sh
    exit 1
fi

# root権限必要
if [ "$(id -u)" != "0" ]; then
   log error "Must be run with root"
   exit 1
fi

if [ -z "$NAME" ]; then
    echo "Usage: $0 <name>"
    exit 1
fi

log info "Stopping container $NAME"
./stop_container.sh "$NAME"

if machinectl remove "$NAME"; then
    log info "successfully removed: $NAME"
else
    log error "remove failed: $NAME"
fi

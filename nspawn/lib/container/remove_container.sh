#!/bin/bash
#
#コンテナを削除

# sudo ./remove_container.sh <name>

NAME=$1
SERVICE="container-${NAME}"
LOGGER="../lib/logger.sh"

cd $(dirname ${BASH_SOURCE:-$0})

[ -f lib/common.sh ] && source lib/common.sh || {
    echo "Failed to source common.sh" >&2
    exit 1
}
load_logger $0
check_root || exit 1


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

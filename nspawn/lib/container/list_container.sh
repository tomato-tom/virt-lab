#!/bin/bash
#コンテナのリスト、情報表示
# list_container.sh [ all ]

cd $(dirname ${BASH_SOURCE:-$0})

[ -f lib/common.sh ] && source lib/common.sh || {
    echo "Failed to source common.sh" >&2
    exit 1
}


if [ "$1" == "all" ]; then
    machinectl list-images
else
    machinectl list
fi


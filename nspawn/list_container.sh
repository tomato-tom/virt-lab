#!/bin/bash
#コンテナのリスト、情報表示
# list_container.sh [ all ]

if [ "$1" == "all" ]; then
    machinectl list-images
else
    machinectl list
fi


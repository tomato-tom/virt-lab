#!/bin/bash
# VMにわかりやすいタイトルつける

usage() {
	echo "Usage: $0 <name> <title>"
	exit 1
}

NAME="$1"
if [[ "$#" < 2 ]]; then
	usage
elif ! virsh list --all --name | grep -qw "$NAME"; then
	"NAME '$NAME' does not exist."
	usage
fi

shift
TITLE="$@"
if [ "$(virsh domstate "$NAME" 2>/dev/null)" == "running" ]; then
	virsh desc "$NAME" --live --config --title "$TITLE"
else
	virsh desc "$NAME" --title "$TITLE"
fi


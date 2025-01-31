#!/bin/bash

set -e

# Install latest release
sudo curl -fsSL https://pkgs.zabbly.com/key.asc -o /etc/apt/keyrings/zabbly.asc
sudo sh -c 'cat <<EOF > /etc/apt/sources.list.d/zabbly-incus-stable.sources
Enabled: yes
Types: deb
URIs: https://pkgs.zabbly.com/incus/stable
Suites: $(. /etc/os-release && echo ${VERSION_CODENAME})
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/zabbly.asc
EOF'

sudo apt-get update
sudo apt-get install -y incus
incus version

# Minimal setup with default options
sudo incus admin init --minimal

# Add current user to incus group
sudo gpasswd -a $USER incus

echo "Please reboot to apply incus group to current user"
echo "Or you can apply it temporarily with the command: newgrp incus"


#!/bin/bash -e

# Minimum installation to build a KVM virtual environment.
sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients
sudo apt-get install -y bridge-utils virtinst libosinfo-bin

# Option
#sudo apt install zfsutils-linux
sudo apt install -y cockpit cockpit-machines

# Add current user to libvirt group
sudo usermod -a -G libvirt $(whoami)
sudo usermod -a -G kvm $(whoami)
sudo systemctl restart libvirtd

echo "Please reboot to apply libvirt group to current user"
echo "Or you can apply it temporarily with the command: newgrp libvirt"


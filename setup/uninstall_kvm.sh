#!/bin/bash

# Remove the current user from the 'libvirt' group
sudo gpasswd -d $USER libvirt

# Purge (completely remove) libvirt-related packages
sudo apt-get purge -y qemu-kvm libvirt-daemon-system libvirt-clients
sudo apt-get purge -y bridge-utils virtinst libosinfo-bin

# Remove unnecessary packages and clean up residual package files
sudo apt-get autoremove -y
sudo apt-get clean

# Remove user-specific libvirt configuration and data
sudo rm -rf $HOME/.config/libvirt
sudo rm -rf $HOME/.local/share/libvirt
sudo rm -rf $HOME/.cache/libvirt

# Remove libvirt-related AppArmor profiles
sudo rm -rf /etc/apparmor.d/libvirt

# Remove global libvirt configuration directory
sudo rm -rf /etc/libvirt

# Remove leftover package information files
sudo rm -f /var/lib/dpkg/info/libvirt*


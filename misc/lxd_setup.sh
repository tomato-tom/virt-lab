#!/bin/bash

# Install LXD
if ! sudo snap install lxd; then
    echo "LXD is already installed. Refreshing..."
    sudo snap refresh lxd
else
    echo "LXD has been installed successfully."
fi

# Add current user to the LXD group
sudo usermod -aG lxd "$USER"

# Default setup of LXD
sudo lxd init --minimal

# Launch container to check operation
echo "Launch a container..."
sudo lxc launch ubuntu:24.04 mycontainer
sudo lxc list
sudo lxc exec mycontainer -- cat /etc/*release
sudo lxc exec mycontainer -- uname -a

echo "Delete the container"
sudo lxc stop mycontainer
sudo lxc delete mycontainer

echo "Please re-login to apply the user to the LXD group"


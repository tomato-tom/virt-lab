#!/bin/bash

set -e

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "This script needs to be run with root privileges."
    echo "Please run 'sudo $0'."
    exit 1
fi

echo "Starting the uninstallation of incus..."

# Stop the services
echo "Stopping services..."
systemctl stop incus.service || true
systemctl stop incus.socket || true
systemctl stop incus-user.service || true
systemctl stop incus-user.socket || true
systemctl stop incus-lxcfs.service || true

# Reload systemd daemon
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Remove the packages
echo "Removing packages..."
apt purge -y incus || true
apt autoremove -y || true
apt clean

# Remove Zabbly repository settings
echo "Removing repository settings..."
rm -f /etc/apt/keyrings/zabbly.asc
rm -f /etc/apt/sources.list.d/zabbly-incus-stable.sources

# Remove configuration files and directories
echo "Removing configuration files and directories..."
rm -rf /home/*/.config/incus
rm -rf /home/*/.cache/incus
rm -rf /etc/logrotate.d/incus
rm -rf /etc/default/incus
rm -rf /var/log/incus
rm -rf /var/lib/incus
rm -rf /var/cache/incus
rm -rf /root/.config/incus
rm -rf /root/.cache/incus
rm -rf /run/incus
rm -rf /run/lxc/lock/var/lib/incus

# Remove network bridges
echo "Removing network bridges..."
for bridge in $(ip link show | grep 'incusbr' | cut -d: -f2 | awk '{print $1}'); do
    ip link delete $bridge || true
done

# Remove the incus group
groupdel incus
groupdel incus-admin

echo "Uninstallation complete."


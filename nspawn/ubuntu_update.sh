#!/bin/bash

# Update package list
apt-get update

# Check if there are any upgradable packages
if ! apt list --upgradable 2>/dev/null | grep -q "upgradable"; then
    echo "Already up to date"
    exit 0
fi

# Run a simulation of the upgrade and check if all three initial values are 0
upgrade_summary=$(apt-get upgrade -s | grep -oP '^\d+ upgraded, \d+ newly installed, \d+ to remove')

# Extract numerical values
upgraded=$(echo "$upgrade_summary" | awk '{print $1}')
newly_installed=$(echo "$upgrade_summary" | awk '{print $3}')
to_remove=$(echo "$upgrade_summary" | awk '{print $6}')

# Display upgrade target details
echo "Upgrade targets:"
echo "Upgraded: $upgraded"
echo "Newly installed: $newly_installed"
echo "To remove: $to_remove"

# If all values are 0, there are no changes
if [[ "$upgraded" -eq 0 && "$newly_installed" -eq 0 && "$to_remove" -eq 0 ]]; then
    echo "No changes"
    exit 0
fi

# Perform the upgrade
apt-get upgrade -y


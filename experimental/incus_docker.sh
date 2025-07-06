#!/bin/bash -e

# To run this script without sudo, the user must belong to the 'incus' group

# Add DockerHub to the Incus remote server
if ! incus remote list | grep -q 'https://docker.io'; then
    incus remote add docker https://docker.io --protocol=oci
fi

incus remote list

# Launch a Docker container with nginx using Incus
if ! incus list | grep -q 'my-nginx'; then
    incus launch docker:nginx my-nginx
fi

# Launch an Ubuntu 24.04 container
if ! incus list | grep -q 'my-noble'; then
    incus launch images:ubuntu/noble my-noble
fi

incus list

# Wait until the IP address for the nginx container is assigned
addr=""
while [ -z "$addr" ]; do
    echo "Waiting for IP address to be assigned to my-nginx..."
    addr=$(incus info my-nginx | grep -E 'inet:.*global' | cut -d ':' -f2 | cut -d'/' -f1)
    sleep 1  # Wait for 1 second
done

# Test connection on port 80
incus exec my-noble -- nc -zv $addr 80

# Ask if the user wants to delete the containers upon exit
echo "Do you want to delete the containers upon exit? (y/n): "
read input

if [ "$input" == 'y' ] || [ -z "$input" ]; then
    incus stop my-noble
    incus delete my-noble
    incus stop my-nginx
    incus delete my-nginx
fi


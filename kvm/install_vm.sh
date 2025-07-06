#!/bin/bash

virt-install \
  --name my-vyos \
  --memory 4096 \
  --vcpus 2 \
  --location ~/Downloads/debian-12.9.0-amd64-netinst.iso \
  --os-variant debian12 \
  --disk size=20 \
  --console pty,target_type=serial \
  --graphics none \
  --autostart


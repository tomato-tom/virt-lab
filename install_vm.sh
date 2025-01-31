#!/bin/bash

virt-install \
  --name my-vyos \
  --memory 2048 \
  --vcpus 2 \
  --cdrom $HOME/Downloads/vyos-1.5-rolling-202411190447-generic-amd64.iso \
  --os-variant debian12 \
  --disk size=10 \
  --console pty,target_type=serial \
  --graphics none \
  --autostart


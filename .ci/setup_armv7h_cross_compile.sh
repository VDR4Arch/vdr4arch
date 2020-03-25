#!/bin/bash

# Get an ARM emulator going. This gets some support by repo-make-ci.sh later
# to get the emulator copied into the chroot environment
sudo apt-get update
sudo apt-get install qemu-user-static

# Enable a reduced repo-make.conf list. ARM build is slow so we don't build the
# full set.
rm repo-make.conf
cp repo-make-arm.conf repo-make.conf

# TODO: Set up DistCC here based on the official Arch Linux ARM "xtools".
# Without distcc the actual ARM compiler runs with qemu which is really slow!

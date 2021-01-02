#!/bin/bash

# Exit on first error
set -e

# Nothing to do for x86_64 as this is the host architecture
if [ "$REPO_MAKE_ARCH" = "x86_64" ]; then
  echo "No ARM build setup needed for x86_64, exiting..."
  exit 0
fi

# Enable 32 bit architecture for ARM builds
sudo dpkg --add-architecture armhf
sudo apt-get update || /bin/true


echo "> /etc/apt/sources.list start"
cat /etc/apt/sources.list
echo "> /etc/apt/sources.list end"


sudo apt-get install crossbuild-essential-armhf

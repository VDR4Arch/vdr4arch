#!/bin/bash

# Exit on first error
set -e

# Nothing to do for x86_64 as this is the host architecture
if [ "$REPO_MAKE_ARCH" = "x86_64" ]; then
  echo "No cross compile setup needed for x86_64, exiting..."
  exit 0
fi

# Install distcc
sudo apt-get update
sudo apt-get install distcc

# We need a more up-to-date qemu (or even better keep it as up-to-date as even
# possible). But later Ubuntu releases want to fade out i386 support so they
# won't give us the versions we want. To fix this, we hack a Debian source into
# the Travis CI VM and get our qemu-arm-static from there.
# WARNING: This is hacky. Do not ever do this on a proper Ubuntu setup!
sudo apt-key adv --recv-keys E1CF20DDFFE4B89E802658F1E0B11894F66AEC98
sudo apt-key adv --recv-keys 6ED6F5CB5FA6FB2F460AE88EEDA0D2388AE22BA9
echo "deb http://http.us.debian.org/debian bullseye main" | sudo tee "/etc/apt/sources.list.d/debian.list"
sudo apt-get update

# Get an ARM emulator going. This gets some support by repo-make-ci.sh later
# to get the emulator copied into the chroot environment.
# We need a 32 bit static qemu binary to properly emulate our ARM 32 bit target
# https://bugs.launchpad.net/qemu/+bug/1805913
sudo apt-get install -t "$DIST" qemu-user-static:i386

# For good measure: Get rid of the Debian source.
sudo rm "/etc/apt/sources.list.d/debian.list"
sudo apt-get update

# Enable a reduced repo-make.conf list. ARM build is slow so we don't build the
# full set.
rm repo-make.conf
cp repo-make-arm.conf repo-make.conf

# If we don't have them cached, get "x-tools" from archlinuxarm.org
# If they update their build-chain, we have to change the checksum here!
if [ "$REPO_MAKE_ARCH" = "armv6h" ]; then
  X_TOOLS="x-tools6h"
  X_TOOLS_MD5="a9c321d97b7fde8e44a0ca1bde19595e"
else
  X_TOOLS="x-tools7h"
  X_TOOLS_MD5="e7f77df95a93818469a9fa562723689f"
fi

mkdir -p "$HOME/cache"
if [ ! -s "$HOME/cache/$X_TOOLS.tar.xz" ]; then
  echo "Downloading x-tools..."
  wget -q -nc "https://archlinuxarm.org/builder/xtools/$X_TOOLS.tar.xz" -O "/var/tmp/$X_TOOLS.tar.xz"
  echo "$X_TOOLS_MD5  $X_TOOLS.tar.xz" > "/var/tmp/$X_TOOLS.tar.xz.md5"
  env -C "/var/tmp" md5sum -c "$X_TOOLS.tar.xz.md5"
  mv "/var/tmp/$X_TOOLS.tar.xz" "$HOME/cache"
else
  echo "x-tools $X_TOOLS found in cache"
fi

# Extract "x-tools"
tar -xf "$HOME/cache/$X_TOOLS.tar.xz" -C "$HOME"

# Fill whitelist for distcc
if [ "$REPO_MAKE_ARCH" = "armv6h" ]; then
  sudo ln -s /usr/bin/distcc /usr/lib/distcc/armv6l-unknown-linux-gnueabihf-cpp
  sudo ln -s /usr/bin/distcc /usr/lib/distcc/armv6l-unknown-linux-gnueabihf-cc
  sudo ln -s /usr/bin/distcc /usr/lib/distcc/armv6l-unknown-linux-gnueabihf-g++
  sudo ln -s /usr/bin/distcc /usr/lib/distcc/armv6l-unknown-linux-gnueabihf-c++
else
  sudo ln -s /usr/bin/distcc /usr/lib/distcc/armv7l-unknown-linux-gnueabihf-cpp
  sudo ln -s /usr/bin/distcc /usr/lib/distcc/armv7l-unknown-linux-gnueabihf-cc
  sudo ln -s /usr/bin/distcc /usr/lib/distcc/armv7l-unknown-linux-gnueabihf-g++
  sudo ln -s /usr/bin/distcc /usr/lib/distcc/armv7l-unknown-linux-gnueabihf-c++
fi

# Execute distcc daemon.
X_TOOLS_BIN="$HOME/$X_TOOLS/arm-unknown-linux-gnueabihf/bin"
env PATH="$X_TOOLS_BIN:/usr/bin" distccd --daemon --allow 127.0.0.1 --log-file=/var/tmp/distcc.log

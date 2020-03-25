#!/bin/bash
#    repo-make - Tool to autobuild a set of PKGBUILD's into a working repository
#    https://github.com/M-Reimer/repo-make
#    Copyright (C) 2020 Manuel Reimer <manuel.reimer@gmx.de>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This script is meant to be used together with repo-make for building with
# continuous integration systems. The Linux system on the CI build container
# can be any Linux. This script sets up a temporary Arch Linux chroot and then
# runs your build inside it.

set -e

#
# Parameters that are meant to be passed via environment variables
# They are in theory all optional. To test this script on a VM, just place
# your PKGBUILD's to /var/tmp/pkgbuilds and execute the script as root
# The repository will be created to /var/tmp/repo-make-target
#

# Cache directory path
REPO_MAKE_CACHE=${REPO_MAKE_CACHE:-/var/tmp/repo-make-cache}

# Path to create the repository in
REPO_MAKE_TARGET=${REPO_MAKE_TARGET:-/var/tmp/repo-make-target}

# Source path (where PKGBUILD's and repo-make.conf is placed)
REPO_MAKE_PKGBUILDS=${REPO_MAKE_PKGBUILDS:-/var/tmp/pkgbuilds}

# makepkg.conf file to use. It is strongly recommended that you provide your
# own fixed one as we set up the chroot from scratch every time so upstream
# makepkg.conf changes may screw up your repository.
REPO_MAKE_MAKEPKG_CONF=${REPO_MAKE_MAKEPKG_CONF:-/etc/makepkg.conf}

# Arch Linux mirror to use
REPO_MAKE_ARCH_MIRROR=${REPO_MAKE_ARCH_MIRROR:-https://mirrors.edge.kernel.org/archlinux/}

# For which architecture are we meant to build?
REPO_MAKE_ARCH=${REPO_MAKE_ARCH:-x86_64}




#
# repo-make version and checksum.
#

REPO_MAKE_VERSION=3.1.0
REPO_MAKE_SHA1=f4199b77e1a7e0d948e1c73a33ae5f5f89adaa83


#
# Prepare the build environment we were launched in
#

# Build some cache paths and create them if they are not there
SOURCECACHE="$REPO_MAKE_CACHE/sourcedir"
mkdir -p "$SOURCECACHE"
PKGCACHE="$REPO_MAKE_CACHE/pkgcache/$REPO_MAKE_ARCH"
mkdir -p "$PKGCACHE"
IMAGECACHE="$REPO_MAKE_CACHE/imagecache"
mkdir -p "$IMAGECACHE"

# Prepare some temp directory for our use
TMPDIR="/var/tmp/repo-make-ci-$$"
mkdir -m "0700" "$TMPDIR"

# Prepare empty directory for our chroot path
CHROOT="$TMPDIR/build-chroot"
rm -rf "$CHROOT"
mkdir -p "$CHROOT"
# Prevents "could not determine root mount point /" makepkg error
mount --bind "$CHROOT" "$CHROOT"
mount --make-rslave "$CHROOT"

# Create target directory
mkdir -p "$REPO_MAKE_TARGET"

# We want to clean up the stuff we place after exit. Not really needed for
# common CI systems but helps when developing on a VM
function cleanup {
  EXIT_CODE=$?
  set +e # disable termination on error
  # gpg-agent blocks /dev in chroot
  if [ -d "$CHROOT/etc/pacman.d/gnupg" ]; then
    chroot "$CHROOT" gpgconf --homedir /etc/pacman.d/gnupg --kill gpg-agent
  fi
  sleep 1
  umount "$CHROOT/proc"
  umount -R "$CHROOT/dev"
  umount -R "$CHROOT/sys"
  umount -R "$CHROOT/var/cache/pacman/pkg"
  umount "$CHROOT/home/build/pkgbuilds"
  umount "$CHROOT/home/build/target"
  umount "$CHROOT/home/build/srcdest"
  umount "$CHROOT"
  rm -rf --one-file-system "$TMPDIR" && echo "REPO-MAKE-CI: Deleted dir $TMPDIR"
  exit $EXIT_CODE
}
trap cleanup EXIT

#
# Get up-to-date Arch bootstrap image (ensures we have the image in cache)
#

if [ "$REPO_MAKE_ARCH" = "x86_64" ]; then
  # Name of the pacman-key keyring for this architecture
  PACMAN_KEYRING="archlinux"

  # Get name and checksum of latest bootstrap image directly from archlinux.org
  IMAGEINFO=$(wget -q https://www.archlinux.org/iso/latest/sha1sums.txt -O - | grep bootstrap | tee "$TMPDIR/archlinux-bootstrap.sha1")
  IMAGENAME=${IMAGEINFO##* }
  IMAGECHECKSUM=${IMAGEINFO%% *}
  if [ "$IMAGENAME" == "$IMAGECHECKSUM" ] || [ ${#IMAGECHECKSUM} -ne 40 ]; then
    echo "REPO-MAKE-CI: Failed to parse sha1sums.txt!"
    exit 1
  fi

  # If image not in cache, then remove old versions and download new image
  # Includes SHA1SUM check
  if [ ! -s "$IMAGECACHE/$IMAGENAME" ]; then
    rm -f "$IMAGECACHE/archlinux-bootstrap-"*
    echo "REPO-MAKE-CI: Downloading new Arch Linux image: $IMAGENAME"
    wget -q -nc "$REPO_MAKE_ARCH_MIRROR/iso/latest/$IMAGENAME" -O "$TMPDIR/$IMAGENAME"
    env -C "$TMPDIR" sha1sum -c "archlinux-bootstrap.sha1"
    mv "$TMPDIR/$IMAGENAME" "$IMAGECACHE"
  else
    echo "REPO-MAKE-CI: Image $IMAGENAME available in image cache!"
  fi

  # Extract image to chroot path
  echo "REPO-MAKE-CI: Extracting Arch Linux bootstrap image"
  tar -x --strip 1 -f "$IMAGECACHE/$IMAGENAME" -C "$CHROOT"

  # Configure mirror
  echo "Server = $REPO_MAKE_ARCH_MIRROR/\$repo/os/\$arch" >> "$CHROOT/etc/pacman.d/mirrorlist"
elif [ "$REPO_MAKE_ARCH" = "armv7h" ]; then
  # Name of the pacman-key keyring for this architecture
  PACMAN_KEYRING="archlinuxarm"

  # Arch Linux ARM does not have any secure way to get checksums from, so we
  # have to use GPG for verification
  IMAGENAME="ArchLinuxARM-rpi-2-latest.tar.gz"
  OURIMAGENAME="$IMAGENAME-$(date +%Y-%m).tar.gz"
  if [ ! -s "$IMAGECACHE/$OURIMAGENAME" ]; then
    rm -f "$IMAGECACHE/ArchLinuxARM-"*
    echo "REPO-MAKE-CI: Downloading new Arch Linux image: $OURIMAGENAME"
    wget -q -nc "http://os.archlinuxarm.org/os/$IMAGENAME" -O "$TMPDIR/$OURIMAGENAME"
    wget -q -nc "http://os.archlinuxarm.org/os/$IMAGENAME.sig" -O "$TMPDIR/$OURIMAGENAME.sig"
    gpg --recv-key 68B3537F39A313B3E574D06777193F152BDBE6A6
    gpg --verify "$TMPDIR/$OURIMAGENAME.sig"
    mv "$TMPDIR/$OURIMAGENAME" "$IMAGECACHE"
  else
    echo "REPO-MAKE-CI: Image $OURIMAGENAME available in image cache!"
  fi

  # Extract image to chroot path
  echo "REPO-MAKE-CI: Extracting Arch Linux bootstrap image"
  tar -x -f "$IMAGECACHE/$OURIMAGENAME" -C "$CHROOT"

  # If the host has qemu-arm-static installed, then copy it over to our chroot.
  if [ -x "/usr/bin/qemu-arm-static" ]; then
    echo "REPO-MAKE-CI: Copying qemu-arm-static into our chroot"
    cp -a "/usr/bin/qemu-arm-static" "$CHROOT/usr/bin"
  fi

  # Arch Linux ARM has a symlink as /etc/resolv.conf. Remove it.
  rm "$CHROOT/etc/resolv.conf"
fi

#
# Set up chroot
#

# Set up some bind mounts
mount -t proc /proc "$CHROOT/proc"
mount --rbind /dev  "$CHROOT/dev"
mount --make-rslave "$CHROOT/dev"
mount --rbind /sys  "$CHROOT/sys"
mount --make-rslave "$CHROOT/sys"
mount --rbind "$PKGCACHE" "$CHROOT/var/cache/pacman/pkg"
mount --make-rslave       "$CHROOT/var/cache/pacman/pkg"

# Copy resolve.conf
cp -f /etc/resolv.conf "$CHROOT/etc"

# Copy makepkg.conf if possible
if [ -s "$REPO_MAKE_MAKEPKG_CONF" ]; then
  echo "REPO-MAKE-CI: Using makepkg.conf from: $REPO_MAKE_MAKEPKG_CONF"
  cp -f "$REPO_MAKE_MAKEPKG_CONF" "$CHROOT/etc"
else
  echo "REPO-MAKE-CI: WARNING: Using default makepkg.conf!"
fi

# Configure our SRCDEST for caching
echo "SRCDEST='/home/build/srcdest'" >> "$CHROOT/etc/makepkg.conf"

# Set up language
echo "en_US.UTF-8 UTF-8" > "$CHROOT/etc/locale.gen"
echo "LANG=en_US.UTF-8" > "$CHROOT/etc/locale.conf"

# Update chroot and create our build user
# Install/update keyring first so we don't get gpg errors for outdated keys
chroot "$CHROOT" /bin/bash -c \
  "source /etc/profile; \
  pacman-key --init; \
  pacman-key --populate $PACMAN_KEYRING; \
  pacman -Sy --noconfirm; \
  pacman -S --noconfirm --needed $PACMAN_KEYRING-keyring; \
  pacman -Su --noconfirm; \
  pacman -S --needed --noconfirm base-devel; \
  locale-gen; \
  useradd -m build"

# Create build target, cache and source directories and connect them
mkdir -p "$CHROOT/home/build/"{target,srcdest,pkgbuilds}
mount --rbind "$REPO_MAKE_PKGBUILDS" "$CHROOT/home/build/pkgbuilds"
mount --rbind "$REPO_MAKE_TARGET" "$CHROOT/home/build/target"
mount --rbind "$SOURCECACHE" "$CHROOT/home/build/srcdest"

# Download repo-make, verify checksum
REPO_MAKE_PKG="repo-make-$REPO_MAKE_VERSION-1-any.pkg.tar.xz"
REPO_MAKE_URL="https://github.com/M-Reimer/repo-make/releases/download/$REPO_MAKE_VERSION/$REPO_MAKE_PKG"
wget -q -nc "$REPO_MAKE_URL" -O "$CHROOT/root/$REPO_MAKE_PKG"
echo "$REPO_MAKE_SHA1  $REPO_MAKE_PKG" > "$CHROOT/root/$REPO_MAKE_PKG.sha1"
env -C "$CHROOT/root" sha1sum -c "$REPO_MAKE_PKG.sha1"

# Install repo-make into chroot, run build
chroot "$CHROOT" /bin/bash -c \
  "source /etc/profile; \
  chown -R build /home/build; \
  pacman -U --noconfirm /root/$REPO_MAKE_PKG; \
  repo-make --restore-repo-mtimes -V -C /home/build/pkgbuilds -t /home/build/target"

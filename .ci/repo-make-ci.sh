#!/bin/bash
#    repo-make - Tool to autobuild a set of PKGBUILD's into a working repository
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
REPO_MAKE_TARGET=${REPO_MAKE_TARGET:-/var/tmp/repo-make-target/x86_64}

# Source path (where PKGBUILD's and repo-make.conf is placed)
REPO_MAKE_PKGBUILDS=${REPO_MAKE_PKGBUILDS:-/var/tmp/pkgbuilds}

# Packager name
REPO_MAKE_PACKAGER=${REPO_MAKE_PACKAGER:-"repo-make-ci autobuild for "${REPO_MAKE_PKGBUILDS##*/}}

# Arch Linux mirror to use
REPO_MAKE_ARCH_MIRROR=${REPO_MAKE_ARCH_MIRROR:-https://mirrors.edge.kernel.org/archlinux/}





#
# repo-make version and checksum.
#

REPO_MAKE_VERSION=3.0.0
REPO_MAKE_SHA1=d4512e27859c49da2adce14a70ea393cc54b4233

#
# Helper functions
#

# Downloads file and verifies sha1sum
# - First parameter: URL
# - Second parameter: Target path
# - Third parameter: SHA1SUM
DownloadAndCheck () {
  # Download
  TMPFILE="$TMPDIR/download_file.tmp"
  wget -q -nc "$1" -O "$TMPFILE"

  # Get download checksum
  DLCHECKSUM=$(sha1sum "$TMPFILE")
  DLCHECKSUM=${DLCHECKSUM%% *}

  # Verify checksum
  if [ "$DLCHECKSUM" != "$3" ]; then
    echo "REPO-MAKE-CI: Checksum check failed for ${1##*/}!"
    rm "$TMPFILE"
    exit 1
  else
    mv "$TMPFILE" "$2"
  fi
}

#
# Prepare the build environment we were launched in
#

# Build some cache paths and create them if they are not there
SOURCECACHE="$REPO_MAKE_CACHE/sourcedir"
mkdir -p "$SOURCECACHE"
PKGCACHE="$REPO_MAKE_CACHE/pkgcache"
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
  killall gpg-agent && sleep 1 # gpg-agent blocks /dev in chroot
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

# Get name and checksum of latest bootstrap image directly from archlinux.org
IMAGEINFO=$(wget -q https://www.archlinux.org/iso/latest/sha1sums.txt -O - | grep bootstrap)
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
   DownloadAndCheck "$REPO_MAKE_ARCH_MIRROR/iso/latest/$IMAGENAME" "$IMAGECACHE/$IMAGENAME" "$IMAGECHECKSUM"
else
  echo "REPO-MAKE-CI: Image $IMAGENAME available in image cache!"
fi

#
# Set up chroot
#

# Extract image to chroot path
echo "REPO-MAKE-CI: Extracting Arch Linux bootstrap image"
tar -x --strip 1 -f "$IMAGECACHE/$IMAGENAME" -C "$CHROOT"

# Configure mirror
echo "Server = $REPO_MAKE_ARCH_MIRROR/\$repo/os/\$arch" >> "$CHROOT/etc/pacman.d/mirrorlist"

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

# Set up language
echo "en_US.UTF-8 UTF-8" > "$CHROOT/etc/locale.gen"
echo "LANG=en_US.UTF-8" > "$CHROOT/etc/locale.conf"

# Update chroot and create our build user
# Install/update keyring first so we don't get gpg errors for outdated keys
chroot "$CHROOT" /bin/bash -c \
  "source /etc/profile; \
  pacman-key --init; \
  pacman-key --populate archlinux; \
  pacman -Sy --noconfirm; \
  pacman -S --noconfirm --needed archlinux-keyring; \
  pacman -Su --noconfirm; \
  pacman -S --needed --noconfirm base-devel; \
  locale-gen; \
  useradd -m build"

# Create build target, cache and source directories and connect them
mkdir -p "$CHROOT/home/build/"{target,srcdest,pkgbuilds}
mount --rbind "$REPO_MAKE_PKGBUILDS" "$CHROOT/home/build/pkgbuilds"
mount --rbind "$REPO_MAKE_TARGET" "$CHROOT/home/build/target"
mount --rbind "$SOURCECACHE" "$CHROOT/home/build/srcdest"

# Build configuration
echo "MAKEFLAGS='-j2'" >> "$CHROOT/etc/makepkg.conf"
echo "PACKAGER='$REPO_MAKE_PACKAGER'" >> "$CHROOT/etc/makepkg.conf"
echo "SRCDEST='/home/build/srcdest'" >> "$CHROOT/etc/makepkg.conf"

# Download repo-make, verify checksum
REPO_MAKE_PKG="repo-make-$REPO_MAKE_VERSION-1-any.pkg.tar.xz"
REPO_MAKE_URL="https://github.com/M-Reimer/repo-make/releases/download/$REPO_MAKE_VERSION/$REPO_MAKE_PKG"
DownloadAndCheck "$REPO_MAKE_URL" "$CHROOT/root/$REPO_MAKE_PKG" "$REPO_MAKE_SHA1"

# Hardcoded for now. Actually making this "multi arch" would require some
# additional work (different bootstrap images and some adaptions for parameters)
REPO_MAKE_ARCH="x86_64"

# Install repo-make into chroot, run build
chroot "$CHROOT" /bin/bash -c \
  "source /etc/profile; \
  chown -R build /home/build; \
  pacman -U --noconfirm /root/$REPO_MAKE_PKG; \
  repo-make -V -C /home/build/pkgbuilds -t /home/build/target/$REPO_MAKE_ARCH"

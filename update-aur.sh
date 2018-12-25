#!/usr/bin/bash

#   VDR4Arch AUR Auto-Update script
#   Copyright (C) 2018 Manuel Reimer <manuel.reimer@gmx.de>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.


# This script Auto-Distributes all changes, made here, to the relevant AUR
# repositories. This way development of the whole package set can be done in one
# single Github repository. The commit messages for AUR are auto-generated.

#
# Configuration
#

# AUR packages handled in this Git repository (full relative path).
PKGLIST=( \
  'deps/graphlcd-base' \
  'deps/libdvbcsa' \
  'deps/perl-template-plugin-javascript' \
  'deps/serdisplib' \
  'deps/tntdb' \
  'deps/tntnet' \
  'fonts/ttf-sourcesanspro' \
  'fonts/ttf-teletext2' \
  'fonts/ttf-vdrsymbols' \
  'irctl' \
  'irmplircd' \
  'kodi-addon-graphlcd' \
  'kodi-addon-pvr-vdr-vnsi' \
  'kodi-setwakeup' \
  'naludump' \
  'plugins/vdr-'* \
  'vdr' \
  'vdr-api' \
  'vdr-addon-lifeguard' \
  'vdradmin-am' \
  'vdr-checkts' \
  'vdrctl' \
  'vdr-epg-daemon' \
  'vdrnfofs' \
  'vdrpbd' \
  'vdr-xorg' \
)

# Commit message-generator
function CommitMessage {
  echo "Sync from VDR4Arch (https://github.com/VDR4Arch/vdr4arch/commit/$1)"
}

# Relative path to the cache directory
AURCACHE="aur-git-cache"



#
# Main code to handle the sync
#

# Create the AUR repository cache directory
mkdir -p "$AURCACHE" || exit 1

# Loop over the package list
for pkgbuilddir in "${PKGLIST[@]}"; do
  echo "Syncing $pkgbuilddir" >&2

  # Extract just the pkgbase (Requires .SRCINFO to be next to the PKGBUILD!)
  pkgbase=$(sed -n 's/^pkgbase = //p' "$pkgbuilddir/.SRCINFO")
  if [ -z "$pkgbase" ]; then
    echo "Failed to get pkgbase for $pkgbuilddir" >&2
    exit 1
  fi

  # If the AUR cache directory doesn't exist, then do a checkout
  aurgit="$AURCACHE/$pkgbase"
  if [ ! -d "$aurgit" ]; then
    git clone "ssh://aur@aur.archlinux.org/${pkgbase}.git" "$aurgit" || exit 1
  fi

  # Get timestamp of latest AUR GIT commit
  aurcommit_time=$(git --git-dir="$aurgit/.git" show -s --format=%ct HEAD)
  if [ -z "$aurcommit_time" ]; then
    aurcommit_time=0
  fi

  # Get timestamp of the Github GIT commit for the PKGBUILD we want to sync
  commit_time=$(git log --format=%ct -1 "$pkgbuilddir/PKGBUILD")

  # Compare the two timestamps.
  if [ "$aurcommit_time" -ge "$commit_time" ]; then
    echo "  Nothing to do!" >&2
    continue
  fi

  # Generate source tarball of our PKGBUILD
  pushd "$pkgbuilddir" >/dev/null || exit 1
    rm -f ./*.src.tar
    SRCEXT='.src.tar' makepkg --skipinteg --source >/dev/null
    commitid=$(git log --format="%H" -n 1 .)
  popd >/dev/null

  # Place the new files into the AUR cache
  pushd "$aurgit" >/dev/null || exit 1
    git rm ./* .SRCINFO >/dev/null 2>&1
  popd >/dev/null
  bsdtar -xf "$pkgbuilddir/"*.src.tar --strip 1 -C "$aurgit"
  rm -f "$pkgbuilddir/"*.src.tar
  pushd "$aurgit" >/dev/null || exit 1
    git add ./* .SRCINFO >/dev/null 2>&1
    if ! git diff --cached --exit-code --quiet; then
      git commit -m "$(CommitMessage $commitid)"
    fi
    git push origin master || exit 1
  popd >/dev/null
done

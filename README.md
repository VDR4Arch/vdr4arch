VDR4Arch
========

[![Build Status](https://travis-ci.com/VDR4Arch/vdr4arch.svg?branch=master)](https://travis-ci.com/VDR4Arch/vdr4arch)

VDR4Arch is a set of VDR packages for Arch Linux.

Our goal is it to combine the feature-richness of VDR with the bleeding edge
design of Arch Linux. This repository also contains some "non VDR" tools that
may be used with VDR (minisatip) or as substitute to VDR (tvheadend).

The provided (and autobuilt) VDR version is always the latest stable version.
For self-compiling of "development versions" you can use the provided "vdr-git"
PKGBUILD which builds from an "unofficial" VDR GIT repository which contains the
official development versions including **official** VDR patches.

AUR
---

All VDR and other media packages are developed here and synced automatically
over to AUR, so please file issues and pull requests here. If your
changes/requests are accepted by the VDR4Arch team, then your change appears on
AUR automatically.

Install the base system
-----------------------

Installing Archlinux is not a big deal. Just follow this Installation Guide
https://wiki.archlinux.org/index.php/Installation_Guide

We don't need many different partitions on VDR systems. In most cases a single `/` (root)
partiton is enough. If you want to separate the system from your recordings
mount another partition to `/srv/vdr/video`

Install VDR4Arch packages
-------------------------

Take a look at the Installation Section in our wiki
https://github.com/VDR4Arch/vdr4arch/wiki/VDR4Arch-Installation-(en_US)#Installation

Compile from source
-------------------

You can find more information about compiling vdr4arch's packages in our wiki
https://github.com/VDR4Arch/vdr4arch/wiki/VDR4Arch-Installation-(en_US)#compile-vdr4arch

Feature/Plugin missing?
-----------------------

You miss something and you want us to add it. No problem!

File an issue, please. But be aware that we don't want to add more patches to
the VDR package.

https://github.com/VDR4Arch/vdr4arch/issues

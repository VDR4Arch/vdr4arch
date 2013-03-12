vdr4arch
========

VDR4Arch is a set of VDR packages for Archlinux.

Our goal is it to combine the feature-richness of VDR with the bleeding edge
design of Archlinux.

Install the base system
-----------------------

Installing Archlinux is not a big deal. Just follow this Installation Guide
and skip the last step (Add a user)

https://wiki.archlinux.org/index.php/Installation_Guide

We don't need many different partitions on VDR systems. In most cases a single `/` (root)
partiton is enough. If you want to separate the system from your recordings
mount another partition to `/srv/vdr/video`

Install VDR4Arch packages
-------------------------

Download [vdr4arch-keyring](http://creimer.net/vdr4arch/repo/vdr4arch-keyring-20130219-1-any.pkg.tar.xz) and install it with `pacman -U`

Open /etc/pacman.conf with your favorites editor and add the following

    [vdr4arch]
    SigLevel = PackageRequired
    Server = http://creimer.net/vdr4arch/repo

To list all available packages run

`pacman -Slq vdr4arch`

For a working VDR install at least `vdr` and `runvdr-extreme`

Compile from source
-------------------

The easiest way? Follow the instuctions for the tool
repo-make at repo-make.tuxfamily.org

Compatibility
-------------

VDR4Arch may be compatible to other VDR packages (e.g. ArchVDR or AUR), but
we don't support that. If you miss any feature/plugin/addon etc, read the next
paragraph.


Feature/Plugin missing?
-----------------------

You miss something and you want us to add it. No problem!

Just file a bug and add the label "enhancement"

https://github.com/CReimer/vdr4arch/issues

Known problems
--------------

None?!?

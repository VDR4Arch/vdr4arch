vdr4arch
========

VDR4Arch is a set of VDR packages for Archlinux.

Our goal is it to combine the feature-richness of VDR with the bleeding edge
design of Archlinux. We provide always the newest version (developer or stable).
But we delay new vdr releases for at least one week in a separate vdr4arch-testing
repository. You can find more information on this testing repository in our wiki

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

Compatibility
-------------

VDR4Arch may be compatible to other VDR packages (e.g. ArchVDR or AUR), but
we don't support that. If you miss any feature/plugin/addon etc, read the next
paragraph.


Feature/Plugin missing?
-----------------------

You miss something and you want us to add it. No problem!

File a bug, please. But be aware that we don't want add more patches to the vdr package

https://github.com/CReimer/vdr4arch/issues

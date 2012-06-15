#!/bin/sh
PRGNAM=vdr-plugin-softhddevice
REPO=git://projects.vdr-developer.org/$PRGNAM.git
git clone --depth 1 $REPO
cd $PRGNAM
#VERSION=$(git describe --always)
VERSION=$(git log -n1 --date=iso | grep 'Date:' | cut -d' ' -f4 | sed 's/-//g')
git archive HEAD --format=tar --prefix=$PRGNAM-$VERSION/ | bzip2 > ../$PRGNAM-$VERSION.tar.bz2
cd ..
rm -rf $PRGNAM

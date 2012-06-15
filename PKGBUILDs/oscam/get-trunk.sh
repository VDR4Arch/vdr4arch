#!/bin/sh
PRGNAM=oscam
REPO=http://streamboard.gmc.to/svn/oscam/trunk
svn co $REPO $PRGNAM
cd $PRGNAM
#VERSION=$(git describe --always)
VERSION=$(svn log -r HEAD | grep -n 2 | awk '{ print $5 }' | sed 's/-//g')
cd ..
mv $PRGNAM $PRGNAM-$VERSION
tar -cjf $PRGNAM-$VERSION.tar.bz2 $PRGNAM-$VERSION
rm -rf $PRGNAM-$VERSION

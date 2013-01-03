# Maintainer: Christopher Reimer <c[dot]reimer[at]googlemail[dot]com>
pkgname=vdr-streamdev
pkgver=20121216
_gitver=9135cde7
_vdrapi=1.7.35
pkgrel=1
pkgdesc="implementation of the VTP (Video Transfer Protocol)"
url="http://projects.vdr-developer.org/projects/show/plg-streamdev"
arch=('x86_64' 'i686')
license=('GPL2')
depends=('gcc-libs' "vdr-api=${_vdrapi}")
optdepends=()
_plugname=$(echo $pkgname | sed 's/vdr-//g')
replaces=("vdr-plugin-$_plugname")
conflicts=("vdr-plugin-$_plugname")
source=("http://projects.vdr-developer.org/git/vdr-plugin-$_plugname.git/snapshot/vdr-plugin-$_plugname-$_gitver.tar.bz2")
md5sums=('32154582e0fed368ea3314a8dbcf15d3')

package() {
  cd "${srcdir}/vdr-plugin-${_plugname}-${_gitver}"

  sed -i '/Make\.global/d' Makefile

  mkdir -p $pkgdir/usr/lib/vdr/plugins
  make CFLAGS="$(pkg-config vdr --variable=cflags)" \
       CXXFLAGS="$(pkg-config vdr --variable=cxxflags)" \
       VDRDIR="/usr/include/vdr" \
       LIBDIR="$pkgdir/$(pkg-config vdr --variable=libdir)" \
       LOCALEDIR="$pkgdir/$(pkg-config vdr --variable=locdir)"
}

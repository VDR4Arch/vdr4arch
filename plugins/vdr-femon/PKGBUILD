# Maintainer: Christopher Reimer <c[dot]reimer[at]googlemail[dot]com>
pkgname=vdr-femon
pkgver=1.7.17
_vdrapi=1.7.35
pkgrel=4
pkgdesc="DVB Frontend Status Monitor plugin"
url="http://www.saunalahti.fi/rahrenbe/vdr/femon/"
arch=('x86_64' 'i686')
license=('GPL2')
depends=('gcc-libs' "vdr-api=${_vdrapi}")
_plugname=$(echo $pkgname | sed 's/vdr-//g')
replaces=("vdr-plugin-$_plugname")
conflicts=("vdr-plugin-$_plugname")
source=("http://www.saunalahti.fi/~rahrenbe/vdr/femon/files/$pkgname-$pkgver.tgz")
md5sums=('ed52aaffd3ba9cecccd191fadf8d85c7')

package() {
  cd "${srcdir}/${_plugname}-${pkgver}"

  mkdir -p $pkgdir/usr/lib/vdr/plugins
  make CFLAGS="$(pkg-config vdr --variable=cflags)" \
       CXXFLAGS="$(pkg-config vdr --variable=cxxflags)" \
       VDRDIR="/usr/include/vdr" \
       LIBDIR="$pkgdir/$(pkg-config vdr --variable=libdir)" \
       LOCALEDIR="$pkgdir/$(pkg-config vdr --variable=locdir)" \
       GITTAG=''
}

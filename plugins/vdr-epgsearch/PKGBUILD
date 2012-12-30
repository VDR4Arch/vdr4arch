# Maintainer: Christopher Reimer <c[dot]reimer[at]googlemail[dot]com>
pkgname=vdr-epgsearch
pkgver=1.0.1.beta2
_vdrapi=1.7.35
pkgrel=4
pkgdesc="Searchtimer and replacement of the VDR program menu"
url="http://winni.vdr-developer.org/epgsearch"
arch=('x86_64' 'i686')
license=('GPL2')
depends=('pcre' "vdr-api=${_vdrapi}")
_plugname=$(echo $pkgname | sed 's/vdr-//g')
replaces=("vdr-plugin-$_plugname")
conflicts=("vdr-plugin-$_plugname")
source=("http://winni.vdr-developer.org/epgsearch/downloads/beta/$pkgname-$pkgver.tgz"
        'epgsearch-vdr-1.7.33.diff::http://projects.vdr-developer.org/git/vdr-plugin-epgsearch.git/patch/?id=1a055e2b')
md5sums=('8ad2bd6a6557532b388adbf70d87d59a'
         '4231ef21c9bad75f9af845dfa85cf1f5')

package() {
  cd "${srcdir}/${_plugname}-${pkgver}"

  patch -p1 -i $srcdir/epgsearch-vdr-1.7.33.diff

  mkdir -p $pkgdir/usr/lib/vdr/plugins
  make CFLAGS="$(pkg-config vdr --variable=cflags)" \
       CXXFLAGS="$(pkg-config vdr --variable=cxxflags)" \
       VDRDIR="/usr/include/vdr" \
       LIBDIR="$pkgdir/$(pkg-config vdr --variable=libdir)" \
       LOCALEDIR="$pkgdir/$(pkg-config vdr --variable=locdir)" \
       MANDIR=$pkgdir/usr/share/man \
       all install-doc
}

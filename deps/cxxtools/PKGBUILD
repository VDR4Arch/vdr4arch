# Maintainer: Christopher Reimer <c[dot]reimer[at]googlemail[dot]com>
pkgname=cxxtools
pkgver=2.1.1
pkgrel=2
pkgdesc="Collection of general-purpose C++ classes"
url="http://www.tntnet.org"
arch=('x86_64' 'i686')
license=('GPL2')
depends=('bash' 'gcc-libs')
options=(!libtool)
source=("http://www.tntnet.org/download/${pkgname}-${pkgver}.tar.gz")
md5sums=('2026a2bb23b966f13893167b4dbc5d70')

build() {
  cd "${srcdir}/${pkgname}-${pkgver}"
  ./configure --prefix=/usr \
              --disable-demos \
              --disable-unittest
  make
}

package() {
  cd "${srcdir}/${pkgname}-${pkgver}"
  make DESTDIR="${pkgdir}" install
}

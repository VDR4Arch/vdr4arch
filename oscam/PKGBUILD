# Maintainer: Christopher Reimer <vdr4arch[at]creimer[dot]net>
pkgname=oscam
pkgver=9767
pkgrel=1
pkgdesc="Open Source Conditional Access Module software"
url="http://www.streamboard.tv/oscam"
arch=('x86_64' 'i686' 'arm' 'armv6h' 'armv7h')
license=('GPL3')
depends=('libusb' 'openssl')
backup=('var/lib/oscam/oscam.conf')
install='oscam.install'
source=("${pkgname}-${pkgver}.zip::http://www.streamboard.tv/oscam/changeset/${pkgver}/trunk?old_path=%2F&old=${pkgver}&format=zip"
        'oscam.conf'
        'oscam.service'
        'oscam-faster_retry.diff')
noextract="${pkgname}-${pkgver}.zip"
md5sums=('b07b19f8d0238409b51ee9ec7ccd3e9a'
         'f6200432fa01030016d6fac913033812'
         '0de56c99e34a6bdb7f4dc6349478a920'
         'b67f77bf1ecaeb9bc4f8cddb5258ed4e')

prepare() {
  cat "${pkgname}-${pkgver}.zip" | bsdtar -xf -

  cd "$srcdir/trunk"
  chmod +x config.sh webif/pages_mkdep
  patch -p1 -i "$srcdir/oscam-faster_retry.diff"
}

build() {
  cd "$srcdir/trunk"

  make CONF_DIR=/var/lib/oscam \
       USE_SSL=1 \
       USE_LIBUSB=1 \
       OSCAM_BIN=oscam \
       LIST_SMARGO_BIN=list_smargo \
       SVN_REV=$pkgver
}

package() {
  cd "$srcdir/trunk"

  #Install binaries
  install -Dm755 oscam "$pkgdir/usr/bin/oscam"
  install -Dm755 list_smargo "$pkgdir/usr/bin/list_smargo"

  #Install config
  install -Dm644 "$srcdir/oscam.conf" "$pkgdir/var/lib/oscam/oscam.conf"

  #Install man-pages
  mkdir -p $pkgdir/usr/share/man/man1/
  mkdir -p $pkgdir/usr/share/man/man5/
  install -Dm644 Distribution/doc/man/*.1 "$pkgdir/usr/share/man/man1"
  install -Dm644 Distribution/doc/man/*.5 "$pkgdir/usr/share/man/man5"

  #Install service file
  install -Dm644 ${srcdir}/oscam.service "$pkgdir/usr/lib/systemd/system/oscam.service"
}

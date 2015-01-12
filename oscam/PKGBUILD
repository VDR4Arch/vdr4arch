# Maintainer: Christopher Reimer <vdr4arch[at]creimer[dot]net>
pkgname=oscam
pkgver=10173
pkgrel=1
pkgdesc="Open Source Conditional Access Module software"
url="http://www.streamboard.tv/oscam"
arch=('x86_64' 'i686' 'arm' 'armv6h' 'armv7h')
license=('GPL3')
depends=('libusb' 'openssl')
install='oscam.install'
source=("${pkgname}-${pkgver}.zip::http://www.streamboard.tv/oscam/changeset/${pkgver}/trunk?old_path=%2F&old=${pkgver}&format=zip"
        'oscam.service'
        'oscam.sysuser')
noextract=("${pkgname}-${pkgver}.zip")
md5sums=('48b0d428e055271151439195743edc8e'
         '0de56c99e34a6bdb7f4dc6349478a920'
         'be0d9d7a5fdd8cf4918c4ea91cebd989')

prepare() {
  cat "${pkgname}-${pkgver}.zip" | bsdtar -xf -

  cd "$srcdir/trunk"
  chmod +x config.sh webif/pages_mkdep
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

  #Install man-pages
  mkdir -p $pkgdir/usr/share/man/man1/
  mkdir -p $pkgdir/usr/share/man/man5/
  install -Dm644 Distribution/doc/man/*.1 "$pkgdir/usr/share/man/man1"
  install -Dm644 Distribution/doc/man/*.5 "$pkgdir/usr/share/man/man5"

  #Install service file
  install -Dm644 ${srcdir}/oscam.service "$pkgdir/usr/lib/systemd/system/oscam.service"

  #Install sysuser config
  install -Dm644 ${srcdir}/oscam.sysuser "$pkgdir/usr/lib/sysusers.d/oscam.conf"
}

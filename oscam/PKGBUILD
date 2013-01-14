# Maintainer: Christopher Reimer <c[dot]reimer[at]googlemail[dot]com>
pkgname=oscam
pkgver=8109
pkgrel=1
pkgdesc="Open Source Conditional Access Module software"
url="http://www.oscam.cc"
arch=('x86_64' 'i686')
license=('GPL3')
depends=('libusb' 'openssl')
backup=('etc/logrotate.d/oscam'
        'var/lib/oscam/oscam.ac'
        'var/lib/oscam/oscam.cacheex'
        'var/lib/oscam/oscam.cert'
        'var/lib/oscam/oscam.conf'
        'var/lib/oscam/oscam.dvbapi'
        'var/lib/oscam/oscam.guess'
        'var/lib/oscam/oscam.ird'
        'var/lib/oscam/oscam.provid'
        'var/lib/oscam/oscam.server'
        'var/lib/oscam/oscam.services'
        'var/lib/oscam/oscam.srvid'
        'var/lib/oscam/oscam.tiers'
        'var/lib/oscam/oscam.user'
        'var/lib/oscam/oscam.whitelist')
source=("${pkgname}-${pkgver}.zip::http://www.streamboard.tv/oscam/changeset/${pkgver}/trunk?old_path=%2F&old=${pkgver}&format=zip"
        'oscam.logrotate'
        'oscam.service')
noextract="${pkgname}-${pkgver}.zip"
md5sums=('378cbf5c5b98038f5c31c5c6a987d717'
         '1fadb043e8bf28f3a5fed8732dad39a3'
         '5aff1b9db0027133f3f104fb19d5820c')

build() {
  cat "${pkgname}-${pkgver}.zip" | bsdtar -xf -

  cd "${srcdir}/trunk"
  chmod +x config.sh

  make CONF_DIR=/var/lib/oscam \
       USE_SSL=1 \
       USE_LIBUSB=1 \
       OSCAM_BIN=oscam \
       LIST_SMARGO_BIN=list_smargo \
       SVN_REV=$pkgver
}

package() {
  cd "${srcdir}/trunk"

  #Install binaries
  install -Dm755 oscam "$pkgdir/usr/bin/oscam"
  install -Dm755 list_smargo "$pkgdir/usr/bin/list_smargo"

  #Install configs
  mkdir -p $pkgdir/var/lib/oscam
  install -Dm644 Distribution/doc/example/* "$pkgdir/var/lib/oscam"

  #Install man-pages
  mkdir -p $pkgdir/usr/share/man/man1/
  mkdir -p $pkgdir/usr/share/man/man5/
  install -Dm644 Distribution/doc/man/*.1 "$pkgdir/usr/share/man/man1"
  install -Dm644 Distribution/doc/man/*.5 "$pkgdir/usr/share/man/man5"

  #Install service file
  install -Dm755 ${srcdir}/oscam.service "$pkgdir/usr/lib/systemd/system/oscam.service"

  #Install logrotate rule
  install -Dm644 ${srcdir}/oscam.logrotate "$pkgdir/etc/logrotate.d/oscam"
}

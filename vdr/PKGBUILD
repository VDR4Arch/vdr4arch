# Maintainer: Christopher Reimer <c[dot]reimer[at]googlemail[dot]com>
pkgname=vdr
pkgver=1.7.35
pkgrel=1
pkgdesc="'open' digital satellite receiver and timer controlled video disk recorder"
url="http://tvdr.de/"
arch=('x86_64' 'i686')
license=('GPL2')
depends=('libjpeg-turbo' 'perl' 'ttf-dejavu')
optdepends=('lirc: remote control support'
            'runvdr-extreme: startscript for vdr')
provides=("vdr-api=$pkgver")
backup=('var/lib/vdr/channels.conf'
        'var/lib/vdr/diseqc.conf'
        'var/lib/vdr/keymacros.conf'
        'var/lib/vdr/scr.conf'
        'var/lib/vdr/sources.conf'
        'var/lib/vdr/svdrphosts.conf')
options='!emptydirs'
install='vdr.install'
source=("ftp://ftp.tvdr.de/vdr/Developer/${pkgname}-${pkgver}.tar.bz2"
        'MainMenuHooks-v1_0_2.diff::http://www.vdr-portal.de/index.php?page=Attachment&attachmentID=30330'
        'shutdown.sh'
        'shutdown-wrapper.c')
md5sums=('3b9d0376325370afb464b6c5843591c7'
         '301c9b9766ed5182b07f1debc79abc21'
         'ef8e11062f58a9eb4016dfbf66bb9044'
         '7cad811b4ac5ee6c0b5496d006f1e0ee')

build() {
  gcc -o shutdown-wrapper shutdown-wrapper.c

  cd "${srcdir}/${pkgname}-${pkgver}"

cat > Make.config <<EOF
PREFIX       = /usr
INCDIR       = /usr/include
LOCDIR       = /usr/share/locale
LIBDIR       = /usr/lib/vdr/plugins
VIDEODIR     = /srv/vdr/video
CONFDIR      = /var/lib/vdr
CACHEDIR     = /var/cache/vdr
RESDIR       = /usr/share/vdr
VDR_USER     = vdr
EOF

  patch -p1 -i ${srcdir}/MainMenuHooks-v1_0_2.diff

  # Build VDR with recommended optimization level
  CFLAGS+=' -O3'
  CXXFLAGS+=' -O3 -fPIC'


  # Workaround for missing include in plugin makefiles
  CFLAGS+=" -I$(pwd)/include"
  CXXFLAGS+=" -I$(pwd)/include"

  make
}

package() {
  install -Dm754 shutdown-wrapper "$pkgdir/usr/lib/vdr/bin/shutdown-wrapper"
  install -Dm755 shutdown.sh "$pkgdir/usr/lib/vdr/bin/shutdown.sh"

  cd "${srcdir}/${pkgname}-${pkgver}"

  CFLAGS+=' -O3'
  CXXFLAGS+=' -O3 -fPIC'

  make DESTDIR="${pkgdir}" install
}

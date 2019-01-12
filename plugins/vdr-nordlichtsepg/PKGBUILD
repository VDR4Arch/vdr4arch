# This PKGBUILD could be part of the VDR4Arch project [https://github.com/vdr4arch]

pkgname=vdr-nordlichtsepg
pkgver=0.10
_gitver=0ef021ec3ecfdb42f7f4fb7c263d92a9db80b71a
_vdrapi=2.4.0
pkgrel=1
pkgdesc="The plugin provides an EPG (Electronic Program Guide) similar to the built-in one, but with extra features."
url="https://github.com/lmaresch/vdr-plugin-nordlichtsepg"
arch=('x86_64' 'i686' 'arm' 'armv6h' 'armv7h')
license=('AGPL3')
depends=("vdr-api=${_vdrapi}")
optdepends=('ttf-vdrsymbols')
_plugname=${pkgname//vdr-/}
source=("vdr-plugin-${_plugname}::git+https://github.com/lmaresch/vdr-plugin-nordlichtsepg#commit=$_gitver"
        "50-$_plugname.conf")
backup=("etc/vdr/conf.avail/50-$_plugname.conf")
sha512sums=('SKIP'
         'd8de710cbdd811b1931d946ba906b73bdddc4bc09594ddada86733784bfca81ed14e2d3480fb51a378949f7b3005d1490cfc8a7e2fec0c7569c75ea7ff9d8ca6')

pkgver() {
    cd "${srcdir}/vdr-plugin-${_plugname}"
    git describe --tags | sed 's/-/_/g;s/v//'
}

prepare() {
    cd "${srcdir}/vdr-plugin-${_plugname}"
}

build() {
    cd "${srcdir}/vdr-plugin-${_plugname}"
    make
}

package() {
    cd "${srcdir}/vdr-plugin-${_plugname}"
    make DESTDIR="${pkgdir}" install

    install -Dm644 "$srcdir/50-$_plugname.conf" "$pkgdir/etc/vdr/conf.avail/50-$_plugname.conf"
}
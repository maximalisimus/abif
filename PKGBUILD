pkgname=abif-master
_pkgrun="abif"
pkgver=2.7
pkgrel=1
arch=('any')
url="https://github.com/maximalisimus/$pkgname/"
license=('GPL')
depends=(dialog parted gparted)
makedepends=(git imagemagick)
replaces=($pkgname)

source=("$pkgname::git+https://github.com/maximalisimus/$pkgname.git"
	)
	
md5sums=('SKIP'
	)

prepare() {
	cd ${srcdir}/$pkgname
	make DESTDIR=/ desktop
	make icon
	make DESTDIR=./post/ install
}

package() {
	mkdir -p $pkgdir/usr/
	cp -a ${srcdir}/$pkgname/post/usr/* $pkgdir/usr/
}

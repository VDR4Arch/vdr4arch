#!/bin/bash

set -e

builduser="${1}"
reposrc="${2}"
alarch="${3}"

alchroot=/home/${builduser}/abs/${alarch}
reponame=$(basename ${reposrc})

setup_x86_64_chroot() {
	wget -nc -P /home/${builduser}/ -r -l 1 -nd -A 'archlinux-bootstrap-*-x86_64.tar.gz' 'https://mirrors.ocf.berkeley.edu/archlinux/iso/latest/'
	tar -x -z --strip 1 -C /home/${builduser}/abs/${alarch}/ -f /home/${builduser}/archlinux-bootstrap-*-x86_64.tar.gz
	printf "Server = https://mirrors.kernel.org/archlinux/\$repo/os/\$arch\n" >> ${alchroot}/etc/pacman.d/mirrorlist
}

mkdir -p ${alchroot}
mount --bind ${alchroot} ${alchroot}
setup_${alarch}_chroot

mount -t proc /proc ${alchroot}/proc
mount --rbind /dev ${alchroot}/dev
mount --rbind /sys ${alchroot}/sys
cp -f /etc/resolv.conf ${alchroot}/etc/
printf "en_US.UTF-8 UTF-8\n" > ${alchroot}/etc/locale.gen
chroot ${alchroot} /bin/bash -c \
	"source /etc/profile; \
	locale-gen; \
	pacman-key --init; \
	pacman-key --populate ${distro}; \
	pacman -S -y -u --noconfirm base-devel; \
	groupadd -g 2000 ${builduser}; \
	useradd -u 2000 -g 2000 -m -s /bin/bash ${builduser}"

mkdir -p ${alchroot}/home/${builduser}/{repo,src,${reponame}}
mkdir -p /home/${builduser}/{repo/${alarch},src}
mount --bind /home/${builduser}/repo ${alchroot}/home/${builduser}/repo
mount --bind /home/${builduser}/src ${alchroot}/home/${builduser}/src
mount --bind ${reposrc} ${alchroot}/home/${builduser}/${reponame}
printf "MAKEFLAGS='-j2'\nPACKAGER=\"${reponame} build bot\"\nSRCDEST=/home/${builduser}/src\n" >> ${alchroot}/etc/makepkg.conf

wget -q -nc -P ${alchroot}/usr/bin 'https://github.com/M-Reimer/repo-make/raw/master/repo-make'
chmod 755 ${alchroot}/usr/bin/repo-make
printf "BUILDUSER=${builduser}\n" > ${alchroot}/etc/repo-make.conf
chroot ${alchroot} /bin/bash -c \
	"source /etc/profile; \
	printenv | sort; \
	repo-make -V -C /home/${builduser}/${reponame} -t /home/${builduser}/repo/${alarch}"

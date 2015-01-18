---
author: Livid
date: 2009-06-13 08:45:55+00:00
title: Kernel updater v2
wordpress_id: 320
tags: BASh, Gentoo, kernel ,BASh, Cheats, Gentoo, kernel
...

Немного допилил свой недавний скрипт. Учел предолжение в комментариях,
сделал (простую) обработку исключений, добавил лицензию, и сделал
возможность выбирать тип конфигурации (кроме oldconfig) и еще по
мелочи.

<!--more-->



```bash
#!/bin/bash

cat << EOB
Copyright (C) 2009  Nikolay "Livid" Yakimov

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see .
EOB

echo -ne '\nPress any key to continue...' && read

function exit_msg {
   echo $1
    exit 1
}

CMD="$1"
[ "$CMD" ] || CMD="oldconfig"

cd /usr/src/linux || exit_msg 'cd /usr/src/linux failed'
zcat /proc/config.gz > .config || exit_msg 'No /proc/config.gz or /usr/src/linux not writeable'
make $CMD || exit_msg "make $CMD failed"
make -j5 || exit_msg 'make failed'
make modules_install || exit_msg 'make modules_install failed'
module-rebuild rebuild || exit_msg 'module-rebuild failed'
RELEASE=`cat include/config/kernel.release` || exit_msg 'could not read kernel release version'
VERSION=`cat .version` || exit_msg 'could not read kernel build version'
MBOOT=1
mount /boot || MBOOT=0
cp arch/x86/boot/bzImage /boot/kernel-$RELEASE-$VERSION || exit_msg 'could not copy kernel image to /boot/'
cd /boot || exit_msg 'cd /boot failed'
rm vmlinuz.old || echo 'could not rm vmlinuz.old'
mv vmlinuz vmlinuz.old || echo 'could not mv vmlinuz vmlinuz.old'
ln -s kernel-$RELEASE-$VERSION vmlinuz || exit_msg 'could not symlink new kernel to vmlinuz'
cd || echo 'could not cd ~'
[ $MBOOT == 1 ] && ( umount /boot || echo 'could not umount /boot' )
echo -e 'Kernel update finished.\nYou should reboot soon for changes to take effect'
```


Молчаливо предполагается, что /boot/grub/grub.conf имеет вид

    ...
    title Gentoo Linux current
    root (hd0,0)
    kernel /boot/vmlinuz root=/dev/sda5 resume=/dev/sda6 vga=0x31b

    title Gentoo Linux previous
    root (hd0,0)
    kernel /boot/vmlinuz.old root=/dev/sda5 resume=/dev/sda6 vga=0x31b
    ...


Естественно root, resume, vga могут отличаться :)

Сам скрипт принимает один парамер, который передает в make. Молчаливо
предполагается, что он должен быть menuconfig, xconfig, oldconfig или
config.
Если он не указан, предполагается oldconfig.
Независимо от параметра, "начальный" конфиг берется из /proc/config.gz
Название ядра кодируется как kernel-VERSION-build\#. Localversion я
прицеплять поленился. Если очень надо -- свистите, я сделаю.

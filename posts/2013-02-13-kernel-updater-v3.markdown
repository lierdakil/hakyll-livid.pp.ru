---
author: Livid
date: 2013-02-13 03:17:36+00:00
title: Kernel-updater v3
wordpress_id: 592
tags: BASh, Gentoo, kernel ,BASh, Cheats, Gentoo, kernel
...

Без комментариев, под катом просто версия старого скрипта, которой я
пользуюсь сейчас. Куча опций при помощи getopt и поддержка
кросс-компиляции прилагается.

<!--more-->




```bash
#!/bin/bash

MAKECMD="oldconfig"
JOBS=5
MODULE_REBUILD=""
INITRD=""
GRUB=""
MAKEOPTS_CC=""
MAKE2CMD=""
ARCH=""
CROSS=""

usage() {
    echo "$0 [-br] [-c oldconfig] [-m make_command] [-j jobs]
    -b        automatically mount /boot
    -i        run genkernel initramfs after build
    -g      update grub2 config
    -r      run module-rebuild after make install
    -c oldconfig  path to copy configuration from, default none
    -m make_command   command to configure kernel: oldconfig, menuconfig, etc. default: $MAKECMD
    -j jobs      jobs to run make with, default: $JOBS
    -u make_command Run make_command after oldconfig
    -a arch     Arch to build (e.g. x86_64, needs -x)
    -x cross-compiler E.g. x86_64-pc-linux-gnu-
    "
 exit 1
}

cd /usr/src/linux

while getopts "c:m:j:brhu:a:x:gi" OPTCHR; do
  case "$OPTCHR" in
      c)
         CATCMD=""
          case "${OPTARG##*.}" in
                gz) CATCMD="zcat";;
                xz) CATCMD="xzcat";;
               bz2) CATCMD="bzcat";;
              *) CATCMD="cat";;
          esac
           $CATCMD "$OPTARG" > .config || exit 1
          ;;
     m) MAKECMD="$OPTARG" ;;
        j) JOBS=$OPTARG;;
      b) mount /boot || exit 1;;
     r) MODULE_REBUILD="rebuild" ;;
     i) INITRD="y" ;;
       g) GRUB="y" ;;
     u) MAKE2CMD="$OPTARG";;
        a) ARCH="ARCH=$OPTARG";;
       x) CROSS="CROSS_COMPILE=$OPTARG";;
     *) usage ;;
    esac
done

if ! [ -f .config ]; then
   echo "No .config" 
 exit 1
fi

make $ARCH $MAKECMD || exit 1
[ -n "$MAKE2CMD" ] && ( make $ARCH $MAKE2CMD || exit 1 )
make $ARCH $CROSS $MAKEOPTS_CC -j${JOBS} || exit 1
make $ARCH $CROSS modules_install || exit 1
make $ARCH $CROSS install || exit 1

[ -n "$MODULE_REBUILD" ] && module-rebuild $MODULE_REBUILD

[ -n "$INITRD" ] && genkernel initramfs
[ -n "$GRUB" ] && grub2-mkconfig > /boot/grub2/grub.cfg
```



Рекомендуется вместе с alias, например

```bash
alias newkernel='kernel-update -b -r -i -g -c /proc/config.gz -a x86_64 -x "x86_64-pc-linux-gnu-"'
```

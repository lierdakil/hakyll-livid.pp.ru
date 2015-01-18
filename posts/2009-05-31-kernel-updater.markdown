---
author: Livid
date: 2009-05-31 19:49:07+00:00
title: Kernel updater
wordpress_id: 316
tags: BASh, Gentoo, kernel ,BASh, Cheats, Gentoo, kernel
...

Сегодня по синку опять прилетел апдейт для ядра. И что-то мне так уже
надоело выполнять одну и ту же последовательность действий руками, что я
написал скрипт, который это сделает за меня.

<!--more-->


Скрипт предполагает, что в /proc/ есть файл config.gz, то есть включены
параметры

```bash
CONFIG_IKCONFIG=y
CONFIG_IKCONFIG_PROC=y
```


А еще он считает, что новое ядро уже слинкано в /usr/src/linux.
Собственно, сам скрипт:

```bash
#!/bin/bash

cd /usr/src/linux
zcat /proc/config.gz > .config
make oldconfig
make -j5
make modules_install
module-rebuild rebuild
VERSION=`grep "Linux kernel version" .config | sed 's/# Linux kernel version: //'`
mount /boot
cp arch/x86/boot/bzImage /boot/kernel-$VERSION
```


Количество потоков make установить по вкусу (make -jn). По желанию
добавить nice.
Я еще хотел, чтобы оно само добавляло соответсвующие строки в
/boot/grub/menu.lst, но заленился. Так что это пока вручную.

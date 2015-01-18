---
author: Livid
date: 2011-03-10 18:55:20+00:00
title: Внезапно, hot-swap sata-дисков
wordpress_id: 511
tags: BASh, block, hot-plug, hot-swap, sata, scsi, sysfs ,BASh, Cheats, kernel
...

По ссылке
[http://www.linux.org.ru/...](http://www.linux.org.ru/forum/linux-hardware/5982422)
нашлись скрипты.

Кое-что поменял, но смысл не меняется от этого.

<!--more-->



remove-scsi

```bash
#! /bin/bash
#----------------------------------------------------------------------
# Description: a simple script to remove SCSI devices
# Author: Artem S. Tashkinov 
# Created at: Tue Sep 15 18:30:41 YEKST 2009
# Computer: localhost.localdomain
# System: Linux 2.6.31-k8l on i686
#
# Copyright (c) 2009 Artem S. Tashkinov  All rights reserved.
# Copyright (c) 2011 Nikolay M. "Livid" Yakimov  All lefts reserved.
#
#----------------------------------------------------------------------

strhb="hot-pluggable SCSI devices"
DEVLIST=/sys/class/scsi_disk/*/device

echo "We have found the following $strhb:"

i=0
for item in $DEVLIST; do
        i=$((i+1))
        d_id[$i]="$item"
        echo -n " $i: "
        cat "$item"/model | tr -d '\n'
        echo -n " "
        ls "$item"/block | tr '\n' ' '
        echo
done

echo -n "Please, enter a device number to remove or 0 to exit: "
read devn

if ! [ "$devn" -eq "$devn" 2> /dev/null ]; then
        echo "Error: $devn isn't a number, bye."
        exit 2
fi

if [ "$devn" -lt 1 -o "$devn" -gt $i -o "$devn" -eq 0 ]; then
        echo "No action taken, bye."
        exit
fi

echo 1 > "${d_id[$devn]}"/delete
echo "Done. Consult with dmesg to find out if the device was actually removed"
```



rescan-scsi

```bash
#! /bin/bash

SCSI=/sys/class/scsi_host
test ! -d "$SCSI" && echo "Error: cannot find $SCSI directory." && exit 1
cd "$SCSI" || exit 1

for i in *; do
        echo -n "Scanning $i ..."
        echo "- - -" > $i/scan && echo " done."
done

echo "Finished. Consult with 'dmesg' for details."
```



UPD: Для тех, кто сталкивается с этим впервые, подчеркиваю, что перед
удалением диска из системы, его стоит размонтировать, освободить из
софтрейда (хотя софтрейд неплохо сам справляется), и вообще всячески
снять с него нагрузку. Иначе это будет сродни выключению работающего
компьютера из розетки.

И еще одна общая рекомендация: при замене жесткого диска "на горячую",
без выключения машины, шлейф с данными стоит подключать и отключать
только у незапитанного харда. Никакого особого криминала в обратном
случае, просто лишний раз тормозить/раскручивать шпиндель не полезно, и
шансов угробить электронику чуть больше.

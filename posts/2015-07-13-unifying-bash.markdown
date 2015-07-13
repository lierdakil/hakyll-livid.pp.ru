---
author: Livid
published: 2015-07-13T10:45:32Z
title: Пейринг Logitech Unifying на Bash
wordpress_id: 568
tags: logitech, unifying, Cheats
...

Я уже писал про пейринг устройств Logitech Unifiying, однако прошлые мои решения требовали компиляции сишной программы. Сегодня хочу предложить решение на "чистом" Bash (и `dd`).

```bash
#!/bin/bash

grep -H 'NAME=Logitech USB Receiver' /sys/class/hidraw/hidraw?/device/uevent | cut -f1-5 -d'/' | \
while read syshr; do
	devname=`grep -H DEVNAME "$syshr/uevent" | cut -f2 -d'='`
	if [ -n "$devname" ]; then
		dd if=<(echo -en '\x10\xFF\x80\xB2\x01\x00\x00') of="/dev/$devname" && echo "Pairing mode enabled on $devname"
	fi
done
```

Скрипт пройдется по всем USB-устройствам, и включит режим пейринга на всех Unifying-приемниках, тупо скопировав "волшебную строку" при помощи dd.

---
author: Livid
date: 2009-02-17 21:36:12+00:00
title: Gparted LiveCD через Grub4DOS
wordpress_id: 239
tags: Gentoo, gparted, grub4dos, iso ,Cheats, Gentoo
...

Всякие [проблемы с ICQ](/posts/2009-01-21-icq.html) как-то совершенно
затмили для меня тот факт, что я грозился сказать пару слов о сабже.
Так вот, основное уже сказано в прошлом [посте по
теме](/posts/2009-01-18-%D0%B7%D0%B0%D0%B3%D1%80%D1%83%D0%B7%D0%BA%D0%B0-gentoo-live-cd-%D0%B8%D0%B7-iso-%D0%BF%D1%80%D0%B8-%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D0%B8-grub4dos.html). Хитрость заключается в том, что init
пытается примонтировать cdrom к /newroot/mnt/cdrom (newroot - это
tmpfs-chroot окружение), и, когда у него это не получается, вываливается
в отладочный шелл. Естественно, дальше все банально просто:

```bash
mkdir /newroot/mnt/flash && mount /dev/sdb1 /newroot/mnt/flash
mount -o loop /newroot/mnt/flash/iso/gparted-livecd-0.3.4-9.iso /newroot/mnt/cdrom
```


Собственно, дальше он грузится как с компакт-диска.

---
author: Livid
date: 2009-01-18 02:44:34+00:00
title: Загрузка Gentoo Live CD из ISO при помощи grub4dos
wordpress_id: 221
tags: Gentoo, grub4dos, iso ,Cheats, Gentoo
...

Это, на самом деле, развлечение для настоящих джедаев, зато весело)
Для загрузки я использовал USB Stick Kingston DataTraveler 16G.
Grub4Dos можно скачать (а заодно и узнать о нем побольше) здесь:
<http://grub4dos.sourceforge.net/>
Понадобятся:

-   livecd/minimal-образ gentoo 2008.0 или позже
-   usb flash
-   grub4dos



<!--more-->


Итак, для начала нужно установить (тем или иным [способом из
вики](http://grub4dos.sourceforge.net/wiki/index.php/Grub4dos_tutorial))
Grub4Dos на нужный нам носитель. В моем случае это выглядело так:

```bash
./bootlace.com /dev/sdi
cp grldr /mount/flash/
cp menu.lst /mount/flash/menu.lst.example
```


Ничего сложного, в общем-то. Ясно, что /dev/sdi - это мой usbflash,
причем FAT32 раздел /dev/sdi1 примонтирован к /mount/flash (grub4dos
работает с FAT16, FAT32, NTFS, EXT2).
Далее, я скопировал нужные мне .iso образы в /mnt/flash/iso и сделал
menu.lst в соответствии с [руководством по загрузке
iso](http://diddy.boot-land.net/grub4dos/files/map.htm#hd32) (ссылку
можно найти в [вики](http://grub4dos.sourceforge.net/wiki/index.php))
Честно говоря, делать руками это немного лень, поэтому вот простенький
скриптик (выполняется в корне примонтированного накопителя, в моем
случае /mount/flash)

```bash
#!/bin/bash

echo "color black/cyan yellow/cyan" > menu.lst
echo "timeout 30" >> menu.lst
echo >> menu.lst

for iso in iso/*.iso ; do
  echo "title $iso" >> menu.lst
  echo "map /$iso (hd32)" >> menu.lst
    echo "map --hook" >> menu.lst
  echo "root (hd32)" >> menu.lst
 echo "chainloader" >> menu.lst
 echo >> menu.lst
done
```


Пустые строки я вставил исключительно для красоты.
В результате, получился вот такой menu.lst:

    color black/cyan yellow/cyan
    timeout 30

    title iso/gparted-livecd-0.3.4-9.iso
    map /iso/gparted-livecd-0.3.4-9.iso (hd32)
    map --hook
    root (hd32)
    chainloader

    title iso/install-amd64-minimal-2008.0.iso
    map /iso/install-amd64-minimal-2008.0.iso (hd32)
    map --hook
    root (hd32)
    chainloader

    title iso/install-x86-minimal-2008.0.iso
    map /iso/install-x86-minimal-2008.0.iso (hd32)
    map --hook
    root (hd32)
    chainloader


Дальнейшие шаманства начинаются уже после загрузки основного загрузчика,
короче говоря, можно брать полученный usbflash и вставлять его в целевую
машину.

При загрузке появится стандартное меню типа Grub, в котором,
естественно, нужно выбрать желаемый iso-образ. Для определенности, пусть
это будет install-x86-minimal-2008.0.iso
После нажатия [Enter] появится приглашение выбрать ядро для загрузки
(стандартное приглашение gentoo livecd). Нужно запустить ядро с
параметрами:

    debug cdroot=/dev/loop0


Например,

    gentoo cdroot=/dev/loop0 debug


Пара слов, зачем это делается: параметр debug, помимо вывода большого
количества довольно подробной информации о загрузке, которая нужна
крайне редко, запускает отладочный шелл (ash), аккурат перед началом
заполнения tmpfs-ового root'a, или, если угодно, перед монтированием
cdrom'a, что дает возможность настроить /dev/loop0 на нужный образ. В
свете вышеизложенного, совершенно ясно, что делает cdroot=/dev/loop0:
говорит init, что cdrom надо искать на /dev/loop0
После того, как установка запустит отладочную консоль, нужно
примонтировать наш usbflash-накопитель, скажем, на /root или /temp (обе
папки не используются), или на вновьсозданную, и направить /dev/loop0 на
iso/install-x86-minimal-2008.0.iso:

```bash
mkdir /flash && mount /dev/sdb1 /flash
losetup /dev/loop0 /flash/iso/install-x86-minimal-2008.0.iso
```


После этого можно с чистой совестью нажать Ctrl-D, и система начнет
загружаться во вполне штатном режиме.
Если вызвать reboot или halt, то система будет ругаться на невозможность
отмонтировать loop0, однако этот факт можно с чистой совестью
игнорировать.
В следующий раз расскажу, как запускать gparted-livecd-0.3.4-9.iso
(более новые версии не пробовал). Делается это вполне аналогично с той
разницей, что аналогичный отладочный шелл запускается при ошибке, и
мудрить с параметрами ядра не приходится. (учитывая то, что gparted
livecd основан на gentoo, аналогичность нисколько не удивляет)

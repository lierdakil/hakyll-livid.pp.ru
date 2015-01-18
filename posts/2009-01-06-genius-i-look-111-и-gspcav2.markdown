---
author: Livid
date: 2009-01-06 20:31:59+00:00
title: Genius i-Look 111 и gspcav2
wordpress_id: 214
tags: Gentoo, iLook, kernel, webcam ,Gentoo, kernel, Железо, patch
...

Решил я, что негоже пользоваться deprecated системой (gspcav1) и надо
переходить на v4l2 и соответственно gspcav2 (которые "встроены" в
исходники ядра начиная с 2.6.27).
Но моя веб-камера, естественно, опять не прописана в устройствах, хотя
драйвер ее поддерживает.

<!--more-->


Решается, как и в случае с gspcav1 патчем. На этот раз, всего одна
строчка (ядро 2.6.28)

    --- drivers/media/video/gspca/pac207.c.orig 2009-01-05 14:55:33.000000000 +0300
    +++ drivers/media/video/gspca/pac207.c  2009-01-05 14:54:37.000000000 +0300
    @@ -535,6 +535,7 @@
        {USB_DEVICE(0x093a, 0x2470)},
      {USB_DEVICE(0x093a, 0x2471)},
      {USB_DEVICE(0x093a, 0x2472)},
    + {USB_DEVICE(0x093a, 0x2474)},
      {USB_DEVICE(0x093a, 0x2476)},
      {USB_DEVICE(0x2001, 0xf115)},
      {}


Помимо очевидной необходимости пересобирать ядро (чего многие делать
как-то не любят), есть еще одна засада: дополнительно нам нужны к тому
же userspace библиотеки (по крайней мере, для всех gspca-based камер), в
портеже называемые libv4l.

```bash
emerge -a libv4l
```


Так вот, чтобы все работало, нужно иметь в переменной окружения
LD\_PRELOAD библиотеку v4l2convert.so из пакета libv4l.
Можно запускать нужные приложения с

```bash
LD_PRELOAD=/usr/lib/libv4l/v4l2convert.so myapp
```


Можно добавить соответствующий файл в env.d и выполнить env-update.
Я предпочел второе:

```bash
$ cat /etc/env.d/90libv4l
LD_PRELOAD="/usr/lib/libv4l/v4l2convert.so"
```

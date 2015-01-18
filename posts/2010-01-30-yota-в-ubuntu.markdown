---
author: Livid
date: 2010-01-30 15:19:21+00:00
title: Yota в Ubuntu
wordpress_id: 484
tags: i2400m, Intel, iwl5050, MSI, Ubuntu, Wi-Fi, WiMax, Wind U120, Yota ,MSI Wind u120, Ubuntu, Wi-Fi, Ноутбуки, Сеть, patch
...

Недавно приобрел себе игрушку -- MSI Wind U120. Дешевый и
непритязательный, батарейка дохлая, АТОМ тормозной, как смертный грех,
но мне много не надо чтобы книжки читать в кровати и в дороге.
Так вот, на этом девайсе есть поддержка WiMAXа, и я, естественно, тут же
ринулся ее настраивать.

<!--more-->


В качестве системы на девайс я вкатил ubuntu netbook remix на базе 9.10,
дабы не заморачиваться с кросс-компиляцией в Gentoo (ясно, что собирать
на тормозном атоме много не насобираешь), поэтому инструкции и файлы для
нее.

Итак, во-первых, в ядре с 2.6.29 есть WiMAX-стек, что спасает от
необходимости патчить ядро/собирать сторонние модули. Тем не менее,
суппликанта и набора утилит по умолчанию в системе не наблюдается, их
придется брать отсюда:
<http://linuxwimax.org/Download>
Конкретно нас интересуют WiMAX Network Service и Intel WiMAX Binary
Supplicant.

И то, и другое, как водится, нужно скачать и распаковать. При сборке из
исходников понадобятся заголовки libnl (то есть, пакет libnl-dev).
Подробная инструкция по сборке и установке несколько выходит за рамки
заметки, поэтому отсылаю либо к первоисточнику, либо к ссылкам в конце
статьи. Для ленивых к посту прицеплены deb-пакеты, ебилды для любопытных
можно найти в [соответствующем
баге](http://bugs.gentoo.org/show_bug.cgi?id=299683)

Дабы включить поддержку йоты, в интернетах старательно рекомендуют
использовать специальные файлы настроек (прилагаются вместе со скриптом
инсталляции, см. в конце статьи), однако у меня все, вроде как, работает
и без них.

После, собственно, установки всего упомянутого, добиться желаемого
(включения/выключения вимакса) можно следующим образом:

```bash
./start.sh
#!/bin/bash
modprobe -r iwlagn #Turn off Wi-Fi
wimaxcu ron #Turn WiMax on
wimaxll-wait-for-state-change wmx0
wimaxcu connect network 15 #Yota
```



```bash
./stop.sh
#!/bin/bash
ifconfig wmx0 down #Stop interface
wimaxcu dconnect #Disconnect network
wimaxcu roff  #Turn WiMAX off
modprobe iwlagn #Turn Wi-Fi on
```


После старта я еще руками запускаю поключение wmx0 в Network-Manager,
дабы он получил адрес по dhcp. Можно из стартового скрипта в конце
делать dhclient wmx0

Ну, и в заключение, приложния.
[Intel Wimax Binary Supplicant 1.4.0 i386
deb](http://404.livid.pp.ru/wimax/intel-wimax-binary-supplicant_1.4.0-1_i386.deb)
[Wimax Network Service 1.4.0 i386
deb](http://404.livid.pp.ru/wimax/wimax-network-service_1.4.0-1_i386.deb)
[Yota Config](http://404.livid.pp.ru/wimax/yota-config.tar.bz2)
[start-stop
scripts](http://404.livid.pp.ru/wimax/start-stop-scripts.tar.bz2)

И ссылки по теме:
[Статья на хабре](http://habrahabr.ru/blogs/linux/66879/)
[comnote.blogspot.com/..ubuntu-910-yota-wimax-vs.html](http://comnote.blogspot.com/2009/11/ubuntu-910-yota-wimax-vs.html)

P.S. Для любопытствующих еще добавлю, что при сборке WiMAX Network
Service правильная строка для configure будет выглядеть так:

    ./configure --prefix=/usr --with-i2400m=/usr/src/linux-headers-$(uname -r) --localstatedir=/var --sysconfdir=/etc

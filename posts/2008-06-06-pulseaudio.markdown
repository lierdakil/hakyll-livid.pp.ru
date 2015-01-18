---
author: Livid
date: 2008-06-06 20:51:51+00:00
title: PulseAudio
wordpress_id: 8
tags: Debian, PulseAudio ,Debian, Звук
...

В первом сообщении я заикнулся об этой системке, однако собрался немного
осветить вопрос только сейчас. В настройке под Ubuntu есть некоторые
тонкости, которые не освещены о [официальном
руководстве](http://www.pulseaudio.org/wiki/PerfectSetup).
Преимущественно о них и пойдет речь.


<!--more-->



Во-первых, пакеты:

Необходимые: pulseaudio (meta-package)
Если нужна работа в приложениях, работающих с Alsa, так же
libasound2-plugins
Для прямой работы с gdm, gnome и тп: libpulse-mainloop-glib0

После установки вышеозначенных пакетов, следует подправить
/etc/default/pulseaudio
Во-первых, обязательно
PULSEAUDIO\_SYSTEM\_START=1
иначе сервер вообще не будет грузиться. По необходимости, можно
поставить
DISALLOW\_MODULE\_LOADING=0

Для локального проигрывания этого должно быть вполне достаточно. Чтобы
запустить сервер pulseaudio, достаточно выполнить
\$ sudo /etc/init.d/pulseaudio start
Ссылки в rc.d уже созданы на этапе установки, поэтому можно и
перезагрузиться.

Теперь, чтобы alsalib проигрывал звук через pulseaudio, нужно создать
файл /etc/asound.conf следующего содержания:

    pcm.!default {
        type pulse
    }
    ctl.!default {
        type pulse
    }


Или, если нужен выбор, то

    pcm.pulse {
         type pulse
    }
    ctl.pulse {
        type pulse
    }


(это создаст виртуальное устройство pulse, вывод через которое можно
будет задать)

Так же, если нужна работа через tcp (сетевой звук, ради которого, в
основном, и стоит ставить pulseaudio), придется подправить
/etc/pulse/default.pa, конкретно, заменить:

```bash
# load-module module-native-protocol-tcp
```


на

```bash
load-module module-native-protocol-tcp auth-ip-acl=127.0.0.0/8;192.168.0.0/16
```


192.168.0.0/16 замените на подсеть, которой разрешено использовать
данный сервер pulseaudio.
Естественно, можно дописать еще несколько подсетей через точку с
запятой.

Если вы не ставили libpulse-mainloop-glib0, то вопрос можно решить и
иначе: в файле/etc/pulse/client.conf прописать:

    default-server = localhost


Этот трюк часто очень здорово помогает, поскольку
libpulse-mainloop-glib0 работает почему-то далеко не всегда.

За дельнейшей информацией отсылаю к
<http://www.pulseaudio.org/wiki/PerfectSetup> . Там, правда, все на
английском, но в целом смысл можно уловить, даже не зная языка.

В частности, чтобы звук работал с flash player 9, нужно доставить модуль
libflashsupport.

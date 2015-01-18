---
author: Livid
date: 2013-02-06 10:05:21+00:00
title: Переключение звуковухи в PulseAudio
wordpress_id: 586
tags: BASh, PulseAudio, Звук ,BASh, Cheats, Звук
...

Иногда бывает нужно перенести все источники звука на другой синк
(например потому что у Вас usb-наущники), а делать это руками лень и
зачем™. В Gnome 2, мне доложили, микшер позволял это делать, но
пользователем других окружений, видимо придется довольствоваться
"наколеночными" решениями. Хочу предложить свое.

<!--more-->



```bash
#!/bin/bash

sinks=`pacmd list-sinks | sed -rn 's/\s*name: <([^>]+)>/\1/p' | grep -v combined`
nowsink=`pacmd list-sinks | sed -rn '/\s*\* index:/ {n; s/\s*name: <([^>]+)>/\1/p}'`

INPUTS=`pacmd list-sink-inputs | sed -rn '/^\s*index/ s/.*: (.*)/\1/p'`

if [ "$1" == "-g" ]; then
    newsink=`echo -e "$sinks" | sed 'a \ ""' | xargs Xdialog --menubox 'Choose output' 10 100 3 2>&1`
elif [ "$#" -eq 0 ]; then
    newsink=`echo -e "$sinks\n$sinks" | sed -n "/$nowsink/ { n ; p ; q }"`
else
    newsink=$1
fi

for i in $INPUTS; do
    echo pacmd move-sink-input $i $newsink
    pacmd move-sink-input $i $newsink
done
echo pacmd set-default-sink $newsink
pacmd set-default-sink $newsink
```



Скрипт без параметров переключает на следующую звуковую по списку (кроме
combined), либо принимает 1 параметр -- номер/название sink, либо
параметр -g и отображает графическое меню (при помощи Xdialog) выбора
синка.

Вызов без параметров удобно повесить на хоткей.

Скрипт довольно жестко привязан к формату вывода pacmd, поэтому может
вдруг не работать на каких-то версиях пульса. У меня сейчас 3.0, но c
2.9х он тоже работал.

И да, я тут злоупотребляю sed-ом. Все это можно было сделать гораздо
аккуратнее. Но просто лень и зачем™.

UPD. Конечно же устанавливать умолчальный синк надо один раз, тут я
конечно ошибся.

---
title: EDID override
published: 2023-07-15T18:00:30Z
tags: Kernel, EDID, Xorg
---

Понадобилось использовать кабель подлиннее для монитора, но внезапно оказалось
что через него не пролезает i2c, хотя с картинкой всё ок. Сначала я хотел просто
написать modeline в конфиг xorg, но консоль в разрешении 640х480 выглядит не
очень. Проблема решается оверрайдом EDID.

<!--more-->

Идея в конечном итоге довольно простая: подключить монитор нормальным кабелем,
сдампить EDID, подсунуть его ядру. Технически можно было бы написать EDID
руками, но зачем.

Итак, ядро делает бинарники доступными по пути `/sys/class/drm/*/edid`.
Конкретно в моём случае `/sys/class/drm/card0-DP-1/edid`. Порт можно выяснить
глянув на вывод `xrandr` (но соответствие не один к одному, скажем в `xrandr` у
меня этот порт называется `DP1`).

Сохраним сразу в `/lib/firmware/edid/` (потому что, забегая вперёд, ядро его
будет там искать):

```bash
$ cat /sys/class/drm/card0-DP-1/edid > /lib/firmware/edid/my-monitor-edid.bin
```

название файла произвольное.

Неплохо ещё проверить что сдампили что-то вменяемое: для этого можно воспользоваться утилитой `parse-edid`:

```bash
$ parse-edid < /lib/firmware/edid/my-monitor-edid.bin
Checksum Correct

Section "Monitor"
  ...
EndSection
```

Обращаю внимание, что `parse-edid` читает только с stdin, передать имя файла
аргументом не получится.

Теперь можно скормить этот файл ядру. Для этого у нас есть два варианта:

1. После загрузки можно записать его в
   `/sys/kernel/debug/dri/<card>/<port>/edid_override`, где `<card>` номер карты
   (у меня `0`), а `<port>` название порта в ядре (у меня `DP-1`). Это,
   естественно, будет работать до первой перезагрузки, но для быстрого теста
   вполне вариант.

2. При загрузке указать парамер ядра
   `drm.edid_firmware=<port>:edid/my-monitor-edid.bin`, где `<port>` это
   название порта в ядре (у меня `DP-1`). Чтобы это работало нужно соблюсти два
   условия. Во-первых, файл должен существовать и находиться в `/lib/firmware`,
   а если используется initrd, то файл должен быть в нём. Во-вторых, ядро должно
   быть собрано с параметром `CONFIG_DRM_LOAD_EDID_FIRMWARE=y`. Параметр этот,
   надо отметить, у меня по умолчанию установлен не был.

У меня загрузчик grub, поэтому я дописываю
`drm.edid_firmware=DP-1:edid/my-monitor-edid.bin` в конец
`GRUB_CMDLINE_LINUX_DEFAULT` (или `GRUB_CMDLINE_LINUX`) в `/etc/defaults/grub`,
делаю обычный ритуал с `grub-mkconfig` и собственно всё, остаётся
перезагрузиться.

Initrd у меня собирается dracut-ом, который автоматом включает содержимое
`/lib/firmware`. Как дела обстоят с другими системами не берусь утверждать, но
подозреваю что аналогично. Поскольку мне всё равно пришлось пересобирать ядро чтобы включить `CONFIG_DRM_LOAD_EDID_FIRMWARE`, задоно и initrd пересобрал.

Заметка больше для себя, но вдруг кому пригодится.

P.S. Если "хорошего" EDID взять негде, придётся собирать руками. Для этого есть
<https://sourceforge.net/projects/wxedid/>, или, как вариант, более старый
<https://github.com/akatrevorjay/edid-generator>. Последний по идее генерирует
edid из modeline, который в свою очередь можно сгенерировать используя `cvt`.

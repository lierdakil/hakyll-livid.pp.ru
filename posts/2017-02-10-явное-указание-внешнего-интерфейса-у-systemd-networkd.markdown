---
title: "Явное указание внешнего интерфейса у systemd-networkd-wait-online"
published: 2017-02-10T19:29:35Z
tags: systemd, net, systemd-networkd
---

## Проблема

При нестандартной конфигурации сети, `systemd-networkd-wait-online` отваливается с таймаутом.

В логах при этом можно найти что-то такое:

```
systemd-networkd-wait-online[...]: Event loop failed: Connection timed out
```

Само собой, сервисы, зависящие от `systemd-networkd-wait-online`, не стартуюут.

## Решение

Решение ситуации -- явно указать внешний интерфейс, который должен быть поднят чтобы считать сеть рабочей. Сделать это можно, например, создав файлик `/etc/systemd/system/systemd-networkd-wait-online.service.d/exec.conf` следующего содержания:

```ini
[Service]
ExecStart=
ExecStart=/usr/lib/systemd/systemd-networkd-wait-online -i <interface-name>
```

Вместо `<interface-name>` следует вставить название интерфейса, например, `br0`.

Заодно это решает проблемы на системах с несколькими сетевыми интерфейсами, когда только один из них можно считать "основным", и если он не поднялся -- сети еще, в широком смысле слова, нет.

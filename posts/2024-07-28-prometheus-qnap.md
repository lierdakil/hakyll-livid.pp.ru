---
title: Prometheus exporter на QNAP
published: 2024-07-28T14:28:02Z
tags: prometheus, quap, monitoring, docker
---

На днях _внезапно_ развалился рейд (никогда такого не было и вот опять). Как
оказалось, почта от smartd перестала ходить, но естественно я этого не заметил.

Решил что хватит, надо наконец-таки сделать нормальный мониторинг. Как
настраивать prometheus и grafana в интернете много написано, я не буду
повторяться. Замечу только что в gentoo нет loki, технически он есть в оверлеях,
но и там promtail собирается без поддержки journald (да, у меня gentoo с
systemd, ну вот так). Поэтому пришлось ручками^[На самом деле я просто
скопировал бинарник из официального docker-образа и написал простенький systemd
сервис. Писать ебилд для loki и разбираться с приколами Go ради одного бинарника
совсем не хотелось.].

Но в общем заметка не об этом. Заметка о том, что если уж делать мониторинг, то
надо мониторить всё подряд. В том числе QNAP-овский NAS на arm7. Подробности под
катом.

<!--more-->

Итак, "родных" экспортеров прометея на QNAP нет. Поэтому есть несколько опций:

- Включить на NAS SNMP и гонять где-то snmp_exporter (да хоть на нём же). Эту
  опцию я отбросил, так как много возни с настройкой snmp_exporter и подозреваю
  метрики ни с одним моим дашбордом в графане работать из коробки не будут.
- Извернуться и запустить на NAS сторонний бинарник который будет работать как
  экспортер прометея, [напирмер
  qnapexporter](https://github.com/pedropombeiro/qnapexporter). Отброшено по
  аналогичным причинам: с моими дашбордами из коробки оно работать не будет.
- Запустить в privileged docker контейнерах по крайней мере node_exporter и
  smartctl_exporter. Я выбрал эту, она казалась самой простой. Но всё сложнее,
  чем казалось...

Для начала, node_exporter. Вроде бы всё просто, на [странице
проекта](https://github.com/prometheus/node_exporter?tab=readme-ov-file#docker) даже описано как запустить его в докере:

```
docker run -d \
  --net="host" \
  --pid="host" \
  -v "/:/host:ro,rslave" \
  quay.io/prometheus/node-exporter:latest \
  --path.rootfs=/host
```

Но не тут-то было, в Web UI примонтировать `/` в контейнер нельзя! Да и опцию
`--pid` тоже не передать.

Однако, решение есть. QNAP поддерживает удалённый доступ к докеру, только эта
опция запрятана в не самом очевидном месте.

Итак, открываем Container Station, идём там в Preferences на вкладку Certificates.

![Вкладка Certificates в Container Station
Preferences](/images/qnap-container-station-preferences.png)

Следуем инструкциям, там описанным. Имя хоста в `DOCKER_HOST` не обязательно
совпадает с тем, что в сертификате. Может потребоваться немного поиграться с
domain name или /etc/hosts на хосте с которого будет запускаться докер.

По большому счёту всё сводится к тому чтобы скопировать сертификаты и установить
переменные окружения. После этого `docker` будет работать с удалённым демоном.

Ура, теперь можно выполнить команду для запуска node_exporter и оно даже будет
работать.

Увы, та же стратегия с smartctl_exporter не прокатывает, потому что у
официального образа есть только версия под amd64^[Ну, технически у v0.7 есть
сборка под arm7, но ей уже почти 2 года на момент написания]. Но поскольку у нас
уже есть практически прямой доступ к докеру на NAS, ничто не мешает просто его
собрать.

Ну, "собрать" в смысле просто сделать образ в котором есть smartctl и smartctl_exporter. На alpine на момент написания это достигается следующим файлом:

```dockerfile
FROM arm32v7/alpine:3

RUN apk add smartmontools
RUN apk add prometheus-smartctl-exporter --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/

EXPOSE      9633
ENTRYPOINT  [ "/usr/bin/smartctl-exporter" ]
```

Это работает, в смысле запускается, находит диски и экспортирует метрики. Но
есть один нюанс: smartctl на все диски репортит что lacks SMART capability.

Оказывается, он просто автоматом угадывает неправильный набор команд.
Принудительное указание `-d sat` помогает, но smartctl-exporter не позволяет
передать ключи в smartctl. Поэтому, решаем проблему добавлением wrapper-скрипта:


```dockerfile
FROM arm32v7/alpine:3

RUN apk add smartmontools
RUN apk add prometheus-smartctl-exporter --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/

# это собственно wrapper-скрипт
RUN mkdir -p /usr/local/sbin \
  && echo -e '#!/bin/sh\n/usr/sbin/smartctl -d sat "$@"' > /usr/local/sbin/smartctl \
  && chmod +x /usr/local/sbin/smartctl

EXPOSE      9633
ENTRYPOINT  [ "/usr/bin/smartctl-exporter" ]
# а здесь мы говорим smartctl-exporter использовать скрипт
# вместо, собственно, smartctl
CMD [ "--smartctl.path=/usr/local/sbin/smartctl" ]

```

Пакет prometheus-smartctl-exporter есть только в edge testing. Как вариант,
можно скачать бинарник с гитхаба проекта.

Наконец, можно этот образ собрать (подразумевается удалённо подключаясь к докеру на NAS):

```
docker build path/to/dockerfile/dir -t smartctl_exporter
```

и запустить

```
docker run -d --net=host --user=root --privileged smartctl_exporter
```

Я делаю `--net=host` вместо того чтобы порты пробрасывать, как в [официальном
гайде](https://github.com/prometheus-community/smartctl_exporter?tab=readme-ov-file#example-of-running-in-docker),
но в общем дело вкуса.

По завершении этого квеста невредно сделать `docker builder prune` чтобы
почистить билд-кэши.

В результате можно получить вот такой незамысловатый, но весьма полезный дэшборд:

![Дашборд Grafana показывающий SMART status, температуру, статус mdraid и прочие
связанные метрики](/images/grafana-nas-dashboard.png)

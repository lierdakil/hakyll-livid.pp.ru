---
author: Livid
date: 2008-06-20 06:00:08+00:00
title: Atheros Wi-Fi v2
wordpress_id: 20
tags: Ubuntu, Wi-Fi, Ноутбуки ,Asus Z99L, Ubuntu, Wi-Fi, patch
...

Не так давно я [писал](/posts/2008-06-11-atheros-wi-fi.html) о проблемах с
карточками Atheros AR5007. С тех пор произошло маленькое обновление, и
есть шансы, что вскоре патчи войдут в основную ветку. Основное
обновление такое: теперь поддерживаются 64-битные системы.

Под катом находится обновленная версия с инструкцией по установке.


<!--more-->



Сперва надо отключить идуще "в комплекте" модули ядра. В Убунту для этой
цели есть утилита, доступная здесь:
Система-\>Администрирование-\>Драйвера устройств. Нужно снять отметки с
Atheros Hardware Access Layer (Hal) и Support for Atheros 802.11
wireless LAN cards.

После этого перезагрузитесь.

Поскольку мы будем собирать новый драйвер из исходных кодов, как всегда
потребуется

```bash
$ sudo apt-get install build-essential
```


Уже пропатченную версию исходников можно взять отсюда:
<http://snapshots.madwifi.org/madwifi-hal-0.10.5.6-current.tar.gz>.
Учтите, что иногда версия обновляется, так что если есть баги, можно
попробовать вытянуть снова и пересобрать.

Можно еще взять сборку из SVN, но рассказ о работе с SVN выходит за
рамки темы. SVN-архив здесь:
<https://svn.madwifi.org/madwifi/branches/madwifi-hal-0.10.5.6>

Итак, после того как вы скачали исходники, нужно их распаковать

```bash
$ tar zxf madwifi-hal-0.10.5.6-current.tar.gz
```


Cобрать

```bash
$ cd madwifi-hal-0.10.5.6-*
$ make
```


**ЗАМЕЧАНИЕ:** Если вы обновляете драйвер, то здесь следует выгрузить и
удалить старые драйвера:

```bash
$ sudo scripts/madwifi-unload
$ sudo scripts/find-madwifi-modules.sh -r `uname -r`
```


Установить

```bash
$ sudo make install
```


И загрузить

```bash
$ sudo modprobe ath_pci
```


Как показала практика, модуль ath\_pci так же следует прописать в
/etc/modules, например, так:

```bash
$ sudo bash -c "echo ath_pci >> /etc/modules"
```


P.S. Информация отчасти отсюда: <http://madwifi.org/ticket/1192> и
отсюда <http://madwifi.org/wiki/UserDocs/FirstTimeHowTo>

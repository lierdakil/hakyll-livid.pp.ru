---
author: Livid
date: 2008-06-11 12:22:27+00:00
title: Intel PRO/Wireless 3945ABG
wordpress_id: 12
tags: Ubuntu, Wi-Fi, Ноутбуки ,HP nc6320, Ubuntu, Wi-Fi, Ноутбуки
...

Я не уверен, что сейчас многое изменилось, но этот материал, возможно,
несколько устарел. На эту мысль меня навел следующий пост:

<http://linuxtechie.wordpress.com/2008/04/24/making-intel-wireless-3945abg-work-better-on-ubuntu-hardy/>

Тем не менее, опишу свои, проверенные, танцы с бубном:

Основная мысль такая: subj довольно плохо работает со стоящими в Hardy
по умолчанию драйверами iwl3945, у некоторых часто дропается соединение,
а у меня так он вообще отказывался соединяться с домашней сетью. Здесь
вашему вниманию предлагается workaround, на мой вкус вполне съедобный,
но все же workaround.


<!--more-->



Оригинал можно найти здесь:
<http://ubuntuforums.org/showthread.php?p=4612681>

Я делал следующим образом:

```bash
$ sudo bash -c "echo options iwl3945 disable_hw_scan=1 >> /etc/modprobe.d/iwl3945"
$ sudo reboot
```


После чего добавлял новый источник приложений

    deb http://apt.wicd.net hardy extras


Например так:

```bash
$ sudo bash -c "echo deb http://apt.wicd.net hardy extras >> /etc/apt/sources.list" && sudo apt-get update
```


Ставил wicd

```bash
$ sudo apt-get wicd
```


И пользовался им.

Так же можно добавить иконку статуса, поместив в автозагрузку скрипт
/opt/wicd/tray.py , хотя его полезность в общем и целом невысока.

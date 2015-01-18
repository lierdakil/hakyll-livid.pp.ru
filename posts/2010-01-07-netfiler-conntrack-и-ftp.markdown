---
author: Livid
date: 2010-01-07 19:31:45+00:00
title: Netfiler, conntrack и ftp
wordpress_id: 392
tags: conntrack, ftp, Gentoo, modules, netfilter ,Cheats, Gentoo, kernel, Сеть
...

Для тех несчастных, кто по тем или иным причинам вынужден держать ftp на
нестандартном порту, заметка: чтобы netfilter правильно отрабатывал
RELATED пакеты FTP (то бишь, чтобы пассивный режим работал) на
нестандартном порту, надо этот порт написать в параметре к модулю,
например, так:

    modprobe nf_conntrack_ftp ports=21,12345


В Gentoo это так же можно прописать в /etc/conf.d/modules:

    module_nf_conntrack_ftp_args="ports=21,12345"


дабы применялось при запуске modules, если оный врубает
nf\_conntrack\_ftp конечно.

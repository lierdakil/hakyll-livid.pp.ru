---
author: Livid
date: 2014-05-26 07:58:50+00:00
title: 'В догонку: iBFT с iSCSI и iPXE'
wordpress_id: 646
tags: Gentoo, iPXE, iSCSI, Netboot, PXE ,Gentoo, kernel
...

Оказывается, iPXE умеет сообщать системе, с какого, собственно, iSCSI
Target надо грузиться. Чтобы это все заработало с initrd, который
генерирует genkernel даже особых телодвижений предпринимать не надо,
достаточно вкомпилировать поддержку iBFT в ядро:

    CONFIG_ISCSI_IBFT_FIND=y
    CONFIG_ISCSI_IBFT=y



При этом в параметрах ядра не требуется указывать iscsi\_target,
iscsi\_address и iscsi\_initiatorname (но не забывайте про ip=dhcp), а в
скрипте загрузки, который у меня называется xx-xx-xx-xx-xx-xx.ipxe (где
xx-xx-xx-xx-xx-xx — это mac-адрес бездисковой станции в нижнем
регистре), указать

    set initiator-iqn %initiator-name%


Где initiator-name -- iqn инициатора (т.е. бездисковой станции).
Либо можно тот же параметр указать в настройках DHCP
(iscsi-initiator-iqn code 203)

Поддержка ibft появилась с версии 3.4.13 (аж в 2011 году). В
многочисленных доках оно описано чуть менее, чем никак. Понимание пришло
в результате чтения исходников genkernel'овского linuxrc

P.S. Ссылки на тему: <http://ipxe.org/cfg/initiator-iqn>
<https://blog.hartwork.org/?p=1066>

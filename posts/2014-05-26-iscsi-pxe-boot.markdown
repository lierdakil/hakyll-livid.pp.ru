---
author: Livid
date: 2014-05-26 04:57:06+00:00
title: iSCSI PXE Boot
wordpress_id: 630
tags: Gentoo, iPXE, iSCSI, Netboot, PXE ,Gentoo, kernel
...

Речь пойдет о загрузке бездисковых станций с iSCSI. Вариантов много, я
рассмотрю только один, который выбрал для себя.


<!--more-->



Итак, в программе учавствуют:

-   NAS QNAP как iscsi target и tftp-сервер
-   Роутер Mikrotik как dhcp-сервер
-   Бездисковая x86\_64 машина, которая будет грузитсья с NAS



ПО, которое понадобится:

-   iPXE
-   open-iscsi



Dhcp и tftp есть на железках, и я думаю их настройка не сильно
интересна.

Как настроить iSCSI Terget на QNAP объяснять тоже не очень интересно,
процесс достаточно прямолинеен. Как настроить iSCSI Target на
linux-хосте написана уже не одна статья. Поэтому тоже не буду об этом.
Единственное, упомяну, что data и header digest обозначают проверку всех
данных/команд на предмет порчи по пути от iSCSI-клиента к серверу пр
помощи CRC32c. На небольшой локальной сети это не очень нужно, а оверхед
есть.

Итак, имея на руках iSCSI Target (пока пустой), первым делом надо на
него поставить/перенести ОС. Для этого надо, имея на какой-то машине
open-iscsi, подключить Target.
Сперва сканируем сервер (в моем случае NAS):

    iscsiadm -m discovery -t st -p %server_ip%


получаем список вида ip,lun tgt\_name.
Выбираем нужное и вбиваем команду

    iscsiadm -m node -T %tgt_name% -l


Или, если target только один, можно ограничиться

    iscsiadm -m node -l


Это подключит все известные open-iscsi цели.
Команда

    iscsiadm -m session -P3


покажет, как называется созданное блочное устройство. Например,

    Attached scsi disk sdb     State: running



Дальнейшие действия по установке/переносу ОС никак не отличаются от
работы с обычным блочным устройством. Кто ставил gentoo из stage3,
должен справиться и с этой задачей.

Требуемая конфигурация ядра:

     Device Drivers  --->
      SCSI device support  --->
        [[*]] SCSI device support
          <*> SCSI disk support
        [[*]] SCSI low-level drivers  --->
          <M>   iSCSI Initiator over TCP/IP
        SCSI Transports  --->
          {M} iSCSI Transport Attributes
     Cryptographic options  --->
       [[*]] Cryptographic API
         <*> CRC32c CRC algorithm



Кроме этого настоятельно советую `CONFIG_IP_PNP_DHCP=y` и
`CONFIG_DEFAULT_HOSTNAME="yourhostname"`, дабы сеть поднималась при
загрузке ядра и бездисковая станция внятно рапортовала о своем имени.

Так же требуется initramfs. Призываю не мучить себя, и использовать
genkernel:

    genkernel --iscsi initramfs


Можно указать в `/etc/genkernel.conf` `iSCSI="yes"` и избавить себя от
необходимости писать `--iscsi`.

Отмечу один момент: я предлагаю ставить на подключенный по iSCSI диск
grub2, дабы облегчить в дальнейшем обновления ядра на бездисковой
системе. Но можно и держать ядро и initrd на tftp/http/etc.

Параметры ядра для загрузки:

    iscsi_target=%tgt_name% iscsi_address=%server_ip% iscsi_initiatorname=%init_name% ip=dhcp


tgt\_name известно из выдачи iscsiadm, как и IP сервера. Просьба
обратить внимание, что нужен именно IP сервера, а не доменное имя.
Поэтому сервер должен иметь статический IP.
init\_name -- имя инициатора. Должно иметь формат

    iqn.yyyy-mm.naming-authority:unique name

. Например, я использовал

    iqn.2007-11.ru.pp.livid:%hostname%-%mac%

-- не очень красиво, но сойдет.

Не забывайте про ip=dhcp чтобы включить автоконфигурацию ip в ядре.
Иначе будете ломать голову, почему же невозможно подключиться к
серверу.

Теперь про загрузку по PXE. Для этой радости нужен tftp-сервер и
правильно настроенный DHCP-сервер. Как именно настроить DHCP для работы
с PXE написнана не одна статья, поэтому не буду об этом. Про tftp вообще
говорить нечего.
Для загрузки мы будем использовать undionly.kpxe из комплекта iPXE.
Соответственно filename, который нам должен возвращать dhcp-сервер,
имеет значение undionly.kpxe. Поскольку перепрошивать карту мне не
хотелось, пришлось собирать undionly руками из исходника:

    tar jxf .../distfiles/ipxe-1.0.0_p20130925-cba22d3.tar.bz2 && cd ipxe*/src && make bin/undionly.kpxe EMBED=embed.ipxe


Делается это для того, чтобы умолчальный конфиг был встроен в загрузчик
iPXE, и загрузчик не входил в бесконечный цикл, общаясь с
dhcp-сервером.

embed.ipxe:

    #!ipxe

    dhcp
    chain ${17}/default.ipxe



Переменная \${17} берется с dhcp-сервера (опция 17, root-path). У меня
установлена пустой, ибо все на том же сервере. Но можно установить URL
или что-то еще (см. документацию iPXE).

На tftp-сервере соответственно лежит скомпиленный ранее undionly.kpxe,
default.ipxe вида

    #!ipxe

    chain ${17}/${mac:hexhyp}.ipxe


И файл xx-xx-xx-xx-xx-xx.ipxe, где xx-xx-xx-xx-xx-xx -- это mac-адрес
бездисковой станции (важно: в нижнем регистре!), вида

    #!ipxe

    sanboot iscsi:%server_ip%::::%tgt_name%



Если все сделано правильно, то бездисковая станция должна загрузить
iPXE, потом grub, потом kernel.

Пара ссылок на тему:
<http://etherboot.org/wiki/sanboot/gentoo_iscsi>
<http://ipxe.org/howto/chainloading>
[http://pubs.vmware.com/.../c\_iscsi\_naming\_conventions.html](http://pubs.vmware.com/vsphere-4-esx-vcenter/index.jsp?topic=/com.vmware.vsphere.config_iscsi.doc_41/esx_san_config/storage_area_network/c_iscsi_naming_conventions.html)
<http://xgu.ru/wiki/Iscsi>

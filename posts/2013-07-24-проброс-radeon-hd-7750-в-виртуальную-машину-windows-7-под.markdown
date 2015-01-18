---
author: Livid
date: 2013-07-24 10:18:54+00:00
title: Проброс Radeon HD 7750 в виртуальную машину Windows 7 под управлением Xen
wordpress_id: 598
tags: Gentoo, kernel, vga passthrough, Windows, xen ,Gentoo, kernel, Windows
...

Уже много копий переломано и текста понаписано
(<http://habrahabr.ru/post/149416/>, <http://habrahabr.ru/post/137327/>,
<http://forums.linuxmint.com/viewtopic.php?t=112013&f=42>), но я решил
добавить 5 копеек для полноты картины (и чтобы самому не забыть)
Карточка пробрасывается как второй видеоадаптер.

<!--more-->


Итак, понадобится xen, прямые руки, хост с двумя граф. карточками и
поддержкой IOMMU (VT-d, AMD-Vi).

Я использовал

-   app-emulation/xen-4.2.2-r1
    (-custom-cflags -debug -efi -flask -pae -xsm)
-   app-emulation/xen-tools-4.2.2-r3 (hvm qemu screen
    xend -api -custom-cflags -debug -doc -flask -ocaml -pygrub -static-libs)
-   sys-kernel/gentoo-sources-3.10.1



В качестве dom0 у нас выступает gentoo \~x86\_64, конфиг ядра касательно
XEN выглядит так:

```bash
CONFIG_XEN=y
CONFIG_XEN_DOM0=y
CONFIG_XEN_PRIVILEGED_GUEST=y
CONFIG_XEN_PVHVM=y
CONFIG_XEN_MAX_DOMAIN_MEMORY=500
CONFIG_XEN_SAVE_RESTORE=y
# CONFIG_XEN_DEBUG_FS is not set
CONFIG_PCI_XEN=y
CONFIG_XEN_PCIDEV_FRONTEND=y
CONFIG_XEN_BLKDEV_FRONTEND=y
CONFIG_XEN_BLKDEV_BACKEND=y
CONFIG_XEN_NETDEV_FRONTEND=y
CONFIG_XEN_NETDEV_BACKEND=y
CONFIG_INPUT_XEN_KBDDEV_FRONTEND=y
CONFIG_HVC_XEN=y
CONFIG_HVC_XEN_FRONTEND=y
CONFIG_XEN_FBDEV_FRONTEND=y
# Xen driver support
CONFIG_XEN_BALLOON=y
# CONFIG_XEN_SELFBALLOONING is not set
CONFIG_XEN_SCRUB_PAGES=y
CONFIG_XEN_DEV_EVTCHN=y
CONFIG_XEN_BACKEND=y
CONFIG_XENFS=y
CONFIG_XEN_COMPAT_XENFS=y
CONFIG_XEN_SYS_HYPERVISOR=y
CONFIG_XEN_XENBUS_FRONTEND=y
CONFIG_XEN_GNTDEV=m
CONFIG_XEN_GRANT_DEV_ALLOC=m
CONFIG_SWIOTLB_XEN=y
CONFIG_XEN_TMEM=m
CONFIG_XEN_PCIDEV_BACKEND=m
CONFIG_XEN_PRIVCMD=y
CONFIG_XEN_ACPI_PROCESSOR=m
CONFIG_XEN_HAVE_PVMMU=y
```


Вообще, на dom0 frontend-драйвера не нужны, но я их почему-то оставил.
Ключевым в данном случае является CONFIG\_XEN\_PCIDEV\_BACKEND, который
очень нужен для проброса.

После установки xen, если Вы пользуетесь grub2, достаточно выполнить
grub2-mkconfig \> /boot/grub2/grub.cfg, Xen автоматически подхватится.
Инструкции для grub legacy лежат в интернете. Хитрость в том, что ядро
Xen надо загружать с параметром iommu=1. Для этого, перед выполнением
grub2-mkconfig, в /etc/default/grub добавляется

```bash
GRUB_CMDLINE_XEN="iommu=1"
```



Во избежание проблем с сетью, имея net-misc/bridge-utils (ставятся по
зависимостям xen), проще всего сделать /etc/init.d/net.xenbr0 (симлинком
на /etc/init.d/net.lo), поставить его в автозагрузку вместо net.eth0 и
сделать конфиг /etc/conf.d/net примерно таким:

```bash
сonfig_xenbr0="dhcp"
brctl_xenbr0="setfd 0
sethello 10
stp off"
bridge_xenbr0="eth0"
```



Успешно запустив систему в dom0, переходим к созданию domU. Подробные
инструкции по ссылкам в начале статьи, я приведу лишь несколько
указателей.

1) Если есть желание сделать файлы образов для жестких дисков, самый
человечный способ

    fallocate -l %bytes% %filename%


2) Конфиг машины выглядит так:

```bash
#kernel = "/usr/lib/xen/boot/hvmloader"
builder='hvm'
# Memory reserved for Windows domU, in this case 4GB (adjust to your
# needs):
memory = 4096
# Name of the domU that will be created/used:
name = "win7"
vcpus=4 #Most CPUs have 4 cores / 8 threads (=vcpus). Check your CPU
# and change as needed!
#pae=1 #only for 32 bit guests - don't use for 64 bit!
acpi=1
apic=1
# Here my virtual network interfaces - see /etc/network/interfaces below:
vif = [ 'mac=00:16:3e:68:e1:01,bridge=xenbr0' ]
# vif = [ 'vifname=win7,type=ioemu,mac=00:16:3e:68:e1:01,bridge=xenbr0' ]
# I assigned a static MAC address, else it will be changed each time Windows
# boots. The address should start with 00:16:3e., the rest is up to you.
#
# Specifying the disks and Windows ISO for installation, adjust to your
# needs:
#disk = [ 'file:/home/libvirt/Windows-1.img,hda,w' , 'file:/path/to/image/windows7.iso,hdc:cdrom,r' ]
disk = [ 'file:/home/libvirt/Windows-1.img,hda,w' ]
# More disks can be added later using this same method. The path to the
# device or a file can be added. After the first comma is how the device will
# appear. hda is the first, hdb the second etc. hda will appear as IDE,
# sda will appear as SCSI or SATA. After the second comma r means read
# only and w is for write.
boot='dc'
# The above should be changed once Windows is installed: boot="c" to only
# show the Windows file system, else it may try to boot from the ISO image.
sdl=0
vnc=1
vncpasswd=''
stdvga=0
#nographic=1 #!!! only uncomment this if you are using win8 or are trying
# to get a Nvidia card to work. In my case  Nvidia Quadro 2000 - this was not
# needed.
serial='pty'
tsc_mode="default"
viridian=1
#soundhw='all' # I commented it out since its not relevant to me now.
usb=1 # This allows sharing the USB mouse/keyboard.
usbdevice='tablet' # is recommended; in conjunction with USB=1, else comment out
gfx_passthru=0
# Leaving this as 0 is how it works for me with my Quadro 2000 card.
# gfx_passthru=1 would pass through the graphics card as primary display adapter.
# You can change this later for iGPUs or nVidia if needed.
# Try it with 0 first!
pci=[ '01:00.0', '01:00.1' ]
# These values are the ones you found out using the lspci command earlier.
# I also passed through an entire USB controller for native support.
# You can use usb-devices to find out to which hub/host the keyboard/mouse
# is connected. I use a USB KVM switch to connect my keyboard/mouse to two
# USB ports residing on different hubs! One  00:1a.0  is then passed through
# to the domU.
# The following lets Windows take the local time from the dom0:
localtime=1
#To turn on pci power management globally, use (see remarks under pci=... below):
pci_power_mgmt=1
```


Ключевые моменты здесь

    pci=[ '01:00.0', '01:00.1' ]

и

    gfx_passthru=0

. В первом перечисляются pci-id граф. карточки и ее встроенной цифровой
звуковухи (для звука по HDMI/DP). Эти id можно узнать, выполнив из-под
рута lspci (sys-apps/pciutils). Так же за компанию можно пробросить
"лишний" USB-хаб. Я не стал заморачиваться и пользуюсь synergy.
3) Чтобы pci-устройства были пробрасываемы, нужно, чтобы они были
привязаны к модулю xen-pciback. Для этого можно использовать xl:

    xl pci-assignable-add '0000:01:00.0'; xl pci-assignable-add '0000:01:00.1'

. Естественно, модуль должен быть загружен перед выполнением этих
команд:

    modprobe xen-pciback




Но это все описано давно. Дальше самое интересное: при пробросе таким
образом, карточка под win7 имела статус "Код 10: Устройство не может
быть запущено", драйвера при этом в лучшем случае просто не ставятся (а
в худшем роняют виртуалку в BSOD). Два дня мучений привели меня к
интересному воркэраунду. Комментируем в конфиге строчку

    #pci=...

и загружаем машину. Когда система загружена, выполняем на хосте команду

    xl pci-attach %domU_name% %gfx_pci%

в моем случае

    xl pci-attach win7 01:00.0

. Это "на горячую" подключает карточку в виртуалку. При этом карточка
получает уже статус "Код 12: Недостаточно ресурсов для запуска
устройства", и драйвера при этом замечательно ставятся! Поставив
драйвера, выключаем виртуалку и возвращаем в конфиге строчку

    pci=...

. Загружаем машину. Ура, при загрузке Windows, vnc-экран виснет и
появляется картинка на мониторе, подключенном к проброшенной карточке.

В принципе здесь можно было бы и остановиться, но есть одно но: при
перезапуске виртуалки dom0 падает в kernel panic. Чтобы это обтанцевать,
в сценарии выключения виртуалки добавлен вызов deveject
(<http://www.withopf.com/tools/deveject/>) с соответствующими
параметрами. Инструкция по использованию есть, например, здесь:
<https://bbs.archlinux.org/viewtopic.php?id=162768&p=1> (по сути,
запустить в cmd без параметров, посмотреть id граф. карточки, добавить в
сценарий завершения работы с параметром

    -EjectId:"%PCI_ID%"

)

Итог: Пробуйте и у вас получится! Может быть.

P.S. Да, нужно стараться, чтобы с запуска хоста до проброса в виртуалку
карточку никто не трогал, это иногда критично. Мне легко, у меня в
системе просто не стоит радеоновских драйверов. В прочих случаях,
драйвер pcistub и параметр ядра

    pci-stub.ids=%devid%,...

(например pci-stub.ids=1002:6719,1002:aa80) должны помочь. devid можно
узнать по lspci -vv, например.

P.P.S. Еще одно. Из текста можно догадаться, что я пользовался тулсетом
xl, но можно и не догадаться. Так вот, у меня все заработало только при
запуске виртуалки с помощью xl create, xm не заработал.

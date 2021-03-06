---
author: Livid
title: Активация OEM Windows 7 на QEmu/libvirt
tags: Windows 7, qemu, kvm, libvirt
---

Недавно встала проблема активации OEM-лицензии Windows 7 в виртуальной машине qemu под упавлением libvirt на ноутбуке. Оказалось несколько сложнее, чем я ожидал.

<!--more-->

Суть заключается в следующем: OEM-лицензия автоматически активируется при выполнении нескольких условий:

1. В ACPI присутствует SLIC-таблица активации
2. В том названия производителя и модели совпадают в RSDT, SLIC и биосе
3. В системе установлен сертификат производителя
4. Ключ установлен в OEM-ключ производителя

Подставить SLIC-таблицу достаточно просто -- ее можно выдернуть из интерфейса sysfs, конкретно из `/sys/firmware/acpi/tables/SLIC`. Проще всего скопировать ее в файл (например `cat /sys/firmware/acpi/tables/SLIC > /path/to/SLIC.img`). Затем подсунуть ее qemu при помощи опции `-acpitable file=/path/to/SLIC.img`.

Чтобы заставить libvirt передавать эту опцию qemu, придется редактировать конфиг домена вручную. Например, запустив `virsh -c qemu:///system edit <domain_name>`. В конфиге нужно добавить в определение домена пространство имен qemu:

```diff
- <domain type='...'>
+ <domain type='...' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
```

Теперь внутри конфига домена (т.е. между `<domain>...</domain>`) можно написать:

```xml
<qemu:commandline>
  <qemu:arg value='-acpitable'/>
  <qemu:arg value='file=/path/to/SLIC.img'/>
</qemu:commandline>
```

Но это только первый этап.

Второй этап в том, чтобы скопировать поля биоса с хоста. Для этого существует куча опций smbios, но мы пойдем более простым путем: скажем libvirt брать эти поля с хоста. Делается это добавлением в раздел `os` конфига домена строчки `<smbios mode='host'/>`. Например:

```xml
<domain type='...' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  ...
  <os>
    ...
    <smbios mode='host'/>
  </os>
  ...
</domain>
```

Все это прекрасно, но есть одно но: qemu не имеет опций для установки RSDT-поля oem_id. Существует [патч][patch], который копирует это поле из SLIC (если таковая присутствует). Патч нормально накладывается на qemu 2.2.0 (правда с fuzz 2, но это ничего). Как наложить патч на qemu я думаю особо объяснять не надо. На gentoo это делается достаточно лекго, как я пояснял в [одном из прошлых постов][epatch_user]

После всего этого, ACPI и BIOS в точности повторяют "родное" устройство, поэтому система должна активироваться. Если есть возможность поставиться с родного диска производителя -- можно так и поступить, сертификат и OEM-серийник вшиты в установочиный образ. Если такой возможности нет, продолжаем читать.

Сертификаты можно найти в Интернетах, например [здесь][oem-certs]. Точно так же можно найти и OEM-ключи ([например][oem-keys]).

Проще, конечно, заранее скопировать эту информацию непосредственно из Windows. Для этого можно использовать, например, [SLIC Toolkit v3.2][slic-toolkit]. На вкладке Advanced внизу есть область `Pkey&Cert.Valid&Backup`, в котором есть кнопка `Backup` -- она-то нам и нужна.

Так или иначе получив ключ и сертификат, их нужно установить в виртуалке. В администраторской консоли (пуск → cmd.exe → запустить от имени администратора) выполним:

```bat
slmgr -ilc </path/to/certificate.XRM-MS>
slmgr -ipk <OEM-ключ производителя>
slmgr -dli
```

Последняя команда проверяет состояние лицензии. У меня вроде получилось.

P.S. Внимательный читатель мог заметить, что эта техника теоретически может быть применена для активации OEM-лицензии на оборудовании, на которое эта лицензия не распространяется. Помните, что кармические силы карают отступников от лицензионного соглашения. Автор не несет ответственности за прегрешения читателей.

Источники:

* <http://habrahabr.ru/post/247597/>
* <https://techdoors.wordpress.com/2012/09/26/activating-windows-7-oem-way/>
* <https://lists.nongnu.org/archive/html/qemu-devel/2014-04/msg00879.html>
* <https://docs.google.com/open?id=0Bxj5NEo7I3z9dWx3VndfenZBWVE>
* <http://d-fault.nl/Keys.aspx>
* <http://www.bios.net.cn/down/BIOSsggj/2009-12-04/448.html#edown>

[Патч для qemu](../files/RSDT.patch)

[patch]: https://lists.nongnu.org/archive/html/qemu-devel/2014-04/msg00879.html
[epatch_user]: ./2014-09-08-наложение-патчей-без-редактирования-ebui.html
[oem-certs]: https://docs.google.com/open?id=0Bxj5NEo7I3z9dWx3VndfenZBWVE
[oem-keys]: http://d-fault.nl/Keys.aspx
[slic-toolkit]: http://www.bios.net.cn/down/BIOSsggj/2009-12-04/448.html#edown

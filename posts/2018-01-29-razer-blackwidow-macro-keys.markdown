---
title: Макроклавиши Razer BlackWidow
published: 2018-01-29T04:43:53Z
tags: razer, blackwidow, macro, python, pyusb
---

Решил я как-то в позапрошлом году обзавестись нормальной, кошерной клавиатурой. С приятно щёлкающими механическими Cherry MX Blue. В общем купил Razer BlackWidow (2013 edition). Всё хорошо, но есть у этой клавиатуры 5 макро-клавиш, которые под Linux ну никак не заводятся, ни как макро, ни просто так. Оказывается, хитрый Razer включает их только по команде от "родного" драйвера, который, понятно, под линукс не рассчитан.

На самом деле выдрать из драйвера магическую последовательность не то чтобы сложно, но в интернетах эта последовательность ищется легко и непринуждённо, а поведение драйвера легко эмулируется скриптом на питоне. Скрипт и некоторые комментарии под катом.

<!--more-->

Скрипт написан с расчётом на Python 2 и требует библиотеку PyUSB 1.0 (или возможно новее, но на момент написание новее нет). Чтобы лишний раз не возиться с зависимостями, в листинге ниже первые две строчки написаны с расчётом на [менеджер пакетов Nix](https://nixos.org/nix/), конкретно на `nix-shell`. Если оного нет, то первую строчку стоит заменить на

```bash
#!/usr/bin/env python2
```
или
```bash
#!/usr/bin/env python
```
(в зависимости от того, как называется бинарник второго питона). Ну и конечно же, стоит поставить `pyusb`.

На момент написания достоверно известно, что скрипт работает с Python 2.7 и PyUSB 1.0.2.

Значение `USB_PRODUCT` может отличаться от модели к модели. Используйте lsusb и правьте по вкусу.

Скрипт нужно выполнять при каждом запуске.

```python
#!/usr/bin/env nix-shell
#!nix-shell -i python -p 'python2.withPackages(ps: [ ps.pyusb ])'

# Persist environment: nix-shell -p 'python2.withPackages(ps: [ ps.pyusb ])' --indirect --add-root $HOME/.config/nixpkgs/gcroots/pythonUsb

# blackwidow_enable.py
#
# Enables the M1-5 and FN keys to send scancodes on the Razer BlackWidow
# and BlackWidow Ultimate keyboards.
#
# You can use 'xev' and 'xbindkeys' to assign actions to the macro keys.
# From my experience, M1 gets mapped to XF86Tools, and M2..M5 to
# XF86Launch5..XF86Launch8. YMMV
#
# Requires the PyUSB library 1.0
#
# Designed to work with nix-shell. If you don't use Nix package manager,
# install Python 2 and PyUSB 1.0 -- pyusb-1.0.2 with Python 2.7 is known to work.
# Then change shebang (first line) to be:
#
#!/usr/bin/env python2
#
# or, if you only have Python 2,
#
#!/usr/bin/env python
#
# © 2016 Nikolay "Livid" Yakimov <root@livid.pp.ru>
# Based on code by Michael Fincham <michael@finch.am> 2012-03-05
# This code is released under the MIT license.
#
# Original code: <https://finch.am/projects/blackwidow/blackwidow_enable.py>

import sys
import usb
from usb.util import *

USB_VENDOR = 0x1532  # Razer
USB_PRODUCT = 0x011b  # BlackWidow Ultimate 2013 // try '0x011a' if it doesn't work for you.

# These values are from the USB HID 1.11 spec section 7.2.
USB_REQUEST_TYPE = build_request_type(CTRL_OUT, CTRL_TYPE_CLASS, CTRL_RECIPIENT_INTERFACE)
USB_REQUEST = 0x09  # SET_REPORT

# These values are from the manufacturer's driver.
USB_VALUE = 0x0300
USB_INDEX = 0x2
USB_INTERFACE = 2
USB_BUFFER = b"\x00\x00\x00\x00\x00\x02\x00\x04\x02\x00\x00\x00\x00\x00\
\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\
\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\
\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\
\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00"


# actual code
device = usb.core.find(idVendor=USB_VENDOR, idProduct=USB_PRODUCT)
if device is None:
    sys.stderr.write("BlackWidow not found.\n")
    sys.exit(1)

try:
    device.detach_kernel_driver(USB_INTERFACE)
except usb.USBError: #This usually means that kernel driver is already detached
    pass

result = device.ctrl_transfer(bmRequestType = USB_REQUEST_TYPE,
                              bRequest = USB_REQUEST,
                              wValue = USB_VALUE,
                              wIndex = USB_INDEX,
                              data_or_wLength = USB_BUFFER)

if result == len(USB_BUFFER):
    sys.stderr.write("Configured BlackWidow.\n")
else:
    sys.stderr.write("Configuration failed.\n")
    sys.exit(1)


```

Источники:

* Оригинальный скрипт: <https://finch.am/projects/blackwidow/blackwidow_enable.py>

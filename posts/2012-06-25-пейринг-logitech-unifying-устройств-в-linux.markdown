---
author: Livid
date: 2012-06-25 22:40:56+00:00
title: Пейринг Logitech Unifying устройств в Linux
wordpress_id: 568
tags: Compilation, Google, kernel, logitech, unifying ,Cheats, kernel, Soft, Железо
...

Смысл в том, что Logitech для своих новых радиомышей/клавиатур
использует свои особые приемники Unifying (до 5 кажется устройств может
работать с одним приемником). Но поскольку это особые логитековские
устройства, для того, чтобы привязать новую мышку к старому приемнику
нужна особая программа от Логитека. Которая есть только под win32. И
которая не заработает под Wine. Нет выхода? Есть! В гугл-группе
linux.kernel
[нашелся](https://groups.google.com/group/linux.kernel/msg/36c53d79832fc3f5)
добрый человек. Под катом программка на C, которая переводит приемник в
режим пейринга.

<!--more-->



```C
/* 
 * Copyright 2011 Benjamin Tissoires  
 * 
 * This program is free software: you can redistribute it and/or modify 
 * it under the terms of the GNU General Public License as published by 
 * the Free Software Foundation, either version 3 of the License, or 
 * (at your option) any later version. 
 * 
 * This program is distributed in the hope that it will be useful, 
 * but WITHOUT ANY WARRANTY; without even the implied warranty of 
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
 * GNU General Public License for more details. 
 * 
 * You should have received a copy of the GNU General Public License 
 * along with this program.  If not, see . 
 */ 
#include  
#include  
#include  
#include  
#include  
#include  
#include  
#define USB_VENDOR_ID_LOGITECH                  (__u32)0x046d 
#define USB_DEVICE_ID_UNIFYING_RECEIVER         (__s16)0xc52b 
#define USB_DEVICE_ID_UNIFYING_RECEIVER_2       (__s16)0xc532 
int main(int argc, char **argv) 
{ 
        int fd; 
        int res; 
        struct hidraw_devinfo info; 
        char magic_sequence[] = {0x10, 0xFF, 0x80, 0xB2, 0x01, 0x00, 0x00}; 
        if (argc == 1) { 
                errno = EINVAL; 
                perror("No hidraw device given"); 
                return 1; 
        } 
        /* Open the Device with non-blocking reads. */ 
        fd = open(argv[1], O_RDWR|O_NONBLOCK); 
        if (fd < 0) { 
                perror("Unable to open device"); 
                return 1; 
        } 
        /* Get Raw Info */ 
        res = ioctl(fd, HIDIOCGRAWINFO, &info); 
        if (res < 0) { 
                perror("error while getting info from device"); 
        } else { 
                if (info.bustype != BUS_USB || 
                    info.vendor != USB_VENDOR_ID_LOGITECH || 
                    (info.product != USB_DEVICE_ID_UNIFYING_RECEIVER && 
                     info.product != USB_DEVICE_ID_UNIFYING_RECEIVER_2)) { 
                        errno = EPERM; 
                        perror("The given device is not a Logitech " 
                                "Unifying Receiver"); 
                        return 1; 
                } 
        } 
        /* Send the magic sequence to the Device */ 
        res = write(fd, magic_sequence, sizeof(magic_sequence)); 
        if (res < 0) { 
                printf("Error: %d\n", errno); 
                perror("write"); 
        } else if (res == sizeof(magic_sequence)) { 
                printf("The receiver is ready to pair a new device.\n" 
                "Switch your device on to pair it.\n"); 
        } else { 
                errno = ENOMEM; 
                printf("write: %d were written instead of %ld.\n", res, 
                        sizeof(magic_sequence)); 
                perror("write"); 
        } 
        close(fd); 
        return 0; 
} 
```


Собирать, естественно, имея заголовки ядра linux, командой
`gcc -o unifying file.c` (где file.c -- это файл, содержащий
скопипащеный исходник выше, а unifying -- имя конечного бинарника)
Запускать из-под рута с аргументом к /dev/hidrawN, символизирующим
ПЕРВЫЙ hidraw Вашего приемника (у меня это `/dev/hidraw0`, например,
т.е. `./unifying /dev/hidraw0`).

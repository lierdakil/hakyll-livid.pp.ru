---
author: Livid
date: 2014-11-08 13:22:55+00:00
title: В догонку, OVMF и Windows 7
wordpress_id: 695
tags: Gentoo, kernel, kvm, qemu, vfio, vga passthrough, Windows, Windows 7 ,Без рубрики
...

К [предыдущему
посту](/posts/2014-11-07-%D0%BF%D0%B0%D1%80%D0%B0-%D1%81%D0%BB%D0%BE%D0%B2-%D0%BF%D1%80%D0%BE-vfio-%D0%B8-efi.html "Пара слов про VFIO и EFI"),
оказывается, ларчик открывается просто. EFI-установщик семерки
переборчиво относится к видеодрайверу, поэтому, чтобы он запустился,
нужно добавить к qemu параметр `-vga qxl`. В таком варианте установщик
отрабатывает нормально и мы получаем рабочую Windows 7 на GPT.

Источник: [Tianocore
README](https://github.com/tianocore/edk2-OvmfPkg/blob/master/README "Tianocore README")

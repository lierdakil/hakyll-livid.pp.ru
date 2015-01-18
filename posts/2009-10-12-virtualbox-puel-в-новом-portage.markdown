---
author: Livid
date: 2009-10-12 23:48:18+00:00
title: VirtualBox PUEL в новом portage
wordpress_id: 373
tags: Gentoo, portage, puel, virtualbox ,Gentoo, Soft
...

Для тех, кто еще не в курсе, и кому лень читать маны, в ответ на

    !!! The following installed packages are masked:
    - app-emulation/virtualbox-bin-3.0.8 (masked by: PUEL license(s))
    A copy of the 'PUEL' license is located at '/usr/portage/licenses/PUEL'.


нужно сделать

```bash
echo "app-emulation/virtualbox-bin PUEL" >> /etc/portage/package.license
```



И да, ИМХО так удобнее, чем каждый раз в интерактивном режиме ее
принимать, теперь можно поставить систему на апдейт и пойти спать.

/me ставит систему на апдейт и идет спать...

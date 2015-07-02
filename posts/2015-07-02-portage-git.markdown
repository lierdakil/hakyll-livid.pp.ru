---
author: Livid
title: Использование git portage
tags: gentoo, portage, git, howto
published: 2015-07-2T21:55:06Z
---

Portage в Git, что может быть прекраснее?

Нужен portage по крайней мере версии 2.2.16.

Во-первых, нужно убрать старое дерево, например `mv /usr/portage{,_bak}`.

Затем сделать `git clone https://github.com/gentoo/gentoo-portage-rsync-mirror /usr/portage`.

Теперь обновляем `/etc/portage/repo.conf/gentoo.conf`, раздел `[gentoo]`

```
[gentoo]
location = /usr/portage
sync-type = git
sync-uri = https://github.com/gentoo/gentoo-portage-rsync-mirror
auto-sync = true
```

P.S. Официальный гайд предлагает держать дерево в `/var/db/repos/gentoo`. Оставлю на усмотрение читателя, какой вариант более предпочтителен.

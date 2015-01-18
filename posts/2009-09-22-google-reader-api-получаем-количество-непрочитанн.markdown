---
author: Livid
date: 2009-09-22 21:15:08+00:00
title: 'Google Reader API: Получаем количество непрочитанных записей'
wordpress_id: 350
tags: API, BASh, Google ,BASh, Cheats
...

В общем, не мудрствуя лукаво, на правах заметки.

```bash
#!/bin/bash

USER="Username" #without "@gmail.com"
PASS="Password" #somehow, passwords containing & symbol do not work well here

FEED_ID="user/[0-9]+/state/com.google/reading-list"

SID=`curl -s https://google.com/accounts/ClientLogin -d Email="${USER}" -d Passwd="${PASS}" -d source=gReader-Curl -d service=reader | grep '^SID='`

TOKEN=`curl -s -G "https://www.google.com/reader/api/0/token" --header "Cookie:${SID}"`

COUNT=`curl -s -G 'https://www.google.com/reader/api/0/unread-count?all=true' --header "Cookie: ${SID}; T=${TOKEN}" | sed -rn 's:.*'"${FEED_ID}"'([0-9]*).*:\1: p'`

[ "x${COUNT}" == "x" ] && echo "0" || echo "${COUNT}"
```



И где почитать про API: [Unofficial Google Reader
API](http://code.google.com/p/pyrfeed/wiki/GoogleReaderAPI)

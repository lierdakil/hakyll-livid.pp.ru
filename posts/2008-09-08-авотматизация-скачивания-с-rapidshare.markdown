---
author: Livid
date: 2008-09-08 08:18:05+00:00
title: Авотматизация скачивания с Rapidshare
wordpress_id: 65
tags: Rapidshare ,BASh, Cheats, Soft
...

Еще один небольшой, но на этот раз многострочный скрипт. Его, в
принципе, тоже можно скомпоновать в одну строчку, но я поленился.
Суть скрипта в следующем: с тех пор, как на rapidshare убрали проверку
на человека и урезали скорость "простым юзерам", качать стало удобнее,
но дольше. Поэтому автоматизация в данном случае напрашивается сама
собой. Из чистого интереса, я попробовал реализовать такую автоматизацию
при помощи bash-скрипта, и, к своему удивлению, преуспел. Ниже следует,
собственно, сам скрипт и несколько пояснений.

<!--more-->



```bash
#!/bin/bash

echo -n Getting link...
LINK=`wget -q -O - $1 | grep "form id=\"ff\"" | sed -e "s/.*.*/\1/"`
echo done

echo -n Getting second link...
DLP=`wget -q -O - --post-data="dl.start=Free" $LINK`
echo done

echo -n Calculating...
COUNT=`echo $DLP | tr "\r" "\n" | grep "var c=" | sed -e "s/.*var c=\([0-9]*\);.*/\1/"`
LINK=`echo $DLP | tr "\r" "\n" | grep checked | grep document.dlf.action |  sed -e "s,^.*document\.dlf\.action=.'\([^\']*\).*$,\1,"`
echo done

echo We will begin downloading $LINK in $COUNT seconds

echo -n Waiting $COUNT seconds...
sleep $COUNT
echo done

wget $LINK
```


Такой скрипт принимает одну ссылку вида
http://www.rapidshare.com/files/12354698/File.rar
Затем ждет нужное время и скачивает файл в текущую директорию.
Для получения html и файла используется wget, для парсинга html - tr,
grep, sed.
Чтобы скачать список файлов (предположим, список находится в файле list,
а вышеприведенный скрипт называется ./rsdown), можно выполнить такой
однострочник:

```bash
while read LINK; do ./rsdown $LINK ; sleep 5 ; done < list 
```


sleep 5 здесь ждет 5 секунд, дабы rapidshare не выдал, что с вашего ip
качается файл. Предосторожность, возможно, излишняя, но в скрипте нет
обработчика ошибок, поэтому оных следует избегать всеми возможными
средствами.
Скрипт не делает ничего такого, что не делал бы человек. Разве что, не
загружает ничего лишнего.

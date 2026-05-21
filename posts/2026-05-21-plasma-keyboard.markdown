---
title: Раскладка в plasma-keyboard
published: 2026-05-21T02:55:23Z
tags: kde, plasma, touchscreen, keyboard
---

plasma-keyboard штука сравнительно новая и не очень обкатанная, но в общем я
наткнулся на небольшую проблемку: страница в настройках сломана, инструкции
как настроить руками нет нигде.

В общем убив 2 часа на мучание гугла, нашёл ответ в исходниках за 5 минут...

<!--more-->

Совсем вкратце, конфиг весь в `.config/plasmakeyboardrc`. Схема
[в исходниках](https://github.com/KDE/plasma-keyboard/blob/9058ed656178df542192ca7b2223daff32666be2/src/plasmakeyboardsettings.kcfg#L12).

TL;DR, включить нужные раскладки можно как-то так

```bash
$ cat $HOME/.config/plasmakeyboardrc
[General]
enabledLocales=en_US,ru_RU
```

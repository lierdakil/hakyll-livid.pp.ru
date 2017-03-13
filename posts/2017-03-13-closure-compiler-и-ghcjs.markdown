---
title: Closure-Compiler и ghcjs
published: 2017-03-13T19:29:35Z
tags: ghc, ghcjs, haskell, node.js, javascript, closure-compiler
---

Ghcjs оказывается иногда незаменим если хочется Хаскеля в JavaScript-окружении. Однако его выдача имеет нередко просто чудовищные размеры.

Решить (или по крайней мере уменьшить) проблему размера возможно с помощью гугловского closure-compiler. Однако в случае сборки под node.js возникает трудность: `ADVANCED_OPTIMIZATIONS` ломают названия нодовских функций. И все, привет. Есть, само собой, <https://github.com/dcodeIO/ClosureCompiler.js>, но он отмечен как outdated.

В общем, можно достичь нужного эффекта руками. Для этого следует клонировать <https://github.com/dcodeIO/node.js-closure-compiler-externs> и включить параметром `--externs` все `*.js` файлы оттуда. Вручную это, конечно, грустно. Поэтому я набросал вот такой вот скрипт:

```bash
#!/bin/bash
closure-compiler $1.jsexe/all.js --compilation_level=ADVANCED_OPTIMIZATIONS $(ls node.js-closure-compiler-externs/*.js | sed 's/^/--externs=/') --externs=$1.jsexe/all.js.externs > $1.js
```

Он, само собой, ужасен, но нужного эффекта достичь позволяет.

Замечание: гарантий, что extern'ы корректные, ни у кого нет. Поэтому что-то в каких-то случаях может ломаться совершенно случайным образом. Используйте на свой страх и риск.

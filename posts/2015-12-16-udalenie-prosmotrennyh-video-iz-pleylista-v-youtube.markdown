---
title: Удаление просмотренных видео из плейлиста в YouTube
date: 2015-12-16T21:05:19Z
---

Коротко и по делу, можно выполнить что-то такое в консоли:

```javascript
[].slice.call(
    document.getElementsByClassName("watched")
).forEach(
    function (x) { x.parentElement.parentElement.parentElement.getElementsByClassName("pl-video-edit-remove")[0].click(); }
)
```

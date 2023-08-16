---
title: Nullmailer SMTP
published: 2023-08-16T00:27:27Z
tags: SMTP, Nullmailer, Cheats, inetd, postfix
---

Перенёс postfix на новый хост, но встала проблемка -- перебивать везде ip для
отсылки почты лень и я не вспомню все, где надо, и всё сломается. Задался
вопросом, как бы схитрить, по крайней мере на некоторое время.

В качестве sendmail на хостах без postfix-а используется nullmailer. Беглый
гуглёж показал, что в интернетах говорят дескать "не умеет ваш nullmailer в
smtp, ставьте postfix", что, конечно, неправда. Или же говорят "да, nullmailer
то что надо" но не объясняют как его повесить на 25 порт от слова совсем.
Решение очевидное, но явилось мне не сразу. Подробности под катом.

<!--more-->

Итак, задача: заставить nullmailer слушать на 25-м порту по SMTP и пересылать
что он туда получит на postfix. Собственно вторая задача уже решена, nullmailer
и так собирает "системную" почту.

<details>
<summary>Для полноты описания</summary>

- `/etc/nullmailer/me` содержит FDQN имя хоста, например `localhost.localdomain`;
- `/etc/nullmailer/defaultdomain` -- имя домена по умолчанию, например `localdomain`
- `/etc/nullmailer/remotes` -- релеи для отправки почты, в простейшем случае например `mx.localdomain smtp`.

В `remotes` можно указать порт, starttls, логин и пароль, при необходимости, но
оставим эти детали за скобками.

Если вдруг `localdomain` вызывает сомнения, на постфиксе стоят (ну, должны
стоять, у меня стоят) правила, переписывающие исходящие `foo@bar.localdomain` во
что-то более осмысленное.

</details>

Nullmailer также предоставляет `/usr/sbin/sendmail`. У `sendmail` есть режим
эмуляции SMTP, включаемый флагом `-bs`. Обычно это интересно в контексте
отладки, но в нашем случае это интересно ещё и тем, что у нас есть сервер SMTP
встроенный в nullmailer, но только вот слушает он не на сокете, а на stdio.

Вызывает ассоциации, правда? inetd/xinetd как раз для этого -- взять stdio и сунуть его в сокет!

Поэтому, можно написать примитивный сервер inetd, например:

```inetd
service sendmail
{
    disable        = no
    port           = 25
    socket_type    = stream
    protocol       = tcp
    wait           = no
    user           = mail
    server         = /usr/sbin/sendmail
    server_args    = -bs
    type           = unlisted
    log_type       = SYSLOG mail info
    log_on_failure = ATTEMPT
}
```

Всяких `user` и прочие параметры править по вкусу, главное -- `port`,
`socket_type`, `protocol`, `server` и `server_args`.
Собственно, всё.

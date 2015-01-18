---
author: Livid
date: 2009-05-16 20:19:48+00:00
title: Сборка QtiPlot под Windows
wordpress_id: 297
tags: qtiplot, Windows ,Windows
...

Это, конечно, оффтопик, но собирать qtiplot под windows проходится долго
и мучительно, а это иногда бывает нужно во враждебном windows-окружении.
"С нахрапу" qtiplot не собирается, и приличных гайдов я не видел. То,
что предсталено ниже есть продукт личных проб и ошибок.

<!--more-->



Введение
========


Итак, для сборки, помимо, собственно, исходников qtiplot, и MinGW
потребуются:

-   Qt версии 4.4.0 или выше (на мой взгляд, либо 4.4.3, либо 4.5.1,
    работает и так и эдак)
-   Qwt версии 5.2.0 (я предпочитаю сборку той же версии из SVN)
-   GSL (проще всего под Win найти версию 1.8, и она вполне подойдет для
    наших прозаических нужд)
-   muParser версии 1.28
-   zlib
-   опционально libpng
-   BOOST C++ Libraries версии 1.36.0 (хотя 1.37.0 тоже работает, как
    показал эксперимент)
-   Опционально [Python 2.5](http://www.python.org/),
    [SIP](http://www.riverbankcomputing.co.uk/software/sip/download),
    [PyQt](http://www.riverbankcomputing.co.uk/software/pyqt/download)


MinGW можно (и, даже, пожалуй, стоит) поставить при помощи инсталлятора
Qt. Это и удобнее и поставится нужная версия. Хотя если MinGW уже есть,
то лцчше использовать его.
Скачать библиотеки Qt можно здесь:
<http://www.qtsoftware.com/downloads>. Рекомендую ограничиться
библиотеками.

Перед сборкой следует убедиться, что пути с qmake и mingw32-make
находиться в PATH (по умолчанию qmake ставится в C:\\Qt\\\\bin,
mingw32-make в C:\\MinGW\\bin)

Переходим к сборке компонент.

MuParser
========


Сразу оговорюсь, все исходники у меня лежат в C:\\build\\.
Соответственно все команды даются с учетом этого факта. Подставьте свой
путь при необходимости.
Скачать muparser можно здесь:
<http://sourceforge.net/project/showfiles.php?group_id=137191&package_id=150725>
Полученный архив надо распаковать (я распаковал в C:\\build)
Дальше нужно открыть командную строку (Пуск-Выполнить-cmd), и там:

    cd C:\build\muparser\build
    mingw32-make -f makefile.mingw




Qwt
===


Взять исходники Qwt 5.2.0 можно здесь:
http://sourceforge.net/project/showfiles.php?group\_id=13693&package\_id=11488
Однако, они поставляются для сборки динамичкеской библиотеки, а qtiplot
требует статической линковки. Поэтому, распаковав qwt в C:\\build,
открываем C:\\build\\qwt-5.2.0\\qwtconfig.pri
И исправляем:

        # Qt 4
        win32 {
            # On Windows you can't mix release and debug libraries.
            # The designer is built in release mode. If you like to use it
            # you need a release version. For your own application development you
            # might need a debug version. 
            # Enable debug_and_release + build_all if you want to build both.

            CONFIG           += release     # release/debug/debug_and_release
            #CONFIG           += release_and_release
            #CONFIG           += build_all
        }


на

        # Qt 4
        win32 {
            # On Windows you can't mix release and debug libraries.
            # The designer is built in release mode. If you like to use it
            # you need a release version. For your own application development you
            # might need a debug version. 
            # Enable debug_and_release + build_all if you want to build both.

            CONFIG           += debug     # release/debug/debug_and_release
            #CONFIG           += release_and_release
            #CONFIG           += build_all
        }


и

    CONFIG           += QwtDll


на

    CONFIG           -= QwtDll


После этого можно собирать:

    cd С:\build\qwt-5.2.0
    qmake -recursive && mingw32-make




zlib
====


zlib можно просто скачать, но я предпочитаю собрать. Исходники берутся с
<http://zlib.net/>
Дальше все довольно тривиально:

    cd E:\build\zlib-1.2.3
    mingw32-make -f win32\Makefile.gcc




BOOST C++
=========


Берется отсюда: <http://www.boost.org/users/history/>
Желательно взять версию 1.36.0. Распаковываем, опять же, в C:\\build.
Помимо, собственно, boost, следует так же скачать BOOST JAM отсюда:
<http://www.boost.org/users/history/>
После этого можно перейти к сборке. Нам на самом деле нужно собрать
всего две библиотеки:

    cd E:\build\boost_1_36_0
    bjam --build-dir=..\boost-build --toolset=gcc --build-type=minimal --link=static --variant=release --runtime-link=static --with-date_time --with-thread stage



GSL
===


Проще всего -- скачать:
<http://gnuwin32.sourceforge.net/packages/gsl.htm>
Нас интересует только "Developer files" (gsl-1.8-lib.zip)


QtiPlot
=======


Я не стану останавливаться на сборке libpng, а так же установке Python,
SIP, PyQt, это опционально, тривиально, и в сети полно описаний. Поэтому
переходим сразу к qtiplot.
Для начала, я не стал собирать мануалы (для них нужен еще целый ворох
программ, я решил что они ни к чему) Поэтому из файла
C:\\build\\qtiplot\\qtiplot.pro сразу убирается строка

           manual 



Далее, если мы не хотим Python, то в файле
С:\\build\\qtiplot\\qtiplot\\qtiplot.pro нужно заккоментировать строку

    SCRIPTING_LANGS += Python


(нужно добавить в начало строки решетку, да)

Если мы решаем, что нам лень собирать libpng, то следует так же
закомментировать строку

    CONFIG          += HAVE_LIBPNG



или засунуть libpng.a и заголовки в
C:\\build\\qtiplot\\3rdparty\\3rdparty\\libpng

Теперь нужно раскидать собранные ранее библиотеки по папкам в
C:\\build\\qtiplot\\3rdparty:
C:\\build\\muparser\\lib, C:\\build\\muparser\\include в папку
C:\\build\\qtiplot\\3rdparty\\muparser
C:\\build\\qwt-5.2\\lib C:\\build\\qwt-5.2\\src в папку
C:\\build\\qtiplot\\3rdparty\\qwt
gsl-1.8-lib.zip нужно распаковать в C:\\build\\qtiplot\\3rdparty\\gsl
C:\\build\\zlib-1.2.3\\libz.a в папку
C:\\build\\qtiplot\\3rdparty\\zlib

C:\\build\\boost\_1\_36\_0 нужно переименовать в
C:\\build\\qtiplot\\3rdparty\\boost\_1\_36\_0
C:\\build\\boost-build\\boost\\bin.v2\\libs\\date\_time\\build\\gcc-mingw-3.4.5\\release\\link-static\\threading-multi\\libboost\_date\_time-mgw34-mt-1\_36.lib
переименовать в
C:\\build\\qtiplot\\3rdparty\\boost\_1\_36\_0\\lib\\libboost\_date\_time-mgw34-mt.lib
C:\\build\\boost-build\\boost\\bin.v2\\libs\\thread\\build\\gcc-mingw-3.4.5\\release\\link-static\\threading-multi\\libboost\_thread-mgw34-mt-1\_36.lib
в
C:\\build\\qtiplot\\3rdparty\\boost\_1\_36\_0\\lib\\libboost\_thread-mgw34-mt.lib

Наконец, можно приступить к сборке.

    cd C:\build\qtiplot
    qmake qtiplot.pro && mingw32-make


Попытки скрипта сборки открыть python-скрипты в отсутствие python можно
игнорировать (нажатием на кнопочку cancel)

Полученный файл лежит в C:\\build\\qtiplot\\qtiplot\\qtiplot.exe
Замечания, исправления, предложения приветствуются.

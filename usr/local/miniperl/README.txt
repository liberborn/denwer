+-------------------------------------------------------------------------+
| Джентльменский набор Web-разработчика                                   |
| Версия: Денвер-3 2013-06-02                                             |
+-------------------------------------------------------------------------+
| Copyright (C) 2001-2010 Дмитрий Котеров.                                |
+-------------------------------------------------------------------------+
| Данный файл является частью комплекса программ "Денвер-3". Вы не можете |
| использовать  его в коммерческих  целях.  Никакие другие ограничения не |
| накладываются.  Если вы хотите внести изменения в исходный код,  авторы |
| будут рады получить от вас комментарии и замечания. Приятной работы!    |
+-------------------------------------------------------------------------+
| Домашняя страница: http://denwer.ru                                     |
| Контакты: http://forum.dklab.ru/denwer                                  |
+-------------------------------------------------------------------------+

This EXE was re-compiled manually in Windows XP SP2 Rus, because
else it has a problem with cp866 endocing in Windows Vista. Very,
very strange behaviour... but seems it works fine after re-compilation.
To test it, run miniperl_test.bat.

While complinig, MSVCRT.lib is got from old Visual C 6.0 distribution,
so the EXE refers to MSVCRT.DLL which is present in all systems, not
to MSVCR71.DLL! It's important. To build so, used

call "%VS71COMNTOOLS%vsvars32.bat"
set LIB=path-to-old-msvcrt.lib;%LIB%
set PCHFLAGS=-QIfist

(without -QIfist Perl does not build unfortunately).


Perl version less than 5.6 is bad, because system() contains bugs 
with ""-quoted program names.

Perl version 5.6 is bad, because in the standard distribution it
has a problem with cp866 letters in Windows Vista, and after manual
re-compilation with MSVCRT.lib it contains this bug too (if you
compile 5.6 with MSVCR71.DLL, cp866 letters are okay).

Finally, Perl version 5.8 seems to be OK: after manual re-compilation 
with forced MSVCRT.DLL it does not contain cp866 charset bug in Vista.
So, miniperl.exe from this compilation is used.

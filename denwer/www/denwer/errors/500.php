<?$TITLE = "500 Internal Server Error"; include "../_header.php"?>

The server encountered an internal error or
misconfiguration and was unable to complete
your request.<P>
Please contact the server administrator,
 <?=$_SERVER['SERVER_ADMIN']?> and inform them of the time the error occurred,
and anything you might have done that may have
caused the error.<P>
More information about this error may be available
in the server error log.<P>

<h2>Подсказка Денвера</h2>

Вероятнее всего, скрипт, который запускает данная страница, не смог корректно 
выполниться. <b>Детально причины ошибки должны быть описаны</b> в файле 
<tt><?=dirname($_SERVER['DOCUMENT_ROOT'])?>/error.log</tt>.

<p>Вот наиболее частые причины 500-й ошибки: 

<ul>
<li>В скрипте имеются ошибки. Например, каждый скрипт должен выводить заголовок <tt>Content-Type</tt> 
перед началом печати страницы. Подробнее об этом читайте в статье <a href="http://dklab.ru/chicken/nablas/3.html">Борьба с 500-й Ошибкой закончилась</a>.

<p>Корректные пути к CGI-директориям следующие:
<p><?include "_pathes.php"?>

<li>Вы не установили некоторые библиотеки, которые необходимы скрипту. 
Для Perl-скриптов: установите пакет с библиотеками Perl, который доступен 
по адресу <a href="http://dklab.ru/chicken/web/packages/perl.html">http://dklab.ru/chicken/web/packages/perl.html</a>. 
<li>Вы указали неправильную первую строчку в скрипте, по которой Apache определяет путь 
к интерпретатору. Первая строка должна быть: 

<ul>
<li>для Perl: 
<pre>
#!/usr/bin/perl -w 
</pre>
или 
<pre>
#!/usr/local/bin/perl -w 
</pre>

<li>для PHP: 
<pre>
#!/usr/bin/php 
</pre>
или 
<pre>
#!/usr/local/bin/php 
</pre>
</ul>

Здесь указывается путь относительно корня до файлов <tt>perl.exe</tt> и <tt>php.exe</tt> 
соответственно (расширение <tt>exe</tt> и буква диска опускаются для совместимости с Unix). 
Проверьте, чтобы до этой строке в скрипте ничего не было (в том числе и комментариев). 

<p>Хотя Денвер поддерживает оба варианта, заметьте также, что PHP-скрипты удобнее 
запускать из-под mod_php, встроенного в Apache, а не через внешнюю программу 
<tt>php.exe</tt>. Для использования mod_php просто поместите PHP-скрипт в www-директорию 
(а не в директорию с CGI-скриптами). 

<li>В текущей директории расположен файл <tt>.htaccess</tt> с ошибочными директивами. 
Например, Apache в Денвере не поддерживает устаревший модуль mod_charset, имеющийся у 
некоторых хостеров, и расценивает директивы вроде <tt>CharsetDisable</tt> как ошибочные. 
Для того, чтобы исправить ситуацию, отредактируйте файл <tt>.htaccess</tt>, чтобы он
выглядел примерно так:
<pre>
&lt;IfModule mod_charset.c&gt; 
  CharsetRecodeMultipartForms off 
  # и другие директивы mod_charset
&lt;/IfModule&gt;
</pre>

</ul>

<?php include "../_footer.php"?>
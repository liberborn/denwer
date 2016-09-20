<?$TITLE = "404 Not Found"; include "../_header.php"?>

The requested URL <?=$_SERVER['REDIRECT_URL']?> was not found on this server.<P>

<h2>Подсказка Денвера</h2>
<p>Вы ошиблись при наборе URL в браузере. Вероятнее всего, сервер 
пытается найти файл <tt><?=$_SERVER['DOCUMENT_ROOT']?><?=$_SERVER['REDIRECT_URL']?></tt>, 
которого не существует. 

<p>В случае использования CGI-скриптов, корректные пути к CGI-директориям следующие:

<p><?include "_pathes.php"?>

<?include "../_footer.php"?>
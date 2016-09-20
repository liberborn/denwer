<?$TITLE = "405 Method Not Allowed"; include "../_header.php"?>

The requested method POST is not allowed for the URL <?=$_SERVER['REDIRECT_URL']?>.<P>

<h2>Подсказка Денвера</h2>

Возможно, вы пытаетесь отправить данные POST-форму на страницу, которая 
не является скриптом (например, на SHTML-страницу). Проверьте путь в 
атрибуте <tt>action</tt> тэга <tt>&lt;form&gt;</tt>, инициировавшего данный 
запрос. Проверьте также, не пуст ли этот атрибут (и задан ли). 

<p>Учтите, что корректные пути к CGI-директориям следующие: 
<p><?include "_pathes.php"?>

<?include "../_footer.php"?>

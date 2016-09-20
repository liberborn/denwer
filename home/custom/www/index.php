<html>
<head><title>Нестандартный виртуальный хост</title></head>
<body>
Имя хоста: <tt><?php echo $_SERVER['SERVER_NAME']?></tt><br>
IP-адрес: <tt><?php echo $_SERVER['SERVER_ADDR']?></tt><br>
Порт: <tt><?php echo $_SERVER['SERVER_PORT']?></tt><br>
Другая ссылка (если этот хост - единственный на IP <tt><?php echo $_SERVER['SERVER_ADDR']?></tt>):
<a href="http://<?php echo $_SERVER['SERVER_ADDR']?>:<?php echo $_SERVER['SERVER_PORT']?>">http://<?php echo $_SERVER['SERVER_ADDR']?>:<?php echo $_SERVER['SERVER_PORT']?></a>

<p>Если вы хотите настроить Apache так, чтобы хост был виден из локальной сети, см. 
статью <a href="http://www.denwer.ru/faq/shared.html">Apache: сервер, видимый из Интернета</a>.

</body>
</html>
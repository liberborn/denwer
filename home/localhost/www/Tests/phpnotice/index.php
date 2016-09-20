<?
#<title>Проверка перехвата PHP Notice в Денвере</title>
##<!--order=045-->
error_reporting(E_ALL);
echo "Ниже должно быть выведено сообщение об ошибке (Notice), снабженное раскрывающейся подсказкой Денвера.<br>";
echo $non_existed_variable;
?>

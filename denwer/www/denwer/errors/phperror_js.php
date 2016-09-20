<?
#######################################################
## Do not modify this line! It is updated automatically.
$show_tip = true;
#######################################################

if (isset($_GET['never'])) {
	$f = fopen(__FILE__, "rb"); $st = fread($f, 10000); fclose($f);
	$st = preg_replace('/(\$show_tip\s*=\s*)\w+/', '$1false', $st);
	$f = fopen(__FILE__, "wb"); fwrite($f, $st); fclose($f);
	exit;
}
Header("Content-type: application/x-javascript; charset=windows-1251");
?>

function denwer_element(name)
{
	if (document.all) return document.all[name];
	if (document.getElementById) return document.getElementById(name);
	return null;
}

function denwer_showTip(on)
{
	if (!denwer_element("denwer_onPhpErrorHelp")) {
		alert("Too old browser version!");
		return false;
	}
	if (!on) {
		denwer_element("denwer_onPhpErrorHelp").style.display="none"; 
		denwer_element("denwer_onPhpErrorHref").style.display="block";
	} else {
		denwer_element("denwer_onPhpErrorHelp").style.display="block"; 
		denwer_element("denwer_onPhpErrorHref").style.display="none";
	}
	return false;
}

function denwer_delTip()
{
	if (confirm("Подсказка больше никогда не по\явитс\я. Вы уверены?")) {
		denwer_element("denwer_onPhpErrorImg").src = "<?=$_SERVER['SCRIPT_NAME']?>?never";
		denwer_element("denwer_onPhpErrorHelp").style.display="none"; 
		denwer_element("denwer_onPhpErrorHref").style.display="none";
	}
	return false;
}

function denwer_onPhpError(obj)
{
	var d = document;

	if (d.countPhpErrors) return;

	var body = '' + (document.body && document.body.innerHTML? document.body.innerHTML : '');
	var p = body.lastIndexOf("<!--error-->");
	if (!p) return;

	var isNotice = body.indexOf('>Notice</') >= 0;
	if (!isNotice) return;

	d.write("<img id=denwer_onPhpErrorImg width=1 height=1 border=0>");
	d.write('<span id=denwer_onPhpErrorHelp style="background:#FFFFE1; display:none; font-size:10pt; padding:4; width:80%; border-width:1; border-style:solid;">');
	d.write(
		"<nobr style='float:right'>[ <a href='#' onclick='denwer_showTip(0)'><b>убрать подсказку</b></a> | "+
		"<a href='#' onclick='denwer_delTip()'><b>никогда больше не показывать</b></a> ]</nobr><br>"+
		"<p>Это предупреждение, веро\ятнее всего, возникает вследствие высокого уровн\я "+
		"контрол\я ошибок в PHP, по умолчанию установленного в Денвере (<tt>E_ALL</tt>). "+
		"Такой режим вывода ошибок \явл\яетс\я рекомендуемым и сильно помогает при "+
		"отладке скриптов. Однако множество готовых скриптов требуют более низкого "+
		"уровн\я ошибок.</p> "+
		"<p>Вы можете установить более слабый контроль ошибок одним из следующих способов:</p>"+
		"<ul>"+
		"<li>Впишите в скрипты строчку: "+
			"<pre>Error_Reporting(E_ALL & ~E_NOTICE);</pre> "+
			"Этот способ особенно удобен, если в скрипте есть один файл (конфигурационный), "+
			"который подключаетс\я всеми остальными."+
		"<li><i>Рекомендуемый способ</i>. Создайте в директории со скриптом файл "+
			"<tt>.htaccess</tt> следующего содержани\я: "+ 
			"<pre>php_value error_reporting 7</pre>" +
		"<li>Исправьте в <tt>/usr/local/php/php.ini</tt> значение <tt>error_reporting</tt> "+ 
			"на <nobr><tt>E_ALL & ~E_NOTICE</tt></nobr>. Этот способ <i>не \явл\яетс\я</i> рекомендуемым "+
			"и может привести к серьезным неудобствам при отладке!"+
		"</ul>"+
		""
	);
	d.write('</span>');
	d.write("<a id=denwer_onPhpErrorHref href='#' onclick='denwer_showTip(1)'><b><font color=red>[Денвер: показать возможную причину ошибки]</font></b></a>");
	document.countPhpErrors = 1;
}

<?if (@$show_tip) {?>
	denwer_onPhpError();
<?}?>

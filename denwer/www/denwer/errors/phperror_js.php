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
	if (confirm("��������� ������ ������� �� ��\�����\�. �� �������?")) {
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
		"<nobr style='float:right'>[ <a href='#' onclick='denwer_showTip(0)'><b>������ ���������</b></a> | "+
		"<a href='#' onclick='denwer_delTip()'><b>������� ������ �� ����������</b></a> ]</nobr><br>"+
		"<p>��� ��������������, ����\����� �����, ��������� ���������� �������� �����\� "+
		"�������\� ������ � PHP, �� ��������� �������������� � ������� (<tt>E_ALL</tt>). "+
		"����� ����� ������ ������ \���\����\� ������������� � ������ �������� ��� "+
		"������� ��������. ������ ��������� ������� �������� ������� ����� ������� "+
		"�����\� ������.</p> "+
		"<p>�� ������ ���������� ����� ������ �������� ������ ����� �� ��������� ��������:</p>"+
		"<ul>"+
		"<li>������� � ������� �������: "+
			"<pre>Error_Reporting(E_ALL & ~E_NOTICE);</pre> "+
			"���� ������ �������� ������, ���� � ������� ���� ���� ���� (����������������), "+
			"������� �����������\� ����� ����������."+
		"<li><i>������������� ������</i>. �������� � ���������� �� �������� ���� "+
			"<tt>.htaccess</tt> ���������� ���������\�: "+ 
			"<pre>php_value error_reporting 7</pre>" +
		"<li>��������� � <tt>/usr/local/php/php.ini</tt> �������� <tt>error_reporting</tt> "+ 
			"�� <nobr><tt>E_ALL & ~E_NOTICE</tt></nobr>. ���� ������ <i>�� \���\����\�</i> ������������� "+
			"� ����� �������� � ��������� ����������� ��� �������!"+
		"</ul>"+
		""
	);
	d.write('</span>');
	d.write("<a id=denwer_onPhpErrorHref href='#' onclick='denwer_showTip(1)'><b><font color=red>[������: �������� ��������� ������� ������]</font></b></a>");
	document.countPhpErrors = 1;
}

<?if (@$show_tip) {?>
	denwer_onPhpError();
<?}?>

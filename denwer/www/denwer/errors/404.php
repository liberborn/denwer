<?$TITLE = "404 Not Found"; include "../_header.php"?>

The requested URL <?=$_SERVER['REDIRECT_URL']?> was not found on this server.<P>

<h2>��������� �������</h2>
<p>�� �������� ��� ������ URL � ��������. ��������� �����, ������ 
�������� ����� ���� <tt><?=$_SERVER['DOCUMENT_ROOT']?><?=$_SERVER['REDIRECT_URL']?></tt>, 
�������� �� ����������. 

<p>� ������ ������������� CGI-��������, ���������� ���� � CGI-����������� ���������:

<p><?include "_pathes.php"?>

<?include "../_footer.php"?>
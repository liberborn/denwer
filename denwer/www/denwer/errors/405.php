<?$TITLE = "405 Method Not Allowed"; include "../_header.php"?>

The requested method POST is not allowed for the URL <?=$_SERVER['REDIRECT_URL']?>.<P>

<h2>��������� �������</h2>

��������, �� ��������� ��������� ������ POST-����� �� ��������, ������� 
�� �������� �������� (��������, �� SHTML-��������). ��������� ���� � 
�������� <tt>action</tt> ���� <tt>&lt;form&gt;</tt>, ��������������� ������ 
������. ��������� �����, �� ���� �� ���� ������� (� ����� ��). 

<p>������, ��� ���������� ���� � CGI-����������� ���������: 
<p><?include "_pathes.php"?>

<?include "../_footer.php"?>

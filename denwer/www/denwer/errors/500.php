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

<h2>��������� �������</h2>

��������� �����, ������, ������� ��������� ������ ��������, �� ���� ��������� 
�����������. <b>�������� ������� ������ ������ ���� �������</b> � ����� 
<tt><?=dirname($_SERVER['DOCUMENT_ROOT'])?>/error.log</tt>.

<p>��� �������� ������ ������� 500-� ������: 

<ul>
<li>� ������� ������� ������. ��������, ������ ������ ������ �������� ��������� <tt>Content-Type</tt> 
����� ������� ������ ��������. ��������� �� ���� ������� � ������ <a href="http://dklab.ru/chicken/nablas/3.html">������ � 500-� ������� �����������</a>.

<p>���������� ���� � CGI-����������� ���������:
<p><?include "_pathes.php"?>

<li>�� �� ���������� ��������� ����������, ������� ���������� �������. 
��� Perl-��������: ���������� ����� � ������������ Perl, ������� �������� 
�� ������ <a href="http://dklab.ru/chicken/web/packages/perl.html">http://dklab.ru/chicken/web/packages/perl.html</a>. 
<li>�� ������� ������������ ������ ������� � �������, �� ������� Apache ���������� ���� 
� ��������������. ������ ������ ������ ����: 

<ul>
<li>��� Perl: 
<pre>
#!/usr/bin/perl -w 
</pre>
��� 
<pre>
#!/usr/local/bin/perl -w 
</pre>

<li>��� PHP: 
<pre>
#!/usr/bin/php 
</pre>
��� 
<pre>
#!/usr/local/bin/php 
</pre>
</ul>

����� ����������� ���� ������������ ����� �� ������ <tt>perl.exe</tt> � <tt>php.exe</tt> 
�������������� (���������� <tt>exe</tt> � ����� ����� ���������� ��� ������������� � Unix). 
���������, ����� �� ���� ������ � ������� ������ �� ���� (� ��� ����� � ������������). 

<p>���� ������ ������������ ��� ��������, �������� �����, ��� PHP-������� ������� 
��������� ��-��� mod_php, ����������� � Apache, � �� ����� ������� ��������� 
<tt>php.exe</tt>. ��� ������������� mod_php ������ ��������� PHP-������ � www-���������� 
(� �� � ���������� � CGI-���������). 

<li>� ������� ���������� ���������� ���� <tt>.htaccess</tt> � ���������� �����������. 
��������, Apache � ������� �� ������������ ���������� ������ mod_charset, ��������� � 
��������� ��������, � ����������� ��������� ����� <tt>CharsetDisable</tt> ��� ���������. 
��� ����, ����� ��������� ��������, �������������� ���� <tt>.htaccess</tt>, ����� ��
�������� �������� ���:
<pre>
&lt;IfModule mod_charset.c&gt; 
  CharsetRecodeMultipartForms off 
  # � ������ ��������� mod_charset
&lt;/IfModule&gt;
</pre>

</ul>

<?php include "../_footer.php"?>
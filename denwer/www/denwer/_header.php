<?php
$TITLE = preg_replace("/^[\s\d]+/", "", @$TITLE? $TITLE : @$_REQUEST["TITLE"]);
$USE_HEAD = @$USE_HEAD? $USE_HEAD : @$_REQUEST["USE_HEAD"];
$ISMAIN = @$ISMAIN? $ISMAIN : @$_REQUEST["ISMAIN"];
?>
<html>
<head>
  <title><?=strip_tags($TITLE)?></title>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <style type="text/css">
  <!--
    html, body { padding: 0px; margin: 0px; }
    .menu { padding: 4px 10px 4px 10px; border-bottom: 3px double #999999; background: #FFFFFF; font-size: 85%; font-weight: bold; }
    p { text-align: justify }
    h1 { font-size: 150%; }
    h2 { font-size: 130%; }
  -->
  </style>
</head>

<body bgcolor="white" text="#000000" link="#00639C" alink="#ffaa00" vlink="#00437C">

<table width="100%" height="100%" cellpadding="0" cellspacing="0" border="0">
<tr valign="top">
  <td bgcolor="#DEDFDE" width="80%" style="border-right: 1px outset">
    <?if ($USE_HEAD) {?>
      <table class="menu" width="100%" cellpadding="0" cellspacing="0" border="0">
      <tr>
        <td>
          <a href="http://localhost">localhost</a>
          |
          <a href=http://localhost/Tools/>Утилиты</a>
          |
          <a href=http://localhost/Docs/>Документация</a>
          |
          <a href=http://localhost/Test/>Тестирование</a>
        </td>
        <td align="right">
          <a href="http://www.denwer.ru">Сайт Денвера</a>
          |
          <a href="http://faq.dklab.ru/denwer/">FAQ</a>
          |
          <a href="http://www.denwer.ru/dis/">Дистрибутивы</a>
          |
          <a href="http://forum.dklab.ru/denwer/">Пишите нам!</a>
        </td>
      </tr>
      </table>
    <?}?>
    <div style="width=100%; padding: 0px 10px 4px 10px">
      <?if (@$ISMAIN) {?>
        <a href="http://www.denwer.ru"><script>
            function setCookie(name, value, path, expires, domain, secure) {
              var curCookie = name + "=" + escape(value) +
                ((expires) ? "; expires=" + expires.toGMTString() : "") +
                ((path) ? "; path=" + path : "; path=/") +
                ((domain) ? "; domain=" + domain : "") +
                ((secure) ? "; secure" : "");
              document.cookie = curCookie;
            }
            function getCookie(name) {
              var prefix = name + "=";
              var cookieStartIndex = document.cookie.indexOf(prefix);
              if(cookieStartIndex == -1) return null;
              var cookieEndIndex = document.cookie.indexOf(";", cookieStartIndex + prefix.length);
              if(cookieEndIndex == -1) cookieEndIndex = document.cookie.length;
              return unescape(document.cookie.substring(cookieStartIndex + prefix.length, cookieEndIndex));
            }
            var c = (getCookie('vc') || 0);
            setCookie('vc', parseInt(c) + 1, '/', new Date(new Date().getTime()+1000*3600*24*365*4));
            document.write('<img width="73" height="94" style="float:right; margin:10px 0px 0px 60px" border=0 src="http://www.denwer.ru/logo.gif?' + c + '" />');
        </script></a>
      <?}?>
      <h1 style="margin-top: 0.2em"><?=$TITLE?></h1>

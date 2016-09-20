<?php
@extract($_SERVER, EXTR_SKIP); @extract($_POST, EXTR_SKIP); @extract($_GET, EXTR_SKIP);
if (@$doGo) {
  do {
    if (!@mysql_connect("localhost", "root", $rootpass)) {
      $eBadRootPass = mysql_error();
      break;
    }
    SetCookie("mysqlpass", $rootpass, time()+3600*24*365*5);

    if ($db=="" || !preg_match('/^[a-z0-9_]+$/i',$db)) {
      $eBadDb = 1; break;
    }
    if ($login=="" || !preg_match('/^[a-z0-9_]+$/i',$login)) {
      $eBadUser = 1; break;
    }
    if ($password!=$password1) {
      $eBadPass = 1; break;
    }
    if (!@mysql_query("create database $db")) {
      $eDBExists = 1; break;
    }
    mysql_select_db("mysql");
    $r = @mysql_query("select * from user where user='$login'");
    if (@mysql_num_rows($r)) {
      $eUserExists=1; break;
    }
    mysql_query("insert into user values ('localhost', '$login', PASSWORD('$password'), 'N','N','N','N','N','N','N','N','N','Y','N','N','N','N')");
    mysql_query("insert into db   values ('localhost', '$db',   '$login',               'Y','Y','Y','Y','Y','Y','Y','Y','Y','Y')");
    mysql_query("flush privileges");
    $eOK = 1;
  } while(0);
}
if (!isSet($rootpass)) $rootpass=@$mysqlpass;
?>
<?$TITLE="Заведение новых БД и пользователей MySQL"; include "../../_header.php"?>

<?if(@$eOK) {?>
  <h2>База данных и новый пользователь заведены.</h2>
<?}?>

<form name=Form action=<?=$SCRIPT_NAME?> method=POST>

<table width=70% cellpadding=5 cellspacing=2>
<tr valign=top>
  <td colspan=2>
    <font size=-1>
    <p>Большинство хостинг-провайдеров при регистрации в MySQL выдают 
    пользователям доступ к персональной базе данных. При этом 
    сообщается также логин и пароль доступа. Логин чаще всего совпадает 
    с именем базы данных. Настоящий скрипт поможет вам создать
    пользователя на локальной машине и назначить ему такие же параметры, какие
    выдал вам хостинг-провайдер. Это сильно поможет при отладке Web-приложений.
    </p>
  </td>
</tr>
<tr bgcolor=EEEEEE valign=top>
  <td><nobr>Пароль администратора MySQL:</td>
  <td>
    <input type=password size=30 name=rootpass value="<?=@HtmlSpecialChars($rootpass)?>">
    <?if(@$eBadRootPass) {?>
      <br><font color=red size=2>Ошибка: <?=$eBadRootPass?>.
    <?}?>
  </td>
</tr>
<tr bgcolor=EEEEEE valign=top>
  <td>Имя базы данных:</td>
  <td>
    <input type=text size=30 name=db value="<?=@HtmlSpecialChars($db)?>">
    <?if(@$eBadDb) {?>
      <br><font color=red size=2>Ошибка: недопустимое имя базы данных.</font>
    <?}?>
    <?if(@$eDBExists) {?>
      <br><font color=red size=2>Ошибка: такая база данных уже есть.</font>
    <?}?>
  </td>
</tr>
<tr bgcolor=E5E5E5 valign=top>
  <td>Логин пользователя:</td>
  <td>
    <input type=text size=30 name=login value="<?=@HtmlSpecialChars($login)?>" onChange="chg=true;" onFocus="chg=true;">
    <?if(@$eBadUser) {?>
      <br><font color=red size=2>Ошибка: недопустимое имя пользователя.</font>
    <?}?>
    <?if(@$eUserExists) {?>
      <br><font color=red size=2>Ошибка: такой пользователь уже есть.</font>
    <?}?>
  </td>
</tr>
<tr bgcolor=EEEEEE valign=top>
  <td>Пароль:</td>
  <td><input type=password size=30 name=password value="<?=@HtmlSpecialChars($password)?>"></td>
</tr>
<tr bgcolor=E5E5E5 valign=top>
  <td>...еще раз:</td>
  <td>
    <input type=password size=30 name=password1 value="<?=@HtmlSpecialChars($password1)?>">
    <?if(@$eBadPass) {?>
      <br><font color=red size=2>Ошибка: пароли не совпадают.
    <?}?>
  </td>
</tr>
<tr bgcolor=FFFFFF valign=top>
  <td>&nbsp;</td>
  <td><input type=submit name=doGo value="Создать БД и пользователя"></td>
</tr>
<tr valign=top>
  <td colspan=2>
    <font size=-1>
    <p><b>Примечание</b>: пароль администратора MySQL по умолчанию пустой.
    </p>
  </td>
</tr>
</table>
</form>


<script language=JavaScript>
<!--
var chg=document.Form.login.value!=document.Form.db.value;
function Sync() {
  var form=document.Form;
  if(!chg) {
    form.login.value=form.db.value;
    setTimeout("Sync()",100);
  }
}
Sync();
//-->
</script>

<?include "../../_footer.php"?>

<?include "_lib.php"?>
<table width="100%" border="1" cellspacing="2" cellpadding="4">
<tr bgcolor="silver">
  <td><b>URL</b></td>
  <td><b>ќписание</b></td>
</tr>
<?$Colors=array("#f8f8f8","#f0f0f0"); $n=0?>
<?foreach(getAllTests() as $e) {?>
  <tr valign="top" bgcolor="<?=$Colors[($n++)%2]?>">
    <td>
      <a href="<?=$e['url']?>"><?=$e['url']?></a>
    </td>
    <td>
      <font size="-1"><?=$e['title']?>
      <?if (isset($e['comment'])) {?>
        <br /><i style="color: red"><?=$e['comment']?></i>
      <?}?>
      </font>
    </td>
  </tr>
<?}?>
</table>
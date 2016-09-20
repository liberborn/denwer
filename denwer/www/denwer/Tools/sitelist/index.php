<?$TITLE="Список зарегистрированных сайтов"; include "../../_header.php"?>
<?
// Original idea by: Dmitry Boykov (http://forum.dklab.ru/users/DmitryBoykov/)
$file = file('/usr/local/apache/conf/vhosts.conf');
foreach ($file as $line) {
  if (preg_match('/^[^#]* <VirtualHost \s+ [^:>]+ (?::(\d+))?/six', $line, $p)) {
    $port = @$p[1];
  }
  if (preg_match('/^[^#]* ServerName \s+ "?([^"]*)"?/six', $line, $p)){
    if ($port == 443) continue;
    $dom = preg_replace('/^www\./si', '', $p[1]);
    $dom .= $port && $port != 80? ":$port" : "";
    $domains[$dom] = join(".", array_reverse(preg_split('/\./', $dom)));
  }
}
asort($domains);

$prev = false;
foreach ($domains as $dom=>$parts) {
  if (!$prev || !preg_match('/'.preg_quote($prev, '/').'$/si', $dom)) {
    echo "<a href=\"http://{$dom}\"><b>{$dom}</b></a></br>";
    $prev = $dom;
  } else {
    print "<dd><a href=\"http://{$dom}\">{$dom}</a><br /></dd>";
  }
}
?>
<?include "../../_footer.php"?>
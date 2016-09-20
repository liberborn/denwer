// Для кросс-браузерности. (-:
var ie = document.all && document.all.item && !window.opera;
if ( !ie ) {
	var el_in_find_td = document.getElementById('in_find_td');
	el_in_find_td.style.borderTop = "2px groove ButtonFace";
}

// Выключает некоторые опции, если это необходимо.
function dnsearchChangeMode() {
	if ( document.forms['dnsearch_form']['mode'].value == "regex" ) {
		document.forms['dnsearch_form']['logic'].disabled = true;
	} else {
		document.forms['dnsearch_form']['logic'].disabled = false;
	}
}

// Проверка на возможность грузить локальные ссылки.
function openLocalFile(file, blank) {
	if ( file.match( /^file:/ ) ) {
		try {
			if ( !blank ) { document.location = file; }
			else          { window.open(file);        }
		} catch (e) {
			alert('Ваш браузер не может перейти по локальной ссылке. Скорее всего это связано с настройками безопасности вашего пользовательского агента. Если Вы используете браузер Mozilla (и другие подобные клиенты вроде Firefox), Вам необходимо ввести в адресной строке «about:config», затем найти опцию «security.checkloaduri» и выставить её значение как «false». После этой операции Вы сможете переходить по локальным ссылкам. Если же Вы используете другой браузер, смотрите его настройки безопасности.\n\nКроме того, зафиксированы случаи блокировки обращений к локальным адресам программой «Kaspersky Anti-Hacker».\n\nВот, что выдал Ваш браузер при попытке перехода по локальной ссылке:\n'+e);
		}
		return false;
	} else { return true; }
}

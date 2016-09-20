# +-------------------------------------------------------------------------+
# | Джентльменский набор Web-разработчика                                   |
# | Версия: Денвер-3 2013-06-02                                             |
# +-------------------------------------------------------------------------+
# | Copyright (C) 2001-2010 Дмитрий Котеров.                                |
# +-------------------------------------------------------------------------+
# | Данный файл является частью комплекса программ "Денвер-3". Вы не можете |
# | использовать  его в коммерческих  целях.  Никакие другие ограничения не |
# | накладываются.  Если вы хотите внести изменения в исходный код,  авторы |
# | будут рады получить от вас комментарии и замечания. Приятной работы!    |
# +-------------------------------------------------------------------------+
# | Домашняя страница: http://denwer.ru                                     |
# | Контакты: http://forum.dklab.ru/denwer                                  |
# +-------------------------------------------------------------------------+

package StartManager;
$VERSION = 3.00;
use Tools;

sub action($%);
sub action($%) {
	my $action = lc(shift||"");
	my %data = @_;

	# Set envirinment?
	if(my $ENV=$data{PATH}) {
		my @env=();
		foreach my $e (@{ref $ENV eq "ARRAY"? $ENV : [$ENV]}) {
			my $s = $e;
			$s=~s{/}{\\}sg;
			push @env, $s if $ENV{PATH}!~/(;|^)\Q$s\E(;|$)/s;
		}
		$ENV{PATH} = join(";",@env,$ENV{PATH});
	}

	# Restart?..
	my $sub = $data{$action};
	if($action eq "restart") {
		if($sub && $sub->($action,%data) || !$sub) {
			action("stop",%data);
			action("_middle",%data) if ref $data{_middle} eq "CODE";
			return action("start",%data);
		}
	}

	# Other action?
	if(ref $sub eq "CODE") {
		$sub->($action,%data);
	} else {
		my @caller;
		for(my $i=0; my @c=caller($i); $i++) {
			if($c[0] ne __PACKAGE__) {
				@caller = @c;
				last;
			}
		}
		my @actions = map { ref $data{$_} eq "CODE" && !/^_/? ($_) : () } sort keys %data;
		my $fn = basename(dirname($caller[1]))."/".basename($caller[1]);
		die(
			($action? "Undefined action \"$action\" in $fn\n" : "").
			"Usage: $fn {".join("|",@actions,"restart")."}\n"
		);
	}
}

return 1;
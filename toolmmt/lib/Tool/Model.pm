package Tool::Model;
use Mojo::Base 'Mojolicious';

use Tool::Model::Webdb;
has 'webdb' => sub { Tool::Model::Webdb->new };


#------------------------------------------------------------------
sub today{
#------------------------------------------------------------------

=head2 今日の日付 [today]

=over 2

今日の日付を返す

=item ($yy,$mm,$dd) = today();

=back

=cut

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    return $year + 1900 ,$mon + 1,$mday;
}
#------------------------------------------------------------------
sub now{
#------------------------------------------------------------------

=head2 現在の時刻 [now]

=over 2

現在の時刻を返す

=item ($hh,$mm,$ss) = now();

=back

=cut

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    return $hour,$min,$sec;
}
sub getwdayName{
    my $s = shift;
    return (qw(日 月 火 水 木 金 土))[$s->getwday(@_)];
}
sub getwday{
    my $s = shift;
    my($year, $mon, $mday) = @_;

    if ($mon == 1 or $mon == 2) {
        $year--;
        $mon += 12;
    }
    return int($year + int($year / 4) - int($year / 100) + int($year / 400)
        + int((13 * $mon + 8) / 5) + $mday) % 7;
}
sub addmon{
    my $s = shift;
    my ($y,$m,$d,$add) = @_;
    $m += $add;
    my $mod = int($m) % 12;
    $mod = 12 unless($mod);
    if($m <= 0){ $y = $y + int($m/12) - 1;
    }else{ $y = $y + int(($m - 1)/12);}
    return $y,$mod,$d;
}
sub adddate{
    my $s = shift;
    return mjd2date(date2mjd(shift,shift,shift) + shift);
}
sub date2mjd{
    my ($y,$m,$d) = @_;
    if($m <= 2){$y--;$m += 12;}
    return int($y*365.25)+int($y/400)-int($y/100)+int(($m-2)*30.59)+$d-678912;
}
sub diffdate{
    my $s = shift;
    my ($y,$m,$d) = $s->ymd_split(shift);
    my ($yy,$mm,$dd) = $s->ymd_split(shift);
    return date2mjd($y,$m,$d) - date2mjd($yy,$mm,$dd);
}
sub mjd2date{
    my $days = shift;
    $days += 678912;
    my $y = int($days/365.25);
    my $tmp;
    while(($tmp = $days-int($y*365.25)-int($y/400)+int($y/100))<30.59){
        $y--;
    }
    my $m = int($tmp / 30.59) + 2;
    my $d = $tmp - int(($m-2)*30.59);
    if($m > 12){$y++;$m-=12;}
    return $y,$m,$d;
}

#------------------------------------------------------------------------#
sub ymd_split{
#------------------------------------------------------------------------#

=head2 日付分解 [ymd_split]

日付らしき文字列を年、月、日に分解する

 ($y,$m,$d) = ymd_split("YYYY-MM-DD");

=cut

    my $shift = shift;
    my $tmp = shift;
    $tmp =~ /\D*(\d{1,4})\D*(\d{1,2})\D*(\d{1,2})\D*/;
    return $1,$2,$3;
}
#------------------------------------------------------------------
sub holiday{
#------------------------------------------------------------------

=head2 祝日計算 [holiday]

=over 2

祝日なら祝日の名前を返す

=item $name = holiday(-date=>YYYYMMDD)

 西暦年月日より祝日の判断を行う

=back

=cut

    my $s = shift;
    my %x = (
        1 => {1 => "元旦",},
        2 => {11 => "建国記念日",
            23 => "天皇誕生日"},
        4 => {29 => "昭和の日",},
        5 => {3 => "憲法記念日",
            4 => "みどりの日",
            5 => "こどもの日",},
        8 => {11 => "山の日",},
        11 => {3 => "文化の日",
            23 => "勤労感謝の日",},
        @_);
    my($y,$m,$d) = $s->ymd_split($x{-date});
    $m = $m+0;
    $d = $d+0;
    $x{1}{$s->get_w_day($y,1,2,1)} = "成人の日";
    $x{7}{$s->get_w_day($y,7,3,1)} = "海の日";
    $x{9}{$s->get_w_day($y,9,3,1)} = "敬老の日";
    $x{10}{$s->get_w_day($y,10,2,1)} = "スポーツの日";
    my ($vernal,$autumnal)=$s->get_equinox_day($y);
    $x{3}{$vernal} = "春分の日";
    $x{9}{$autumnal} = "秋分の日";
    my($yy,$mm,$dd) = $s->adddate($y,$m,$d,-1);
    if($s->getwday($yy,$mm,$dd) == 0 and defined $x{$mm}{$dd}){
        $x{$m}{$d} = "振替の休日";
    }
    if($s->getwday($yy,5,5) <= 2){
        $x{5}{6} = "国民の休日";
    }
    return $x{$m}{$d};
}
#------------------------------------------------------------------
sub get_w_day{
#------------------------------------------------------------------

=head2 $y年$m月第$n曜日の日を返す [get_w_day]

=over 2

=item $d = get_w_day($y,$m,$n,$wday)

 $y: 年
 $m: 月
 $n: 第何曜日かを指定[1〜5]
 $n: 曜日 [0〜6] (0:日曜 1:月曜 2:火曜 3:水曜 4:木曜 5:金曜 6:土曜)
 $d: 対象の日付を返す 

=back

=cut

	my $s = shift;
	my ($y,$m,$n,$wday) = @_;
	my $st_wday = $s->getwday($y,$m,1);
	my $end_day = $s->end_day($y*100+$m);
	my $d;
	if($wday >= $st_wday){$n--;}
	$d = 7 * $n + $wday + 1 - $st_wday;
	if($d > $end_day or $d <= 0){$d = '';}
	return $d;
}
#------------------------------------------------------------------
sub get_equinox_day{
#------------------------------------------------------------------

=head2 春分の日と秋分の日を求める [get_equinox_day]

=over 2

 指定した年の春分日・秋分日をもとめる
（1980年から2099年に適用）
 ($vernal,$autumnal)=get_equinox_day($y);

=back

=cut

    my $s = shift;
    my ($yy)=@_;
    my ($vernal) = int(20.8431+0.242194*($yy-1980)-int(($yy-1980)/4));
    my ($autumnal)=int(23.2488+0.242194*($yy-1980)-int(($yy-1980)/4));

    return ($vernal,$autumnal);
}
#------------------------------------------------------------------
sub end_day{
#------------------------------------------------------------------

=head2 末日算出 [end_day]

=over 2

入力年月から末日を計算する。

=item $day = end_day($DATE)

 $DATE: 日付 YYYYMM or YYYY/MM
 $day: $DATEの末日(28or29or30or31)

=back

=cut
	my $s = shift;
	my $yymm = shift;
	my @end = (31,28,31,30,31,30,31,31,30,31,30,31);
	$yymm =~ /^(\d{1,4})\D*(\d{1,2})$/;
	my ($y,$m) = ($1,$2);
	if($2 != 2){return $end[$m - 1];}
	if($y % 400 == 0 or $y % 100 != 0 and $y %4 == 0){
		return 29;
	}else{	return $end[$m - 1];}
}
sub make_days{
    my ($s,$y,$m,$d,$dumy) = @_;
    my @days = map{[$y,$m,$_]} (1 .. $s->end_day($y*100+$m));
    my $w = $s->getwday($y,$m,$s->end_day($y*100+$m));
    my ($yy,$mm,$dd) = (0,0,0);
    for ($w+1 .. 6){ 
        ($yy,$mm,$dd) = $s->adddate($y,$m,$s->end_day($y*100+$m),$dd+1);
        push(@days,[$yy,$mm,$dd]);
    }
    $d = 1;
    $w = $s->getwday($y,$m,$d);
    while($w--){
        ($y,$m,$d) = $s->adddate($y,$m,$d,-1);
        unshift(@days,[$y,$m,$d]);
    }
    return @days;
}
sub make_cal{
    my ($s,$y,$m,$d,$dumy) = @_;
    my $cal = '';
    $cal .= "<table border=0 width=50%>";
    $cal .= $s->tag("tr",$s->tag("td",qw(日 月 火 水 木 金 土)));
    my $i = 0;
    $cal .= join ("",map {$s->day_class($i++,$y,$m,$_) } $s->make_days($y,$m,$d));
    $cal .= "</table>";
    return $cal;
}
sub day_class{
    my ($s,$i,$y,$m,$d) = @_;
    my $text ='';
    my $class = $s->holiday(-date=>$d->[0]*10000+$d->[1]*100+$d->[2]);
    if($class ne ''){
        $class = 'hol';
    }else{
        $class = qw(Sun Mon Tue Wed Thu Fri Sat)[$i % 7];
    }
    $class .= ' today' if ($s->isToday($d->[0],$d->[1],$d->[2]));
    $class = 'Non' if($m != $d->[1]); 
    $text .= '<tr>' if($i % 7 == 0);
    $text .= qq{<td class="$class">$d->[2]</td>};
    $text .= '</tr>' if($i % 7 == 6);
    return $text;
}
sub isToday{
    my ($s,$y,$m,$d) = @_;
    my ($yy,$mm,$dd) = $s->today();
    return 1 if($y == $yy and $m == $mm and $d == $dd);
    return 0;
}
sub tag{
    my $s = shift;
    my $tag = shift;
    my $text ='';
    $text .= "<${tag}>$_</${tag}>" for(@_);
    return $text;
}

1;

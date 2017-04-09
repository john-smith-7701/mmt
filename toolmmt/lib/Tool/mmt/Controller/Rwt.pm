package Tool::mmt::Controller::Rwt;
use Mojo::Base 'Tool::mmt::Controller::Mmt';
use Mojo::Util qw(slurp);
use Encode qw/ decode decode_utf8 encode encode_utf8/;

has contents => "";
has line_count => 0;
has page_count => 0;
has page => 0;
has max_line => 42;
has restart_page => 1;
has end_page => 10000;
has rskip => 0;
has endsw => 0;
has break_level => -1;
has head_print => 0;
has head_line => sub {[]};
has line => sub {[]};
has sth => "";
has sql =>"";
has ref => sub {{}};
has oref => "";
has bottom_const => "<div align=right>Powered by perl-mojolicious</div>";
has column => 1;
has title => "";
has print_form => "rwt/print_main";
has item_list => sub {[]};
has dele_item => sub {{'UPD_TIME'=>1}};
has lf_spec => sub {{}};
has break_ctl => sub {[
            {
                level => 99,
                key => '項目名',
                _bef => 0,      # 前改行
                _aft => 0,      # 後改行
                '項目１' => 0,    # 0: sumry
                '項目２' => '小計' # コンスタント
            },
    ]};

my @line;
my $dbh;
my $dele_item = {UPD_TIME =>,1};
my $init_sw = 0;

sub print_main {
    my $s = shift;
    $dbh = $s->app->model->webdb->dbh;
    $s->rwt_init;
    $s->_rwt_init;
    $init_sw = 0;
    $s->sth($s->rwt_prepare($s->sql));
    $s->sth->execute();
    $s->render($s->print_form);
}
sub rwt_init{
    my $s = shift;
    $s->item_list([]);
}
sub _rwt_init{
    my $s = shift;
    $s->stash->{title} = "rwt sample";
    if($s->sql eq ""){
        if($s->param('table') ne ''){
            $s->sql(qq{select * from @{[$s->param('table')]}});
        }else{
            $s->sql("select * from 商品");
        }
    }

    $s->title($s->param('title')||$s->param('table')||'title') if ($s->title eq "");
    $s->line_count(0);
    $s->page_count(0);
    @{$s->item_list} = map { encode_utf8($_) } @{$s->item_list};
    $s->sth($s->rwt_prepare($s->sql));
    $s->sth->execute();
    if(@{$s->item_list} == 0){
        $s->item_list([@{$s->sth->{NAME}}]);
    }
    @{$s->item_list} = grep { ! $dele_item->{$_} } @{$s->item_list};
}
sub print_proc{
    my $s = shift;
    my $ref = shift;
    $s->rskip(0);
    $s->endsw(0);
    $s->rwt_tisel($ref);
    if($s->endsw != 0 or $s->page_count > $s->end_page){
        return;
    }
    return if($s->rskip == 1);
    $s->rwt_data_save($ref) if($init_sw == 0);
    $init_sw = 1;

    $s->break_check($ref);
    $s->rwt_dtail($ref);
    $s->rwt_dtail_opt($ref);
    $s->rwt_print_dt($ref);
    $s->rwt_sumry($ref);
    $s->rwt_sumcomp($ref);
    $s->head_print(0);
    $s->rwt_data_save($ref);
}
sub final_proc{
    my $s = shift;
    $s->endsw(99);
    $s->break_level(0);
    $s->break_routine(0);
    $s->footer(99);
}
sub _bottom_print{
    my $s = shift;
    $s->printout("</table>");
    $s->bottom_print();
    $s->printout("</section>");
}
sub bottom_print{
    my $s = shift;
    $s->printout($s->bottom_const) if($s->bottom_const);
}
sub break_check{
    my $s = shift;
    my $ref = shift;
    my $level = 99;

    if($s->line_count > $s->max_line or $s->line_count == 0){
        $s->rwt_head_print();
    }

    my $oref = $s->oref;
    my $i = -1;
    for my $break_control (@{$s->break_ctl}){
        $i++;
        $level = $break_control->{level};

        if ($ref->{$break_control->{key}} ne 
            $oref->{$break_control->{key}}){
                   $s->break_routine($i);
                   last;
        }
    }
}
sub break_routine{
    my $s = shift;
    my $i = shift;
    for (my $j = @{$s->break_ctl} - 1;$j>=$i;$j--){
        $s->rwt_print_levelset($j);
        $s->rwt_print_level($j,$i);
    }
}
sub rwt_print_levelset{
    my $s = shift;
    my $i = shift;
    my $ctl = $s->break_ctl->[$i];
    $s->feed($ctl->{_bf}) if (exists($ctl->{_bf}));
    $line[0] = "<tr>";
    for (@{$s->item_list}) {
        if (exists($ctl->{$_})){
            $line[0] .= $s->set_lf_spec($ctl->{$_},$_);
           if ($ctl->{$_} =~ m/^[0-9\-\+\.]+$/){
               $ctl->{$_} = 0;
           }
        }else{
            $line[0] .= "<td>&nbsp;</td>";
        }
    }
    $line[0] .= "</tr>";
}
sub rwt_print_level{
    my $s = shift;
    my $i = shift;
    my $break = shift;
    if($s->line_count > $s->max_line or $s->line_count == 0){
        $s->rwt_head_print();
    }
    for my $line (@line){
        $s->printout($line);
        $s->line_count($s->line_count+1)
    }
    my $ctl = $s->break_ctl->[$i];
    $s->feed($ctl->{_af}) if (exists($ctl->{_af}) and $i == $break);
}
sub rwt_dtail_opt{
    my $s = shift;
}
sub rwt_dtail_bef{
    my $s = shift;
}
sub rwt_dtail{
    my $s = shift;
    my $ref = shift;
    $s->rwt_dtail_bef($ref);

    $s->line->[0] = "<tr>";
    for (@{$s->item_list}) {
        $s->line->[0] .= $s->set_lf_spec($ref->{$_},$_);
    }
    $s->line->[0] .= "</tr>";
}
sub set_lf_spec{
    my $s = shift;
    my $r = shift;
    my $name = shift;
    my $item = "<td ";
    $item .= qq{class="};
    $item .= exists($s->lf_spec->{$name}->{class})  ?
               $s->lf_spec->{$name}->{class}
               :"overflow";
    $item .= qq{" };
    $item .= qq{style="};
    $item .= exists($s->lf_spec->{$name}->{style}) ? 
               $s->lf_spec->{$name}->{style}
               :"width:200px;max-width:200px";
    $item .= qq{">@{[$s->edit($r,$s->lf_spec->{$name}->{edit})]}</td>};
    return $item;
}
sub edit{
    my $s = shift;
    my $data = shift;
    my $edit = shift;
    return $data if ($data eq "&nbsp;");
    $data = sprintf($edit->[1],$data) if $edit->[1];
    if ($edit->[0] & hex("04")){
       1 while $data =~ s/(.*\d)(\d\d\d)/$1,$2/;
    }
    if ($edit->[0] & hex("02")){
       $data = "" if($data == 0)
    }
    return $data;
}
sub cell_width{
    my $s = shift;
    my $w = shift;
    my $p = shift;
    $w ||= 100;
    $p ||= 3;
    return "width:${w}px;max-width:${w}px;padding:1px ${p}px;";
} 
sub group_inji{
}
sub rwt_sumry{
}
sub rwt_sumcomp{
    my $s = shift;
    my $ref = shift;
    for my $ctl (@{$s->break_ctl}){
       for (@{$s->sth->{NAME}}){
           if (exists($ctl->{$_}) and $ctl->{$_} =~ m/^[0-9\-\+\.]+$/){
               $ctl->{$_} += $ref->{$_};
           }
       }
    }
}
sub rwt_print_dt{
    my $s = shift;
    my $ref = shift;
    for(@{$s->line}){
        if($s->line_count > $s->max_line){
            $s->line_count(0);
            $s->rwt_head_print();
        }
        $s->printout($_);
        $s->line_count($s->line_count + 1);
    }
}
sub rwt_feed{
    my $s = shift;
    $s->line_count($s->max_line + 1);
}
sub rwt_head_print{
    my $s = shift;
    $s->head();
    if ($s->column > 1){
       my $colwidth = sprintf("width=%d%%",int(100/$s->column));
       my $mod = $s->page_count % $s->column;
       if ($mod == 1){
          $s->printout($s->head_line->[0]);
          $s->printout(qq{<table width=100%><tr>});
       } 
       $s->printout(qq{<td $colwidth aligin=center style="vertical-align:top">});
    }
    my $i = 0;
    for(@{$s->head_line}){
        if ($i == 0 and $s->column > 1){
        }else{
           $s->printout($_);
        }
        $i++;
    }
}
sub printout{
    my $s = shift;
    if($s->page < $s->restart_page){
        return;
    }
    if($s->page > $s->end_page){
        return;
    }
    $s->c_set(shift);
}
        
sub rwt_prepare{
    my $s = shift;
    return $dbh->prepare($s->sql);
}
sub rwt_dataget{
    my $s = shift;
    return $s->sth->fetchrow_hashref();
}
sub rwt_tisel{
    my $s = shift;
}
sub rwt_data_save{
    my $s = shift;
    my $ref = shift;
    $s->oref({});
    my $oref = {};
    for (@{$s->sth->{NAME}}){
        $oref->{$_} = $ref->{$_};
    }
    $s->oref($oref);
}

sub head{
    my $s = shift;
    $s->footer() unless ($s->endsw);
    $s->page_count($s->page_count + 1);
    if ($s->column > 1) {
       $s->page(int($s->page_count / $s->column) + 1);
    }else{
       $s->page($s->page_count);
    }
    $s->head_line->[0] = qq{<section class="sheet">};
    $s->head_line->[0] .= qq{
<table width=100%>
<tr>
<td width=30%></td>
<td width=40% align=center><h1>@{[$s->title]}</h1></td>
<td width=30% align=right>page:@{[$s->page]}</td>
</tr></table>};

    $s->head_line->[1] = "<table border=1><tr>";
    for (@{$s->item_list}) {
        $s->head_line->[1] .= qq{<th class="overflow" >@{[decode_utf8($_)]}</th>};
    }   
    $s->head_line->[1] .= "</tr>";
    $s->line_count(1);
}
sub footer{
    my $s = shift;
    my $level = shift||0;
    return if ($s->endsw == 100);
    return if ($s->page_count == 0);

    $s->feed();
    if ($s->column > 1){
        while (1){
            $s->printout("</table></td>");
            if ($s->page_count % $s->column == 0){
                $s->printout("</tr>");
                $s->_bottom_print();
                last;
            }
            if ($s->endsw == 99 or $s->endsw == 100){
                $s->endsw(100);
                $s->rwt_head_print();
                $s->feed();
            }else{ last;}
        }
    }else{
        $s->_bottom_print();
   }
}
sub feed{
    my $s = shift;
    my $feed_count = shift || $s->max_line - $s->line_count + 1;
    $feed_count =  $feed_count < 0 ? $s->max_line + $feed_count
                                   : $s->line_count + $feed_count - 1; 
    return if ($s->line_count == 0);
    $feed_count = $s->max_line if ($feed_count > $s->max_line);
    for(;$s->line_count <= $feed_count ; $s->line_count($s->line_count+1)){
        my $text = "<tr>";
        for (@{$s->item_list}) {
            $text .= $s->set_lf_spec("&nbsp;",$_);
        }
        $text .= "</tr>";
        $s->printout($text);
    }
}
sub c_set{
    my $s = shift;
    my $t = shift;
    $s->contents($s->contents . $t . "\n");
}
sub c_get{
    my $s = shift;
    my $text = $s->contents;
    $s->contents("");
    return $text;
}

1;

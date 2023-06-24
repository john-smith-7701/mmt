 package Tool::mmt::Controller::Menu;
 use Mojo::Base 'Tool::mmt::Controller::Json';
 use Encode qw/ decode decode_utf8 encode encode_utf8/;

 
 sub menu{
     my $s = shift;
     my $data = $s->menu_get();
     $s->stash(_data=> $data);
     $s->render('menu/menu');
 }
 sub menu_get{
     my $s = shift;
     my $menu = $s->param('menu') || 'START';
     my $sql = <<END_Script;

     select m.SEQ_NO,m.No,m.名称 as meisyo,m.メニュー区分 as menukbn,a.URL,a.PARAM,m.memo 
     from menu_config m 
     left join menu_item a on a.ID = m.menu_ID and a.ID <> ''
     where m.ID = ? AND
        exists (select 1 from user_group a inner join user_group b on b.groupId = a.groupId and b.id = ? where a.id = m.ID)
     order by m.No
END_Script

     my $dbh = $s->app->model->webdb->dbh;
     my $data = $dbh->selectall_arrayref($sql,+{Slice => +{}},$menu,$s->param('user'));
     return $data;
 }
 sub select{
     my $s = shift;
     my $sql = "select a.*,m.* from menu_config m left join menu_item a on a.ID = m.menu_ID 
                where m.SEQ_NO = ?";
     my $dbh = $s->app->model->webdb->dbh;
     my $data = $dbh->selectall_arrayref($sql,+{Slice => +{}},$s->param('no'));
     $s->stash(_data=> $data);
     $s->stash(_parm=> $s->select_pars($data));
     $s->render('menu/select');
 }
 sub select_pars{
     my $s = shift;
     my $r = shift;
     my $param = {'title'=>$r->[0]->{encode_utf8('名称')}};
     $param->{'condition'} = $s->condition_form($r->[0]->{memo});
     return $param;
 }
 sub condition_form{
     my $s = shift;
     my $r = shift;
     my $text = '';
     my @cond = split("\n",$r);
     $text .= "<fieldset><legend>条件</legend>\n";
     for (@cond){
         my @pars = split(/,/,$_);
         $text .= "<div class='flexX'><div class='itemlabel'>" . $pars[1] . "</div>"
                . $s->make_input_type(@pars)
                . qq{</div>\n}; 
     }
     $text .= "</fieldset>\n";
     return $text;
 }
 sub make_input_type{
     my $s = shift;
     my @pars = @_;
     my $text = "<div>";
     if($pars[0] =~ /^p/){
         $text .= "<input type=text name=$pars[0]" . "_" . $pars[1] . ">" . join(",",@pars[2..$#pars]) ;
     } else {
         $text .= "<input type=text name=$pars[0]" . "_" . $pars[1] . "_ge>～"
                . "<input type=text name=$pars[0]" . "_" . $pars[1] . "_le>";
     }
     $text .= "</div>";
     return $text;
 }
 sub make_panel{
     my $s = shift;
     my $text = <<END_SCRIPT;
<link rel="stylesheet" type="text/css" href="/css/demo.css" />

<div id="overlay" class="content">
    <div class="inner">
    @{[$s->panel_content()]}
            <div id="panel" class="panel hide"></div>
    </div>
</div>

<script type="text/javascript">
    \$(function() {
        \$('#panel').toggle(
            function() {
                \$(this).addClass('show').removeClass('hide');
                \$('#overlay').stop().animate( { left : - \$('#overlay').width() + 20 + 'px' }, 300 );
                sessionStorage.setItem("CalPanel","hide")
            },
            function() {
                \$(this).addClass('hide').removeClass('show');
                \$('#overlay').stop().animate( { left : '0px' }, 300 );
                sessionStorage.setItem("CalPanel","show")
            }
        );
        \$('#overlay').fadeIn(500);
    });
    window.onload = function(){
        if(sessionStorage.getItem("CalPanel") == "hide"){
            window.setTimeout(function(){
                \$("#panel").click();
            },1000);
        }
    };

</script>

END_SCRIPT
     return $text;
 }
 sub panel_content{
     my $s = shift;
     my $m = $s->app->model;
     my $ym = shift || sprintf("%04d%02d%02d",$m->today());
     my ($yy,$mm,$dd) = $m->ymd_split($ym);
     my $text = <<END_SCRIPT
    <p align=center>
    <div id=calendar>
    @{[$s->calendar2($yy*10000+$mm*100+1)]}
    </div>
    <script type="text/javascript">
    function get_cal(ym){
        \$.ajax({
                type: 'POST',
                url: '/api/json/calendar',
                data: {
                        ym: ym,
                        mode: '@{[$s->param('mode')]}',
                        session: '@{[$s->session('session')]}',
                    },
                success: function(data){
                        \$("#calendar").html(data);
                    }
        });
    }
    </script>
    </p>
END_SCRIPT
 }
 1;

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
     my $sql = "select m.SEQ_NO,m.No,m.名称 as meisyo,m.メニュー区分 as menukbn,a.URL,a.PARAM from menu_config m left join menu_item a on a.ID = m.menu_ID 
                where m.ID = ? order by m.No";
     my $dbh = $s->app->model->webdb->dbh;
     my $data = $dbh->selectall_arrayref($sql,+{Slice => +{}},$menu);
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
     $text .= "<fieldset><legend>条件</legend><table>";
     for (@cond){
         my @pars = split(/,/,$_);
         $text .= "<tr>" . "<th>" . $pars[1] . "</th>"
                . $s->make_input_type(@pars)
                . qq{</tr>}; 
     }
     $text .= "</table></fieldset>";
     return $text;
 }
 sub make_input_type{
     my $s = shift;
     my @pars = @_;
     my $text = "<td>";
     if($pars[0] =~ /^p/){
         $text .= "<input type=text name=$pars[0]" . "_" . $pars[1] . "></td><td colspan=2>" . join(",",@pars[2..$#pars]) . "</td>";
     } else {
         $text .= "<input type=text name=$pars[0]" . "_" . $pars[1] . "_ge></td><td>～</td><td>"
                . "<input type=text name=$pars[0]" . "_" . $pars[1] . "_le></td>";
     }
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
            },
            function() {
                \$(this).addClass('hide').removeClass('show');
                \$('#overlay').stop().animate( { left : '0px' }, 300 );
            }
        );
        \$('#overlay').fadeIn(500);
    });
    window.onload = function(){
//      document.getElementById("panel").click();
    };

</script>

END_SCRIPT
     return $text;
 }
 sub panel_content{
     my $s = shift;
     my $text = <<END_SCRIPT
    <pre>
    @{[`cal -3h`]}
    @{[`date +"%a %b %d %Y"`]}
    </pre>
END_SCRIPT
 }
 1;

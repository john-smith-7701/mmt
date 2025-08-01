package Tool::mmt::Controller::Schedule;
use Mojo::Base 'Tool::mmt::Controller::Mmt';


sub init_set {
    my $s = shift;
    $s->mmtForm('mmt/schedule');
    $s->param('_table','user_schedule');
    $s->stash->{title} = '予定';
    push (@{$s->{_action}},{name=>'参照',action=>sub {$s->data_get()}});  
    push (@{$s->{_action}},{name=>'更新',action=>sub {$s->data_update()}});
    push (@{$s->{_action}},{name=>'検索',action=>sub {$s->data_serch()}});
    if($s->param('_action') eq ''){
        $s->data_get();
    }
}
sub where{
    my $s = shift;
    my $t = "join session a on a.user = m.userid where 日付 = ? and session = ?";
    $s->{'m'}->{where} = [$s->param('ymd'),$s->param('session')];
    if($s->param('_action') ne ''){
        $t = $s->SUPER::where;
    }
    return $t;
}
sub action_set{
    my $s = shift;
    push (@{$s->{_action}},{name=>'参照',action=>sub {$s->data_get()}});  
    push (@{$s->{_action}},{name=>'更新',action=>sub {$s->data_update()}});
    push (@{$s->{_action}},{name=>'検索',action=>sub {$s->data_serch()}});
}
sub data_update{
    my $s = shift;
    $s->param('item0',$s->session2user());
    if($s->param('key0') == 0){
        $s->data_insert();
    }else{
        $s->SUPER::data_update();
    }
    $s->redirect_to("/menu/calendar?mode=schedule&ym=@{[$s->param('item1')]}");
}
sub UPDATE_SUB{
    my $s = shift;
    my $log = Mojo::Log->new();
    #$log->debug( $s->{sql});
}
sub GET_AF_CHECK{
    my $s = shift;
    if ($s->{errorflag} == 1){
        $s->param('key0',0);
        $s->param('item1',$s->param('ymd'));
    }
    $s->param('item0',$s->session('session'));
}
sub data_serch{
    my $s = shift;
    $s->set_table_info();
    my $dbh = $s->app->model->webdb->dbh;
    my $sql = "select * from @{[$s->param('_table')]} where userid = ? order by 日付 desc";
    my @p = ();
    push @p,$s->param('user');
    $s->{'sth'} = $dbh->prepare($sql);
    $s->{'sth'}->execute(@p);
    $s->my_render($s->mmtDataList);
}
1;

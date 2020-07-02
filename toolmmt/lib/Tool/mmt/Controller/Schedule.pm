package Tool::mmt::Controller::Schedule;
use Mojo::Base 'Tool::mmt::Controller::Mmt';


sub init_set {
    my $s = shift;
    $s->mmtForm('mmt/schedule');
    $s->param('_table','user_schedule');
    $s->stash->{title} = '予定';
    push (@{$s->{_action}},{name=>'参照',action=>sub {$s->data_get()}});  
    push (@{$s->{_action}},{name=>'更新',action=>sub {$s->data_update()}});
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
}
sub data_update{
    my $s = shift;
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
    $log->debug( $s->{sql});
}
sub GET_AF_CHECK{
    my $s = shift;
    if ($s->{errorflag} == 1){
        $s->param('key0',0);
        $s->param('item0',$s->param('user'));
        $s->param('item1',$s->param('ymd'));
    }
}
1;

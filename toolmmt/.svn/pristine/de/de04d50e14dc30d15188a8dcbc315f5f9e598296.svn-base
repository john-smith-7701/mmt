package Tool::mmt::Controller::Userinfo;
use Mojo::Base 'Tool::mmt::Controller::Mmt';


sub init_set {
    my $s = shift;
    $s->mmtForm('mmt/userinfo');
    $s->param('_table','user_info');
    $s->stash->{title} = 'ユーザー情報を変更';
    $s->param('key0',$s->param('user'));
    push (@{$s->{_action}},{name=>'参照',action=>sub {$s->data_get()}});  
    push (@{$s->{_action}},{name=>'更新',action=>sub {$s->data_update()}});
    if($s->param('_action') eq ''){
        $s->data_get();
    }
}
sub action_set{
    my $s = shift;
    push (@{$s->{_action}},{name=>'参照',action=>sub {$s->data_get()}});  
    push (@{$s->{_action}},{name=>'更新',action=>sub {$s->data_update()}});
}

1;

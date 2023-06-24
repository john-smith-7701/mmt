package Tool::mmt::Controller::Changepassword;
use Mojo::Base 'Tool::mmt::Controller::Json';

sub menu{
    my $s = shift;
    my $render = $s->regstry() || 'auth/changepassword';
    $s->render($render);
}
sub regstry{
    my $s = shift;
    return undef if($s->param('newpasswd') ne $s->param('repasswd'));
    my $dbh = $s->app->model->webdb->dbh;
    my $data = $dbh->selectall_arrayref(
                "select 1 as user from user_tbl where userid = ? and password = sha(?)",+{Slice => +{}},$s->param('user'),$s->param('passwd').'qweer.info');
    return undef unless $data->[0]->{user};
    $dbh->do("update user_tbl set password = sha(?) where userid = ?",undef,
        $s->param('newpasswd').'qweer.info',$s->param('user'));
    return 'mmt/index';
 }
 
 1;

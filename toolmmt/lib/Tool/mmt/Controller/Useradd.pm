package Tool::mmt::Controller::Useradd;
use Mojo::Base 'Tool::mmt::Controller::Json';

sub menu{
    my $s = shift;
    my $render = $s->regstry() || 'auth/useradd';
    $s->render($render);
}
sub regstry{
    my $s = shift;
    $s->stash->{errmsg} = 'ユーザー名を入力してください。';
    return undef if($s->param('name') eq '');
    $s->stash->{errmsg} = 'メールアドレスを入力してください。';
    return undef if($s->param('email') eq '');
    my $dbh = $s->app->model->webdb->dbh;

    $s->stash->{errmsg} = 'ユーザー名が登録済みです';
    my $data = $dbh->selectall_arrayref(
                "select 1 as user from user_tbl where userid = ?",+{Slice => +{}},$s->param('name'));
    return undef if $data->[0]->{user};

    $s->stash->{errmsg} = 'メールアドレスが登録済みです';
    my $data = $dbh->selectall_arrayref(
                "select 1 as email from user_info where メール = ?",+{Slice => +{}},$s->param('email'));
    return undef if $data->[0]->{email};

    $s->stash->{errmsg} = '登録出来ませんでした。';
    eval {
        $dbh->do("start transaction",undef);

        $dbh->do("insert into user_tbl (userid,password,id) values (?,sha(?),0)",undef,
            $s->param('name'),"初期パスワードqweer.info");
        $dbh->do("insert into user_info (userid,メール,名前,ニックネーム,郵便番号,住所,電話番号,URL,メモ) values (?,?,?,?,?,?,?,?,?)",undef,
            $s->param('name'),$s->param('email'),$s->param('name'),$s->param('name'),'','','','','');

        $dbh->do("commit",undef);

        $s->stash->{errmsg} = '登録しました。（まだです）';
    };
    return undef;
 }
 
 1;

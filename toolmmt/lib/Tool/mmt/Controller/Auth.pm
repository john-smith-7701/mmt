package Tool::mmt::Controller::Auth;
use Mojo::Base 'Tool::mmt::Controller::Mmt';
use UUID::Tiny;
sub login {
    my $s = shift;
    $s->redirect_to($s->param('url')) if $s->param('url');
    $s->render( template => 'mmt/index');
}
sub check {
    my $s = shift;
    # セッション確定済なら認証通過
    if($s->session('session')){
        $s->param('session',$s->session('session'));
        my $dbh = $s->app->model->webdb->dbh;
        # セッションよりユーザを取得
        my $data = $dbh->selectall_arrayref(
                "select user,ニックネーム as nick from session left join user_info on userid = user where session = ?"
                        ,+{Slice => +{}},$s->session('session'));
        if($data->[0]->{'user'}){
            $s->param('user',$data->[0]->{'user'});
            $s->param('nick',$data->[0]->{'nick'}||'名無し');
            return 1;
        }
    }
    #パスワードチェック
    if($s->userAuth()){
        return 1;
    }
    $s->stash( 'url' => $s->req->url);
    $s->render( template => 'auth/login');
    return undef;
}
sub userAuth{
    my $s = shift;
    my $user = $s->param('user')||'';
    my $pass = $s->param('passwd')||'';
    if ($user eq '' or $pass eq '' or $user =~ /(admin|root)/i){
        $s->param('user','guest');
        $s->param('passwd','柿くへば鐘が鳴るなり法隆寺 by 子規');
        return undef; 
    }
    my $sessionId = $s->randomStr();
    my $dbh = $s->app->model->webdb->dbh;
    # パスワードを確認
    my $data = $dbh->selectall_arrayref(
                "select 1 as user from user_tbl where userid = ? and password = sha(?)",+{Slice => +{}},$s->param('user'),$s->param('passwd').'qweer.info');
    return undef unless $data->[0]->{user};
    # セッションにユーザーを登録
    $dbh->do("INSERT INTO  session (session,user) values (?,?)",undef,$sessionId,$s->param('user')); 
    $s->session('session' => $sessionId);
    return 1;
}
sub logout{
    my $s = shift;
    # セッション削除
    my $dbh = $s->app->model->webdb->dbh;
    $dbh->do("DELETE FROM session where session = ?",undef,$s->session('session')); 
    $s->session(expires => 1);
    $s->stash( 'url' => './login' );
    $s->render( template => 'auth/login');
}
sub token{
    my $s = shift;
    my $ret = $s->userAuth();
    my $json = qq/{"token":"@{[$s->session('session')]}"}/;
    if($ret){
        $s->render(data => $json,format=>'json');
    }else{
        $s->render(text => 'Authentication required!', status => 401);
    }
}
sub randomStr{
    my $s = shift;
    return UUID_to_string(create_UUID(UUID_V4));
=pod
    my %arg = (-length =>16,
                        -str => (join '',('A'..'Z','a'..'z','0'..'9')),
                         @_);
    my @str = split //,$arg{'-str'};
    my $str = "";
    for(1 .. $arg{'-length'}){$str .= $str[int rand($#str+1)];}
    return $str;
=cut
}
 
1;

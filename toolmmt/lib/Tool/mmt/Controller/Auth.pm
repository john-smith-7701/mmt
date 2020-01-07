package Tool::mmt::Controller::Auth;
use Mojo::Base 'Tool::mmt::Controller::Mmt';

sub login {
    my $s = shift;
    $s->redirect_to($s->param('url')) if $s->param('url');
    $s->render( template => 'mmt/index');
}
sub check {
    my $s = shift;
    # セッション確定済なら認証通貨
    if($s->session('session')){
        return 1;
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
        $s->param('passwd','guest01');
        return undef; 
    }
    my $sessionId = $s->randomStr();
    $s->session('session' => $sessionId);
    return 1;
}
sub logout{
    my $s = shift;
    # セッション削除
    $s->session(expires => 1);
    $s->stash( 'url' => './login' );
    $s->render( template => 'auth/login');
}
sub randomStr{
    my $s = shift;
    my %arg = (-length =>16,
                        -str => (join '',('A'..'Z','a'..'z','0'..'9')),
                         @_);
    my @str = split //,$arg{'-str'};
    my $str = "";
    for(1 .. $arg{'-length'}){$str .= $str[int rand($#str+1)];}
    return $str;
}
 
1;

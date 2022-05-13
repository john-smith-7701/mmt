 package Tool::mmt::Controller::Json;
 use Mojo::Base 'Tool::mmt::Controller::Mmt';
 use Encode qw/ decode decode_utf8 encode encode_utf8/;
 use Mojo::JSON qw(decode_json encode_json);
 use utf8;

 my $perl_object =  {head => 'Json Test Data',array=>[1,2,3,4],lang=>['perl','ruby','php'],
            日本語=>['漢字','ひらがな','ｶﾀｶﾅ']};

 sub json_post{
     my $s = shift;
     use Mojo::UserAgent;
     my $ua = Mojo::UserAgent->new;
     my $data = $ua->post('http://www21051ue.sakura.ne.jp:8888/index.cgi' =>
                                {Accept=> '*/*'} => json => $perl_object);
     if (my $res = $data->success){
         $s->render(data => $res->body ,format=>'html');
     }else{
         my ($err, $code) = $data->error;
         $s->render(data => $code ? "$code response: $err\n" : "Connection error: $err\n",
             format => 'text');
     }
 }

 sub json_test01{
     my $s = shift;
     $s->json_or_jsonp( $s->render_to_string(json => $perl_object)
         );
 }
 
 sub json{
     my $s = shift;
     if($s->req->json){
        $s->render(json => $s->req->json);
     }else{
        $s->render('json/json');
     }
 }

 sub json_or_jsonp{
     my $s = shift;
     my $json = shift;
     my $callback = $s->param('callback') ||"";
     if($callback ne ""){
         $s->render(data => "$callback($json)",format => 'js');
     } else {
         $s->render(data => $json, format=>'json');
     }
 }
 sub get{
     my $s = shift;
     my $sql = "select name,chat from test.chatdata order by rand() limit 10";
     my $dbh = $s->app->model->webdb->dbh;
     my $data = $dbh->selectall_arrayref($sql,+{Slice => +{}});
     $s->json_or_jsonp( $s->render_to_string(json => $data));
 }
 sub calendar{
     my $s = shift;
     my $m = $s->app->model;
     my $ym = $s->param('ym') || sprintf("%04d%02d%02d",$m->today());
     $s->render(text => $s->calendar2($ym));
 }
 sub calendar2{
     my $s = shift;
     my $ym = shift;
     my $m = $s->app->model;
     my ($yy,$mm,$dd) = $m->addmon($m->ymd_split($ym),-1);
     my $text = qq{<button id="prevMon"onclick="get_cal('@{[$yy*10000 + $mm*100+1]}')"><<</button>};
     ($yy,$mm,$dd) = $m->ymd_split($ym);
     $text .= qq{ $yy / $mm };
     ($yy,$mm,$dd) = $m->addmon($m->ymd_split($ym),1);
     $text .= qq{<button id="nextMon" onclick="get_cal('@{[$yy*10000 + $mm*100+1]}')">>></button>};
     $text .= $m->make_cal($m->ymd_split($ym),$s->param('mode'),$s->param('session'));
     return $text;
 }
 sub db_render_to_string{
     my $s = shift;
     my $p = shift;
     my $t = shift;
     my $newt = [];
     for my $a (@$t){
         my $newh = {};
         for my $k (keys(%$a)){
             $newh->{decode_utf8($k)} = $a->{$k};
         }
         push(@$newt,$newh);
     }
     return encode_json($newt);
 }
 
 1;

 package Tool::mmt::Controller::Json;
 use Mojo::Base 'Tool::mmt::Controller::Mmt';
 
 sub json_post{
     my $s = shift;
     use Mojo::UserAgent;
     my $ua = Mojo::UserAgent->new;
     my $data = $ua->post('http://localhost:3001/api/example/json' =>  {Accept=> '*/*'} => json => {a => 'b'});
     $s->render(json => $data->res->json);
 }
 sub json_test01{
     my $s = shift;
     $s->render(json => {head => 'Json Test Data',array=>[1,2,3,4],lang=>['perl','ruby','php'],
         日本語=>['漢字','ひらがな','ｶﾀｶﾅ']});
 }
 
 sub json{
     my $s = shift;
     $s->render(json => $s->req->json);
 }
 
 1;

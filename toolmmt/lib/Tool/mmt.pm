package Tool::mmt;
use Mojo::Base 'Mojolicious';
use Tool::Model;

has 'model' => sub {Tool::Model->new};
has 'controller' => "mmt";

# This method will run once at server start
sub startup {
  my $self = shift;
  $self->plugin('Config'=>{'file'=>'toolmmt.conf'});

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');
  $self->plugin('TagHelpers');
  $self->types->type(json =>'application/json;charset=UTF-8');
  # Router
  my $r = $self->routes;
  $r->namespaces(['Tool::mmt::Controller']);
  # ユーザー認証
  my $sr = $r->under->to('auth#check');
  # Normal route to controller
  $r->get('/')->to('example#welcome');
  $sr->get('/logout')->to('auth#logout');
  $sr->any('/login')->to('auth#login');
  $sr->any('/*name/login')->to('auth#login');
  $sr->any('/*name/logout')->to('auth#logout');
  $sr->get('/mmt/:_table/desc')->to('mmt#desc');
  $sr->get('/mmt/:_table')->to(controller => $self->controller,action =>'mainform');
  $sr->post('/mmt/:_table')->to(controller => $self->controller,action => 'registry');
  $sr->get('/mmtx/:controller')->to(controller => $self->controller,action =>'mainform');
  $sr->post('/mmtx/:controller')->to(controller => $self->controller,action => 'registry');
  $sr->any('/mmtx/:controller')->to(controller => $self->controller,action => 'mainform');
  $sr->any('/rwt/:controller')->to(controller => $self->controller,action => 'print_main');
  $sr->any('/menu/:controller')->to(controller => $self->controller,action => 'menu');
  $r->any('/api/:controller/:action')->to('example#welcom');
}

1;

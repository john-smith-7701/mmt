package Tool::mmt;
use Mojo::Base 'Mojolicious';
use Tool::Model;

has 'model' => sub {Tool::Model->new};
has 'controller' => "mmt";

# This method will run once at server start
sub startup {
  my $self = shift;

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');
  $self->plugin('TagHelpers');
  $self->types->type(json =>'application/json;charset=UTF-8');
  # Router
  my $r = $self->routes;
  $r->namespaces(['Tool::mmt::Controller']);
  # Normal route to controller
  $r->get('/')->to('example#welcome');
  $r->get('/mmt/:_table/desc')->to('mmt#desc');
  $r->get('/mmt/:_table')->to(controller => $self->controller,action =>'mainform');
  $r->post('/mmt/:_table')->to(controller => $self->controller,action => 'registry');
  $r->get('/mmtx/:controller')->to(controller => $self->controller,action =>'mainform');
  $r->post('/mmtx/:controller')->to(controller => $self->controller,action => 'registry');
  $r->any('/mmtx/:controller')->to(controller => $self->controller,action => 'mainform');
  $r->any('/rwt/:controller')->to(controller => $self->controller,action => 'print_main');
  $r->any('/api/:controller/:action')->to('example#welcom');
}

1;

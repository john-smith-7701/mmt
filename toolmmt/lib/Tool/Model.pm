package Tool::Model;
use Mojo::Base 'Mojolicious';

use Tool::Model::Webdb;
has 'webdb' => sub { Tool::Model::Webdb->new };

1;

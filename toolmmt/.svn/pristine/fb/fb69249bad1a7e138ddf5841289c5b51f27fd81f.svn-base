package Tool::mmt::Controller::Usertbl;
use Mojo::Base 'Tool::mmt::Controller::Mmt';

has 'mmtDataList' => 'mmt/datalist';

sub mainform {
    my $self = shift;

    $self->mmtForm('mmt/mainform');
    $self->param('_table','user_tbl');
    $self->SUPER::mainform;
}
sub registry{
    my $self = shift;
    $self->mmtForm('mmt/mainform');
    $self->param('_table','user_tbl');
    $self->SUPER::registry;
}
1;

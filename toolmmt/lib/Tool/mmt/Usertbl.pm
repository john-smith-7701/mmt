package Tool::mmt::Usertbl;
use Mojo::Base 'Tool::mmt::Mmt';

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

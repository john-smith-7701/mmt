package Webdb::constant;
use utf8;

sub new {
    my $class = shift;
    my $self = bless {},$class;
    $self->_initalize;
    return $self;
}
sub _initalize{
    my $s = shift;
    $s->{data_source} = "DBI:mysql:database=YourDB;host=localhost";
    $s->{user}        = "YourName";
    $s->{password}    = "YourPassword";

=POD

SQLlite

    $s->{data_source} = "DBI:SQLite:dbname=/tmp/a.db";
    $s->{user}        = "";
    $s->{password}    = "";

=cut

    $s->{explan} = {
        '担当者'    => {
            'ID'    => 'admin:管理者,0～999',
        },
        '商品'      => {
            '商品区分' => '0:課税,1:非課税,2:軽減課税',
        },
    };
    $s->{sidebar} = <<End_Text;
      <h4><a href="http://park15.wakwak.com/~k-lovely/cgi-bin/wiki/wiki.cgi">無精・短気・傲慢</a></h4>
End_Text
}

1;

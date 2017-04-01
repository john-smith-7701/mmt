package Tool::Model::Webdb;
use Mojo::Base 'Mojolicious';
use DBI;
use utf8;
use Data::Dumper;
use Tool::Model::Webdb::constant;

has const => sub {
    my $s = shift;
    return Webdb::constant->new();
};

has dbh => sub {
  my $self = shift;

  my $data_source = $self->const->{data_source};
  my $user        = $self->const->{user};
  my $password    = $self->const->{password};

  my $dbh;
  if($self->const->{data_source} =~ /^dbi:sqlite/i ){
      $dbh = DBI->connect($data_source);
      $dbh->{sqlite_unicode} = 1;
  }else{
      $dbh = DBI->connect(
               $data_source,
               $user,
               $password,
               {RaiseError => 1,
                mysql_enable_utf8 =>1,
                mysql_auto_reconnect =>1,
               }
      );
      $dbh->do("set names utf8");
  }
  return $dbh;
};

#---------------------------------------------------------------#
sub desc_table{
#---------------------------------------------------------------#

=head2 desc_table テーブル情報取得

=cut

   my $s = shift;
   my $m = shift || 'm';
   my $f;
   $s->{'m'}->{key} = [];
   $s->{'m'}->{item} = [];
   my $dbh = $s->dbh;
   my $sth = $dbh->prepare($s->desc_param($m));
   $sth->execute();
   my $flag = 0;
   while(my $ref = $sth->fetchrow_hashref()){
        if($s->const->{data_source} =~ /^dbi:sqlite/i ){
            $f = $ref->{name};
            $s->{'m'}->{$f}->{Type} = $ref->{type}|| 'varchar';
            $s->{'m'}->{$f}->{Null} = $ref->{notnull}?'NO':'YES';
            $s->{'m'}->{$f}->{Key} = $ref->{pk}?'PRI':'';
            $s->{'m'}->{$f}->{Default} = $ref->{dflt_value};
            $s->{'m'}->{$f}->{Extra} = '';
            $s->{'m'}->{$f}->{Size} = $s->size($ref->{type});
        }else{
            $f = $ref->{Field};
            $s->{'m'}->{$f}->{Type} = $ref->{Type};
            $s->{'m'}->{$f}->{Null} = $ref->{Null};
            $s->{'m'}->{$f}->{Key} = $ref->{Key};
            $s->{'m'}->{$f}->{Default} = $ref->{Default};
            $s->{'m'}->{$f}->{Extra} = $ref->{Extra};
            $s->{'m'}->{$f}->{Size} = $s->size($ref->{Type});
        }
        if($s->{'m'}->{$f}->{Key} eq 'PRI'){
            push @{$s->{'m'}->{key}},$f;
        }elsif($s->{'m'}->{$f}->{Type} =~ /timestamp/){
            $s->{'m'}->{timestamp} = $f;
        }else{  push @{$s->{'m'}->{item}},$f;
        }
        $flag = 1;
    }
    $sth->finish();
    return $s->{'m'};
}
sub desc_param{
    my $s = shift;
    my $m = shift;
    if($s->const->{data_source} =~ /^dbi:sqlite/i ){
        return "pragma table_info($m)";
    }else{
        return "desc " . "$m";
    }
}
#---------------------------------------------------------------#
sub size{
#---------------------------------------------------------------#

=head2 size 項目桁数取得

        フィールドタイプより桁数を計算する

=over 2

=item C<$ret = $mmt->size($ref->{Type})>

        $ref->{Type}: データベースより取得したフィールドのタイプ
        $ret: フィールドタイプより計算した項目の桁数を返す

=back

=cut

    my $s = shift;
    my $type = shift;
    my ($t1,$t2,$t3);
    if($type =~ /\w+\((\d+)\,{0,1}(\d{0,1})\)/){
        $t1 = $1;
    }else{
        $t1 = 20;
    }
    $t1++ if($2);
    $t1++ if($s->type_numeric2($type));
    if($type eq 'date'){
        $t1 = 10;
    }elsif($type eq 'time'){
        $t1 = 8;
    }elsif($type eq 'datetime'){
        $t1 = 20;
    }
    return $t1;
}
#---------------------------------------------------------------#
sub type_numeric{
#---------------------------------------------------------------#

=head2 type_numeric

        フィールドタイプが数値項目かチェックする

=cut

    my $s = shift;
    my $f = shift;
    return($s->type_numeric2($s->{'m'}->{$f}->{Type}));
}
#---------------------------------------------------------------#
sub type_numeric2{
#---------------------------------------------------------------#

=head2 type_numeric2

        フィールドタイプが数値項目かチェックする

=cut

    my $s = shift;
    my $type = shift;
    return($type =~ /(numeric|int|deci|double|float|real)/);
}

sub desc{
  my $self = shift;
  my $table = shift;
  return "<pre>" . 
         Dumper ($self->dbh->selectall_arrayref("desc $table",+{Slice => +{}}));
         "</pre>"
}

#------------------------------------------------------------------
sub random_str{
#------------------------------------------------------------------

=head2 ランダム文字列作成 [random_str]

=over 2

ランダムな文字列を作成する(WEB POWERのstdio.plより参照)

=item C<$text = ramdom_str(-length,-str)>

 -length: 作成文字数 デフォルト８文字
 -str: ランダム文字構成文字種 デフォルト(A..Z,a..z,0-9)
 $text: 作成文字列 $str内の文字を$length個の文字列を作成

=back

=cut 

    my $self = shift;
    my %arg = (-length =>8,
                        -str => (join '',('A'..'Z','a'..'z','0'..'9')),
                         @_);
    my @str = split //,$arg{'-str'};
    my $str = "";
    for(1 .. $arg{'-length'}){$str .= $str[int rand($#str+1)];}
    return $str;
}

#------------------------------------------------------------------
sub csv_split{
#------------------------------------------------------------------

=head2 csv形式の行を分割する [csv_split]

=over 2

=item @values csv_split($text)

=back

=cut

    my $s = shift;
    my $text = shift;
    $text =~ s/(?:\x0D\x0A|[\x0D\x0A])?$/,/;
    return map {/^"(.*)"$/ ? scalar($_ = $1, s/""/"/g, $_) : $_}
                ($text =~ /("[^"]*(?:""[^"]*)*"|[^,]*),/g);
}

sub hello{
  my $self = shift;
  return 'My name is Webdb';
}

sub show_tables{
    my $s = shift;
    my $dbh = $s->dbh;
    my $sth = $dbh->prepare("show tables");
    $sth->execute();
    return $sth;
}

1;

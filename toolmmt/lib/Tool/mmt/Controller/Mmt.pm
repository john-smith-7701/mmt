package Tool::mmt::Controller::Mmt;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Log;
use utf8;
use Encode;

has 'mmtForm' => 'mmt/mainform';
has 'mmtDataList' => 'mmt/datalist';

# This action will render a template
sub mainform {
    my $self = shift;

    $self->_init_set();
    $self->{'m'} = $self->app->model->webdb->desc_table($self->param('_table'));
    $self->{'m'}->{'table'} = $self->param('_table');
    $self->set_input_names();
    $self->action_set();
    $self->look_up_set();
    if(defined($self->param('_action')) && $self->param('_action') eq 'get_name'){
        return $self->get_name();
    }
    if(defined($self->param('_action')) && $self->param('_action') eq 'subwin'){
        return $self->subwin();
    }

    $self->my_render($self->mmtForm);
}
sub _init_set{
    my $s = shift;
    $s->param('_focus','key0');
    $s->init_set();
}
sub init_set {
    my $s = shift;
}
sub look_up_set{
    my $s = shift;
}
sub my_render{
    my $s = shift;
    my $render = shift;
    $s->stash->{_title} = $s->param('_table');
    $s->render($render);
}
sub make_sidebar{
    my $s = shift;
    my $table_list = '<h4>TABLES</h4><ul>';
    my $tables;
    if ($s->app->model->webdb->const->{data_source} =~ /^dbi:sqlite/i ){
        $tables = $s->app->model->webdb->dbh->selectall_arrayref(
            'select name from sqlite_master where type="table"');
    }else{
        $tables = $s->app->model->webdb->dbh->selectall_arrayref('show tables');
    }
    $table_list .= join "\n",map {qq{<li><a href="/mmt/$_->[0]">$_->[0]</a></li>}} grep { $_->[0] !~ /user/ } @$tables;
    $table_list .= '</ul>';
    return $s->app->model->webdb->const->{sidebar} . $table_list;
}
sub make_drop_down_menu{
    my $s = shift;
    my $text = '';
    $text = <<END_MENU;
<ul class="main-menu">
    <li>
    <a href="#">@{[$s->param('nick')]}</a>
        <ul class="sub-menu">
            <li><a href=/menu/menu>TOP_MENU</a></li>
            <li><a href=./logout>logout</a></li>
            <li><a href="#">@{[$s->param('user')]}</a>
                <ul class="sub-menu">
                    <li><a href=/menu/changepassword>パスワード変更</a></li>
                    <li><a href=/mmtx/userinfo>情報修正</a></li>
                    <li><a href=/menu/calendar?mode=schedule>スケジュール</a></li>
                    <li><a href="#">・・・</a></li>
                </ul>
            </li>
            <hr>
            <li><a href="http://park15.wakwak.com/~k-lovely/cgi-bin/wiki/wiki.cgi?page=memo">終了</a></li>
        </ul>
    </li>
    <li>
    <a href="#">DUMY</a>
    </li>
</ul>
END_MENU
    return $text;
}
sub make_drop_down_js{
    my $s = shift;
    my $text = '';
    $text = <<"End_Script";
<script type="text/javascript">
\$(function() {
    \$("ul.main-menu li").hover(function() {
        \$(this).children('ul').show();
    }, function() {
        \$(this).children('ul').hide();
    });
});
</script>

End_Script
    return $text;
}
sub registry{
   my $self = shift;

   $self->_init_set();
   $self->action_set();
   #my $log = Mojo::Log->new();
   #$log->debug( "IN registry" );

   for my $action  (@{$self->{'_action'}}) {
       if($action->{'name'} eq $self->param('_action')){
           return $action->{action}();
       }
   }
   $self->stash->{'_dumper'} = $self->dumper ($self->param()) .
       $self->param('_action');
   $self->render('mmt/dumper');
}
#---------------------------------------------------------------#
sub type_numeric{
#---------------------------------------------------------------#

=head2 type_numeric

        フィールドタイプが数値項目かチェックする

=cut

    my $s = shift;
    my $f = shift;
    return($s->app->model->webdb->type_numeric2($s->{'m'}->{$f}->{Type}));
}

sub numeric_chk2{
    my $s = shift;
    my $k = shift;
    my $i = shift;
    my $ii = shift || 0;
    $s->{'m'}->{$s->{'m'}->{$k}[$i]}->{Type} =~ /\((\d+)\,?(\d)?\)/;
    my $n = $1-$2 ; 
    my $n2 = $2;
    my @tmp = $s->param("$k$i");
    return ($tmp[$ii] =~ /^[+-]{0,1}\d{0,$n}\.{0,1}\d{0,$n2}$/);
}
#---------------------------------------------------------------#
sub numeric_chk{
#---------------------------------------------------------------#

=head2 numeric_chk

        データ内容がが数値かチェックする

=cut

        my $s = shift;
    my $num = shift;
    return ($num =~ /^[+-]{0,1}\d+\.{0,1}\d*$/);
}
#---------------------------------------------------------------#
sub type_date{
#---------------------------------------------------------------#

=head2 type_date

        フィールドタイプが日付項目かチェックする

=cut

        my $s = shift;
    my $f = shift;
    return($s->{'m'}->{$f}->{Type} =~ /^date$/);
}

sub labels{
    my $s = shift;
    my @array = @_;
    for(@array){
        $_ = $s->Label($_);
    }
    return @array;
}
sub Label{
    my $s = shift;
    my $tmp = shift;
    return ($s->{'m'}->{label}->{$tmp}) ? $s->{'m'}->{label}->{$tmp} : $tmp ;
}

sub action_set{
    my $s = shift;
    push (@{$s->{_action}},{name=>'参照',action=>sub {$s->data_get()}});  
    push (@{$s->{_action}},{name=>'登録',action=>sub {$s->data_insert()}});
    push (@{$s->{_action}},{name=>'更新',action=>sub {$s->data_update()}});
    push (@{$s->{_action}},{name=>'削除',action=>sub {$s->data_delete()}});
    push (@{$s->{_action}},{name=>'検索',action=>sub {$s->data_serch()}});
    push (@{$s->{_action}},{name=>'Upload',action=>sub {$s->upload_upd()}});
    push (@{$s->{_action}},{name=>'CSV',action=>sub {$s->csv_out()}});
    push (@{$s->{_action}},{name=>'JSON',action=>sub {$s->json_out()}});
    push (@{$s->{_action}},{name=>'一覧表',action=>sub {$s->list_out()}});
}
sub set_table_info{
    my $s = shift;
    $s->{'m'} = $s->app->model->webdb->desc_table($s->param('_table'));
    $s->{'m'}->{'table'} = $s->param('_table');
    $s->set_input_names();
    $s->look_up_set();

}
#------------------------------------------------------------------#
sub serch_input_field_append{
    my $s = shift;
    my $i = shift;
    return if($i !~ /^[1-9]$/);
    my $text = $s->select_field('AndOr_0'=>['','AND','OR']) . $s->serch_input_field();
    return join('<br>',map{$text =~ s/_\d/_$_/g;$text} (1 .. $i));
}
sub serch_input_field{
    my $s = shift;
    my @item_list = (@{$s->{m}->{key}},@{$s->{m}->{item}});

    return  $s->select_field('<serch_item_0>'=>
                [map{[$s->Label($_),$_]} @item_list]) .
            $s->select_field('<serch_op_0>' =>
            [qw(like = <> <= < > >= between regexp)]) .
        $s->text_field('<serch_value_0>');
}
#------------------------------------------------------------------#
sub input_field{
#------------------------------------------------------------------#
	my $s = shift;
	my $name = shift;
	my $j = shift || 0;
	my $style = 'text-align: left';
	my $addComma = ';';
	if($s->type_numeric($name)){
		$style = 'text-align: right';
	}
	if(grep {$s->{'n'}->{$name} eq $_} @{$s->{'m'}->{editA5}}){
		$addComma = "this.value=addComma(this.value)";
	}
	if(grep {$s->{'n'}->{$name} eq $_} @{$s->{'m'}->{editF1}}){
		$addComma = "this.value=edit_F1(this.value)";
	}
	if($s->{'m'}->{$name}->{Type} eq 'text'){
		return $s->text_area($s->{'n'}->{$name},
            id => $s->{'n'}->{$name},
            rows=>5,cols=>30);
	}elsif($s->{'m'}->{$name}->{Type} =~ /enum\((.*)\)/){
		return $s->select_field($s->{'n'}->{$name},
			=> [map {s/'//g;$_} split /,/,$1]);
	}else{	return $s->text_field($s->{'n'}->{$name},
            id => $s->{'n'}->{$name},
            #size=>int($s->{'m'}->{$name}->{Size}*1.3)+1,
            #size=>'100%',
            style=>$style);
	}
}
sub disp_field{
	my $s = shift;
	my $name = shift;
	my $style = 'text-align: left';
	my $override = 0;
	if($s->type_numeric($name)){
		$style = 'text-align: right';
	}
	if($s->param('_action') eq $s->{msg}->{action}->[6] or
		$s->param('_action') eq "get"){
		$override = 1;
		$s->param($name,$s->{'m'}->{ref}->{$name});
	}
	return $s->text_field("$name",
			size=>int($s->{'m'}->{$name}->{Size}*1.3)+1
	);
}
sub get_explan{
    my ($s,$table,$item) = @_;
    return $s->app->model->webdb->const->{explan}->{$table}->{$item} || '';
}    
#---------------------------------------------------------------#
sub csv_out{
#---------------------------------------------------------------#
    my $s = shift;
    $s->data_serch_select();

    my $content =  "";

    my @name = (@{$s->{'sth'}->{'NAME'}});
    if ($s->app->model->webdb->const->{data_source} =~ /^dbi:sqlite/i ){
        $content = encode('shift_jis',join (",",map {'"' . $s->Label($_) . '"'} @name));
    }else{
        $content = encode('shift_jis',decode_utf8(join (",",map {'"' . $s->Label($_) . '"'} @name)));
    }
    $content .= "\n";
    while ( my $ref = $s->{'sth'}->fetchrow_arrayref()) {
        $content .= encode('shift_jis',join (",",map {s/(["])/"$1/g ;'"' .  $_ . '"'} @{$ref}));
        $content .= "\n";
    }
  
    # HTTP Headers
    my $headers = $s->res->headers;
    $headers->content_disposition("attachment; filename=" . encode('shift_jis',$s->param('_table')) . ".csv");
    $headers->content_type('text/csv;charset=Shift_JIS');
  
    # Render data
    return $s->render(data => $content);

}
#---------------------------------------------------------------#
sub json_out{
#---------------------------------------------------------------#
    my $s = shift;
    $s->data_serch_select();
    my $data = $s->{'sth'}->fetchall_arrayref({});
    my $data2;
    if ($s->app->model->webdb->const->{data_source} =~ /^dbi:sqlite/i ){
        $data2 = $data;
    }else{
        for my $rec (@$data){
            my $new_rec = {};
            for my $key (keys %$rec){
              $new_rec->{decode_utf8($key)} = $rec->{$key};
            }
            push(@{$data2},$new_rec);
        }
    }


    $s->{'sth'}->finish;
    $s->render(json => $data2);

}
#---------------------------------------------------------------#
sub list_out{
#---------------------------------------------------------------#
    my $s = shift;
    my $url=$s->url_for("/rwt/rwt");
    my @ret = $s->data_serch_select();
    my $sql = $s->param_set(@ret);
    $s->redirect_to($url->query(
            table=>$s->param('_table'),
            sql=>$sql));
}
sub param_set{
    my $s = shift;
    my $sql = shift;
    for(@_){
        $sql =~ s/\s\?/ '$_'/;
    }
    return $sql;
}
#---------------------------------------------------------------#
sub data_serch{
#---------------------------------------------------------------#

=head2 data_serch データ検索処理

        検索ボタン投下後の処理でテーブル内容を一覧表示する。

=cut

    my $s = shift;
    $s->data_serch_select();

    $s->my_render($s->mmtDataList);
}
sub data_serch_select{
    my $s = shift;
    $s->set_table_info();
    my $dbh = $s->app->model->webdb->dbh;
    my $sql = "select * from @{[$s->param('_table')]} where ";
    my @p = ();
    for (0 .. 5){
        next if($_ != 0 and $s->param("AndOr_$_") eq "");
        $sql .= qq( @{[$s->param("AndOr_$_")]} ) if($_ != 0);
        my @param = $s->param("<serch_value_$_>");
        $sql .= qq( @{[$s->param("<serch_item_$_>")]} @{[$s->param("<serch_op_$_>")]} ? ); 
        if($s->param("<serch_op_$_>") eq 'between'){
            $sql .= " and ? ";
            @param = split ",",$s->param("<serch_value_$_>");
        }
        if($s->param("<serch_op_$_>") eq 'like'){
            $param[0] = "%" . $param[0] . "%";
        }
        push @p,@param;
    }
    #my $log = Mojo::Log->new();
    #$log->debug( $sql);
    $s->{'sth'} = $dbh->prepare($sql);
    $s->{'sth'}->execute(@p);
    return $sql,@p;
}
#---------------------------------------------------------------#
sub data_get{
#---------------------------------------------------------------#

=head2 data_get データ読込処理

        読込ボタン投下後のでKEY項目入力内容にてテーブルを参照する。

=cut

    my $s = shift;
    $s->{errorflag} = 0;
    $s->set_table_info();
    my $dbh = $s->app->model->webdb->dbh;

    $s->{sql} = "select m.* from $s->{'m'}->{table} m " . $s->where();
    my $sth = $dbh->prepare($s->{sql});
    $sth->execute(@{$s->{'m'}->{where}});
    $s->{_itemcount} = 0;
    my $ref = $sth->fetchrow_hashref();
    if($ref){
        for(0..$#{$s->{'m'}->{key}}){
            $s->param("key$_",$ref->{$s->my_encode("utf8",$s->{'m'}->{key}[$_])});
        }
        $s->{_itemcount}++;
        $s->param('_focus','item0');
    }else{  $s->{errstr} = "未登録です";
        $s->{errorflag} = 1;
        $s->itemClear();
    }
    if($s->{errorflag} == 0){
        for(0..$#{$s->{'m'}->{item}}){
            $s->param("item$_",$ref->{$s->my_encode("utf8",$s->{'m'}->{item}[$_])});
        }
    }
    if(defined $s->{'m'}->{timestamp}){
        $s->param("timestamp",$ref->{$s->{'m'}->{timestamp}});
    }
    $s->{'m'}->{ref} = $ref;
    if($s->{errorflag} == 0){
        while($ref = $sth->fetchrow_hashref()){
            for(0..$#{$s->{'m'}->{item}}){
                $s->stash->("item$_") = $ref->{$s->{'m'}->{item}[$_]};
            }
            $s->{_itemcount}++;
        }
    }
    $s->GET_AF_CHECK();

    $s->my_render($s->mmtForm);
}
sub my_encode{
    my $s = shift;
    my $enc = shift;
    my $data = shift;
    if ($s->app->model->webdb->const->{data_source} =~ /^dbi:sqlite/i ){
        return $data;
    }else{
        return encode($enc,$data);
    }
}
 
sub GET_AF_CHECK(){
    my $s = shift;
}#---------------------------------------------------------------#
sub data_insert{
#---------------------------------------------------------------#

=head2 data_insert データ追加処理

        登録ボタン投下後の処理で入力データを追加登録する。

=cut

        my $s = shift;
    $s->set_table_info();
    $s->_data_insert(0);
}
sub _data_insert{
    my $s = shift;
    my $i = shift;
    my $dbh = $s->app->model->webdb->dbh;
    $s->{sql} = "insert into $s->{'m'}->{table} (";
    $s->{sql} .= join(",",@{$s->{'m'}->{key}},@{$s->{'m'}->{item}});
    $s->{sql} .= ") values(";
    my $cnt = @{$s->{'m'}->{key}}+@{$s->{'m'}->{item}};
    my $tmp = "?," x $cnt;
    $tmp =~ s/,$//;
    $s->{sql} .= $tmp .")";
    $s->{'m'}->{where} = [];
    for (0..$#{$s->{'m'}->{key}}){
        push @{$s->{'m'}->{where}},$s->param("key$_");
    }
    for (0..$#{$s->{'m'}->{item}}){
        push @{$s->{'m'}->{where}},
             (@{[$s->param("item$_")]}[$i]||
              $s->param("item$_"));
    }
    $s->INSERT_SUB;
    my $sth = $dbh->prepare($s->{sql});
    my $ret;
    eval {
        $ret = $sth->execute(@{$s->{'m'}->{where}});
    };
    if($@){
        $s->{errstr} = $s->err_str($sth->errstr) ;
    }else{
        $s->{errstr} =  "登録しました";
    }
    if($s->param('key0') eq ''){
        $s->{next} = $s->{home_p}||"item0";
    }else{  $s->{next} = $s->{home_p}||"key0";
    }

    $s->my_render($s->mmtForm);
}
sub err_str{
    my $s = shift;
    return shift;
}
#---------------------------------------------------------------#
sub INSERT_SUB{
#---------------------------------------------------------------#

=head2 INSERT_SUB 登録前処理

        DATAがINSERTされる直前のルーチンです。何か処理がある時には
        オーバーライドして下さい。

=cut

}
#---------------------------------------------------------------#
sub data_update{
#---------------------------------------------------------------#

=head2 data_update データ更新処理

        修正ボタン投下後の処理で入力データを修正する。

=cut

    my $s = shift;
    $s->set_table_info();
    $s->_data_update(0);
}
sub _data_update{
    my $s = shift;
    my $i = shift||0;
    my $dbh = $s->app->model->webdb->dbh;
    $s->{sql} = "update $s->{'m'}->{table} set ";
    for(@{$s->{'m'}->{item}}){
        $s->{sql} .= "$_ = ?,";
    }
    $s->{sql} =~ s/,$/ /;
    $s->{sql} .= $s->where();
    $s->{'m'}->{where} = [];
    for (0..$#{$s->{'m'}->{item}}){
        push @{$s->{'m'}->{where}},
             (@{[$s->param("item$_")]}[$i]||
              $s->param("item$_"));
    }
    for (0..$#{$s->{'m'}->{key}}){
        push @{$s->{'m'}->{where}},$s->param("key$_");
    }
    if(defined $s->{'m'}->{timestamp}){
        $s->{sql} .= " and $s->{'m'}->{timestamp} = ? ";
        push @{$s->{'m'}->{where}},$s->param("timestamp");
    }
    $s->UPDATE_SUB;
    my $sth = $dbh->prepare($s->{sql});
    my $ret;
    eval {
        $ret = $sth->execute(@{$s->{'m'}->{where}});
    };
    if($@){
        $s->{errstr} = $sth->errstr ;
    }else{
        $s->{errstr} =  "修正しました";
    }
    if ($ret < 1){ $s->{errstr} .=
        "修正データありません（キー項目修正しましたか？または他のユーザーに修正された可能性が有ります。もう１度読み込んでください。）";}
    $s->{next} = $s->{home_p}||"key0";

    $s->my_render($s->mmtForm);
}
#---------------------------------------------------------------#
sub where {
#---------------------------------------------------------------#

=head2 where

        KEY項目入力内容にてテーブルを参照する条件を組み立てる。

=cut

    my $s = shift;
    my $tmp = "where ";
    $s->{'m'}->{where} = [];
    for (0..$#{$s->{'m'}->{key}}){
        $tmp .= $s->{'m'}->{key}[$_] . " = ? and ";
        push @{$s->{'m'}->{where}},$s->param("key$_");
    }
    $tmp =~ s/and $/ /;
    $tmp .= $s->{orderby}|| '';
    return $tmp;
}
sub itemClear{
    my $s = shift;
    for(0..$#{$s->{'m'}->{item}}){
        $s->param("item$_",'');
    }
}
#---------------------------------------------------------------#
sub UPDATE_SUB{
#---------------------------------------------------------------#

=head2 UPDATE_SUB 更新前処理

        DATAがUPDATEされる直前のルーチンです。何か処理がある時には
        オーバーライドして下さい。

=cut

}
#---------------------------------------------------------------#
sub data_delete{
#---------------------------------------------------------------#

=head2 data_delete データ削除処理

        削除ボタン投下後の処理で入力データを削除する。

=cut

        my $s = shift;
    $s->set_table_info();
    my $dbh = $s->app->model->webdb->dbh;
    $s->{sql} = "delete from $s->{'m'}->{table} ";
    $s->{sql} .= $s->where();
    $s->DELETE_SUB;
    my $sth = $dbh->prepare($s->{sql});
    my $ret;
    eval {
        $ret = $sth->execute(@{$s->{'m'}->{where}});
    };
    if($@){
        $s->{errstr} = $sth->errstr;
    }else{
        $s->{errstr} = "削除しました";
    }
    if ($ret < 1){ $s->{errstr} =
        "削除データありません（キー項目修正しましたか？または他のユーザーに修正された可能性が有ります。もう１度読み込んでください。）";}
    $s->{next} = $s->{home_p}||"key0";

    $s->my_render($s->mmtForm);
}
#---------------------------------------------------------------#
sub DELETE_SUB{
#---------------------------------------------------------------#

=head2 DELETE_SUB 削除前処理

        DATAがDELETEされる直前のルーチンです。何か処理がある時には
        オーバーライドして下さい。

=cut

}
#---------------------------------------------------------------#
sub AFTER_PROC{
#---------------------------------------------------------------#

=head2 AFTER_PROC 更新処理後ルーチン

        登録、修正、削除の各々の処理後に処理されるルーチン

=cut

}
sub set_input_names{
    my $s = shift;
    $s->{'n'} = $s->input_names();
}
sub get_input_name{
    my $s = shift;
    my $input_name = shift;
    my @name = grep {$s->{'n'}->{$_} eq $input_name;} keys %{$s->{'n'}};
    return $name[0];
} 
#---------------------------------------------------------------#
sub input_names{
#---------------------------------------------------------------#

=head2 input_names 入力フィールド名読み出し

        入力フィールド名のhashを返す

=cut

    my $s = shift;
    my $n = {};
    for(0..$#{$s->{'m'}->{key}}){
        $n->{$s->{'m'}->{key}[$_]} = "key$_";
    }
    for(0..$#{$s->{'m'}->{item}}){
        $n->{$s->{'m'}->{item}[$_]} = "item$_";
    }
    return $n;
}
#---------------------------------------------------------------#
sub upload_upd{
#---------------------------------------------------------------#
    my $s        = shift;
    my $upload   = $s->param('upload_file');
    my $filename = $upload->filename;
    my $string = Encode::decode("Shift_JIS",$upload->slurp);
    my (@title,@data);
    my $line = 0;
    my ($sql,$sql2);
    my ($key,$item);
    my $error_flag = 0;
    my $errstr ;
    my $dbh = $s->app->model->webdb->dbh;
    my $count = 0;
    my $count2 = 0;
    $s->set_table_info();
    for (split /\n/,$string){
        next if(/^$/);
        s/\x0D//;
        s/\x0A//;
        $line++;
        if($filename =~ /.csv$/i){
            @data = $s->app->model->webdb->csv_split($_);
        }else{  @data = split '\t',$_;
        }
        if ( $line == 1 ) {
            @title = @data;
            ($sql,$sql2,$key,$item) = $s->make_upload_sql(@title);
            unless(defined $key->[0]){
                $errstr = "キー項目がありません";
                $error_flag = 1;
            }
            if((@$key - 1) != $#{$s->{m}->{key}}){
                $errstr =  "キー項目の個数が違います";
                $error_flag = 1;
            }
            next;
        }
        if($error_flag == 0){
            if($s->param('_truncate_') eq 'on'){
                $dbh->do("truncate table $s->{m}->{table}");
            }
            my $sth = $dbh->prepare($sql);
            my $sth2 = $dbh->prepare($sql2);
            my @prepare;
            my $ret;
            @prepare = ();
            if($#data != $#title){
                $errstr .=  "[$line] Error Skip" . join ",",@data ;
                next ;
            }
            push @prepare,map{$data[$_]} @$item,@$key;
            if(($ret = $sth->execute(@prepare)) < 1){
                $ret = $sth2->execute(@prepare);
                $count2 += $ret;
            }else{  $count += $ret;}
        }

    }
    $errstr .= " IN:${line} UPDATE:${count} INSERT:${count2}";
    $s->{errstr} = $errstr;
    $s->my_render($s->mmtForm);
}

sub make_upload_sql{
    my $s = shift;
    my @title = @_;
    my (@key,@item);
    my ($sql,$sql2);
    for my $i (0..$#title){
        if(grep {$title[$i] eq $_} @{$s->{m}->{key}}){
            push @key,$i;
        }elsif(grep {$title[$i] eq $_} @{$s->{m}->{item}}){
            push @item,$i;
        }else{
        }
    }
    $sql = "update " . $s->{'m'}->{table} . " set ";
    $sql .= join ',',map {"$title[$_] = ?"} @item ;
    $sql .= " where ";
    $sql .= join ' and ',map {"$title[$_] = ?"} @key ;
    $sql2 = "insert into " . $s->{'m'}->{table} ."(";
    $sql2 .= join ',',map {"$title[$_]"} @item,@key;
    $sql2 .= ") values (";
    $sql2 .= join ",",map {'?'} @item,@key;
    $sql2 .= ")";
    return ($sql,$sql2,\@key,\@item);
}

sub make_ajax{
    my $s = shift;
    my $p = '';
    my $onload = '';
    #
    # マスタ参照ajax(LOOK_UPをサーチ)
    #
    for (keys %{$s->{'m'}->{LOOK_UP}->{ref $s}}){
        next unless ($_ =~ /^(\D)+(\d)+$/);
        $p .= $s->new_updater($_);
        $onload .= "\$('#$_').change();\n";
    }
    #
    # マスタ参照ウインド(WUBWINをサーチ)
    #
    for (keys %{$s->{'m'}->{SUBWIN}->{ref $s}}){
        next unless ($_ =~ /^(\D)+(\d)+$/);
        $p .= $s->new_subwin($_);
    }
    return $p . $onload;
}
#
# マスタ参照(http://www21051ue.sakura.ne.jp:3003/mmtx/commodity?_action=get_name&n=item5&p=001&p=002)
#
sub get_name{
    my $s = shift;
    my @names = qw/未登録/;
    #eval {
        @names = $s->app->model->webdb->dbh->selectrow_array(
                    $s->{'m'}->{LOOK_UP}->{ref $s}->{$s->param('n')}->[0],undef,@{$s->every_param('p')});
    #};
    if ($@){
        $s->render(json=>$@);
    } else{
        my $json = {rec=>@names};
        $s->render(json=>$json);        # JSONを描画する
    }
}
sub subwin{
    my $s = shift;
    my $subwin = $s->{'m'}->{SUBWIN}->{ref $s}->{$s->param('n')};
    my $sql = $subwin->[0];
    my $render = $subwin->[2] || 'mmt/subwin';
    my $param = $s->param('p');
    my $dbh = $s->app->model->webdb->dbh;
    $s->{'sth'} = $dbh->prepare($sql);
    $s->{'sth'}->execute(@{$s->every_param('p')});
    $s->stash->{_title} = '検索';
    $s->stash->{_sql} = $sql;
    $s->stash->{_controller} = ref $s;
    $s->render($render);
}
sub new_updater{
    my $s = shift;
    my $n = shift;
    my $p = '"';
    $p .= join '',map{qq{ + "&p=" + \$('#$_').val()}} @{$s->{'m'}->{'LOOK_UP'}->{ref $s}->{$n}->[1]};
    return <<End_Script;
jQuery('#$n').change( function (){                  // 内容が変化した時に実行
    jQuery.ajax({                                   // http通信を行う
     type: 'GET',                                   // 通信種類を指定(GET,POST,PUT,DELETE)
     dataType: 'json',                              // サーバーから返されるデータタイプ
     data: "_action=get_name&n=$n$p ,               // サーバーに送信する値
     success:function(data,textStatus,jqXHR){       // ajax通信が成功した時のajax event
      jQuery('#d_$n').html(data.rec);               // 返値を描画
     return false;
     }
    });
});
End_Script
}
sub new_subwin{
    my $s = shift;
    my $n = shift;
    my $p = '"';
    $p .= join '',map{qq{ + "&p=" +  \$('#$_').val()}} @{$s->{'m'}->{'SUBWIN'}->{ref $s}->{$n}->[1]};
    my $win_para = "width=600,height=500,resizable=yes,scrollbars=yes";
    return <<End_Script;
jQuery(document).ready(function(){                  
    jQuery('#l_$n').html(                           // LABELをボタンに変更する
        "<input type=button value=@{[$s->Label($s->get_input_name($n))]}>");
});

jQuery('#l_$n').click( function (){                 // SUB WINDOWを開く
    window.open("@{[$s->url_for->query(            
                        _action=>'subwin'
                        ,n=>$n
                        )
                  ]}$p,'_blank','$win_para');
    return false;
});
End_Script
}

1;

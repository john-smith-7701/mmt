package Tool::mmt::Controller::Menumnt;
use Mojo::Base 'Tool::mmt::Controller::Json';
use Mojo::JSON qw(decode_json encode_json to_json);
use Encode;
use utf8;

 
sub menu{
    my $s = shift;
    my $data = $s->menu_get();
    $s->param('_focus','menu_ID');
    $s->stash(_data=> $data,_user => $s->param('user'));
    $s->render('menu/menumnt');
}
sub menu_get{
    my $s = shift;
    my $menu = $s->param('menu') || 'START';
    my $sql = <<END_Script;

    select m.*
    from menu_config m 
    left join menu_item a on a.ID = m.menu_ID 
    where m.ID = ? AND
        exists (select 1 from user_group a inner join user_group b on b.groupId = a.groupId and b.id = ? where a.id = m.ID)
     order by m.No
END_Script

    my $dbh = $s->app->model->webdb->dbh;
    my $data = $dbh->selectall_arrayref($sql,+{Slice => +{}},$menu,$s->param('user'));
    return $data;
}
sub getMenuItem {
    my $s = shift;
    my $sql = <<END_Script;
    select m.* from menu_item m order by UPD_TIME desc
END_Script
    my $dbh = $s->app->model->webdb->dbh;
    my $data = $dbh->selectall_arrayref($sql,+{Slice => +{}});
    $s->json_or_jsonp( $s->render_to_string(json => $data));
}
sub getMenuId {
    my $s = shift;
    my $sql = <<END_Script;
    select ID from menu_config group by ID
END_Script
    my $dbh = $s->app->model->webdb->dbh;
    my $data = $dbh->selectall_arrayref($sql,+{Slice => +{}});
    $s->json_or_jsonp( $s->render_to_string(json => $data));
}
sub getMenu{
    my $s = shift;
    my $data = $s->menu_get();
    $s->json_or_jsonp( $s->render_to_string(json => $data));
}
sub insertMenuItem {
    my $s = shift;
    my $sql = <<END_Script;
    insert into menu_item 
        (SEQ_NO,ID,名称,URL,略称,PARAM,権限) values (0,?,?,?,'','','')
END_Script
    my $dbh = $s->app->model->webdb->dbh;
    my $ret = $dbh->do($sql,undef,$s->param('ID'),$s->param('NAME'),$s->param('URL'));
    $s->json_or_jsonp( $s->render_to_string(json => [{return=>$ret}]));

}
sub updateMenuConfig{
    my $s = shift;
    # JSONを受け取る
    my $data = $s->req->json;
    my $updsql = <<END_Script;
    update menu_config set No = ?,名称 = ? where SEQ_NO = ?
END_Script
    my $insertsql = <<END_Script;
    insert menu_config (SEQ_NO,ID,No,メニュー区分,menu_ID,名称,追加パラメータ,memo,権限)
        values (0,?,?,?,?,?,'','','')
END_Script
    my $dbh = $s->app->model->webdb->dbh;
    for my $r (@$data){
        if(exists($r->{'delelist'})){
            if(@{$r->{delelist}}){
                my $keys = join(',',@{$r->{delelist}});
                my $delesql = <<END_Script;
delete from menu_config where SEQ_NO in ($keys)
END_Script
                $dbh->do($delesql);
            }
        }elsif($r->{'seq_no'} != 0){
            $dbh->do($updsql,undef,$r->{'num_data'},$r->{'name'},$r->{'seq_no'});
        }else{
            $dbh->do($insertsql,undef,$r->{'menu'},$r->{'num_data'},($r->{'menu_id'} eq '' ? '':'0010'),$r->{'menu_id'},$r->{'name'});
        }
    }
    $s->json_or_jsonp( $s->render_to_string(json => [{return=>'OK'}]));
}
1;

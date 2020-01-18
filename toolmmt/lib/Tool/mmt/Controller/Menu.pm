 package Tool::mmt::Controller::Menu;
 use Mojo::Base 'Tool::mmt::Controller::Json';

 
 sub menu{
     my $s = shift;
     my $data = $s->menu_get();
     $s->stash(_data=> $data);
 }
 sub menu_get{
     my $s = shift;
     my $menu = $s->param('menu') || 'START';
     my $sql = "select m.No,m.名称 as meisyo,m.メニュー区分 as menukbn,a.URL,a.PARAM from menu_config m left join menu_item a on a.ID = m.menu_ID 
                where m.ID = ? order by m.No";
     my $dbh = $s->app->model->webdb->dbh;
     my $data = $dbh->selectall_arrayref($sql,+{Slice => +{}},$menu);
     return $data;
 }
 
 1;

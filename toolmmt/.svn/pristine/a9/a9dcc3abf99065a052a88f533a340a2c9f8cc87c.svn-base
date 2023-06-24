package Tool::mmt::Controller::Calendar;
use Mojo::Base 'Tool::mmt::Controller::Menu';

sub menu{
    my $s = shift;
    my $m = $s->app->model;
    my $ym = $s->param('ym') || sprintf("%04d%02d%02d",$m->today());
    my $text = $s->panel_content($ym);
    $s->stash(_data => $text);
    $s->render('calendar/menu');
}
 
 1;

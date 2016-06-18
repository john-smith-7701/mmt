package Tool::mmt::Controller::Commodity;
use Mojo::Base 'Tool::mmt::Controller::Mmt';

has 'mmtDataList' => 'mmt/datalist';

sub init_set {
    my $s = shift;
    $s->mmtForm('mmt/mainform');
    $s->param('_table','商品');
}
sub look_up_set{
    my $s = shift;
    $s->{'m'}->{LOOK_UP}->{ref $s}->{$s->{'n'}->{'大分類'}} = 
        ["select 略称 from 分類名称 where 中分類 = '' and 小分類 = '' and 大分類 = ? ", 
            [$s->{'n'}->{'大分類'}] ];
    $s->{'m'}->{SUBWIN}->{ref $s}->{$s->{'n'}->{'大分類'}} = 
        ["select 大分類,略称 from 分類名称 where 中分類 = '' and 小分類 = ''", 
             []];

    $s->{'m'}->{LOOK_UP}->{ref $s}->{$s->{'n'}->{'中分類'}} = 
        ["select 略称 from 分類名称 where 大分類 = ? and 中分類 = ? and 小分類 = '' ", 
            [$s->{'n'}->{'大分類'},$s->{'n'}->{'中分類'}] ];
    $s->{'m'}->{SUBWIN}->{ref $s}->{$s->{'n'}->{'中分類'}} = 
        ["select 中分類,略称 from 分類名称 where 大分類 = ? and 中分類 <> '' and 小分類 = ''", 
            [$s->{'n'}->{'大分類'}] ];

    $s->{'m'}->{LOOK_UP}->{ref $s}->{$s->{'n'}->{'小分類'}} = 
        ["select 略称 from 分類名称 where 大分類 = ? and 中分類 = ? and 小分類 = ? ", 
            [$s->{'n'}->{'大分類'},$s->{'n'}->{'中分類'},$s->{'n'}->{'小分類'}] ];
    $s->{'m'}->{SUBWIN}->{ref $s}->{$s->{'n'}->{'小分類'}} = 
        ["select 小分類,略称 from 分類名称 where 大分類 = ? and 中分類 = ? and 小分類 <> ''", 
            [$s->{'n'}->{'大分類'},$s->{'n'}->{'中分類'}] ];
}

1;

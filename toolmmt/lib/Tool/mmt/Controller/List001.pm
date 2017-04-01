package Tool::mmt::Controller::List001;
use Mojo::Base 'Tool::mmt::Controller::Rwt';
use Encode qw/ decode decode_utf8 encode encode_utf8/;

sub rwt_init {
    my $s = shift;
    $s->column(2);
    $s->bottom_const('<div style="text-align:right;"> Rwt Sample</div>');
    $s->sql(q{select * from 商品 order by 大分類,中分類,小分類,商品コード});
    $s->item_list([qw/大分類 中分類 小分類 商品コード 品名 上代/]); 
    $s->lf_spec->{encode_utf8("大分類")}->{style} = "@{[$s->cell_width(20)]}text-align:center";
    $s->lf_spec->{encode_utf8("中分類")}->{style} = "@{[$s->cell_width(20)]}text-align:center";
    $s->lf_spec->{encode_utf8("小分類")}->{style} = "@{[$s->cell_width(20)]}text-align:center";
    $s->lf_spec->{encode_utf8("商品コード")}->{style} = "@{[$s->cell_width(30)]}text-align:left";
    $s->lf_spec->{encode_utf8("品名")}->{style} = "@{[$s->cell_width(200)]}text-align:left";
    $s->lf_spec->{encode_utf8("上代")}->{style} = "@{[$s->cell_width(80)]}text-align:right";
    $s->lf_spec->{encode_utf8("上代")}->{edit} = [hex("a5"),"%.2f"];
    $s->break_ctl([
                    {level=>10
                    ,_bf=>1
                    ,_af=>0
                    ,key=>encode_utf8("大分類")
                    ,encode_utf8("品名")=>"大計",
                    ,encode_utf8("上代")=>0},
                    {level=>8
                    ,_bf=>1
                    ,_af=>0
                    ,key=>encode_utf8("中分類")
                    ,encode_utf8("品名")=>"中計",
                    ,encode_utf8("上代")=>0},
                    {level=>6
                    ,_bf=>-5
                    ,_af=>0
                    ,key=>encode_utf8("小分類")
                    ,encode_utf8("品名")=>"小計",
                    ,encode_utf8("上代")=>0}
    ]);
}
1;

package Tool::mmt::Controller::List001;
use Mojo::Base 'Tool::mmt::Controller::Rwt';
use Encode qw/ decode decode_utf8 encode encode_utf8/;

sub rwt_init {
    my $s = shift;
    $s->column(3);
    $s->sql(q{select * from 分類名称 where 1 /*where*/ order by 大分類,中分類,小分類});
    $s->item_list([qw/大分類 中分類 小分類 分類名 集計１/]);
    $s->title('分類マスタ');
    $s->lf_spec->{encode_utf8("大分類")}->{style} = "@{[$s->cell_width(30)]}text-align:center";
    $s->lf_spec->{encode_utf8("中分類")}->{style} = "@{[$s->cell_width(30)]}text-align:center";
    $s->lf_spec->{encode_utf8("小分類")}->{style} = "@{[$s->cell_width(30)]}text-align:center";
    $s->lf_spec->{encode_utf8("分類名")}->{style} = "@{[$s->cell_width(120)]}text-align:left";
    $s->lf_spec->{encode_utf8("集計１")}->{style} = "@{[$s->cell_width(60)]}text-align:right";
    $s->lf_spec->{encode_utf8("集計１")}->{edit} = [hex("a5"),"%.2f"];
    $s->break_ctl([
                    {level=>10
                    ,key=>encode_utf8("大分類")
                    ,encode_utf8("分類名")=>"大計",
                    ,encode_utf8("集計１")=>0},
                    {level=>8
                    ,key=>encode_utf8("中分類")
                    ,encode_utf8("分類名")=>"中計",
                    ,encode_utf8("集計１")=>0},
    ]);
}
1;

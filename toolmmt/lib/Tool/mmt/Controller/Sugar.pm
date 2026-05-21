package Tool::mmt::Controller::Sugar;
use Mojo::Base 'Tool::mmt::Controller::Mmt';

my %jp_op = (
    '未満' => '<',
    '以下' => '<=',
    '超える' => '>',
    '以上' => '>=',
    '等しい' => '==',
    '異なる' => '!=',
    'じゃない' => '!=',
    'でない' => '!=',
);
my %jp_logical = (
    'で' => '&&',
    'かつ' => '&&',
    'か' => '||',
    'または' => '||',
);
my $jp_op_re = join '|', map { quotemeta } sort { length($b) <=> length($a) } keys %jp_op;
my $jp_logical_re = join '|', map { quotemeta } sort { length($b) <=> length($a) } keys %jp_logical;

sub convert {
    my ($class,$text) = @_;

    # 全角ASCII → 半角ASCII
    $text =~ s/([！-～])/chr(ord($1)-0xFEE0)/ge;

    # 全角space
    $text =~ tr/　/ /;

    # もし〜なら〜以外は〜
    $text =~ s/
        もし(.+?)(?:なら|の場合|の時|時)(?:は)*(.+?)以外(?:(?:は|で))?
    /
        my ($cond,$true) = ($1,$2);
        $cond = convert_condition($cond);
        "($cond) ? $true : "
    /gex;

    # 単価と数量 → 単価,数量
    $text =~ s/
        ・(.+?)で(.+?)には(.+?);
    /
        my ($args,$func,$proc) = ($1,$2,$3);
        $args =~ s|と|,|g;
        "$func($args) = $proc;"
    /gex;

    return $text;
}
sub convert_condition{
    my $cond = shift;
    my $last_lhs;

    # 全角数字 → 半角数字
    $cond =~ tr/０-９/0-9/;
    $cond =~ s/でない/じゃない/g;

    # 論理演算子で分割（区切り文字も保持）
    my @list = split /($jp_logical_re)/, $cond;

    for (@list){

        # 論理演算子
        if(exists $jp_logical{$_}){
            $_ = $jp_logical{$_};
            next;
        }
        s/
            (?:
                ([^\s]+?)が
            )?
            ([^\s]+?)
            ($jp_op_re)?
        $
        /
            do {
                my ($lhs,$rhs,$op)=($1,$2,$3);
                $lhs = defined $lhs ? $lhs : $last_lhs;
                $last_lhs = $lhs;
                # 数値+単位なら単位除去
                $rhs =~ s|^([0-9\.]+).*$|$1|;
                $op = defined $op ? $jp_op{$op} : '==';
                "$lhs $op $rhs";
            }
        /gex;
    }
    return join ' ', @list;
}


1;

use strict;
my $op = { '-' => [sub {$_[1] - $_[0]},1,'L',2],
           '+' => [sub {$_[1] + $_[0]},1,'L',2],
           '*' => [sub {$_[1] * $_[0]},2,'L',2],
           '/' => [sub {$_[1] / $_[0]},2,'L',2],
           '%' => [sub {$_[1] % $_[0]},2,'L',2],
           'NGE' => [sub {-$_[0]},3,'R',1],
           '**' => [sub {$_[1] ** $_[0]},4,'R',2],
           'x' => [sub {$_[1] * $_[0]},2,'L',2], # 多項式対応？
           '(' => [sub { },0,'L',2],
       };
# 中置記法の引数をスペースで分割し後置記法に変換し計算を行う
print calc(infix_to_postfix(split (/\s+/,adjust(pop))));

 

sub infix_to_postfix{      # 中置記法を後置記法に変換
    my @post = ();                                                     # 後置記法用スタック
    my @opr = ();                                                      # 演算子用のワークスタック
    my $prev = 'START';
    for ('(',@_,')'){                                                  # 中置記法の要素をカッコでくくり（処理を単純にする為）先頭から最後まで処理を行う。
        if ($_ eq ")"){                                                # 要素が閉じカッコの場合
            push @post,pop @opr while( @opr && $opr[-1] ne "(" );      #     開きカッコまで演算子用スタックから要素を取出し後置記法用スタックに積む。
            pop @opr;                                                  #     開きカッコを読み捨てる。
        }elsif(exists $op->{$_}){                                      # 要素が演算子の場合
            my $cur = $_;
            if ($cur eq '-' && ($prev eq 'START' || $prev eq '(' || $prev eq 'OP')) {
                $cur = 'NGE';                                          # 単項マイナスを追加
            }
                                                                       #     要素が開きカッコでなく要素のプライオリティが低い間、
                                                                       #     演算子スタックを取出し後置記法用スタックに積む。
            push @post,pop @opr while($_ ne "(" && @opr && juge_priority($cur,$opr[-1]));
            push @opr,$cur;                                            #     要素を演算子スタックに積む。
            $prev = 'OP';
        }else{                                                         # 要素が演算子以外の場合
            push @post,$_;                                             #     要素を後置記法用スタックに積む。     
            $prev = 'NUM';
        }
    }
    return @post;                                                      # 後置記法用スタックを返却する。
}
sub juge_priority {
    $op->{$_[0]}->[2] eq 'R'
        ?$op->{$_[0]}->[1] <  $op->{$_[1]}->[1]
        :$op->{$_[0]}->[1] <= $op->{$_[1]}->[1];
}
sub calc {                 # 逆ポーランド記法の計算
    my @stack = ();
    #print join(',',@_)."\n";
                                                                       # 1.逆ポーランド記法の要素を先頭から最後まで処理を行う。
                                                                       # 2.要素が演算子の場合にスタックから２つの要素を取出し計算結果をスタックに積む。
                                                                       # 3.要素が演算子でない場合に要素をスタックに積む。
    push @stack,(exists $op->{$_} ?  $op->{$_}->[3] == 1 ? $op->{$_}->[0](pop @stack):$op->{$_}->[0](pop @stack,pop @stack) : $_) for @_;
    return pop @stack;                                                 # スタックから要素を取出し返却する。
}
sub adjust{
    my $text = shift;
    $text =~ s{([\-\+\*\/\%\(\)x])}{ $1 }g;
    $text =~ s{\s+}{ }g;
    $text =~ s{\* \*}{\*\*}g;
    $text =~ s{([\d\)]\s+)\(}{$1 * (}g;    # 多項式対応？
    return $text;
}

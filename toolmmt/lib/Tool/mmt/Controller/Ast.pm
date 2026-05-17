=head1

 NAMETool::mmt::Controller::Ast - 式解析および AST 評価エンジン

=head1 SYNOPSIS

  my $ast = Tool::mmt::Controller::Ast->new;
  my $node = $ast->Astnew('formula'=>'1 + 2 * 3');
  my $val  = $node->{anser};

=head1 DESCRIPTION

文字列で与えられた式を解析し、抽象構文木 (AST) を生成し、
評価結果を返すモジュールです。

四則演算、比較演算子、論理演算子、三項演算子、変数代入、関数呼び出しなどを扱います。

=head1 SUPPORTED OPERATORS

=head2 算術演算子

  +  -  *  /  %

=head2 比較演算子

  ==  !=  >  >=  <  <=

=head2 論理演算子

  &&  ||

=head2 代入演算子

  =
=head2 三項演算子

  ? :

=head1 VARIABLES

変数は識別子名で参照します。

  a = 10;
  b = a + 5;

=head1 RETURN VALUES

評価結果として数値、文字列、真偽値、または内部データ構造を返します。

=head1 ERROR HANDLING

不正な構文、未定義変数、不正な関数呼び出し時は例外または undef を返します。

=head1 EXAMPLES

=head2 四則演算

  1 + 2 * 3結果: 7

=head2 三項演算子

  a ? b : c

=head2 変数代入

  x = 10;
  y = x + 5;

=head1 NOTES

再帰的に AST を評価するため、極端に深いネスト式ではスタック消費に注意してください。

=head1 AUTHOR

John Smith

=head1 LICENSEPrivate

 Use / Internal Tool

=cut

package Tool::mmt::Controller::Ast;
use Mojo::Base 'Tool::mmt::Controller::Mmt';
use Tool::mmt::Controller::Sugar;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use constant {
    LEFT    => 'L',         # 左結合
    RIGHT   => 'R',         # 右結合
    OPERATOR => 0,          # 演算子
    FUNCTION => 0,          # 計算処理定義
    PRIORITY => 1,          # 優先順位
    ASSOCIATIVE => 2,       # 結合性
    OPTION  => 3,           #
    UNARY   => 1,           # 単項演算子
    ASSIN   => 2,           # 代入演算子
    VAR_NAME  => qr/[\p{L}_][\p{L}\p{N}_]*/u,  # 変数名 
};

my $op = +{     # オペレータ定義
           ';'   => [sub { $_[2]},          10,'L',0],
           '||'  => [sub {$_[1] || $_[2]},  20,'L',0],
           '&&'  => [sub {$_[1] && $_[2]},  30,'L',0],
           '?'   => [sub { },               55,'R',0],
           ':'   => [sub { },               55,'R',0],
           '='   => [sub {$_[0]->setValue('',$_[1],$_[2])},
                                            50,'R',2],
           ':='   => [sub {$_[0]->setValue('global',$_[1],$_[2])},
                                            50,'R',2],
           '<='  => [sub {$_[1] <= $_[2]},  60,'L',0],
           '>='  => [sub {$_[1] >= $_[2]},  60,'L',0],
           '>'   => [sub {$_[1] >  $_[2]},  60,'L',0],
           '<'   => [sub {$_[1] <  $_[2]},  60,'L',0],
           '=='  => [sub {$_[1] == $_[2]},  60,'L',0],
           '!='  => [sub {$_[1] != $_[2]},  60,'L',0],
            '-'  => [sub {$_[1] - $_[2]},   70,'L',0],
           '+'   => [sub {$_[1] + $_[2]},   70,'L',0],
           '*'   => [sub {$_[1] * $_[2]},   80,'L',0],
           '/'   => [sub {$_[2]?
                            $_[1] / $_[2]
                            :$_[0]->_error("Zero divied!!")},
                                            80,'L',0],
           '%'   => [sub {$_[2]?
                            $_[1] % $_[2]
                            :$_[0]->_error("Zero divied!!")},
                                            80,'L',0],
           'NGE' => [sub { -$_[1]},         90,'R',1],
           '!'   => [sub { $_[1] ? 0 : 1},  90,'R',1],
           #perl関数定義 START
           'sqrt'  => [sub { sqrt(($_[0]->split_eval($_[1]))[0])},
                                            90,'R',1],
           'sin'  => [sub { sin(($_[0]->split_eval($_[1]))[0])},
                                            90,'R',1],
           'cos'  => [sub { cos(($_[0]->split_eval($_[1]))[0])},
                                            90,'R',1],
           'uc'  => [sub { uc(($_[0]->split_eval($_[1]))[0])},
                                            90,'R',1],
           'lc'  => [sub { lc(($_[0]->split_eval($_[1]))[0])},
                                            90,'R',1],
           'length'  => 
                    [sub { length(($_[0]->split_eval($_[1]))[0])},
                                            90,'R',1],
           'substr'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                           substr($x[0],$x[1],$x[2])},
                                            90,'R',1],
           'pop'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                           pop($x[0])},
                                            90,'R',1],
           'push'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                           push($x[0],$x[1])},
                                            90,'R',1],
           'shift'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                           shift($x[0])},
                                            90,'R',1],
           'unshift'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                           unshift($x[0],$x[1])},
                                            90,'R',1],
           'join'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                            $_[0]->setLog(join("|",@x));
                            if(@x != 2){                                        # split_evalを再考せねば
                                join(join(',',@x[0..$#x - 1]),@{$x[-1]})        # なさけない！！
                            }else{
                                join($x[0],@{$x[1]})
                            }
                                            },
                                            90,'R',1],
           'keys'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                           \@{[keys($x[0])]}},
                                            90,'R',1],
           'match'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                            my $re = qr/$x[0]/;
                            \@{[$x[1] =~ $re]}},
                                            90,'R',1],
           'replace'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                            my $re = qr/$x[0]/;
                            $x[2] =~ s/$re/$x[1]/;
                            $x[2]},
                                            90,'R',1],
           #perl関数定義 END
           'continue'  => 
                    [sub { die bless {}, 'AST::Continue'; },
                                            90,'R',1],
           'return'  => 
                    [sub { die bless {}, 'AST::Return'; },
                                            90,'R',1],
           'array'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                           $x[0][$x[1]]},
                                            90,'R',1],
           'hash'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                           $x[0]{$x[1]}},
                                            90,'R',1],
           '--_pre'  => 
                    [sub { $_[0]->inc_dec($_[1],'-','pre')},
                                            90,'R',1],
           '++_pre'  => 
                    [sub { $_[0]->inc_dec($_[1],'+','pre')},
                                            90,'R',1],
           '--_post'  => 
                    [sub { $_[0]->inc_dec($_[1],'-','post')},
                                            90,'R',1],
           '++_post'  => 
                    [sub { $_[0]->inc_dec($_[1],'+','post')},
                                            90,'R',1],
           '**'  => [sub {$_[1] ** $_[2]},  90,'R',0],
           '('   => [sub { },               -1,'L',0],
           ')'   => [sub { },               -1,'L',0],
           '['   => [sub { },               -1,'L',0],
           ']'   => [sub { },               -1,'L',0],
           '{'   => [sub { },               -1,'L',0],
           '}'   => [sub { },               -1,'L',0],
           '=>'   => [sub { },               -1,'L',0],
           "x"   => [sub {$_[1] x $_[2]},   80,'L',0],
        };
sub inc_dec{
    my $s = shift;                                              # インクリメント・デクリメント計算
    my ($val,$inc,$pre) = @_;                                   # 引数(変数、加算or減算,前置きor後置き)
    $val =~ s/^\((.*)\)$/$1/;                                   # 外側のカッコを削除
    my $var = exists $s->{global}{$val} ? 'global' : 'vars';    # グローバル変数かローカル変数かを確認
    my $ret = $s->{$var}{$val};                                 # 現在の値を保持（プレフィックス用）
    ($inc eq '+') ? ++$s->{$var}{$val} : --$s->{$var}{$val};    # 加算or減算(inc or dec)
    if($pre eq 'pre'){ $ret = $s->{$var}{$val}};                # プレフィックスの場合は計算後の値を返却
    return $ret;
}
sub ast{
    my $s = shift;
    my $x = $s->Astnew('formula'=>$s->param('calc'));
    $s->stash(anser => $x->{anser});
}
sub _ast{
    my $s = shift;
    $s->{vars} = {};
    $s->{func} = {};
    $s->{count} = 0;
    $s->{const} = [];
    $s->{ret} = 'stack over!';
    $s->{logText} = '';
    # 構文木作成
    $s->{root} = $s->makeTree(@{$s->item_split($s->adjust(shift))->{item}});

    eval {
        local $SIG{ALRM} = sub {
            die bless {}, 'AST::Timeout';
        };
        alarm(5);

        # 構文木計算
        $s->{anser} = $s->readTree($s->{root});

        alarm(0);
    };
    alarm(0);
    if($@){
        die $@;
    }

    # デバック情報出力
    $s->{root}->{vars} = $s->{vars};
    $s->{root}->{text} = $s->{logText};
    #$s->{root}->{global} = $s->{global};
    $s->{root}->{func} = $s->{func};
    $s->{root}->{const} = $s->{const};
    $s->{root}->{LOG} = $s->{global}{LOG};
    $s->stash(tree => Dumper $s->{root});

    return $s->{anser}
}
sub Astnew {                                           # 
    my $s = shift;
    my $x = {@_};
    $s->setReOps();
    $s->_ast($x->{formula}) if (exists $x->{formula});
    return $s;
}
sub setReOps{                                       # 演算子の正規表現作成
    my $s = shift;
    $s->{ops} = join ('|',map {s/(\W)/\\$1/g;$_;} sort {length $b <=> length $a} keys %$op);
    $s->{ops} = "(".$s->{ops}.")";
    return $s;
}

=head2 newNode

 新しいNODEを作成する。オペレータ(data)が"="で左辺値が配列定義で無くHASHの場合はファンクションを定義する。

  newNode(data,left,right)

         data
         /  \
      left  right

=over 4

=item オペレータ

=item 左辺値

=item 右辺値

=cut

sub newNode{
    my $s = shift;
    if($_[0] eq '=' and ref($_[1]) eq 'HASH' and $_[1]->{data} !~ /(array|hash)/){
        $s->makeFunc($_[1],$_[2]);
    }else{
        return {data => shift(),left =>shift(),right=>shift()};
    }
}
=head2 makeFunc

  ユーザー定義関数を定義する。

  makeFunc(leftNode,rigthNode)

=over 4

=item leftNode

  leftNodeのdataにファンクション名を定義、rightに引数の定義

=item rightNode

  rightNodeに処理内容を定義

=cut

sub makeFunc{
    my $s = shift;
    my $name = $_[0]->{data};
    my $data = $_[1];
    $s->{func}{$name} = {args=>$_[0]->{right},body=>$data};
}
sub readTree{                                       # AST計算
    my ($s,$node) = @_;
    return $s->getValue('c',$node) if(ref($node) ne 'HASH');
    if( exists $op->{$node->{data}} && $op->{$node->{data}}->[OPTION] == UNARY ){
        return $op->{$node->{data}}->[FUNCTION]($s,$s->readTree($node->{'right'}));
    }
    if(exists $s->{func}->{$node->{data}}){
        return $s->callFunc($node);
    }
    if($node->{data} eq '?'){
        return $s->readTree($node->{left})
            ? $s->readTree($node->{right}->{left})
            : $s->readTree($node->{right}->{right});
    }
    my $newnode = {};
    do{$newnode->{$_} = ($_ eq 'right' and $node->{data} eq '&&' and ! $newnode->{'left'}) ? 0 : ref($node->{$_}) eq 'HASH' ? $s->readTree($node->{$_}) : $node->{$_};} for ('left','right');
    exists $op->{$node->{data}} ? $op->{$node->{data}}->[OPTION] == ASSIN
                                # 代入処理　右ノードの値を左の変数にセットし結果を返却する
                                ? $op->{$node->{data}}->[FUNCTION]($s,$s->getContainer($node->{left}),
                                                            $s->getValue($node->{data},$newnode->{right}))
                                # 計算実行　左ノードの値と右ノードの値を渡し関数を実行するし結果を返却する
                                : $op->{$node->{data}}->[FUNCTION]($s,$s->getValue($node->{data},$newnode->{left}),
                                                            $s->getValue($node->{data},$newnode->{right}))
                                # 値を返却する
                                : $s->getValue('c',$node->{data});
}
sub getContainer{
    my $s = shift;
    my $container = shift;
    if(ref($container) eq 'HASH'){
        if($container->{data} =~ /(array|hash)/){
            my @x = $s->split_eval($container->{right},',');
            return [$x[0],$x[1]];
        }else{
            return $container;
        }
    }else{
        return $container;
    }
}
sub callFunc{
    my $s = shift;
    my $node = shift;
    return $s->{ret} if($s->{count} > 1000);
    $s->{count}++;
    local $s->{vars} = {%{$s->{vars}}};

    my $args = $s->{func}->{$node->{data}}->{args};
    $args =~ s/^\(//;
    $args =~ s/\)$//;
    my @names = split(',',$args);
    my @args = $s->split_eval($node->{right},',');
    for(@names){
        my $x = shift(@args);
        $x = $s->getValue('',$x);
        $s->{vars}{$_} = $x;
    }
    while(1){
        eval {
            $s->{ret} = $s->readTree($s->{func}->{$node->{data}}->{body});
        };
        next if(ref($@) eq 'AST::Continue');
        last if(ref($@) eq 'AST::Return');
        die $@ if($@);
        last;
    }
    $s->{count}--;
    return $s->{ret};
}
sub topSplit{
    my $s = shift;
    my $sep = shift;
    my $text = shift;
    $text =~ s/^\s*[\[{](.*)[\]}]\s*$/$1/;
    $text = $s->adjust($text);  # 引数形式のカッコ内は１つのトークンととし別で処理するのでカッコ内のスペースを削除する
    my @arr = ();
    my @tmp = split($sep,$text);
    my $depth = 0;
    for(@tmp){
        s/^\s*(.*\S)\s*$/$1/;
        if($depth == 0){
            push(@arr,$_);
            $depth += () = $_ =~ /[\[\{]/g;
        }else{
            $arr[-1] .= ",$_";
            $depth += () = $_ =~ /[\[\{]/g;
            $depth -= () = $_ =~ /[\]\}]/g;
        }
    }
    for(@arr){
        if(/^\s*[\[].*[\]]\s*$/){
            $_ = [$s->topSplit($sep,$_)];
        }elsif(/^\s*[\{].*[\}]\s*$/){
            $_ = {$s->topSplit($sep,$_)};
        }
        $_ =~ s/__STR__\|(\d+)\|__/$s->{const}->[$1]/ge;
        $_ =~ s/^(["'])(.*)\1/$2/;
    }
    @arr;
}
sub split_eval{
    my $s = shift;
    my $text = shift;
    $text =~ s/^\((.*)\)$/$1/;
    $text = $s->adjust($text);  # 引数形式のカッコ内は１つのトークンととし別で処理するのでカッコ内のスペースを削除する
    my @t = split('',$text);
    shift(@t) if($t[0] eq '(');
    pop(@t) if($t[$#t] eq ')');
    my $sep = shift;
    my $st = 0;
    my @array = ();
    my $depth = 0;
    my $i = -1;
    for(@t){
        $i++;
        $depth++ if $_ eq '(';
        $depth-- if $_ eq ')';
        if($_ eq $sep && $depth == 0){
            push(@array,join('',@t[$st .. $i-1]));
            $st = $i+1;
        }
    }
    push(@array,join('',@t[$st .. (@t - 1)]));
    my @ans = ();
    for(@array){
        push(@ans,$s->readTree($s->makeTree(@{$s->item_split($s->adjust($_))->{item}})));
    }
    $s->{ret} .= join('|',@ans) . 'x';
    return @ans;
}
sub getValue{
    my $s = shift;
    my $var = exists $s->{'global'}{$_[1]} ? 'global' : 'vars';
    my $t =  exists $s->{$var}{$_[1]} ? $s->{$var}{$_[1]} 
                                                      : $_[1];
    $t =~ s/__STR__\|(\d+)\|__/$s->{const}->[$1]/ge;
    $t =~ s/^(["'])(.*)\1$/$2/;
    return $t;
}

=head2 setVlue

 変数に値をセットします。

  setValue($scope,$out,$value)

=over 4

=item 変数スコープ

 'global' or 'vars' ローカル変数かグローバル変数かの指定を行う。未設定の場合はグローバル領域に存在すれば'globa'とし以外は'vars'とスコープを切り替える。

=item 受け取り側変数

 [a,1] or b 配列またはスカラを指定します。

=item セットする値

 '[1,2,3]' or 4 配列かスカラで指定します。

=cut

sub setValue{
    my $s = shift;
    my ($scope,$out,$val) = @_;
    my $values = $s->normalize_value($val);
    if(ref($out) eq 'ARRAY'){
        if(ref($out->[0]) eq 'HASH'){
            $out->[0]{$out->[1]} = $values;
        }else{
            $out->[0][$out->[1]] = $values;
        }
    }else{
        if($scope eq ''){
            $scope = exists $s->{'global'}{$out} ? 'global' : 'vars';
        }
        $s->{$scope}{$out} = $values;
    }
}
sub normalize_value{
    my ($s,$val) = @_;
    $val =~ s/(:|=>)/,/g;
    $s->setLog($val);
    $val =~ /^\[.*\]$/  ? [$s->topSplit(',',$val)] :
    $val =~ /^\{.*\}$/  ? +{$s->topSplit(',',$val)}
                        : $val;
}

=head2 makeTree

 計算式の全要素よりASTを組み立てる

 makeTree(item1,item2, ... ,itemN)

 2 + 3 * 4

       +
     /   \
    2     *
        /   \
       3     4

=cut

sub makeTree{                                       # AST組み立て
    my ($s,@tok) = @_;
    @tok = $s->strip_outer(@tok);
    return shift(@tok) if(@tok <= 1);               # 要素が一つの時は要素を返す
    my ($prio,$i,$m,$depth,$twin,$level) = (99,-1,0,0,-1,0);
    for(@tok){                                      # 一番右側の一番プライオリティの低いオペレータを検索
        ++$i;
        my $cur = $_;
        if(/^$s->{ops}$/){
            ++$depth if($_ eq '(');
            --$depth if($_ eq ')');
            next if($depth or $_ eq ')');           #  括弧の間は読み飛ばす
            if($_ eq '-' && ($i == 0 || ($tok[$i - 1] =~ /^$s->{ops}$/ && ($tok[$i - 1] ne ')' && $tok[$i - 1] ne 'x')))){
                $tok[$i] = $cur = 'NGE';
            }
            if($s->judge_priority($cur,$prio)){
                $prio = $op->{$cur}->[PRIORITY];
                $m = $i;
            }
        }
        ++$level if($_ eq '?');                     # 三項演算子の対の？を検索する
        --$level if($_ eq ':');
        $twin = $i if($tok[$m] eq '?' and $_ eq ':' and $twin == -1 and $level == 0);
    }
    $s->_error("Unbalance '()' $depth") if($depth != 0);
    my @right =  $twin != -1 ?                      # 三項演算子の真を括弧で括る
                ('(',@tok[$m+1 .. $twin-1],')',@tok[$twin .. $#tok]) : (@tok[$m+1 .. $#tok]);
    return $s->newNode($tok[$m],                    # オペレータとオペランド（右と左）を返す
                            $s->makeTree(@tok[0 .. $m-1]),
                            $s->makeTree(@right)
                );
}

=head2 strip_outer

 strip_outer(item1,item2, ... ,itemN)

 一番外側の括弧を外す

=cut

sub strip_outer{
    my ($s,@tok) = @_;
    while($tok[0] eq '(' and $tok[-1] eq ')'){
        my ($depth ,$top_open_count) = (0,0);
        for(@tok){                                  # '('の深さを計算
            ++$depth if($_ eq '(');                     
            --$depth if($_ eq ')');
            ++$top_open_count if($depth == 1 and $_ eq '(');
        }
        $s->_error("Unbalance '()' $depth") if($depth != 0);
        if($top_open_count == 1){                   #  一番外側の括弧が１つの時に括弧を外す
            shift @tok; pop @tok;
        }else{
            last;
        }
    }
    return @tok;
}
sub judge_priority {
    my $s = shift;
    $op->{$_[OPERATOR]}->[ASSOCIATIVE] eq RIGHT
        ?$op->{$_[OPERATOR]}->[PRIORITY] <  $_[PRIORITY]
        :$op->{$_[OPERATOR]}->[PRIORITY] <= $_[PRIORITY];
}
sub item_split{                                     # 計算式を要素に分解
    my $s = shift;
    my $text = shift || $s->{_text};
    my @token = ();
    my @tmp = split ' ',$text;
    my $depth = 0;
    for(@tmp){
        if($depth == 0){
            push(@token,$_);
            ++$depth if(/^[\[\{]/);
        }else{
            $token[-1] .= $_;
            ++$depth if(/^[\[\{]/);
            --$depth if(/[\]\}]\s*$/);
        }
    }
    $s->{item} = [@token];
    $s->{logText} .= "[[" . join('|',@token) ."]]";
    return $s;
}
sub adjust{                                         # 入力式の調整（整理）を行う
    my ($s,$text) = @_;
    $text = Tool::mmt::Controller::Sugar->convert($text);
    $s->setLog($text);
    my @token = ();
    my $i = @{$s->{const}};                         # コーテーションで囲われた文字列を抽出し
    while($text =~ /\A(.*?)((["']).*?[^\\]\3)(.*)\z/sm){    # 文字リテラルとそれ以外に別ける
        push(@token,$1);
        push(@{$s->{const}},$2);
        $text = $4;
    }
    push(@token,$text);
    my $text = '';
    for(@token){                                    # 文字リテラルを内部形式に変換し
        #$text .= $s->adjust2($_);                   # 　入力式を再編成する
        $text .= $_;                   # 　入力式を再編成する
        $text .= "__STR__|@{[$i++]}|__" if($i < @{$s->{const}});
    }
    $text = $s->adjust2($text);
    return $s->{_text} = $s->_normalize_args_space($text);  # 引数形式のカッコ内は１つのトークンととし別で処理するのでカッコ内のスペースを削除する
}
sub adjust2{                                        # 特殊な計算は内部形式に変換しオペレータの前後にスペースを注入する
    my ($s,$text) = @_;                             # 計算式ITEMをスペースで分割出来るようにする
    # Increment , Decrement は内部表現に変換
    $text =~ s/(\+\+|--)(${\VAR_NAME})/ $1\_pre($2) /g;
    $text =~ s/(${\VAR_NAME})(\+\+|--)/ $2\_post($1) /g;

    #並列表現を内部表現に変換
    my $old ='';
    while($old ne $text){
        $old = $text;
        $text =~ s/(${\VAR_NAME}|\w.*?\))\[(.+?)\]/array(\1,\2)/g;
        $text =~ s/(${\VAR_NAME}|\w.*?\))\{(.+?)\}/hash(\1,\2)/g;
    }

    #オペレータの前後にスペースを付加する。（のちにスペースで各要素を分割する）
    $text =~ s/$s->{ops}/ $1 /g;

    $text =~ s{(\b\d+|\))\s*\(}{$1 \* \(}g;             # 開き括弧の前が演算子じゃない時に*を補完 ex). (1+2)(2-1) -> (1+2)*(2-1)
    $text =~ s/(\s*;\s*)*$//g;                          # 末尾のセミコロン(文の区切り)を削除
    return $text;
}
sub _normalize_args_space {
    my ($s, $text) = @_;
    # 引数が1つの時は２つのかたちにする。　無理やり感あり
    $text =~ s/([A-Za-z]([^\s()]*)\s+\()([^()]*)\)/$1$3,)/g;
    # カッコの内側から順に引数内のスペースを削除処理（ネスト対応）
    $text =~ s/,/ ,/g;
    # 引数形式の内側の()内のスペースを削除し()を_[ _]に変換
    while (
        ($text =~ s!\(([^()]*?\s+,[^()]*)\)!
           '_['.  ($1 =~ s/\s+//gr) .'_]'
        !ge)){
    }
    # _[ _]を()に戻す
    $text =~ s/_\[/(/g;
    $text =~ s/_\]/)/g;
    $text =~ s/,\)/)/g;
    return $text;
}
sub setLog{
    my ($s,$log) = @_;
    $_[0]->{global}->{LOG} .= $log ;
}
sub _error{
    my ($s,$text) = @_;
    $s->{ret} = $text;
    croak $text;
}
1;

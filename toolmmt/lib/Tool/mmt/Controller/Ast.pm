package Tool::mmt::Controller::Ast;
use Mojo::Base 'Tool::mmt::Controller::Mmt';
use strict;
use warnings;
use Data::Dumper;

my $op = +{ '-' => [sub {$_[0] - $_[1]},1],         # オペレータ定義
           '+' => [sub {$_[0] + $_[1]},1],
           '*' => [sub {$_[0] * $_[1]},2],
           '/' => [sub {$_[0] / $_[1]},2],
           '%' => [sub {$_[0] % $_[1]},2],
           '**' => [sub {$_[0] ** $_[1]},3],
           #'x' => [sub {$_[0] * $_[1]},8], # 多項式対応？
           '(' => [sub { },9],
           ')' => [sub { },10],
        };
sub ast{
    my $s = shift;
    my $x = $s->Astnew('formula'=>$s->param('calc'));
    $s->stash(anser => $x->{anser});
}
sub _ast{
    my $s = shift;
    $s->{root} = $s->makeTree(@{$s->item_split($s->adjust(shift))->{item}});
    $s->stash(tree => Dumper $s->{root});
    $s->{anser} = $s->readTree($s->{root});
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
    $s->{ops} = join ('|',map {s/(.)/\\$1/g;$_;} sort {length $b <=> length $a} keys %$op);
    $s->{ops} = "(".$s->{ops}.")";
    return $s;
}
sub newNode{
    my $s = shift;
    return {data => shift(),left =>shift(),right=>shift()};
}
sub readTree{                                       # AST計算
    my ($s,$node) = @_;
    return $node if(ref($node) ne 'HASH');
    do{$node->{$_} = $s->readTree($node->{$_}) if(ref($node->{$_}) eq 'HASH')} for ('left','right');
    exists $op->{$node->{data}} ? $op->{$node->{data}}->[0]($node->{left},$node->{right})
                                : $node->{data};
}
sub makeTree{                                       # AST組み立て
    my $s = shift;
    while($_[0] eq '(' and $_[-1] eq ')'){
        my ($r,$sw) = (0,0);
        for(@_){                                    # '('の深さを計算
            ++$r if($_ eq '(');                     
            --$r if($_ eq ')');
            ++$sw if($r == 1 and $_ eq '(');
        }
        if($sw == 1){                               #  一番外側の括弧を外す
            shift; pop;
        }else{
            last;
        }
    }
    return shift() if(@_ <= 1);                     # 要素が一つの時は要素を返す
    my ($prio,$i,$m,$r) = (99,-1,0,0);
    for(@_){                                        # 一番右側の一番プライオリティの低いオペレータを検索
        ++$i;
        if(/^$s->{ops}$/){
            ++$r if($_ eq '(');
            --$r if($_ eq ')');
            next if($r or $_ eq ')');              #  括弧の間は読み飛ばす
            if($op->{$_}->[1] <= $prio){
                $prio = $op->{$_}->[1];
                $m = $i;
            }
        }
    }
    return $s->newNode($_[$m],                      # オペレータとオペランド（右と左）を返す
                            $s->makeTree(@_[0 .. $m-1]),
                            $s->makeTree(@_[$m+1 .. $#_])
                );
}
sub item_split{                                     # 計算式を要素に分解
    my $s = shift;
    my $text = shift || $s->{_text};
    $s->{item} = [split ' ',$text];
    return $s;
}
sub adjust{                                         # 計算式の要素をスペースで分割
    my ($s,$text) = @_;
    $text =~ s/$s->{ops}/ $1 /g;
    $text =~ s{([\d\)])\s*\(}{$1 \* \(}g;           #   開き括弧の前が演算子じゃない時に*を補完 ex). (1+2)(2-1) -> (1+2)*(2-1)
    $s->{_text} = $text =~ s/($s->{ops}\s*-)\s*/$1/g;
    return $text;
}
1;

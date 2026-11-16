#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use feature 'say';
use Carp qw(croak);

# --------------------------------------------------
# 演算子テーブル
# --------------------------------------------------
my %OP_TABLE = (
    '-'  => { code => sub { $_[1] - $_[0] }, prec => 1, assoc => 'L', arity => 2 },
    '+'  => { code => sub { $_[1] + $_[0] } , prec => 1, assoc => 'L', arity => 2 },
    '*'  => { code => sub { $_[1] * $_[0] } , prec => 2, assoc => 'L', arity => 2 },
    '/'  => { code => sub { $_[1] / $_[0] } , prec => 2, assoc => 'L', arity => 2 },
    '%'  => { code => sub { $_[1] % $_[0] } , prec => 2, assoc => 'L', arity => 2 },
    '**' => { code => sub { $_[1] ** $_[0] }, prec => 4, assoc => 'R', arity => 2 },
    'NGE'=> { code => sub { -$_[0] }      , prec => 3, assoc => 'R', arity => 1 },
    '('  => { code => sub {},             prec => 0, assoc => 'L', arity => 0 },
    'x'  => { code => sub { $_[1] * $_[0] } , prec => 2, assoc => 'L', arity => 2 }, # 任意の文字で掛け算
);

# --------------------------------------------------
# 入力正規化
# --------------------------------------------------
sub normalize_expression {
    my ($txt) = @_;

    # 演算子の前後に空白を入れる
    $txt =~ s/([+\-*\/%()x])/$1 /g;

    # **（指数）を一つにまとめる
    $txt =~ s/\*\s*\*/**/g;

    # 暗黙の掛け算 2(3+4) => 2 * (3+4)
    $txt =~ s/(\d|\))\s*\(/$1 * (/g;

    $txt =~ s/\s+/ /g;          # 余分な空白を圧縮
    $txt =~ s/^\s+|\s+$//g;     # 前後の空白除去
    return $txt;
}

# --------------------------------------------------
# 中置→後置変換（Shunting‑yard アルゴリズム）
# --------------------------------------------------
sub infix_to_postfix {
    my @tokens = @_;
    my @out;
    my @stack;
    my $prev = 'START';

    for ('(', @tokens, ')') {
        if ($_ eq ')') {
            push @out, pop @stack while @stack && $stack[-1] ne '(';
            pop @stack;                     # '(' を捨てる
        }
        elsif (exists $OP_TABLE{$_}) {
            my $cur = $_;

            # 単項マイナスの判定
            if ($cur eq '-' && ($prev eq 'START' || $prev eq '(' || $prev eq 'OP')) {
                $cur = 'NGE';
            }

            while (@stack && $stack[-1] ne '(' && should_pop($cur, $stack[-1])) {
                push @out, pop @stack;
            }
            push @stack, $cur;
            $prev = 'OP';
        }
        else {
            push @out, $_;
            $prev = 'NUM';
        }
    }
    return @out;
}

sub should_pop {
    my ($cur, $top) = @_;
    my $c = $OP_TABLE{$cur};
    my $t = $OP_TABLE{$top};

    return 0 unless $t;        # '(' のときは pop しない
    return $c->{assoc} eq 'R' ? $c->{prec} <  $t->{prec}
                               : $c->{prec} <= $t->{prec};
}

# --------------------------------------------------
# 後置記法評価（RPN）
# --------------------------------------------------
sub evaluate_rpn {
    my @stack;
    for my $token (@_) {
        if (exists $OP_TABLE{$token}) {
            my $op = $OP_TABLE{$token};
            croak "演算子 '$token' の引数が足りません" if $op->{arity} > @stack;
            my @args = splice @stack, -$op->{arity};
            push @stack, $op->{code}->(@args);
        }
        else {
            croak "不正なトークン '$token'" unless $token =~ /^[0-9]+(?:\.[0-9]*)?$/;
            push @stack, $token + 0;   # 数値化
        }
    }
    croak "式が不完全です" unless @stack == 1;
    return $stack[0];
}

# --------------------------------------------------
# メインロジック
# --------------------------------------------------
my $expr = shift @ARGV // do {
    local $/;                 # スラッシュで全体を一括取得
    <STDIN>;
};

die "式が空です。\n" unless defined $expr && $expr ne '';

my @tokens   = split /\s+/, normalize_expression($expr);
my @postfix  = infix_to_postfix(@tokens);
my $result   = evaluate_rpn(@postfix);

say $result;


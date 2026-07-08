package Interpreter::Op;
use strict;
use warnings;
use utf8;
use Exporter 'import';
our @EXPORT_OK = qw(getOp) ;
my $op = {     # オペレータ定義
           ';'   => [sub { $_[2]},          10,'L',0],
           '||'  => [sub {$_[1] || $_[2]},  20,'L',0],
           '&&'  => [sub {$_[1] && $_[2]},  30,'L',0],
           '?'   => [sub { },               55,'R',0],
           ':'   => [sub { },               55,'R',0],
           '='   => [sub {$_[0]->setValue('',$_[1],$_[2])},
                                            50,'R',2],
           ':='   => [sub {$_[0]->setValue('global',$_[1],$_[2])},
                                            50,'R',2],
           '<='  => [sub {$_[0]->cmp_auto($_[1], $_[2],sub {$_[0] <= $_[1]},sub{$_[0] le $_[1]})}, 
                                            60,'L',0],
           '>='  => [sub {$_[0]->cmp_auto($_[1], $_[2],sub {$_[0] >= $_[1]},sub{$_[0] ge $_[1]})},
                                            60,'L',0],
           '>'   => [sub {$_[0]->cmp_auto($_[1], $_[2],sub {$_[0] >  $_[1]},sub{$_[0] gt $_[1]})},
                                            60,'L',0],
           '<'   => [sub {$_[0]->cmp_auto($_[1], $_[2],sub {$_[0] <  $_[1]},sub{$_[0] lt $_[1]})},
                                            60,'L',0],
           '=='  => [sub {$_[0]->cmp_auto($_[1], $_[2],sub {$_[0] == $_[1]},sub{$_[0] eq $_[1]})},
                                            60,'L',0],
           '!='  => [sub {$_[0]->cmp_auto($_[1], $_[2],sub {$_[0] != $_[1]},sub{$_[0] ne $_[1]})},  
                                            60,'L',0],
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
                    [sub { my $type = ($_[0]->split_eval($_[1]))[0];
                       ref($type) eq 'ARRAY' ? @{$type} : length($type)},
                                            90,'R',1],
           'int'  => [sub { int(($_[0]->split_eval($_[1]))[0])},
                                            90,'R',1],
           'substr'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                           substr($x[0],$x[1],$x[2])},
                                            90,'R',1],
           'pop'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                           pop(@{$x[0]})},
                                            90,'R',1],
           'push'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
			   if(ref($x[1]) eq  'ARRAY'){
                               push(@{$x[0]},@{$x[1]});
		           }else{
                               push(@{$x[0]},(@x[1..$#x]));
		           }},
                                            90,'R',1],
           'shift'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                           shift(@{$x[0]})},
                                            90,'R',1],
           'unshift'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                           unshift(@{$x[0]},$x[1])},
                                            90,'R',1],
           'join'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                            if(@x >= 2){
                                join($x[0],map {@{$_||[]}} @x[1..$#x])
                            }else{
                                $_[0]->_error("join : Missing arguments") ;
                            }
                                            },
                                            90,'R',1],
           'split'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                           my @xx = split($x[0],$x[1]);\@xx},
                                            90,'R',1],
           'keys'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                           \@{[keys(%{$x[0]})]}},
                                            90,'R',1],
           'match'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                            my $re = qr/$x[0]/;
                            \@{[$x[1] =~ /$re/g]}},
                                            90,'R',1],
           'replace'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                            my $re = qr/$x[0]/;
                            $x[2] =~ s/$re/$x[1]/g;
                            $x[2]},
                                            90,'R',1],
           '..'  => [sub {\@{[$_[1] .. $_[2]]}},   65,'L',0],
           #perl関数定義 END
           'map'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                           my @a = map {$_[0]->setValue('','$_',$_);
                                        my @x = $_[0]->split_eval($_[1],',');
                                        $x[0]
                                       } @{$x[1]};
                          \@a},
                                            90,'R',1],
           'continue'  => 
                    [sub { die bless {}, 'AST::Continue'; },
                                            90,'R',1],
           'return'  => 
                    [sub {  my @x = $_[0]->split_eval($_[1],',');$_[0]->{ret} = $x[0];die bless {}, 'AST::Return'; },
                                            90,'R',1],
           'array'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
			   if(ref($x[1]) eq  'ARRAY'){
			       [@{$x[0]}[@{$x[1]}]];
		           }else{
                               $x[0][$x[1]];
		           }},
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
           "XX"   => [sub {$_[1] x $_[2]},   65,'L',0],
};
sub getOp {
    return $op;
}
1;

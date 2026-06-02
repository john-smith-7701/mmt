package Tool::mmt::Controller::Ast;
use Mojo::Base 'Mojolicious::Controller';
use strict;
use warnings;
use Tool::Model::Interpreter::Ast;
use DDP;
use Carp;

sub ast{
    my $s = shift;
    my $ast = Interpreter::Ast->new();
    my $x = $ast->Astnew('formula'=>$s->param('calc'));

    # デバック情報出力
    $x->{root}->{vars} = $x->{vars};
    $x->{root}->{text} = $x->{logText};
    #$s->{root}->{global} = $s->{global};
    $x->{root}->{func} = $x->{func};
    $x->{root}->{const} = $x->{const};
    $x->{root}->{LOG} = $x->{global}{LOG};
    $s->stash(tree => np( $x->{root}, colored => 0  ));

    $s->stash(anser => $x->{anser});
}
1;

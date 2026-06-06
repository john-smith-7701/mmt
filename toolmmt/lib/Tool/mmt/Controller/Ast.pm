package Tool::mmt::Controller::Ast;
use Mojo::Base 'Tool::mmt::Controller::Json';
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
    $s->{root}->{global} = $s->{global};
    $x->{root}->{func} = $x->{func};
    $x->{root}->{const} = $x->{const};
    $x->{root}->{LOG} = $x->{global}{LOG};
    $s->stash(tree => np( $x->{root}, colored => 0  ));

    $s->stash(anser => $x->{answer});
    if(($s->req->method eq 'GET' && $s->param('calc') ne '') || $s->param('out') eq 'json'){
        my $res = {'answer'=>$x->{answer}};
        if($s->param('debg') eq 'on'){
            $res->{'root'} = $x->{'root'};
        }
        $s->json_or_jsonp( $s->render_to_string(json => $res));
    }
}
1;

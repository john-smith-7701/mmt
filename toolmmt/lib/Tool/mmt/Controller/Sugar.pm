package Tool::mmt::Controller::Sugar;
use Mojo::Base 'Tool::mmt::Controller::Mmt';

sub convert {
    my ($class,$text) = @_;

    # もし〜なら〜以外は〜
    $text =~ s/
        もし(.+?)なら(.+?)以外は(.+?)
    /
        ($1 ? $2 : $3)
    /gx;

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

1;

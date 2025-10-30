#!/usr/bin/env perl
use strict;
use warnings;
use Mojolicious::Lite;
use Imager;
use File::Temp qw/ tempfile tempdir /;

# ホームページ - アップロードフォーム
get '/' => sub {
    my $c = shift;
    $c->render(template => 'index');
};

# 画像差分処理
post '/diff' => sub {
    my $c = shift;
    
    # アップロードされたファイルを取得
    my $img1_upload = $c->param('image1');
    my $img2_upload = $c->param('image2');
    
    # ファイルが存在するかチェック
    unless ($img1_upload && $img2_upload) {
        $c->render(text => '2つの画像ファイルを選択してください', status => 400);
        return;
    }
    
    # 一時ファイルに保存
    my ($fh1, $tmp1) = tempfile(UNLINK => 1, SUFFIX => '.png');
    my ($fh2, $tmp2) = tempfile(UNLINK => 1, SUFFIX => '.png');
    
    print $fh1 $img1_upload->slurp;
    print $fh2 $img2_upload->slurp;
    close $fh1;
    close $fh2;
    
    # Imagerで画像を読み込む
    my $img1 = Imager->new(file => $tmp1);
    my $img2 = Imager->new(file => $tmp2);
    
    unless ($img1 && $img2) {
        $c->render(text => '画像の読み込みに失敗しました: ' . 
                  ($img1 ? '' : Imager->errstr) . ' ' . 
                  ($img2 ? '' : Imager->errstr), status => 400);
        return;
    }
    
    # 画像サイズを合わせる（小さい方に合わせる）
    my $width1  = $img1->getwidth;
    my $height1 = $img1->getheight;
    my $width2  = $img2->getwidth;
    my $height2 = $img2->getheight;
    
    my $min_width  = $width1 < $width2 ? $width1 : $width2;
    my $min_height = $height1 < $height2 ? $height1 : $height2;
    
    # 必要に応じてリサイズ
    if ($width1 != $min_width || $height1 != $min_height) {
        $img1 = $img1->scale(xpixels => $min_width, ypixels => $min_height);
    }
    if ($width2 != $min_width || $height2 != $min_height) {
        $img2 = $img2->scale(xpixels => $min_width, ypixels => $min_height);
    }
    
    # 差分画像を作成
    my $diff_img = Imager->new(xsize => $min_width, ysize => $min_height);
    
    for my $y (0 .. $min_height - 1) {
        for my $x (0 .. $min_width - 1) {
            my $color1 = $img1->getpixel(x => $x, y => $y);
            my $color2 = $img2->getpixel(x => $x, y => $y);
            
            # RGB各チャンネルの差分を計算
            my @rgb1 = $color1->rgba;
            my @rgb2 = $color2->rgba;
            
            my $r_diff = abs($rgb1[0] - $rgb2[0]);
            my $g_diff = abs($rgb1[1] - $rgb2[1]);
            my $b_diff = abs($rgb1[2] - $rgb2[2]);
            
            # 差分をグレースケールに変換（平均値）
            my $gray = int(($r_diff + $g_diff + $b_diff) / 3);
            
            my $diff_color = Imager::Color->new($gray, $gray, $gray);
            $diff_img->setpixel(x => $x, y => $y, color => $diff_color);
        }
    }
    
    # 画像をメモリに保存
    my $output_data;
    $diff_img->write(data => \$output_data, type => 'png')
        or die $diff_img->errstr;
    
    # PNGとしてレスポンスを返す
    $c->res->headers->content_type('image/png');
    $c->render(data => $output_data);
};

app->start;

__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html>
<head>
    <title>画像差分ツール</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .form-group { margin: 20px 0; }
        label { display: block; margin-bottom: 5px; }
        input[type="file"] { margin-bottom: 10px; }
        button { padding: 10px 20px; background: #007cba; color: white; border: none; cursor: pointer; }
        button:hover { background: #005a87; }
    </style>
</head>
<body>
    <h1>画像差分ツール</h1>
    <form action="diff" method="post" enctype="multipart/form-data">
        <div class="form-group">
            <label for="image1">画像1:</label>
            <input type="file" id="image1" name="image1" accept="image/*" required>
        </div>
        <div class="form-group">
            <label for="image2">画像2:</label>
            <input type="file" id="image2" name="image2" accept="image/*" required>
        </div>
        <button type="submit">差分画像を作成</button>
    </form>
</body>
</html>


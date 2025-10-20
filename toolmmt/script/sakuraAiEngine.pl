#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Mojo::UserAgent;
use Mojo::JSON qw(encode_json decode_json);

# トップページ - TOKEN入力フォーム
get '/' => sub ($c) {
    $c->render(template => 'index');
};

# POST /send - TOKENをAPIに送信
post '/send' => sub ($c) {
    my $token = $c->param('token') || 'デフォルトTOKEN';

    my $url = 'https://api.ai.sakura.ad.jp/v1/chat/completions';
    my $auth = "Bearer $ENV{ACCTOKEN}";

    my $data = {
        model       => 'gpt-oss-120b',
        messages    => [ { role => 'system', content => $token } ],
        temperature => 0.7,
        max_tokens  => 10000,
        stream      => Mojo::JSON->false,
    };

    my $ua = Mojo::UserAgent->new;
    my $res = $ua->post(
        $url => {
            'Accept'        => 'application/json',
            'Content-Type'  => 'application/json',
            'Authorization' => $auth,
        } => json => $data
    )->result;

    if ($res->is_success) {
        my $json = $res->json;
        my $content = $json->{choices}[0]{message}{content} // '(レスポンスなし)';
        $c->stash(token => $token, content => $content);
        $c->render(template => 'result');
    } else {
        $c->render(text => "エラー: " . $res->message);
    }
};

app->start;

__DATA__

@@ index.html.ep
% layout 'default';
% title 'TOKEN入力';
<h2>さくらAIリクエストテスト</h2>
<form method="POST" action="send">
  <label for="token">TOKEN入力:</label>
  <input type="text" name="token" id="token" style="width:90%">
  <input type="submit" value="送信">
</form>

@@ result.html.ep
% layout 'default';
% title 'APIレスポンス';
<h2>リクエスト内容</h2>
<p><b>TOKEN:</b> <%= $token %></p>

<h2>AIレスポンス</h2>
<div style="white-space:pre-wrap; border:1px solid #ccc; padding:10px; background:#f9f9f9;">
  <%= $content %>
</div>

<a href="./">戻る</a>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title><%= title %></title>
</head>
<body style="font-family:sans-serif; margin:30px;">
  <%= content %>
</body>
</html>


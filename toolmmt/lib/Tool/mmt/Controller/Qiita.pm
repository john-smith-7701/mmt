package Tool::mmt::Controller::Qiita;
use Mojo::Base 'Tool::mmt::Controller::Json';
use Mojo::UserAgent;
use utf8;

=encoding utf8

=head1 NAME

Tool::mmt::Controller::Qiita - Qiita のアクセス数（PV）を集計する API

=head1 ROUTES

既存のルート C</api/:controller/:action> にそのまま乗る。

  POST/GET /api/qiita/collect   Qiita API から記事一覧を取得して DB に保存（cron 用）
  GET      /api/qiita/daily     日別の合計PV・増加PV を返す
  GET      /api/qiita/daily?id=記事ID   記事ごとの日別PV を返す

=head1 SETUP

=over 2

=item 1. テーブル作成

  mysql -u YourName -p YourDB < lib/Tool/Model/Sql/qiita_tables.sql

=item 2. トークンと集計キーを設定

hypnotoad を起動する環境で環境変数を設定する。

  export QIITA_ACCESS_TOKEN="Qiita の個人用アクセストークン(read_qiita)"
  export QIITA_COLLECT_KEY="cron だけが知っている任意の文字列"
  hypnotoad script/toolmmt

環境変数の代わりに toolmmt.conf に書いてもよい（その場合は git にコミットしないこと）。

  qiita => {
    token       => '...',
    collect_key => '...',
  },

=item 3. cron

  15 6 * * * curl -fsS -H "X-Collect-Key: 集計キー" http://localhost:3003/api/qiita/collect > /dev/null

=back

集計キーが設定されていない場合、collect は常に 403 を返す（公開URLから誰でも実行できないようにするため）。

=cut

# UserAgent はアプリで1つを使い回す（テストではここにモックを差し込む）
has qiita_ua => sub { shift->app->{qiita_ua} ||= Mojo::UserAgent->new(request_timeout => 30) };

sub _conf {
    my ($s, $name, $env) = @_;
    return $ENV{$env} if defined $ENV{$env} && $ENV{$env} ne '';
    return ($s->app->config->{qiita} || {})->{$name};
}

sub _api_base {
    my $s = shift;
    return ($s->app->config->{qiita} || {})->{api_base} || 'https://qiita.com/api/v2';
}

sub _error {
    my ($s, $status, $msg) = @_;
    $s->render(status => $status, json => {status => 'error', message => $msg});
    return undef;
}

# Qiita の日時 (2026-11-14T10:00:00+09:00) を DATETIME 形式にする
sub _datetime {
    my $t = shift // return undef;
    return $t =~ /^(\d{4}-\d\d-\d\d)T(\d\d:\d\d:\d\d)/ ? "$1 $2" : undef;
}

#---------------------------------------------------------------#
sub collect {
#---------------------------------------------------------------#
    my $s = shift;

    # 集計キーの確認
    my $key = $s->_conf('collect_key', 'QIITA_COLLECT_KEY');
    return $s->_error(403, 'collect key is not configured') unless defined $key && $key ne '';
    my $given = $s->req->headers->header('X-Collect-Key') // '';
    return $s->_error(403, 'forbidden') unless $given eq $key;

    my $token = $s->_conf('token', 'QIITA_ACCESS_TOKEN');
    return $s->_error(500, 'QIITA_ACCESS_TOKEN is not set') unless defined $token && $token ne '';

    # 集計日（通常は今日。テストや再集計用に date=YYYY-MM-DD も受け付ける）
    my $date = $s->param('date') // sprintf('%04d-%02d-%02d', $s->app->model->today);
    return $s->_error(400, 'invalid date') unless $date =~ /^\d{4}-\d\d-\d\d$/;

    # 記事一覧を全ページ取得
    my @items;
    for my $page (1 .. 100) {
        my $tx = $s->qiita_ua->get(
            $s->_api_base . "/authenticated_user/items?per_page=100&page=$page"
                => {Authorization => "Bearer $token"});
        my $res = $tx->result;
        return $s->_error(502, 'Qiita API error: ' . $res->code . ' ' . ($res->message // ''))
            unless $res->is_success;
        my $list = $res->json || [];
        push @items, @$list;
        last if @$list < 100;
    }

    # DB へ保存
    my $webdb = $s->app->model->webdb;
    my $dbh = $webdb->dbh;
    # 長時間アイドルで MySQL に切断されていると begin_work が失敗する
    # (mysql_auto_reconnect は AutoCommit 切替時には効かない) ので接続し直す
    unless ($dbh->ping) {
        delete $webdb->{dbh};
        $dbh = $webdb->dbh;
    }
    local $dbh->{RaiseError} = 1;
    my ($total, $increase) = (0, 0);
    eval {
        $dbh->begin_work;
        for my $item (@items) {
            my $pv = $item->{page_views_count} // 0;
            $total += $pv;
            $s->_save_item($dbh, $item, $pv);
            my $inc = $s->_save_daily($dbh, $date, $item, $pv);
            $increase += $inc // 0;
        }
        $dbh->commit;
        1;
    } or do {
        my $err = $@ || 'unknown error';
        eval { $dbh->rollback };
        $s->app->log->error("qiita collect: $err");
        return $s->_error(500, 'database error');
    };

    $s->render(json => {
        status   => 'ok',
        date     => $date,
        items    => scalar(@items),
        total_pv => $total,
        increase => $increase,
    });
}

sub _save_item {
    my ($s, $dbh, $item, $pv) = @_;
    my @val = (
        $item->{title} // '',
        $item->{url} // '',
        _datetime($item->{created_at}),
        _datetime($item->{updated_at}),
        $pv,
        $item->{likes_count} // 0,
        $item->{stocks_count} // 0,
    );
    my ($exists) = $dbh->selectrow_array(
        'select 1 from qiita_item where 記事ID = ?', undef, $item->{id});
    if ($exists) {
        $dbh->do('update qiita_item set タイトル = ?, URL = ?, 投稿日時 = ?, 更新日時 = ?,
                  PV数 = ?, いいね数 = ?, ストック数 = ? where 記事ID = ?',
                 undef, @val, $item->{id});
    } else {
        $dbh->do('insert into qiita_item (タイトル, URL, 投稿日時, 更新日時, PV数, いいね数, ストック数, 記事ID)
                  values (?, ?, ?, ?, ?, ?, ?, ?)',
                 undef, @val, $item->{id});
    }
}

# 戻り値は増加PV（前回データがなければ undef）
sub _save_daily {
    my ($s, $dbh, $date, $item, $pv) = @_;
    my ($prev) = $dbh->selectrow_array(
        'select PV数 from qiita_daily where 記事ID = ? and 集計日 < ? order by 集計日 desc limit 1',
        undef, $item->{id}, $date);
    my $inc = defined $prev ? $pv - $prev : undef;
    my @val = ($pv, $inc, $item->{likes_count} // 0, $item->{stocks_count} // 0);

    # 同じ日に再実行した場合は上書きする
    my ($exists) = $dbh->selectrow_array(
        'select 1 from qiita_daily where 集計日 = ? and 記事ID = ?', undef, $date, $item->{id});
    if ($exists) {
        $dbh->do('update qiita_daily set PV数 = ?, 増加PV = ?, いいね数 = ?, ストック数 = ?
                  where 集計日 = ? and 記事ID = ?',
                 undef, @val, $date, $item->{id});
    } else {
        $dbh->do('insert into qiita_daily (PV数, 増加PV, いいね数, ストック数, 集計日, 記事ID)
                  values (?, ?, ?, ?, ?, ?)',
                 undef, @val, $date, $item->{id});
    }
    return $inc;
}

#---------------------------------------------------------------#
sub daily {
#---------------------------------------------------------------#
    my $s = shift;
    my $days = $s->param('days') // 30;
    $days = 30 unless $days =~ /^\d+$/ && $days > 0 && $days <= 3660;
    my $id = $s->param('id');
    my $dbh = $s->app->model->webdb->dbh;

    my $rows;
    if (defined $id && $id ne '') {
        $rows = $dbh->selectall_arrayref(
            "select 集計日 as date, PV数 as pv, 増加PV as increase, いいね数 as likes, ストック数 as stocks
               from qiita_daily where 記事ID = ? order by 集計日 desc limit $days",
            {Slice => {}}, $id);
    } else {
        $rows = $dbh->selectall_arrayref(
            "select 集計日 as date, sum(PV数) as pv, sum(増加PV) as increase, count(*) as items
               from qiita_daily group by 集計日 order by 集計日 desc limit $days",
            {Slice => {}});
    }
    # 数値は数値として JSON に出す
    for my $r (@$rows) {
        $r->{$_} = defined $r->{$_} ? $r->{$_} + 0 : undef for grep { $_ ne 'date' } keys %$r;
    }
    $s->json_or_jsonp($s->render_to_string(json => [reverse @$rows]));
}

1;

use Mojo::Base -strict;
use utf8;

use Test::More;
use Test::Mojo;
use Mojo::UserAgent;
use Mojolicious::Lite ();
use DBI;

plan skip_all => 'DBD::SQLite is required' unless eval { require DBD::SQLite; 1 };

# ---- Qiita API のモック -------------------------------------------------
# 記事数とPVはテストの中で書き換える
my @articles;
my $mock = Mojolicious->new;
$mock->log->level('fatal');
$mock->routes->get('/authenticated_user/items' => sub {
    my $c = shift;
    return $c->render(status => 401, json => {message => 'Unauthorized'})
        unless ($c->req->headers->authorization // '') eq 'Bearer test-token';
    my $per  = $c->param('per_page') || 20;
    my $page = $c->param('page') || 1;
    my @slice = grep { defined } @articles[($page - 1) * $per .. $page * $per - 1];
    $c->render(json => \@slice);
});
my $qiita = Mojo::UserAgent->new;
$qiita->server->app($mock);

sub make_articles {
    my ($n, $pv_of) = @_;
    @articles = map {
        +{
            id               => sprintf('id%05d', $_),
            title            => "記事 $_ <b>&",
            url              => "https://qiita.com/u/items/id$_",
            created_at       => '2026-11-14T10:00:00+09:00',
            updated_at       => '2026-11-15T11:22:33+09:00',
            page_views_count => $pv_of->($_),
            likes_count      => 1,
            stocks_count     => 2,
        }
    } 1 .. $n;
}

# ---- アプリ（DB は SQLite のメモリDB） ---------------------------------
$ENV{QIITA_ACCESS_TOKEN} = 'test-token';
$ENV{QIITA_COLLECT_KEY}  = 'secret';

my $t = Test::Mojo->new('Tool::mmt');
$t->app->log->level('fatal');
$t->app->config->{qiita}{api_base} = $qiita->server->url->path('')->to_string;
$t->app->config->{qiita}{api_base} =~ s{/$}{};
$t->app->{qiita_ua} = $qiita;

my $dbh;
if (my $dsn = $ENV{QIITA_TEST_DSN}) {
    # MySQL で試す場合（テーブルは作り直す）
    #   QIITA_TEST_DSN='DBI:mysql:database=test;host=localhost' QIITA_TEST_USER=.. QIITA_TEST_PASS=.. prove -l t/qiita.t
    $dbh = DBI->connect($dsn, $ENV{QIITA_TEST_USER}, $ENV{QIITA_TEST_PASS},
        {RaiseError => 1, mysql_enable_utf8 => 1});
    $dbh->do('set names utf8mb4');
    $dbh->do("drop table if exists $_") for qw(qiita_item qiita_daily);
    open my $fh, '<:encoding(UTF-8)', 'lib/Tool/Model/Sql/qiita_tables.sql' or die $!;
    my $sql = join '', grep { !/^\s*--/ } <$fh>;
    $sql =~ s/--[^\n]*//g;
    $dbh->do($_) for grep { /\S/ } split /;/, $sql;
} else {
    $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '',
        {RaiseError => 1, sqlite_unicode => 1});
}
$dbh->do($_) for $ENV{QIITA_TEST_DSN} ? () : (
    q{create table qiita_item (記事ID varchar(20) primary key, タイトル varchar(255) not null default '',
      URL varchar(255) not null default '', 投稿日時 datetime, 更新日時 datetime,
      PV数 int not null default 0, いいね数 int not null default 0, ストック数 int not null default 0,
      UPD_TIME timestamp default current_timestamp)},
    q{create table qiita_daily (集計日 date not null, 記事ID varchar(20) not null,
      PV数 int not null default 0, 増加PV int, いいね数 int not null default 0, ストック数 int not null default 0,
      UPD_TIME timestamp default current_timestamp, primary key (集計日, 記事ID))},
);
$t->app->model->webdb->dbh($dbh);

# ---- 集計キー -----------------------------------------------------------
$t->get_ok('/api/qiita/collect')->status_is(403);
$t->get_ok('/api/qiita/collect' => {'X-Collect-Key' => 'wrong'})->status_is(403);
{
    local $ENV{QIITA_COLLECT_KEY} = '';
    $t->get_ok('/api/qiita/collect' => {'X-Collect-Key' => ''})->status_is(403)
      ->json_is('/message' => 'collect key is not configured');
}

# ---- 1日目: 150記事（2ページ）。1記事だけ PV が null -----------------
make_articles(150, sub { $_[0] == 7 ? undef : $_[0] * 10 });
my $sum1 = 0; $sum1 += $_->{page_views_count} // 0 for @articles;

$t->get_ok('/api/qiita/collect?date=2026-11-20' => {'X-Collect-Key' => 'secret'})
  ->status_is(200)
  ->json_is('/status'   => 'ok')
  ->json_is('/items'    => 150)
  ->json_is('/total_pv' => $sum1)
  ->json_is('/increase' => 0);

is $dbh->selectrow_array('select count(*) from qiita_item'), 150, 'items saved (pagination)';
is $dbh->selectrow_array('select count(*) from qiita_daily where 集計日 = ?', undef, '2026-11-20'), 150, 'daily saved';
# DBD::mysql は日本語の列名をハッシュキーとしてデコードしないので、配列で受け取る
my @row = $dbh->selectrow_array('select タイトル, 投稿日時, 更新日時 from qiita_item where 記事ID = ?',
    undef, 'id00001');
is $row[0], '記事 1 <b>&', 'title (utf8)';
is $row[1], '2026-11-14 10:00:00', 'created_at converted';
is $row[2], '2026-11-15 11:22:33', 'updated_at converted';
ok !defined $dbh->selectrow_array('select 増加PV from qiita_daily where 記事ID = ?', undef, 'id00001'),
  'first day increase is NULL';

# ---- 2日目: 全記事 +5 PV、記事が1つ増える ------------------------------
make_articles(151, sub { $_[0] == 7 ? 5 : $_[0] * 10 + 5 });
$t->get_ok('/api/qiita/collect?date=2026-11-21' => {'X-Collect-Key' => 'secret'})
  ->status_is(200)
  ->json_is('/items'    => 151)
  ->json_is('/increase' => 150 * 5);   # 新しい記事は前回なし→増加に含めない

is $dbh->selectrow_array('select 増加PV from qiita_daily where 集計日 = ? and 記事ID = ?',
    undef, '2026-11-21', 'id00002'), 5, 'increase computed';
is $dbh->selectrow_array('select PV数 from qiita_item where 記事ID = ?', undef, 'id00002'), 25,
  'item updated to latest PV';

# ---- 同じ日の再実行は上書き（行が増えない） -----------------------------
$t->get_ok('/api/qiita/collect?date=2026-11-21' => {'X-Collect-Key' => 'secret'})->status_is(200);
is $dbh->selectrow_array('select count(*) from qiita_daily where 集計日 = ?', undef, '2026-11-21'), 151,
  'rerun on same day overwrites';

# ---- 日別API -------------------------------------------------------------
$t->get_ok('/api/qiita/daily')
  ->status_is(200)
  ->json_is('/0/date' => '2026-11-20')
  ->json_is('/0/items' => 150)
  ->json_is('/1/date' => '2026-11-21')
  ->json_is('/1/increase' => 750);

$t->get_ok('/api/qiita/daily?id=id00002')
  ->status_is(200)
  ->json_is('/0/pv' => 20)
  ->json_is('/1/pv' => 25)
  ->json_is('/1/increase' => 5);

$t->get_ok('/api/qiita/daily?callback=cb')->status_is(200)->content_like(qr/^cb\(/);

# ---- Qiita API エラー ----------------------------------------------------
{
    local $ENV{QIITA_ACCESS_TOKEN} = 'bad-token';
    $t->get_ok('/api/qiita/collect' => {'X-Collect-Key' => 'secret'})
      ->status_is(502)->json_like('/message' => qr/401/);
}

# ---- 不正な日付 -----------------------------------------------------------
$t->get_ok('/api/qiita/collect?date=2026-1-1' => {'X-Collect-Key' => 'secret'})->status_is(400);

done_testing();

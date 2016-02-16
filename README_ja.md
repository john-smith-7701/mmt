# Name

_mmt_ -- Master Maintenance Tool mojolicious application.

## Overview

MySQLのデータをメンテナンスするツール

## Description

mmtをインストール後data_source,user,passwordを設定するだけでデータの登録、修正、削除、一覧表示
が出来る。  
mmtを継承してアプリケーションを作成する事が出来る。

## Demo
* [商品](http://www21051ue.sakura.ne.jp:3003/mmt/%E5%95%86%E5%93%81)
* [user_tbl](http://www21051ue.sakura.ne.jp:3003/mmt/user_tbl)
* [chatdata](http://www21051ue.sakura.ne.jp:3003/mmt/chatdata)
* [commodity(商品)](http://www21051ue.sakura.ne.jp:3003/mmtx/commodity) Mmtを継承し商品テーブルメンテを作成

```perl
package Tool::mmt::Commodity;
use Mojo::Base 'Tool::mmt::Mmt';

has 'mmtDataList' => 'mmt/datalist';

sub init_set {
    my $s = shift;
    $s->mmtForm('mmt/mainform');
    $s->param('_table','商品');
}
sub look_up_set{
    my $s = shift;
    $s->{'m'}->{LOOK_UP}->{ref $s}->{$s->{'n'}->{'大分類'}} = 
        ["select 略称 from 分類名称 where 中分類 = '' and 小分類 = '' and 大分類 = ? ", 
            [$s->{'n'}->{'大分類'}] ];
    $s->{'m'}->{SUBWIN}->{ref $s}->{$s->{'n'}->{'大分類'}} = 
        ["select 大分類,略称 from 分類名称 where 中分類 = '' and 小分類 = ''", 
             []];

    $s->{'m'}->{LOOK_UP}->{ref $s}->{$s->{'n'}->{'中分類'}} = 
        ["select 略称 from 分類名称 where 大分類 = ? and 中分類 = ? and 小分類 = '' ", 
            [$s->{'n'}->{'大分類'},$s->{'n'}->{'中分類'}] ];
    $s->{'m'}->{SUBWIN}->{ref $s}->{$s->{'n'}->{'中分類'}} = 
        ["select 中分類,略称 from 分類名称 where 大分類 = ? and 中分類 <> '' and 小分類 = ''", 
            [$s->{'n'}->{'大分類'}] ];

    $s->{'m'}->{LOOK_UP}->{ref $s}->{$s->{'n'}->{'小分類'}} = 
        ["select 略称 from 分類名称 where 大分類 = ? and 中分類 = ? and 小分類 = ? ", 
            [$s->{'n'}->{'大分類'},$s->{'n'}->{'中分類'},$s->{'n'}->{'小分類'}] ];
    $s->{'m'}->{SUBWIN}->{ref $s}->{$s->{'n'}->{'小分類'}} = 
        ["select 小分類,略称 from 分類名称 where 大分類 = ? and 中分類 = ? and 小分類 <> ''", 
            [$s->{'n'}->{'大分類'},$s->{'n'}->{'中分類'}] ];
}

1;
```

## Requirement
* mojolicious
* DBD::mysql
* Text::CSV::Encoded

## Usage
mojokiciousの機動方法はご自由に。
* script/mytool daemon
* hypnotoad script/mytool

## Install
<pre>
$ git clone https://github.com/john-smith-7701/mmt.git
</pre>
## Contribution

## Licence

## Author

john smith <john.smith.7701@gmail.com>

http://park15.wakwak.com/~k-lovely/cgi-bin/wiki/wiki.cgi


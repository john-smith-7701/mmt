 package Tool::mmt::Controller::Btree;
 use Mojo::Base 'Tool::mmt::Controller::Json';

=head1 名前

B-Tree サンプル

=head1 概要

 C言語によるアルゴリズム辞典
 P.316
 Ｂ木 B-Tree

 https://gist.github.com/viz3/3486656 
 cをperlに書き換え

=cut

 has root => undef();               # B木の根
 has M => 5;                        # 1ページのデータ数の上限の半分
 has newp => undef();               # insert()の生成した新しいページ
 has key => '';                     # キー
 has value => '';                   # データ（未使用）
 has message => 'errmessage';
 has done => 0;
 has deleted => 0;
 has undersize => 0;
 has debugtext => 'Debug TREE';
 has level => 0;
 
 # 新しいページの作成
 sub newpage{
     my $s = shift;
     # ページ key: キー node: 他ページへのポインタ n:データ数
     my $node = {key => [], node => [],n =>0, value => []};
     return $node;
 }
 # ノードを開放する（まだ未実装）
 sub free{
     my $s = shift;
     my $node = shift;
 }

 # バイナリーサーチ
 #
 # ページよりキー($s->key)以上の最初の値を検索
 sub first_index{
     my ($s,$p) = @_;
     my ($l,$r,$k,$x) = (0, $p->{n} - 1, 0, 0);
     while($l <= $r){                           # 左が右以下の間ループ
         $k = int(($l+$r)/2);                   # 左と右の真ん中を計算
         $x = $s->{key} <=> $p->{key}->[$k];    # キーを比較
         last if ($x == 0);                     # キーが見つかったら抜ける
         if($x<0) { 
             $r = $k - 1;                       # キーが小さい場合 
         }else{                                 #     右端を真ん中の１つ前
             $l = $k + 1;                       # 大きい場合
         };                                     #     左端を真ん中の１つ後
     }

     # キー以上の最初のINDEXを返す
     return ($x == 1)  ? ++$k : $k;
 }
 
 # キーを検索
 sub search{
     my $s = shift;
     my $key = shift ||$s->key;
     $s->key($key);
     my $p = $s->root;
     while($p){
         my $k = $s->first_index($p,$key,$p->{n} - 1);
         return 1 if($p->{key}->[$k] == $s->{key});
         $p = $p->{node}->[$k];
     }
     return 0;
 }

 # keyをp->{key}[k]に挿入する
 sub insertitem{
     my ($s,$p,$k) = @_;
     splice(@{$p->{key}},$k,0,$s->key);
     splice(@{$p->{node}},$k+1,0,$s->newp);
     $p->{n}++;
 }
 
 # keyをp->{key}[k]に挿入し、ページpを割る
 sub node_split{
     my ($s,$p,$k) = @_;
     my $q = $s->newpage();
     # 挿入する場所がM以下の場合はM、Mより大きい場合はM+1以降を新しいページにコピーする。
     my $m = ($k <= $s->M) ? $s->M : $s->M + 1;
     @{$q->{key}} = @{$p->{key}}[$m .. $p->{n} - 1];
     @{$q->{node}} = @{$p->{node}}[$m+1 .. $p->{n}];
     unshift @{$q->{node}},undef();

     $q->{n} = 2 * $s->M - $m;
     $p->{n} = $m;
     if ($k <= $s->M){
         $s->insertitem($p,$k);                 # 元のページに挿入
     }else{
         $s->insertitem($q,$k - $m);            # 新しいページに挿入
     }
     # 元ページの最後のキーを追い出し最後のノードを新しいページの最初のノードに移す。
     $s->key($p->{key}->[$p->{n} - 1]);
     $q->{node}->[0] = $p->{node}->[$p->{n}];
     $p->{n}--;
     # 新しいページをnewpに入れてもどる
     $s->newp($q);
 }

 # ページpから木を再帰的に辿って挿入する
 sub insertsub{
     my ($s,$p) = @_;
 
     unless($p){
         $s->done(0);
         $s->newp(undef());
         return;
     }
     my $k = $s->first_index($p,$s->key,$p->{n} - 1);
     if($k < $p->{n} && $p->{key}->[$k] == $s->key){
         $s->message("もう登録されています");
         $s->done(1);
         return;
     }
     $s->insertsub($p->{node}->[$k]);
     return if($s->done);
     if($p->{n} < 2 * $s->M){
         # ページが割れない場合
         $s->insertitem($p,$k);
         $s->done(1);
     }else{
         # ページが割れる場合
         $s->node_split($p,$k);
         $s->done(0);
     }
 }
 
 # キーkeyをB木に挿入する
 sub insert{
     my $s = shift;
     my $key = shift||$s->key;
     $s->key($key);
     $s->message("[ $key ]登録しました");
     $s->insertsub($s->root);
     return if($s->done);
     
     # 挿入がまだ終了していない場合に新しいROOTノードを作成する。
     my $p = $s->newpage();
     $p->{n} = 1 ;
     $p->{key}->[0] = $s->{key};
     $p->{node}->[0] = $s->root;
     $p->{node}->[1] = $s->newp;
     $s->root($p);
 }

 # p->{key}[k],p-node[k+1]を外す。ページが小さくなりすぎたらundersizeフラグを立てる
 sub removeitem{
     my ($s,$p,$k) = @_;
     splice(@{$p->{key}},$k,1);
     splice(@{$p->{node}},$k+1,1);
     $s->undersize( --($p->{n}) < $s->M );
 }
 
 # p->{node}[k-1]の最右要素をP-key[k-1]経由でp->{node}[k]に動かす
 sub moveright{
     my ($s,$p,$k) = @_;
     my $left = $p->{node}->[$k - 1];
     my $right = $p->{node}->[$k];
     $right->{n}++;
     unshift(@{$right->{key}},$p->{key}->[$k - 1]);
     $p->{key}->[$k - 1] = $left->{key}->[$left->{n} - 1];
     unshift(@{$right->{node}},$left->{node}->[$left->{n}]);
     $left->{n}--;
 } 
 
 # p->{node}[k]の最左要素をp->{key}[k-1]経由でp->{node}[k-1]に動かす
 sub moveleft{
     my ($s,$p,$k) = @_;
 
     my $left = $p->{node}->[$k - 1];
     my $right = $p->{node}->[$k];
     $left->{n}++;
     $left->{key}->[$left->{n} - 1] = $p->{key}->[$k - 1];
     $left->{node}->[$left->{n}] = shift(@{$right->{node}});
     $p->{key}->[$k - 1] = shift(@{$right->{key}});
 }

 # p->{node}[k -1],p->{node}[k]を統合する
 sub combine{
     my ($s,$p,$k) = @_;

     my $right = $p->{node}->[$k];
     my $left = $p->{node}->[$k - 1];
     $left->{n}++;
     $left->{key}->[$left->{n} - 1] = $p->{key}->[$k - 1];
     splice(@{$left->{key}},$left->{n},0,@{$right->{key}}[0 .. $right->{n} - 1]);
     splice(@{$left->{node}},$left->{n},0,@{$right->{node}}[0 .. $right->{n}]);
     $left->{n} += $right->{n};
     $s->removeitem($p,$k - 1);
     $s->free($right);
 }

 # 小さくなりすぎたページをp->{node}->[k]を修復する
 sub restore{
     my ($s,$p,$k) = @_;
     $s->undersize(0);
     if($k > 0){
         if($p->{node}->[$k - 1]->{n} > $s->M) {
             $s->moveright($p,$k);
         }else{
             $s->combine($p,$k);
         }
     }else{
         if($p->{node}->[1]->{n} > $s->M) {
             $s->moveleft($p,1);
         }else{
             $s->combine($p,1);
         }
     }
 }

 # ページPから再帰的に木をたどり削除する
 sub deletesub {
     my ($s,$p) = @_;
     my $q;
     if(!$p){
         # 見つからなかった
         return;
     }
     my $k = $s->first_index($p,$s->key,$p->{n} - 1);
     if ($k < $p->{n} && $p->{key}->[$k] == $s->key) {
         # 見つかった
         $s->deleted(1);
         if(($q = $p->{node}->[$k])){
             # 木をたどりキー以下の最大の値を検索
             $q = $q->{node}->[$q->{n}] while ($q->{node}->[$q->{n}]);
             $p->{key}->[$k] = $q->{key}->[$q->{n} - 1];
             $s->key($q->{key}->[$q->{n} - 1]);
             $s->deletesub($p->{node}->[$k]);
             if($s->undersize){
                 $s->restore($p,$k);
             }
         }else{
             $s->removeitem($p,$k);
         }
     }else{
         $s->deletesub($p->{node}->[$k]);
         if($s->undersize){
             $s->restore($p,$k);
         }
     }
 }

 # キーkeyをB木から外す
 sub delete{
     my $s = shift;
     my $key = shift||$s->key;
     $s->key($key);
     my $p;
     $s->deleted($s->undersize(0));
     # 根から再帰的に木をたどり削除する
     $s->deletesub($s->root);
     if($s->deleted){
         if($s->root->{n} == 0) {
             $p = $s->root;
             $s->root($s->root->{node}->[0]);
             undef($p);
         }
         $s->message("[ $key ] 削除しました");
     }else{
         $s->message("見つかりません");
     }
 }

 # デモ用にB木を表示
 
 sub tree_dump{
     my ($s,$p) = @_;
     if(!$p){
         return;
     }
     $s->level($s->level + 1);
     $s->debugtext($s->debugtext . "<br>" . 
         " N -> " . $p->{n} . "ー" x $s->level . " [ " .
         join(', ',@{$p->{key}}[0 ..$p->{n} - 1]) . " ]" );
     $s->tree_dump($_) for (@{$p->{node}}[0 .. $p->{n}]);
     $s->level($s->level - 1);
 }
 sub debug_print{
     my $s = shift;
     $s->level(0);
     $s->debugtext($s->debugtext . "<br>" . "-" x 80 . $s->message); 
     $s->tree_dump($s->root);
     $s->render(template => 'btree/btree','message'=> $s->message,
            'treetext'=>$s->debugtext);
 
 }
 sub btree{
     my $s = shift;
     $s->M(int(rand(8)+2));
     #    $s->M(5);
     $s->debugtext($s->debugtext . " (M:" . $s->M . ")"); 
     $s->insert($_ * 2) for (11 .. 15);
     $s->debug_print();
     $s->insert(25);
     $s->debug_print();
     $s->insert($_ * 2 - 1) for (1 .. 4);
     $s->debug_print();
     $s->insert($_ * 2 - 1) for (1 .. 5);
     $s->debug_print();
     $s->insert($_) for (30 .. 100);
     $s->debug_print();
     $s->delete($_) for (92 .. 99);
     $s->debug_print();
     $s->delete(51);
     $s->debug_print();
     $s->insert(51);
     $s->debug_print();
     $s->delete(75);
     $s->debug_print();
 }

 1;

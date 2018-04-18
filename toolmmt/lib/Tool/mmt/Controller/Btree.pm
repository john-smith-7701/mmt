 package Tool::mmt::Controller::Btree;
 use Mojo::Base 'Tool::mmt::Controller::Json';
 
 has root => undef();
 has M => 5;
 has newp => undef();
 has key => '';
 has message => 'errmessage';
 has done => 0;
 has deleted => 0;
 has undersize => 0;
 has debugtext => 'Debug TREE';
 has level => 0;
 
 # 新しいページの作成
 sub newpage{
     my $s = shift;
     my $node = {key => [], node => [],n =>0};
     return $node;
 }
 
 # キーを検索
 sub search{
     my $s = shift;
     my $key = shift ||$s->key;
     $s->key($key);
     my $p = $s->root;
     while($p){
         my $k = 0;
         while($k < $p->{n} && $p->{key}->[$k] < $s->{key}){$k++;}
         return 1 if($_ eq $s->{key});
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
     my $m = ($k <= $s->M) ? $s->M : $s->M + 1;
     for ( my $j = $m + 1; $j <= 2 * $s->M ;$j++){
         $q->{key}->[$j - $m - 1] = $p->{key}->[$j - 1];
         $q->{node}->[$j - $m] = $p->{node}->[$j];
     }
     $q->{n} = 2 * $s->M - $m;
     $p->{n} = $m;
     if ($k <= $s->M){
         $s->insertitem($p,$k);
     }else{
         $s->insertitem($q,$k - $m);
     }
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
     my $k = 0;
     while($k < $p->{n} && $p->{key}->[$k] < $s->key){ $k++; }
     if($p->{key}->[$k] == $s->key){
         $s->message("もう登録されています");
         $s->done(1);
         return;
     }
     $s->insertsub($p->{node}->[$k]);
     if($s->done){
         return;
     }
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
     $s->message("登録しました");
     $s->insertsub($s->root);
     if($s->done){
         return;
     }
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
     while(++$k < $p->{n}){
         $p->{key}->[$k - 1] = $p->{key}->[$k];
         $p->{node}->[$k] = $p->{node}->[$k + 1];
     }
     $s->undersize( --($p->{n}) < $s->M );
 }
 
 # p->{node}[k-1]の最右要素をP-key[k-1]経由でp->{node}[k]に動かす
 sub moveright{
     my ($s,$p,$k) = @_;
     my $left = $p->{node}->[$k - 1];
     my $right = $p->{node}->[$k];
     for (my $j = $right->{n}; $j > 0 ; $j--){
         $right->{key}->[$j] = $right->{key}->[$j - 1];
         $right->{node}->[$j + 1] = $right->{node}->[$j];
     }
     $right->{node}->[1] = $right->{node}->[0];
     $right->{n}++;
     $right->{key}->[0] = $p->{key}->[$k - 1];
     $p->{key}->[$k - 1] = $left->{key}->[$left->{n} - 1];
     $right->{node}->[0] = $left->{node}->[$left->{n}];
     $left->{n}--;
 } 
 
 # p->{node}[k]の最左要素をp->{key}[k-1]経由でp->{node}[k-1]に動かす
 sub moveleft{
     my ($s,$p,$k) = @_;
 
     my $left = $p->{node}->[$k - 1];
     my $right = $p->{node}->[$k];
     $left->{n}++;
     $left->{key}->[$left->{n} - 1] = $p->{key}->[$k - 1];
     $left->{node}->[$left->{n}] = $right->{node}->[0];
     $p->{key}->[$k - 1] = $right->{key}->[0];
     $right->{node}->[0] = $right->{node}->[1];
     $right->{n}--;
     for (my $j = 1 ; $j <= $right->{n} ; $j++){
         $right->{key}->[$j - 1] = $right->{key}->[$j];
         $right->{node}->[$j] = $right->{node}->[$j + 1];
     }
 }

 # p->{node}[k -1],p->{node}[k]を統合する
 sub combine{
     my ($s,$p,$k) = @_;

     my $right = $p->{node}->[$k];
     my $left = $p->{node}->[$k - 1];
     $left->{n}++;
     $left->{key}->[$left->{n} - 1] = $p->{key}->[$k - 1];
     $left->{node}->[$left->{n}] = $right->{node}->[0];
     for (my $j = 1; $j <= $right->{n}; $j++){
         $left->{n}++;
         $left->{key}->[$left->{n} - 1] = $right->{key}->[$j - 1];
         $left->{node}->[$left->{n}] = $right->{node}->[$j];
     }
     $s->removeitem($p,$k - 1);
     #free(right);
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
     my $k = 0;
     while($k < $p->{n} && $p->{key}->[$k] < $s->key) { $k++; }
     if ($k < $p->{n} && $p->{key}->[$k] == $s->key) {
         # 見つかった
         $s->deleted(1);
         if(($q = $p->{node}->[$k + 1])){
             $q = $q->{node}->[0] while ($q->{node}->[0]);
             $p->{key}->[$k] = $q->{key}->[0];
             $s->key($q->{key}->[0]);
             $s->deletesub($p->{node}->[$k + 1]);
             if($s->undersize){
                 $s->restore($p,$k + 1);
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
             $s->root = $s->root->{node}->[0];
             undef($p);
         }
         $s->message("削除しました");
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
 sub btree{
     my $s = shift;
     $s->M(int(rand(8)+2));
     $s->debugtext($s->debugtext . " (M:" . $s->M . ")"); 
     $s->insert($_ * 2) for (11 .. 15);
     $s->insert($_ * 2 - 1) for (1 .. 6);
     $s->insert($_) for (1 .. 20);
     $s->insert($_) for (30 .. 100);
     $s->insert(7);
     $s->delete($_) for (92 .. 99);
     $s->delete(11);
     $s->delete(51);
     $s->insert(11);
     $s->insert(51);
     $s->delete(75);

     $s->level(0);
     $s->tree_dump($s->root);
     $s->render(template => 'btree/btree','message'=> $s->message,
            'treetext'=>$s->debugtext);
 }

 1;

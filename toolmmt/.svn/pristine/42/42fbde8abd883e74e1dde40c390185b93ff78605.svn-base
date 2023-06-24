 package Tool::mmt::Controller::Chabo;
 use Mojo::Base 'Tool::mmt::Controller::Json';
 
=head1 NAME
  chabo - AI(Artificial incompetence) chabo(chat bot) module

=cut
 
 use Encode;
 #use Text::MeCab;
 use MeCab;

 has chatdata => 'test.chatdata';
 has markov => 'test.markov';
 
 sub sample_parse{
     my $s = shift;
     my $r = $s->text_parse($s->get_para('text','テスト'));
     $s->json_or_jsonp( $s->render_to_string(json => $r));
 }
 sub sample_put_together{
     my $s = shift;
     my @t = (join('',$s->put_together($s->get_para('text','perl'))));
     $s->json_or_jsonp( $s->render_to_string(json=>\@t));
 }
 sub sample_get_time_line{
     my $s = shift;
     my $r = $s->time_line();
     $s->json_or_jsonp( $s->render_to_string(json => $r));
 }
 sub talk{
     my $s = shift;
     my $r = $s->text_parse($s->get_para('text','perl'));
     my $w = $s->select_word($r);
     my @ans = (join('',$s->put_together($w)));
     unshift(@ans,$w);
     $s->json_or_jsonp( $s->render_to_string(json=>\@ans));
 }
 sub chatbot{
     my $s = shift;
     my $name = $s->get_para('name','no name');
     my $action = $s->get_para('action','');
     my $chat = $s->get_para('chat','');
     my $id = $s->write_log($name,$chat);
     my $r = $s->text_parse($chat);
     my ($w,$ans);
     if($ans = $s->greeting($r,$name,$chat)){
        $s->write_log('チャボ',$ans);
        return $s->stash->{answer} = $ans;
     }
     $w = $s->select_word($r);
     $ans = (join('',$s->put_together($w)));
     $ans = $s->arrange_text($ans);
     $s->put_markov($r,$id);
     $s->write_log('チャボ',$ans);
     $s->stash->{answer} = $ans;
 }
 sub arrange_text{
     my $s = shift;
     my $text = shift;
     $text =~ s/^RT@[^:]+://g;
     $text =~ s/\*\.jp://g;
     return $text;
 }
 sub write_log{
     my $s = shift;
     my $name = shift;
     my $chat = shift;
     return if($chat eq '');
     my $dbh = $s->app->model->webdb->dbh;
     $dbh->do("INSERT INTO  @{[$s->chatdata]} (name,chat) values (?,?)",undef,$name,$chat); 
     return $dbh->{mysql_insertid};
 }
 sub greeting{
     my $s = shift;
     my $ws = shift;
     my $name = shift;
     my $chat = shift;
     if($chat =~ m{(\)?\(?([-+]?\d+\)?\s*[-+*/%]\s*)+[-+]?\d+\)?)を計算}){
				return eval $1;}
     return "" if (@$ws > 6);
     my @a = grep {$_->{feature} =~ '感動詞'} @$ws;
     return "" if (@a == 0);
     my $prefix = "はい、";
     return $prefix . $a[int(rand scalar @a)]->{ surface } . " $name" . "さん";
 }
 sub select_word{
     my $s = shift;
     my $ws = shift;
     my @a = grep {$_->{feature} =~ '名詞'} @$ws;
     return $a[int(rand scalar @a)]->{ surface };
 }
 sub get_para{
     my $s = shift;
     my $item = shift||'text';
     my $def = shift;
     my $t = $s->param($item)||'';
     if ($t eq "") {
        $t = ref $s->req->json eq 'HASH' ? $s->req->json->{$item}  
                                         : $def;
     }
     return $t
 } 
 sub text_parse{
     my $s = shift;
     my $text = shift;

=POD
Text::MeCabが文字化けするのでMeCabに変えてみた

     my $parser = Text::MeCab->new();
     my $n = $parser->parse(encode('utf-8',$text));
     my @ret = ();
     while($n){
        push(@ret,+{surface=>decode('utf-8',$n->surface),feature=>decode('utf-8',$n->feature)});
        $n = $n->next;
     }

=cut

     my @ret = map { /(.*)\t(.*?),/
                ? +{ surface=>decode('utf-8',$1),feature=>decode('utf-8',$2) }
                : +{ surface=>'EOS'} }
            split("\n",MeCab::Tagger->new()->parse(encode('utf-8',$text)));
     return \@ret;
 }
  
 sub put_together{
     my $s = shift;
     my $word = shift||'わたし';
     my @words = ();
     my $dbh = $s->app->model->webdb->dbh;
     
     # 最初の一言
     my $sql = "select word1,word2 from @{[$s->markov]} where word1 like ? or word2 like ? order by rand() limit 1";
     my $data = $dbh->selectall_arrayref($sql,+{Slice => +{}},'%'.$word.'%','%'.$word.'%');
     push(@words,$data->[0]->{word1});
     push(@words,$data->[0]->{word2});
 
     # 後ろを作成
     $sql = "select word1,word2,word3 from @{[$s->markov]} where word1 = ? and word2 = ? order by rand() limit 1";
     my $sth = $dbh->prepare($sql);
     while(1){
         $sth->execute($words[-2],$words[-1]);
         if(my $ref = $sth->fetchrow_hashref()){
             if($ref->{word3} =~ /EOS/){
                 last;
             }
             push(@words,$ref->{word3});
         }else{
             last;
         }
     }
     
     # 前を作成
     $sql = "select word1,word2,word3 from @{[$s->markov]} where word2 = ? and word3 = ? order by rand() limit 1";
     $sth = $dbh->prepare($sql);
     while(1){
         $sth->execute($words[0],$words[1]);
         if(my $ref = $sth->fetchrow_hashref()){
             unshift(@words,$ref->{word1});
         }else{
             last;
         }
     }
     my $before = "";
     my $regex = qr/[a-zA-Z0-9!-.]{2,}/;
     for my $word (@words){
         if ($before =~ /$regex/ and $word =~ /$regex/){
            $word = " " . $word;
         }
         $before = $word;
     }
     return @words;
 }
 sub time_line{
     my $s = shift;
     my $limit = shift||50;
     my $start = shift||0; 
     my $dbh = $s->app->model->webdb->dbh;
     my $sql = "select UPD_TIME,name,chat from @{[$s->chatdata]} order by SEQ_NO desc limit ?,?";
     my $data = $dbh->selectall_arrayref($sql,+{Slice => +{}},$start,$limit);
     return $data;
 } 
 sub put_markov{
     my $s = shift;
     my $r = shift;
     my $id = shift;
     my $dbh = $s->app->model->webdb->dbh;
     my $sth = $dbh->prepare("insert @{[$s->markov]} (word1,word2,word3,chat_No,part)
 						values (?,?,?,?,?)");
     if (@$r > 2 ) {
         # 「2語の接頭語と1語の接尾語」のマルコフ連鎖テーブルを作成
         # $markov{接頭語前}{接頭語後ろ}[no]=接尾語 の形式
         # $markov{$wakatigaki[0]}{$wakatigaki[1]}[]=$wakatigaki[2];
 
         for (my $i = 2 ; $i < @$r ; $i++) {
 			$sth->execute($r->[$i-2]->{surface}
 				,$r->[$i-1]->{surface},$r->[$i]->{surface}
 				,$id,$r->[$i-2]->{feature});
         }
     }
 }
 1;

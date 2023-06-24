package Tool::mmt::Controller::Matrix;
use Mojo::Base 'Tool::mmt::Controller::Menu';
use Encode qw/ decode decode_utf8 encode encode_utf8/;

sub menu{
     my $s = shift;
     $s->render('matrix/menu');
}
sub matrixFixedCss{
    my $s = shift;
    my ($rows,$columns,@width) = @_;
    my $css ='';
    my $addLine = ':before{'
                .   'content:""; position:absolute; pointer-events:none;'
                .   'top:-1px; left:-1px; width:100%; height:100%;'
                .   'border-left: 1px solid #888;'
                .   'border-top:  1px solid #888;'
                . '}';
    my $left=0;
    for ( my $i=1; $i<=$rows; $i++){
        $left=0;
        for (my $j=1;$j<=$columns;$j++){
            $left+=$width[$j-1];
            $css .= ".fixed${i}${j}{ position: sticky; top: @{[($i-1)*1.5+3]}rem; left: ${left}rem; z-index: 2;background: white;}\n"
                 .  ".fixed${i}${j}${addLine}\n";
                 $css .= ".fixed9${j}{ position: sticky; bottom: 0;                   left: ${left}rem; z-index: 2;background: #747474;}\n"
                 .  ".fixed9${j}${addLine}\n" if($i==1);
        }
    }
    return $css;
}
sub head_line{
    my $s = shift;
    my $hd = "A";
    my $x = 3;
    my $text = '';
    for (my $i=1;$i<50;$i++){
        my $j = $i < $x ? $i : $x ;
        $text .= qq{<th class="fixed1$j" width="110px" nowrap>$hd</th>};
        $hd++;
    }
    return $text;
}
sub cell_make{
    my $s = shift;
    my $x = 3;
    my $y = 3;
    my $text = '';
    for (my $i=2;$i<100;$i++){
        $text .= "<tr>\n";
        for (my $j=1;$j<50;$j++){
            my $ci = $i < $x ? $i : $x;
            my $cj = $j < $y ? $j : $y;
            $text .= qq{<td class="fixed${ci}${cj}">} . $s->matrix_input($i,$j) . "</td>\n";
        }
        $text .= "</tr>\n";
    }
    return $text;
}
sub matrix_input{
    my $s = shift;
    my ($i,$j) = @_;
    my $text=qq{<input type="text" name="_i_${i}_${j}" id="_i_${i}_${j}" onclick="cursMode=false;" onkeydown="matrix_keyDown(event)" value="${i}-${j}">};
    return $text;
}
sub keyDown{
    my $s = shift;
	my $text = <<'EndScript';
var cursMode = true;
function matrix_keyDown(e){
    let id = e.srcElement.id;
    let res = id.match(/(_i_)(\d+)_(\d+)/);
    let y = 0;
    let x = 0;
    if(res[1] === '_i_'){
      y = Number(res[2]);
      x = Number(res[3]);
    }
    document.getElementById('item1').innerText = id + " " + e.keyCode;
    if (cursMode && e.keyCode == 39) {
       x += 1;
    }else if (cursMode && e.keyCode == 37) {
       x -= 1; 
    }else if (e.keyCode == 40) {
       y += 1;
       cursMode = true;
    }else if (e.keyCode == 38) {
       y -= 1;
       cursMode = true;
    }else if (e.keyCode == 13) {  // Enter
       x = 1;
       y += 1;
       cursMode = true;
    }else if (e.keyCode == 36) {   // Home
       y = 2;
       cursMode = true;
    }else if (e.keyCode == 35) {   // End
       y = 99;
       cursMode = true;
    }else if (e.keyCode == 9) {   // Tab
       cursMode = true;
    }else{
       cursMode = false;
    }
    if(res[1] === '_i_' && y > 1 && x > 0 && cursMode){
       id = res[1] + y + "_" + x;
       document.getElementById(id).focus();
       document.getElementById(id).scrollIntoView({block: 'center',inline: 'center'});
    }
}
EndScript
	return $text;
}
1;

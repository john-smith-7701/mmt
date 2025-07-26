var note2pdf = (function (){
  const orderTbl2 = document.getElementById("bodyApplication2");
  var focusable = [];
  var texts = [];
  var starti = '';
  var hiduke = {};
  var oya = {};
  var hidukeID = '';
  var inFocus = '';
  document.getElementById('select3').click();
  const loadJsonInput = document.getElementById('load-json');
  loadJsonInput.addEventListener('change', function () {
      note2pdf.makeInputArea();
  });

  async function makeInputArea() {

      await ps4pdf.sleep(1000);
      texts = ps4pdf.getTexts();
      orderTbl2.innerHTML = '';
      mae = '';
      starti = '';
      hiduke = {};
      hidukeID = '';
      oya = {};

      await texts.forEach((t,i) => {
          t.selected = false;  //全セレクトをクリア
          if(t.textAlign != 'none'){
              const template = document.createElement('template');
              let inputType = "text";
              let element = "";
              let disabled = '';
              let labelName = t.name;
              let match = t.name.match(/（(元号|年|月|日|年月日)）/);
              if(match){
                  inputType = "date";
                  element = match[1];
                  if(hidukeID === ''){
                      hidukeID = i;
                      hiduke[hidukeID] = [];
                      hiduke[hidukeID].push(hidukeID);
                  }else{
                      hiduke[hidukeID].push(i);
                      inputType = "text";
                      disabled = 'disabled';
                  }
                  oya[i] = hidukeID;
                  labelName = labelName.replace(/（.*）/,'');
              }else{
                  if(hidukeID !== ''){
                      mae = hidukeID;
                  }
                  hidukeID = '';
              }
              match = t.name.match(/(画像|署名)/);
              if(match){
                  element = 'img';
              }
              template.innerHTML = `<tr id="tr${i}" data-id="${i}" draggable="true" class="fixed10 ${disabled}">
               <td>${labelName}<br><input type="${inputType}" data-type="${inputType}" data-element="${element}" data-id="${i}" id="input${i}" value="${t.text}" onfocus="note2pdf.focus_rtn(this);" onblur="note2pdf.blur_rtn(this);"></td></tr>`;
              orderTbl2.appendChild(template.content.firstElementChild);
              if(mae !== ''){
                  focusable[mae] = i;
              }
              if(starti === ''){
                  starti = i;
              }
              mae = i;

          }
      });
      focusable[mae] = starti;
      text2InputHiduke();

      const input = document.getElementById(`input${starti}`);
      texts[starti].selected = true;
      ps4pdf.setTexts(texts);
      ps4pdf.redrawCanvas();
      input.focus();
      input.select();
  }
  //日付項目を入力エリアにセット
  function text2InputHiduke(){
      const eras = {
          '令和': 2019,
          '平成': 1989,
          '昭和': 1926,
          '大正': 1912,
          '明治': 1868,
          '': 0
      };

      Object.keys(hiduke).forEach(key => {
          const t = hiduke[key];
          if(t.length == 4){
            const inputDate = document.getElementById(`input${t[0]}`);
            inputDate.value = (eras[texts[t[0]].text] + z2n(texts[t[1]].text) - 1) + '-' + ('00'+z2n(texts[t[2]].text)).slice(-2) + '-' + ('00'+z2n(texts[t[3]].text)).slice(-2);
          }
      });
  }
  function z2n(text){
      let x = text.replace(/[^０-９0-9]/g,'');
      x = x.replace(/[０-９]/g,function(s){
          return String.fromCharCode(s.charCodeAt(0) - 0xFEE0);
      });
      return Number(x);
  }
  //フォーカスが入った時
  async function focus_rtn(el){
      const match = el.id.match(/input(\d+)$/);
      if(!match){return;}
      let element = el.dataset.element;
      if(element === 'img' ){texts = ps4pdf.getTexts();}
      let i = match[1];
      if(inFocus !== ''){
        texts[inFocus].selected = false;
      }
      inFocus = i;
      el.style.backgroundColor = 'lightyellow';
      texts[i].selected = true;
      if(i in oya){
          hiduke[oya[i]].forEach(ii => {texts[ii].selected = true;});
      }
      ps4pdf.setTexts(texts);
      await ps4pdf.sleep(200);
      ps4pdf.redrawCanvas();
  }
  //フォーカスが離れた時
  function blur_rtn(el){
      const match = el.id.match(/input(\d+)$/);
      if(!match){return;}
      let inputType = el.dataset.type;
      let element = el.dataset.element;
      let i = match[1];
      if(element === 'img' && inFocus === i){return;}
      if(inputType == 'date' ){
          editymd(el,i,element);
      }
      el.style.backgroundColor = '';
      blueTab(i,el);
  }

  document.addEventListener('keydown', function(e) {
    if(e.key === 'Tab'){
        inFocus = '';
    }
    if (e.key === 'Enter') {
      const el = e.target;
      const match = el.id.match(/input(\d+)$/);
      if(match){
        texts[focusable[match[1]]].selected = true;
        blueTab(match[1],el);
      }
    }
  });
  //離れる時にデータをセーブ
  async function blueTab(i,el){
    if(el.dataset.type != 'date'){
      texts[i].text = el.value;
    }
    texts[i].selected = false;
    el.style.backgroundColor = '';
    if(i in hiduke){
        hiduke[i].forEach(ii => {texts[ii].selected = false;});
    }
    ps4pdf.setTexts(texts);
    await ps4pdf.sleep(200);
    ps4pdf.redrawCanvas();
  } 

  function editymd(el,i,element){
      const value = el.value;
      const ymd = new Date(value);
      let gymd;
      if(hiduke[el.dataset.id].length === 4){
        gymd = ymd.toLocaleDateString("ja-JP-u-ca-Japanese", { era: "long" });
        const match = gymd.match(/^(\D+)(\d+)\D+(\d+)\D+(\d+)$/);
        if(match){
            hiduke[el.dataset.id].forEach((id,i) => {
                texts[id].text = match[i+1];
                if(i != 0){
                    document.getElementById(`input${id}`).value = match[i+1];
                }
            });
        }
      }
  }
  //手書きサイン処理
	function openDialog() {
		document.getElementById("myDialog").showModal();
	}
  const canvas = document.getElementById('signature');
  const ctx = canvas.getContext('2d');
  let drawing = false;

  canvas.addEventListener('pointerdown', (e) => {
    drawing = true;
    ctx.beginPath();
    ctx.moveTo(e.offsetX, e.offsetY);
  });
  canvas.addEventListener('pointermove', (e) => {
    if (drawing) {
      ctx.lineWidth = 5;
      ctx.lineTo(e.offsetX, e.offsetY);
      ctx.stroke();
    }
  });
  canvas.addEventListener('pointerup', () => {
    drawing = false;
  });

  function clearCanvas() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
  }

  document.getElementById('signForm').addEventListener('submit', async (e) => {
    e.preventDefault();

    // サインをPNG画像として取得
    const dataUrl = canvas.toDataURL('image/png');
    //const blob = await (await fetch(dataUrl)).blob();
    texts.forEach(t => { if(t.selected) {
        t.image = dataUrl.split(',')[1];
    }});
    ps4pdf.setTexts(texts);
    ps4pdf.redrawCanvas();

    clearCanvas();
    myDialog.close();
  });

  return {
      focus_rtn(el) {
          focus_rtn(el);
      },
      blur_rtn(el) {
          blur_rtn(el);
      },
      makeInputArea(){
          makeInputArea();
      },
      openDialog(){
          openDialog();
      },
      clearCanvas(){
          clearCanvas();
      }
  };
})();

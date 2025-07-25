var ps4pdf = (function (){
  const canvas = document.getElementById('pdf-canvas');
  const ctx = canvas.getContext('2d');
  const fileInput = document.getElementById('pdf-upload');
  const textInput = document.getElementById('textInput');
  const colorPicker = document.getElementById('colorPicker');
  const fontSize = document.getElementById('fontSizeSelect');
  const fontName = document.getElementById('fontNameSelect');
  const textAlign = document.getElementById('text-align');
  const saveJsonBtn = document.getElementById('save-json');
  const loadJsonInput = document.getElementById('load-json');
  const cvTop = document.getElementById('cvTop');
  const orderTbl = document.getElementById("bodyApplication");
  const orderPnl = document.getElementById("orderPnl");
  const sleep = msec => new Promise(resolve => setTimeout(resolve, msec));

  let texts = [];
  let selectedIndex = -1;
  let isDragging = false;
  let isMoving = false;
  let isResizing = false;
  let resizeDir = '';
  let startX = 0, startY = 0;
  let offsetX = 0, offsetY = 0;
  let pdfBackground = null;
  const HANDLE_SIZE = 8;
  let currentPdfFilename = "textdata.json"; // デフォルト
  let history = [];
  let undohis = [];
  let currentMode = 'create';
  let lastID = 0;
  let pdfurl = null;
  function KeyPress(e){
      var evtobj = window.event? event : e;
      if(evtobj.keyCode == 26 && evtobj.ctrlKey){     // CTRL+z
          if(event.shiftKey){
           redo();
          }else{
              undo();
          }
      }
      if(evtobj.keyCode == 25 && evtobj.ctrlKey){      // CTRL+y
          redo();
      }
  }
  function undo(){
      if(history.length){
          texts = history.pop();
          redrawCanvas();
          undohis.push(history.pop());
      }
  }
  function redo(){
      if(undohis.length){
          texts = undohis.pop();
          redrawCanvas();
      }
  }
  document.onkeypress = KeyPress;                     // Key Press イベントハンドラセット
  
  function getFont() {
    return `${fontSize.value}px ${fontName.value}`;
  }
  
  function redrawCanvas() {
    if (pdfBackground) {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.drawImage(pdfBackground, 0, 0);
    }
  
    texts.forEach((item, index) => {
      ctx.fillStyle = item.selected ? 'rgba(255,0,0,0.3)' : 'rgba(0,0,255,0.2)';
      if(item.textAlign == 'none'){
          ctx.fillStyle = 'rgba(255,255,255)';
      }
      ctx.fillRect(item.x, item.y, item.w, item.h);
      ctx.font = item.font || getFont();
      ctx.fillStyle = item.color || '#000';
      if ((item.image) && item.image != ''){
          const img = new Image();
         img.src = "data:image/png;base64,"+item.image;
          ctx.drawImage(img, item.x, item.y, item.w, item.h); // x, y, width, heigh
      }
      if (item.textAlign === 'vertical') {
          ctx.textAlign = 'right';
          drawVerticalText(ctx, item.text, item.x, item.y, item.w, item.h, item.fontSize);
      } else {
          ctx.textAlign = item.textAlign;
          wrapText(ctx, item.text, item.textAlign == 'right' ? item.x + item.w + 5: item.x, item.y + parseInt(item.fontSize) - 2, item.w, 20);
      }
      if (index === selectedIndex) drawHandles(item);

      const row = document.getElementById(`tr${index}`);
      if (item.selected){
          row.style.backgroundColor = 'lightblue';
          const input = document.getElementById(`input${index}`);
          if(input){
            input.focus();
            input.select();
            input.scrollIntoView({block: 'end'});
          }
      }else{
          row.style.backgroundColor = '';
      }
    });
    history.push(JSON.parse(JSON.stringify(texts)));
    if(history.length > 200){
        history = history.splice(0,100);
    }
  }
  //疑似縦書き
  function drawVerticalText(ctx, text, x, y, w, h, fontSize) {
    const chars = text.split('');
    chars.forEach((char, i) => {
      ctx.fillText(char, x + w , y + (i+1) * fontSize);
    });}
  
  function wrapText(context, text, x, y, maxWidth, lineHeight) {
    const words = text.split(' ');
    let line = '';
    for (let i = 0; i < words.length; i++) {
      const testLine = line + words[i] + ' ';
      const metrics = context.measureText(testLine);
      if (metrics.width > maxWidth && i > 0) {
        context.fillText(line, x, y);
        line = words[i] + ' ';
        y += lineHeight;
      } else {
        line = testLine;
      }
    }
    context.fillText(line, x, y);
  }
  
  // ドラッグ・選択・編集・削除・保存・読み込み処理（省略せず完全動作）
  function drawHandles(item) {
    const handles = [
      { x: item.x + item.w, y: item.y + item.h, dir: 'se' },
    ];
    ctx.fillStyle = 'black';
    handles.forEach(h => ctx.fillRect(h.x - 4, h.y - 4, 8, 8));
  }
  function getHandleUnderMouse(mx, my, item) {
    return [
      { x: item.x + item.w, y: item.y + item.h, dir: 'se' },
    ].find(h => mx >= h.x - 6 && mx <= h.x + 6 && my >= h.y - 6 && my <= h.y + 6);
  }
  // 入力順テーブル作成
  function orderTblSet(){
    orderTbl.innerHTML = '';
    texts.forEach((t, i) => { orderLineSet(t,i)});
  }
  function orderLineSet(t,i){
    const template = document.createElement('template');
    template.innerHTML = `<tr id="tr${i}" data-id="${i}" draggable="true" class="fixed10">
        <td>${t.id}</td><td><input type="text" id="inp${i}" value="${t.name}"></td></tr>`;
    orderTbl.appendChild(template.content.firstElementChild);
  }
 
  fileInput.addEventListener('change', function () {
    const file = this.files[0];
    if (file && file.type === 'application/pdf') {
      const reader = new FileReader();
      reader.onload = function () {
        const typedarray = new Uint8Array(reader.result);
        pdfjsLib.getDocument({ data: typedarray }).promise.then(pdf => {
          return drawPDFonCanvas(pdf);
        });
      };
      reader.readAsArrayBuffer(file);
    }
  });

  //PDFをキャンバスに描画
  function drawPDFonCanvas(pdf){
    return pdf.getPage(1).then(page => {
      const scale = 1.336;
      const viewport = page.getViewport({ scale });
      canvas.width = viewport.width;
      canvas.height = viewport.height;
      return page.render({ canvasContext: ctx, viewport }).promise.then(() => {
        pdfBackground = new Image();
        pdfBackground.src = canvas.toDataURL("image/png");
        pdfBackground.onload = () => redrawCanvas();
      });
    });
  }
  //編集内容をキャンバスに描画
  function drawJSONonCanvas(){
    texts.forEach((t) => {
      if ('id' in t) {
        if (t.id > lastID) { lastID = t.id; }
      } else {
        t['id'] = ++lastID;
      }
      if (!('name' in t)) {
        t['name'] = t['id'];
      }
    });
    orderTblSet();
    redrawCanvas();
  }
  const loadServerPdf = document.getElementById('loadServerPdf');
  if(loadServerPdf){
    loadServerPdf.addEventListener('click', function () {
    pdfurl = '/pdf/nouzeisyoumeiseikyuu.pdf'; // サーバー上のPDFパス（適宜変更）
    fileInput.files[0] = null;
    fileInput.value = '';
    loadJsonInput.files[0] = null;
    loadJsonInput.value = '';

    pdfjsLib.getDocument(pdfurl).promise.then(pdf => {
      return drawPDFonCanvas(pdf);
    }).catch(err => {
      console.error('PDFの読み込みに失敗しました:', err);
    });

    lastID = 0;
    fetch('/json/nouzeisyoumeiseikyuu.json') // ← サーバー上のJSONファイルのパスに変更
      .then(response => {
        if (!response.ok) {
          throw new Error('サーバーエラー: ' + response.status);
        }
        return response.json();
      })
      .then(async (json) => {
        const orderTbl2 = document.getElementById("bodyApplication2");
        if(orderTbl2){ orderTbl2.innerHTML = '';}
        const reader = new FileReader();
        texts = JSON.parse(JSON.stringify(json));
        drawJSONonCanvas();
        currentPdfFilename = "textdata.json"; // サーバーからなので固定名でOK
        note2pdf.makeInputArea();
      })
      .catch(err => {
        alert('JSONの読み込みに失敗しました: ' + err);
      });

    history = [];
    });
  }


  document.getElementsByName('mode').forEach(radio => {
    radio.addEventListener('change', () => {
        if(radio.value == 'order'){
            orderPnl.style.display = 'block';
        }else{
            orderPnl.style.display = 'none';
        }
    });
    });
  
  canvas.addEventListener('mousedown', (e) => {
    const rect = canvas.getBoundingClientRect();
    const mx = e.clientX - rect.left;
    const my = e.clientY - rect.top;
    startX = mx; startY = my;
    selectedIndex = -1;
    isDragging = true; isResizing = false; isMoving = false;
  
    texts.forEach((item, index) => {
      const handle = getHandleUnderMouse(mx, my, item);
      if (handle) {
        selectedIndex = index;
        isResizing = true;
        resizeDir = handle.dir;
      } else if (mx >= item.x && mx <= item.x + item.w && my >= item.y && my <= item.y + item.h) {
        selectedIndex = index;
        isMoving = true;
        offsetX = mx - item.x;
        offsetY = my - item.y;
      }
    });
  });
  
  canvas.addEventListener('mousemove', (e) => {
    if (selectedIndex < 0) return;
    const rect = canvas.getBoundingClientRect();
    const mx = e.clientX - rect.left;
    const my = e.clientY - rect.top;
    const item = texts[selectedIndex];
    const dx = mx - startX, dy = my - startY;
  
    if (isResizing) {
      startX = mx; startY = my;
      texts.forEach(t => {
        if(t.selected){
          switch (resizeDir) {
            case 'nw': t.x += dx; t.y += dy; t.w -= dx; t.h -= dy; break;
            case 'ne': t.y += dy; t.w += dx; t.h -= dy; break;
            case 'sw': t.x += dx; t.w -= dx; t.h += dy; break;
            case 'se': t.w += dx; t.h += dy; break;
          }
        }
      });
      redrawCanvas();
    } else if (isMoving) {
      nx = item.x - (mx - offsetX);
      ny = item.y - (my - offsetY);
      texts.forEach(t => {
        if(t.selected){
          t.x -= nx;
          t.y -= ny;
        }
      });
      redrawCanvas();
    }
  });
  
  canvas.addEventListener('mouseup', (e) => {
    if (isDragging && !isMoving && !isResizing) {
      const rect = canvas.getBoundingClientRect();
      const mx = e.clientX - rect.left;
      const my = e.clientY - rect.top;
      const w = mx - startX;
      const h = my - startY;
      if (Math.abs(w) > 5 && Math.abs(h) > 5) {
        if(document.querySelector("input[name='mode']:checked").value == "create"){
          texts.push({
            x: Math.min(startX, mx),
            y: Math.min(startY, my),
            w: Math.abs(w),
            h: Math.abs(h),
            text: '',
            color: colorPicker.value,
            font: getFont(),
            fontSize: fontSize.value,
            fontName: fontName.value,
            textAlign: textAlign.value,
            id: ++lastID,
            name: lastID
          });
          selectedIndex = texts.length - 1;
          orderLineSet(texts[selectedIndex],selectedIndex);
          showTextInput(rect.left, rect.top);
        }
      }
    }
    isDragging = isMoving = isResizing = false;
  });
  
  canvas.addEventListener('click', (e) => {
    const rect = canvas.getBoundingClientRect();
    const mx = e.clientX - rect.left;
    const my = e.clientY - rect.top;
    selectedIndex = -1;
    texts.forEach((item, index) => {
      if (mx >= item.x && mx <= item.x + item.w && my >= item.y && my <= item.y + item.h) {
        if (e.shiftKey) {
          item.selected = !item.selected;
        } else {
          texts.forEach(t => t.selected = false);
          item.selected = true;
          selectedIndex = index;
          if(typeof oya !== 'undefined'){
            if(index in oya){
              hiduke[oya[index]].forEach(i => {texts[i].selected = true;});
            }
          }
        }
        redrawCanvas();
      }
    });
    if (selectedIndex >= 0) showTextInput(rect.left, rect.top);
    if(document.querySelector("input[name='mode']:checked").value == "create"){
    }else{
      texts.forEach(t => {
        const hit = startX <= t.x && mx >= t.x + t.w && startY <= t.y && my >= t.y + t.h;
        if (hit) t.selected = !t.selected;
      });
      redrawCanvas();
    }
  });
  
  function showTextInput(offsetLeft, offsetTop) {
    const item = texts[selectedIndex];
    textInput.style.width = `${item.w}px`;
    textInput.style.font = item.font || getFont();
    textInput.style.color = item.color || '#000';
    textInput.style.display = 'block';
    textInput.value = item.text;
    fontSize.value = item.fontSize;
    fontName.value = item.fontName;
    textAlign.value = item.textAlign;
    textInput.focus();
  }
  
  textInput.addEventListener('keydown', function (e) {
    if (e.key === 'Enter') {
      if (selectedIndex >= 0) {
        texts[selectedIndex].text = textInput.value;
        texts[selectedIndex].color = colorPicker.value;
        texts[selectedIndex].font = getFont();
        texts[selectedIndex].fontSize = fontSize.value;
        texts[selectedIndex].fontName = fontName.value;
        texts[selectedIndex].textAlign = textAlign.value;
        redrawCanvas();
      }
      textInput.style.display = 'none';
    }
  });
  // 項目削除 
  window.addEventListener('keydown', (e) => {
    if (e.key === 'Delete' && selectedIndex >= 0) {
      texts = JSON.parse(JSON.stringify(updateItems()));
      texts.splice(selectedIndex, 1);
      selectedIndex = -1;
      textInput.style.display = 'none';
      orderTblSet();
      redrawCanvas();
    }
  });
  function updateItems(){
    const rows = document.querySelectorAll('#tblApplication tbody tr');
    let newTexts = [];
    Array.from(rows).map(row => {
        const id = row.dataset.id;
        texts[id].name = document.getElementById(`inp${id}`).value;
        newTexts.push(texts[id]);
    });
    return newTexts;
  }
  
  saveJsonBtn.addEventListener('click', () => {
    let newTexts = updateItems();
    const blob = new Blob([JSON.stringify(newTexts)], { type: 'application/json' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = currentPdfFilename;
    a.click();
  });

  colorPicker.addEventListener('change', () => {
    texts.forEach(t => { if(t.selected) {t.colorPicker = colorPicker.value; }});
    redrawCanvas();
  });
  fontSize.addEventListener('change', () => {
    texts.forEach(t => { if(t.selected) {t.fontSize = fontSize.value; }});
    redrawCanvas();
  });
  fontName.addEventListener('change', () => {
    texts.forEach(t => { if(t.selected) {t.fontName = fontName.value; }});
    redrawCanvas();
  });
  textAlign.addEventListener('change', () => {
    texts.forEach(t => { if(t.selected) {t.textAlign = textAlign.value; }});
    redrawCanvas();
  });
  // ローカルJSON読込
  loadJsonInput.addEventListener('change', function () {
    lastID = 0;
    const file = this.files[0];
    if (!file) return;
    const orderTbl2 = document.getElementById("bodyApplication2");
    if(orderTbl2){ orderTbl2.innerHTML = '';}
    const reader = new FileReader();
    reader.onload = async (e) => {
      try {
        await sleep(500);
        texts = JSON.parse(e.target.result);
        drawJSONonCanvas();
        currentPdfFilename = file.name || "textdata.json";
      } catch (err) {
        alert(err);
      }
    };
    history = [];
    reader.readAsText(file);
  });
  // 選択項目コピー処理
  document.getElementById("copy-selected").addEventListener("click", () => {
    const clones = texts.filter(t => t.selected).map(t => {
      t.selected = false;
      id = ++lastID;
      return { ...t, x: t.x + 30, y: t.y + 10, id: id, name: id, selected: true };
    });
    i = texts.length;
    clones.map((tt) => {orderLineSet(tt,i++);});
    texts.push(...clones);
    redrawCanvas();
  });
  // 左側を揃える
  document.getElementById("align-left").addEventListener("click", () => {
      min = Math.min.apply(null,texts.filter(o => o.selected).map(o => o.x));
      texts.forEach(t => { if(t.selected) {t.x = min; }});
      redrawCanvas();
  });
  // 上側を揃える
  document.getElementById("align-top").addEventListener("click", () => {
      min = Math.min.apply(null,texts.filter(o => o.selected).map(o => o.y));
      texts.forEach(t => { if(t.selected) {t.y = min; }});
      redrawCanvas();
  });
  //画像を描画
  document.getElementById('image-upload').addEventListener('change', function (e) {
    const file = e.target.files[0];
    if (!file) return;
  
    const img = new Image();
    const reader = new FileReader();
    reader.onload = function (event) {
      img.onload = function () {
          texts.forEach(t => { if(t.selected) {
              t.image = img.src.split(',')[1];
          }});
          redrawCanvas();
      };
      img.src = event.target.result;
    };
    reader.readAsDataURL(file);
  });
  
  // ✅ サーバーに送信してPDFを作成する処理
  document.getElementById("sendToServer").addEventListener("click", async () => {
    let file = fileInput.files[0];
    if (!file) {
      if(pdfurl){
        const response = await fetch(pdfurl);
        const blob = await response.blob();
        file = new File([blob], "sample.pdf", { type: "application/pdf" });
      }else{
        alert("PDFファイルを選択してください。");
        return;
      }
    }
    const lineEdit = (item) =>{
        return ({
          image: item.image,
          text: item.text,
          left: parseInt(item.x),
          top: parseInt(item.y) + parseInt(cvTop.value),
          width: item.w + "px",
          height: item.h + "px",
          color: item.color,
          "font-size": item.fontSize + "px",
          "font-family": item.fontName,
          "text-align": item.textAlign,
          "white-space": "pre-wrap",
          "overflow-wrap": "break-word",
          "background": item.textAlign == 'none' ? '#FFF' : 'none',
          "writing-mode": item.textAlign == 'vertical' ? 'vertical-rl' : 'horizontal-tb',
        });
    };
    //白抜きを先にセットする
    const formattedTexts = texts.filter(o => o.textAlign == 'none').map(item => { return lineEdit(item); });
    const formattedTexts2 = texts.filter(o => o.textAlign != 'none').map(item => { return lineEdit(item); });
    const formData = new FormData();
    formData.append("pdf", file);
    formData.append("json", JSON.stringify({ texts: formattedTexts.concat(formattedTexts2) }));
  
    try {
      //const response = await fetch("https://app-9c073af5-8e79-4e94-aeec-15ecaad5bdd0.ingress.apprun.sakura.ne.jp/edit-pdf", 
      const response = await fetch("https://qweer.info/docker/editpdf/edit-pdf", {
        method: "POST",
        body: formData
      });
  
      if (!response.ok) throw new Error("サーバーエラー");
  
      const blob = await response.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = "edited.pdf";
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    } catch (err) {
      alert("PDF生成失敗: " + err);
    }
  });

  //テーブルの行をドラッグで入れ替える
    document.addEventListener('DOMContentLoaded', () => {
      const table = document.getElementById('tblApplication');
      let draggedRow = null;

      table.addEventListener('dragstart', (e) => {
        if (e.target.tagName === 'TR') {
          draggedRow = e.target;
          e.dataTransfer.effectAllowed = 'move';
          e.dataTransfer.setData('text/html', e.target.outerHTML);
          e.target.style.opacity = '0.5';
        }
      });

      table.addEventListener('dragover', (e) => {
        e.preventDefault();
        const targetRow = e.target.closest('tr');
        if (targetRow && targetRow.parentNode === draggedRow.parentNode && targetRow !== draggedRow) {
          const tbody = table.tBodies[0];
          const rect = targetRow.getBoundingClientRect();
          const next = (e.clientY - rect.top) > (rect.height / 2);
          tbody.insertBefore(draggedRow, next ? targetRow.nextSibling : targetRow);
        }
      });

      table.addEventListener('drop', (e) => {
        e.preventDefault();
        draggedRow.style.opacity = '1';
        draggedRow = null;
      });

      table.addEventListener('dragend', (e) => {
        if (draggedRow) {
          draggedRow.style.opacity = '1';
        }
        draggedRow = null;
      });
    });
    
    return {
        getTexts() {
            return texts;
        },
        setTexts(newTexts) {
            texts = JSON.parse(JSON.stringify(newTexts));
        },
        redrawCanvas() {
          redrawCanvas();
        },
        async sleep(millisecond) {
            await sleep(millisecond);
        }

    };
})();


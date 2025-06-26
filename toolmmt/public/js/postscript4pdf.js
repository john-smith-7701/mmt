//pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.9.179/pdf.worker.min.js';
var postscript4pdf = (function (){
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

fileInput.addEventListener('change', function () {
  const file = this.files[0];
  if (file && file.type === 'application/pdf') {
    const reader = new FileReader();
    reader.onload = function () {
      const typedarray = new Uint8Array(reader.result);
      pdfjsLib.getDocument({ data: typedarray }).promise.then(pdf => {
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
      });
    };
    reader.readAsArrayBuffer(file);
  }
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
    item.x = mx - offsetX;
    item.y = my - offsetY;
    texts.forEach(t => {
      if(item != t && t.selected){
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
        textAlign: textAlign.value
      });
      selectedIndex = texts.length - 1;
      showTextInput(rect.left, rect.top);
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
        redrawCanvas();
      } else {
        texts.forEach(t => t.selected = false);
        item.selected = true;
        selectedIndex = index;
        redrawCanvas();
      }
    }
  });
  if (selectedIndex >= 0) showTextInput(rect.left, rect.top);
});

function showTextInput(offsetLeft, offsetTop) {
  const item = texts[selectedIndex];
  //textInput.style.left = `${item.x + offsetLeft}px`;
  //textInput.style.top = `${item.y + offsetTop}px`;
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

window.addEventListener('keydown', (e) => {
  if (e.key === 'Delete' && selectedIndex >= 0) {
    texts.splice(selectedIndex, 1);
    selectedIndex = -1;
    textInput.style.display = 'none';
    redrawCanvas();
  }
});

saveJsonBtn.addEventListener('click', () => {
  const blob = new Blob([JSON.stringify(texts)], { type: 'application/json' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = currentPdfFilename;
  a.click();
});

loadJsonInput.addEventListener('change', function () {
  const file = this.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = function (e) {
    try {
      texts = JSON.parse(e.target.result);
      redrawCanvas();
      currentPdfFilename = file.name || "textdata.json";
    } catch (err) {
      alert('JSON読み込みエラー');
    }
  };
  history = [];
  reader.readAsText(file);
});
// 選択項目コピー処理
document.getElementById("copy-selected").addEventListener("click", () => {
  const clones = texts.filter(t => t.selected).map(t => {
    t.selected = false;
    return { ...t, x: t.x + 30, y: t.y + 10, selected: true };
  });
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
  const file = fileInput.files[0];
  if (!file) {
    alert("PDFファイルを選択してください。");
    return;
  }

  const formattedTexts = texts.map(item => ({
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
  }));

  const formData = new FormData();
  formData.append("pdf", file);
  formData.append("json", JSON.stringify({ texts: formattedTexts }));

  try {
    //const response = await fetch("https://app-9c073af5-8e79-4e94-aeec-15ecaad5bdd0.ingress.apprun.sakura.ne.jp/edit-pdf", {
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
})();

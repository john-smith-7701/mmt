/**
 * さくらAI Engine のテキストメッセージを安全かつリッチHTMLへ変換する
 *
 * @param {string} text - AI が返す生テキスト
 * @returns {string} - サニタイズ済みかつ装飾済みHTML文字列
 */
function convertAiMessageToHtml(text) {
    if (typeof text !== "string") return "";
    const escapeHtml = (str) =>
      str
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#39;")
        .replace(/\\`/g, "&#60;");

    // まずは全体をエスケープしてから、HTML化したい部分だけ逆変換
    text = escapeHtml(text);

    let isTable = false;
    let tableHd = false;
    let headerRow = '';
    let alignRow = '';
    let dataRows = [];
    // パイプで分割し、先頭・末尾の余計な空文字を除去
    const splitRow = (row) =>
      row
        .trim()
        .replace(/^(\|)/, "")
        .replace(/(\|)$/, "")
        .split("|")
        .map((cell) => cell.trim());

    let rows = text.split("\n");
    let newrows = [];
    rows.forEach((row) => {
        if(/^\|/.test(row)){
            cols = splitRow(row);
            if(isTable){
                dataRows.push(row);
                if(tableHd){
                    tableHd = false;
                    row = "<tbody>";
                }else{
                    row = `<tr>`;
                    cols.forEach((cell,i) => {
                        row += `<td style="left">${ cell}</td>`;
                    });
                    row += `</tr>`;
                }
            }else{
                isTable = true;
                tableHd = true;
                row = `<table class="aiTable" border="1"><tr>`;
                cols.forEach((cell,i) => {
                    row += `<th style="left">${cell}</th>`;
                });
                row += `</tr>`;
            }
        }else{
            if(isTable){
                isTable =false;
                row = `</tbody></table>\n${row}`;
            }else{
            }
        }
        newrows.push(row);

    });
  
  let page = newrows.join("\n");
  // **太字**
  page = page.replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
  // *斜体*
  page = page.replace(/\*([^*]+)\*/g, "<em>$1</em>");
  // ```ブロックコード``` → <pre><code>
  page = page.replace(
    /```([\s\S]*?)```/g,
    (match, p1) =>
      `<pre><code>${p1}</code></pre>`
  );
  // `インラインコード`
  page = page.replace(/`([^`]+?)`/g, "<code>$1</code>");

  // -------------------------------------------------------------
  // 4️⃣ URL 自動リンク化
  // -------------------------------------------------------------
  const urlPattern = /https?:\/\/[^\s<]+/g;
  page = page.replace(urlPattern, (url) => {
    //const safeUrl = escapeHtml(url);
    return `<a href="${url}" target="_blank" rel="noopener noreferrer">${url}</a>`;
  });

  return page;
}

/* -------------------------------------------------------------
   エクスポート（Node でも使えるように）
   ------------------------------------------------------------- 
if (typeof module !== "undefined" && module.exports) {
  module.exports = { convertAiMessageToHtml };
}
if (typeof export !== "undefined") {
  export { convertAiMessageToHtml };
}
 */

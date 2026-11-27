// Tiện ích chung cho các script export: ghi JSON dễ đọc (ngắn thì gọn một dòng, dài thì xuống dòng)
// và ghi dữ liệu thành nhiều file con trong một thư mục.
//   const { writeJson, writeParts } = require('./lib');
const fs = require('fs');
const path = require('path');

const WIDTH = 110;   // độ rộng tối đa của một dòng gọn

// như JSON.stringify nhưng có khoảng trắng sau dấu ':' và ',' cho dễ đọc
function flat(v) {
  if (v === null || typeof v !== 'object') return JSON.stringify(v);
  if (Array.isArray(v)) return '[' + v.map(flat).join(', ') + ']';
  return '{' + Object.keys(v).map(k => JSON.stringify(k) + ': ' + flat(v[k])).join(', ') + '}';
}

function isPrim(v) { return v === null || typeof v !== 'object'; }

// col = số cột đã dùng bên trái (thụt lề + khóa) để biết còn chỗ cho giá trị
function format(v, col = 0, indent = 0) {
  const fl = flat(v);
  if (isPrim(v) || col + fl.length <= WIDTH) return fl;
  const pad = '  '.repeat(indent + 1), end = '  '.repeat(indent);
  if (Array.isArray(v)) {
    if (v.every(isPrim)) {   // mảng số/chuỗi dài: xếp nhiều phần tử mỗi dòng
      const lines = []; let cur = '';
      for (const x of v) {
        const t = JSON.stringify(x);
        if (cur && pad.length + cur.length + t.length + 2 > WIDTH) { lines.push(cur); cur = ''; }
        cur += (cur ? ', ' : '') + t;
      }
      if (cur) lines.push(cur);
      return '[\n' + lines.map(l => pad + l).join(',\n').replace(/,\n/g, ',\n') + '\n' + end + ']';
    }
    return '[\n' + v.map(x => pad + format(x, pad.length, indent + 1)).join(',\n') + '\n' + end + ']';
  }
  const keys = Object.keys(v);
  return '{\n' + keys.map(k => {
    const head = JSON.stringify(k) + ': ';
    return pad + head + format(v[k], pad.length + head.length, indent + 1);
  }).join(',\n') + '\n' + end + '}';
}

function pretty(v) { return format(v) + '\n'; }

function writeJson(file, v) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, pretty(v), 'utf8');
}

// parts: { tênFile: {KHOÁ: giá trị, ...}, ... } -> <dir>/<tênFile>.json. Xoá các file .json cũ không còn trong parts.
function writeParts(dir, parts) {
  fs.mkdirSync(dir, { recursive: true });
  for (const f of fs.readdirSync(dir)) if (f.endsWith('.json') && !(f.slice(0, -5) in parts)) fs.unlinkSync(path.join(dir, f));
  for (const [name, obj] of Object.entries(parts)) writeJson(path.join(dir, name + '.json'), obj);
}

// Đọc một bộ dữ liệu chia nhỏ (thư mục chứa nhiều file .json, mỗi file là một object) và gộp các khoá lại.
function readDataset(dir) {
  const out = {};
  for (const f of fs.readdirSync(dir).sort()) if (f.endsWith('.json')) Object.assign(out, JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')));
  return out;
}

module.exports = { format, pretty, writeJson, writeParts, readDataset };

// CLI: node tools/export/lib.js <file.json>...  -> định dạng lại tại chỗ (kiểm dữ liệu không đổi)
if (require.main === module) {
  const assert = require('assert');
  for (const f of process.argv.slice(2)) {
    const before = JSON.parse(fs.readFileSync(f, 'utf8'));
    writeJson(f, before);
    assert.deepStrictEqual(JSON.parse(fs.readFileSync(f, 'utf8')), before);
    console.log('formatted', f, fs.readFileSync(f, 'utf8').split('\n').length, 'dòng');
  }
}

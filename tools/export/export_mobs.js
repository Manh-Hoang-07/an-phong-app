// Xuất bảng hình quái của web (public/js/art/sprites.js: MOBS, LOOK, LOOK_TINT) + hạng quái (MON_GRADE) -> data/mob_art.json
//   node D:\Source\AnPhong-App\tools\export\export_mobs.js
const fs = require('fs');
const src = fs.readFileSync('D:/Source/AnPhong/public/js/art/sprites.js', 'utf8');
const G = require('D:/Source/AnPhong/shared');
const grab = (name, open) => {
  const i = src.indexOf('const ' + name + ' = {');
  if (i < 0) throw new Error('khong thay ' + name);
  let depth = 0, j = src.indexOf('{', i);
  const start = j;
  for (; j < src.length; j++) { if (src[j] === '{') depth++; else if (src[j] === '}') { depth--; if (depth === 0) break; } }
  return (0, eval)('(' + src.slice(start, j + 1) + ')');
};
const out = { MOBS: grab('MOBS'), LOOK: grab('LOOK'), LOOK_TINT: grab('LOOK_TINT'), MON_GRADE: G.MON_GRADE };
require('./lib').writeJson('D:/Source/AnPhong-App/data/mob_art.json', out);
console.log('mobs', Object.keys(out.MOBS).length, 'look', Object.keys(out.LOOK).length, JSON.stringify(out.MON_GRADE));

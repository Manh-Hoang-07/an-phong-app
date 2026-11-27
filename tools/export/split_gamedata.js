// Tách data/gamedata.json (do server/tools/export-gamedata.js của web sinh, một file khổng lồ) thành nhiều file nhỏ dễ đọc
// trong data/game/: meta, skills, items, schools, monsters, npcs, maps, constants. Chạy sau mỗi lần export từ web:
//   node tools/export/split_gamedata.js
// MAP_TEXTS bị bỏ vì trùng 100% với data/maps/<id>.txt (đã có tools/sync/sync_maps.ps1). gamedata.json được xoá sau khi tách.
const fs = require('fs');
const path = require('path');
const { writeParts } = require('./lib');

const ROOT = path.join(__dirname, '..', '..');
const SRC = path.join(ROOT, 'data', 'gamedata.json');
const DST = path.join(ROOT, 'data', 'game');
if (!fs.existsSync(SRC)) { console.error('Không thấy ' + SRC + ' — chạy node server/tools/export-gamedata.js (web) trước'); process.exit(1); }

const g = JSON.parse(fs.readFileSync(SRC, 'utf8'));
const NAMES = { SKILLS: 'skills', ITEMS: 'items', SCHOOLS: 'schools', MONSTERS: 'monsters', NPCS: 'npcs', MAPS: 'maps', CONSTANTS: 'constants' };
const META = ['version', 'generatedAt', 'dataHash'];
const parts = { meta: {} };
for (const [k, v] of Object.entries(g)) {
  if (META.includes(k)) parts.meta[k] = v;
  else if (k === 'MAP_TEXTS') continue;
  else parts[NAMES[k] || k.toLowerCase()] = { [k]: v };
}
writeParts(DST, parts);
fs.unlinkSync(SRC);
console.log('đã tách thành', Object.keys(parts).map(n => n + '.json').join(', '));

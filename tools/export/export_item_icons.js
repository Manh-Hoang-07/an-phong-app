// Export item icons from web's ItemArt (SVG generated in code) into app assets.
// Run: node tools/export/export_item_icons.js
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const WEB = 'D:\\Source\\AnPhong';
const APP = 'D:\\Source\\AnPhong-App';

// Load full GameData from shared (sets up GameData via require side effects).
const G = require(path.join(WEB, 'shared', 'index.js'));
global.GameData = G;
// itemicons.js uses window.GameData
global.window = { GameData: G };

const code = fs.readFileSync(path.join(WEB, 'public', 'js', 'art', 'itemicons.js'), 'utf8');
vm.runInThisContext(code + '\n;globalThis.__ItemArt = ItemArt;', { filename: 'itemicons.js' });
const Art = globalThis.__ItemArt;
if (!Art || typeof Art.svg !== 'function') {
  console.error('ItemArt.svg not available');
  process.exit(1);
}

const gamedata = require('./lib').readDataset(path.join(APP, 'data', 'game'));
const ids = Object.keys(gamedata.ITEMS || {});
const outDir = path.join(APP, 'assets', 'items');
fs.mkdirSync(outDir, { recursive: true });

let ok = 0, fail = 0;
for (const id of ids) {
  try {
    const svg = Art.svg(id);
    if (!svg || svg.length < 50) throw new Error('empty svg');
    fs.writeFileSync(path.join(outDir, id + '.svg'), svg, 'utf8');
    ok++;
  } catch (e) {
    fail++;
    if (fail <= 10) console.error('FAIL', id, e.message);
  }
}
console.log(`EXPORTED ${ok}/${ids.length} icons, fail=${fail}, dir=${outDir}`);

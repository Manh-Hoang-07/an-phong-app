// Xuất diện mạo từng bản đồ của web (nền ảnh ghép lớp + chỉnh màu, sương, ánh sáng, thời tiết, cảnh trí, ô đất) ra data/map_looks.json.
//   node D:\Source\AnPhong-App\tools\export_looks.js
const fs = require('fs');
const vm = require('vm');
const SRC = 'D:/Source/AnPhong/public/js/scene/';
const ctx = vm.createContext({ console, Math, Object, Array, Set, Map, Number, String, JSON });
const run = (f) => vm.runInContext(fs.readFileSync(SRC + f, 'utf8'), ctx, { filename: f });
run('map_props_data.js');
run('map_scenes.js');
run('map_looks.js');
const ML = vm.runInContext('MapLooks', ctx);
const PROPS = vm.runInContext('MapProps', ctx);
const game = JSON.parse(fs.readFileSync('D:/Source/AnPhong-App/data/gamedata.json', 'utf8'));
const out = { maps: {}, packs: {}, tile_variants: ML.TILE_VARIANTS, prop_sets: PROPS.SETS };
for (const [k, v] of Object.entries(ML.PACKS)) out.packs[k] = { layers: v.layers, ext: v.ext, cover: !!v.cover, filter: v.filter || 'linear' };
for (const id of Object.keys(game.MAPS)) {
  const theme = game.MAPS[id].theme;
  const look = ML.get(id, theme);
  const defs = ML.layerDefs(look);
  const layers = {};
  for (const [l, d] of Object.entries(defs)) layers[l] = JSON.parse(JSON.stringify(d));
  const { scene, decor, ...rest } = look;
  out.maps[id] = { theme, ...JSON.parse(JSON.stringify(rest)), decor: decor ? JSON.parse(JSON.stringify(decor)) : {}, layers, all: (scene && scene.all) || {} };
}
fs.writeFileSync('D:/Source/AnPhong-App/data/map_looks.json', JSON.stringify(out));
console.log('maps', Object.keys(out.maps).length, 'packs', Object.keys(out.packs).length);
console.log(JSON.stringify(out.maps.lang), '\n', JSON.stringify(out.maps.hang), '\n', JSON.stringify(out.maps.rung));

// Xuất hằng số tính chỉ số nhân vật (calcStats của web) -> data/calc.json
//   node D:\Source\AnPhong-App\tools\export_calc.js
const fs = require('fs');
const G = require('D:/Source/AnPhong/shared');
const perks = {};
for (const [k, v] of Object.entries(G.PERKS)) perks[k] = { mul: v.mul || null, add: v.add || null, name: v.name, desc: v.desc };
const ky = {};
for (const [k, v] of Object.entries(G.ITEMS)) if (v.kyNguyen) ky[k] = v.stats || {};
const sx = {};
for (const [k, v] of Object.entries(G.SCHOOLS)) if (v.skillPower || v.skillCost) sx[k] = { skillPower: v.skillPower || null, skillCost: v.skillCost || null };
const out = { SCHOOL_EXTRA: sx,
  QUALITY_MUL: G.QUALITY_MUL, SET_LEVELS: G.SET_LEVELS, SET_BONUS: G.SET_BONUS, SET_TIER_LOW: G.SET_TIER_LOW, SET_TIER_HIGH: G.SET_TIER_HIGH,
  SETS: G.SETS.map(s => ({ id: s.id, min: s.min, max: s.max, name: s.name })), PERKS: perks, KY_NGUYEN: ky,
  NOVICE_CURVE: G.NOVICE_CURVE, EVOLUTION_MUL: G.EVOLUTION_MUL, STAMINA: G.STAMINA, SLOTS: G.SLOTS,
  NHIEM_STAT_MUL: 1.18, NHIEM_HP_PENALTY: 0.06,
};
fs.writeFileSync('D:/Source/AnPhong-App/data/calc.json', JSON.stringify(out));
console.log('calc ok', Object.keys(perks).length, 'perks', Object.keys(ky).length, 'ky nguyen');

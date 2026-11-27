// Xuất hằng số tính chỉ số nhân vật (calcStats của web) -> data/calc.json
//   node D:\Source\AnPhong-App\tools\export\export_calc.js
const fs = require('fs');
const G = require('D:/Source/AnPhong/shared');
const perks = {};
for (const [k, v] of Object.entries(G.PERKS)) perks[k] = { mul: v.mul || null, add: v.add || null, name: v.name, desc: v.desc };
const ky = {};
const kyfx = {};
for (const [k, v] of Object.entries(G.ITEMS)) if (v.kyNguyen) { ky[k] = v.stats || {}; if (v.fx) kyfx[k] = v.fx; }
const sx = {};
for (const [k, v] of Object.entries(G.SCHOOLS)) if (v.skillPower || v.skillCost) sx[k] = { skillPower: v.skillPower || null, skillCost: v.skillCost || null };
// Dung hợp Tử Linh: bảng quái (cấp, máu đã gồm hạng, giáp) + đường cong quái theo cấp [hp, atk, def]
const fmon = {};
for (const [k, v] of Object.entries(G.MONSTERS)) fmon[k] = { level: v.level || 1, hp: G.monHp(v), def: v.def || 0, atk: v.atk || 0 };
const mcurve = [];
for (let l = 1; l <= 200; l++) { const c = G.monCurve(l); mcurve.push([c.hp, c.atk, c.def]); }
// Trang bị thú: chỉ số cộng thêm theo từng món
const pgear = {};
for (const [k, v] of Object.entries(G.ITEMS)) if (v.kind === 'pet_gear') pgear[k] = G.petGearBonusOf(v);
const mountAtk = {};
for (const [k, v] of Object.entries(G.MOUNTS)) mountAtk[k] = v.atk || 1;
const out = { PET_CURVE: G.PET_CURVE, PET_SKILLS: G.PET_SKILLS, SUMMONS: G.SUMMONS, SUMMON_SKILLS: G.SUMMON_SKILLS, MOUNT_ATK: mountAtk, WEAPON_TYPES: G.WEAPON_TYPES, FUSION_MON: fmon, MON_CURVE: mcurve, FUSION: G.FUSION, PET_GEAR: pgear, SCHOOL_EXTRA: sx,
  QUALITY_MUL: G.QUALITY_MUL, SET_LEVELS: G.SET_LEVELS, SET_BONUS: G.SET_BONUS, SET_TIER_LOW: G.SET_TIER_LOW, SET_TIER_HIGH: G.SET_TIER_HIGH,
  SETS: G.SETS.map(s => ({ id: s.id, min: s.min, max: s.max, name: s.name })), PERKS: perks, KY_NGUYEN: ky, KY_FX: kyfx, REGEN: G.REGEN,
  NOVICE_CURVE: G.NOVICE_CURVE, EVOLUTION_MUL: G.EVOLUTION_MUL, STAMINA: G.STAMINA, SLOTS: G.SLOTS,
  NHIEM_STAT_MUL: 1.18, NHIEM_HP_PENALTY: 0.06,
};
require('./lib').writeJson('D:/Source/AnPhong-App/data/calc.json', out);
console.log('calc ok', Object.keys(perks).length, 'perks', Object.keys(ky).length, 'ky nguyen');

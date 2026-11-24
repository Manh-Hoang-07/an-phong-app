const fs = require('fs');
const G = require('D:/Source/AnPhong/shared');

const schools = Object.keys(G.SCHOOLS);
const slots = G.SLOTS;
const cases = [];

function mkPlayer(school, lv, pts, equip, extra) {
  const p = {
    name: 'T', level: lv, school: school,
    points: Object.assign({ str: 0, agi: 0, vit: 0, spi: 0 }, pts),
    equip: equip || {}, perks: [], kyNguyen: { owned: [], active: [] },
    bag: [], skills: {}, skillSlots: [], quests: {}, mounts: { owned: [], summoned: [] },
    awakenTier: 0, formChoice: '', formActive: false,
  };
  return Object.assign(p, extra || {});
}

// 1. Moi class, vai cap do, khong do
for (const sc of schools) {
  for (const lv of [1, 10, 30, 60, 90, 120]) {
    cases.push({ label: sc + ' lv' + lv, player: mkPlayer(sc, lv, {}) });
  }
}

// 2. Diem tiem nang
for (const sc of ['kiem_si', 'phap_su', 'tanker']) {
  for (const pts of [{ str: 50 }, { vit: 100 }, { agi: 80, spi: 40 }, { str: 30, agi: 30, vit: 30, spi: 30 }]) {
    cases.push({ label: sc + ' pts ' + JSON.stringify(pts), player: mkPlayer(sc, 60, pts) });
  }
}

// 3. Mac do that: chon vai mon moi slot o cac cap
const bySlot = {};
for (const [id, d] of Object.entries(G.ITEMS)) {
  if (!d.slot || !slots.includes(d.slot)) continue;
  if (d.kyNguyen) continue;
  (bySlot[d.slot] = bySlot[d.slot] || []).push({ id, lv: d.level || 1 });
}
for (const sc of ['kiem_si', 'cung_thu', 'tanker']) {
  for (const lv of [20, 50, 80]) {
    const eq = {};
    let n = 0;
    for (const s of slots) {
      const list = (bySlot[s] || []).filter(x => x.lv <= lv).sort((a, b) => b.lv - a.lv);
      if (!list.length) continue;
      eq[s] = { id: list[0].id, q: 3, plus: 2, roll: 1.0, aff: [] };
      n++;
    }
    cases.push({ label: sc + ' lv' + lv + ' fullgear' + n, player: mkPlayer(sc, lv, { vit: 20, str: 20 }, eq) });
  }
}

// 4. Ky Nguyen dang bat
const kyIds = Object.keys(G.ITEMS).filter(id => G.ITEMS[id].kyNguyen);
for (const sc of ['kiem_si', 'phap_su']) {
  cases.push({ label: sc + ' kynguyen all', player: mkPlayer(sc, 70, { vit: 30 }, {}, { kyNguyen: { owned: kyIds, active: kyIds } }) });
}

// 5. Noi tai
const perkIds = Object.keys(G.PERKS);
for (const sc of ['kiem_si', 'sat_thu']) {
  cases.push({ label: sc + ' perks all', player: mkPlayer(sc, 70, { vit: 20 }, {}, { perks: perkIds }) });
}

// 6. Thuc tinh (form)
for (const sc of ['kiem_si', 'phap_su', 'tanker']) {
  cases.push({ label: sc + ' awaken2 form', player: mkPlayer(sc, 70, { vit: 20 }, {}, { awakenTier: 2, formChoice: 'awaken2', formActive: true }) });
}

// 7. Nhiem do
for (const sc of ['kiem_si']) {
  const eq = {};
  for (const s of ['weapon', 'mu', 'ao']) {
    const list = (bySlot[s] || []).filter(x => x.lv <= 60).sort((a, b) => b.lv - a.lv);
    if (list.length) eq[s] = { id: list[0].id, q: 3, plus: 0, roll: 1.0, aff: [], nhiem: 2 };
  }
  cases.push({ label: sc + ' nhiem2', player: mkPlayer(sc, 60, {}, eq) });
}

// 8. Cap cao nhu nguoi choi that (15k HP)
for (const sc of ['kiem_si', 'tanker']) {
  for (const lv of [150, 200, 250]) {
    const eq = {};
    for (const s of slots) {
      const list = (bySlot[s] || []).filter(x => x.lv <= lv).sort((a, b) => b.lv - a.lv);
      if (list.length) eq[s] = { id: list[0].id, q: 4, plus: 10, roll: 1.0, aff: [] };
    }
    cases.push({ label: sc + ' lv' + lv + ' maxgear', player: mkPlayer(sc, lv, { vit: 200, str: 100 }, eq, { perks: perkIds, kyNguyen: { owned: kyIds, active: kyIds } }) });
  }
}

const out = [];
for (const c of cases) {
  let st;
  try { st = G.calcStats(c.player, { form: !!c.player.formActive }); }
  catch (e) { out.push({ label: c.label, error: String(e.message) }); continue; }
  out.push({ label: c.label, player: c.player, expected: st });
}
fs.writeFileSync('D:/Source/AnPhong-App/.calc_cases.json', JSON.stringify(out));
console.log('cases', out.length, 'errors', out.filter(x => x.error).length);
// 9. Tu Linh Dung Hop (fusion): bong ma cong thang vao nguoi
{
  const mons = Object.keys(G.MONSTERS);
  for (const lv of [20, 60, 100]) {
    const souls = [];
    for (let i = 0; i < 8; i++) souls.push({ monster: mons[(i * 7) % mons.length], lv: 10 + i * 12, stats: { level: 10 + i * 12 } });
    souls.push({ monster: mons[3], stats: { level: 33 } });
    const p = mkPlayer('kiem_si', lv, { vit: 20 }, {}, { fusion: { until: Date.now() + 1e10, souls } });
    const st = G.calcStats(p, {});
    const i = out.length;
    out.push({ label: 'fusion lv' + lv, player: p, expected: st });
  }
}
fs.writeFileSync('D:/Source/AnPhong-App/.calc_cases.json', JSON.stringify(out));
// Bo sung fx + passives de tools/fx_check.gd so Game.special_fx / has_passive voi web
for (const o of out) {
  if (!o.player) continue;
  try { o.fx = G.specialFx(o.player); o.passives = G.passivesOf(o.player); } catch (e) {}
}
fs.writeFileSync('D:/Source/AnPhong-App/.calc_cases.json', JSON.stringify(out));

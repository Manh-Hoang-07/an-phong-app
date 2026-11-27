// Kiểm tra tĩnh (không cần mạng): NPC của từng nhiệm vụ có xuất hiện ở map chỉ định không.
// Chạy: node tools/tests/check_quest_npcs.js
const fs = require('fs'), path = require('path');
const root = path.join(__dirname, '..', '..');
const q = require(path.join(root, 'data/quests.json'));
const g = require(path.join(root, 'data/gamedata.json'));
const QUESTS = q.QUESTS, SIDE = q.SIDE || [];
const idx = {}; QUESTS.forEach((x, i) => idx[x.id] = i);
const edge = (v, hi) => typeof v === 'string' ? (v in idx ? idx[v] : (hi ? 1 << 30 : -1)) : v;
let bad = 0;
const say = (m) => { bad++; console.log(m); };
// map -> [{ch, npc, hasMarker}]
const hosts = {};
for (const [mid, m] of Object.entries(g.MAPS)) {
  const file = path.join(root, 'data/maps', mid + '.txt');
  const text = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : (g.MAP_TEXTS[mid] || '');
  for (const [ch, nid] of Object.entries(m.npcs || {})) {
    const has = text.includes(ch);
    (hosts[nid] = hosts[nid] || []).push({ map: mid, ch, has });
    if (!has) say(`[MAP] ${mid}: NPC ${nid} ký tự '${ch}' không có trong file map (sẽ không spawn)`);
    if (!g.NPCS[nid]) say(`[MAP] ${mid}: NPC ${nid} không có trong NPCS`);
  }
}
const rows = [];
function check(qq, step, label) {
  const nid = qq.npc;
  if (!g.NPCS[nid]) return say(`[${label}] ${qq.id} (${qq.name}): npc '${nid}' không có trong NPCS`);
  const hs = (hosts[nid] || []).filter(h => h.has);
  if (!hs.length) return say(`[${label}] ${qq.id} (${qq.name}): npc '${nid}' không đứng ở map nào`);
  const ap = g.NPCS[nid].appear;
  if (!ap) return;
  // map nào thật sự hiện ở bước này
  const vis = hs.filter(h => (ap[h.map] || []).some(r => step >= edge(r[0], false) && step <= edge(r[1], true)));
  if (step == null) { return; }
  if (!vis.length) say(`[${label}] ${qq.id} (${qq.name}) bước ${step}: npc '${nid}' bị ẩn ở mọi map (appear=${JSON.stringify(ap)}; maps=${hs.map(h => h.map)})`);
}
QUESTS.forEach((x, i) => check(x, i, 'MAIN'));
// phụ tuyến: không có bước cố định; chỉ kiểm tra NPC tồn tại ở map nào đó
SIDE.forEach(x => { const nid = x.npc; const hs = (hosts[nid] || []).filter(h => h.has);
  if (!g.NPCS[nid]) say(`[SIDE] ${x.id}: npc '${nid}' không có trong NPCS`);
  else if (!hs.length) say(`[SIDE] ${x.id} (${x.name}): npc '${nid}' không đứng ở map nào`);
  else { const ap = g.NPCS[nid].appear; if (ap && !hs.some(h => ap[h.map])) say(`[SIDE] ${x.id}: npc '${nid}' có appear nhưng không khớp map nào (${hs.map(h=>h.map)})`); }
});
console.log(bad ? `\n${bad} vấn đề` : 'OK: mọi NPC nhiệm vụ đều có mặt đúng map');
process.exitCode = bad ? 1 : 0;

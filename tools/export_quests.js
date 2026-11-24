// Xuất nhiệm vụ chính + phụ tuyến sang data/quests.json cho app (tên, NPC, mục tiêu, lời thoại, phần thưởng).
//   node D:\Source\AnPhong-App\tools\export_quests.js
const fs = require('fs');
const G = require('D:/Source/AnPhong/shared');
const pick = (q) => ({ id: q.id, name: q.name, npc: q.npc, req: q.req || null, obj: q.obj || {}, start: q.start || [], end: q.end || [], reward: q.reward || {}, choices: q.choices || null, minLevel: (G.questMinLevel && !String(q.id).startsWith('p')) ? G.questMinLevel(q) : 0 });
const out = { QUESTS: G.QUESTS.map(pick), SIDE: (G.SIDE_QUESTS || []).map(pick),
  AWAKENS: G.AWAKENS, EVOLUTION_SCHOOLS: Object.keys(G.EVOLUTIONS || {}), STAMINA: G.STAMINA };
fs.writeFileSync('D:/Source/AnPhong-App/data/quests.json', JSON.stringify(out));
console.log('quests', out.QUESTS.length, 'side', out.SIDE.length);

// Xuất nhiệm vụ chính + phụ tuyến sang data/quests/*.json cho app (tên, NPC, mục tiêu, lời thoại, phần thưởng).
//   node D:\Source\AnPhong-App\tools\export\export_quests.js
const { writeParts } = require('./lib');
const G = require('D:/Source/AnPhong/shared');
const pick = (q) => ({ id: q.id, name: q.name, npc: q.npc, req: q.req || null, obj: q.obj || {}, start: q.start || [], end: q.end || [], reward: q.reward || {}, choices: q.choices || null, minLevel: (G.questMinLevel && !String(q.id).startsWith('p')) ? G.questMinLevel(q) : 0 });
const out = { QUESTS: G.QUESTS.map(pick), SIDE: (G.SIDE_QUESTS || []).map(pick),
  AWAKENS: G.AWAKENS, EVOLUTION_SCHOOLS: Object.keys(G.EVOLUTIONS || {}), STAMINA: G.STAMINA };
writeParts('D:/Source/AnPhong-App/data/quests', {
  main: { QUESTS: out.QUESTS }, side: { SIDE: out.SIDE },
  awaken: { AWAKENS: out.AWAKENS, EVOLUTION_SCHOOLS: out.EVOLUTION_SCHOOLS, STAMINA: out.STAMINA },
});
console.log('quests', out.QUESTS.length, 'side', out.SIDE.length);

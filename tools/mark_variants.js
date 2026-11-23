// Đánh dấu "variant" cho các kỹ năng có công thức hiệu ứng trùng hệt kỹ năng khác (khác lớp/class nhưng cùng kiểu),
// để app đổi tông màu + biến thể hình cho từng kỹ năng. Chạy lại sau mỗi lần đồng bộ data/skillfx từ web.
//   node D:\Source\AnPhong-App\tools\mark_variants.js
const fs = require('fs');
const dir = 'D:/Source/AnPhong-App/data/skillfx/';
const groups = {};
const files = fs.readdirSync(dir).filter(f => f.endsWith('.json') && f !== 'manifest.json').sort();
for (const f of files) {
  const j = JSON.parse(fs.readFileSync(dir + f));
  const s = JSON.stringify([j.theme, j.type, j.sig, j.colors, j.layers.map(l => [l.kind, l.params, l.t, l.trigger])]);
  (groups[s] = groups[s] || []).push([f, j]);
}
let marked = 0;
for (const g of Object.values(groups)) {
  g.forEach(([f, j], i) => {
    if (i === 0 && !('variant' in j)) return;
    if (j.variant === i) return;
    j.variant = i;
    fs.writeFileSync(dir + f, JSON.stringify(j, null, 2));
    marked++;
  });
}
console.log('đã đánh dấu', marked, 'kỹ năng, nhóm trùng:', Object.values(groups).filter(g => g.length > 1).length);

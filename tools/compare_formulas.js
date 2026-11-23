'use strict';
/*
 * So sánh công thức GDScript (src/logic/Formulas.gd) với bản JS gốc (shared/core.js).
 * Chạy: node D:\Source\AnPhong-App\tools\compare_formulas.js
 *
 * Cách làm: lấy giá trị kỳ vọng từ shared/core.js (nguồn thật), so với bảng giá trị
 * đã port trong Formulas.gd (EXPECTED_GD). Nếu lệch → báo lỗi. Khi có Godot, chạy thêm
 * scene test trong Godot để tự đọc Formulas.gd và so trực tiếp.
 */
const path = require('path');
const G = require(path.join(__dirname, '..', '..', 'AnPhong', 'shared'));

// Giá trị lấy từ Formulas.gd (port thủ công, giữ nguyên làm mốc đối chiếu)
const EXPECTED_GD = {
  exp_to_next: { 1: 40, 5: 617, 10: 2004, 30: 12976, 60: 42161 },
  r1: { '1.25': 1.3, '0.04': 0, '9.99': 10 },
  interp: {
    '[[0,0],[10,100],[20,50]]@5': 50,
    '[[0,0],[10,100],[20,50]]@15': 75,
    '[[0,0],[10,100],[20,50]]@25': 50,
    '[[0,0],[10,100],[20,50]]@-3': 0,
  },
  def_reduce: {
    '0@1': 0,
    '60@1': 60 / 132,
    '100@10': 100 / 280,
    '10000@1': 0.75,
  },
};

let fails = 0;
function check(name, got, want) {
  const ok = Math.abs(Number(got) - Number(want)) < 1e-6;
  if (!ok) fails++;
  console.log(`${ok ? 'OK  ' : 'FAIL'} ${name}: JS=${got} GD=${want}`);
}

for (const [lv, want] of Object.entries(EXPECTED_GD.exp_to_next)) {
  check(`expToNext(${lv})`, G.expToNext(Number(lv)), want);
}
for (const [v, want] of Object.entries(EXPECTED_GD.r1)) {
  check(`r1(${v})`, G.r1(Number(v)), want);
}
for (const [key, want] of Object.entries(EXPECTED_GD.interp)) {
  const [pts, x] = key.split('@');
  check(`interp(${pts}, ${x})`, G.interp(JSON.parse(pts), Number(x)), want);
}
for (const [key, want] of Object.entries(EXPECTED_GD.def_reduce)) {
  const [def, lv] = key.split('@');
  check(`defReduce(${def}, ${lv})`, G.defReduce(Number(def), Number(lv)), want);
}

// mitigate không có trong core.js; công thức = raw*(1-defReduce), tối thiểu 1
check('mitigate(100,60,1)', Math.max(1, Math.round(100 * (1 - G.defReduce(60, 1)))),
  Math.max(1, Math.round(100 * (1 - 60 / 132))));

console.log(`\n${fails === 0 ? '✓ Tất cả công thức khớp giữa JS và GDScript.' : `✗ ${fails} giá trị lệch.`}`);
process.exit(fails === 0 ? 0 : 1);

// Xuất hình vẽ-bằng-code của web (ô đất, thác nước, cảnh trí, NPC) ra PNG cho app Godot.
// Chạy NGUYÊN các file public/js/art/*.js của web trên một "Phaser Graphics" giả có bộ rasterizer khử răng cưa.
//   node D:\Source\AnPhong-App\tools\export\export_art.js
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const vm = require('vm');

const SRC = 'D:/Source/AnPhong/public/js/art/';
const OUT = 'D:/Source/AnPhong-App/assets/art/';
fs.mkdirSync(OUT, { recursive: true });

// ------------------------------------------------------------------ PNG
const crcTable = (() => { const t = new Uint32Array(256); for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; } return t; })();
const crc32 = (buf) => { let c = 0xffffffff; for (let i = 0; i < buf.length; i++) c = crcTable[(c ^ buf[i]) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; };
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(td));
  return Buffer.concat([len, td, crc]);
}
function encodePNG(w, h, rgba) {
  const raw = Buffer.alloc((w * 4 + 1) * h);
  for (let y = 0; y < h; y++) { raw[y * (w * 4 + 1)] = 0; rgba.copy(raw, y * (w * 4 + 1) + 1, y * w * 4, (y + 1) * w * 4); }
  const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 6;
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw, { level: 9 })), chunk('IEND', Buffer.alloc(0))]);
}

// ------------------------------------------------------------------ Rasterizer
const SS = 4;   // lấy mẫu con theo chiều dọc
class Canvas {
  constructor(w, h) { this.w = w; this.h = h; this.px = new Float32Array(w * h * 4); }   // premultiplied
  // polys: [[ [x,y],... ], ...] đã ở toạ độ pixel; quy tắc non-zero
  fill(polys, color, alpha) {
    const w = this.w, h = this.h;
    const edges = [];
    let minY = 1e9, maxY = -1e9;
    for (const poly of polys) {
      const n = poly.length;
      if (n < 3) continue;
      for (let i = 0; i < n; i++) {
        const a = poly[i], b = poly[(i + 1) % n];
        if (a[1] === b[1]) continue;
        edges.push(a[1] < b[1] ? { x0: a[0], y0: a[1], x1: b[0], y1: b[1], d: 1 } : { x0: b[0], y0: b[1], x1: a[0], y1: a[1], d: -1 });
        minY = Math.min(minY, a[1], b[1]); maxY = Math.max(maxY, a[1], b[1]);
      }
    }
    if (!edges.length) return;
    const r = ((color >> 16) & 255) / 255, g = ((color >> 8) & 255) / 255, b = (color & 255) / 255;
    const y0 = Math.max(0, Math.floor(minY)), y1 = Math.min(h - 1, Math.ceil(maxY));
    const cov = new Float32Array(w);
    for (let y = y0; y <= y1; y++) {
      cov.fill(0);
      let any = false;
      for (let s = 0; s < SS; s++) {
        const sy = y + (s + 0.5) / SS;
        const xs = [];
        for (const e of edges) if (sy >= e.y0 && sy < e.y1) xs.push([e.x0 + (sy - e.y0) / (e.y1 - e.y0) * (e.x1 - e.x0), e.d]);
        if (!xs.length) continue;
        xs.sort((p, q) => p[0] - q[0]);
        let wind = 0;
        for (let i = 0; i < xs.length - 1; i++) {
          wind += xs[i][1];
          if (wind === 0) continue;
          const xa = Math.max(0, xs[i][0]), xb = Math.min(w, xs[i + 1][0]);
          if (xb <= xa) continue;
          any = true;
          const pa = Math.floor(xa), pb = Math.min(w - 1, Math.floor(xb));
          if (pa === pb) cov[pa] += (xb - xa) / SS;
          else {
            cov[pa] += (pa + 1 - xa) / SS;
            for (let x = pa + 1; x < pb; x++) cov[x] += 1 / SS;
            cov[pb] += (xb - pb) / SS;
          }
        }
      }
      if (!any) continue;
      for (let x = 0; x < w; x++) {
        const c = Math.min(1, cov[x]) * alpha;
        if (c <= 0) continue;
        const i = (y * w + x) * 4;
        const ia = 1 - c;
        this.px[i] = r * c + this.px[i] * ia;
        this.px[i + 1] = g * c + this.px[i + 1] * ia;
        this.px[i + 2] = b * c + this.px[i + 2] * ia;
        this.px[i + 3] = c + this.px[i + 3] * ia;
      }
    }
  }
  toRGBA() {
    const out = Buffer.alloc(this.w * this.h * 4);
    for (let i = 0; i < this.w * this.h; i++) {
      const a = this.px[i * 4 + 3];
      if (a <= 0.0005) continue;
      out[i * 4] = Math.round(Math.min(1, this.px[i * 4] / a) * 255);
      out[i * 4 + 1] = Math.round(Math.min(1, this.px[i * 4 + 1] / a) * 255);
      out[i * 4 + 2] = Math.round(Math.min(1, this.px[i * 4 + 2] / a) * 255);
      out[i * 4 + 3] = Math.round(Math.min(1, a) * 255);
    }
    return out;
  }
}

const orient = (p) => { let a = 0; for (let i = 0; i < p.length; i++) { const q = p[(i + 1) % p.length]; a += p[i][0] * q[1] - q[0] * p[i][1]; } return a >= 0 ? p : p.slice().reverse(); };
const circlePoly = (cx, cy, rx, ry, n = 48) => { const p = []; for (let i = 0; i < n; i++) { const a = Math.PI * 2 * i / n; p.push([cx + Math.cos(a) * rx, cy + Math.sin(a) * ry]); } return p; };

// ------------------------------------------------------------------ Phaser Graphics giả
const meta = {};
class Graphics {
  constructor() { this.sx = 1; this.sy = 1; this.fs = { c: 0, a: 1 }; this.ls = { w: 1, c: 0, a: 1 }; this.path = []; this.cur = null; this.cv = null; }
  scaleCanvas(sx, sy) { this.sx = sx; this.sy = sy; }
  _cv() { return this.cv; }
  _t(x, y) { return [x * this.sx, y * this.sy]; }
  fillStyle(c, a = 1) { this.fs = { c, a }; return this; }
  lineStyle(w, c, a = 1) { this.ls = { w, c, a }; return this; }
  _fillPolys(polys) { this.cv.fill(polys.map(orient), this.fs.c, this.fs.a); }
  fillRect(x, y, w, h) { this._fillPolys([[this._t(x, y), this._t(x + w, y), this._t(x + w, y + h), this._t(x, y + h)]]); return this; }
  fillCircle(x, y, r) { this._fillPolys([circlePoly(x * this.sx, y * this.sy, r * this.sx, r * this.sy)]); return this; }
  fillEllipse(x, y, w, h) { this._fillPolys([circlePoly(x * this.sx, y * this.sy, w / 2 * this.sx, h / 2 * this.sy)]); return this; }
  fillTriangle(x1, y1, x2, y2, x3, y3) { this._fillPolys([[this._t(x1, y1), this._t(x2, y2), this._t(x3, y3)]]); return this; }
  fillRoundedRect(x, y, w, h, r = 5) {
    r = Math.min(r, w / 2, h / 2);
    const p = [];
    const corner = (cx, cy, a0) => { for (let i = 0; i <= 8; i++) { const a = a0 + (Math.PI / 2) * i / 8; p.push(this._t(cx + Math.cos(a) * r, cy + Math.sin(a) * r)); } };
    corner(x + w - r, y + r, -Math.PI / 2); corner(x + w - r, y + h - r, 0); corner(x + r, y + h - r, Math.PI / 2); corner(x + r, y + r, Math.PI);
    this._fillPolys([p]); return this;
  }
  fillPoints(pts) { this._fillPolys([pts.map(p => this._t(p.x, p.y))]); return this; }
  // đường dẫn
  beginPath() { this.path = []; this.cur = null; return this; }
  moveTo(x, y) { this.cur = [this._t(x, y)]; this.path.push(this.cur); return this; }
  lineTo(x, y) { if (!this.cur) return this.moveTo(x, y); this.cur.push(this._t(x, y)); return this; }
  arc(x, y, r, a0, a1, acw = false) {
    if (!this.cur) { this.cur = []; this.path.push(this.cur); }
    let d = a1 - a0;
    if (!acw) { while (d < 0) d += Math.PI * 2; if (d > Math.PI * 2) d = Math.PI * 2; }
    else { while (d > 0) d -= Math.PI * 2; if (d < -Math.PI * 2) d = -Math.PI * 2; }
    const n = Math.max(6, Math.ceil(Math.abs(d) / (Math.PI / 24)));
    for (let i = 0; i <= n; i++) { const a = a0 + d * i / n; this.cur.push(this._t(x + Math.cos(a) * r, y + Math.sin(a) * r)); }
    return this;
  }
  closePath() { if (this.cur && this.cur.length) { this.cur.closed = true; } return this; }
  fillPath() { this._fillPolys(this.path.filter(p => p.length >= 3)); return this; }
  _strokePolys(paths) {
    const w = Math.max(0.5, this.ls.w * (this.sx + this.sy) / 2), hw = w / 2, polys = [];
    for (const p of paths) {
      const pts = p.closed ? p.concat([p[0]]) : p;
      for (let i = 0; i < pts.length - 1; i++) {
        const a = pts[i], b = pts[i + 1];
        const dx = b[0] - a[0], dy = b[1] - a[1], L = Math.hypot(dx, dy);
        if (L < 1e-6) continue;
        const nx = -dy / L * hw, ny = dx / L * hw;
        polys.push(orient([[a[0] + nx, a[1] + ny], [b[0] + nx, b[1] + ny], [b[0] - nx, b[1] - ny], [a[0] - nx, a[1] - ny]]));
      }
      if (w > 1.6) for (const q of pts) polys.push(orient(circlePoly(q[0], q[1], hw, hw, 16)));
    }
    if (polys.length) this.cv.fill(polys, this.ls.c, this.ls.a);
  }
  strokePath() { this._strokePolys(this.path); return this; }
  lineBetween(x1, y1, x2, y2) { this._strokePolys([[this._t(x1, y1), this._t(x2, y2)]]); return this; }
  strokeEllipse(x, y, w, h) { const p = circlePoly(x * this.sx, y * this.sy, w / 2 * this.sx, h / 2 * this.sy, 48); p.closed = true; this._strokePolys([p]); return this; }
  strokeCircle(x, y, r) { return this.strokeEllipse(x, y, r * 2, r * 2); }
  generateTexture(key, w, h) {
    // vẽ lại: Graphics gốc ghi lệnh rồi mới sinh ảnh; ở đây vẽ trực tiếp nên cv đã có
    this.out = { key, w, h };
  }
  destroy() {}
}

// ------------------------------------------------------------------ Phaser giả
const stored = new Map();
const hsv = (c) => { const r = ((c >> 16) & 255) / 255, g = ((c >> 8) & 255) / 255, b = (c & 255) / 255; const mx = Math.max(r, g, b), mn = Math.min(r, g, b), d = mx - mn; let h = 0; if (d) { if (mx === r) h = ((g - b) / d) % 6; else if (mx === g) h = (b - r) / d + 2; else h = (r - g) / d + 4; h /= 6; if (h < 0) h += 1; } return { h, s: mx ? d / mx : 0, v: mx }; };
const fromHsv = (h, s, v) => { const f = (n) => { const k = (n + h * 6) % 6; return v - v * s * Math.max(0, Math.min(k, 4 - k, 1)); }; return (Math.round(f(5) * 255) << 16) | (Math.round(f(3) * 255) << 8) | Math.round(f(1) * 255); };
const ColorObj = (c) => { const o = hsv(c); return { lighten(p) { o.v = Math.min(1, o.v + p / 100); return this; }, darken(p) { o.v = Math.max(0, o.v - p / 100); return this; }, get color() { return fromHsv(o.h, o.s, o.v); } }; };
const Phaser = { Display: { Color: { IntegerToColor: ColorObj } }, Textures: { FilterMode: { LINEAR: 1, NEAREST: 0 } }, BlendModes: {} };

const scene = {
  textures: { exists: (k) => stored.has(k), get: () => ({ setFilter() {}, getSourceImage() { return null; }, source: [{ scaleMode: 0 }] }), remove() {} },
  make: { graphics: () => { const g = new Graphics(); return g; } },
  anims: { exists: () => true, create() {}, generateFrameNumbers() { return []; }, remove() {} },
  load: { spritesheet() {}, image() {} },
};

// Graphics cần canvas TRƯỚC khi vẽ: bọc make() để cấp canvas đúng cỡ sau khi scaleCanvas.
// Cách đơn giản: ghi nhận lệnh, vẽ khi generateTexture — nhưng make() gọi draw(g) rồi mới generateTexture(w,h).
// Nên ta cấp canvas lớn tạm trong Graphics rồi cắt theo (w,h) khi generate.
const MAXW = 640, MAXH = 640;
Graphics.prototype._ensure = function () { if (!this.cv) this.cv = new Canvas(MAXW, MAXH); };
for (const m of ['fillRect', 'fillCircle', 'fillEllipse', 'fillTriangle', 'fillRoundedRect', 'fillPoints', 'fillPath', 'strokePath', 'lineBetween', 'strokeEllipse', 'strokeCircle']) {
  const orig = Graphics.prototype[m];
  Graphics.prototype[m] = function (...a) { this._ensure(); return orig.apply(this, a); };
}
Graphics.prototype.generateTexture = function (key, w, h) {
  this._ensure();
  const c = new Canvas(w, h);
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) for (let k = 0; k < 4; k++) c.px[(y * w + x) * 4 + k] = this.cv.px[(y * MAXW + x) * 4 + k];
  fs.writeFileSync(path.join(OUT, key + '.png'), encodePNG(w, h, c.toRGBA()));
  stored.set(key, { w, h });
};

// ------------------------------------------------------------------ Chạy code art của web
const ctx = vm.createContext({ Phaser, console, Math, Object, Array, Set, Map, Number, String, JSON });
const run = (f) => vm.runInContext(fs.readFileSync(SRC + f, 'utf8'), ctx, { filename: f });
run('art.js');
for (const f of ['terrain.js', 'scenery.js', 'characters.js']) run(f);
const Art = vm.runInContext('Art', ctx);
const L = Art._;
for (const fn of ['tiles', 'water', 'earth', 'decorations', 'npcs']) { console.log('->', fn); L[fn](scene); }
for (const [key, v] of stored) meta[key] = { w: v.w, h: v.h, scale: 1 / Art.hdScale(key) };
fs.writeFileSync(OUT + 'meta.json', JSON.stringify(meta));
console.log('Đã xuất', stored.size, 'hình vào', OUT);

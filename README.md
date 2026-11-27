# Thức Tỉnh — App Godot (điện thoại, ngang)

Client điện thoại (Android / iOS) dùng chung tài khoản, thế giới và server với bản web `D:\Source\AnPhong`.
Luật chơi nằm ở server; app chỉ hiển thị, gửi input/đòn và nhận kết quả.
Kế hoạch và nhật ký sửa lỗi: [docs/KE_HOACH_SUA.md](docs/KE_HOACH_SUA.md) (nhật ký lịch sử).

## Trạng thái (2026-11-23)

Đã có: đăng nhập/đăng ký, HUD cảm ứng, bản đồ từng file, quái do server quản lý (nhận sát thương từ đòn lao, boss slam/special),
chết và hồi sinh, đổi map qua cổng/dịch chuyển, NPC + cổng + đồ rơi với nút tương tác, nhận thưởng (`kills` theo phiếu `kid`),
hồi chiêu + MP kỹ năng, lưu trạng thái định kỳ, người chơi khác (tên, hoạt ảnh, bóng chat), đội nhóm, giao dịch, chợ, đổi khu,
21 panel hai cột, âm thanh tổng hợp, rung khi bị đánh.

Chưa kiểm tra / chưa làm: chạy với server thật và cảm ứng thật trên máy (mới kiểm bằng ảnh chụp + mô phỏng gói tin),
fusion / manaburst / allin, thú đồng hành và bóng ma đi theo, export `.apk` / `.ipa` ký chính thức, domain server mặc định
(`Settings.DEFAULT_SERVER` vẫn là `https://monmon.io.vn` — nhập địa chỉ thật ở Login → "Cài đặt máy chủ").

## Cấu trúc

```
AnPhong-App/
├── project.godot          # Godot 4, Compatibility, viewport 960x432, landscape, mouse<->touch
├── data/
│   ├── game/              # skills, items, schools, monsters, npcs, maps, constants, meta (.json) — tách từ gamedata.json của web
│   ├── quests/            # main, side, awaken (.json) — tools/export/export_quests.js
│   ├── map_looks.json     # tools/export/export_looks.js (nền, thời tiết, cảnh trí từng map)
│   ├── (assets/mapcache/)  # ảnh nền map bake sẵn (PNG) — chạy lại tools/export/bake_maps.ps1 khi đổi data/maps, map_looks.json, assets/art hoặc MapTileArt/MapView (đổi ảnh ô mẫu thì tăng MapView.CACHE_VER); thiếu/lệch thì game tự dựng như cũ
│   ├── maps/<id>.txt      # mỗi bản đồ một file (copy từ shared/maps, tools/sync/sync_maps.ps1)
│   └── skillfx/           # hiệu ứng kỹ năng, cùng file với web
├── assets/                # bg, chars, mobs, npcs, items (svg), fonts (Be Vietnam Pro), ui/icons (svg)
├── src/
│   ├── autoload/          # Settings, Net (HTTP), Socket (WebSocket), Data, Game, Social, Audio
│   ├── scenes/            # Boot -> Login -> World (World.gd = hub: node, trạng thái dùng chung, điều phối)
│   │   └── world/         # WorldPart + hệ thống: Map, Motor, Target, Buff, Combat, Life, Pet, Loot, Net, Potion, Form
│   ├── world/             # MapView, Background, CharSprite, MobSprite, RemotePlayer, MapEntities (NPC/cổng),
│   │                      # LootNode, FloatText, SkillFx (điều phối hiệu ứng kỹ năng), MapTileArt (sinh ảnh ô đất cho MapView)
│   │   └── fx/            # FxExt (sổ đăng ký, thứ tự = ưu tiên), FxShape (node vẽ), FxProj (đạn), AuraOrbit, FxCreature,
│   │                      # FxSkill_<Class>.gd = bản hiện hành (Swordsman, Archer, Assassin, Tank, Mage,
│   │                      # Healer, Necromancer, Summoner, CommonOmni); FxSkillOld_*.gd = bản cũ, chỉ còn các kỹ năng chưa viết lại
│   └── ui/                # UITheme (design system), SplashBG, MobileHUD (hub), GamePanels (hub), PanelWidgets, SkillIcons...
│       ├── hud/           # HudPart + HudStats/Menu/Controls/Chat/Notices/Panel/Prompts/ScreenFx/Buffs, ActionButton
│       └── panels/        # PanelBase + PanelBag/Equip/Skills/Quest/World/Shop/Pets/System/Awaken/Social (mỗi file vài build_<tab>)
└── tools/                 # tests/ (check_scripts, ui_smoke, combat_test, move_test, ...), export/ (export_*.js lấy dữ liệu từ web), sync/ (sync_maps, sync_assets)
```

## Chạy

```powershell
# Mở / import (lần đầu hoặc khi thêm asset)
godot --headless --path D:\Source\AnPhong-App --import
godot --path D:\Source\AnPhong-App

# Kiểm tra lỗi parse mọi script
godot --headless --path D:\Source\AnPhong-App --script res://tools/tests/check_scripts.gd

# Chụp ảnh giao diện không cần server (dữ liệu nhân vật giả)
godot --path D:\Source\AnPhong-App --rendering-driver opengl3 --script res://tools/tests/ui_smoke.gd -- <login|boot|hud|world|combat|menu|bag|char|skills|shop|social|trade> out.png
```

Godot 4.7 đang để ở `D:\Source\.godot-validate\`. Đồng bộ dữ liệu từ web:

```powershell
node D:\Source\AnPhong\server\tools\export-gamedata.js
node D:\Source\AnPhong-App\tools\export\split_gamedata.js
powershell -ExecutionPolicy Bypass -File D:\Source\AnPhong-App\tools\sync\sync_maps.ps1
powershell -ExecutionPolicy Bypass -File D:\Source\AnPhong-App\tools\sync\sync_assets.ps1
```

## Giao thức (đã đối chiếu với server)

- HTTP: `/api/login|register|me|action|logout`. Phiên là cookie `ap_session`, lưu trong `Settings.session`.
- Phản hồi action có `events` — `Net.action` chuyển cho `Game.on_events` (msg, levelup, loot, picked, map...).
- WebSocket `/ws?token=<ap_session>`:
  - Gửi: `pos {map,x,y,f,a,h,r}` (a: idle/run/jump/fall/atk/hit/dead), `hit {u,d,c,k,dir,id}`, `cast`, `chat {text,ch}`, `ch {n}`, `party_*`, `trade_*`.
  - Nhận: `hello`, `room {list}`, `join {p}`, `leave {id}`, `snap {p:[[id,x,y,f,a]]}`, `look`, `mobs {list}`, `msnap {p:[[u,x,y,f,st,fl]]}`,
    `mhit/mhp/mdie/mresp/mspawn/mdel/mact`, `chat`, `sys`, `patch`, `party`, `trade`, `chlist`.
- Hạ quái: khi `mdie` có `kid` và mình là người hạ/góp sức -> gửi `kills {list:[{kid}]}` để nhận thưởng.
- Quái gây sát thương bằng đòn lao (`st == 2`): client kiểm va chạm và tự trừ máu (giống web), chết thì gửi `die {where}`.

## Hệ thống giao diện

- `UITheme.gd`: token màu / cỡ chữ (>=13) / khoảng cách / vùng chạm (>=44), font đóng gói, icon SVG, safe area.
- HUD: joystick động nửa trái, nút Đánh + cung 5 kỹ năng + Nhảy bên phải, nút ngữ cảnh (Nói chuyện / Vào cổng / Nhặt) ở giữa-dưới.
- Điều khiển game chỉ dùng `InputEventScreenTouch/Drag` (đa điểm); nút panel dùng chuột giả lập từ cảm ứng (`emulate_mouse_from_touch`).
  Trên PC để thử: `emulate_touch_from_mouse` đã bật.

## Nguyên tắc

- Không sửa luật chơi ở client. Số liệu ở `shared/` và server.
- Mỗi lần sửa UI: chạy `check_scripts.gd` rồi chụp ảnh bằng `ui_smoke.gd`.
- Test runtime bằng scene thật, không chỉ `--editor --quit` (editor không load script chưa dùng).
- Không restart/deploy server khi đang phát triển app.

## Build iOS không cần Mac
Xem [docs/IOS_CI.md](docs/IOS_CI.md) — GitHub Actions (macOS) xuất dự án Xcode và ký .ipa.

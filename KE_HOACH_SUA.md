# Kế hoạch sửa app An Phong (Godot)

Ngày rà soát: 2026-11-23. Chỉ đọc mã, chưa chạy được app (máy chưa có `godot` trong PATH, server cần PostgreSQL) nên mục "giao diện" dựa trên đọc code, chưa có ảnh chụp.

## A. Bug / thiếu sót chức năng (so với web + server)

### Nghiêm trọng (game không chơi trọn vẹn được)
1. **Nhân vật bất tử, quái vô hại.** Web có `hurtPlayer` (combat.js, boss.js); app không có. Không gửi `die`, `respawn_choice`, `kills`, `save` -> không chết, không hồi sinh, HP/MP và vị trí không lưu lên server.
2. **Không nhặt đồ.** Event `loot`/`picked` chỉ ghi log; app không có vật phẩm rơi trên map, không gửi `pickup`.
3. **Không tương tác được trên bản đồ.** NPC không hiện, không chạm vào được; cổng dịch chuyển không đi vào được (chỉ có panel "Cổng"). Muốn mua đồ phải gõ `/shop` trong chat.
4. **Sát thương client tự tính** (`World._strike_nearby`: `atk * power` từ bản tính rút gọn `Game.recalc_stats`). Server chỉ kẹp trần nên số sát thương sai lệch so với web (thiếu perks/set/awaken/buff). README ghi "không tự tính luật" nhưng thực tế đang tự tính.
5. **Thiếu hệ thống xã hội:** `party`, `trade`, chợ người chơi (`market_*`), kênh khu (`ch`/`chlist`) — Socket nhận gói nhưng không có UI. Chat không đổi kênh được.
6. **Thiếu boss, target, cooldown/MP kỹ năng**: bấm kỹ năng liên tục, không có hồi chiêu, không kiểm MP, không có siêu tuyệt kỹ / fusion / manaburst / allin (chỉ vẽ FX khi server gửi).
7. **Âm thanh: không có** (`assets/audio` trống, `Audio.gd` không được gọi ở đâu).

### Lỗi logic / kỹ thuật
8. ~~`Settings.DEFAULT_SERVER` là domain giả~~ — đã đặt `https://monmon.io.vn` (2026-11-23; `/api/me` trả 200, `/ws` trả 401 với token sai, tức server tới được).
9. `Settings._apply_fps` đổi `physics_ticks_per_second` = 30 khi bật "tiết kiệm pin" -> vật lý/va chạm/nhảy đổi theo FPS.
10. `Boot.gd`: `Net.version()` luôn lỗi (server chưa có `/api/version`) nên không bao giờ phát hiện dữ liệu cũ. Cần thêm endpoint hoặc bỏ bước.
11. `Game.set_player`: dòng `if not p.has("hp")` thừa/vô nghĩa; `hp` thiếu thì về 0 (thanh máu trống khi `player` không có hp).
12. `World._on_players`: nhánh `t in ["leave","mdel"]` xử lý trùng với `_on_mob_packet` (mdel đã return sớm, nên chỉ `leave` chạy; code thừa gây hiểu nhầm). Người chơi khác không có tên, không có hướng/anim/HP, chỉ nhảy vị trí (không nội suy).
13. `World._on_offline` rỗng: mất mạng không có thông báo; `Net.action` trả `{}` khi hàng đợi bận nên panel không biết kết quả.
14. `World._upsert_remote` gọi `sprite.setup()` trước khi add vào cây; `_mobs`/`_players` không dọn khi đổi map (chỉ có 1 lần load map lúc `_ready`). **Đi qua cổng / teleport không tải lại map** -> `change_map`/`teleport` đổi server nhưng scene vẫn map cũ cho tới khi vào lại app.
15. Joystick: chỉ nhận chạm trong ô 132x132 nên "kéo từ đâu cũng được" không hoạt động; chuột trái trên desktop cũng điều khiển joystick và đang tranh với phím attack (chuột trái = đánh).
16. `GamePanels` rải rác: `Net.action` không có callback, `act()` luôn hiện toast "Đang xử lý…" kể cả khi bị chặn; panel build lại toàn bộ khi mỗi patch (mất vị trí cuộn, giật).
17. `build_skills`: closure `func(): _pick_skill_slot(i)` trong vòng lặp bắt biến `i` — kiểm tra lại GDScript capture; `learn_skill` liệt kê `learned.keys()` nên **không hiện kỹ năng chưa học** để học.
18. Bản đồ/panel dùng `Data.MAPS`... nhưng Quest panel in id thô (`step`, `progress` key), phụ tuyến in id thay vì tên.
19. `project.godot`: `config/features` ghi 4.3 nhưng README ghi 4.7; `viewport 1280x720`, `stretch=expand` + HUD đặt theo offset cứng nên lệch trên màn hình dài/tai thỏ (không có safe area).
19b. **Không đăng ký được tài khoản:** ô "Tên nhân vật" bị ẩn (`_char.visible = false`) và không có chỗ nào bật lên (`_on_register_toggled` không được nối), nên bấm Đăng ký luôn báo "Nhập tên nhân vật".
20. Không có kiểm thử tự động; chưa export được APK/IPA.

## B. Giao diện (vì sao "xấu")
- **Tab bar 19 nút nhỏ** (64x36, chữ 12) trong 620px cuộn ngang -> khó bấm trên điện thoại, không có icon, các nút ngữ cảnh (Cửa hàng, Rèn, Kho, Dịch chuyển, NPC, Mật mã, Cổng) lẫn với nút luôn dùng.
- **Chồng lấn HUD**: log chat (y=118..268) đè lên badge/thanh trạng thái; quest tracker, tab bar, toast cùng nằm góc phải trên; ô chat đặt ngang hàng joystick nên bị ngón tay che.
- **Nút kỹ năng** là chữ (icon emoji từ data), không có hồi chiêu, không có hiệu ứng nhấn, kích thước 58x62 cứng.
- **Panel** là 1 ô to ở giữa che gần hết màn hình, dùng chung layout "danh sách nút" (`action_button` cho mọi thứ: Lấy · tên đồ, Gửi · tên đồ…). Không có icon ở Kho/Cửa hàng/Rèn/Kỹ năng, không tooltip, không so sánh trang bị, không hiện chỉ số vật phẩm.
- **Font** nạp từ `C:/Windows/Fonts/segoeui.ttf` -> trên Android/iOS không có file này nên rơi về font mặc định (thiếu dấu tiếng Việt/emoji). Emoji (🗺🏪⚒…) không hiển thị đồng đều.
- **Màn Login/Boot** chưa áp theme (dùng control mặc định của Godot, `Title` là Label trơn), không logo, không nhớ tài khoản, nút Đăng ký bấm là gọi API ngay (cờ `_on_register_toggled` không được nối).
- **Thế giới:** bản đồ vẽ bằng `draw_rect` đơn sắc; NPC/props không có; số sát thương nổi, thanh máu quái, tên người chơi khác không có; nhân vật không có tên trên đầu.
- Cỡ chữ 10–13px khắp nơi, trên mobile quá nhỏ; không có scale theo DPI.

## C. Kế hoạch sửa (theo giai đoạn)

### Bản đồ: mỗi map một file (ĐÃ LÀM 2026-11-23)
- Web lưu 59 map ở `shared/maps/<id>.txt`; trước đây app gộp tất cả vào `MAP_TEXTS` trong `data/gamedata.json`.
- Nay app có `data/maps/<id>.txt` (59 file, đã kiểm tra nội dung trùng khớp 100% với web). `Data.map_text(id)` / `Data.has_map_text(id)` đọc từng file và cache; thiếu file thì rơi về `MAP_TEXTS`. `World.gd` đã đổi sang dùng hàm này.
- Đồng bộ lại khi web sửa map: `powershell -ExecutionPolicy Bypass -File D:\Source\AnPhong-App\tools\sync_maps.ps1`.
- **Chưa kiểm tra bằng Godot** (máy chưa có Godot): cần mở thử World ở vài map (`cong_do`, `lang`, `rung`, `hang`).
- Việc tiếp theo cho phần map, gộp vào Giai đoạn 1 mục 2 (đổi map đúng): chỉ nạp map đang đứng + map kế cận qua cổng (tải lười, giải phóng map cũ), `MapView`/`Background` dựng lại khi đổi map.
- Tùy chọn: tách luôn phần metadata (`MAPS`: NPC, cổng, spawn, theme) thành `data/maps/<id>.json` để mỗi map đủ cả hình lẫn dữ liệu trong một chỗ; hiện metadata vẫn nằm trong `gamedata.json`.

### Quyết định đã chốt (2026-11-23)
- **Chỉ nhắm điện thoại** (PC đã có web): bỏ mọi hỗ trợ chuột/bàn phím cho giao diện; chỉ chạm. Khóa ngang (landscape), thiết kế theo 2 cỡ: ~800×360 (điện thoại nhỏ) và ~900×412 (tai thỏ), có safe area.
- **Server có domain + HTTPS**: đặt `DEFAULT_SERVER` thành domain thật, ẩn ô Server URL ở Login (chỉ để trong Cài đặt nâng cao). Cần bạn cho domain.
- **Ưu tiên giao diện đẹp trước**, rồi mới tới chức năng lõi.

### Giai đoạn 0 — Chuẩn bị (0,5 ngày)
- Cài Godot 4.x, thêm vào PATH; `git init` cho `AnPhong-App`; chụp ảnh hiện trạng.
- Thiết lập chạy thử trên điện thoại thật (Android: bật USB debugging, export debug APK) và giả lập viewport điện thoại trên desktop để lặp nhanh. Smoke test headless mở 19 panel.
- Đặt `DEFAULT_SERVER` = domain thật.

### Giai đoạn 1 — Giao diện mobile (ưu tiên, 5–6 ngày)
1. **Nền tảng thiết kế**: token trong `UITheme` (màu, cỡ chữ tối thiểu 14px, khoảng cách, bo góc, vùng chạm tối thiểu 48px); bundle font Be Vietnam Pro vào `res://assets/fonts` (bỏ font Windows); icon SVG thay emoji; hàm scale theo DPI và safe area.
2. **Login / Boot**: theme, logo, nền nghệ thuật, nhớ tài khoản, chuyển Đăng nhập ↔ Đăng ký rõ ràng (sửa luôn lỗi không đăng ký được), trạng thái kết nối.
3. **HUD chơi game** (bố cục ngang một tay cái):
   - Trái-trên: avatar tròn + HP/MP/EXP gọn, tên · Lv.
   - Giữa-trên: nhiệm vụ đang làm (thu gọn được); toast.
   - Phải-trên: 1 nút Menu + mini-map/tên map; menu mở dạng lưới icon lớn (Túi, Nhân vật, Kỹ năng, Nhiệm vụ, Bản đồ, Xã hội, Cài đặt) thay cho 19 nút.
   - Trái-dưới: joystick động (chạm bất kỳ nửa trái màn hình), chat thu gọn thành bong bóng ở giữa-dưới.
   - Phải-dưới: nút Đánh lớn + vòng 5 kỹ năng hình tròn có icon, vòng hồi chiêu, rung nhẹ khi bấm; nút Nhảy riêng.
   - Panel ngữ cảnh (Cửa hàng, Rèn, Kho, Dịch chuyển, NPC, Mật mã) chỉ mở khi chạm NPC trên bản đồ, không có nút cố định.
4. **Panel**: bottom-sheet hoặc hai cột (danh sách trái, chi tiết phải), ô đồ có icon + viền độ hiếm + chạm giữ xem chi tiết, nút đóng lớn, giữ vị trí cuộn khi refresh, cuộn bằng vuốt. Làm lại theo thứ tự: Túi, Trang bị, Nhân vật, Kỹ năng, Cửa hàng, Rèn, Kho, còn lại.
5. **Thế giới**: số sát thương nổi, thanh máu quái, tên trên đầu nhân vật/người chơi khác, NPC và cổng có icon/hiệu ứng nổi bật, tinh chỉnh bản đồ bớt đơn sắc.
6. Chụp ảnh từng màn trên điện thoại thật để duyệt trước khi sang giai đoạn sau.

### Giai đoạn 2 — Vòng chơi cốt lõi (3–4 ngày)
1. Nhận sát thương từ quái, chết/hồi sinh (`die`, `respawn_choice`), gửi `save` định kỳ và khi thoát/đổi map.
2. Đổi map đúng: sau `change_map`/`teleport`/`respawn` dọn mob/remote, nạp lại map (chỉ nạp map đang đứng, giải phóng map cũ), dịch chuyển tới `arrive`.
3. Chạm NPC/cổng trên bản đồ để tương tác (bỏ lệnh `/shop`, `/npc`).
4. Vật phẩm rơi + `pickup`; hồi chiêu + MP kỹ năng.
5. Sát thương: đối chiếu `Formulas`/`calcStats` với `shared/core.js` (mở rộng `tools/compare_formulas.js`).
6. Sửa lỗi kỹ thuật A.8–A.15 (FPS/vật lý, version endpoint, safe area…).

### Giai đoạn 3 — Hoàn thiện (3–4 ngày)
- Xã hội: đội nhóm, giao dịch, chợ, đổi kênh khu (làm dạng sheet cảm ứng).
- Boss + target; fusion/manaburst/allin.
- Âm thanh (cùng bộ với web `core/sound.js`), rung (haptic).
- Người chơi khác: tên, anim, nội suy vị trí.
- Export Android/iOS ký chính thức, test nhiều máy, tối ưu FPS/pin/nhiệt.

### Thứ tự
GĐ0 -> GĐ1 (giao diện) -> GĐ2 (lõi) -> GĐ3. Khoảng 2–3 tuần làm một mình. Lưu ý: GĐ1 làm trước nên một số HUD (hồi chiêu, tương tác NPC) sẽ là khung rỗng/dữ liệu giả cho tới GĐ2.

## D. Còn cần bạn cung cấp
- Domain server thật (để đặt mặc định).
- Android, iOS hay cả hai? (iOS cần máy Mac để export)
- Có muốn giữ phong cách "xanh đêm + vàng đồng" hiện tại, hay đổi sang hướng khác (ví dụ lấy theo màu web)?

## E. Nhật ký tiến độ
### 2026-11-23 — Giai đoạn 0 + GĐ1 (đợt 1) xong
- Có Godot 4.7.2 tại `D:\Source\.godot-validate\`; `git init` đã chạy (chưa commit). Chụp thử giao diện: `godot --path . --rendering-driver opengl3 --script res://tools/ui_smoke.gd -- <login|boot|hud|menu|bag|char|skills> out.png` (dữ liệu nhân vật giả, không cần server).
- `project.godot`: viewport 960×432, **sửa orientation (trước là 1 = dọc, nay 4 = ngang)**, bật `emulate_touch_from_mouse`, bỏ chuột trái khỏi hành động Đánh.
- `UITheme.gd` viết lại: token màu/cỡ chữ/khoảng cách, font Be Vietnam Pro đóng gói (`assets/fonts`), 19 icon SVG (`assets/ui/icons`), safe area, nút chính/phụ/icon.
- `Login`/`Boot` làm lại (nền parallax, logo, tab Đăng nhập ↔ Đăng ký, **sửa lỗi không đăng ký được**, nhớ tên đăng nhập, auto-login theo cookie phiên — trước đây không bao giờ chạy vì chỉ kiểm `token`).
- `MobileHUD.gd` viết lại: avatar + HP/MP/STA, EXP mảnh dưới đáy, nhiệm vụ giữa-trên, tên map + chat + menu phải-trên, joystick động (nửa trái), nút Đánh lớn + cung 5 kỹ năng + nút Nhảy (vòng hồi chiêu `start_cooldown` đã có, chưa nối), menu lưới icon thay 19 nút, panel dạng ngăn kéo bên phải (giữ vị trí cuộn), toast mờ dần, log tự biến mất.
- **Chưa kiểm tra:** cảm ứng thật (joystick đa điểm, nút kỹ năng) — chỉ mới kiểm layout bằng ảnh chụp; cần thử trên điện thoại/giả lập. Emoji icon kỹ năng cần xem trên Android (phụ thuộc font hệ thống).
- **Còn lại của GĐ1:** làm lại từng panel (Túi, Trang bị, Nhân vật, Kỹ năng, Cửa hàng, Rèn, Kho… dạng hai cột, tooltip, bỏ emoji trong tiêu đề); thế giới (số sát thương nổi, thanh máu quái, tên trên đầu, NPC/cổng); đặt domain thật làm `DEFAULT_SERVER`.

### 2026-11-23 (đợt 2) — GĐ1 hoàn tất + GĐ2 + phần lớn GĐ3
**Phát hiện lớn khi đối chiếu giao thức:** app cũ xử lý sai nhiều gói WS (`room`, `join`, `snap`, `msnap` đều khác định dạng server)
và **không bao giờ đổi phiếu thưởng `kills`** (nên hạ quái không nhận kinh nghiệm/vàng/đồ). Đã sửa toàn bộ — xem "Giao thức" trong README.

Đã làm:
- Thế giới: `World.gd` viết lại. Nhận sát thương từ đòn lao của quái, boss `mact` (slam/special/enrage), chết + bảng hồi sinh (`die`),
  đổi map thật qua cổng/dịch chuyển (`change_map`/`teleport`, fade, dựng lại map/quái/người chơi), lưu định kỳ (`save`),
  đổi phiếu thưởng (`kills`), đồ rơi + nhặt (`pickup`), nút tương tác ngữ cảnh (NPC / cổng / đồ), hồi chiêu + MP kỹ năng,
  kỹ năng nhiều nhát + lướt, hồi máu/MP tự nhiên, camera giới hạn theo map + rung, chữ nổi sát thương.
- Đối tượng: `MobSprite` (nội suy, thanh máu sau khi bị đánh, tên khi gần), `RemotePlayer` (tên, hoạt ảnh, bóng chat),
  `MapEntities` (NPC + cổng theo marker), `LootNode`, `FloatText`.
- Panel: viết lại bố cục hai cột cho 19 panel + 2 panel mới (Xã hội: quanh đây / đội / khu / chợ; Giao dịch trực tiếp). Ô đồ có icon, chi tiết có chỉ số.
- Mạng: sửa `send_chat` (kênh dạng chuỗi), `send_channel` (`n`), `send_hit` (cờ chí mạng), forward `events` của HTTP.
- Âm thanh tổng hợp bằng code (hit/crit/hurt/cast/pickup/coin/levelup/portal/ui/death) + chỉnh âm lượng, rung khi bị đánh (Cài đặt).
- Công cụ: `tools/check_scripts.gd` (bắt lỗi parse), `tools/ui_smoke.gd` (chụp ảnh + mô phỏng gói tin, kể cả `combat`).

**Còn lại / rủi ro (chưa làm hoặc chưa kiểm):**
1. **Chưa chạy với server thật** (cần PostgreSQL) và **chưa thử cảm ứng thật** — mọi thứ mới kiểm bằng ảnh chụp và gói tin giả.
   Việc đầu tiên nên làm: đặt domain thật, đăng nhập, đánh một con quái, xem có nhận thưởng + log không.
2. Vị trí Y của quái so với chân sprite chưa đối chiếu với server (có thể lệch vài px).
3. Fusion / manaburst / allin, thú đồng hành và bóng ma đi theo, `target` khoá mục tiêu, hiệu ứng buff đầy đủ của web (né, khiên đá, hộ mệnh...).
4. Sát thương vẫn tính ở client từ `calcStats` rút gọn (server kẹp trần). Cần port đầy đủ `calcStats` nếu muốn khớp web.
5. Quest panel hiển thị id thô cho phụ tuyến (gamedata chưa xuất tên nhiệm vụ).
6. Export Android/iOS ký chính thức, test nhiều máy, tối ưu pin/nhiệt.
7. Domain mặc định `Settings.DEFAULT_SERVER`.

### 2026-11-23 (đợt 3) — Thiết kế lại giao diện panel
Vấn đề phát hiện khi rà lại: ô đồ quá to và nhét cả tên + số lượng + giá vào ô; panel Trang bị bị cắt (thấy 8/10 ô) và phải cuộn cả trang để thấy nút; khung chi tiết cuộn theo danh sách; mỗi lần đổi panel phải quay ra menu.
Đã sửa:
- **Ô đồ kiểu game** (`PanelWidgets.item_cell`): vuông 58px, chỉ icon + viền độ hiếm, số lượng ở góc dưới phải, huy hiệu (+n / Mặc) góc trên trái. Tên, chỉ số, giá chỉ xem ở khung chi tiết. Túi lấp đầy bằng ô trống như game.
- **Cửa hàng** dạng hàng danh sách: icon | tên + chỉ số | giá (vàng) bên phải.
- **Trang bị**: 10 ô vuông (5×2) có nhãn nhỏ bên dưới + tổng ATK/DEF/Chí mạng.
- **Kỹ năng**: thanh 5 ô tròn (emoji + số), danh sách gọn, khung chi tiết có Nâng cấp + gán ô 1–5.
- **Bố cục chung**: thanh tab dọc bên trái (Túi, Trang bị, Nhân vật, Kỹ năng, Nhiệm vụ, Bản đồ, Xã hội) để chuyển nhanh; panel rộng hơn (80% màn); hai cột tự cuộn riêng, khung chi tiết luôn thấy nút hành động.

### 2026-11-23 (đợt 4) — Thiết kế lại theo phong cách game (tham khảo UI game RPG mobile)
Tham khảo thực tế (Google Images: inventory/equipment UI, HUD mobile RPG 2D) cho thấy: khung viền vàng nổi khối, nền gradient,
ô đồ lõm có viền màu theo độ hiếm, tiêu đề dạng ribbon, thanh máu có khung + độ bóng, màn trang bị nhân vật ở giữa, ô hai bên.
- **`src/ui/UISkin.gd`** (mới): tự vẽ bằng code các texture 9-slice khử răng cưa — khung panel, thẻ, khung lõm, ribbon, nút (default/primary/danger/ghost × 4 trạng thái),
  nút tròn, ô đồ (6 độ hiếm + chọn + trống), thanh máu (khung + fill bóng), tab, viên thuốc HUD. (Tên `Skin` trùng lớp gốc của Godot nên đặt `UISkin`.)
- Áp vào toàn bộ: theme mặc định, Login/Boot, HUD (avatar khung vàng, thanh HP/MP/STA có khung, nút kỹ năng viền vàng nổi khối, nút menu/chat tròn),
  ngăn kéo panel (khung vàng, ribbon tiêu đề, thanh tab dọc), menu lưới 7 cột, mọi ô đồ/hàng danh sách/thẻ/tab.
- **Trang bị kiểu nhân vật ở giữa**: cột 5 ô trái + khung nhân vật + cột 5 ô phải; ô trống ghi tên ô; khung bên phải hiện chỉ số hoặc chi tiết món.
- UI đặt `texture_filter = LINEAR` ở root để khung/icon mượt trên màn hình DPI cao (project mặc định là Nearest cho pixel art).

### 2026-11-23 (đợt 5) — Làm đẹp + giao tiếp với người dùng
- **Hiệu ứng** (`src/world/Fx.gd`, mới): vệt chém lưỡi liềm (đánh thường + kỹ năng cận chiến), tia lửa trúng đòn (crit to + vàng), khói/tia khi quái chết (boss to hơn),
  cột sáng + vòng sóng khi thăng cấp, vòng khiên/hồi máu/cường hóa theo loại kỹ năng, vệt lướt, nháy đỏ khi bị đánh, viền đỏ nhấp nháy khi máu < 30%, rung camera.
- **Hội thoại NPC** (`src/ui/NpcDialog.gd`, mới): chân dung trái, bảng tên + lời thoại gõ từng chữ, danh sách lựa chọn phải (có icon, nút vàng cho hành động chính),
  chạm màn hình để bỏ qua hiệu ứng gõ. Trên đầu NPC có dấu `!` / `?` nhiệm vụ và icon dịch vụ nhấp nhô.
- **Kỹ năng**: chi tiết đầy đủ (loại, tuyệt kỹ, MP/hồi, thanh cấp kỹ năng, sức mạnh/số nhát/tầm, mốc nâng cấp Lv5/Lv10 khoá-mở, gán ô nào có đánh dấu ô hiện tại, lý do nút bị khoá).
  Nút kỹ năng ngoài HUD có vòng sáng khi hồi chiêu xong.
- **Trang bị**: khung chi tiết hiện độ hiếm, yêu cầu cấp/class (xanh nếu đạt, đỏ nếu chưa), chỉ số, và **so sánh với món đang mặc** (▲ xanh / ▼ đỏ).
- **Kỳ Nguyên**: panel riêng, thẻ từng ấn (icon, trạng thái ĐANG BẬT / đã sở hữu / mở khoá ở cấp N, hiệu ứng, chỉ số cộng, nút Bật/Tháo, giá Linh Ngọc).
- **Giao tiếp**: thông báo có loại (✓ xanh / ✕ đỏ / ! cam) + âm báo lỗi; hộp xác nhận cho vứt đồ, giải phóng bóng ma, tẩy điểm kỹ năng, đăng xuất;
  thanh "Mất kết nối" khi rớt mạng; gợi ý lần đầu (nói chuyện NPC, nhặt đồ, qua cổng, máu thấp) chỉ hiện một lần; thanh nhiệm vụ hiện tiến độ thật (`queststep`).

### 2026-11-23 (đợt 6) — Bản đồ thế giới kiểu web + gọn gàng hơn
- **Bản đồ thế giới** (`src/ui/WorldMapView.gd`, mới): sơ đồ giấy da, các khu là điểm tròn nối nhau bằng đường (xanh = đã mở, nét đứt xám = chưa mở),
  Tân Đô viền đỏ to hơn, sao vàng = vị trí hiện tại, ổ khoá = chưa mở. **Cùng thuật toán bố cục và hạt giống với web** (`web/panels/map.js`) nên sơ đồ có cùng hình dạng.
  Kéo để di chuyển, nút +/− phóng to thu nhỏ, chạm điểm để xem Quái / NPC / Nối tới + lý do chưa mở, nút "Về vị trí của tôi". Nhớ vị trí kéo khi mở lại.
- **Dữ liệu nhiệm vụ** (`tools/export_quests.js` -> `data/quests.json`): 100 nhiệm vụ chính + 28 phụ tuyến. Nhờ đó bản đồ biết khu nào đã mở (`Data.quest_done`) và panel Nhiệm vụ có tên thật.
- **Panel Nhiệm vụ** viết lại: tên nhiệm vụ, NPC + nơi gặp, mục tiêu có thanh tiến độ (hạ quái / thu thập / đến nơi / cấp), phần thưởng dạng chip, trích lời thoại; phụ tuyến có tên.
- **Gọn gàng / trải nghiệm**: thanh tab dọc có nhãn chữ; Túi có lọc (Tất cả / Trang bị / Tiêu hao / Khác); **nút bình máu / MP nhanh** ngoài màn chơi (có số lượng, hồi chiêu 1s);
  thanh chờ mảnh dưới tiêu đề khi đang gửi lệnh lên server; âm nhấn nút; hiệu ứng mờ khi đổi tab.
- Lưu ý: khi export lại gamedata từ web nhớ chạy thêm `node tools/export_quests.js`.

### 2026-11-23 (đợt 7) — Đất đặc, nền riêng từng map, NPC giống web
Lỗi người dùng chỉ ra: dưới mặt đất vẫn lộ ảnh nền (app cũ chỉ vẽ một dải cỏ mỏng, README cũ còn ghi "KHÔNG tô đặc"), mọi map dùng chung vài nền theo theme, NPC là hình người vẽ tạm, HUD hiện tên map thừa.
- **Công cụ mới**: `tools/export_art.js` chạy NGUYÊN code art của web (ô đất, thác, cảnh trí, 100+ NPC) trên một Phaser Graphics giả có rasterizer khử răng cưa -> PNG vào `assets/art/` (+ `meta.json` hệ số HD).
  `tools/export_looks.js` xuất diện mạo từng map của web -> `data/map_looks.json` (công thức nền ghép lớp + chỉnh màu, sương, ánh sáng, thời tiết, cảnh trí, biến thể ô đất). Chạy lại khi web đổi art/map.
- **Đất** (`MapView.gd` viết lại): ô đất ĐẶC như web — mặt cỏ/đá trên cùng, thân đất có vân (3 biến thể), viền tối + bo góc theo hàng xóm, bục gỗ, cỏ/hoa/sỏi rải trên mặt đất, biến thể theo map (tuyết, cát, đá tím, đất nâu...). "Nướng" thành ảnh 1024px khi vào map (≈70–90ms trên máy tính).
  Có nhà ($), đèn (!), cây (&), pha lê/nhũ đá (^), bộ props ảnh (thông, xương rồng, đá...), thác và hồ nước chuyển động.
- **Nền riêng từng map** (`Background.gd` viết lại): đúng công thức web (59 map, 67 bộ nền), shader chỉnh hue/sat/lum/tint/mix/gamma, cảnh tĩnh (lr_*) phủ kín + ghép gương, sương sát đất.
  `Weather.gd` (mới): ánh sáng chung nhân màu, hạt sáng, mưa/tuyết/than hồng/sương theo từng map.
- **NPC**: dùng hình vẽ của web (tóc, áo, đạo cụ theo từng người) + ảnh gốc cho 3 NPC có ảnh; bóng dưới chân, thở nhẹ, quay mặt vào giữa map; dấu "!"/"?" nhiệm vụ lấy từ nhiệm vụ hiện tại thật (chỉ NPC giao nhiệm vụ có dấu).
  Cổng dùng hình cổng của web (cộng sáng, co giãn); cổng gom nhiều điểm đến mở bảng chọn điểm đến thay vì đi thẳng.
- Bỏ tên map trên HUD. Camera dừng đúng đáy map (không còn lộ nền dưới đất).
- Chưa làm: cây/cỏ lay theo gió, lõi sâu tối cho map nhiều tầng đã có nhưng chưa kiểm, quái "tall map" cuộn nền dọc, NPC ẩn theo chương (`npcHere`) — hiện hiện tất cả NPC khai báo trong map.

### 2026-11-23 (đợt 8) — Rà soát giao diện
- **Dải nền thừa dưới đất (mọi map)**: nền được đặt theo vị trí nhân vật trong khi camera bị chặn ở đáy map nên lệch nhau. Nay nền bám `Camera2D.get_screen_center_position()`.
- **Mưa/tuyết đè lên panel**: `MobileHUD` là CanvasLayer lồng trong node layer 10 nên mang chỉ số 1, ngang lớp thời tiết. Đã đặt layer = 10.
- Bảng Cổng hiện tên nhiệm vụ yêu cầu thay vì mã (`c3q6`), có 🔒 và khoá nút; Linh thú chỉ hiện điều khiển cho Triệu Hồi Sư; thêm trạng thái rỗng có icon + hướng dẫn (Dịch chuyển, Nhiệm vụ ngày, Xã hội, Đội, Chợ, Nhiệm vụ); nhãn thanh tab "Trang bị" thống nhất với menu.
- Chưa rà bằng tay: Login/Boot sau khi đổi nền, bảng hồi sinh, một số panel phụ (Bóng ma, Thú cưng, Class) vì cần dữ liệu thật.

### 2026-11-23 (đợt 9) — HUD gọn + nút đánh + đủ tab
- **Khung chỉ số** góc trái-trên làm lại: chân dung + cấp, bên phải là một khung duy nhất gồm 3 thanh có icon (♥ HP, ◆ MP có số, ⚡ thể lực mảnh). **Bỏ tên/hạng/class.** Nhiệm vụ chỉ còn **một dòng nhỏ** ngay dưới khung (chạm để mở panel Nhiệm vụ); bỏ viên thuốc nhiệm vụ giữa màn hình.
- **Cụm nút hành động**: nút Đánh to hơn, nền đỏ + vành vàng đôi; 5 kỹ năng nới cung (không còn chồng nhau), **viền theo loại** (tuyệt kỹ vàng, tấn công cam, phòng thủ xanh dương, hồi phục xanh lá, triệu hồi tím), **mờ đi khi không đủ MP**, số đếm hồi chiêu to hơn, vòng sáng khi sẵn sàng; nút Nhảy gọn.
- **Thanh tab dọc** nay đủ 9 mục không cần cuộn: Túi, Trang bị, Nhân vật, Kỹ năng, Nhiệm vụ, Bản đồ, Xã hội, **Thú cưng**, **Cài đặt** (Kỳ Nguyên, Bóng ma, Linh thú... vẫn ở menu).
- **Panel Thú cưng** làm lại: thẻ từng thú (cấp, trạng thái, thanh sinh lực, nút Triệu hồi / Thu hồi).
- **Panel Cài đặt** làm lại theo nhóm: thẻ tài khoản; Hiển thị (đồ họa thấp, 30 FPS, hiện số sát thương); Âm thanh & rung (âm lượng có %, rung); Khác (xem lại gợi ý, đăng xuất có xác nhận).

### 2026-11-23 (đợt 10) — Bố cục nút kỹ năng + thể lực rõ hơn
- **Thể lực**: thanh xanh lá sáng, cao 12px, có số (vd 86 / 100); HP 18px, MP 14px.
- **4 kỹ năng thường** (ô 1–4) xếp hàng ngang giữa-dưới màn hình; **kỹ năng đặc biệt** (ô 5, thường là tuyệt kỹ) là nút viền vàng, đặt chếch lên bên trái nút Đánh. Nút Nhảy và bình nhanh dời sang trái nút Đánh; nút tương tác / gợi ý nhích lên khỏi hàng kỹ năng.

### 2026-11-23 (đợt 11) — Biến hình (Ấn thức tỉnh) + thể lực
Trước đây app chỉ có 4 nút chọn Ấn trong panel Nhân vật, không có cách bật biến hình, không có thể lực thật (thanh luôn đứng yên), không gọi được NPC ẩn để mở khóa Ấn.
- **Dữ liệu**: `tools/export_quests.js` xuất thêm `AWAKENS` (5 Ấn: cấp, hao phí, hệ số, màu hào quang, mô tả), `STAMINA`, `EVOLUTION_SCHOOLS` -> `data/quests.json`.
- **Thể lực** (port từ web): tối đa theo cấp + nhanh nhẹn; đánh thường / kỹ năng / tuyệt kỹ tốn 4 / 14 / 50; hồi 12/s sau 0,8s không đánh; kiệt sức thì khoá tới 30%. Thanh thể lực trên HUD nay nhảy thật.
- **Biến hình**: nút ngọn lửa trên nút Đánh (chỉ hiện khi đã mở Ấn), nút nhỏ góc trên-trái hiện số La Mã Ấn đang chọn để **đổi ấn** (chỉ đổi lúc dạng thường). Bật: kiểm đủ năng lượng/thể lực (≥ 3 giây hao phí), nhân hệ số máu/năng lượng/tấn công/phòng thủ, nhuộm màu + hào quang lửa, vòng sóng, rung, banner; mỗi giây trừ năng lượng + thể lực, cạn mà hồi không bù thì tự về dạng thường; chết cũng tự kết thúc. Gửi `form_toggle` / `form_select` lên server, nhận sự kiện `form` / `awaken`.
- **Panel Biến hình** (menu): thẻ trạng thái + nút chính, mô tả, tài nguyên, danh sách 5 Ấn (hệ số, trạng thái, chọn ấn), hướng dẫn mở khóa. Panel Nhân vật có lối tắt.
- **NPC ẩn Người Gác Màn**: gõ "npc an" trong chat ở Tân Đô -> xuất hiện bên cạnh; hội thoại có nhận thử thách Biến Hình (đúng cấp, tuần tự) / Tiến hóa chức nghiệp và trả thử thách kèm tiến độ.
- Chưa làm: hình biến hình riêng theo class (web có bộ sprite form; app mới nhuộm màu + hào quang), phím tắt T.

### 2026-11-23 (đợt 12) — Ô kỹ năng đúng mô hình web + hào quang riêng từng Ấn
- **Ô kỹ năng**: HUD có 4 ô thường (slot 0–3), **2 ô tuyệt kỹ/tuyệt phẩm** (slot 5, 6 của server; phím R, X) cạnh nút Đánh, và **1 ô kỹ năng trang bị** (ô ảo từ món `grantsSkill`, phím V, chỉ hiện khi đang mặc). Tuyệt phẩm dùng chung 2 ô tuyệt kỹ (luật server). Panel Kỹ năng chia theo nhóm, gán ô theo loại, có mục Tuyệt phẩm và Kỹ năng trang bị.
- **Tuyệt phẩm**: gửi đúng gói `manaburst` / `allin` / `fusion` / `exec`. Chưa kiểm với server thật.
- **Hiệu ứng tung chiêu**: dùng chung công thức web (175 kỹ năng, 110 bộ lớp hiệu ứng khác nhau, 20 kiểu); các kỹ năng cùng kiểu và cùng bảng màu trông gần giống nhau.
- **Hào quang từng Ấn**: I vàng bốc lên · II hồng tím + tia điện · III băng lam, bông tuyết rơi · IV huyết hỏa dữ dội · V tím trắng, quầng sáng + vệt sao xoay.

### 2026-11-23 (đợt 13) — Vẽ lại hiệu ứng kỹ năng
Trước đây mọi layer đều vẽ bằng vài hình đơn giản (vòng tròn, chữ nhật) và mỗi layer bị nhân bản n lần chồng lên nhau nên kỹ năng nào cũng na ná.
- `SkillFx.gd` viết lại: hạt, tia, vòng, cột sáng, trận pháp, lưỡi chém, sét, vật rơi, thiên thạch, mưa tên, vết nứt, tàn ảnh đều vẽ theo **chủ đề của kỹ năng** (lửa: giọt lửa + cánh hoa; băng: mảnh băng + bông tuyết; sét: tia ngoằn ngoèo; bóng tối/hư vô: khói + ngũ giác; huyết: giọt máu; thánh: sao 4 cánh + tia mặt trời; gió: lưỡi liềm; đất: đá; kiếm/thép: lưỡi kiếm; cung: mũi tên; ...).
- Trận pháp nằm **dẹt trên mặt đất** và xoay; kiếm/búa/thiên thạch rơi từ trên xuống rồi nổ vòng sóng; nhát chém vung quét theo hướng nhìn; cộng sáng (ADD) cho hệ sáng, trộn thường cho hệ tối. Mỗi primitive chỉ một bản (không còn chồng 8 lớp).
- Nháy màn hình (flash) giờ phủ cả màn hình bằng CanvasLayer.

### 2026-11-23 (đợt 14) — Mỗi kỹ năng một hiệu ứng riêng
- Kiểm: 175 kỹ năng, 139 công thức khác nhau; 36 kỹ năng (33 nhóm) có công thức trùng hệt kỹ năng khác (thường khác class, cùng kiểu).
- Thêm **biểu tượng đặc trưng** theo `sig` của từng kỹ năng (86 loại: vuốt, kiếm chéo, mũi giáo, vòng xoáy, bóng phân thân, đầu lâu, phượng hoàng, rồng, bông tuyết, sét, thiên thần, cánh, khiên, gai...). Vẽ ngay lúc tung chiêu, to hơn với tuyệt kỹ.
- `tools/mark_variants.js` đánh dấu `variant` cho kỹ năng trùng công thức; app xoay tông màu + lật biến thể để mỗi kỹ năng nhìn khác nhau. Chạy lại script sau mỗi lần đồng bộ `data/skillfx` từ web.

### 2026-11-24 — Đồng bộ chiến đấu với web
Nguyên nhân máu thấp (3k thay vì 15k): `recalc_stats` cũ đọc `it.stats` do món đồ tự lưu (server không lưu) nên bỏ qua đồ/phẩm chất/cường hóa/bộ/nội tại/Kỳ Nguyên/Ấn. Bản mới đã port đủ và khớp web 2500/2500 ca ngẫu nhiên (`tools/calc_check.gd`).
- **Sát thương lên quái** (`_calc_hit`): trừ giáp quái (`defReduce`), cộng `boss%`, buff tấn công/chí mạng, xuyên giáp Thần Kiếm, chí mạng x1.6 (Cung Thủ x1.8, Sát Thủ x2.5 sau lướt), trần chí mạng 90%, dao động 0.9–1.1, Kiếm Tâm hồi 0,5% máu.
- **Quái đánh người** (`_hurt_player`): phẫn nộ x1.25 (cờ `fl & 4` từ server), giậm đất x1.5, chiêu trùm theo `style`; né Phiêu Diêu, Xuyên Không, Khiên Đá, Hộ Mệnh; Thành Đồng; thủ thế giảm sát thương; khiên năng lượng hút MP.
- **Buff** (`_buffs`): guard / manashield / buff cộng dồn từng kỹ năng; tốc đánh, hồi máu liên tục. Kỹ năng hồi máu nay hồi thật (Trị Liệu Sư +20%).
- **Hồi phục** (`_regen`): chỉ khi không giao chiến 2s, 0,5%/giây; đồ nhiễm chặn hồi máu; Dòng Chảy; Cấm Chú khóa MP.
- Đợt 2 (cùng ngày): **dung hợp Tử Linh** (cộng chỉ số bóng ma vào `recalc_stats`, tự hết hạn + gửi `fusion_end`); **thú đồng hành** gánh 18% sát thương, gục 15s rồi hồi 50%, hồi máu khi yên, lưu `pets` kèm save/đổi map; **phản sát thương** thủ thế; **Ấn Sát** (Sát Kiếp); **Trấn Hồn** hồi khi hạ quái; **Đóng Băng** bộ Băng Long; **Cổ Ngữ** kỹ năng đầu miễn MP; **Băng Sương** làm chậm; hút máu; kháng đánh thường; buff exec/vsSlowed/chain; kỹ năng gửi kèm slow/freeze/stun/knock; tiêu MP theo `costMul`, hồi chiêu theo `cdr`.
- Kiểm: `tools/calc_check.gd` (chỉ số, gồm dung hợp) và `tools/fx_check.gd` (hiệu ứng + nội tại) đều lệch 0 so với web. Chưa kiểm với server và cảm ứng thật.

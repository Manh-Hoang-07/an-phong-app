# Báo cáo rà soát & kế hoạch sửa hiệu ứng kỹ năng

Ngày rà soát: 2026-11-26. Chỉ đọc mã + dữ liệu (`data/skillfx/*.json`, `SkillFx.gd`, `fx/FxSkillOld_AssassinArcher..d.gd`, `World.gd`, `Proj.gd`, `Fx.gd`). **Chưa chạy Godot nên chưa có ảnh chụp**; kết luận dựa trên đọc code. Chưa sửa gì.

Tổng: 175 kỹ năng / 10 nhóm (sát thủ 22, cung thủ 23, tanker 24, kiếm sĩ 23, tử linh 13, pháp sư 24, trị liệu 22, triệu hồi 12, chung 4, toàn năng 8).

## 1. Kết luận: vì sao nhìn "đâu đâu"

Hình vẽ riêng của từng kỹ năng (`FxSkill_*`) **đã có cho 167/175 kỹ năng và tên khớp** (vd. Thiên Kiếm Giáng = kiếm trời trong cột sáng, Khiên Phi Trảm = đĩa khiên xoay). Cái làm sai là **4 lớp hiệu ứng chung chạy chồng lên mọi kỹ năng, không phân biệt class**:

| # | Lớp gây lệch | Ở đâu | Biểu hiện |
|---|---|---|---|
| L1 | **Viên đạn bay là một quả cầu sáng cho mọi kỹ năng** (cam; riêng pháp sư xanh). `arrow=false` ở mọi chỗ trừ 1 nơi. | `World._proj_color`, `World._shoot`, `Proj._draw` | Phi Đao, Tên Băng, Kiếm Khí, Quang Tiễn, Linh Điểu, Phi Tiêu Độc… đều bay ra "bóng đèn cam". ~37 kỹ năng bị. |
| L2 | **Hiệu ứng theo loại kỹ năng, màu cứng** | `World.gd` ~1070–1095 | `melee`/`backstep`: vệt chém vàng. `guard`/`buff`/`manashield`: bong bóng xanh/vàng. `aoe`/`meteor`/`sword_fall`/`arrow_rain`: **vòng sóng cam** (Băng Ngục, Giọt Thánh, Thiên Kiếm Giáng… đều có vòng cam). `heal`: vòng hồi. `summon`: vòng tím. |
| L3 | **Lớp "cast" chung của web**: mọi kỹ năng đều tự vẽ trận rune dưới đất (theo `theme`) + quầng sáng + 8 tia lửa | `data/skillfx/*.json` (layer `cast` giống hệt nhau: sigil r=58 + glow 1.7 + burst 8) | Kiếm sĩ/tanker/sát thủ cũng có "pháp trận" dưới chân; theme wind → xoắn ốc, holy → sao 8 cánh… |
| L4 | **`fire_all`: khi cast, bắn luôn mọi layer có trigger khác** (buff, dashStep, guard, arrowZone, heal, aoe…) | `SkillFx.play` (`fire_all := kind == "cast"`) | Chân Kiếm Thức Tỉnh (kiếm sĩ) nhận cột sáng thánh 320px + đĩa rune + **flash toàn màn hình**; Tuyên Chiến, Ý Chí Bất Diệt, U Minh Cuồng Triều cũng thế. Cung thủ nhận meteor/arrowZone chung, Pháp sư nhận flash. |
| L5 | Tia lửa khi trúng quái luôn trắng/vàng | `Fx.hit_spark` | Chém kiếm, bắn băng, độc, thánh… trúng đều tia lửa vàng giống nhau. |
| L6 | 8 kỹ năng chưa có hình riêng mới, dùng hình cũ/chung: ks30, pa9 (`swordshield`), ks40, ulKiem1 (`swordrain`), ks45 (`swordawaken`), ulChung1 (`quake`), tl1 (`healplus`), ps37 (`lightball`) | `SkillFx.SIG_BY_ID` | Cặp trùng nhau chỉ khác tông màu: ks40=ulKiem1, ks30=pa9. |

## 2. Quy tắc làm lại (áp cho tất cả)

1. **Một kỹ năng = một cụm hiệu ứng duy nhất**, mô tả đúng tên. Khi kỹ năng đã có hình riêng (`FxExt`), **tắt L2, L3, L4** cho nó (chỉ giữ layer `shake` nếu là chấn động).
2. **Viên đạn thật vẽ theo kỹ năng** (L1): thêm bảng `PROJ_SHAPE[id]` trong `Proj.gd` (dao găm, phi tiêu, mũi tên các loại, kiếm khí lưỡi liềm, sóng, đầu lâu, xích, rắn sét, cầu lửa/băng, tia thánh, quỷ hỏa, chim, rồng…), màu lấy từ `theme` của kỹ năng thay cho cam/xanh cứng. Hình riêng bay trước, hình `sig` chỉ vẽ phần nổ/đích — hết cảnh hai thứ chồng nhau.
3. **Hiệu ứng trúng đòn theo hệ** (L5): vệt chém thép (kiếm/tanker), mũi tên cắm + bụi (cung), tia lửa (lửa), mảnh băng (băng), giọt độc (độc/huyết), sao vàng (thánh), vòng linh hồn (tử linh/triệu hồi).
4. Kỹ năng **buff/hộ thể** vẽ trên người (aura/khiên/cánh…), kỹ năng **vùng** vẽ trên đất đúng vùng sát thương, kỹ năng **lướt** để lại tàn ảnh dọc quãng lướt.
5. Khung giới hạn: giữ pool Node2D, `MAX_PARTICLES`, `quality_low` như hiện tại.
6. Làm theo thứ tự: **(a)** L2+L4 (sửa nhanh, đổi diện mạo lớn nhất) → **(b)** L1 đạn bay → **(c)** L6 làm mới 8 kỹ năng → **(d)** L5 → **(e)** rà từng kỹ năng bằng cảnh xem thử (`FxGallery`: lưới 175 nút, bấm là phát, chụp ảnh đối chiếu).

## 3. Kế hoạch theo từng kỹ năng

Ký hiệu: **GIỮ** = hình riêng đã khớp tên, chỉ cần bỏ lớp chung chồng lên (L2–L4). **ĐẠN** = làm hình đạn bay riêng (L1). **MỚI** = viết hình mới (L6). Phần mô tả là thứ người chơi sẽ thấy.

### Sát thủ (22) — bóng tối + dao găm + máu
| Kỹ năng | Hiệu ứng sẽ có |
|---|---|
| av25 Ảnh Bộ Đoạt Mệnh | GIỮ `sx_reaperstep`: bước lướt để tàn ảnh đen, nhát hái tử thần ở điểm dừng. Bỏ vòng/rune chung. |
| st1 Lướt Bóng | GIỮ `sx_shadowdash`: vệt bóng đen kéo dài dọc quãng lướt. |
| st6 Ảnh Trảm Liên Kích | GIỮ `sx_slashchain`: chuỗi vệt chém bóng nối tiếp theo quãng lướt. |
| st7 Huyết Ảnh Truy Sát | GIỮ `sx_bloodchase`: tàn ảnh đỏ máu lao theo, giọt máu bắn. |
| av42 Huyết Ảnh Liên Hoàn | GIỮ `sx_bloodchain`: dây chuyền các nhát lướt nối bằng sợi máu. |
| av27 Ảnh Độn | GIỮ `sx_smokebomb`: bom khói nổ ở chỗ cũ, người biến mất. |
| st9 Xóa Dấu | GIỮ `sx_erasetrace`: khói quét sạch dấu chân dưới đất. |
| av30 Phi Đao U Ảnh | **ĐẠN** dao găm bóng xoay + vệt ma; GIỮ `sx_ghostdagger` làm bóng đuôi. |
| av37 Mưa Phi Đao Bóng | **ĐẠN** nhiều dao găm; GIỮ `sx_daggerrain` (mưa dao rơi vùng xa). |
| st5 Trăm Nhát Phân Tán | **ĐẠN** loạt dao quạt rộng; GIỮ `sx_hundredcuts`. |
| st8 Phi Tiêu Độc | **ĐẠN** phi tiêu 4 cánh xanh độc xoay; GIỮ `sx_poisonstar` + giọt độc khi trúng. |
| ulSat1 Huyết Ảnh Vạn Đao | **ĐẠN** dao đỏ máu bay dày; GIỮ `sx_bloodblades` (vạn đao quanh người). |
| av32 Ảnh Phân Thân | GIỮ `sx_clonesplit`: tách 2–3 bóng người đứng cạnh. Bỏ bong bóng buff vàng. |
| av35 Thế Thân Bóng Tối | GIỮ `sx_substitute`: bóng/khúc gỗ thế thân tại chỗ, thân thật mờ đi. |
| st4 Ẩn Thân | GIỮ `sx_fadecloak`: áo choàng tối quấn, người mờ dần. |
| av38 Sát Ý Dâng Trào | GIỮ `sx_killaura`: khí sát đỏ + mắt đỏ. Bỏ bong bóng. |
| st3 Cuồng Sát | GIỮ `sx_frenzy`: khí đỏ cuồng loạn, vệt chém ngẫu nhiên quanh người. |
| av40 Bách Ảnh Sát | GIỮ `sx_multistab`: hàng chục nhát đâm nhỏ liên tục. Bỏ vệt chém vàng chung. |
| st10 Tử Huyệt | GIỮ `sx_deathpoint`: nhát đâm điểm + chấm đỏ tử huyệt. |
| st2 Nhát Kép | GIỮ `sx_crossslash`: hai nhát chém chéo hình chữ X. |
| av45 Vạn Ảnh Tuyệt Sát | GIỮ `sx_shadowstorm`: bão bóng người chém vòng quanh. |
| st11 Bóng Đêm Bao Phủ | GIỮ `sx_darkveil`: màn đen phủ vùng đất, tối dần. |

### Cung thủ (23) — mũi tên theo từng loại
| Kỹ năng | Hiệu ứng sẽ có |
|---|---|
| hl1 Tiễn Xuyên Phá | **ĐẠN** mũi tên lửa to, xuyên + vệt lửa; GIỮ `ax_piercearrow`. |
| hl10 Tiễn Xuyên Tâm | **ĐẠN** mũi tên thánh dài như thương; GIỮ `ax_heartarrow` (ghim tim). |
| xa25 Ấn Tâm Tiễn | **ĐẠN** tên thánh, cắm vào để lại ấn hình vòng. |
| hl11 Hỏa Vũ Liên Châu | **ĐẠN** chùm tên lửa quạt; GIỮ `ax_firevolley`. |
| hl2 Tam Tiễn | **ĐẠN** 3 tên thường tỏa quạt. |
| hl9 Xạ Liên Hoàn | **ĐẠN** tên bắn dồn nhịp nhanh. |
| xa37 Liên Châu Ngũ Tiễn | **ĐẠN** 5 tên quạt rộng. |
| hl3 Mắt Ưng | GIỮ `ax_eagleeye`: mắt ưng + tâm ngắm trên đầu. Bỏ bong bóng buff. |
| xa35 Thần Nhãn | GIỮ `ax_divineeye`: con mắt thần sáng + tâm ngắm. |
| hl4 Lùi Né | GIỮ `ax_hopback`: nhảy lùi, vệt gió + lông vũ. |
| xa30 Bước Lùi Liên Xạ | GIỮ `ax_hopshoot`: lùi + bắn nhanh 1 loạt. |
| hl5 Mưa Tên | GIỮ `ax_arrowrain`: mưa tên rơi vùng, cắm xuống đất. Bỏ meteor/arrowZone chung. |
| hl7 Bão Tên Định Mệnh | GIỮ `ax_arrowstorm`: bão tên xoáy tím linh. |
| xa40 Thiên Võng Xạ Kích | GIỮ `ax_skynet`: lưới tên đan trên trời giáng xuống. |
| ulCung2 Thiên Hỏa Mưa Tên | GIỮ `ax_firerain`: mưa tên lửa. Bỏ meteor chung. |
| xa45 Thiên Hỏa Thần Tiễn | GIỮ `ax_fireshaft`: một mũi tên lửa khổng lồ giáng xuống. |
| hl6 Tam Tiễn Truy Kích | **ĐẠN** 3 tên gió tự dẫn hướng (cong theo mục tiêu); GIỮ `ax_homing`. |
| hl8 Tên Băng | **ĐẠN** mũi tên băng lam + khói lạnh; trúng thì vỡ mảnh băng. |
| ulCung1 Tinh Vân Tuyệt Xạ | **ĐẠN** tên sao + dải tinh vân; GIỮ `ax_nebula`. |
| xa27 Tiễn Thần Tốc | **ĐẠN** tên sét rất nhanh, vệt điện. |
| xa32 Tên Phá Giáp | **ĐẠN** tên thép mũi khoan; trúng thì mảnh giáp vỡ. |
| xa38 Bẫy Linh Quang | GIỮ `ax_spirittrap`: bẫy thánh quang trên đất. Bỏ sigil chung. |
| xa42 Tinh Tú Truy Hồn | **ĐẠN** sao băng tự dẫn; GIỮ `ax_starhoming`. |

### Tanker (24) — khiên, thép, đất
| Kỹ năng | Hiệu ứng sẽ có |
|---|---|
| hv25 Khiên Phi Trảm | **ĐẠN** đĩa khiên răng cưa xoay (khớp `t_disc`). |
| hv27 Thuẫn Kích / tk1 Khiên Phá | GIỮ `t_bash` / `t_shieldbreak`: khiên đập, tia va chạm / khiên nứt vỡ. Bỏ vệt chém vàng (L2). |
| hv30 Thuẫn Trận Phản Chấn | GIỮ `t_wall`: hàng khiên tháp dựng lên. Bỏ sigil chung. |
| hv32 Ý Chí Hộ Vệ | GIỮ `t_willguard`: khiên nhỏ xoay quanh người. |
| hv35 Chấn Địa / tk6 Địa Chấn | GIỮ `t_crack` / `t_tremor`: nứt đất, đá trồi, rung màn hình. Bỏ vòng cam. |
| hv37 Khiên Xoáy / tk2 Vòng Thép | GIỮ `t_shieldvortex` / `t_steelring`. |
| hv38 Thành Lũy / tk7 Pháo Đài Bất Khuất / ulTank1 Thành Đồng | GIỮ `t_bastion` / `t_keep` / `t_bronzewall`: tường thành / tháp canh / cổng thành đồng. |
| hv40 Pháo Đài Tiến Quân / tk8 Xung Phong | GIỮ `t_march` / `t_charge`: pháo đài đẩy tới / đầu trâu húc, bụi sau lưng. Vệt lướt đặt theo quãng. |
| hv42 Phản Chấn Địa Long | GIỮ `t_earthdragon`: địa long trồi lên gầm. |
| hv45 Tuyên Chiến | GIỮ `t_banner`: cắm chiến kỳ + sóng hô. **Bỏ** cột sáng/đĩa rune/flash (L4). |
| tk3 Thịnh Nộ | GIỮ `t_fury`: lửa giận + gân nổi. Bỏ bong bóng buff. |
| tk4 Giáp Sắt | GIỮ `t_ironarmor`: mảnh giáp lục giác lắp vào người. |
| tk5 Sóng Thép | GIỮ `t_steelwave`: sóng thép nhọn ập tới. |
| tk9 Tiếng Gầm Uy Hiếp | GIỮ `t_roar`: sóng âm răng cưa từ miệng. |
| tk10 Phản Giáp | GIỮ `t_thorns`: giáp gai bung ra. |
| tk11 Búa Thiên Lôi | GIỮ `t_hammer`: búa khổng lồ + sét giáng. |
| ulTank2 Địa Chấn Thiên Hạ | GIỮ `t_worldquake`: rung mạnh toàn màn hình, đất vỡ. |
| ulTankSuper Thiết Bích Vĩnh Cửu | GIỮ `t_hexdome`: vòm lục giác thép. |

### Kiếm sĩ (23) — mọi hiệu ứng phải có kiếm / kiếm khí
| Kỹ năng | Hiệu ứng sẽ có |
|---|---|
| ks25 Kiếm Khí Hoành Tảo | GIỮ `k_sweep`: nhát quét ngang lưỡi liềm kiếm khí. |
| ks27 Nhất Kiếm Thiên Phong | GIỮ `k_windthrust`: một mũi kiếm xuyên, gió xoáy quanh. |
| ks32 Kiếm Ý Hộ Thân | GIỮ `k_swordintent`: các thanh kiếm lơ lửng xoay quanh người. |
| ks35 Long Ảnh Liên Trảm | GIỮ `k_dragonshadow`: bóng rồng + nhát chém chéo để lại. Bỏ hạt "rồng" chung. |
| ks37 Tam Kiếm Hợp Nhất | GIỮ `k_trisword`: 3 kiếm quy về một nhát đâm. |
| ks38 Kiếm Khí Trường Hà | **ĐẠN** dải kiếm khí xanh uốn như sông (không phải quả cầu); GIỮ `k_riverqi`. |
| ks42 Phong Vân Kiếm Vũ | GIỮ `k_cloudsword`: mây + kiếm múa trong gió. |
| pa1 Trảm Kích Lướt | GIỮ `k_dashslash`: tàn ảnh + nhát chém chéo cuối. |
| pa10 Cuồng Phong Trảm | GIỮ `k_cyclone`: lốc phễu cuốn nhát chém. |
| pa11 Kiếm Khí Tung Hoành | **ĐẠN** kiếm khí chéo dọc/ngang; GIỮ `k_crossqi` (lưới). |
| pa2 Liên Trảm | GIỮ `k_chain`: chuỗi chém nhiều góc. |
| pa3 Cuồng Nộ | GIỮ `k_berserk`: hỏa khí + mắt rực + vết chém. **Bỏ** bong bóng buff. |
| pa4 Khiên Ý Chí | GIỮ `k_willshield`: khiên ánh sáng khắc kiếm. |
| pa5 Thiên Kiếm Giáng | GIỮ `k_heavensword`: kiếm trời khổng lồ trong cột sáng. **Bỏ** vòng cam chung. |
| pa6 Kiếm Vũ Liên Hoàn | GIỮ `k_swordloop`: vòng kiếm khí lồng nhau. |
| pa7 Phá Quân Trảm | GIỮ `k_armybreak`: nhát bổ chéo xé đôi trận địch. |
| pa8 Đâm Xuyên | GIỮ `k_pierce`: mũi kiếm mảnh xuyên + nón xung kích. |
| ulKiem2 Kiếm Vũ Tuyệt Diệt | GIỮ `k_swordbloom`: hoa kiếm nở dưới trăng máu. |
| **ks30 Kiếm Tâm Phản Kích** | **MỚI** `k_mindcounter`: tâm kiếm (vòng ý) nhận đòn → kiếm gạt chéo, tia phản chấn bật ngược. |
| **pa9 Kiếm Phản Kích** | **MỚI** `k_parry`: lưỡi kiếm đỡ ngang, tia lửa thép, nhát chém trả đòn. (Khác ks30, hết trùng.) |
| **ks40 Vạn Kiếm Quy Tông** | **MỚI** `k_tenthousand` (theo mô tả: "kiếm khí chém nhiều hướng trong vùng rộng quanh người", bán kính 240): hàng trăm kiếm nhỏ từ bốn phía bay *quy về* người rồi bung ra thành vòng kiếm khí chém mọi hướng, vòng chém lan đúng 240px. |
| **ulKiem1 Kiếm Trận Hủy Diệt** | **MỚI** `k_swordarray` (theo mô tả: "hai thanh kiếm khổng lồ giáng liên tiếp phía trước", bán kính 170): kiếm trận (vòng kiếm cắm trên đất) hiện trước, rồi **hai** kiếm khổng lồ đâm xuống lần lượt tại 140px và 270px, đúng chỗ và đúng nhịp tính sát thương. (Khác ks40, hết trùng.) |
| **ks45 Chân Kiếm Thức Tỉnh** | **MỚI** `k_trueawaken`: thanh kiếm thật phóng to sau lưng, hào quang kiếm ý, mắt kiếm mở. **Bỏ** cột thánh + đĩa rune + flash toàn màn hình. |

### Tử linh thuật sư (13) — xương, hồn, xích, tử khí
| Kỹ năng | Hiệu ứng sẽ có |
|---|---|
| nl1 Lời Nguyền Tàn Lụi | **ĐẠN** đầu lâu nguyền lục tím; GIỮ `c_witherskull` (làm héo). |
| nl8 Xiềng Xích Âm Hồn | **ĐẠN** sợi xích hồn phóng ra; GIỮ `c_soulchains`. |
| nl10 Hồn Nổ Dây Chuyền | GIỮ `c_soulchainblast`: hồn nổ lan chuyền. |
| nl11 Tử Khí Tràn Ngập | GIỮ `c_deathmist`: sương tử khí phủ đất. |
| nl2 Triệu Hồi Bóng | GIỮ `c_shadowsummon`: bóng người trồi lên từ đất. Bỏ cột sáng chung. |
| nl3 Hút Linh | GIỮ `c_soulsiphon`: dòng hồn bị hút về người. |
| nl4 Đội Quân U Ảnh | GIỮ `c_phantomarmy`: hàng ma binh mờ. |
| nl5 Cổng Âm Giới | GIỮ `c_netherportal`: cổng xoáy tím, tay ma thò ra. |
| nl6 Phân Hồn | GIỮ `c_soulsplit`: hồn tách khỏi thân. |
| nl7 Vuốt Quỷ | GIỮ `c_demonclaw`: vuốt quỷ xé 3 đường. |
| nl9 Hồn Phách Hộ Thể | GIỮ `c_soulward`: hồn xoay quanh người. |
| ulLinh2 U Minh Cuồng Triều | GIỮ `c_ghosttide`: thủy triều linh hồn. **Bỏ** cột + rune + flash chung. |
| ulTuLinhDungHop Tử Linh Dung Hợp | GIỮ `c_soulfusion`; bỏ sigil/pillar/runeDisc chung. |

### Pháp sư (24) — nguyên tố
| Kỹ năng | Hiệu ứng sẽ có |
|---|---|
| ps25 Lôi Xà | **ĐẠN** rắn sét ngoằn ngoèo; GIỮ `c_thundersnake`. |
| tn9 Tia Sét Xuyên | **ĐẠN** tia sét xuyên thẳng; GIỮ `c_piercebolt`. |
| ps27 Hỏa Cầu Nổ / tn8 Hỏa Cầu | **ĐẠN** cầu lửa có đuôi (nổ ở ps27). |
| tn1 Sóng Băng | **ĐẠN** sóng băng lam, mảnh băng. |
| ps30 Hỏa Tường | GIỮ `c_firewall`: tường lửa trên đất. |
| ps32 Băng Phong Trận / tn3 Băng Ngục / tn6 Băng Lưu Bạo | GIỮ `c_icecircle` / `c_iceprison` / `c_iceburst`: trận băng / lồng băng / bão tuyết nổ. Bỏ vòng cam. |
| ps35 Tinh Thạch Hộ Thể / tn4 Khiên Năng Lượng | GIỮ `c_crystalguard` / `c_energyshield`. |
| ps37 Lôi Cầu Xoáy | **MỚI** `c_lightball`: quả cầu sét xoáy bay đến, phóng tia điện xung quanh (đang dùng hình cũ). |
| ps38 Hồi Nguyên / tn2 Hồi Phục | GIỮ `c_restoremoon` / `c_healcross`. Bỏ vòng hồi chung. |
| ps40 Bão Nguyên Tố / ps45 Thiên Địa Hợp Nhất Pháp | GIỮ `c_elemstorm` / `c_heavenearth`. Bỏ flash chung. |
| ps42 Dịch Chuyển Tức Thời / tn10 Dịch Chuyển Nguyên Tố | GIỮ `c_teleport` / `c_elemblink`. Bỏ sigil chung. |
| tn11 Địa Ngục Liệt Hỏa | GIỮ `c_hellfire`: biển lửa dưới đất. Bỏ meteor/sigil chung. |
| tn5 Thiên Thạch / tn7 Hỏa Tinh Bạo Liệt | GIỮ `c_meteor` / `c_emberburst`. Bỏ meteor chung chồng lên. |
| ulPhap1 Lôi Đế Giáng Thế | GIỮ `c_thunderlord`: sét to giáng xuống. Bỏ flash chung. |
| ulPhap2 Băng Hải Phong Thiên | GIỮ `c_frozensea`. |
| ulPhapSuper Cấm Chú Giải Phóng | GIỮ `c_forbidden`; bỏ sigil+pillar chung. |

### Trị liệu sư (22) — thánh quang, hồi phục
| Kỹ năng | Hiệu ứng sẽ có |
|---|---|
| tg27 Thánh Quang Chiếu | GIỮ `dx_lightshaft`: cột sáng chéo từ trời. |
| tl2 Sóng Thánh | **ĐẠN** lưỡi sóng sáng liềm; GIỮ `dx_crescent`. |
| tl30 Quang Tiễn | **ĐẠN** mũi tên ánh sáng; GIỮ `dx_lightarrow`. |
| tl9 Thánh Ấn | **ĐẠN** ấn triện xoay; GIỮ `dx_seal`. |
| tg32 Phước Lành / tl3 Ân Sủng | GIỮ `dx_bless` (mưa tia vàng) / `dx_dove` (bồ câu). Bỏ cột sáng chung. |
| tg37 Thiên Sứ Hộ Tống | GIỮ `dx_angel`: cánh thiên sứ. Bỏ cột chung. |
| tg38 Thánh Dụ | GIỮ `dx_decree`: cuộn sắc lệnh. |
| tg42 Ánh Sáng Phán Xét | GIỮ `dx_judge`: búa ánh sáng giáng pháp trận. |
| tg45 Phục Sinh Ánh Quang / ulTri1 Thánh Quang Hồi Sinh | GIỮ `dx_phoenix` / `dx_phoenix2`: phượng hoàng bay lên. |
| tl1 Chữa Lành | **MỚI** `dx_heal`: vòng thập tự xanh lục + dấu cộng + lá nhỏ bay lên (đang dùng dấu cộng chung). |
| tl10 Thanh Tẩy | GIỮ `dx_purify`: vòng nước quét từ chân lên đầu. |
| tl11 Quang Vũ Tái Sinh | GIỮ `dx_lightrain`: mưa ánh sáng, mầm xanh. |
| tl25 Thánh Vực / tl7 Kết Giới Sinh Mệnh | GIỮ `dx_sanctum` (pháp trận) / `dx_lifedome` (vòm dây leo). |
| tl35 Kết Giới Thánh Quang / tl4 Khiên Ánh Sáng | GIỮ `dx_hexdome` / `dx_lightshield`. Bỏ cột chung. |
| tl40 Bình Minh Tái Sinh | GIỮ `dx_sunrise`: mặt trời mọc. |
| tl5 Phép Thánh Toàn Trị | GIỮ `dx_allheal`: thập tự lớn bay lên. |
| tl6 Thánh Quang Hộ Thể | GIỮ `dx_aura`: hai vòng sáng xoay. Bỏ cột chung. |
| tl8 Giọt Thánh | GIỮ `dx_holydrop`: giọt nước thánh rơi. |

### Triệu hồi sư (12) — linh hồn, linh thú
| Kỹ năng | Hiệu ứng sẽ có |
|---|---|
| th1 Linh Tiễn | **ĐẠN** tia quỷ hỏa lượn sóng; GIỮ `dx_wisp`. |
| th8 Linh Điểu Truy Kích | **ĐẠN** chim linh hồn bay dẫn hướng; GIỮ `dx_spiritbird`. |
| th10 Linh Long Xung | **ĐẠN** rồng phương Đông uốn lượn; GIỮ `dx_dragon`. |
| th11 Vạn Linh Quy Tụ / ulLinh1 Vạn Linh Bùng Nổ | GIỮ `dx_gather` (hồn xoáy vào) / `dx_soulburst` (nổ ra, đầu lâu). |
| th2 Linh Thể Hộ Vệ | GIỮ `dx_guardian`: hiệp sĩ hồn cầm khiên. |
| th3 Nổ Linh Lực | GIỮ `dx_spiritblast`: cầu linh lực phình rồi nổ. |
| th4 Hiệu Lệnh Triệu Hồi | GIỮ `dx_banner`: cờ lệnh. |
| th5 Triệu Hồi Linh Thú | GIỮ `dx_beast`: pháp trận + bóng sói. Bỏ cột chung. |
| th6 Tiếng Gọi Linh Hồn | GIỮ `dx_soulcall`. |
| th7 Linh Giới Hộ Thân | GIỮ `dx_soulorbit`. |
| th9 Cộng Hưởng Linh Thú | GIỮ `dx_resonance`: dấu chân thú khổng lồ. |

### Chung (4) và Toàn năng (8)
| Kỹ năng | Hiệu ứng sẽ có |
|---|---|
| ulChung1 Thiên Địa Chấn Động | **MỚI** `dx_heavenquake`: trời đất rung, vết nứt lớn, đá trên trời rơi xuống (hiện dùng `quake` của tanker). |
| ulChung2 Ý Chí Bất Diệt | GIỮ `dx_will`; bỏ cột/rune/flash chung. |
| ulChung3 Hư Không Tuyệt Trảm | GIỮ `dx_voidslash`: vết nứt hư không. |
| ulSinhTu Sinh Tử Đồng Quy | GIỮ `dx_taiji`: thái cực đồ. |
| ulToanNangSuper Vạn Pháp Quy Nhất | GIỮ `dx_allone`. |
| vn1 Thức Tỉnh Tối Thượng | GIỮ `dx_awaken`; bỏ cột/rune/flash chung (đã có cột riêng). |
| vn2 Hợp Nhất Nguyên Tố / vn3 Dòng Chảy / vn4 Thế Cân Bằng / vn5 Tinh Lực / vn6 Thủ Ấn / vn7 Trảm Hợp Nhất | GIỮ `dx_elemfuse` / `dx_flow` / `dx_balance` / `dx_vigor` / `dx_palm` (**ĐẠN** bàn tay ấn) / `dx_tripleslash`. Bỏ đĩa rune chung (vn3, vn4). |

## 3b. Đối chiếu với MÔ TẢ kỹ năng (`gamedata.json` → `SKILLS[id].desc`, `type`, `range/radius/count/hits/duration/slow/freeze/knock/heal`)

Đọc mô tả cho thấy hai loại vấn đề nữa: (A) một số hình riêng **trái với mô tả**; (B) hiệu ứng **không khớp cơ chế thật** (số lượng, vị trí, nhịp, thời gian). Phần này **ghi đè** bảng ở mục 3 khi có mâu thuẫn.

### A. Hình riêng đang/dự kiến trái mô tả → sửa
| Kỹ năng | Mô tả thật | Hiện tại / dự kiến cũ | Sửa thành |
|---|---|---|---|
| tg27 Thánh Quang Chiếu | *projectile* "tia sáng thánh xuyên qua kẻ địch", tầm 520, xuyên | `dx_lightshaft` = cột sáng rọi từ trời xuống chỗ đứng | Tia sáng thánh bắn ngang xuyên qua hàng quái (đạn riêng + vệt dài), chỉ nổ sao nhỏ ở cuối tầm. |
| nl6 Phân Hồn | *shadow_command* "xung kích bóng tối, đội bóng ma tập trung tấn công mục tiêu gần nhất" | `c_soulsplit` = hồn tách khỏi thân | Sóng xung kích tối lan r=240 từ người, các bóng ma lao thành vệt về **mục tiêu gần nhất**, đánh dấu mục tiêu bằng vòng tím. |
| ps38 Hồi Nguyên | "Hồi **năng lượng** lớn, hồi thêm chút máu" | `c_restoremoon` (vầng trăng, thiên về hồi máu) | Hạt **xanh dương (mana)** từ trời/đất chảy vào người là chính, chỉ vài hạt xanh lục (máu). |
| xa45 Thiên Hỏa Thần Tiễn | arrow_rain 24 tên, rộng 520 — "mưa tên lửa phủ một vùng rộng" | dự kiến "một mũi tên lửa khổng lồ" | Mưa tên lửa 24 mũi rộng 520px, kèm một "thần tiễn" lớn nổ ở tâm. Khác ulCung2 (600px, đất bốc cháy kéo dài). |
| hl6 Tam Tiễn Truy Kích | "ba mũi tên xuyên giáp **theo đường thẳng**", tầm 620, xuyên | dự kiến tên tự dẫn cong | 3 mũi tên song song bay **thẳng**, đầu khoan xuyên giáp, vệt gió đuổi theo sau (giữ ý "truy kích" bằng vệt, không bẻ quỹ đạo vì đòn tính thẳng). |
| xa42 Tinh Tú Truy Hồn | 5 tên sao, xuyên mọi quái, tầm 700 | dự kiến sao băng tự dẫn | 5 mũi tên sao bay thẳng quạt hẹp, rải bụi sao, để lại vệt hồn mờ. |
| ks37 Tam Kiếm Hợp Nhất | "Ba nhát liên hoàn, **nhát cuối nổ kiếm khí**" (melee 3 hits) | `k_trisword` = 3 kiếm quy về một nhát đâm | 3 nhát chém liền (1–2 nhỏ, nhát 3 lớn) và nhát cuối nổ làn kiếm khí. |
| ks25 Kiếm Khí Hoành Tảo | 4 hits, "nhát cuối mạnh hơn" | quét 1 nhát | 3 đường quét + nhát thứ 4 to hơn, tỏa kiếm khí. |
| pa7 Phá Quân Trảm | 4 nhát, "kết thúc bằng đòn **phá giáp**" | 1 nhát bổ chéo | 3 nhát + nhát cuối bổ chéo làm vỡ mảnh giáp địch. |
| tk5 Sóng Thép | "Đập **kiếm** xuống đất, sóng thép nổ diện rộng" (sword_fall r=220 tại ~140px) | sóng thép chạy về phía trước | Kiếm thép to đập xuống tại 140px, sóng thép nổ bung hình tròn r=220. |
| ulChung3 Hư Không Tuyệt Trảm | "**hai** nhát chém khổng lồ đánh xuống" (count 2) | 1 vết nứt | 2 vết nứt hư không xé xuống lần lượt tại 140px và 270px. |
| st9 Xóa Dấu | lùi 200px, miễn sát thương, "tung **2 phi tiêu** trả đòn" | khói/xóa dấu chân | Khói + 2 phi tiêu bắn ngược về trước lúc lùi. |
| av27 Ảnh Độn | lùi 230px, miễn thương, "**3 ảnh phân thân** bắn trả" | bom khói | Khói + 3 bóng phân thân bắn trả. |
| ps42 / tn10 / hl4 / xa30 | lùi + để lại **4 / 3 / 1 / 4** loạt đạn (phép / nguyên tố / tên / tên) | chỉ vòng dịch chuyển | Số loạt đạn bắn ra đúng bằng `count`, hướng về phía trước lúc lùi. |
| ulChung1 Thiên Địa Chấn Động | "Giải phóng nguyên lực, nổ tung mọi thứ xung quanh" r=240 (chung/arcane) | quake của tanker | Nổ nguyên lực: sóng xung kích trời + đất, vết nứt, đá, bán kính 240 **quanh người**. (Không dùng hình búa/địa chấn của tanker.) |
| ulToanNangSuper Vạn Pháp Quy Nhất | "tung **cùng lúc cả ba** tuyệt kỹ chung (Địa Chấn + Hư Không Trảm + Ý Chí Bất Diệt) + một vụ nổ" | 6 viên ngọc xoáy | Ghép 3 hình: chấn động + 2 vết hư không + lửa ý chí, kết thúc vụ nổ cầu vồng. |
| ulPhapSuper Cấm Chú Giải Phóng | "đốt sạch năng lượng thành một vụ nổ", bán kính 340 | `c_forbidden` | Dồn mana (xanh) thành cầu co lại ở người → nổ r=340, độ lớn theo lượng MP đã đốt. |
| ulSinhTu Sinh Tử Đồng Quy | *execute*: hạ gục **mục tiêu** | vẽ tại chỗ người | Vẽ thái cực **trên mục tiêu**, có sợi nối từ người; mục tiêu tan thành khói trắng-đen. |

### B. Đồng bộ hiệu ứng với cơ chế thật (áp cho cả nhóm)
1. **Số lượng = tham số**: số nhát = `hits` (av40 7, pa6 6, ulKiem2 9, nl7 3…); số vật bay = `count` (av37 7 dao, st5 5, ulSat1 9, hl11 7 tên, xa37 5, xa42 5, th10 3 rồng, th8 2 chim…); số tên mưa = `arrows` (12/16/18/24); số đợt rơi = `count` (ps40 3, ps45 5, tn11 3, ulPhap1 4, nl5 2, th11 2, ulLinh1 2, ulKiem1 2).
2. **Vị trí & nhịp rơi khớp vùng sát thương**: kiếm rơi ở 140/270/400px, trễ 0,3s + 0,22s mỗi đợt; thiên thạch ở 170px + 110px mỗi đợt, trễ 0,6s + 0,42s; mưa tên tâm tại `width/2+30` trước mặt. Hiện hiệu ứng vẽ ở vị trí cố định nên nổ lệch chỗ mất máu.
3. **Kích thước = bán kính/tầm thật**: dùng `radius`, `range`, `distance`, `width` của kỹ năng để chỉnh cỡ vòng, vệt lướt, vệt đạn (vd. av25 lướt 220px thì tàn ảnh dài đúng 220px).
4. **Buff / hộ thể kéo dài**: kỹ năng có `duration` 3–12s (70s với Thiết Bích) → hiệu ứng nhỏ **duy trì trên người suốt thời gian**, có hiệu ứng tan khi hết (hiện chỉ phát ~1s rồi mất).
   - Buff **hồi máu liên tục** (hv32, tg32, tl10, tl3): thêm xung dấu cộng xanh lục theo nhịp.
   - **Manashield** (ps35, tn4, tl4, tl35, nl9, th7): khiên tông xanh mana, **gợn sóng mỗi khi đỡ đòn**.
   - Buff cho **bóng ma / linh thú** (nl4, nl5, th4, th9): aura phát trên chính bóng ma/linh thú đang đi theo, không chỉ trên người.
   - ulTankSuper (70s miễn thương nhưng **không gây sát thương**): vòm thép xám lạnh + biểu tượng "kiếm bị khóa", khác hẳn tanker thường.
5. **Trạng thái trên quái**: `slow` → xích/bóng nặng dưới chân theo hệ (tối/băng/độc…); `freeze` → khối băng bọc quái (ps32, tn3, tn6, ulPhap2, vn2); `knock` → bụi + vệt đẩy lùi (hv27, tk1, tk8, hv40, ks42); xa32 → ký hiệu giáp nứt; st10 (gấp đôi khi bị chậm) → chấm đỏ lóe nếu mục tiêu đang chậm.
6. **Kỹ năng vừa gây sát thương vừa hồi** (nl3, nl11, tl5, tl7, tl40, vn2, th11): thêm dòng hạt từ quái bay về người (hút sinh lực) hoặc xung xanh lục. Kỹ năng hồi cả máu lẫn MP (tg45, tl11, tl25, tl6, ulTri1, vn5): hạt **xanh lục + xanh dương**.
7. **Toggle triệu hồi** (nl2, th5): hiệu ứng *bật* (trồi lên) và *tắt* (tan biến) khác nhau; nl2 chỉ ẩn bóng, không phải triệu mới.
8. **Chain / lan**: nl10 mỗi quái trúng nổ lan sang quái cạnh → vẽ tia nối từng vụ nổ; ps37 / tn11 / ulPhap1 nổ lan quanh điểm rơi (`chainRadius 170`).
9. **Mô tả có chữ "xuyên"** (`pierce`): đạn không biến mất khi trúng, chỉ nổ tia nhỏ tại từng quái; đạn không xuyên (ps27, tn8, tl9, hl8) thì nổ/vỡ tại quái đầu tiên.

### C. Mâu thuẫn trùng tên cần phân biệt rõ (cùng nhóm, mô tả gần giống)
| Cặp | Phân biệt bằng |
|---|---|
| ks30 (5s, phản 60%, buff công + tốc) / pa9 (3s, phản 80%, "chém trả") | ks30: vòng kiếm tâm tĩnh, hào quang kéo dài 5s; pa9: thế đỡ ngắn 3s, mỗi lần bị đánh **chém trả** một nhát. |
| tk11 Búa Thiên Lôi (r210) / tk5 Sóng Thép (r220) / pa5 Thiên Kiếm Giáng (r180) | búa + sét / kiếm thép + sóng thép / kiếm trời khổng lồ + cột sáng. |
| hv35 / tk6 / hv42 / ulTank2 / tk9 | nứt đất 220 / rung sàn 220 / địa long 280 / rung cả chiến trường 300 + rung camera / sóng âm gầm 230. |
| hl5 / hl7 / xa40 / xa45 / ulCung2 | mưa tên thường 360 / bão tên 430 / lưới tên 420 / mưa tên lửa 520 / đất cháy 600. |
| tl6 / tl25 / tl11 / tg38 / tl8 / tl1 | hồi 30/50/60/60/15/35%: hào quang xoay / pháp trận / mưa sáng / sắc lệnh / giọt nhỏ / thập tự xanh — cỡ hiệu ứng tăng theo % hồi. |
| vn3 Dòng Chảy / vn4 Thế Cân Bằng | dòng năng lượng chảy quanh người / cán cân, khác tông màu rõ rệt. |

## 3c. Phạm vi & mục tiêu: hiệu ứng rơi ở đâu?

Hiện tại: hiệu ứng vẽ ở **một chỗ cố định** (quanh người hoặc 140px trước mặt), **không biết quái ở đâu**. Sát thương thì tính riêng theo hình vùng (`_strike_shape` → `_shape_hits`: vòng tròn tâm người/điểm rơi, hoặc hộp chữ nhật). Nên có thể thấy kiếm rơi chỗ không có quái, còn quái bị trúng thì không có gì xảy ra trên người.

**Đề xuất: mỗi kỹ năng vùng có 2 tầng hiệu ứng**
1. **Tầng vùng** (luôn có, kể cả khi không có quái): vẽ đúng hình và đúng kích thước vùng sát thương (`radius`, `range`, `width`) để người chơi thấy tầm đánh. Ví dụ Vạn Kiếm Quy Tông: kiếm bay quy về người rồi vòng kiếm khí tỏa đúng 240px.
2. **Tầng mục tiêu** (theo từng quái bị trúng thật): `_strike_shape` đã duyệt từng quái trúng, chỉ cần phát một tín hiệu `(skill_id, vị trí quái)` cho `SkillFx`. Mỗi quái trúng nhận hiệu ứng riêng của kỹ năng, **đúng vào người nó**.

**Ví dụ Vạn Kiếm Quy Tông, vùng 240px có 4 quái:** vòng kiếm khí tỏa ra từ người; 4 quái trúng đòn thì **mỗi con một cụm nhát kiếm chém xuống** (vệt chém nhiều hướng, tia kiếm khí xuyên qua người nó, tia lửa thép). Quái đứng ngoài 240px không có gì. Nếu vùng trống không quái: chỉ có tầng vùng.

**Quy tắc theo loại kỹ năng**
| Loại | Tầng vùng | Tầng mục tiêu |
|---|---|---|
| `aoe` quanh người (ks40, ks42, pa10, hv35…) | vòng/sóng đúng `radius` tâm người | hiệu ứng riêng trên **từng quái trúng** |
| `sword_fall` / `meteor` (pa5, ulKiem1, tn5, tn11…) | vật rơi đúng tâm từng điểm rơi, đúng nhịp | quái trong vòng nổ nhận vụ nổ/vết chém nhỏ; điểm rơi nào không có quái vẫn nổ ở tâm |
| `arrow_rain` | vùng mưa đúng `width` | mỗi mũi tên rơi đúng chỗ tính sát thương; mũi cắm trúng quái thì có tia máu/lửa |
| `melee` nhiều nhát (ks25, pa6…) | vệt chém đúng `range` trước mặt | mỗi nhát trúng con nào thì vệt chém dính con đó; nhát cuối có hiệu ứng lớn |
| `projectile` (xuyên) | đạn bay đúng `range` | nổ nhỏ **tại từng quái bị xuyên qua**; đạn không xuyên nổ ở quái đầu tiên |
| `dash` | vệt lướt đúng `distance` | vệt chém dính các quái trên đường lướt |
| `buff` / `guard` | không có vùng | không có (hiệu ứng trên người) |

**Giới hạn hiệu năng:** tối đa **8 quái** được vẽ hiệu ứng riêng mỗi lần tung (con thứ 9 trở đi chỉ có tia lửa nhỏ), giảm còn 4 khi `quality_low`; dùng pool node hiện có.

## 4. Khối lượng

**Nguyên tắc (cập nhật): mỗi kỹ năng có hình vẽ riêng của nó, không dùng chung.** 167 kỹ năng đã có hình riêng từ trước, nhưng chưa ai duyệt bằng mắt nên không đảm bảo đẹp/đúng. Vì vậy:

1. **Bước 0 – Cảnh xem thử** (`FxGallery`): phát từng kỹ năng, chụp ảnh các mốc thời gian, lưu vào `docs/fx_review/<id>.png`.
2. **Bước 1 – Tắt lớp chung L2/L3/L4** cho mọi kỹ năng (sửa chung, nhanh).
3. **Bước 2 – Vẽ lại từng kỹ năng theo nhóm**, mỗi kỹ năng một hàm vẽ riêng + một hình đạn riêng (nếu bắn đạn, ~37 cái, mỗi cái một hình, không còn "bảng dùng chung"). Thứ tự: nhóm bị lệch nhiều nhất trước (mục 3b-A, ~30 kỹ năng) → kiếm sĩ → cung thủ → sát thủ → tanker → pháp sư → trị liệu → tử linh → triệu hồi → chung/toàn năng.
4. **Bước 3 – Duyệt theo nhóm**: sau mỗi nhóm chụp lại, bạn xem rồi mới sang nhóm tiếp. Kỹ năng nào trông không khớp tên/mô tả thì vẽ lại.
5. 8 kỹ năng đang dùng hình cũ (ks30, pa9, ks40, ulKiem1, ks45, ulChung1, tl1, ps37) vẽ mới hoàn toàn.
6. Cần cài Godot vào máy để chạy cảnh xem thử (lần rà này chưa có).

## 5. Quyết định đã chốt (2026-11-26) và kế hoạch thực hiện

### Đã chốt
1. Mỗi kỹ năng có hình vẽ riêng và hình đạn riêng; không dùng bảng hình chung.
2. Trận rune theo class (chi tiết bên dưới); vòng cam/bong bóng chung của `World.gd` bỏ cho mọi class.
3. Hai tầng hiệu ứng vùng (mục 3c): tầng vùng đúng bán kính + tầng mục tiêu trên từng quái trúng; tối đa 8 quái có hiệu ứng riêng (4 khi `quality_low`).
4. Hiệu ứng theo mô tả (mục 3b): số lượng/vị trí/nhịp/thời lượng khớp tham số kỹ năng; buff kéo dài suốt `duration`.

### Các giai đoạn
| GĐ | Việc | Kết quả kiểm |
|---|---|---|
| 0 | Cài Godot; dựng cảnh xem thử `FxGallery` (175 nút, chụp ảnh mốc thời gian vào `docs/fx_review/`) | ảnh hiện trạng |
| 1 | Sửa lớp chung: tắt L2/L3/L4 theo quy tắc rune; thêm cờ "có hình riêng" | chụp lại vài kỹ năng mỗi class |
| 2 | Hạ tầng: tín hiệu (skill_id, vị trí quái) từ `_strike_shape` → `SkillFx.play_hit`; đạn riêng (`Proj` nhận hình theo id); buff kéo dài + trạng thái trên quái; màu hit theo hệ | thử trong cảnh xem thử với 0/1/4/10 quái |
| 3 | Vẽ lại từng kỹ năng theo nhóm, **duyệt ảnh từng nhóm** rồi mới sang nhóm sau. Thứ tự: mục 3b-A (~30 kỹ năng lệch mô tả) → kiếm sĩ (gồm 5 kỹ năng vẽ mới) → cung thủ → sát thủ → tanker → pháp sư (gồm ps37) → trị liệu (gồm tl1) → tử linh → triệu hồi → chung/toàn năng (gồm ulChung1) | ảnh từng nhóm |
| 4 | Rà cuối: hiệu năng (FPS khi 10 quái + kỹ năng vùng), `quality_low`, không lỗi khi thiếu file | báo cáo cuối |

Lưu ý: `Data.gd` và `GamePanels.gd` đang có sửa đổi chưa commit; kế hoạch không chạm hai file đó.

### Quy tắc trận rune (đã chốt)
1. **Trận rune dưới chân — theo class**:
   - **Giữ** (là một phần của bộ hình, vẽ riêng từng kỹ năng, không dùng rune chung): pháp sư, trị liệu sư, tử linh thuật sư, triệu hồi sư, chung/toàn năng — nhóm phép thuật.
   - **Chỉ giữ ở kỹ năng thật sự là trận/vùng/triệu hồi/hộ thể trên đất**: tanker (thuẫn trận, thành lũy, địa chấn), cung thủ (bẫy Linh Quang, lưới tên), sát thủ (Bóng Đêm Bao Phủ, Xóa Dấu).
   - **Bỏ**: kiếm sĩ và các đòn đánh/lướt/bắn của sát thủ, cung thủ, tanker (không ai niệm trận khi vung kiếm hay bắn tên). Ngoại lệ: Kiếm Trận Hủy Diệt (ulKiem1) là trận kiếm thật.
   - Vòng cam/bong bóng chung của `World.gd` vẫn bỏ cho mọi class.

extends RefCounted
## Hub các panel game (port từ web public/js/ui/panels/*.js). Bố cục hai cột (danh sách + chi tiết) cho điện thoại ngang.
## Mọi thao tác gọi Net.action(type, params); luật chơi ở server. host = MobileHUD.
## Mỗi panel nằm ở src/ui/panels/Panel*.gd (hàm build_<tab>); hub giữ trạng thái dùng chung và điều phối theo tên tab.

const PanelAwaken := preload("res://src/ui/panels/PanelAwaken.gd")
const T := preload("res://src/ui/UITheme.gd")
const PanelBag := preload("res://src/ui/panels/PanelBag.gd")
const PanelEquip := preload("res://src/ui/panels/PanelEquip.gd")
const PanelPets := preload("res://src/ui/panels/PanelPets.gd")
const PanelQuest := preload("res://src/ui/panels/PanelQuest.gd")
const PanelShop := preload("res://src/ui/panels/PanelShop.gd")
const PanelSkills := preload("res://src/ui/panels/PanelSkills.gd")
const PanelSocial := preload("res://src/ui/panels/PanelSocial.gd")
const PanelSystem := preload("res://src/ui/panels/PanelSystem.gd")
const PanelWorld := preload("res://src/ui/panels/PanelWorld.gd")

# Trạng thái UI dùng chung giữa các panel (trạng thái riêng nằm trong từng module)
var selected_where := ""
var selected_key := ""
var confirm_drop := ""
var confirm_buy := ""
var equip_detail := false
var npc_id := ""
var ctx_extra: Dictionary = {}

var host: Object = null
var pets: Variant = null   # PanelPets: giữ tham chiếu để công cụ test chọn thú (pet_sel)
var _modules: Array = []

func _init(_host: Object) -> void:
	host = _host
	_modules = [PanelAwaken.new(self), PanelBag.new(self), PanelEquip.new(self), PanelPets.new(self), PanelQuest.new(self), PanelShop.new(self), PanelSkills.new(self), PanelSocial.new(self), PanelSystem.new(self), PanelWorld.new(self)]
	for m in _modules:
		if m is PanelPets: pets = m

func p() -> Dictionary:
	return Game.player

func act(type: String, params: Dictionary = {}, silent: bool = true) -> void:
	if type == "use":
		# Bình thuốc: server cộng vào máu/MP tức thời của client (như web), không phải giá trị lưu cũ
		params = params.duplicate()
		params["hp"] = Game.hp
		params["mp"] = Game.mp
	Net.action(type, params)
	if not silent and host: host.toast("Đang xử lý…")

func refresh() -> void:
	if host and host.has_method("refresh_panel"): host.refresh_panel()

func _select(where: String, key: String) -> void:
	selected_where = where; selected_key = key
	confirm_drop = ""; confirm_buy = ""; equip_detail = false; refresh()

func _deselect() -> void:
	selected_where = ""; selected_key = ""; confirm_drop = ""; confirm_buy = ""; equip_detail = false; refresh()

## Dựng panel theo tên tab: tìm module có hàm build_<tab>.
func build(tab: String, extra: Dictionary = {}) -> Control:
	ctx_extra = extra.duplicate()
	if tab.is_empty(): return T.label("Chọn một mục.", T.FS_M, T.C_MUTED)
	var fn_name := "build_" + tab
	for m in _modules:
		if m.has_method(fn_name):
			var node: Variant = m.call(fn_name)
			return node if node is Control else T.label("Lỗi panel: " + tab, T.FS_M, T.C_RED)
	return T.label("Chưa có panel: " + tab, T.FS_M, T.C_RED)

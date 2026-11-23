extends Node
## Trạng thái xã hội: đội nhóm, giao dịch trực tiếp, danh sách khu, chợ người chơi.
## Nhận gói từ Socket (qua World) và sự kiện `market` từ server; panel/HUD đọc từ đây.

signal changed(kind: String)             # "party" | "trade" | "channels" | "market" | "nearby"
signal invited(kind: String, from: Dictionary)   # lời mời đội / giao dịch
signal trade_ended(reason: String, done: bool)

var party: Dictionary = {}               # {id, leader, members:[{id,name,lv,sc,hp,map,on,dead}]}
var trade: Dictionary = {}               # {id, lockAt, me:{items,gold,locked}, them:{id,name,lv,items,gold,locked}}
var channels: Dictionary = {}            # {map, cur, cap, max, list:[[n,count],...]}
var browse: Dictionary = {}              # kết quả market_browse
var mine: Dictionary = {}                # kết quả market_mine
var nearby: Dictionary = {}              # id -> {name, lv, sc} người chơi cùng map (World cập nhật)

func in_party() -> bool:
	return int(party.get("id", 0)) > 0

func in_trade() -> bool:
	return int(trade.get("id", 0)) > 0

func on_message(m: Dictionary) -> void:
	match str(m.get("t", "")):
		"party":
			party = m if int(m.get("id", 0)) > 0 else {}
			changed.emit("party")
		"party_inv": invited.emit("party", m.get("from", {}))
		"trade_inv": invited.emit("trade", m.get("from", {}))
		"trade":
			trade = m
			changed.emit("trade")
		"trade_end":
			trade = {}
			trade_ended.emit(str(m.get("reason", "")), m.get("done", null) != null)
			changed.emit("trade")
		"chlist":
			channels = m
			changed.emit("channels")

func on_market(ev: Dictionary) -> void:
	match str(ev.get("kind", "")):
		"browse": browse = ev
		"mine": mine = ev
	changed.emit("market")

func clear() -> void:
	party = {}; trade = {}; channels = {}; browse = {}; mine = {}; nearby = {}

extends Node
## Status pemain, flag cerita, hubungan, inventaris, dan tugas kuliah.

var player_name: String = "Dimas"
var uang: int = 650000
var energi: int = 90
var kenyang: int = 70
var mood: int = 60
var utang: int = 0
var flags: Dictionary = {}          # String -> bool
var timed_flags: Dictionary = {}    # String -> hari terakhir berlaku
var rel: Dictionary = {}            # npc -> 0..10
var inv: Dictionary = {}            # item -> jumlah
var tugas: Dictionary = {}          # id -> {progress, dicetak, dikumpul, nilai}
var counters: Dictionary = {}
var news_log: Array = []
var talk_count: Dictionary = {}
var ui_open: bool = false
var lokasi: String = "kos_room"


func _ready() -> void:
	reset()


func reset() -> void:
	player_name = "Dimas"
	uang = GameData.START_UANG
	energi = 90
	kenyang = 70
	mood = 60
	utang = 0
	flags = {}
	timed_flags = {}
	counters = {"hadir": 0, "proyek": 0, "listrik": GameData.LISTRIK_AWAL}
	news_log = []
	talk_count = {}
	ui_open = false
	lokasi = "kos_room"
	rel = {"tati": 1, "asep": 1, "rani": 1, "fikri": 0, "darto": 0, "mira": 0, "rw": 0, "yoga": 0}
	inv = {"mi_instan": 2, "kopi_sachet": 2, "deterjen": 0, "paket": 0, "salinan": 0}
	tugas = {}
	for t in GameData.TUGAS:
		tugas[t["id"]] = {"progress": 0, "dicetak": false, "dikumpul": false, "nilai": -1}


# ---------- flag ----------
func has_flag(f: String) -> bool:
	if flags.get(f, false):
		return true
	if timed_flags.has(f):
		return int(timed_flags[f]) >= TimeManager.day
	return false


func set_flag(f: String) -> void:
	flags[f] = true


func flag_hari(nama: String) -> bool:
	return has_flag(nama + "_d" + str(TimeManager.day))


func set_flag_hari(nama: String) -> void:
	flags[nama + "_d" + str(TimeManager.day)] = true


func relasi(npc: String) -> int:
	return int(rel.get(npc, 0))


func jumlah_inv(item: String) -> int:
	return int(inv.get(item, 0))


func count_testimoni() -> int:
	var n: int = 0
	for k in flags.keys():
		if str(k).begins_with("testimoni_") and flags[k]:
			n += 1
	return n


# ---------- efek ----------
const WARNA_PLUS := Color("#9be37a")
const WARNA_MINUS := Color("#ff9a7a")
const WARNA_MOOD := Color("#f08ab0")
const WARNA_KENYANG := Color("#f0b860")
const WARNA_ENERGI := Color("#7fd7ff")


func _pop(pops: Array, teks: String, warna: Color) -> void:
	pops.append([teks, warna])


## Menerapkan efek. Perubahan stat ditampilkan sebagai teks melayang di atas pemain
## (hanya selisih yang benar-benar terjadi setelah dibatasi 0..100). silent = tanpa teks.
func apply_effects(eff: Dictionary, silent: bool = false) -> void:
	var pops: Array = []
	for k in eff.keys():
		var v: Variant = eff[k]
		match k:
			"uang":
				var n1: int = int(v)
				uang += n1
				if n1 != 0:
					_pop(pops, ("+" if n1 > 0 else "-") + GameData.rp(absi(n1)), WARNA_PLUS if n1 > 0 else WARNA_MINUS)
			"energi":
				var d2: int = clampi(energi + int(v), 0, 100) - energi
				energi += d2
				if d2 != 0:
					_pop(pops, "Energi %+d" % d2, WARNA_ENERGI if d2 > 0 else WARNA_MINUS)
			"kenyang":
				var d3: int = clampi(kenyang + int(v), 0, 100) - kenyang
				kenyang += d3
				if d3 != 0:
					_pop(pops, "Kenyang %+d" % d3, WARNA_KENYANG if d3 > 0 else WARNA_MINUS)
			"mood":
				var d4: int = clampi(mood + int(v), 0, 100) - mood
				mood += d4
				if d4 != 0:
					_pop(pops, "Mood %+d" % d4, WARNA_MOOD if d4 > 0 else WARNA_MINUS)
			"utang":
				utang = maxi(0, utang + int(v))
			"waktu":
				TimeManager.advance(int(v))
			"flag":
				if v is Array:
					for f in v:
						flags[str(f)] = true
				else:
					flags[str(v)] = true
			"flag_hari":
				set_flag_hari(str(v))
			"timed":
				for f in v.keys():
					timed_flags[f] = int(v[f])
			"rel":
				for n in v.keys():
					var d: int = int(v[n])
					var lama: int = relasi(n)
					rel[n] = clampi(lama + d, 0, 10)
					if int(rel[n]) > lama and GameData.NPC.has(n):
						_pop(pops, "Lebih akrab: %s" % GameData.NPC[n]["nama"], WARNA_MOOD)
			"inv":
				for it in v.keys():
					inv[it] = maxi(0, jumlah_inv(it) + int(v[it]))
			"tugas":
				for id in v.keys():
					tugas[id]["progress"] = clampi(int(tugas[id]["progress"]) + int(v[id]), 0, 100)
			"counter":
				for c in v.keys():
					counters[c] = int(counters.get(c, 0)) + int(v[c])
	EventBus.stats_changed.emit()
	if not silent:
		for p in pops:
			EventBus.popup.emit(str(p[0]), p[1])


# ---------- simpan / muat ----------
func to_dict() -> Dictionary:
	return {
		"nama": player_name, "uang": uang, "energi": energi, "kenyang": kenyang,
		"mood": mood, "utang": utang, "flags": flags, "timed": timed_flags,
		"rel": rel, "inv": inv, "tugas": tugas, "counters": counters,
		"log": news_log, "talk": talk_count,
	}


func from_dict(d: Dictionary) -> void:
	reset()
	player_name = str(d.get("nama", "Dimas"))
	uang = int(d.get("uang", 0))
	energi = int(d.get("energi", 80))
	kenyang = int(d.get("kenyang", 60))
	mood = int(d.get("mood", 60))
	utang = int(d.get("utang", 0))
	flags = d.get("flags", {})
	timed_flags = {}
	for k in d.get("timed", {}).keys():
		timed_flags[k] = int(d["timed"][k])
	for k in d.get("rel", {}).keys():
		rel[k] = int(d["rel"][k])
	for k in d.get("inv", {}).keys():
		inv[k] = int(d["inv"][k])
	for k in d.get("tugas", {}).keys():
		var t: Dictionary = d["tugas"][k]
		tugas[k] = {"progress": int(t["progress"]), "dicetak": bool(t["dicetak"]),
			"dikumpul": bool(t["dikumpul"]), "nilai": int(t["nilai"])}
	for k in d.get("counters", {}).keys():
		counters[k] = int(d["counters"][k])
	news_log = d.get("log", [])
	for k in d.get("talk", {}).keys():
		talk_count[k] = int(d["talk"][k])

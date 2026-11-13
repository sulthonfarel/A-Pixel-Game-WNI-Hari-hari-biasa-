extends Node
## Menjalankan event harian (berita, harga, rumor) dan menyediakan komentar tiap tokoh.


func run_day(day: int) -> Array:
	var hari_ini: Array = []
	for e in GameData.EVENTS:
		if int(e["day"]) == day:
			_apply(e)
			hari_ini.append(e)
	return hari_ini


func _apply(e: Dictionary) -> void:
	var eff: Dictionary = e.get("eff", {})
	Economy.apply_event(eff)
	var sisa: Dictionary = eff.duplicate()
	sisa.erase("harga")
	sisa.erase("habis")
	GameState.apply_effects(sisa, true)
	GameState.news_log.append(e["id"])


## Komentar terbaru dari seorang tokoh; idx dipakai untuk bergilir bila ada banyak.
func komentar(npc: String, idx: int) -> String:
	var daftar: Array = []
	for i in range(GameState.news_log.size() - 1, -1, -1):
		var e: Dictionary = GameData.event_by_id(str(GameState.news_log[i]))
		if e.has("kata") and e["kata"].has(npc):
			daftar.append(e["kata"][npc])
	if daftar.is_empty():
		return ""
	return str(daftar[idx % daftar.size()])


func warga_lines() -> Array:
	for i in range(GameState.news_log.size() - 1, -1, -1):
		var e: Dictionary = GameData.event_by_id(str(GameState.news_log[i]))
		if e.has("warga"):
			return e["warga"]
	return ["Hari ini biasa-biasa saja. Syukurlah.", "Kalau hari biasa-biasa saja, itu juga rezeki."]

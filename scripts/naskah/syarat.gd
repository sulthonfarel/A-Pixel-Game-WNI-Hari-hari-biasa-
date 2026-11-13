class_name Syarat
extends RefCounted
## Kondisi dalam naskah ("| jika ..."). Beberapa kondisi dipisah koma dan harus terpenuhi SEMUA (DAN).
##
## Bentuk kondisi:
##   flag nama            !flag nama            penanda cerita menyala / tidak
##   flag_hari nama       !flag_hari nama       penanda khusus hari ini
##   jumat   hari_kerja   salat_aktif           (boleh diawali ! untuk kebalikannya)
##   <nilai><op><angka>   op: >=  <=  >  <  =  !=
##       nilai: hari, jam, menit, uang, utang, catatan, listrik, tagihan,
##              akrab.<tokoh>, inv.<barang>, hitung.<penghitung>
## Nama flag boleh memuat {hari} (diganti nomor hari saat ini), mis. "ustaz_bantu_d{hari}".

const NILAI_DASAR: Array = ["hari", "jam", "menit", "uang", "utang", "catatan", "listrik", "tagihan"]
const BOOLEAN: Array = ["jumat", "hari_kerja", "salat_aktif"]

static var _re: RegEx = null


static func parse(s: String, lokasi: String) -> Array:
	var out: Array = []
	if s.strip_edges() == "":
		return out
	if _re == null:
		_re = RegEx.new()
		_re.compile("^([a-z_][a-z0-9_.]*)\\s*(>=|<=|!=|=|<|>)\\s*(-?\\d+)$")
	for mentah in s.split(","):
		var t: String = mentah.strip_edges()
		if t == "":
			continue
		var neg: bool = t.begins_with("!")
		if neg:
			t = t.substr(1).strip_edges()
		if t.begins_with("flag_hari "):
			out.append({"t": "flag_hari", "n": t.substr(10).strip_edges(), "neg": neg})
		elif t.begins_with("flag "):
			for nm in t.substr(5).strip_edges().split(" ", false):
				out.append({"t": "flag", "n": nm, "neg": neg})
		elif BOOLEAN.has(t):
			out.append({"t": t, "neg": neg})
		else:
			var m: RegExMatch = _re.search(t)
			if m == null or neg:
				Naskah.lapor("%s: kondisi tidak dikenali -> '%s'" % [lokasi, t])
				continue
			var nama: String = m.get_string(1)
			if not _nilai_valid(nama):
				Naskah.lapor("%s: nilai '%s' tidak dikenal di kondisi '%s'" % [lokasi, nama, t])
				continue
			out.append({"t": "cmp", "n": nama, "op": m.get_string(2), "x": int(m.get_string(3))})
	return out


static func _nilai_valid(n: String) -> bool:
	return NILAI_DASAR.has(n) or n.begins_with("akrab.") or n.begins_with("inv.") or n.begins_with("hitung.")


static func nilai(n: String) -> int:
	match n:
		"hari":
			return TimeManager.day
		"jam":
			return TimeManager.jam()
		"menit":
			return TimeManager.minutes
		"uang":
			return GameState.uang
		"utang":
			return GameState.utang
		"catatan":
			return GameState.count_testimoni()
		"listrik":
			return Daily.listrik_hari()
		"tagihan":
			return Daily.sewa_tagihan()
	if n.begins_with("akrab."):
		return GameState.relasi(n.substr(6))
	if n.begins_with("inv."):
		return GameState.jumlah_inv(n.substr(4))
	if n.begins_with("hitung."):
		return int(GameState.counters.get(n.substr(7), 0))
	return 0


static func _nama(n: String) -> String:
	return n.replace("{hari}", str(TimeManager.day))


static func cek(terms: Array) -> bool:
	for t in terms:
		var ok: bool = true
		match t["t"]:
			"flag":
				ok = GameState.has_flag(_nama(str(t["n"])))
			"flag_hari":
				ok = GameState.flag_hari(_nama(str(t["n"])))
			"jumat":
				ok = GameData.hari_jumat(TimeManager.day)
			"hari_kerja":
				ok = TimeManager.hari_kerja()
			"salat_aktif":
				ok = not GameData.salat_sekarang(TimeManager.day, TimeManager.minutes).is_empty()
			"cmp":
				var v: int = nilai(str(t["n"]))
				var x: int = int(t["x"])
				match str(t["op"]):
					">=":
						ok = v >= x
					"<=":
						ok = v <= x
					">":
						ok = v > x
					"<":
						ok = v < x
					"=":
						ok = v == x
					"!=":
						ok = v != x
		if bool(t.get("neg", false)):
			ok = not ok
		if not ok:
			return false
	return true

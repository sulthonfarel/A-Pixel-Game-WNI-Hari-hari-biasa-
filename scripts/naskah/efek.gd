class_name Efek
extends RefCounted
## Efek dalam naskah ("efek: ..." atau "| efek ..."). Beberapa efek dipisah koma.
## Hasilnya Dictionary yang dipahami GameState.apply_effects() dan Economy.apply_event().
##
##   uang +15000     energi -12     kenyang +40     mood +3     utang +7000     waktu 90
##   akrab.tati +2   (hubungan)     inv.paket +1    (barang)    tugas.t3 +40    (progres tugas)
##   hitung.bantu +1 (penghitung)   flag a b c      (nyalakan penanda)           flag_hari a
##   timed.nama 12   (penanda aktif sampai hari 12)
##   harga.telur x1.3  (pengali harga)               habis.mi_instan 2  (stok habis N hari)

const ANGKA: Array = ["uang", "energi", "kenyang", "mood", "utang", "waktu"]
const GRUP: Dictionary = {
	"akrab": "rel", "inv": "inv", "tugas": "tugas", "hitung": "counter",
	"timed": "timed", "harga": "harga", "habis": "habis",
}


static func parse(s: String, lokasi: String) -> Dictionary:
	var out: Dictionary = {}
	if s.strip_edges() == "":
		return out
	for mentah in s.split(","):
		var t: String = mentah.strip_edges()
		if t == "":
			continue
		if t.begins_with("flag_hari "):
			out["flag_hari"] = t.substr(10).strip_edges()
			continue
		if t.begins_with("flag "):
			var arr: Array = out.get("flag", [])
			for nm in t.substr(5).strip_edges().split(" ", false):
				arr.append(nm)
			out["flag"] = arr
			continue
		var sp: int = t.find(" ")
		if sp < 0:
			Naskah.lapor("%s: efek '%s' perlu nilai (mis. 'uang +5000')" % [lokasi, t])
			continue
		var kunci: String = t.substr(0, sp).strip_edges()
		var nilai: String = t.substr(sp + 1).strip_edges()
		if ANGKA.has(kunci):
			if not nilai.replace("+", "").replace("-", "").is_valid_int():
				Naskah.lapor("%s: nilai efek '%s' bukan angka" % [lokasi, t])
				continue
			out[kunci] = int(out.get(kunci, 0)) + int(nilai)
			continue
		var titik: int = kunci.find(".")
		var grup: String = kunci.substr(0, titik) if titik > 0 else ""
		if not GRUP.has(grup):
			Naskah.lapor("%s: efek '%s' tidak dikenal" % [lokasi, kunci])
			continue
		var kunci_dict: String = GRUP[grup]
		var nama: String = kunci.substr(titik + 1)
		var d: Dictionary = out.get(kunci_dict, {})
		if grup == "harga":
			d[nama] = float(nilai.trim_prefix("x"))
		else:
			d[nama] = int(nilai)
		out[kunci_dict] = d
	return out


## Salinan efek dengan {hari} pada nama penanda diganti nomor hari sekarang.
static func isi(e: Dictionary) -> Dictionary:
	if e.is_empty():
		return e
	var out: Dictionary = e.duplicate(true)
	for k in ["flag", "flag_hari"]:
		if not out.has(k):
			continue
		if out[k] is Array:
			var arr: Array = []
			for f in out[k]:
				arr.append(str(f).replace("{hari}", str(TimeManager.day)))
			out[k] = arr
		else:
			out[k] = str(out[k]).replace("{hari}", str(TimeManager.day))
	return out

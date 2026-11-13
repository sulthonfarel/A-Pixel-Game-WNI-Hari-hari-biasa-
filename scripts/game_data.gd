@tool
class_name GameData
extends RefCounted
## Semua data statis game: barang, lokasi, jadwal tokoh, tugas, dan event cerita.
## Ubah angka/teks di sini untuk menyetel keseimbangan dan cerita.

const HARI: Array = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"]
const START_UANG := 650000
const SEWA := 400000
const SEWA_TEMPO := 20
const SEWA_TOLERANSI := 25
const SEWA_DENDA := 50000
const LISTRIK_AWAL := 7          # hari listrik menyala dari token awal
const JUMLAH_HARI := 28
const HARI_RAPAT := 27
const OUTDOOR: Array = ["gang", "kampus", "koridor", "jalan", "lapangan"]

# ---------------------------------------------------------------- tokoh
const NPC: Dictionary = {
	"dimas": {"nama": "Dimas", "badan": "#3f5fbf", "rambut": "#1a1a1a", "kulit": "#d9a066"},
	"tati": {"nama": "Bu Tati", "badan": "#c0504d", "rambut": "#2b2b2b", "kulit": "#e0ac69"},
	"asep": {"nama": "Kang Asep", "badan": "#3b7ea1", "rambut": "#222222", "kulit": "#d9a066"},
	"rani": {"nama": "Rani", "badan": "#8e5ea2", "rambut": "#3a2418", "kulit": "#e8b88a"},
	"fikri": {"nama": "Fikri", "badan": "#2e9b57", "rambut": "#111111", "kulit": "#cf9560"},
	"darto": {"nama": "Pak Darto", "badan": "#7a6a4f", "rambut": "#9a9a9a", "kulit": "#d9a066"},
	"mira": {"nama": "Teh Mira", "badan": "#d98c3a", "rambut": "#2a1a10", "kulit": "#e0ac69"},
	"rw": {"nama": "Pak RW", "badan": "#5b6b7a", "rambut": "#555555", "kulit": "#d9a066"},
	"yoga": {"nama": "Mas Yoga", "badan": "#4a4a8a", "rambut": "#1a1a1a", "kulit": "#e0ac69"},
	"pelanggan1": {"nama": "Pelanggan", "badan": "#6b8e8e", "rambut": "#3a3a3a", "kulit": "#d9a066"},
	"pelanggan2": {"nama": "Pelanggan", "badan": "#a0805a", "rambut": "#1e1e1e", "kulit": "#e0ac69"},
	"ustaz": {"nama": "Pak Ustaz Hilman", "badan": "#f4f0e6", "rambut": "#222222", "kulit": "#d9a066"},
	"imam": {"nama": "Cak Imam", "badan": "#8a8a8a", "rambut": "#1a1a1a", "kulit": "#cf9560"},
	"ujang": {"nama": "Mang Ujang", "badan": "#c9b89a", "rambut": "#222222", "kulit": "#d9a066"},
}
const NPC_LIST: Array = ["tati", "asep", "rani", "fikri", "darto", "mira", "rw", "yoga", "pelanggan1", "pelanggan2", "ustaz", "imam", "ujang"]

# posisi tokoh saat rapat warga (hari ke-27, 19.00-22.00) di Balai RW
const RAPAT_POS: Dictionary = {
	"tati": [585, 252], "asep": [615, 256], "darto": [645, 252], "mira": [675, 256],
	"rani": [735, 256], "fikri": [765, 252], "ustaz": [795, 256],
}

# ---------------------------------------------------------------- barang
const ITEMS: Dictionary = {
	"nasi_tempe": {"nama": "Nasi + tempe orek + sayur", "harga": 7000, "tag": "sayur", "kenyang": 40, "energi": 6, "mood": 0},
	"nasi_telur": {"nama": "Nasi + telur dadar", "harga": 9000, "tag": "telur", "kenyang": 45, "energi": 8, "mood": 2},
	"nasi_ayam": {"nama": "Nasi + ayam goreng", "harga": 15000, "tag": "ayam", "kenyang": 55, "energi": 10, "mood": 5},
	"gorengan": {"nama": "Gorengan (3 buah)", "harga": 4000, "tag": "minyak", "kenyang": 15, "energi": 3, "mood": 2},
	"es_teh": {"nama": "Es teh manis", "harga": 3000, "tag": "gula", "kenyang": 5, "energi": 3, "mood": 3},
	"kopi_hitam": {"nama": "Kopi hitam", "harga": 5000, "tag": "kopi", "kenyang": 0, "energi": 10, "mood": 3},
	"kopi_susu": {"nama": "Kopi susu", "harga": 8000, "tag": "kopi", "kenyang": 5, "energi": 10, "mood": 5},
	"mi_rebus": {"nama": "Mi rebus + telur", "harga": 10000, "tag": "telur", "kenyang": 40, "energi": 6, "mood": 3},
	"mi_instan": {"nama": "Mi instan (1 bungkus)", "harga": 3500, "tag": "mi"},
	"kopi_sachet": {"nama": "Kopi sachet", "harga": 2000, "tag": "kopi"},
	"deterjen": {"nama": "Deterjen sachet", "harga": 8000, "tag": "sabun"},
	"air_mineral": {"nama": "Air mineral botol", "harga": 3000, "tag": "", "kenyang": 0, "energi": 3, "mood": 0},
	"teh_botol": {"nama": "Teh botol dingin", "harga": 5000, "tag": "gula", "kenyang": 3, "energi": 4, "mood": 3},
	"susu_kotak": {"nama": "Susu kotak", "harga": 6000, "tag": "", "kenyang": 8, "energi": 6, "mood": 2},
	"roti": {"nama": "Roti isi cokelat", "harga": 5000, "tag": "", "kenyang": 22, "energi": 3, "mood": 2},
	"snack": {"nama": "Keripik pedas", "harga": 3000, "tag": "minyak", "kenyang": 8, "energi": 1, "mood": 3},
	"minuman_energi": {"nama": "Minuman berenergi", "harga": 7000, "tag": "gula", "kenyang": 0, "energi": 14, "mood": 0},
	"telur": {"nama": "Telur ayam (1 butir)", "harga": 2500, "tag": "telur"},
	"beras": {"nama": "Beras 1 liter (±4 porsi nasi)", "harga": 14000, "tag": "beras", "inv": {"nasi": 4}},
	"token_listrik": {"nama": "Token listrik Rp20.000 (+7 hari)", "harga": 20000, "tag": "", "instan": {"mood": 3}, "counter": {"token": 1, "listrik": 7}},
	"minyak_kayu_putih": {"nama": "Minyak kayu putih", "harga": 9000, "tag": "", "instan": {"energi": 5, "mood": 2}},
	"batagor": {"nama": "Batagor kuah kacang", "harga": 12000, "tag": "minyak", "kenyang": 45, "energi": 8, "mood": 5},
	"siomay": {"nama": "Siomay + kentang", "harga": 11000, "tag": "ayam", "kenyang": 42, "energi": 7, "mood": 4},
	"cuanki": {"nama": "Cuanki (bakso kuah)", "harga": 10000, "tag": "ayam", "kenyang": 38, "energi": 6, "mood": 5},
	"seblak": {"nama": "Seblak kerupuk pedas", "harga": 12000, "tag": "sayur", "kenyang": 40, "energi": 5, "mood": 6},
	"cendol": {"nama": "Es cendol", "harga": 7000, "tag": "gula", "kenyang": 12, "energi": 4, "mood": 5},
	"bandrek": {"nama": "Bandrek hangat", "harga": 6000, "tag": "gula", "kenyang": 5, "energi": 7, "mood": 6},
	"lampu": {"nama": "Lampu belajar", "harga": 35000, "tag": "", "upgrade": "lampu"},
	"poster": {"nama": "Poster dinding", "harga": 15000, "tag": "", "upgrade": "poster"},
	"earphone": {"nama": "Earphone baru", "harga": 45000, "tag": "", "upgrade": "earphone"},
	"payung": {"nama": "Payung lipat", "harga": 25000, "tag": "", "upgrade": "payung", "mood_up": 3},
}
const MENU_WARUNG: Array = ["nasi_tempe", "nasi_telur", "nasi_ayam", "gorengan", "es_teh"]
const MENU_MIRA: Array = ["kopi_hitam", "kopi_susu", "mi_rebus", "es_teh"]
const MENU_ASEP: Array = ["mi_instan", "kopi_sachet", "deterjen", "lampu", "poster", "earphone"]
const TOKO_MADURA: Dictionary = {
	"Makanan & minuman": ["air_mineral", "teh_botol", "susu_kotak", "roti", "snack", "minuman_energi"],
	"Dapur kos (bahan masak)": ["mi_instan", "telur", "beras", "kopi_sachet"],
	"Kebutuhan kos & lainnya": ["deterjen", "token_listrik", "minyak_kayu_putih", "payung", "lampu", "poster", "earphone"],
}
const MENU_UJANG: Array = ["batagor", "siomay", "cuanki", "seblak", "cendol", "bandrek"]

const TRANSPORT: Dictionary = {
	"jalan": {"nama": "Jalan kaki", "harga": 0, "tag": "", "menit": 45, "energi": 12},
	"angkot": {"nama": "Angkot", "harga": 5000, "tag": "transport", "menit": 30, "energi": 4},
	"ojol": {"nama": "Ojek online", "harga": 14000, "tag": "bbm", "menit": 12, "energi": 1},
}

## Tugas kuliah: data/naskah/tugas.naskah
static var TUGAS: Array = DataCerita.tugas()



# ---------------------------------------------------------------- lokasi
# Data lokasi (objek, pintu, spawn, tepi) kini ada di scenes/maps/<id>.tscn. Lihat scripts/location_view.gd.


# ---------------------------------------------------------------- jadwal & jam buka
static func _j(loc: String, x: float, y: float) -> Dictionary:
	return {"loc": loc, "pos": Vector2(x, y)}


static func jadwal(npc: String, day: int, jam: int) -> Dictionary:
	var dow: int = (day - 1) % 7
	var kerja: bool = dow < 5
	if day == HARI_RAPAT and jam >= 19 and jam < 22 and RAPAT_POS.has(npc):
		var rp: Array = RAPAT_POS[npc]
		return _j("lapangan", float(rp[0]), float(rp[1]))
	match npc:
		"darto":
			if (jam >= 7 and jam < 10) or (jam >= 17 and jam < 19):
				return _j("koridor", 258, 248)
		"fikri":
			if (jam >= 6 and jam < 10) or (jam >= 16 and jam < 21):
				return _j("jalan", 575, 228)
		"mira":
			if jam >= 7 and jam < 23:
				return _j("kopi_mira", 320, 86)
		"rani":
			if kerja and jam >= 10 and jam < 15:
				return _j("kampus", 440, 198)
			if (not kerja) and jam >= 15 and jam < 19:
				return _j("kopi_mira", 110, 188)
		"yoga":
			if dow < 6 and jam >= 8 and jam < 20:
				return _j("fotokopi", 320, 98)
		"ustaz":
			if jam >= 12 and jam < 14 and (day - 1) % 7 == 4:
				return _j("gang", 218, 224)
			if jam >= 5 and jam < 21:
				return _j("masjid", 300, 240)
		"ujang":
			if jam >= 14 and jam < 22:
				return _j("jalan", 692, 224)
		"pelanggan1":
			if jam >= 20 and jam < 23:
				return _j("gang", 758, 218)
			if (jam >= 7 and jam < 9) or (jam >= 12 and jam < 14) or (jam >= 18 and jam < 20):
				return _j("lapangan", 168, 252)
		"pelanggan2":
			if (jam >= 7 and jam < 9) or (jam >= 12 and jam < 14) or (jam >= 18 and jam < 20):
				return _j("lapangan", 334, 252)
	return {}


static func buka(loc: String, day: int, jam: int) -> bool:
	var dow: int = (day - 1) % 7
	match loc:
		"warung_tati":
			return jam >= 6 and jam < 21
		"kelontong":
			return true
		"fotokopi":
			return dow < 6 and jam >= 8 and jam < 20
		"balai_rw":
			if day == HARI_RAPAT and jam >= 19 and jam < 22:
				return true
			return dow < 5 and ((jam >= 8 and jam < 12) or (jam >= 13 and jam < 15))
		"kopi_mira":
			return jam >= 7 and jam < 23
	return true


## Lokasi interior yang punya jam tutup (pemain diminta keluar saat tutup).
const INTERIOR_JAM: Array = ["fotokopi", "kopi_mira"]


static func jam_buka(loc: String) -> String:
	match loc:
		"warung_tati":
			return "Buka 06.00–21.00."
		"kelontong":
			return "Buka 24 jam."
		"fotokopi":
			return "Buka Senin–Sabtu 08.00–20.00."
		"balai_rw":
			return "Buka Senin–Jumat 08.00–12.00 dan 13.00–15.00."
		"kopi_mira":
			return "Buka 07.00–23.00."
	return ""


# ---------------------------------------------------------------- util
static func rp(n: int) -> String:
	var s: String = str(absi(n))
	var out: String = ""
	var c: int = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i != 0:
			out = "." + out
	return ("-" if n < 0 else "") + "Rp" + out


static func event_by_id(id: String) -> Dictionary:
	for e in EVENTS:
		if e["id"] == id:
			return e
	return {}


const SALAT: Array = [
	{"id": "zuhur", "nama": "Zuhur", "dari": 705, "sampai": 810},
	{"id": "ashar", "nama": "Ashar", "dari": 900, "sampai": 1005},
	{"id": "magrib", "nama": "Magrib", "dari": 1075, "sampai": 1130},
	{"id": "isya", "nama": "Isya", "dari": 1150, "sampai": 1245},
]
const JUMAT_MENU: Dictionary = {
	5: "nasi, ayam suwir, dan sambal",
	12: "nasi, tempe orek, dan sayur asem",
	19: "nasi dan telur balado (telur masih mahal, tapi donaturnya baik hati)",
	26: "nasi, ikan asin, lalapan, dan kerupuk",
}


static func hari_jumat(day: int) -> bool:
	return (day - 1) % 7 == 4


## Waktu salat yang sedang berlangsung; pada hari Jumat Zuhur menjadi Salat Jumat (11.45–12.30).
static func salat_sekarang(day: int, minutes: int) -> Dictionary:
	if hari_jumat(day) and minutes >= 705 and minutes < 750:
		return {"id": "jumat", "nama": "Salat Jumat", "menit": 40}
	for s in SALAT:
		if minutes >= int(s["dari"]) and minutes < int(s["sampai"]):
			if s["id"] == "zuhur" and hari_jumat(day) and minutes < 750:
				continue
			return {"id": s["id"], "nama": "Salat " + str(s["nama"]), "menit": 15}
	return {}


static func salat_berikutnya(minutes: int) -> String:
	for s in SALAT:
		if minutes < int(s["dari"]):
			return "%s sekitar %02d.%02d" % [s["nama"], floori(int(s["dari"]) / 60.0), int(s["dari"]) % 60]
	return "Subuh besok pagi"


static func kegiatan_selesai(day: int) -> int:
	var tabel: Dictionary = {6: 0, 8: 2, 9: 3, 11: 4, 13: 6, 15: 8, 18: 9, 22: 11, 25: 12}
	var hasil: int = 0
	for k in tabel.keys():
		if day >= int(k):
			hasil = maxi(hasil, int(tabel[k]))
	return hasil


# ---------------------------------------------------------------- event cerita
# eff: harga {tag: pengali} • habis {item: hari} • flag • timed {flag: sampai_hari} • uang
# kata: komentar tiap tokoh • warga: dua pendapat pelanggan warung (sering saling berlawanan)
## Berita & kejadian harian: data/naskah/berita.naskah
static var EVENTS: Array = DataCerita.berita()

extends Node
## Pencapaian kecil. Status disimpan di GameState.flags dengan awalan "ach_".

const DAFTAR: Array = [
	{"id": "anak_kos", "nama": "Anak Kos Sejati", "ket": "Memasak sendiri di kamar 10 kali."},
	{"id": "rajin_salat", "nama": "Langkah ke Masjid", "ket": "Salat berjamaah di masjid 12 kali."},
	{"id": "tepat_waktu", "nama": "Deadline Fighter", "ket": "Mengumpulkan 3 tugas tepat waktu."},
	{"id": "pendengar", "nama": "Pendengar yang Baik", "ket": "Mencatat 4 pengalaman warga."},
	{"id": "kritis", "nama": "Sumbernya Mana?", "ket": "Mengecek kebenaran pesan berantai soal beras."},
	{"id": "dermawan", "nama": "Receh Berkah", "ket": "Mengisi kotak amal 5 kali."},
	{"id": "rajin_kuliah", "nama": "Mahasiswa Rajin", "ket": "Hadir kuliah 10 kali."},
	{"id": "hemat", "nama": "Hemat Pangkal Kaya", "ket": "Punya Rp450.000 lebih dengan sewa sudah lunas."},
	{"id": "akrab", "nama": "Orang Kampung Sini", "ket": "Akrab (hubungan 5+) dengan 3 warga."},
	{"id": "rapat", "nama": "Suara dari Bangku Belakang", "ket": "Menghadiri rapat warga."},
	{"id": "jumat", "nama": "Pemburu Jumat Berkah", "ket": "Ikut Jumat Berkah 3 kali."},
	{"id": "penolong", "nama": "Tangan Terbuka", "ket": "Membantu warga 3 kali (Bu Tati, Pak Ustaz, antar paket)."},
	{"id": "kucing", "nama": "Teman si Oreng", "ket": "Mengelus kucing kampung 5 kali."},
]


func _c(k: String) -> int:
	return int(GameState.counters.get(k, 0))


func terpenuhi(id: String) -> bool:
	match id:
		"anak_kos":
			return _c("masak") >= 10
		"rajin_salat":
			return _c("salat") >= 12
		"tepat_waktu":
			return _c("tepat") >= 3
		"pendengar":
			return GameState.count_testimoni() >= 4
		"kritis":
			return GameState.has_flag("hoax_cek")
		"dermawan":
			return _c("amal") >= 5
		"rajin_kuliah":
			return _c("hadir") >= 10
		"hemat":
			return GameState.uang >= 450000 and GameState.has_flag("sewa_lunas")
		"akrab":
			var n: int = 0
			for k in GameState.rel.keys():
				if int(GameState.rel[k]) >= 5:
					n += 1
			return n >= 3
		"rapat":
			return GameState.has_flag("rapat_hadir")
		"jumat":
			return _c("jumat") >= 3
		"penolong":
			return _c("bantu") >= 3
		"kucing":
			return _c("kucing") >= 5
	return false


func sudah(id: String) -> bool:
	return bool(GameState.flags.get("ach_" + id, false))


func jumlah() -> int:
	var n: int = 0
	for a in DAFTAR:
		if sudah(str(a["id"])):
			n += 1
	return n


func cek() -> void:
	for a in DAFTAR:
		var id: String = str(a["id"])
		if not sudah(id) and terpenuhi(id):
			GameState.flags["ach_" + id] = true
			EventBus.pencapaian.emit(str(a["nama"]))

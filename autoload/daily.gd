extends Node
## Hal-hal yang berubah tiap pagi: token listrik, denda sewa, kejutan kecil.
## Juga menyusun "rencana hari ini" untuk ponsel (tanpa efek samping).

const KEJUTAN: Array = [
	{"t": "Di saku jaket ada uang Rp10.000 yang entah sejak kapan di situ. Hari yang baik dimulai dari hal kecil.", "eff": {"uang": 10000, "mood": 3}},
	{"t": "Tetangga sebelah menyisihkan sepiring nasi goreng di depan pintu. Tanpa nama, tanpa catatan. Hanya kebaikan.", "eff": {"kenyang": 25, "mood": 4}},
	{"t": "Ponselmu kehabisan kuota tepat saat bangun. Dunia terasa lebih sunyi, dan sedikit lebih tenang.", "eff": {"mood": -2}},
	{"t": "Ibu mengirim pesan suara: 'Sudah makan?' Tiga kata, cukup untuk menghangatkan satu hari.", "eff": {"mood": 6}},
	{"t": "Semalam nyamuk berpesta. Kamu bangun dengan bentol di mana-mana dan tidur yang kurang nyenyak.", "eff": {"energi": -8, "mood": -2}},
	{"t": "Sinar matahari masuk pas ke meja belajar. Rasanya seperti restu semesta untuk mengerjakan tugas.", "eff": {"energi": 5, "mood": 3}},
	{"t": "Kamu menemukan sisa gorengan kemarin di kantong plastik. Masih layak. Hampir.", "eff": {"kenyang": 10}},
]


func sewa_tagihan() -> int:
	return GameData.SEWA + (GameData.SEWA_DENDA if GameState.has_flag("sewa_denda") else 0)


func listrik_hari() -> int:
	return int(GameState.counters.get("listrik", 0))


func listrik_ada() -> bool:
	return listrik_hari() > 0


## Dipanggil sekali tiap pagi setelah hari berganti. Mengembalikan baris untuk ringkasan pagi.
func proses_pagi() -> Array:
	var baris: Array = []
	var day: int = TimeManager.day
	# --- listrik
	var sisa: int = listrik_hari()
	if sisa > 0:
		sisa -= 1
		GameState.counters["listrik"] = sisa
	if sisa == 0:
		baris.append("LISTRIK PADAM: token habis. Kompor listrik mati dan laptop tinggal sisa baterai. Beli token di Warung Madura.")
	elif sisa <= 2:
		baris.append("Token listrik tinggal %d hari. Lampu meteran di koridor mulai berkedip." % sisa)
	# --- sewa
	if not GameState.has_flag("sewa_lunas"):
		if day == GameData.SEWA_TOLERANSI:
			baris.append("Hari terakhir toleransi sewa kos. Besok Pak Darto tidak akan sesabar kemarin.")
		elif day == GameData.SEWA_TOLERANSI + 1:
			GameState.apply_effects({"flag": "sewa_denda", "mood": -8}, true)
			baris.append("Di pintu kamar ada catatan tempel dari Pak Darto: sewa terlambat, denda %s ditambahkan. Total tagihan %s." % [GameData.rp(GameData.SEWA_DENDA), GameData.rp(sewa_tagihan())])
	# --- kejutan kecil (acak tapi konsisten per hari, jadi tidak berubah saat memuat simpanan)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7000 + day * 31
	if day >= 2 and day != 14 and rng.randf() < 0.30:
		var pilih: Dictionary = KEJUTAN[rng.randi() % KEJUTAN.size()]
		baris.append(str(pilih["t"]))
		GameState.apply_effects(pilih["eff"], true)
	return baris


## Daftar pengingat untuk hari ini (tidak mengubah apa pun).
func rencana_hari_ini() -> Array:
	var r: Array = []
	var day: int = TimeManager.day
	var kerja: bool = TimeManager.hari_kerja()
	for t in GameData.TUGAS:
		var st: Dictionary = GameState.tugas[t["id"]]
		if bool(st["dikumpul"]) or day < int(t["mulai"]):
			continue
		var sisa: int = int(t["tenggat"]) - day
		var tahap: String = "progres %d%%" % int(st["progress"])
		if int(st["progress"]) >= 100:
			tahap = "tinggal dikumpulkan" if bool(st["dicetak"]) else "tinggal dicetak lalu dikumpulkan"
		var kapan: String = "tenggat HARI INI" if sisa == 0 else ("tenggat %d hari lagi" % sisa if sisa > 0 else "TELAT, kumpulkan secepatnya")
		r.append("Tugas: %s — %s (%s)." % [t["nama"], tahap, kapan])
	if kerja:
		r.append("Kuliah hari ini pukul 08.00–10.30 (boleh masuk 07.30–09.30). Kumpulkan tugas lewat ruang kelas.")
	else:
		r.append("Akhir pekan: kampus libur, fotokopi tutup di hari Minggu, Balai RW tutup.")
	if not GameState.has_flag("sewa_lunas"):
		if day >= GameData.SEWA_TEMPO:
			r.append("Sewa kos %s sudah jatuh tempo (toleransi sampai hari %d)." % [GameData.rp(sewa_tagihan()), GameData.SEWA_TOLERANSI])
		else:
			r.append("Sewa kos %s jatuh tempo hari ke-%d." % [GameData.rp(sewa_tagihan()), GameData.SEWA_TEMPO])
	var l: int = listrik_hari()
	if l <= 2:
		r.append("Listrik: %s." % ("PADAM, beli token di Warung Madura" if l == 0 else "tinggal %d hari" % l))
	if GameData.hari_jumat(day):
		r.append("Hari Jumat: Salat Jumat 11.45, lalu Jumat Berkah di depan masjid (±12.30, cepat habis).")
	if day == 14:
		r.append("Kiriman Ibu Rp500.000 masuk hari ini.")
	if day == GameData.HARI_RAPAT:
		r.append("RAPAT WARGA pukul 19.00 di Balai RW.")
	elif day < GameData.HARI_RAPAT and GameState.has_flag("undangan_rapat"):
		r.append("Rapat warga: hari ke-27, pukul 19.00, Balai RW.")
	if GameState.has_flag("pos_layanan") and TimeManager.nama_hari() in ["Senin", "Selasa", "Rabu", "Kamis"]:
		r.append("Pos layanan administrasi buka 09.00–12.00 hari ini.")
	if GameState.jumlah_inv("paket") > 0:
		r.append("Kamu masih membawa paket titipan Fikri untuk Pak RW (Balai buka Senin–Jumat, jam kerja).")
	if GameState.has_flag("surat_butuh_salinan") and not GameState.has_flag("surat_selesai"):
		r.append("Surat pengantar domisili: butuh salinan KTP & KK (fotokopi), lalu temui Pak RW.")
	if GameState.utang > 0:
		r.append("Utang kasbon ke Bu Tati: %s." % GameData.rp(GameState.utang))
	return r

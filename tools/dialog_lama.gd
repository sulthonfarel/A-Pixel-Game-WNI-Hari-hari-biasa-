class_name DialogLama
extends RefCounted
## Dialog dibangun dinamis sesuai kondisi (hari, flag, hubungan, kabar terbaru).
## Simpul dialog: {"s": pembicara, "t": teks, "ch": [pilihan], "eff": {efek}, "next": id, "aksi": nama}
## Pilihan: {"t": teks, "n": id_berikut, "eff": {efek}, "aksi": nama_aksi}

static var nodes: Dictionary = {}
const BISA_AKRAB: Array = ["tati", "asep", "rani", "fikri", "darto", "mira", "rw", "yoga", "ustaz", "imam", "ujang"]

const SALAM: Dictionary = {
	"tati": ["Mangga, {nama}. Sarapan dulu?", "Siang, {nama}. Nasinya masih hangat.", "Sore, Nak. Lauk tinggal yang itu-itu, tapi enak."],
	"asep": ["Pagi, Kang {nama}! Mau beli apa?", "Siang, Kang. Panas ya. Es batu habis, tapi gosip masih ada.", "Sore, Kang. Mau belanja atau mau dengar kabar terbaru?"],
	"rani": ["Pagi. Kamu sudah sarapan atau cuma ngopi?", "Hai, {nama}. Lagi senggang? Aku lagi coba nyicil tugas.", "Sore, {nama}. Hari ini rasanya panjang banget, ya."],
	"fikri": ["Pagi, Kang. Mau berangkat? Aku masih nunggu orderan.", "Eh, {nama}. Aku lagi istirahat sebentar.", "Sore, Kang. Lagi nunggu orderan malam."],
	"darto": ["Pagi, {nama}. Sudah sarapan?", "Siang, Nak. Kamar aman?", "Sore, {nama}. Jemuran jangan numpuk di teras ya."],
	"mira": ["Mangga, Aa. Kopi atau teh?", "Siang. Masih sepi, belum ada yang nonton bola.", "Sore, {nama}. Tempat duduk masih kosong."],
	"rw": ["Selamat pagi, {nama}. Ada yang bisa dibantu?", "Siang, Nak. Silakan duduk.", "Sore, {nama}. Kantor hampir tutup."],
	"ustaz": ["Assalamu'alaikum, {nama}. Pagi yang baik.", "Wa'alaikumsalam, {nama}. Sudah makan siang?", "Sore, Nak. Sebentar lagi Magrib."],
	"ujang": ["Mangga, Aa. Batagornya masih hangat.", "Mangga, Aa. Mau batagor atau cuanki?", "Mangga, Aa. Sore-sore begini enaknya yang berkuah."],
	"imam": ["Pagi, Mas. Belanja apa?", "Siang, Mas. Panas ya.", "Malam, Mas. Mau belanja apa? Warung ini buka terus; yang tutup cuma kalau saya ngantuk."],
	"yoga": ["Pagi, Mas. Mau print atau fotokopi?", "Siang, Mas. Antreannya lumayan.", "Sore. Printernya belum ngambek, silakan."],
}


# ---------------------------------------------------------------- util
static func fill(t: String) -> String:
	return t.replace("{nama}", GameState.player_name).replace("{uang}", GameData.rp(GameState.uang))


static func _n(id: String, s: String, t: String, ch: Array = [], eff: Dictionary = {}, next: String = "") -> void:
	var d: Dictionary = {"s": s, "t": t, "ch": ch}
	if not eff.is_empty():
		d["eff"] = eff
	if next != "":
		d["next"] = next
	nodes[id] = d


static func _c(t: String, n: String = "", eff: Dictionary = {}, aksi: String = "") -> Dictionary:
	var d: Dictionary = {"t": t}
	if n != "":
		d["n"] = n
	if not eff.is_empty():
		d["eff"] = eff
	if aksi != "":
		d["aksi"] = aksi
	return d


static func _salam(npc: String, cnt: int) -> String:
	var j: int = TimeManager.jam()
	var i: int = 0
	if j >= 16:
		i = 2
	elif j >= 11:
		i = 1
	var s: String = str(SALAM[npc][i])
	var k: String = NewsSystem.komentar(npc, cnt)
	if k != "":
		s += "\n\n" + k
	return s


## Satu baris dialog sekali tampil.
static func solo(speaker: String, text: String, eff: Dictionary = {}) -> String:
	nodes.clear()
	_n("solo", speaker, text, [], eff)
	return "solo"


static func hub(npc: String) -> String:
	nodes.clear()
	var cnt: int = int(GameState.talk_count.get(npc, 0))
	GameState.talk_count[npc] = cnt + 1
	# ngobrol rutin pelan-pelan mengakrabkan (tiap obrolan ke-3, sampai hubungan 4)
	if cnt % 3 == 2 and BISA_AKRAB.has(npc) and GameState.relasi(npc) < 4:
		GameState.apply_effects({"rel": {npc: 1}})
	match npc:
		"tati":
			_hub_tati(cnt)
		"asep":
			_hub_asep(cnt)
		"rani":
			_hub_rani(cnt)
		"fikri":
			_hub_fikri(cnt)
		"darto":
			_hub_darto(cnt)
		"mira":
			_hub_mira(cnt)
		"rw":
			_hub_rw(cnt)
		"yoga":
			_hub_yoga(cnt)
		"ustaz":
			_hub_ustaz(cnt)
		"imam":
			_hub_imam(cnt)
		"ujang":
			_hub_ujang(cnt)
		_:
			_hub_pelanggan(npc, cnt)
	return "hub"


# ---------------------------------------------------------------- Bu Tati
static func _hub_tati(cnt: int) -> void:
	var ch: Array = []
	ch.append(_c("Pesan makanan", "", {}, "menu_tati"))
	if GameState.uang < 9000 and GameState.utang <= 0 and GameState.relasi("tati") >= 1:
		ch.append(_c("Kasbon dulu ya, Bu… (utang Rp7.000)", "tati_kasbon"))
	if GameState.utang > 0:
		ch.append(_c("Bayar utang (%s)" % GameData.rp(GameState.utang), "", {}, "bayar_utang"))
	if TimeManager.day >= 3 and not GameState.has_flag("bantu_tati") and TimeManager.jam() < 16:
		ch.append(_c("Ada yang bisa dibantu, Bu?", "tati_bantu"))
	if GameState.has_flag("program_launch") and not GameState.has_flag("testimoni_tati"):
		ch.append(_c("Soal Program Kampung Nyaman, Bu…", "tati_program"))
	ch.append(_c("Cuma mampir, Bu."))
	_n("hub", "Bu Tati", _salam("tati", cnt), ch)
	_n("tati_kasbon", "Bu Tati", "Yah… sekali ini ya, {nama}. Tapi dicatat. Jangan jadi kebiasaan. Ibu juga punya utang ke pemasok.", [], {"kenyang": 40, "energi": 6, "utang": 7000, "waktu": 15, "rel": {"tati": 1}})
	_n("tati_bantu", "Bu Tati", "Kebetulan, {nama}. Ibu mau ke pasar beli cabai dan telur, tapi pinggang lagi nggak enak. Bantu angkat belanjaan, ya? Nanti Ibu kasih uang capek.", [_c("Siap, Bu.", "tati_bantu2"), _c("Nanti ya, Bu.")])
	_n("tati_bantu2", "", "Pasar pagi itu ramai. Cabai naik, telur naik, tomat entah kenapa tetap sama. Pedagang bilang naiknya 'dari sananya'. Entah sananya di mana.", [], {"waktu": 90, "energi": -12, "uang": 15000, "rel": {"tati": 2}, "flag": "bantu_tati", "counter": {"bantu": 1}})
	_n("tati_program", "{nama}", "Bu, boleh nanya soal Program Kampung Nyaman? Menurut Ibu gimana?", [], {}, "tati_program2")
	_n("tati_program2", "Bu Tati", "Spanduknya bagus, jalannya mulus. Tapi biaya dapur Ibu nggak ikut turun: telur, gas, cabai. Ibu harus tahan harga supaya langganan nggak kabur. Kalau ada program yang bantu pedagang kecil, Ibu belum dengar.", [], {"flag": "testimoni_tati", "mood": 1}, "tati_program3")
	_n("tati_program3", "", "Dimas mencatat di ponselnya: 'Bu Tati — biaya operasional naik, belum ada bantuan untuk pedagang kecil.'")


# ---------------------------------------------------------------- Kang Asep
static func _hub_asep(cnt: int) -> void:
	var ch: Array = []
	ch.append(_c("Belanja", "", {}, "menu_asep"))
	if GameState.has_flag("hoax_beras") and TimeManager.day <= 6 and not GameState.has_flag("hoax_selesai"):
		ch.append(_c("Katanya beras bakal langka, Kang?", "asep_hoax"))
	if GameState.has_flag("program_launch") and TimeManager.day >= 10 and not GameState.has_flag("testimoni_asep"):
		ch.append(_c("Menurut Kang Asep, Program Kampung Nyaman gimana?", "asep_program"))
	ch.append(_c("Warung ini milik siapa, Kang?", "asep_madura"))
	ch.append(_c("Cuma lihat-lihat."))
	_n("hub", "Kang Asep", _salam("asep", cnt), ch)
	_n("asep_madura", "Kang Asep", "Punya Pak Haji Samsul, orang Sumenep. Saya jaga siang, Cak Imam jaga malam. Gantian supaya warung nggak pernah tutup. Dua tahun di sini saya paham satu hal: pelanggan boleh lupa bayar, tapi lupa nama kita jangan.", [], {"mood": 1})
	_n("asep_hoax", "Kang Asep", "Kang, denger nggak? Katanya beras bakal langka minggu depan! Pesannya beredar di grup RW. Tadi sudah ada yang borong mi instan. Rak saya hampir kosong!", [
		_c("Wah, forward ke grup kos ah.", "asep_hoax_fwd", {"flag": ["hoax_forward", "hoax_selesai"], "mood": 1}),
		_c("Tunggu, sumbernya mana? Aku cek dulu.", "asep_hoax_cek", {"flag": ["hoax_cek", "hoax_selesai"], "waktu": 30, "mood": 2, "rel": {"asep": 1, "rani": 1}}),
		_c("Ah, nggak usah dipikirin.", "", {"flag": ["hoax_abaikan", "hoax_selesai"]}),
	])
	_n("asep_hoax_fwd", "Kang Asep", "Nah! Biar yang lain siap-siap juga!", [], {}, "asep_hoax_fwd2")
	_n("asep_hoax_fwd2", "", "Dimas menekan 'kirim'. Tiga menit kemudian, dua orang di grup kos membalas dengan stiker panik.")
	_n("asep_hoax_cek", "", "Dimas menelusuri pesan itu. Gambar yang beredar ternyata tangkapan layar lama dengan tanggal yang diedit. Sumber aslinya tidak ada.", [], {}, "asep_hoax_cek2")
	_n("asep_hoax_cek2", "Kang Asep", "Waduh… untung belum saya sebar. Hatur nuhun, Kang. Besok-besok saya tanya dulu.")
	_n("asep_program", "{nama}", "Kang, menurut Akang, Program Kampung Nyaman gimana buat warung ini?", [], {}, "asep_program2")
	_n("asep_program2", "Kang Asep", "Sejak ada acara-acara itu, orang lewat depan warung lebih banyak, lumayan. Tapi waktu jalan ditutup, truk pasokan telat dua hari. Rak kosong, pelanggan nanya terus. Ya… ada untung, ada buntung.", [], {"flag": "testimoni_asep", "mood": 1}, "asep_program3")
	_n("asep_program3", "", "Dimas mencatat: 'Kang Asep — keramaian naik, tapi pasokan telat saat jalan ditutup.'")


# ---------------------------------------------------------------- Rani
static func _hub_rani(cnt: int) -> void:
	var ch: Array = []
	if TimeManager.day >= 14 and TimeManager.day <= 19 and int(GameState.counters.get("proyek", 0)) < 2:
		ch.append(_c("Yuk kerjain proyek kelompok bareng.", "rani_proyek"))
	if TimeManager.day >= 11 and GameState.relasi("rani") >= 2 and not GameState.has_flag("rani_cerita"):
		ch.append(_c("Kamu kelihatan capek, Ran. Ada apa?", "rani_cerita"))
	if GameState.has_flag("rani_cerita") and not GameState.has_flag("testimoni_rani"):
		ch.append(_c("Boleh kucatat soal pos layanan itu? Buat dokumentasi warga.", "rani_catat"))
	ch.append(_c("Ngobrol santai saja.", "rani_santai"))
	ch.append(_c("Aku lanjut dulu, Ran."))
	_n("hub", "Rani", _salam("rani", cnt), ch)
	_n("rani_proyek", "Rani", "Oke. Laptopku sudah rapi. Punyamu pasti terbuka dengan 47 tab, kan?", [], {"waktu": 120, "energi": -10, "tugas": {"t3": 40}, "rel": {"rani": 2}, "mood": 3, "counter": {"proyek": 1}})
	_n("rani_cerita", "Rani", "Nggak apa-apa. Cuma… aku kerja paruh waktu di katering tiap Sabtu-Minggu. Adikku butuh biaya sekolah. Dan pos layanan Kampung Nyaman itu buka Senin sampai Kamis jam sembilan sampai dua belas. Persis jam kuliahku.", [], {}, "rani_cerita2")
	_n("rani_cerita2", "Rani", "Aku butuh surat keterangan dari sana buat beasiswa adikku. Daftarnya online, tapi berkasnya harus dibawa langsung. Bisa sih bolos kelas, tapi dosenku tipe 'telat satu menit tamat'.", [
		_c("Boleh kucatat? Buat dokumentasi warga.", "rani_catat"),
		_c("Aku bisa tanya Pak RW soal jamnya.", "rani_janji", {"flag": "rani_janji", "rel": {"rani": 1}}),
		_c("Berat ya. Semangat, Ran.", "", {"rel": {"rani": 2}, "mood": 1, "flag": "rani_cerita"}),
	], {"flag": "rani_cerita"})
	_n("rani_catat", "Rani", "Boleh. Tapi tulis apa adanya, jangan didramatisir. Aku cuma pengin jamnya masuk akal.", [], {"flag": "testimoni_rani", "rel": {"rani": 1}}, "rani_catat2")
	_n("rani_catat2", "", "Dimas mencatat: 'Rani — jam pos layanan bentrok dengan kuliah dan kerja; berkas fisik tetap harus dibawa.'")
	_n("rani_janji", "Rani", "Serius? Makasih, Dim. Jangan janji kalau berat, ya.")
	var santai: Array = [
		"Aku mikir, kenapa tugas selalu datang lebih cepat daripada uang kiriman?",
		"Kopi di kafe itu enak, tapi harganya sama dengan dua kali makan di warung. Aku selalu menimbang, lalu pesan air putih.",
		"Kadang aku iri sama yang bisa fokus belajar tanpa mikir ongkos. Tapi ya sudah, aku punya jalanku sendiri.",
		"Kalau ada tugas kelompok, aku selalu jadi yang bikin jadwalnya. Nggak apa-apa, aku suka rapi.",
	]
	_n("rani_santai", "Rani", str(santai[cnt % santai.size()]))


# ---------------------------------------------------------------- Fikri
static func _hub_fikri(cnt: int) -> void:
	var ch: Array = []
	if TimeManager.day >= 3 and GameState.jumlah_inv("paket") == 0 and not GameState.has_flag("paket_selesai") and not GameState.has_flag("paket_dibawa"):
		ch.append(_c("Ada yang bisa kubantu, Fik?", "fikri_paket"))
	if TimeManager.day >= 15 and GameState.has_flag("program_launch") and not GameState.has_flag("testimoni_fikri"):
		ch.append(_c("Menurutmu Program Kampung Nyaman gimana, Fik?", "fikri_program"))
	ch.append(_c("Cuma nyapa."))
	var s: String = _salam("fikri", cnt)
	if GameState.relasi("fikri") >= 3:
		s += "\n\n(Fikri: 'Kalau naik ojolku, buat langganan kukasih potongan seribu dua ribu.')"
	_n("hub", "Fikri", s, ch)
	_n("fikri_paket", "Fikri", "Eh Kang, ada paket buat Pak RW, tapi aku harus ngejar order jauh. Bisa titip? Nanti kutraktir kopi.", [
		_c("Sini, aku antar.", "fikri_paket2", {"inv": {"paket": 1}, "flag": "paket_dibawa", "rel": {"fikri": 1}}),
		_c("Maaf, lagi buru-buru."),
	])
	_n("fikri_paket2", "", "Paket kecil berlakban cokelat. Penerima: Pak RW, Balai RW. 'Jangan dibuka ya, Kang,' kata Fikri, setengah bercanda.")
	_n("fikri_program", "Fikri", "Penghasilanku tergantung narik. Waktu jalan ditutup, aku muter, bensin nambah, penumpang nunggu lebih lama. Orderan jauh nggak ketutup. Tapi lampu jalan baru bikin narik malam lebih tenang, itu jujur bagus.", [], {"flag": "testimoni_fikri", "mood": 1}, "fikri_program2")
	_n("fikri_program2", "", "Dimas mencatat: 'Fikri — penutupan jalan memotong penghasilan harian; lampu jalan membantu.'")


# ---------------------------------------------------------------- Pak Darto
static func _hub_darto(cnt: int) -> void:
	var ch: Array = []
	if not GameState.has_flag("sewa_lunas"):
		ch.append(_c("Bayar sewa (%s)" % GameData.rp(Daily.sewa_tagihan()), "", {}, "bayar_sewa"))
	if not GameState.has_flag("kursi"):
		ch.append(_c("Beli kursi bekas (Rp50.000)", "", {}, "beli_kursi"))
	ch.append(_c("Soal listrik, Pak…", "darto_listrik"))
	ch.append(_c("Permisi, Pak."))
	var s: String = _salam("darto", cnt)
	if TimeManager.day >= GameData.SEWA_TEMPO and not GameState.has_flag("sewa_lunas"):
		s += "\n\nSewa bulan ini, ya. Saya tunggu sampai tanggal 25. Saya nggak galak, tapi bendahara listrik lebih nggak sabaran."
	_n("hub", "Pak Darto", s, ch)
	var l: int = Daily.listrik_hari()
	var info: String = "\n\n(Meteran kamarmu: " + ("token HABIS, belilah di Warung Madura.)" if l == 0 else "token cukup untuk %d hari lagi.)" % l)
	_n("darto_listrik", "Pak Darto", "Listrik kos naik terus. Anak-anak nyalain kipas, kompor listrik, charger, lampu… semuanya barengan. Saya cuma minta: matikan lampu kalau keluar. Itu juga sedekah, kan?" + info)


# ---------------------------------------------------------------- Teh Mira
static func _hub_mira(cnt: int) -> void:
	var ch: Array = []
	ch.append(_c("Pesan sesuatu", "", {}, "menu_mira"))
	ch.append(_c("Nonton TV sebentar", "", {}, "tv"))
	ch.append(_c("Kerjakan tugas di sini (sekalian pesan es teh)", "", {}, "kerja_kopi"))
	if TimeManager.day >= 15 and GameState.has_flag("program_launch") and not GameState.has_flag("testimoni_mira"):
		ch.append(_c("Teh Mira, gimana soal Program Kampung Nyaman?", "mira_program"))
	ch.append(_c("Cuma mampir."))
	_n("hub", "Teh Mira", _salam("mira", cnt), ch)
	_n("mira_program", "Teh Mira", "Papan informasinya ada, lampu jalan nyala, orang betah nongkrong lama. Tapi jam buka pos layanan nggak ditempel di tempat orang lewat. Ujung-ujungnya yang nanya ke sini. Saya bukan petugas, tapi saya jawab juga.", [], {"flag": "testimoni_mira", "mood": 1}, "mira_program2")
	_n("mira_program2", "", "Dimas mencatat: 'Teh Mira — informasi jam layanan tidak ada di tempat orang sering lewat.'")


# ---------------------------------------------------------------- Pak RW
static func _hub_rw(cnt: int) -> void:
	var ch: Array = []
	if GameState.jumlah_inv("paket") > 0:
		ch.append(_c("Titipan paket dari Fikri, Pak.", "rw_paket"))
	if TimeManager.day == GameData.HARI_RAPAT and TimeManager.jam() >= 19 and not GameState.has_flag("rapat_hadir"):
		ch.append(_c("Pak, rapatnya sudah bisa dimulai?", "", {}, "rapat"))
	ch.append(_c("Tanya soal Program Kampung Nyaman", "rw_program"))
	if TimeManager.day >= 9 and not GameState.has_flag("surat_selesai"):
		if not GameState.has_flag("surat_mulai"):
			ch.append(_c("Saya mau urus surat pengantar domisili.", "rw_surat1"))
		elif GameState.jumlah_inv("salinan") > 0:
			ch.append(_c("Saya sudah bawa salinan KTP & KK, Pak.", "rw_surat_ok"))
		else:
			ch.append(_c("Soal surat pengantar tadi, Pak…", "rw_surat_blm"))
	if TimeManager.day >= 18 and GameState.count_testimoni() >= 1 and not GameState.has_flag("catatan_diserahkan"):
		ch.append(_c("Pak, saya punya catatan pengalaman beberapa warga.", "rw_catatan"))
	if GameState.has_flag("rani_janji") and not GameState.has_flag("rw_pertanyaan_rani") and TimeManager.day >= 12:
		ch.append(_c("Pak, soal jam buka pos layanan…", "rw_jam"))
	ch.append(_c("Permisi, Pak."))
	_n("hub", "Pak RW", _salam("rw", cnt), ch)
	_n("rw_program", "Pak RW", "Program Kampung Nyaman itu inisiatif memperbaiki fasilitas dan layanan di lingkungan kita: ada 12 kegiatan. Penerangan, perbaikan jalan, papan informasi, pos layanan, taman, dan seterusnya. Setiap kegiatan selesai kami laporkan ke kecamatan.", [], {}, "rw_program2")
	_n("rw_program2", "{nama}", "Kalau warga punya keluhan, lapornya ke siapa, Pak?", [], {}, "rw_program3")
	_n("rw_program3", "Pak RW", "Ke saya. Senin sampai Jumat, jam delapan sampai tiga, kecuali istirahat. Lewat dari itu… ya, besok.")
	_n("rw_paket", "Pak RW", "Oh, ini yang ditunggu. Terima kasih ya, Nak. Ini sedikit uang jasa. Salam buat Fikri.", [], {"inv": {"paket": -1}, "flag": "paket_selesai", "rel": {"fikri": 1, "rw": 1}, "uang": 5000, "mood": 2, "counter": {"bantu": 1}})
	_n("rw_surat1", "Pak RW", "Surat pengantar? Boleh. Bawa fotokopi KTP dan KK, ya. Di fotokopian dekat sini.", [], {"flag": ["surat_mulai", "surat_butuh_salinan"]}, "rw_surat1b")
	_n("rw_surat1b", "{nama}", "Bukannya formulirnya online, Pak?", [], {}, "rw_surat1c")
	_n("rw_surat1c", "Pak RW", "Pendaftarannya online, betul. Tapi tetap harus ditempel salinan fisik yang dicap basah. Sistemnya modern, stempelnya tradisional.")
	_n("rw_surat_ok", "Pak RW", "Nah, lengkap. Sebentar, saya cap dulu. Dan… selesai. Rapi sekali. Biasanya ada yang kurang satu lembar.", [], {"inv": {"salinan": -1}, "flag": "surat_selesai", "rel": {"rw": 2}, "mood": 3})
	_n("rw_surat_blm", "Pak RW", "Belum ada salinan KTP dan KK-nya? Fotokopinya di dekat sini, buka sampai jam delapan malam. Tapi saya sendiri tutup jam tiga, ya.")
	_n("rw_catatan", "Pak RW", "Catatan warga, ya… ini bagus. Tapi formatnya bukan format laporan kecamatan. Nanti saya lampirkan sebagai 'masukan warga', ya. Terima kasih sudah mau mendengarkan orang-orang.", [], {"flag": "catatan_diserahkan", "rel": {"rw": 1}, "mood": 2})
	_n("rw_jam", "Pak RW", "Jam itu ketentuan dari kecamatan, bukan dari saya. Tapi akan saya sampaikan sebagai usulan. Belum tentu berubah, tapi lebih baik disampaikan daripada dipendam.", [], {"flag": "rw_pertanyaan_rani", "rel": {"rw": 1}})


# ---------------------------------------------------------------- Pak Ustaz & Cak Imam
static func _hub_ustaz(cnt: int) -> void:
	var ch: Array = []
	if not GameData.salat_sekarang(TimeManager.day, TimeManager.minutes).is_empty():
		ch.append(_c("Saya ikut salat berjamaah, Pak Ustaz.", "", {}, "salat_masjid"))
	ch.append(_c("Tanya jadwal salat & Jumat Berkah", "ustaz_info"))
	var m: int = TimeManager.minutes
	if GameData.hari_jumat(TimeManager.day) and m >= 735 and m < 810 and not GameState.has_flag("ustaz_bantu_d" + str(TimeManager.day)):
		ch.append(_c("Boleh saya bantu membagikan nasi?", "ustaz_bantu"))
	if GameState.has_flag("program_launch") and TimeManager.day >= 15 and not GameState.has_flag("testimoni_ustaz"):
		ch.append(_c("Pak Ustaz, soal Program Kampung Nyaman…", "ustaz_program"))
	ch.append(_c("Permisi, Pak Ustaz."))
	_n("hub", "Pak Ustaz Hilman", _salam("ustaz", cnt), ch)
	_n("ustaz_info", "Pak Ustaz Hilman", "Adzan Zuhur sekitar jam sebelas lewat empat puluh lima, Ashar jam tiga, Magrib jam enam, Isya jam tujuh lewat seperempat. Hari Jumat, jumatan jam sebelas empat puluh lima. Setelahnya ada Jumat Berkah di depan masjid, kira-kira setengah satu. Kadang cepat habis, jadi jangan terlalu santai.")
	_n("ustaz_bantu", "{nama}", "Pak Ustaz, boleh saya bantu membagikan nasinya?", [], {}, "ustaz_bantu2")
	_n("ustaz_bantu2", "Pak Ustaz Hilman", "Alhamdulillah. Silakan, Nak. Satu per satu ya, jangan lupa senyum. Itu lauknya juga.", [], {"flag": "ustaz_bantu_d" + str(TimeManager.day), "waktu": 40, "energi": -6, "mood": 5, "kenyang": 30, "rel": {"ustaz": 2}, "counter": {"bantu": 1}}, "ustaz_bantu3")
	_n("ustaz_bantu3", "", "Barisan mengular dari depan masjid sampai tiang listrik. Ada bapak ojol, ibu-ibu pulang pasar, dan seorang mahasiswa yang berpura-pura baru lewat. Pak Ustaz menyisihkan sebungkus untuk Dimas tanpa berkata apa-apa.")
	_n("ustaz_program", "Pak Ustaz Hilman", "Programnya baik, Nak. Tapi jamaah sepuh kami sulit lewat jalan yang ditutup waktu Jumatan, dan kabar program jarang sampai ke mereka. Mereka tahunya dari pengajian. Lampu jalan baru membantu sekali untuk jamaah Isya. Kalau boleh usul, pengumuman ditempel juga di masjid.", [], {"flag": "testimoni_ustaz", "mood": 1}, "ustaz_program2")
	_n("ustaz_program2", "", "Dimas mencatat: 'Pak Ustaz — jamaah lansia sulit lewat jalan tutup; kabar program jarang sampai ke mereka.'")


static func _hub_ujang(cnt: int) -> void:
	var ch: Array = []
	ch.append(_c("Pesan", "", {}, "menu_ujang"))
	ch.append(_c("Mang, gerobaknya keliling ke mana saja?", "ujang_rute"))
	ch.append(_c("Cuma lihat-lihat, Mang."))
	_n("hub", "Mang Ujang", _salam("ujang", cnt), ch)
	_n("ujang_rute", "Mang Ujang", "Dari Cibiru sampai Ujungberung, Aa. Sore nongkrong di sini karena dekat pos ronda dan masjid: pembeli datang sendiri. Dua puluh tahun dorong gerobak, kaki lebih hafal gang daripada saya sendiri.", [], {"mood": 1})


static func _hub_imam(cnt: int) -> void:
	var ch: Array = []
	ch.append(_c("Belanja", "", {}, "menu_imam"))
	ch.append(_c("Kok buka terus, Cak?", "imam_24jam"))
	ch.append(_c("Cuma lihat-lihat."))
	_n("hub", "Cak Imam", _salam("imam", cnt), ch)
	_n("imam_24jam", "Cak Imam", "Buka 24 jam itu bukan karena kami nggak butuh tidur, Mas. Tapi jam dua pagi pasti ada yang butuh mi instan, obat sakit kepala, atau cuma butuh orang untuk diajak ngobrol. Pelanggan malam itu jujur: nggak ada yang pura-pura kuat.", [], {"mood": 2})


# ---------------------------------------------------------------- Mas Yoga & pelanggan
static func _hub_yoga(cnt: int) -> void:
	var ch: Array = [
		_c("Cetak / fotokopi", "", {}, "menu_foto"),
		_c("Printernya baik-baik saja?", "yoga_printer"),
		_c("Permisi."),
	]
	_n("hub", "Mas Yoga", _salam("yoga", cnt), ch)
	_n("yoga_printer", "Mas Yoga", "Printer? Hidup segan, mati tak mau. Tapi selama masih bisa ngeluarin kertas, kita anggap sehat.")


static func _hub_pelanggan(npc: String, cnt: int) -> void:
	var w: Array = NewsSystem.warga_lines()
	var i: int = 0 if npc == "pelanggan1" else 1
	_n("hub", "Pelanggan", str(w[i % w.size()]))


# ---------------------------------------------------------------- pembuka
static func build_intro() -> void:
	nodes.clear()
	_n("intro_1", "", "Senin pagi di Gang Sukamaju. Hujan semalam masih menetes dari talang seng, dan kipas angin berputar dengan suara yang makin mirip pesawat tua.", [], {}, "intro_2")
	_n("intro_2", "{nama}", "Saldo… {uang}. Uang tinggal segini. Kalau beli ayam, besok makan apa? Kalau nggak beli ayam, hari ini makan apa?", [], {}, "intro_3")
	_n("intro_3", "", "Kiriman berikutnya baru masuk tanggal 14. Sewa kos jatuh tempo tanggal 20. Tugas pertama dikumpulkan Jumat. Dimas sudah punya rencana besar untuk semuanya. Sayangnya, rencana itu belum dimulai.", [], {}, "intro_4")
	_n("intro_4", "", "(WASD / panah: jalan • E: berinteraksi • Tab: ponsel • Enter / Spasi: memilih. Mulailah dari meja belajar… atau kasur. Terserah.)")


# ---------------------------------------------------------------- rapat warga
static func build_rapat() -> void:
	nodes.clear()
	var L: Array = []
	L.append(["Pak RW", "Terima kasih sudah hadir. Program Kampung Nyaman sudah berjalan beberapa minggu. Dari 12 kegiatan, 12 sudah terlaksana. Alhamdulillah."])
	L.append(["Teh Mira", "Pak, bolanya mulai jam sembilan."])
	L.append(["Pak RW", "Siap, kita cepat. Silakan warga menyampaikan tanggapan, satu per satu."])
	var tati: String = "Spanduknya bagus, jalannya mulus. Tapi biaya dapur Ibu naik: telur, gas, cabai. Apa ada program yang menyentuh pedagang kecil seperti Ibu?"
	if GameState.relasi("tati") >= 3:
		tati += " Nak {nama} sempat bantu Ibu ke pasar, dia lihat sendiri harga-harganya."
	L.append(["Bu Tati", tati])
	L.append(["Fikri", "Jalan dulu ditutup tiga hari. Buat saya itu tiga hari penghasilan berkurang. Bensin naik, ongkos tidak naik sebanding. Lampu jalan bagus, itu saya akui. Tapi saya tidak ingat ada yang tanya dulu soal jadwal penutupannya."])
	var rani: String = "Pos layanan buka Senin sampai Kamis jam sembilan sampai dua belas. Banyak warga yang jam segitu kuliah atau kerja. Daftarnya online, tapi berkas fisik tetap harus dibawa."
	L.append(["Rani", rani])
	if GameState.has_flag("rw_pertanyaan_rani"):
		L.append(["Pak RW", "Pertanyaan soal jam itu sudah saya teruskan ke kecamatan. Belum ada jawaban resmi, tapi sudah disampaikan."])
	if GameState.has_flag("hoax_cek"):
		L.append(["Kang Asep", "Truk pasokan telat waktu jalan ditutup. Tapi jalan barunya enak. Dan untung dulu Kang {nama} ngecek pesan soal beras. Saya hampir ikut menyebar."])
	elif GameState.has_flag("hoax_forward"):
		L.append(["Kang Asep", "Dulu ada pesan soal beras. Banyak yang ikut menyebar, termasuk saya hampir percaya. Mi instan saya habis dalam setengah jam. Kita perlu hati-hati dengan pesan berantai."])
	else:
		L.append(["Kang Asep", "Truk pasokan telat waktu jalan ditutup. Tapi jalan barunya enak. Untung ada yang jujur menyampaikan keluhan, bukan cuma pujian."])
	L.append(["Pak Ustaz Hilman", "Dari masjid, kami titip satu hal: jamaah yang sepuh jarang kebagian kabar program. Mohon pengumuman ditempel juga di masjid, dan jalan jangan ditutup bersamaan dengan jam Jumatan."])
	L.append(["Teh Mira", "Lampu jalan bikin warung saya lebih ramai. Tapi pos layanan itu: yang bertanya jam bukanya justru ke warung saya, bukan ke pos. Mungkin informasinya perlu ditaruh di tempat orang sering lewat."])
	L.append(["Pak Darto", "Saya cuma pemilik kos. Listrik penerangan jalan itu siapa yang bayar? Kalau iuran naik, anak-anak kos ikut kena."])
	L.append(["Pak RW", "Saya mengerti semua itu. Tapi saya harus jujur: kecamatan menilai laporan dari jumlah kegiatan dan dokumentasi. Itu format yang diminta. Saya bukan tidak mau mendengar. Saya terikat format."])
	L.append(["Pak RW", "Ada yang ingin menambahkan?"])
	for i in range(L.size()):
		var nxt: String = "r%d" % (i + 2)
		if i == L.size() - 1:
			nxt = "r_pilih"
		_n("r%d" % (i + 1), str(L[i][0]), str(L[i][1]), [], {}, nxt)
	var ch: Array = []
	if GameState.count_testimoni() >= 1:
		ch.append(_c("Saya sempat mencatat pengalaman beberapa warga. Boleh saya bacakan?", "r_catatan"))
	ch.append(_c("Pak, bolehkah laporan ditambah kolom 'masalah yang belum selesai'?", "r_usul"))
	ch.append(_c("Cukup, Pak. Saya mendengarkan saja.", "r_diam"))
	_n("r_pilih", "", "Semua mata beralih ke bangku belakang. Dimas menelan ludah. Es teh di tangannya sudah mencair sejak tadi.", ch)
	# catatan warga
	var baris: Array = []
	if GameState.has_flag("testimoni_tati"):
		baris.append("• Bu Tati: biaya dapur naik, belum ada bantuan untuk pedagang kecil.")
	if GameState.has_flag("testimoni_asep"):
		baris.append("• Kang Asep: keramaian naik, tapi pasokan telat saat jalan ditutup.")
	if GameState.has_flag("testimoni_rani"):
		baris.append("• Rani: jam pos layanan bentrok dengan kuliah dan kerja.")
	if GameState.has_flag("testimoni_fikri"):
		baris.append("• Fikri: penutupan jalan memotong penghasilan harian.")
	if GameState.has_flag("testimoni_mira"):
		baris.append("• Teh Mira: informasi jam layanan tidak ada di tempat orang lewat.")
	if GameState.has_flag("testimoni_ustaz"):
		baris.append("• Pak Ustaz: jamaah sepuh sulit lewat jalan tutup; kabar program jarang sampai ke mereka.")
	var teks: String = "Dimas membuka catatan di ponselnya dan membaca pelan:\n" + "\n".join(baris)
	var hasil: String = "hasil_campuran"
	var jawab: String = "Terima kasih, Nak. Ini masukan berharga. Akan saya lampirkan sebagai 'masukan warga' bersama laporan."
	if GameState.count_testimoni() >= 4:
		hasil = "hasil_baik"
		jawab = "Ini… lebih lengkap dari yang saya kira. Akan saya lampirkan sebagai 'Catatan Warga' dan saya minta kecamatan meninjau jam pos layanan. Untuk pertama kalinya, masalah warga ikut tercantum di laporan."
	_n("r_catatan", "", teks, [], {}, "r_catatan2")
	_n("r_catatan2", "Pak RW", jawab, [], {"flag": hasil}, "r_tutup")
	_n("r_usul", "Pak RW", "Kolom baru… Kecamatan mungkin tidak keberatan. Coba saya tanyakan. Kalau diizinkan, kita tulis: kegiatan selesai, dan masalah yang masih berjalan.", [], {"flag": ["hasil_campuran", "usul_kolom"]}, "r_tutup")
	_n("r_diam", "Pak RW", "Baik. Kalau begitu rapat ditutup. Laporan 12 dari 12 akan dikirim ke kecamatan. Terima kasih semuanya.", [], {"flag": "hasil_formal"}, "r_tutup")
	_n("r_tutup", "Teh Mira", "Alhamdulillah. Bolanya belum mulai. Ada yang mau nonton di warung saya?", [], {"waktu": 90, "flag": "rapat_hadir", "mood": 4})

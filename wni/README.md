# WNI: Hari-Hari Biasa — proyek Godot 4.7.2

Game cozy pixel-art tentang hidup biasa seorang mahasiswa di Gang Sukamaju, Bandung Timur.
Resolusi dasar 480x270. Kamar kos memakai latar pixel-art `assets/kos_room.png` (potongan melintang); lokasi lain masih placeholder kotak berwarna yang digambar lewat kode.

## Cara menjalankan
1. Buka Godot 4.7.2 → Import → pilih `project.godot`.
2. Tekan F5.

Kontrol: **WASD/Panah** jalan • **E** interaksi • **Tab** ponsel • **Enter/Spasi** memilih • **Esc** batal.

## Karakter
Dimas memakai sprite sheet asli yang sudah di-snap ke grid piksel aslinya (tepi tajam, tanpa blur), dibuat dalam tiga ukuran integer-rapi: tinggi 50 (gang), 62 (koridor, masjid, interior), dan 100 (kamar kos) di `assets/chars/dimas_*.png`. Pose: ponsel, garuk kepala (mengerjakan tugas), gestur bicara (dialog). Semua NPC punya sprite pixel-art gaya serupa (digambar prosedural, `tools/make_chars.py`) dengan idle 2 frame. Bila Anda punya sprite NPC asli, cukup timpa `assets/chars/<id>_<50|62|100>.png` (frame persegi berjajar horizontal, kaki di tengah bawah).

## Alur keluar-masuk kos
Kamar kos → pintu kamar → **koridor lantai 2** (`assets/koridor_bg.png`, pagar menyambung dan digambar di depan karakter) → tangga turun di ujung kanan → Gang Sukamaju. Pak Darto kini berada di koridor pada jam-jam tertentu. Benda di koridor yang bisa diinteraksi: pintu tetangga, rak sepatu, tempat sampah, tanaman, meteran listrik, jemuran.

## Gang Sukamaju (2D scrolling, kamera mengikuti)
Latar adalah gabungan dua gambar acuan yang disambung di kios Warung Madura (`tools/make_gang2.py`). Isi gang hanya: Kost (gerbang ke tangga), **Masjid Al-Ikhlas**, **Warung Madura** (cukup dari luar; tekan E untuk bicara dengan penjual: Kang Asep siang, Cak Imam malam, tanpa sprite penjual, lalu pilih belanja), dan **Pos ronda** (duduk ngobrol, nonton catur, selebaran). Rumah lain adalah rumah warga (tidak bisa dimasuki). Ambience: kabut pagi, burung, warga lewat, ayam kampung, kucing, lampu jendela malam. Tidak ada kendaraan di gang.

Ujung kanan gang → **Lapangan RW 05** (Bagian 2, dari `bagian2_part1_warteg_bu_tati_v8` + `bagian2_part2_balai_rw_v2`, disambung di lapangan bulutangkis oleh `tools/make_lapangan.py`):
- **Warteg Bu Tati**: tekan E di depan etalase → dialog Bu Tati lalu pesan makanan (tanpa sprite penjual). Papan menu & harga di kanan stan.
- **Balai RW 05**: tekan E di depan aula → dialog Pak RW (program, surat pengantar, paket, rapat). Jam layanan mengikuti jam kerja. Papan pengumuman RW memuat capaian program, pos layanan, undangan rapat. Rapat warga hari ke-27 berlangsung di halaman Balai.
- **Lapangan bulutangkis** (pukul kok sendirian atau ajak warga akrab sore hari), kentongan pos kamling, lapak baju obral, meteran listrik.

Ujung kanan lapangan → **Jalan Sukamaju** (masih placeholder): Fotokopi, Kopi Teh Mira, halte angkot/ojol ke kampus, gerobak Mang Ujang, dan lalu lintas. Ujung kiri tiap scene kembali ke scene sebelumnya.

## Skala karakter
Kamar kos: Dimas besar (sheet 150 px) dengan **efek perspektif**: makin ke bawah (mendekat ke kamera) makin besar, makin ke atas makin kecil. Gang & jalan: 75 px. Koridor: 62 px.

## Masjid
Adzan berbunyi pada jam salat (toast). Di dalam masjid: salat berjamaah (Zuhur, Ashar, Magrib, Isya; Jumat = Salat Jumat), wudu, baca Al-Qur'an, kotak amal. **Jumat Berkah**: tiap Jumat (hari 5, 12, 19, 26) setelah jumatan ±12.30 makanan gratis dibagikan di depan masjid (menu berbeda tiap pekan, cepat habis); Anda bisa membantu Pak Ustaz membagikan. Ada catatan warga ke-6 dari Pak Ustaz.

## Ponsel (Tab)
Berita & pesan, keuangan, tugas, hubungan dengan warga, catatan warga, jam buka & jadwal salat, scroll medsos.

## Isi game
- 28 hari (Senin–Minggu berulang), jam berjalan otomatis (1 hari ≈ 9 menit nyata), hujan sore.
- 8 lokasi: kamar kos, gang, warung Bu Tati, kelontong Kang Asep, fotokopi, Balai RW, kopi Teh Mira, kampus.
- 7 tokoh dengan jadwal harian, dialog dinamis, dan hubungan: Bu Tati, Kang Asep, Rani, Fikri, Pak Darto, Teh Mira, Pak RW (+ Mas Yoga).
- Ekonomi: uang, harga berubah karena berita (telur, BBM, cabai), stok habis karena rumor, tiga moda transportasi.
- Alur tugas kuliah: kerjakan → cetak di fotokopi → kumpulkan di kelas sebelum tenggat.
- Cerita: event berita harian → Program Kampung Nyaman → pendataan pengalaman warga → rapat warga (hari 27) → ending bercabang.
- Sampingan: kasbon & bantu belanja Bu Tati, paket Fikri, surat pengantar Pak RW (fotokopi KTP/KK), hoaks beras (forward/cek/abaikan), proyek bareng Rani.
- Simpan otomatis tiap tidur.

## Struktur
- `autoload/` — EventBus, GameState (status & efek), TimeManager, Economy, NewsSystem, SaveSystem.
- `scripts/game_data.gd` — **semua data**: barang, harga, lokasi, jadwal, tugas, event cerita. Mulai ubah dari sini.
- `scripts/dialogue_db.gd` — dialog dinamis tiap tokoh dan adegan rapat.
- `scripts/main.gd` — alur permainan, menu, tidur, ending.
- `scripts/location_view.gd`, `actor.gd`, `player.gd`, `hud.gd`, `ui_menu.gd`, `dialogue_box.gd`.

## Cara menambah konten
- **Event baru**: tambah entri di `GameData.EVENTS` (day, judul, isi, eff, kata, warga).
- **Barang**: tambah di `ITEMS` dan masukkan ke `MENU_*`.
- **Nama tokoh utama**: ditanyakan saat "Mulai baru" (bawaan: Dimas).
- **Keseimbangan**: `START_UANG`, `SEWA`, harga barang, dan `TimeManager.MENIT_PER_DETIK`.

## Belum ada (ide lanjutan)
Interior warung/Madura/fotokopi/balai/kopi/kampus masih placeholder, musik & suara hujan, kosakata Sunda lebih banyak (ditinjau penutur asli), lebih banyak sampingan.

Catatan: bagian akhir brief (rapat warga) terpotong di dokumen, jadi adegan rapat saya susun sendiri dari bab 6 — silakan sesuaikan.

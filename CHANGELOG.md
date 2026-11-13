# Perubahan (versi perbaikan & pendalaman)

## Bug & logika yang diperbaiki
- **Layar ending tidak terlihat**: lapisan fade hitam digambar di atas menu. Kini fade berada di bawah dialog/menu.
- **Rapat warga bisa diulang** tanpa batas (waktu +90 mnt, mood +4 tiap kali) → hanya sekali.
- **Spam galon & gardu** (energi/mood naik lebih cepat dari penurunan per jam) → dibatasi per hari.
- **Pingsan (energi 0) melompati satu hari penuh**, bahkan memicu ending di hari ke-28 → kini kehilangan 2,5 jam, energi pulih 35, hari berlanjut.
- **Jam kuliah tidak konsisten** (teks 08.00, kode 07.00) → 08.00–10.30, masuk 07.30–09.30, sekali sehari.
- **Adzan berbunyi di jam bulat** → kini tepat di awal waktu salat (11.45, 15.00, 17.55, 19.10).
- **Pemain tetap di dalam toko saat tutup** (fotokopi, Kopi Teh Mira) → dipersilakan keluar.
- `reset_smoothing()` dipanggil padahal smoothing kamera tidak aktif → kini aktif.
- Walker di lapangan berjalan di jalur yang salah; jendela Jumat Berkah di gambar tidak sama dengan logika (12.15–13.45).
- Setelah ending, waktu terus berjalan di layar judul.
- Hubungan Teh Mira / Cak Imam / Mas Yoga / Mang Ujang praktis tak bisa naik → kini naik lewat obrolan (tiap 3×) dan langganan (tiap 3 pembelian).
- Penyimpanan: validasi data, versi, serta menyimpan lokasi, posisi, dan cuaca.

## Fitur baru / dilengkapi
- **Token listrik** kini bermakna (7 hari/token): kompor mati, kerja di kos lebih lambat, kamar gelap saat padam; meteran berkedip merah.
- **Denda sewa** Rp50.000 setelah lewat masa toleransi (hari 25); status tampil di ponsel & dialog Pak Darto.
- **Kejutan pagi** acak-tapi-konsisten, **ringkasan pagi** lebih lengkap, **Rencana hari ini** di ponsel.
- **Kualitas tidur** tergantung jam tidur (18.00 → +60 energi, 24.00 → +84).
- **Payung** (Warung Madura): hujan di luar kini menguras energi tanpa payung.
- **13 pencapaian**, **rapor akhir** 0–100 dengan predikat S–D.
- **Menu jeda (Esc)**: simpan di tempat, pengaturan volume/layar penuh, kembali ke judul.
- Peringatan sekali saat energi/kenyang/mood kritis.

## Efek & suasana
- **Audio prosedural** (tanpa berkas audio): klik, ketik dialog, koin, langkah, pintu, adzan/bel, petir, hujan, jangkrik, kicau burung, dan musik latar siang/malam yang bisa diatur volumenya.
- Teks melayang berwarna untuk uang/energi/mood/hubungan; penanda `[E]` yang melayang di atas objek.
- Warna hhari-malam halus (kurva keyframe), **vignette** shader yang berdenyut merah saat kritis.
- Hujan 2 lapis + cipratan + **petir** dengan getar kamera; payung di tangan pemain; debu langkah.
- Banner nama lokasi, HUD baru (ikon cuaca, bar berkedip, uang berputar, bilah hari).
- Dialog dengan **potret karakter** dan pilihan via tombol angka.
- Ambient: kunang-kunang, uap warung, ngengat di lampu koridor, jendela kamar (bintang/hujan/lampu kota), debu di sinar matahari, kipas masjid, lampu depan kendaraan malam hari.

## Alat uji (opsional) — folder `tools/`
- `bot_test.gd`: bot acak yang memainkan game hingga hari ke-28 mencari error runtime.
- `logic_test.gd`: uji logika listrik, denda, skor, ending.
- `shot_test.gd`: tangkap layar skenario (perlu renderer, mis. xvfb).


## Konversi ke scene (lanjutan)
- **Lokasi jadi scene**: `scenes/maps/<id>.tscn` kini sumber data sebenarnya (spawn = Marker2D, objek = `Interactable`, pintu = `Pintu`, tepi = `TepiLokasi`, pagar & ayam sebagai node). `GameData.LOKASI` dihapus; arsipnya ada di `tools/lokasi_data.gd` hanya untuk generator `tools/bangun_peta.tscn`.
- **UI jadi scene**: `scenes/ui/hud.tscn`, `dialogue_box.tscn`, `ui_menu.tscn`, tema `tema.tres`, shader `shaders/vignette.gdshader`. Script memakai `%NamaUnik`, bukan membangun node lewat kode. `HUD.Ikon` dipisah jadi `HudIkon`.
- **Entitas jadi scene**: `scenes/entities/{npc,walker,ayam,motor,angkot}.tscn`; properti ayam/motor/pagar kini `@export`.
- **Perbaikan**: `angkot.gd` memuat JPG lewat `Image.load()` yang gagal setelah export. Gambar diproses sekali menjadi `assets/angkot.png` (`tools/make_angkot.py`).
- `scenes/sections/location.tscn` dihapus (digantikan peta); `world.tscn` memakai `maps/kos_room.tscn` + `Player` langsung.


## Dialog & cerita jadi data (sistem Naskah)
- **Semua dialog dipindah ke `data/naskah/*.naskah`** (11 tokoh, pelanggan, intro, rapat) dengan format teks yang mudah dibaca dan ditulis.
  Kondisi (`| jika hari>=3, !flag x`), efek (`efek: uang +5000, akrab.tati +1`), percabangan (`lanjut:` bersyarat), dan teks bergilir
  dinyatakan di berkas, bukan di kode. Panduan: `data/naskah/PANDUAN.md`.
- **Berita & tugas** (`GameData.EVENTS/TUGAS`) kini dari `berita.naskah` dan `tugas.naskah`.
- **Mesin baru** di `scripts/naskah/` (`Naskah`, `Syarat`, `Efek`, `DataCerita`); `DialogueDB` kini hanya pemilih simpul (±150 baris dari ±400).
- **Validator** `tools/cek_naskah.tscn`: galat dengan nama berkas+baris; peringatan untuk simpul yatim, flag salah ketik, pembicara asing.
- **Uji kesetaraan** `tools/uji_dialog.tscn`: dialog naskah identik dengan versi kode lama pada 600 keadaan acak x 13 tokoh + rapat + intro (0 beda).
- Catatan ekspor: tambahkan `data/naskah/*` pada filter non-resource di preset export.

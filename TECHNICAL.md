# Dokumentasi Teknis — WNI: Hari-Hari Biasa

Dokumen ini menjelaskan implementasi proyek berdasarkan kode yang ada. Ini ditujukan untuk pengembang yang ingin memahami arsitektur, menelusuri alur runtime, mengubah konten, atau menjalankan pemeriksaan manual.

## 1. Ringkasan teknis

- **Engine:** Godot 4.7 (fitur proyek mencantumkan `4.7`).
- **Bahasa:** GDScript; beberapa alat pembuat aset menggunakan Python.
- **Genre dan sudut pandang:** game 2D pixel-art, kamera side-view dengan pergerakan pemain pada sumbu X/Y.
- **Resolusi viewport:** 480×270, diperbesar ke jendela awal 1280×720 dengan stretch `canvas_items`.
- **Renderer:** Compatibility / GL Compatibility.
- **Scene utama:** `scenes/main.tscn`, berisi node `Main` dengan script `scripts/main.gd`.
- **Arsitektur scene:** `main.tscn` memakai section scene untuk dunia dan antarmuka. **Setiap lokasi adalah scene sungguhan** di `scenes/maps/<id>.tscn` (latar, spawn, objek, pintu, tepi, pagar, ayam sebagai node). UI (HUD, dialog, menu) juga scene di `scenes/ui/` dengan tema `tema.tres`. Yang tetap dibuat saat runtime hanya konten yang bergantung state: NPC terjadwal, pejalan kaki, dan kendaraan lewat (instance dari `scenes/entities/`).
- **Siklus permainan:** 28 hari; waktu berjalan pada laju 2 menit permainan per detik nyata selama permainan aktif dan UI tidak mengunci waktu.

File konfigurasi utama adalah [`project.godot`](./project.godot). Ringkasan pemain dan kontrol juga tersedia di [`README.md`](./wni/README.md).

## 2. Struktur proyek

```text
project.godot                 Konfigurasi aplikasi, renderer, viewport, dan autoload
scenes/
  main.tscn                   Menggabungkan section dunia dan antarmuka
  sections/
    world.tscn                CanvasModulate, lokasi awal (kos_room), Player, Camera2D
    interface.tscn            RainOverlay, Vignette (shader), HUD, Fade, DialogueBox, UIMenu; menerapkan tema
    player.tscn               Pemain dengan script Player
  maps/                       SATU SCENE PER LOKASI (sumber data lokasi yang sebenarnya)
    kos_room.tscn  koridor.tscn  gang.tscn  lapangan.tscn  jalan.tscn
    masjid.tscn  fotokopi.tscn  kopi_mira.tscn  kampus.tscn
  ui/
    tema.tres                 Tema global (panel, tombol)
    hud.tscn  dialogue_box.tscn  ui_menu.tscn
  entities/
    npc.tscn  walker.tscn  ayam.tscn  motor.tscn  angkot.tscn
shaders/
  vignette.gdshader
scripts/
  main.gd                     Orkestrasi game, alur, interaksi, dan ending
  game_data.gd                Data statis: item, NPC, jadwal, tugas, event (data lokasi sudah pindah ke scenes/maps)
  dialogue_db.gd              Pembuatan node dialog berdasarkan state
  location_view.gd            Logika lokasi: membaca node peta, interaksi, collider, NPC terjadwal, efek ambient
  interactable.gd, pintu.gd,
  tepi_lokasi.gd              Node data lokasi yang dapat diedit di editor (@tool)
  hud_ikon.gd                 Ikon cuaca/waktu pada HUD
  player.gd                   Gerakan dan animasi pemain
  actor.gd                    Rendering karakter/NPC berbasis sprite sheet
  hud.gd                      Status, prompt interaksi, toast, banner lokasi
  ui_menu.gd                  Menu pilihan dan input teks
  dialogue_box.gd             Kotak dialog, efek mengetik, pilihan
  rain_overlay.gd             Hujan, percikan, kilat, dan sinyal petir
  fence_layer.gd              Layer pagar koridor
  interact_marker.gd          Penanda objek/NPC yang dapat diinteraksi
  float_text.gd               Teks perubahan status yang melayang
  angkot.gd, motor.gd,
  walker.gd, ayam.gd          Entitas dekoratif bergerak
autoload/
  event_bus.gd                Sinyal lintas sistem
  game_state.gd               State sesi dan penerapan efek
  time_manager.gd              Jam, hari, kebutuhan berkala, dan cuaca
  economy.gd                  Harga dinamis, stok, dan biaya transportasi
  news_system.gd              Event harian dan komentar warga
  daily.gd                    Pemrosesan pagi dan ringkasan rencana
  save_system.gd              Serialisasi dan pemuatan save
  achievements.gd             Kondisi pencapaian
  audio_manager.gd            Efek audio, ambience, musik prosedural, pengaturan
assets/
  *.png                       Latar dan sprite karakter
  chars/                      Sprite sheet NPC/pemain pada beberapa ukuran
tools/
  *.gd                        Skrip tes otomatis/visual
  *.py                        Skrip pembentukan atau pemrosesan gambar
```

`.godot/` berisi cache/import editor lokal, bukan sumber data gameplay yang sebaiknya diedit manual. Berkas `.uid` dan `.import` dikelola Godot untuk identitas dan proses impor aset.

## 3. Bootstrap dan pohon runtime

### 3.1 Scene dan hierarki

`scenes/main.tscn` langsung menggabungkan `world.tscn` dan `interface.tscn`. `main.gd` mengambil node yang sudah ada dari kedua section itu. Pemain dan lokasi dibuat dari `player.tscn` serta `location.tscn`; saat berpindah lokasi, instance lokasi lama diganti dengan instance baru.

- `world.tscn`: `CanvasModulate`, root `World`, instance lokasi awal beserta pemain, dan `Camera2D`. Lokasi serta pemain terlihat di Scene panel dan dipakai sebagai instance awal runtime.
- Script lokasi dan aktor menyediakan preview editor khusus: `world.tscn` menampilkan background koridor dan sprite pemain tanpa memanggil setup runtime. Lokasi awal gameplay tetap kamar kos.
- `interface.tscn`: susunan overlay, HUD, fade, dialog, dan menu. Urutan child menentukan urutan gambar; fade berada di atas HUD, tetapi di bawah dialog dan menu.
- `maps/<id>.tscn`: root bertipe `LocationView` dengan properti Inspector (nama, ukuran, batas jalan, tinggi sprite, kecepatan, perspektif `depth`, lalu lintas/pejalan kaki, papan nama, jendela lampu) dan node anak:
  - `Latar` (Sprite2D, `show_behind_parent`): gambar latar; ganti tekstur langsung di Inspector.
  - `Entities` (y-sort): tempat pemain, NPC, ayam, kendaraan. `PlayerPratinjau` (grup `preview_editor`) hanya tampil di editor dan dibuang saat game jalan.
  - `Spawns/*` (Marker2D): titik muncul; nama marker = id spawn.
  - `Objek/*` (`Interactable`): kotak objek. Properti `label` (kosong = dekor), `solid`, `syarat_flag`, `warna`, `teks`. Nama node = id yang ditangani `main._objek()`.
  - `Pintu/*` (`Pintu`): `ke`, `spawn`, `nama_tujuan`, `label`.
  - `Tepi/*` (`TepiLokasi`): pindah lokasi di ujung kiri/kanan.
  - `Pagar` (`FenceLayer`, hanya koridor), `InteractMarker`.
  Semua kotak (Interactable/Pintu) tampil berwarna di editor: merah = penghalang, biru = bisa diinteraksi, kuning = pintu.
- Efek ambient yang bergantung jam/cuaca/state (kunang-kunang, uap, jendela malam, dll.) tetap digambar oleh `LocationView._draw()` karena dinamis.
- `main._load_location(id, spawn)` memuat `scenes/maps/<id>.tscn` dan memindahkan satu node `Player`; `spawn` kosong = spawn pertama.

### 3.2 Urutan awal

1. Godot memuat `scenes/main.tscn`.
2. Autoload dibuat sebagai singleton sebelum scene utama.
3. Scene utama memuat section dunia dan antarmuka. `Main._ready()` mengambil node-node tersebut, menginisialisasi pemain, serta memberi tema pada root UI.
4. `Main` menghubungkan sinyal `EventBus`, `TimeManager`, serta sinyal petir ke handler UI/visual.
5. `location.tscn` dimuat untuk lokasi kamar sebagai latar layar judul; waktu dihentikan.
6. Menu utama mengarahkan ke mulai baru, lanjutkan save, atau keluar.

Secara konseptual, pohon runtime utamanya berbentuk:

```text
Main
├── WorldSection (Node2D)
│   ├── CanvasModulate
│   └── World (Node2D)
│       ├── LocationView (instance location.tscn; berubah saat pindah lokasi)
│       │   ├── Entities (Node2D; y-sort)
│       │   │   ├── Player (instance player.tscn)
│       │   │   └── Actor / dekorasi bergerak
│       │   └── InteractMarker
│       └── Camera2D
└── InterfaceSection (CanvasLayer)
    └── Root (Control)
        ├── RainOverlay
        ├── Vignette (ShaderMaterial: shaders/vignette.gdshader)
        ├── HUD
        ├── Fade
        ├── DialogueBox
        └── UIMenu
```

UI ditambahkan berdasarkan urutan child sehingga urutan gambar penting. Fade sengaja berada di atas HUD tetapi di bawah dialog dan menu.

### 3.2 Mulai baru, lanjut, dan pindah lokasi

- **Mulai baru:** reset `GameState`, `TimeManager`, dan `Economy`; bersihkan nama; jalankan event hari pertama; hidupkan waktu; muat kamar; tampilkan intro dari `DialogueDB`.
- **Lanjut:** `SaveSystem.muat()` mengembalikan state, hari/jam/cuaca, ekonomi, lokasi, dan koordinat pemain. Lokasi dan spawn dimuat ulang, lalu posisi tersimpan diterapkan.
- **Pindah lokasi:** fade ke hitam, panggil `_load_location()`, lalu fade kembali. Pemain yang sama dipindahkan ke `entities` lokasi baru.
- **Tidur:** memulihkan energi (atau menerapkan penalti jika tertidur paksa), mengurangi kenyang, memajukan hari, memperbarui stok/event/proses pagi, memuat kamar, lalu menyimpan otomatis.

## 4. Sistem global (autoload)

Nama singleton harus tetap konsisten dengan deklarasi di `[autoload]` pada `project.godot`; kode merujuknya langsung sebagai global.

| Singleton | Tanggung jawab | Data/API yang perlu diketahui |
|---|---|---|
| `EventBus` | Komunikasi antarsistem dengan sinyal | `stats_changed`, `hour_changed`, `rain_changed`, `toast`, `popup`, `waktu_maju`, `pencapaian` |
| `GameState` | State permainan yang berubah selama sesi | `uang`, `energi`, `kenyang`, `mood`, `utang`, `flags`, `timed_flags`, `rel`, `inv`, `tugas`, `counters`, `news_log`, `talk_count` |
| `TimeManager` | Jam dan hari permainan | `day`, `minutes` (menit sejak tengah malam), `raining`, `running`, `advance()`, `new_day()` |
| `Economy` | Harga dan ketersediaan | `mult` (pengali per tag), `habis` (stok habis sementara), `harga()`, `tersedia()`, `transport()` |
| `NewsSystem` | Menerapkan event sesuai hari | `run_day()`, `komentar()`, `warga_lines()` |
| `Daily` | Aturan harian | sewa, token listrik, kejutan pagi, pengingat dan rencana hari ini |
| `SaveSystem` | Save/load lokal | `simpan()`, `muat()`, `ada()`, `hapus()` |
| `Sfx` | Audio dan preferensi audio/tampilan | `play()`, `set_ambience()`, `apply_settings()`, `simpan_pengaturan()` |
| `Ach` | Evaluasi pencapaian | `cek()`, `sudah()`, `jumlah()`, `DAFTAR` |

### 4.1 Sinyal `EventBus`

- `stats_changed`: state pemain berubah; HUD membaca ulang nilai.
- `hour_changed(hour)`: dipancarkan setiap jam penuh. Dipakai untuk refresh jadwal NPC, ambience, penutupan lokasi, dan efek per jam.
- `rain_changed(is_raining)`: transisi kondisi hujan.
- `toast(text)`: notifikasi singkat.
- `popup(text, color)`: teks perubahan status di dekat pemain.
- `waktu_maju(dari, ke)`: rentang menit yang telah dilalui; dipakai untuk menemukan waktu adzan di antara jam bulat.
- `pencapaian(nama)`: pencapaian baru untuk toast dan efek audio.

Gunakan sinyal untuk pemberitahuan lintas sistem, bukan untuk menyimpan state utama. Nilai state tetap berada pada singleton yang bertanggung jawab.

### 4.2 Kontrak efek `GameState.apply_effects()`

Efek adalah `Dictionary` yang dapat menggabungkan beberapa perubahan sekaligus:

```gdscript
GameState.apply_effects({
    "uang": -5000,
    "energi": -10,
    "kenyang": 20,
    "mood": 2,
    "waktu": 15,
    "flag": "aksi_selesai",
    "flag_hari": "sudah_mandi",
    "timed": {"jalan_ditutup": 12},
    "rel": {"tati": 1},
    "inv": {"mi_instan": -1},
    "counter": {"masak": 1},
    "tugas": {"t1": 25},
})
```

Kunci yang dikenali:

- `uang`: perubahan uang; tidak dibatasi.
- `energi`, `kenyang`, `mood`: perubahan dibatasi 0–100.
- `utang`: perubahan utang; hasil tidak boleh kurang dari nol.
- `waktu`: menit yang diteruskan ke `TimeManager.advance()`.
- `flag`: nama flag atau array nama flag permanen.
- `flag_hari`: nama flag yang disimpan sebagai `<nama>_d<hari>`.
- `timed`: dictionary nama flag → hari terakhir berlaku; `has_flag()` membandingkannya dengan hari sekarang.
- `rel`: perubahan hubungan per ID NPC, dibatasi 0–10.
- `inv`: perubahan jumlah item, dibatasi minimum nol.
- `tugas`: perubahan progres per ID tugas, dibatasi 0–100.
- `counter`: perubahan counter numerik.

`silent = true` mencegah popup perubahan status, tetapi sinyal `stats_changed` tetap dikirim. Efek `waktu` dapat menyebabkan handler waktu berjalan saat efek lainnya sedang diproses; pertimbangkan urutan ini bila menambah efek gabungan.

## 5. Data permainan dan skema konten

[`scripts/game_data.gd`](./scripts/game_data.gd) adalah sumber data statis. `GameData` mewarisi `RefCounted`, bukan singleton; dipakai melalui `class_name GameData` dan konstanta/fungsi statis.

Data utama:

- `HARI`, `START_UANG`, `SEWA`, `SEWA_TEMPO`, `SEWA_TOLERANSI`, `SEWA_DENDA`, `LISTRIK_AWAL`, `JUMLAH_HARI`, `HARI_RAPAT`.
- `NPC`, `NPC_LIST`, dan `RAPAT_POS`.
- `ITEMS`, menu pedagang, `TOKO_MADURA`, dan `TRANSPORT`.
- `TUGAS`.
- `LOKASI`, jadwal NPC, jam buka, kalender salat, dan `EVENTS`.

### 5.1 Definisi lokasi (scene peta)

Lokasi tidak lagi didefinisikan sebagai dictionary. Setiap lokasi adalah scene `scenes/maps/<id>.tscn` dengan root `LocationView`.
Cara menambah/mengubah:

- **Ganti latar**: pilih node `Latar`, ubah `texture`. **Objek**: geser/ubah ukuran node di `Objek/` (`Interactable`); `label` kosong = dekor.
  **Titik muncul**: `Marker2D` di `Spawns/`. **Pintu**: node `Pintu` (`ke`, `spawn`, `nama_tujuan`). **Tepi**: node `TepiLokasi`.
- Id objek = nama node, dan harus ditangani di `main._objek()` bila `label` diisi.
- Lokasi baru: duplikat scene peta yang mirip, ganti `loc_id`, `nama`, `ukuran`, lalu tambahkan jadwal NPC di `GameData.jadwal()`.

### 5.2 Pintu dan sambungan tepi

`Pintu.ke` + `Pintu.spawn` menunjuk ke id peta dan nama `Marker2D` tujuan. `TepiLokasi` (arah `kiri`/`kanan`) membuat pemain pindah lokasi
saat berjalan sampai ujung. `main._load_location(id, spawn)` memuat scene dan menempatkan pemain; `spawn` kosong = spawn pertama.

### 5.3 Jadwal dan jam buka

- `GameData.jadwal(npc, day, jam)` menghasilkan dictionary `{loc, pos}` atau dictionary kosong.
- `LocationView.refresh()` membuat ulang NPC sesuai lokasi dan waktu saat itu.
- `hour_changed` memicu refresh; perpindahan NPC terjadi pada batas jam, bukan setiap menit.
- `GameData.buka(loc, day, jam)` menjadi aturan utama untuk usaha/fasilitas tertentu.
- `INTERIOR_JAM` dipakai untuk mengeluarkan pemain dari interior yang sudah tutup pada pemeriksaan waktu terkait.

### 5.4 Menambahkan item dan menu

Tambahkan ID item di `GameData.ITEMS`. Field yang umum dipakai:

- `nama`, `harga`, `tag`: nama, harga dasar, dan kelompok harga dinamis.
- `kenyang`, `energi`, `mood`: efek konsumsi.
- `inv`: item yang ditambahkan ke inventaris.
- `instan`: efek langsung saat pembelian, misalnya token listrik.
- `counter`: counter yang bertambah saat pembelian.
- `upgrade`: nama flag upgrade permanen.
- `mood_up`: bonus mood khusus pembelian upgrade.

Masukkan ID tersebut ke array menu atau kategori toko. Periksa alur `Main._menu_makan()`, `_belanja_kat()`, atau handler aktivitas terkait: bentuk efek pembelian ditentukan oleh kode, bukan sepenuhnya oleh data item. Untuk tipe item baru, implementasikan dan uji handler-nya.

Harga akhir dibulatkan ke kelipatan Rp500. Tag event di `Economy.mult` mengalikan harga item dan transportasi dengan tag yang sama; tag kosong menggunakan pengali default.

### 5.5 Berita dan kejadian harian

Ada di `data/naskah/berita.naskah` (bukan lagi di `GameData`). `GameData.EVENTS` dan `GameData.TUGAS` adalah `static var` yang diisi
`DataCerita` dari berkas naskah. Cara menulisnya: lihat `data/naskah/PANDUAN.md`.

## 6. Sistem gameplay

### 6.1 Waktu, kebutuhan, dan cuaca

- `TimeManager.minutes` menyimpan menit sejak pukul 00.00; sesi baru dimulai pada menit 360 (06.00).
- `_process()` memajukan waktu berdasarkan `MENIT_PER_DETIK = 2.0`.
- Waktu berhenti jika `running == false` atau `GameState.ui_open == true`.
- Setiap pergantian jam penuh mengurangi energi 3 dan kenyang 5. Jika kenyang di bawah 20, mood turun 2; jika kenyang nol, energi turun lagi 3.
- Pola hujan ditentukan secara deterministik dari hari dan jam pada sore hari, dengan pola tambahan pada malam tertentu.
- Saat berada di luar ketika hujan, `Main` mengurangi energi per jam; payung mengurangi penalti.
- Adzan diperiksa dari rentang menit `waktu_maju`, agar dapat berbunyi pada menit tertentu, tidak hanya pada jam penuh.
- Saat waktu mencapai/melewati 24.00 atau energi menjadi nol, alur utama memaksa tidur/pingsan.

### 6.2 Ekonomi dan kebutuhan harian

- Uang dan utang disimpan di `GameState`.
- Harga dasar ada di `GameData.ITEMS`; `Economy.harga()` menerapkan pengali tag dan pembulatan.
- Event berita dapat mengubah pengali harga atau menandai item habis selama beberapa hari.
- Transportasi menawarkan jalan kaki, angkot, dan ojol. Hujan, penutupan jalan, rute angkot, serta hubungan dengan Fikri dapat mengubah biaya/waktu/energi.
- Sistem pagi mengurangi sisa token listrik dan menerapkan konsekuensi denda sewa setelah masa toleransi. Detail nominal dan tanggal ada pada konstanta `GameData`.
- Sistem kejutan pagi memakai seed berdasarkan hari; hasilnya konsisten untuk hari yang sama.

### 6.3 Tugas kuliah

Empat tugas berada di `GameData.TUGAS`, masing-masing dengan hari mulai dan tenggat. State tiap tugas di `GameState.tugas` berisi:

```text
progress: int (0..100)
dicetak: bool
dikumpul: bool
nilai: int (-1 jika belum dinilai)
```

Siklus implementasi:

1. Kerjakan di kamar atau lokasi belajar.
2. Progress bertambah berdasarkan kondisi pemain, upgrade, listrik, mood, dan kemungkinan distraksi.
3. Cetak saat tugas mencapai 100%; proses memakai uang dan waktu.
4. Kumpulkan di ruang kelas pada hari kerja. Ketepatan terhadap tenggat menentukan nilai dan counter pencapaian.

### 6.4 NPC dan hubungan

- Data identitas, nama, warna, dan daftar NPC berada di `GameData.NPC`.
- Posisi/waktu ditentukan oleh `GameData.jadwal()`.
- Dialog hub dibangun oleh `DialogueDB.hub()` sesuai ID NPC, hari, jam, jumlah percakapan, flag, hubungan, dan berita terbaru.
- Hubungan disimpan sebagai angka 0–10. Percakapan rutin atau aksi cerita dapat mengubahnya.
- NPC yang menjadi dekorasi/walker tidak selalu menyediakan jalur dialog utama.

### 6.5 Dialog dan aksi dialog (sistem Naskah)

Seluruh dialog ada di `data/naskah/*.naskah`; panduan penulis: `data/naskah/PANDUAN.md`.

| Komponen | Berkas | Tugas |
|---|---|---|
| `Naskah` | `scripts/naskah/naskah.gd` | Membaca berkas `.naskah` menjadi struktur simpul, melaporkan galat dengan `berkas:baris` |
| `Syarat` | `scripts/naskah/syarat.gd` | Mengurai dan mengevaluasi kondisi `| jika ...` |
| `Efek` | `scripts/naskah/efek.gd` | Mengurai `efek: ...` menjadi dictionary untuk `GameState.apply_effects()` |
| `DataCerita` | `scripts/naskah/data_cerita.gd` | Berita dan tugas dari naskah ke `GameData.EVENTS/TUGAS` |
| `DialogueDB` | `scripts/dialogue_db.gd` | Memulai percakapan (`hub`, `build_intro`, `build_rapat`) dan menyelesaikan simpul saat ditampilkan (`ambil`) |
| `DialogueBox` | `scripts/dialogue_box.gd` | Menampilkan simpul: ketik, potret, pilihan, menjalankan efek dan aksi |

Alur: `main._bicara(npc)` -> `DialogueDB.hub(npc)` memilih berkas `<npc>.naskah` -> `DialogueBox.run("hub")` memanggil `DialogueDB.ambil(id)`
berulang. Simpul diselesaikan **saat ditampilkan** (kondisi memakai keadaan terbaru). `aksi` dikembalikan ke `main._aksi()` yang mengerjakan fitur
(belanja, rapat, dll.); daftar aksi yang sah = cabang `match` di `_aksi` dan diperiksa validator.

Pengujian: `tools/cek_naskah.tscn` (validator: tujuan simpul, aksi, kunci, kondisi, flag typo, simpul yatim) dan `tools/uji_dialog.tscn`
(kesetaraan dengan `tools/dialog_lama.gd`, versi kode lama; 37.801 pembandingan, 0 beda saat migrasi).

### 6.6 Pencapaian dan ending

`Ach.DAFTAR` mendeklarasikan pencapaian; `Ach.terpenuhi()` berisi aturan aktual. `Ach.cek()` menandai flag `ach_<id>` dan mengirim sinyal pencapaian. Sistem diperiksa setelah aktivitas tertentu dan saat perubahan gameplay.

Skor ending dihitung di `Main._hitung_skor()`. Komponennya mencakup tugas selesai dan tepat waktu, sewa, testimoni, kehadiran rapat, uang/utang, mood, pencapaian, dan kehadiran kuliah. Jangan menganggap skor sebagai turunan dari seluruh counter: rumus eksplisit di fungsi tersebut adalah sumber kebenarannya.

## 7. Input dan UI

### Kontrol

| Input | Aksi |
|---|---|
| WASD / tombol panah | Bergerak |
| E | Interaksi dengan target terdekat |
| Tab | Buka ponsel |
| Esc | Menu jeda |
| Enter / Spasi | Memilih/melanjutkan dialog atau menu |
| Klik / panah / angka | Memilih opsi sesuai kontrol `UIMenu` dan `DialogueBox` |

Pemain hanya membaca input gerak saat UI tidak terbuka. `Main` menangani tombol aksi global melalui `_unhandled_input()`. Menu dan dialog memiliki penanganan input pilihan sendiri.

### HUD

HUD menampilkan hari/jam, uang, energi, kenyang, mood, tugas/tenggat, token listrik, lokasi, prompt interaksi, toast, dan banner lokasi. Status berasal dari singleton; HUD bukan sumber kebenaran state.

### Ponsel

Menu ponsel menyediakan rencana hari ini, berita/pesan, keuangan, tugas, hubungan warga, catatan/testimoni, jam buka dan salat, pencapaian, serta aksi scroll media sosial yang mengonsumsi waktu.

## 8. Rendering, aset, dan audio

### Rendering dan karakter

- Lokasi memakai tekstur latar bila field `bg` tersedia dan teksturnya dapat dimuat; lokasi lain digambar dari bentuk/data objek di `LocationView`.
- Node `entities` mengaktifkan Y-sort sehingga karakter diurutkan berdasarkan posisi vertikal.
- `Actor` membaca sprite `res://assets/chars/<id>_<tinggi>.png`; tinggi yang dipakai ditentukan oleh lokasi. Sprite sheet berupa frame persegi horizontal.
- `Player` menambahkan animasi jalan, pose khusus, debu langkah, dan payung saat hujan.
- `CanvasModulate` mengubah tint berdasarkan waktu; vignette dan `RainOverlay` ditambahkan sebagai elemen layar.
- Beberapa entitas bergerak adalah dekorasi visual dan bukan sistem navigasi/traffic simulation.

### Aset dan generator

Aset yang tersedia mencakup latar kamar, koridor, gang, masjid, lapangan, serta sprite karakter. Script di `tools/` membantu membuat atau memproses gambar karakter dan latar. Jika mengganti sprite, pertahankan nama berkas, suffix ukuran, format frame horizontal, dan dimensi cell yang sesuai dengan loader.

### Audio

`audio_manager.gd` membangkitkan efek, ambience, hujan/jangkrik, dan musik melalui kode; tidak semua suara berasal dari berkas audio terpisah. Pengaturan volume dan fullscreen disimpan di `user://wni_settings.cfg`. Save permainan dan pengaturan adalah dua berkas yang berbeda.

## 9. Save/load dan persistensi

Save permainan berada di `user://wni_save.json`; versinya saat ini `2`. Bentuk tingkat atas yang ditulis adalah:

```json
{
  "versi": 2,
  "gs": {},
  "day": 1,
  "minutes": 360,
  "raining": false,
  "mult": {},
  "habis": {},
  "loc": "kos_room",
  "px": -1.0,
  "py": -1.0
}
```

`gs` dihasilkan oleh `GameState.to_dict()` dan mencakup nama, uang, stat pemain, flag, timed flag, hubungan, inventaris, tugas, counter, log berita, dan jumlah percakapan. Save juga menyimpan hari/jam/cuaca, pengali harga, stok habis, lokasi, dan posisi pemain.

Perilaku pemuatan:

- JSON harus dapat diparse menjadi dictionary dan memiliki `gs`, `day`, serta `minutes`.
- Hari dan menit dibatasi ke rentang yang diizinkan.
- Lokasi yang tidak dikenal diganti menjadi `kos_room`.
- State direset terlebih dahulu lalu diisi dari save agar field baru punya default.
- Save tidak memuat posisi pemain ke `GameState`; posisi ditangani oleh `SaveSystem.last_pos` dan `Main._lanjut()`.

**Catatan kompatibilitas:** `VERSI` disimpan tetapi kode yang dibaca belum melakukan migrasi berdasarkan nomor versi. Saat mengubah bentuk data save, tambahkan penanganan default/migrasi di `GameState.from_dict()` atau `SaveSystem.muat()` dan pertahankan kompatibilitas dengan save lama.

## 10. Menjalankan dan menguji

### Membuka game

1. Buka Godot 4.7.
2. Import proyek dengan memilih `project.godot`.
3. Jalankan project (F6 untuk scene aktif atau F5 untuk main scene).

### Skrip tes yang tersedia

Komentar pada skrip memberikan contoh pemanggilan:

```text
godot --headless --path . --script res://tools/logic_test.gd
godot --headless --path . --script res://tools/bot_test.gd -- 120
```

- `tools/logic_test.gd`: pemeriksaan logika terarah untuk token listrik, denda, efek, rencana harian, skor, dan tampilan ending.
- `tools/bot_test.gd`: bot acak untuk mencari error runtime dengan `Engine.time_scale` dinaikkan.
- `tools/shot_test.gd`: tangkapan layar skenario visual; komentar dalam file menyebut kebutuhan renderer dan output `/tmp/shots`, jadi jalur tersebut perlu disesuaikan saat menjalankan pada Windows.

Skrip-skrip tersebut merupakan alat proyek, bukan bukti bahwa seluruh gameplay telah tercakup oleh automated test. Untuk perubahan konten, validasi minimal: jalankan proyek, mainkan alur terkait, periksa error Godot, dan uji save/load bila perubahan menyentuh state.

## 11. Panduan perubahan berdasarkan kebutuhan

| Kebutuhan | Berkas utama | Periksa juga |
|---|---|---|
| Mengubah harga, item, lokasi, jadwal, tugas, event | `scripts/game_data.gd` | `scripts/main.gd`, `autoload/economy.gd` |
| Mengubah percakapan atau syarat pilihan | `scripts/dialogue_db.gd` | `scripts/main.gd` (`_aksi`) |
| Mengubah aturan stat, flag, inventaris, efek | `autoload/game_state.gd` | `autoload/time_manager.gd`, pemanggil `apply_effects()` |
| Mengubah waktu/hujan/biaya kebutuhan per jam | `autoload/time_manager.gd` | `scripts/main.gd` (handler jam/cuaca) |
| Mengubah transaksi/harga | `autoload/economy.gd` | `scripts/main.gd` (menu pembelian) |
| Mengubah layar/status UI | `scripts/hud.gd`, `scripts/ui_menu.gd`, `scripts/dialogue_box.gd` | `scripts/main.gd` (pembuatan/visibilitas) |
| Mengubah gerak/karakter/visual map | `scripts/player.gd`, `scripts/actor.gd`, `scripts/location_view.gd` | `scripts/game_data.gd`, aset |
| Mengubah save schema | `autoload/save_system.gd`, `autoload/game_state.gd` | Uji save lama dan save baru |
| Menambah pencapaian | `autoload/achievements.gd` | Counter/flag yang mengukur syarat |
| Mengubah audio/pengaturan | `autoload/audio_manager.gd` | Pemanggil `Sfx.play()` dan pengaturan UI |

## 12. Batasan dan perbedaan dokumentasi

Hal berikut adalah catatan implementasi, bukan jaminan perilaku masa depan:

1. README berada di `wni/README.md` dan menjelaskan konsep/fitur. Kode `GameData.LOKASI` saat ini mendefinisikan sembilan map: kamar, koridor, gang, lapangan, jalan, masjid, fotokopi, kopi Mira, dan kampus. Warteg, Balai RW, dan Warung Madura direpresentasikan sebagai objek/titik interaksi pada map, bukan map interior terpisah.
2. Visual beberapa lokasi digambar dari kode/placeholder; keberadaan data lokasi tidak berarti setiap lokasi memiliki aset latar khusus.
3. README menyebut audio sebagai pekerjaan lanjutan, sedangkan kode audio prosedural telah tersedia di `autoload/audio_manager.gd`. Ini mungkin perbedaan status dokumentasi atau cakupan konten audio, jadi periksa implementasi terbaru sebelum menyimpulkan.
4. `GameData.OUTDOOR` saat ini memasukkan `koridor`, walaupun koridor digambarkan sebagai ruang dalam/area semi-terbuka. Kode yang memakai daftar ini dapat memperlakukannya sebagai lokasi luar untuk efek terkait.
5. `Main` memegang banyak dispatch aksi dan alur cerita sekaligus. Perubahan besar pada gameplay sebaiknya mempertimbangkan pengujian regresi karena perubahan satu aksi dapat berinteraksi dengan waktu, dialog, stat, dan pencapaian.
6. Status dan teks README dapat tertinggal dari implementasi. Gunakan konstanta dan fungsi kode sebagai sumber kebenaran untuk perilaku runtime.

## 13. Glosarium

- **Flag:** penanda cerita/perilaku; dapat permanen, hanya untuk hari berjalan, atau berlaku sampai hari tertentu.
- **Counter:** angka agregat untuk menghitung kejadian seperti memasak, hadir kuliah, atau donasi.
- **Efek:** dictionary perubahan state yang diproses terpusat oleh `GameState.apply_effects()`.
- **Interactable:** objek, pintu, atau NPC yang berada dalam jangkauan interaksi pemain.
- **Spawn:** nama titik koordinat untuk kedatangan pemain pada map tertentu.
- **Tag harga:** kategori seperti `telur`, `bbm`, atau `sayur` yang digunakan event untuk mengubah harga.
- **`user://`:** direktori data pengguna Godot untuk save/pengaturan, terpisah dari folder aset proyek.

## 14. Referensi kode per berkas

Bagian ini merinci source yang ditemukan dalam proyek. Nama API merujuk pada implementasi saat dokumentasi dibuat; untuk perilaku aktual, buka source yang ditautkan.

### 14.1 Entry point dan orkestrasi — `scripts/main.gd`

`Main` adalah pengatur alur paling atas. Script ini membuat objek UI/world secara dinamis dan menghubungkan subsistem; ia bukan tempat penyimpanan data konten utama.

| Kelompok | Fungsi | Peran |
|---|---|---|
| Inisialisasi | `_ready()`, `_tema()` | Membuat node runtime, tema, lokasi awal, koneksi sinyal, lalu membuka layar judul. |
| Siklus sesi | `_title()`, `_mulai_baru()`, `_lanjut()` | Menangani menu awal, reset state/intro, dan pemulihan save. |
| Map | `_fade()`, `_load_location()`, `_pindah()`, `_banner_lokasi()` | Mengganti instance `location.tscn`, menempatkan pemain, mengatur kamera, dan menampilkan nama lokasi. |
| Event & presentasi | `_on_hour()`, `_on_waktu()`, `_on_pencapaian()`, `_on_thunder()`, `_on_popup()`, `_update_popup()`, `_on_rain()` | Menerjemahkan perubahan waktu/cuaca/status menjadi refresh NPC, ambience, adzan, notifikasi, efek kamera, dan teks terapung. |
| Visual waktu | `_tint()`, `_ambience()`, `_update_vignette()` | Mengatur warna waktu, vignette kondisi pemain, dan teks suasana lokasi. |
| Loop utama | `_process()` | Menyelaraskan kamera dan HUD, kondisi visual, prompt, target terdekat, perpindahan tepi, pingsan, dan pengusiran dari interior yang tutup. |
| Interaksi | `_titik_marker()`, `_tepi_dekat()`, `_lewat_tepi()`, `_cari_dekat()`, `_unhandled_input()`, `_interact()`, `_handle()` | Mencari target, memperlihatkan prompt, membaca E/Tab/Esc, dan mendispatch pintu/NPC/objek. |
| Menu/dialog | `_jeda()`, `_pengaturan()`, `_phone()`, `_bicara()`, `_info()`, `_say()` | Menjeda waktu melalui `GameState.ui_open`, membuka ponsel/pengaturan, dan mengadaptasi dialog/menu. |
| Aksi dialog | `_aksi()` | Memetakan string aksi dari node dialog ke transaksi, rapat, salat, TV, dan aksi permainan lain. |
| Toko/kuliah | `_langganan()`, `_menu_makan()`, `_belanja()`, `_belanja_kat()`, `_kerja()`, `_kerja_inner()`, `_fotokopi()`, `_kelas()`, `_transport()` | Menjalankan pembelian, progres tugas, cetak/kumpul, kehadiran, dan perjalanan ke kampus. |
| Objek/lokasi | `_objek()`, `_tetangga()`, `_salat()`, `_amal()`, `_jumat_berkah()`, `_gardu()`, `_selebaran()`, `_lapangan()`, `_kasur()`, `_rak()`, `_jendela()`, `_papan_info()`, `_papan_balai()`, `_tv()` | Berisi logika interaksi khusus objek: kebutuhan kos, fasilitas, ibadah, olahraga, informasi dan NPC sekitar. |
| Ponsel | `_ponsel()` | Membuat sub-menu status, berita, uang, tugas, hubungan, testimoni, jadwal dan pencapaian. |
| Akhir hari/bulan | `_tidur()`, `_pagi()`, `_rapat()`, `_hitung_skor()`, `_ending()` | Memajukan hari, menampilkan ringkasan, menjalankan rapat dan menghasilkan ending/skor. |
| Kondisi darurat | `_cek_peringatan()`, `_pingsan()`, `_usir()` | Memberi peringatan status kritis, menangani energi nol, serta memindahkan pemain keluar dari usaha yang tutup. |

Target objek dicari berdasarkan jarak: NPC memakai radius lebih besar daripada objek, dan radius dikalikan `view.skala`. Objek memakai jarak ke titik terdekat pada rectangle interaksi. Jika beberapa target terjangkau, target dengan jarak terkecil dipilih. Transisi tepi terjadi ketika koordinat X melewati ambang lokasi; konfigurasi tepi menyediakan map tujuan dan spawn.

`Main._process()` sengaja tidak menerima aksi baru saat `busy`. Operasi yang menunggu dialog/menu biasanya menaikkan `busy` dan `GameState.ui_open`, lalu mengembalikan keduanya sesudah operasi selesai. Saat menambah cabang async baru, pastikan kedua state pulih pada semua jalur keluar.

### 14.2 Data dan aturan kalender — `scripts/game_data.gd`

`GameData` menyediakan data statis bersama melalui `class_name`. Bagian-bagiannya:

- Kalender dasar, batas ekonomi, durasi permainan, dan klasifikasi outdoor.
- Palet/identitas NPC dan daftar ID NPC yang dapat dijadwalkan.
- Posisi tetap peserta saat rapat.
- Definisi item dan menu usaha, stok toko Madura, serta biaya/waktu/energi transportasi.
- Empat definisi tugas dengan tanggal mulai/tenggat.
- Sembilan definisi map beserta spawn, pintu, objek, collision, interaksi, dan data visual.
- Jadwal NPC, jam buka, kalender salat Jumat, event berita/pribadi, serta progres kegiatan kampung.

Fungsi statis:

| Fungsi | Hasil |
|---|---|
| `_j(loc, x, y)` | Membuat pasangan map dan posisi untuk jadwal. |
| `jadwal(npc, day, jam)` | Lokasi/posisi NPC saat itu atau dictionary kosong. |
| `buka(loc, day, jam)` | Boolean jam layanan. |
| `jam_buka(loc)` | Teks jam buka untuk notifikasi. |
| `rp(n)` | Format angka sebagai rupiah dengan titik ribuan. |
| `event_by_id(id)` | Event pertama yang ID-nya cocok atau dictionary kosong. |
| `hari_jumat(day)` | Memeriksa hari dalam siklus mingguan. |
| `salat_sekarang(day, minutes)` | Informasi salat yang sedang berlangsung atau kosong. |
| `salat_berikutnya(minutes)` | Label waktu salat terdekat dari tabel salat. |
| `kegiatan_selesai(day)` | Menghitung milestone capaian program berdasarkan tabel hari. |

Karena konstanta item/lokasi/event berisi dictionary dan array bersarang, perubahan skema di satu definisi harus diselaraskan dengan consumer: `LocationView`, `Economy`, `NewsSystem`, `DialogueDB`, atau `Main`.

### 14.3 Dialog — `scripts/dialogue_db.gd` dan `scripts/dialogue_box.gd`

#### `DialogueDB`

- `nodes` adalah dictionary statis node percakapan aktif. Builder membersihkannya dan membangun ulang konten untuk percakapan tertentu.
- `fill()` mengganti placeholder nama pemain dan uang.
- `_n()` membangun node; `_c()` membangun pilihan.
- `_salam()` memilih sapaan berdasarkan jam lalu menambahkan komentar event terbaru.
- `solo()` membuat dialog satu baris/adegan dengan efek opsional.
- `hub(npc)` menambah jumlah obrolan, kadang menaikkan hubungan, lalu memilih builder khusus NPC.
- `_hub_tati()`, `_hub_asep()`, `_hub_rani()`, `_hub_fikri()`, `_hub_darto()`, `_hub_mira()`, `_hub_rw()`, `_hub_ustaz()`, `_hub_ujang()`, `_hub_imam()`, `_hub_yoga()`, dan `_hub_pelanggan()` membangun isi hub sesuai NPC.
- `build_intro()` menyiapkan dialog awal; `build_rapat()` menyiapkan rangkaian dialog rapat.

Node/choice menggunakan string `n`/`next` sebagai ID node dan string `aksi` sebagai perintah yang dieksekusi `Main`. Jika node punya `eff`, efek node diterapkan saat node dibuka; efek pilihan diterapkan setelah pilihan dipilih.

#### `DialogueBox`

- `_ready()` menyusun layout panel, label teks, potret, dan pilihan.
- `_id_tokoh()` dan `_set_potret()` mencari sprite potret berdasarkan nama pembicara.
- `_process()` mengetik teks pada laju `CPS` dan memicu blip audio periodik.
- `_finish()` mengakhiri animasi mengetik.
- `_input()` melewati animasi mengetik dengan accept/klik atau menerima pilihan angka 1–9.
- `run(start_id)` menelusuri node dari `DialogueDB.nodes`, menerapkan efek, menampilkan teks/pilihan, dan mengembalikan ID aksi atau string kosong.

### 14.4 Map dan tampilan dunia — `scripts/location_view.gd`

`LocationView` menerima ID lokasi dalam `setup()` dan membaca semua definisi dari `GameData.LOKASI`. Ia membuat node entity ber-Y-sort, layer pagar bila diperlukan, me-refresh interaksi/NPC, dan menambahkan ayam dekoratif pada map tertentu.

- `_aktif()` mengevaluasi flag syarat objek.
- `refresh()` membangun ulang blocker/interactable, pintu, serta NPC yang dijadwalkan pada jam sekarang.
- `can_stand()` membatasi posisi berdasarkan tepi map, area berjalan Y, dan rectangle blocker di sekitar titik kaki pemain. Ini collision sederhana berbasis rectangle, bukan sistem fisika badan karakter.
- `_process()` menghadapkan NPC ke pemain, menerapkan depth scaling jika data `depth` tersedia, dan menjadwalkan kendaraan/walker.
- `_spawn_vehicle()` membuat angkot atau motor berwarna acak di lokasi jalan.
- `_spawn_walker()` membuat warga melintas di gang/lapangan.
- `_draw()` memilih gambar latar atau placeholder; setelah latar, menjalankan efek dekorasi sesuai lokasi.
- Helper gambar menangani papan tanda, objek, pencahayaan, uap, kunang-kunang, meteran listrik berkedip, serta animasi kamar/koridor/masjid/lapangan/gang/jalan/kampus.

Efek visual digambar ulang saat `_process()` memanggil `queue_redraw()`. Teks interaksi tidak otomatis mengimplementasikan aksi: ID-nya tetap harus dipetakan dalam `Main._objek()`.

Untuk map dengan tekstur `bg`, `_draw()` menggambar tekstur dan efek latar, lalu selesai; gambar properti/map tersebut sudah menjadi bagian dari aset. Objek, pintu, NPC, dan area collision/interaksi masih dibangun dari data secara terpisah. Untuk map tanpa tekstur latar, `_draw()` menggambar geometri objek dan pintu dari data.

### 14.4.1 Pemetaan ID objek ke aksi

`Main._objek(id)` adalah dispatch utama untuk label aksi dari `GameData.LOKASI[*]["objek"]`. ID saat ini dikelompokkan sebagai berikut:

| Kelompok | ID objek | Hasil utama |
|---|---|---|
| Kamar | `kasur`, `meja`, `gazebo`, `lemari`, `rak`, `cucian`, `jendela`, `galon`, `kamar_mandi`, `lampu`, `poster` | Tidur/istirahat, kerja, melihat inventaris/kondisi, memasak, mencuci, minum, mandi, atau info suasana. `lampu`/`poster` terutama merupakan objek upgrade visual bersyarat. |
| Koridor kos | `pintu1`, `pintu3`, `pintu4`, `pintu5`, `rak1`, `rak2`, `sampah1`, `sampah2`, `tanaman`, `meteran`, `jemuran` | Flavor text; buang sampah/menyiram tanaman sekali sehari; melihat sisa token. |
| Gang / usaha | `warung_madura`, `gerobak`, `gardu`, `selebaran`, `kucing`, `nasi_kotak`, `jumat_berkah`, `wudu`, `rak_sandal` | Belanja/bicara, info, aktivitas gardu, makanan terbatas hari tertentu, wudu, dan elus kucing. Beberapa hanya aktif saat flag/kondisi waktu memenuhi syarat. |
| Masjid | `sajadah`, `rak_quran`, `kotak_amal`, `bedug`, `mimbar` | Salat, membaca, amal, atau info dekorasi. |
| Lapangan RW | `warteg`, `papan_menu`, `balai`, `papan_balai`, `lapangan`, `kentongan`, `lapak_baju`, `lapak_baju2`, `meteran` | Dialog/pembelian Bu Tati, pengumuman, dialog Pak RW, badminton, atau flavor text. |
| Jalan/kampus | `halte`, `gerbang`, `gerobak_ujang`, `kelas`, `b_foto`, `b_kopi`, `jalan_tutup` | Transportasi, menu Mang Ujang ketika buka, aktivitas kelas, dan geometri visual/collision. `b_foto`, `b_kopi`, `jalan_tutup` bukan pilihan aksi langsung dalam switch. |
| Interior usaha | `tv`, `mesin`, `rak`, `konter`, `antre`, meja dan dekorasi lain | Televisi memiliki aksi; banyak objek lainnya murni dekorasi/collision. |

Daftar ini adalah silang data-kode, bukan penentu tunggal keterlihatan: label interaksi, syarat flag, jam layanan, jadwal NPC, serta posisi pemain juga dapat memengaruhi apakah aksi bisa dilakukan.

### 14.5 Aktor dan pemain

#### `scripts/actor.gd`

`Actor` memuat `assets/chars/<id>_<h>.png`, menggunakan tinggi cell sprite dari tinggi tekstur, mengatur ID/nama, animasi idle dua frame, orientasi, dan label nama opsional. Jika tekstur tidak ditemukan, `_draw()` menggambar placeholder tubuh sederhana.

#### `scripts/player.gd`

`Player` mewarisi `Actor`. `_process()` membaca WASD/panah jika UI tidak mengunci input, menormalkan arah diagonal, memeriksa gerak horizontal/vertikal secara terpisah dengan `LocationView.can_stand()`, memainkan suara langkah, dan menghidupkan partikel debu. `_draw()` memilih frame idle/jalan atau pose eksplisit. `_gambar_payung()` menggambar payung sederhana di atas karakter.

Frame pose yang digunakan kode: ponsel (10), garuk kepala (11), bicara (12), serta konstanta frame tas (13). Perubahan jumlah/urutan frame aset harus diselaraskan dengan konstanta dan sheet karakter.

### 14.6 UI

#### `scripts/hud.gd`

HUD membaca singleton setiap frame untuk menampilkan hari, nama hari, jam, cuaca, uang, bar energi/kenyang/mood, tenggat tugas pertama yang belum selesai, sisa token listrik, lokasi, prompt, toast, dan banner. API yang dipanggil `Main`: `set_lokasi()`, `set_panel_visible()`, `set_prompt()`, `show_banner()`, dan `toast()`. Fungsi privat menangani interpolasi bar, animasi uang, serta label tenggat.

#### `scripts/ui_menu.gd`

`UIMenu.choose(title, body, options, cancel_id)` membuat menu secara dinamis dan menunggu sinyal `chosen`; option berbentuk dictionary dengan `id`, `label`, dan opsional `enabled`. `ask_text()` menampilkan `LineEdit` dengan batas panjang 16 karakter. `_input()` menangani cancel dan PageUp/PageDown untuk isi panjang.

#### `scripts/interact_marker.gd`

`tunjuk(pos)` mengaktifkan target prompt [E]; `sembunyi()` memulai fade-out. `_process()` menginterpolasi posisi dan alpha, sementara `_draw()` menggambar tombol E/panah beranimasi.

#### `scripts/float_text.gd`

`FloatText.spawn(parent, teks, warna, pos)` menambahkan label ke parent. `_ready()` membuat tween untuk membesar, bergerak ke atas, memudar, lalu menghapus node.

### 14.7 Overlay, pagar, dan entitas dekoratif

| Berkas | Implementasi |
|---|---|
| `scripts/rain_overlay.gd` | Membuat titik hujan dekat/jauh, gerakan diagonal, splash, kilatan acak dan delay guntur. `set_cuaca(hujan, luar)` menentukan apakah hujan ditampilkan pada layar outdoor. Sinyal `thunder` diteruskan `Main` untuk getaran kamera. |
| `scripts/fence_layer.gd` | Menggambar rel, batang, dan tiang pagar dengan fase/jarak yang disetel untuk menyambung pada latar koridor. |
| `scripts/angkot.gd` | Menggerakkan dan menggambar angkot dengan arah, warna badan, roda, jendela, trayek dan sorot lampu malam. |
| `scripts/motor.gd` | Menggerakkan/menggambar motor serta pengendara sebagai dekorasi jalan. |
| `scripts/walker.gd` | `Actor` yang berjalan horizontal dengan frame idle alternasi cepat dan menghapus diri setelah keluar batas. |
| `scripts/ayam.gd` | Ayam dekoratif yang memilih jeda/arah acak, dibatasi antara `x_min` dan `x_max`, lalu digambar secara prosedural. |

`Angkot`, `Motor`, `Walker`, dan `Ayam` adalah elemen ambience; mereka tidak mengatur ekonomi transportasi yang dipilih pemain. Perjalanan pemain diatur oleh `_transport()` dan `Economy.transport()`.

## 15. Referensi autoload per API

Bagian 4 memperkenalkan tanggung jawab singleton; tabel berikut merangkum alur/fungsi utama tiap file.

### `autoload/event_bus.gd`

Hanya mendeklarasikan sinyal global. Tidak menyimpan data, tidak memvalidasi payload, dan tidak mengatur urutan subscriber. Pengirim bertanggung jawab menyediakan payload yang benar.

### `autoload/game_state.gd`

- `_ready()` memanggil `reset()`.
- `reset()` menginisialisasi ekonomi pemain, kebutuhan, flag, hubungan awal, inventaris, tugas, counter, serta lokasi awal.
- `has_flag()`, `set_flag()`, `flag_hari()`, dan `set_flag_hari()` menangani flag permanen/berjangka/per-hari.
- `relasi()`, `jumlah_inv()`, dan `count_testimoni()` adalah helper baca.
- `apply_effects()` memusatkan mutasi state dan notifikasi UI.
- `to_dict()`/`from_dict()` menjadi lapisan serialisasi bagian `gs`.

Penambahan field state sebaiknya dilakukan di empat tempat: deklarasi/default, `reset()`, `to_dict()`, dan `from_dict()`. Tambahkan juga uji kompatibilitas load jika field baru memengaruhi gameplay.

### `autoload/time_manager.gd`

- `jam()`, `menit()`, `jam_str()`, `nama_hari()`, `hari_kerja()` menyediakan representasi waktu.
- `_process()` mengakumulasi menit permainan hanya jika `running` dan UI tidak terbuka.
- `advance(mins)` memajukan menit satu per satu, mengirim event perubahan waktu, dan memproses pergantian jam.
- `_on_hour()` menerapkan konsumsi kebutuhan dan mengevaluasi hujan.
- `_update_rain()` menentukan cuaca dari hari/jam lalu mengirim `rain_changed`.
- `new_day()` mereset jam ke 06.00, menambah hari, dan menghentikan hujan aktif.

### `autoload/economy.gd`

- `reset()` menghapus pengali harga/stok habis.
- `_bulat()` membulatkan harga ke Rp500 terdekat.
- `harga(item_id)` mencari harga dan pengali menurut tag.
- `tersedia(item_id)` memeriksa stok yang tidak habis.
- `apply_event(eff)` menerapkan field `harga` dan `habis` dari efek event.
- `tick_day()` menurunkan masa stok habis.
- `transport(mode)` mengembalikan dictionary `harga`, `menit`, dan `energi` setelah modifikasi kontekstual.

### `autoload/news_system.gd`

`run_day(day)` menerapkan semua event hari itu lalu mengembalikan array event untuk ringkasan pagi. `_apply()` memisahkan efek ekonomi dari efek state. `komentar(npc, idx)` mencari komentar NPC dari log berita terbaru dengan rotasi berdasarkan indeks. `warga_lines()` mengembalikan pendapat warga dari event terbaru yang punya field tersebut.

### `autoload/daily.gd`

`sewa_tagihan()` menghitung sewa termasuk denda aktif; `listrik_hari()` dan `listrik_ada()` membaca token. `proses_pagi()` menurunkan token, mengeluarkan peringatan/denda dan menjalankan kejutan deterministik. `rencana_hari_ini()` hanya menyusun teks pengingat—sesuai komentar fungsi, seharusnya tanpa efek samping.

### `autoload/save_system.gd`

`ada()` memeriksa file save. `simpan(loc, pos)` menyimpan dictionary ke JSON. `muat()` mem-parsing data, memvalidasi field minimum, mereset dan memulihkan GameState/TimeManager/Economy, lalu menyimpan `last_loc` dan `last_pos` untuk `Main`. `hapus()` menghapus file save. Kegagalan akses file atau JSON dilaporkan sebagai `false`; tampilan pesan ditentukan pemanggil.

### `autoload/achievements.gd`

`DAFTAR` menyimpan ID, nama, dan deskripsi. `_c()` membaca counter. `terpenuhi(id)` berisi predicate per achievement. `sudah()` memeriksa flag `ach_<id>`, `jumlah()` menghitung achievement yang sudah dibuka, dan `cek()` menandai yang baru lalu mengirim `EventBus.pencapaian`.

### `autoload/audio_manager.gd`

- `_ready()` membaca preferensi, menyiapkan bus audio/pool player, membangkitkan SFX, loop hujan/jangkrik, lalu memulai thread pembuat musik.
- `_exit_tree()` menunggu thread pembuat musik jika aktif.
- `_setup_bus()`, `_load_settings()`, `simpan_pengaturan()`, `apply_settings()` mengurus bus dan config.
- `play()` mengambil player dari pool untuk memainkan nama efek yang sudah terdaftar.
- `set_ambience(outdoor, raining, jam)` mengubah target level musik/ambience berdasarkan kondisi.
- `_process()` melakukan transisi volume dan menyalakan suara burung pada kondisi tertentu.
- `_mulai_musik()`, `_mk_player()`, `_wav()`, `_loopify()` menangani playback/format stream.
- `_tone()`, `_noise()`, `_mix()`, `_seq()` adalah primitive sintesis waveform.
- `_buat_efek()`, `_make_rain()`, `_make_cricket()` menghasilkan bunyi-bunyi dasar.
- `_gen_music()`, `_mtof()`, `_compose()` membangkitkan musik siang/malam. Musik dibuat di thread lalu dipasang oleh proses utama.

Nama efek yang digunakan oleh source antara lain `click`, `tick`, `blip`, `pop`, `coin`, `chime`, `alert`, `error`, `step`, `door`, `page`, `sleep`, `bell`, `thunder`, `burung1`, dan `burung2`.

## 16. Utilitas pengembangan dan uji

### 16.1 Skrip GDScript di `tools/`

| Berkas | Kegunaan dan cara kerja |
|---|---|
| `tools/logic_test.gd` | `SceneTree` test terarah. Membuat scene utama, menggerakkan menu/dialog dengan sinyal, lalu mencetak pemeriksaan token, denda, efek, rencana harian, skor, dan UI ending. Bukan framework assertion; hasil utamanya berupa log. |
| `tools/bot_test.gd` | Bot smoke-test dengan seed tetap, time scale 6, dan durasi opsional argumen. Mengklik menu/dialog, mengubah waktu, berpindah/interaksi secara acak dan mencetak ringkasan hari/uang/aksi. Gunakan untuk menemukan error runtime, bukan memverifikasi hasil gameplay deterministik secara lengkap. |
| `tools/shot_test.gd` | Menginisialisasi beberapa skenario visual (pagi/malam kamar, hujan gang, petir, koridor, lapangan, dialog) lalu menyimpan screenshot. Script menulis ke `/tmp/shots`; direktori POSIX tersebut tidak langsung cocok dengan Windows. |

### 16.2 Skrip Python di `tools/`

Skrip Python adalah alat authoring offline, tidak dijalankan oleh runtime Godot.

| Berkas | Input/proses/output |
|---|---|
| `tools/snap_dimas.py` | Membaca sprite sheet sumber pada path `/mnt/user-data/uploads/dimas_sprite_sheet.png`; memakai NumPy, Pillow, dan SciPy untuk mengelompokkan karakter, mengestimasi grid piksel, mengambil sampel warna per sel, lalu menyimpan `/tmp/native.npy` dan preview. Path input bersifat lokal/khusus lingkungan authoring. |
| `tools/make_chars.py` | Membaca `/tmp/native.npy`, membuat sheet Dimas dan NPC prosedural dari `SPECS`, lalu menulis variasi ukuran ke `assets/chars/`. Memerlukan NumPy, Pillow, SciPy. `SIZES` saat ini memuat tinggi 50, 62, 75, 100, dan 150; kode runtime meminta ukuran berdasarkan metadata lokasi/portrait. |
| `tools/make_masjid.py` | Menggambar latar masjid 480×270 dari primitive Pillow, menyimpan `assets/masjid_bg.png` dan preview `/tmp/masjid_prev.png`. Tidak bergantung pada gambar input eksternal. |
| `tools/make_gang2.py` | Membaca dua JPG referensi pada `/mnt/user-data/uploads/`, menambal area, menyambung/blend panorama, crop/resize/quantize dan menggambar tangga/gerbang; output `assets/gang_bg.png` plus dua crop preview di `/tmp/`. Memerlukan Pillow dan NumPy. |
| `tools/make_lapangan.py` | Membaca dua PNG referensi pada `/mnt/user-data/uploads/`, menutup watermark/artefak sambungan, blend langit dan foreground, resize/quantize; output `assets/lapangan_bg.png` dan preview `/tmp/lap_full.png`. Memerlukan Pillow dan NumPy. |

Sebelum menjalankan generator yang menimpa aset, pastikan file input yang dirujuk tersedia dan salinan aset saat ini sudah diamankan. Path upload/temporary di script menunjukkan asal lingkungan authoring, bukan path lintas platform atau dependency runtime.

## 17. Kontrak dan alur lintas modul

### 17.1 Siklus interaksi objek/NPC

```text
Main._process()
  -> LocationView.interactables
  -> Main._cari_dekat()
  -> HUD.set_prompt() + InteractMarker.tunjuk()
  -> tombol E
  -> Main._interact()
  -> Main._handle()
      -> pintu: GameData.buka() -> Main._pindah()
      -> NPC: DialogueDB.hub() -> DialogueBox.run()
      -> objek: Main._objek(id)
  -> GameState.apply_effects() / Main._aksi()
  -> LocationView.refresh() + Ach.cek()
```

Untuk menambah titik interaksi yang berfungsi, cek seluruh rantai ini: definisi `objek`/`pintu` → label/range → pencarian target → dispatch ID → efek/aksi → refresh jadwal atau ketersediaan.

### 17.2 Siklus waktu dan event harian

```text
TimeManager._process()
  -> TimeManager.advance()
      -> tiap jam: kebutuhan turun, cuaca dievaluasi, hour_changed
      -> rentang menit: waktu_maju
          -> Main memeriksa adzan
  -> saat tidur:
      -> TimeManager.new_day()
      -> Economy.tick_day()
      -> NewsSystem.run_day(day)
      -> Daily.proses_pagi()
      -> muat kamar, cek achievement, autosave
      -> Main._pagi() menampilkan berita/ringkasan
```

UI modal mengatur `GameState.ui_open`; ini memengaruhi `TimeManager._process()`. Waktu yang dibebankan sebagai efek eksplisit (`"waktu"`) tetap diterapkan melalui `advance()` meskipun UI terbuka.

### 17.3 Jalur pembelian

```text
GameData.ITEMS/menu
  -> Main membangun pilihan dengan Economy.harga()
  -> pilihan dipilih
  -> Main membuat efek uang/inventaris/stat/counter/waktu
  -> GameState.apply_effects()
  -> _langganan() memperbarui counter beli/hubungan
  -> sinyal stats_changed memperbarui HUD
```

Pembelian item tidak diimplementasikan sebagai satu API generik terpisah: `_menu_makan()` dan `_belanja_kat()` masing-masing punya aturan sendiri. Jika menambahkan kategori efek item baru, cek branch pembelian dan konsumsi item terkait.

### 17.4 Urutan efek dan persistensi

Event berita mengirim efek ekonomi ke `Economy` lebih dahulu, lalu menerapkan efek state secara silent, lalu menambahkan ID ke log. Saat tidur, stok habis ditick sebelum event hari baru dijalankan. Urutan ini memengaruhi masa stok dan pengali harga; ubah hanya bila perilaku kalender memang hendak diganti.

Achievement disimpan di `GameState.flags`; posisi, jam, dan ekonomi berada di luar `gs` pada JSON save. Karena itu perubahan lokasi/posisi harus melalui `SaveSystem.simpan(loc, pos)`, bukan hanya `GameState.to_dict()`.

## 18. Cakupan inventaris source

Inventaris runtime yang dibahas di dokumen ini adalah:

- **17 script utama di `scripts/`:** aktor, pemain, lokasi, UI, dialog, efek visual, objek dekoratif, dan orkestrasi.
- **9 singleton di `autoload/`:** event bus, state, waktu, ekonomi, berita, sistem harian, save, pencapaian, dan audio.
- **3 skrip tes di `tools/`:** uji logika, bot smoke-test, dan screenshot.
- **5 skrip Python di `tools/`:** pemrosesan sprite/panorama serta generator gambar.

File gambar dan metadata import bukan kode, tetapi konsumen utamanya diterangkan pada bagian aset. Folder cache editor `.godot/` tidak termasuk source yang sebaiknya diedit.

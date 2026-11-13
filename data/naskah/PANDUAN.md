# Panduan Menulis Naskah

Semua dialog, berita, dan tugas game ada di folder ini, dalam berkas teks `.naskah`.
**Anda tidak perlu menyentuh kode** untuk mengubah kalimat, menambah pilihan, atau menambah percakapan baru.
Bukalah berkas di editor teks apa pun (atau di tab *Script* Godot), ubah, simpan, lalu jalankan game.

## 1. Peta berkas

| Berkas | Isi |
|---|---|
| `tati`, `asep`, `rani`, `fikri`, `darto`, `mira`, `rw`, `yoga`, `ustaz`, `imam`, `ujang` | Percakapan tiap tokoh (dibuka dengan tombol E di dekat tokoh itu) |
| `pelanggan` | Figuran yang membahas berita terbaru |
| `intro` | Adegan pembuka game |
| `rapat` | Rapat warga hari ke-27 (klimaks cerita) |
| `berita` | Berita/kejadian harian: harga naik, hoaks, jalan ditutup, dsb. + komentar tiap tokoh |
| `tugas` | Daftar tugas kuliah (nama, hari mulai, tenggat) |

Nama berkas = id tokoh di game. Tokoh baru butuh berkas baru dengan nama id-nya.

## 2. Bentuk dasar

Satu berkas berisi banyak **simpul** (satu layar dialog). Simpul diawali `== id`, lalu baris `kunci: nilai`.

```
# Baris yang diawali tanda pagar adalah catatan, tidak dibaca game.

== tati_kasbon
bicara: Bu Tati
teks: Yah… sekali ini ya, {nama}. Tapi dicatat.
efek: kenyang +40, utang +7000, waktu 15, akrab.tati +1
```

- **id simpul**: huruf kecil, angka, garis bawah. Bebas, asal unik dalam satu berkas.
- Simpul **`hub`** wajib ada di berkas tokoh: itulah layar pertama saat Dimas menyapa.
- Baris yang diawali **spasi** melanjutkan baris di atasnya (untuk teks panjang).
- Tulis `\n` di dalam teks untuk memaksa baris baru.
- Jangan menulis ` | ` (spasi-garis tegak-spasi) di dalam teks biasa: itu dipakai untuk kondisi/efek.

### Kunci yang tersedia di dialog

| Kunci | Fungsi |
|---|---|
| `bicara:` | Nama pembicara. Kosongkan/hilangkan untuk narasi. `{nama}` = nama pemain (Dimas). |
| `teks:` | Isi kalimat. Boleh lebih dari satu dengan kondisi berbeda (lihat §4). |
| `bergilir:` | Daftar kalimat (baris `- ...`) yang dipakai bergiliran tiap obrolan. |
| `tambah:` | Paragraf tambahan di bawah teks, muncul bila kondisinya terpenuhi. |
| `baris:` | Seperti `tambah:` tetapi hanya pindah baris (tanpa jeda paragraf). |
| `efek:` | Perubahan yang terjadi saat layar ini muncul (§6). |
| `pilihan:` | Daftar jawaban Dimas (baris `- ...`), lihat §3. |
| `lanjut:` | Simpul berikutnya, bila layar ini tanpa pilihan (otomatis tombol "Lanjut"). |
| `aksi:` | Menjalankan fitur game (belanja, rapat, dll.) lalu menutup dialog. |

## 3. Pilihan jawaban

```
pilihan:
- Pesan makanan -> aksi menu_tati
- Kasbon dulu ya, Bu… -> tati_kasbon | jika uang<9000, utang<=0
- Siap, Bu. -> tati_bantu2 | efek akrab.tati +1, mood +2
- Cuma mampir, Bu.
```

Format satu pilihan: `- teks -> tujuan | jika kondisi | efek perubahan`

- **tujuan** = id simpul lain, atau `aksi nama_aksi`. Tanpa `->` percakapan selesai.
- `| jika ...` (opsional): pilihan hanya tampil bila kondisi terpenuhi.
- `| efek ...` (opsional): perubahan yang terjadi saat pilihan itu dipilih.
- Placeholder dalam teks pilihan juga bekerja: `Bayar sewa ({tagihan})`.

### Daftar aksi yang dikenal game
`menu_tati`, `menu_mira`, `menu_asep`, `menu_imam`, `menu_ujang`, `menu_foto`, `bayar_utang`, `bayar_sewa`,
`beli_kursi`, `tv`, `kerja_kopi`, `salat_masjid`, `rapat`. (Daftar resmi: fungsi `_aksi` di `scripts/main.gd`;
validator akan menolak nama yang tidak ada.)

## 4. Teks yang berubah menurut keadaan

Beberapa `teks:` berurutan: **yang pertama kondisinya terpenuhi dipakai**. Taruh yang paling spesifik di atas,
yang bawaan (tanpa kondisi) paling bawah.

```
== hub
bicara: Bu Tati
teks: Mangga, {nama}. Sarapan dulu? | jika jam<11
teks: Siang, {nama}. Nasinya masih hangat. | jika jam<16
teks: Sore, Nak. Lauk tinggal yang itu-itu, tapi enak.
tambah: (Catatan kecil di bawah sapaan.) | jika akrab.tati>=3
```

`lanjut:` juga boleh banyak dan bersyarat, untuk percakapan yang bercabang menurut apa yang sudah terjadi:

```
lanjut: r_asep_cek | jika flag hoax_cek
lanjut: r_asep_fwd | jika flag hoax_forward
lanjut: r_asep_biasa
```

Kabar terbaru dari tokoh (`kata.<tokoh>` di `berita.naskah`) **otomatis** ditempel di akhir simpul `hub`.

### Placeholder dalam teks
`{nama}` nama pemain • `{uang}` saldo • `{utang}` utang kasbon • `{tagihan}` sewa kos (plus denda bila ada)
• `{listrik}` sisa hari listrik • `{catatan}` jumlah catatan warga • `{warga}` (hanya di `pelanggan`).

## 5. Kondisi (`| jika ...`)

Beberapa kondisi dipisah koma, dan **semuanya harus terpenuhi**.

| Bentuk | Arti |
|---|---|
| `flag nama` / `!flag nama` | penanda cerita menyala / belum |
| `flag_hari nama` | penanda khusus hari ini |
| `jumat`, `hari_kerja`, `salat_aktif` | hari Jumat / hari kuliah / sedang waktu salat (tambah `!` untuk kebalikan) |
| `hari>=3` `jam<16` `menit>=735` | operator: `>=  <=  >  <  =  !=` |
| `uang<9000` `utang>0` `listrik<=0` `tagihan>0` | nilai dasar: `hari jam menit uang utang catatan listrik tagihan` |
| `akrab.tati>=2` | tingkat kedekatan dengan tokoh (id tokoh) |
| `inv.paket>=1` | jumlah barang di tas |
| `hitung.proyek<2` | penghitung kegiatan (`proyek`, `bantu`, `masak`, `salat`, dst.) |

Catatan: `jam` bilangan bulat (16 = pukul 16.00). `menit` = menit sejak 00.00 (735 = 12.15).
Nama flag boleh memakai `{hari}`: `!flag ustaz_bantu_d{hari}` artinya "belum membantu pada hari ini".

## 6. Efek (`efek:` atau `| efek ...`)

Beberapa efek dipisah koma.

| Bentuk | Arti |
|---|---|
| `uang +15000`, `uang -7000` | tambah/kurangi uang |
| `energi -12`, `kenyang +40`, `mood +3` | status (dibatasi 0–100) |
| `utang +7000` | utang kasbon |
| `waktu 90` | waktu berlalu 90 menit |
| `akrab.tati +2` | kedekatan dengan tokoh |
| `inv.paket +1` | barang masuk/keluar tas |
| `tugas.t3 +40` | progres tugas t3 naik 40% |
| `hitung.bantu +1` | tambah penghitung (untuk pencapaian) |
| `flag a b c` | nyalakan satu atau lebih penanda cerita |
| `flag_hari nama` | penanda yang hanya berlaku hari ini |
| `timed.nama 12` | penanda aktif sampai hari ke-12 |

Khusus `berita`: `harga.telur x1.3` (harga telur dikali 1,3), `habis.mi_instan 2` (habis 2 hari).

## 7. Resep untuk kasus umum

**Menambah tokoh baru:** buat `data/naskah/<id>.naskah` berisi `== hub`. Daftarkan tokoh di `GameData.NPC`
dan jadwalnya di `GameData.jadwal()` (satu-satunya bagian yang masih di kode).

**Menambah percakapan ke tokoh yang ada:** (1) tambahkan satu baris pilihan di `hub`, (2) buat simpul baru di bawahnya.

```
# di == hub tati, tambahkan:
- Bu, bagaimana kabar anak Ibu? -> tati_anak | jika hari>=8

# lalu di mana saja dalam berkas yang sama:
== tati_anak
bicara: Bu Tati
teks: Alhamdulillah, sudah mulai kerja di Bandung.
efek: mood +2, flag tahu_anak_tati
```

**Percakapan sekali saja:** beri penanda dan larang di pilihannya.
```
- Bu, bagaimana kabar anak Ibu? -> tati_anak | jika !flag tahu_anak_tati
# ... dan di simpul tati_anak ada efek: flag tahu_anak_tati
```

**Cerita berantai (dialog panjang):** gunakan `lanjut:` dari satu simpul ke simpul berikutnya (lihat `rapat.naskah`).

**Menambah berita:** salin satu blok di `berita.naskah`, ganti id, `hari`, teks, dan efek. Komentar tokoh
`kata.tati: ...` akan muncul otomatis di sapaan Bu Tati setelah berita itu terjadi.

**Mengubah isi pagi/rapat/akhir permainan:** teks akhir bulan (rapor & kabar warga) masih di `scripts/main.gd`
(fungsi `_ending`); semua yang diucapkan tokoh sudah di sini.

## 8. Memeriksa pekerjaan Anda

Setelah mengedit, jalankan validator. Ia menunjukkan **nama berkas dan nomor baris** untuk tiap masalah:

```
godot --headless --path . res://tools/cek_naskah.tscn
```

| Pesan | Artinya |
|---|---|
| `GALAT ... tujuan simpul 'x' tidak ada` | Salah ketik id pada `->` atau `lanjut:` |
| `GALAT ... aksi 'x' tidak dikenal` | Nama aksi salah (lihat daftar di §3) |
| `GALAT ... kunci 'x' tidak dikenal` | Kunci baris salah ketik |
| `GALAT ... kondisi tidak dikenali` | Penulisan kondisi/efek salah (lihat §5, §6) |
| `PERINGATAN ... yatim` | Simpul tidak pernah dituju, mungkin lupa dihubungkan |
| `PERINGATAN ... flag 'x' ... tidak pernah dinyalakan` | Hampir pasti salah ketik nama flag |
| `PERINGATAN ... pembicara` | Nama pembicara tidak dikenal (potret tidak muncul) |

Bila game tidak menampilkan dialog yang diharapkan: periksa kondisi `| jika` pada pilihan itu.
Kondisi yang tidak terpenuhi membuat pilihan **tersembunyi** (bukan error).

## 9. Hal teknis yang perlu diingat

- **Ekspor game:** tambahkan `data/naskah/*` pada *Export → Resources → Filters to export non-resource files*,
  jika tidak, berkas naskah tidak ikut dan dialog kosong di hasil ekspor.
- Berkas harus UTF-8 (default di hampir semua editor). Karakter seperti … – • aman dipakai.
- Satu simpul dihitung saat akan ditampilkan, jadi kondisi selalu memakai keadaan game **saat itu**.
- Uji kesetaraan `tools/uji_dialog.tscn` membandingkan dialog naskah dengan versi kode lama; hanya relevan
  selama migrasi. Setelah Anda mulai mengubah cerita, perbedaan itu wajar dan uji tersebut boleh diabaikan.

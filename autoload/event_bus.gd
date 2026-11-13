extends Node
## Sinyal global supaya sistem tidak saling bergantung langsung.

signal stats_changed
signal hour_changed(hour: int)
signal rain_changed(is_raining: bool)
signal toast(text: String)
## Teks melayang di atas kepala pemain (perubahan uang/energi/hubungan).
signal popup(text: String, color: Color)
## Waktu maju dari menit `dari` ke menit `ke` (dipakai untuk adzan tepat waktu).
signal waktu_maju(dari: int, ke: int)
signal pencapaian(nama: String)

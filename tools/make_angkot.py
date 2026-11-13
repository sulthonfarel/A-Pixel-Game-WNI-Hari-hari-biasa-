"""Membuat assets/angkot.png dari assets/angkot.jpg (crop + hapus latar putih di tepi kiri/kanan tiap baris).
Jalankan sekali: python3 tools/make_angkot.py
Sebelumnya proses ini dijalankan saat game berjalan lewat Image.load('res://...jpg'), yang tidak berfungsi
pada hasil export. Sekarang game cukup memuat PNG yang sudah jadi sebagai Texture2D biasa."""
from PIL import Image
import numpy as np

im = Image.open("assets/angkot.jpg").convert("RGBA")
im = im.crop((100, 520, 100 + 1840, 520 + 1000))
a = np.array(im).astype(np.float32) / 255.0
white = (a[..., 0] > 0.93) & (a[..., 1] > 0.93) & (a[..., 2] > 0.93)
h, w = white.shape
for y in range(h):
    row = white[y]
    left = 0
    while left < w and row[left]:
        a[y, left, 3] = 0.0
        left += 1
    right = w - 1
    while right >= left and row[right]:
        a[y, right, 3] = 0.0
        right -= 1
Image.fromarray((a * 255).astype(np.uint8), "RGBA").save("assets/angkot.png", optimize=True)
print("ok", w, h)

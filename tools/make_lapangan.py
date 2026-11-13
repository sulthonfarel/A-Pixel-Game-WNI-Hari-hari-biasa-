"""Menyambung bagian2_part1 (Warteg Bu Tati) + bagian2_part2 (Balai RW) di lapangan bulutangkis."""
from PIL import Image
import numpy as np

A = Image.open('/mnt/user-data/uploads/bagian2_part1_warteg_bu_tati_v8.png').convert('RGB')
B = Image.open('/mnt/user-data/uploads/bagian2_part2_balai_rw_v2.png').convert('RGB')
CUT = 1096        # x gambar 1 tempat gambar 2 dimulai (hasil pencocokan lapangan)
BL = 64
BL_SKY = 240


def patch(im):
    a = np.array(im)
    a[722:768, 1130:1376] = a[676:722, 1130:1376]      # tutup watermark kanan-bawah
    a[700:768, 1030:1140] = a[632:700, 1030:1140]      # tutup sisa motor di tepi sambungan
    return Image.fromarray(a)


A = patch(A); B = patch(B)
Wf = CUT + B.width
full = Image.new('RGB', (Wf, A.height))
full.paste(A.crop((0, 0, CUT, A.height)), (0, 0))
full.paste(B, (CUT, 0))
a = np.array(A).astype(float); b = np.array(B).astype(float); f = np.array(full).astype(float)
def blend(x0, width, rows):
    """Campur ke kanan sambungan: kolom gambar 1 (x0..x0+width) -> kolom gambar 2 (0..width)."""
    for i in range(width):
        t = i / (width - 1)
        x = x0 + i
        f[rows, x, :] = a[rows, x, :] * (1 - t) + b[rows, x - x0, :] * t


blend(CUT, BL_SKY, slice(0, 150))              # langit: pencampuran lebar
blend(CUT, 40, slice(150, A.height))           # bangunan/lapangan: pencampuran sempit
# setelah area campuran, langit bagian atas memakai gambar 2 sepenuhnya
f[0:150, CUT + BL_SKY:CUT + 400, :] = b[0:150, BL_SKY:400, :]
full = Image.fromarray(f.astype(np.uint8))
S = 270 / 768.0
W = round(Wf * S)
im = full.resize((W, 270), Image.LANCZOS)
im = im.quantize(colors=112, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert('RGB')
im.save('assets/lapangan_bg.png')
full.resize((Wf // 2, 384), Image.LANCZOS).save('/tmp/lap_full.png')
print(W, 270, Wf)

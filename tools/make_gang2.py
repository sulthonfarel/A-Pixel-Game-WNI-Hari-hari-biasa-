"""Menyambung Gang_Kost_Satu + Gang_Kost_Dua menjadi latar gang scroll (1053x270)."""
from PIL import Image, ImageDraw
import numpy as np

A = Image.open('/mnt/user-data/uploads/Gang_Kost_Satu.jpg').convert('RGB')
B = Image.open('/mnt/user-data/uploads/Gang_Kost_Dua.jpg').convert('RGB')
OFF = 2387            # x0 gambar 2 dalam koordinat gambar 1 (hasil pencocokan kios Warung Madura)
CUT = 2560            # titik sambung (di dalam kios, area tumpang tindih)
BL = 70
S = 0.205
TOP = 219


def patch(im):
    """Tutup kotak hitam / watermark di pojok kanan-bawah dengan tekstur jalan di atasnya."""
    a = np.array(im)
    a[1446:1536, 2290:2752] = a[1356:1446, 2290:2752]
    return Image.fromarray(a)


A = patch(A); B = patch(B)
Wf = OFF + B.width
full = Image.new('RGB', (Wf, A.height))
full.paste(A.crop((0, 0, CUT, A.height)), (0, 0))
full.paste(B.crop((CUT - OFF, 0, B.width, B.height)), (CUT, 0))
a = np.array(A).astype(float); b = np.array(B).astype(float); f = np.array(full).astype(float)
for i in range(BL):
    x = CUT - BL // 2 + i
    t = i / (BL - 1)
    f[:, x, :] = a[:, x, :] * (1 - t) + b[:, x - OFF, :] * t
full = Image.fromarray(f.astype(np.uint8))
crop = full.crop((0, TOP, Wf, A.height))
W = round(Wf * S)
im = crop.resize((W, 270), Image.LANCZOS)
im = im.quantize(colors=112, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert('RGB')
d = ImageDraw.Draw(im)
# gerbang kost + tangga naik (dinding kost tidak punya pintu pada gambar acuan)
d.rectangle([22, 158, 68, 220], fill=(52, 40, 34))
d.rectangle([20, 156, 70, 159], fill=(104, 78, 58))
d.rectangle([20, 156, 21, 220], fill=(104, 78, 58)); d.rectangle([69, 156, 70, 220], fill=(104, 78, 58))
for i in range(6):
    y0 = 214 - i * 8
    d.rectangle([28 + i * 6, y0, 67, min(220, y0 + 7)], fill=(150 - i * 7, 138 - i * 7, 122 - i * 6))
    d.rectangle([28 + i * 6, y0, 33 + i * 6, y0 + 1], fill=(196, 186, 164))
d.line([(24, 206), (62, 168)], fill=(112, 112, 120), width=2)
d.rectangle([16, 220, 74, 222], fill=(160, 152, 136))
im.save('assets/gang_bg.png')
im.crop((0, 0, 540, 270)).resize((1080, 540), Image.NEAREST).save('/tmp/g2a.png')
im.crop((513, 0, 1053, 270)).resize((1080, 540), Image.NEAREST).save('/tmp/g2b.png')
print(W, 270)

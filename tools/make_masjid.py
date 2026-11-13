from PIL import Image, ImageDraw
import random
W, H = 480, 270
im = Image.new('RGB', (W, H), (226, 216, 192))
d = ImageDraw.Draw(im)
rnd = random.Random(3)
# langit-langit & dinding
d.rectangle([0, 0, W, 22], fill=(186, 170, 140)); d.rectangle([0, 22, W, 24], fill=(120, 100, 76))
for x in range(0, W, 24):
    d.line([(x, 24), (x, 200)], fill=(214, 204, 180))
d.rectangle([0, 196, W, 206], fill=(150, 120, 86))                   # lis bawah dinding
# lantai karpet hijau + shaf
d.rectangle([0, 206, W, H], fill=(70, 112, 88))
for y in range(212, H, 14):
    d.rectangle([0, y, W, y + 1], fill=(222, 214, 170))
for x in range(0, W, 40):
    d.line([(x, 206), (x + (x - 240) // 3, H)], fill=(58, 96, 74))
# mihrab (lengkung gelap berbingkai hijau)
d.rectangle([186, 72, 294, 206], fill=(48, 110, 82))
d.rectangle([194, 84, 286, 206], fill=(62, 52, 46))
d.ellipse([194, 62, 286, 118], fill=(62, 52, 46)); d.ellipse([186, 54, 294, 110], outline=(48, 110, 82), width=8)
d.polygon([(240, 36), (232, 52), (248, 52)], fill=(212, 176, 76))
for i in range(5):
    d.rectangle([216 + i * 10, 140, 220 + i * 10, 150], fill=(212, 176, 76))      # kaligrafi (simbol)
d.rectangle([186, 196, 294, 206], fill=(120, 92, 66))
# mimbar kayu
d.rectangle([306, 120, 352, 206], fill=(112, 78, 50)); d.rectangle([306, 120, 352, 124], fill=(150, 108, 70))
for i in range(5):
    d.rectangle([306 + i * 4, 206 - (i + 1) * 12, 352, 206 - i * 12], fill=(120 + i * 6, 84 + i * 4, 54))
d.rectangle([322, 100, 346, 122], fill=(100, 68, 44)); d.rectangle([326, 104, 342, 120], fill=(142, 100, 66))
# jendela lengkung bermotif hijau
for wx in (34, 404):
    d.rectangle([wx, 70, wx + 42, 150], fill=(120, 168, 150)); d.ellipse([wx, 52, wx + 42, 96], fill=(120, 168, 150))
    d.rectangle([wx - 3, 70, wx + 45, 154], outline=(150, 120, 86), width=3)
    for k in range(0, 44, 7):
        d.line([(wx + k, 60), (wx + k, 150)], fill=(70, 120, 100)); 
    for k in range(70, 150, 9):
        d.line([(wx, k), (wx + 42, k)], fill=(70, 120, 100))
# bedug
d.ellipse([92, 168, 134, 206], fill=(120, 84, 54)); d.rectangle([92, 180, 134, 200], fill=(130, 92, 58))
d.ellipse([124, 172, 140, 202], fill=(196, 164, 110)); d.ellipse([90, 196, 136, 210], fill=(98, 70, 46))
# rak Al-Quran
d.rectangle([362, 150, 418, 206], fill=(112, 78, 50))
for r in range(3):
    d.rectangle([365, 154 + r * 17, 415, 168 + r * 17], fill=(80, 56, 38))
    for k in range(10):
        d.rectangle([367 + k * 5, 156 + r * 17, 370 + k * 5, 167 + r * 17], fill=[(40, 110, 80), (180, 60, 56), (212, 176, 76), (60, 90, 150)][k % 4])
# kotak amal
d.rectangle([432, 176, 448, 206], fill=(196, 196, 190)); d.rectangle([432, 176, 448, 182], fill=(120, 130, 128)); d.rectangle([436, 186, 444, 196], fill=(70, 120, 90))
# pintu keluar (lengkung terang ke luar)
d.rectangle([452, 122, 478, 206], fill=(236, 226, 190)); d.ellipse([452, 108, 478, 136], fill=(236, 226, 190))
d.rectangle([450, 122, 453, 206], fill=(120, 92, 66))
# kipas & lampu gantung
d.line([(150, 24), (150, 40)], fill=(70, 70, 70)); d.ellipse([132, 38, 168, 46], fill=(90, 90, 96))
d.line([(340, 24), (340, 40)], fill=(70, 70, 70)); d.ellipse([322, 38, 358, 46], fill=(90, 90, 96))
d.line([(240, 24), (240, 34)], fill=(70, 70, 70)); d.ellipse([232, 34, 248, 46], fill=(250, 232, 150))
# jam dinding
d.ellipse([60, 30, 84, 54], fill=(240, 236, 224), outline=(90, 70, 50)); d.line([(72, 42), (72, 34)], fill=(40, 40, 40)); d.line([(72, 42), (78, 44)], fill=(40, 40, 40))
im.save('assets/masjid_bg.png')
im.resize((960, 540), Image.NEAREST).save('/tmp/masjid_prev.png')

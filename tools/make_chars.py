"""Menghasilkan sprite sheet karakter dalam 3 ukuran (tinggi ±50 / 62 / 100 px).
Dimas: dari /tmp/native.npy (hasil snap grid piksel dari sprite sheet asli).
NPC: digambar prosedural dengan gaya serupa (outline gelap 1 px)."""
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

OUT = 'assets/chars'
SIZES = {50: 1.0, 62: 62 / 51.0, 75: 75 / 51.0, 100: 2.0, 150: 3.0}
CELL = {50: 58, 62: 70, 75: 88, 100: 116, 150: 172}


def place(frames, size):
    """frames: list of RGBA uint8 arrays (native). Kembalikan sheet horizontal."""
    r = SIZES[size]
    cell = CELL[size]
    sheet = Image.new('RGBA', (cell * len(frames), cell), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        im = Image.fromarray(f)
        if r != 1.0:
            im = im.resize((max(1, round(im.width * r)), max(1, round(im.height * r))), Image.NEAREST)
        arr = np.array(im)
        h, w = arr.shape[:2]
        ys, xs = np.nonzero(arr[:int(h * 0.45), :, 3])
        cx = int(round(xs.mean())) if len(xs) else w // 2
        ox = cell // 2 - cx
        oy = cell - 1 - h
        cellimg = Image.new('RGBA', (cell, cell), (0, 0, 0, 0))
        cellimg.paste(im, (ox, oy))
        sheet.paste(cellimg, (i * cell, 0))
    return sheet


# ------------------------------------------------------------- NPC prosedural
OUTLINE = (24, 14, 14, 255)


def rect(c, x0, y0, x1, y1, col):
    c[y0:y1 + 1, x0:x1 + 1] = (*col, 255)


def shade(col, f):
    return tuple(max(0, min(255, int(v * f))) for v in col)


def hexc(s):
    s = s.lstrip('#')
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def person(spec, bob=0):
    W, H = 30, 56
    c = np.zeros((H, W, 4), np.uint8)
    cx = W // 2
    skin = hexc(spec.get('skin', '#d9a066'))
    hair = hexc(spec.get('hair', '#1a1a1a'))
    shirt = hexc(spec.get('shirt', '#4a6fa5'))
    pants = hexc(spec.get('pants', '#2b2f45'))
    shoe = hexc(spec.get('shoe', '#e8e8e8'))
    wide = spec.get('wide', 0)          # badan lebih lebar
    top = 4 + bob                      # kepala turun sedikit saat 'napas'
    # kaki / bawahan
    legs_y0, legs_y1 = 33, 49
    style = spec.get('bottom', 'pants')
    if style == 'sarong':
        sar = hexc(spec.get('sarong', '#4a5a7a'))
        rect(c, cx - 6 - wide, legs_y0 - 2, cx + 5 + wide, legs_y1 - 2, sar)
        for yy in range(legs_y0, legs_y1 - 1, 3):
            rect(c, cx - 6 - wide, yy, cx + 5 + wide, yy, shade(sar, 0.8))
        for xx in range(cx - 6 - wide, cx + 6 + wide, 3):
            rect(c, xx, legs_y0 - 2, xx, legs_y1 - 2, shade(sar, 1.18))
        rect(c, cx - 5, legs_y1 - 1, cx - 2, legs_y1 + 1, skin)
        rect(c, cx + 1, legs_y1 - 1, cx + 4, legs_y1 + 1, skin)
        rect(c, cx - 6, legs_y1 + 2, cx - 2, legs_y1 + 3, shade(shoe, 0.7))
        rect(c, cx + 1, legs_y1 + 2, cx + 5, legs_y1 + 3, shade(shoe, 0.7))
    elif style == 'rok':
        rk = hexc(spec.get('rok', '#5b4a3a'))
        rect(c, cx - 6 - wide, legs_y0 - 2, cx + 5 + wide, legs_y1 + 1, rk)
        rect(c, cx - 6 - wide, legs_y0 - 2, cx - 6 - wide, legs_y1 + 1, shade(rk, 0.8))
        for yy in range(legs_y0 + 2, legs_y1, 4):
            rect(c, cx - 5, yy, cx + 4, yy, shade(rk, 0.9))
        rect(c, cx - 5, legs_y1 + 2, cx - 2, legs_y1 + 3, shade(shoe, 0.7))
        rect(c, cx + 1, legs_y1 + 2, cx + 4, legs_y1 + 3, shade(shoe, 0.7))
    else:
        rect(c, cx - 5, legs_y0, cx - 1, legs_y1, pants)
        rect(c, cx + 1, legs_y0, cx + 5, legs_y1, pants)
        rect(c, cx, legs_y0, cx, legs_y0 + 5, shade(pants, 0.6))
        rect(c, cx - 5, legs_y0, cx - 5, legs_y1, shade(pants, 0.8))
        rect(c, cx + 5, legs_y0, cx + 5, legs_y1, shade(pants, 0.8))
        rect(c, cx - 6, legs_y1 + 1, cx - 1, legs_y1 + 3, shoe)
        rect(c, cx + 1, legs_y1 + 1, cx + 6, legs_y1 + 3, shoe)
        rect(c, cx - 6, legs_y1 + 3, cx - 1, legs_y1 + 3, shade(shoe, 0.7))
        rect(c, cx + 1, legs_y1 + 3, cx + 6, legs_y1 + 3, shade(shoe, 0.7))
    # badan
    ty0 = 17 + bob
    ty1 = 33
    rect(c, cx - 6 - wide, ty0, cx + 5 + wide, ty1, shirt)
    rect(c, cx - 6 - wide, ty0, cx - 6 - wide, ty1, shade(shirt, 0.8))
    rect(c, cx + 5 + wide, ty0, cx + 5 + wide, ty1, shade(shirt, 0.8))
    rect(c, cx - 6 - wide, ty1 - 1, cx + 5 + wide, ty1, shade(shirt, 0.85))
    pat = spec.get('pattern')
    if pat == 'batik':
        for yy in range(ty0 + 2, ty1, 3):
            for xx in range(cx - 5 - wide + (yy % 2), cx + 5 + wide, 3):
                c[yy, xx] = (*shade(shirt, 1.4), 255)
    if pat == 'jaket':
        j = hexc(spec.get('jaket', '#2e9b57'))
        rect(c, cx - 6 - wide, ty0, cx - 2, ty1, j)
        rect(c, cx + 1, ty0, cx + 5 + wide, ty1, j)
        rect(c, cx - 1, ty0, cx, ty1, shirt)
        rect(c, cx - 6 - wide, ty0, cx - 6 - wide, ty1, shade(j, 0.75))
        rect(c, cx - 5, ty0 + 6, cx - 3, ty0 + 7, (240, 240, 240))
    if spec.get('apron'):
        ap = hexc(spec['apron'])
        rect(c, cx - 4, ty0 + 3, cx + 3, ty1 + 6, ap)
        rect(c, cx - 4, ty0 + 3, cx - 4, ty1 + 6, shade(ap, 0.85))
    if spec.get('lanyard'):
        rect(c, cx - 1, ty0, cx, ty0 + 8, (200, 60, 60))
        rect(c, cx - 2, ty0 + 8, cx + 1, ty0 + 10, (240, 240, 240))
    if spec.get('koko'):
        for yy in range(ty0 + 1, ty0 + 8):
            c[yy, cx] = (*shade(shirt, 0.7), 255)
    # lengan
    for side in (-1, 1):
        ax = cx + side * (7 + wide)
        rect(c, min(ax, ax + side), ty0 + 1, max(ax, ax + side), ty1 - 4, shade(shirt, 0.92))
        hx = ax if side < 0 else ax
        rect(c, min(hx, hx + side), ty1 - 3, max(hx, hx + side), ty1 - 1, skin)
    if spec.get('tas'):
        t = hexc(spec['tas'])
        for k in range(ty1 - ty0 - 2):
            c[ty0 + k, cx - 5 + (k * 10) // (ty1 - ty0)] = (*t, 255)
    # leher & kepala
    rect(c, cx - 1, 15 + bob, cx + 1, 17 + bob, shade(skin, 0.9))
    hy0, hy1 = top + 2, top + 12
    rect(c, cx - 4, hy0 + 2, cx + 4, hy1, skin)
    rect(c, cx - 5, hy0 + 4, cx - 5, hy1 - 2, skin)
    rect(c, cx + 5, hy0 + 4, cx + 5, hy1 - 2, skin)
    rect(c, cx - 4, hy1, cx + 4, hy1, shade(skin, 0.88))
    # mata & mulut
    c[hy0 + 6, cx - 3] = (*OUTLINE[:3], 255)
    c[hy0 + 6, cx + 2] = (*OUTLINE[:3], 255)
    c[hy0 + 9, cx - 1:cx + 1] = (*shade(skin, 0.6), 255)
    if spec.get('glasses'):
        for xx in (cx - 4, cx - 3, cx - 2):
            c[hy0 + 5, xx] = (60, 60, 70, 255)
        for xx in (cx + 1, cx + 2, cx + 3):
            c[hy0 + 5, xx] = (60, 60, 70, 255)
    if spec.get('kumis'):
        rect(c, cx - 3, hy0 + 8, cx + 2, hy0 + 8, shade(hair, 1.0))
    # rambut / penutup kepala
    hs = spec.get('style', 'short')
    if hs == 'short':
        rect(c, cx - 5, hy0 - 1, cx + 5, hy0 + 2, hair)
        rect(c, cx - 5, hy0 + 2, cx - 4, hy0 + 5, hair)
        rect(c, cx + 4, hy0 + 2, cx + 5, hy0 + 5, hair)
    elif hs == 'ponytail':
        rect(c, cx - 5, hy0 - 1, cx + 5, hy0 + 3, hair)
        rect(c, cx - 5, hy0 + 3, cx - 4, hy0 + 8, hair)
        rect(c, cx + 5, hy0 + 3, cx + 7, hy0 + 11, hair)
    elif hs == 'hijab':
        hj = hexc(spec.get('hijab', '#8e3b46'))
        rect(c, cx - 6, hy0 - 1, cx + 6, hy0 + 3, hj)
        rect(c, cx - 6, hy0 + 3, cx - 5, hy0 + 14, hj)
        rect(c, cx + 5, hy0 + 3, cx + 6, hy0 + 14, hj)
        rect(c, cx - 6, hy0 + 12, cx + 6, hy0 + 15, hj)
        rect(c, cx - 3, hy0 + 14, cx + 3, hy0 + 15, shade(hj, 0.85))
        rect(c, cx - 4, hy0 + 2, cx + 4, hy0 + 3, shade(hj, 1.15))
    elif hs in ('peci', 'kopiah'):
        pc = hexc(spec.get('peci', '#1a1a1a'))
        rect(c, cx - 5, hy0 + 1, cx + 5, hy0 + 2, hair)
        rect(c, cx - 5, hy0 - 3, cx + 5, hy0 + 0, pc)
        rect(c, cx - 5, hy0 - 3, cx + 5, hy0 - 3, shade(pc, 1.3) if sum(pc) < 600 else shade(pc, 0.9))
    elif hs == 'cap':
        cp = hexc(spec.get('peci', '#2e9b57'))
        rect(c, cx - 5, hy0 - 2, cx + 5, hy0 + 1, cp)
        rect(c, cx + 1, hy0 + 1, cx + 8, hy0 + 2, shade(cp, 0.8))
        rect(c, cx - 5, hy0 + 2, cx - 4, hy0 + 4, hair)
    elif hs == 'gray':
        g = (170, 170, 175)
        rect(c, cx - 5, hy0 - 1, cx + 5, hy0 + 1, g)
        rect(c, cx - 5, hy0 + 1, cx - 4, hy0 + 4, g)
        rect(c, cx + 4, hy0 + 1, cx + 5, hy0 + 4, g)
    # outline
    alpha = c[:, :, 3] > 0
    dil = ndi.binary_dilation(alpha, structure=np.array([[0, 1, 0], [1, 1, 1], [0, 1, 0]]))
    edge = dil & ~alpha
    c[edge] = OUTLINE
    # bayangan kecil di dalam: gelapkan piksel tepi bawah-kanan dari massa (kesan volume)
    ys, xs = np.nonzero(c[:, :, 3])
    c = c[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    return c


SPECS = {
    'tati': dict(style='hijab', hijab='#8e3b46', shirt='#c0504d', pattern='batik', bottom='rok', rok='#5b4a3a', apron='#e8e0d0', wide=2, skin='#e0ac69', shoe='#6b5a4a'),
    'asep': dict(style='peci', peci='#1a1a1a', hair='#1a1a1a', shirt='#3b7ea1', bottom='pants', pants='#8a7a5a', skin='#d9a066', shoe='#7a5a3a', kumis=True),
    'rani': dict(style='hijab', hijab='#7a8fb5', shirt='#f0ece4', bottom='pants', pants='#3d4f7a', skin='#e8b88a', tas='#7a4a2a', shoe='#e8e8e8'),
    'fikri': dict(style='cap', peci='#2e9b57', hair='#111111', shirt='#222222', pattern='jaket', jaket='#2e9b57', bottom='pants', pants='#222a3a', skin='#cf9560', shoe='#3a3a3a'),
    'darto': dict(style='gray', shirt='#7a6a4f', bottom='sarong', sarong='#4a5a7a', skin='#d9a066', glasses=True, wide=1, shoe='#6a5a4a'),
    'mira': dict(style='ponytail', hair='#2a1a10', shirt='#d98c3a', apron='#6b4a2a', bottom='pants', pants='#3d4f7a', skin='#e0ac69', shoe='#e8e8e8'),
    'rw': dict(style='peci', peci='#1a1a1a', hair='#555555', shirt='#5b4630', pattern='batik', bottom='pants', pants='#222222', skin='#d9a066', kumis=True, glasses=True, shoe='#2a2a2a'),
    'yoga': dict(style='short', hair='#1a1a1a', shirt='#4a4a8a', lanyard=True, bottom='pants', pants='#3d4f7a', skin='#e0ac69', shoe='#e8e8e8'),
    'pelanggan1': dict(style='cap', peci='#a0452a', hair='#222222', shirt='#6b8e8e', bottom='pants', pants='#4a3a2a', skin='#d9a066', shoe='#5a4a3a'),
    'pelanggan2': dict(style='hijab', hijab='#c9a24f', shirt='#a0805a', bottom='rok', rok='#3a4a3a', skin='#e0ac69', shoe='#e8e8e8'),
    'ustaz': dict(style='kopiah', peci='#f0f0f0', hair='#222222', shirt='#f4f0e6', koko=True, bottom='sarong', sarong='#3a4a3a', skin='#d9a066', kumis=True, shoe='#6a5a4a'),
    'ujang': dict(style='cap', peci='#d8d2c0', hair='#222222', shirt='#c9b89a', apron='#3a5a7a', bottom='pants', pants='#4a4030', skin='#d9a066', kumis=True, shoe='#5a4a3a'),
    'imam': dict(style='peci', peci='#1a1a1a', hair='#1a1a1a', shirt='#8a8a8a', bottom='sarong', sarong='#6a3a3a', skin='#cf9560', kumis=True, shoe='#6a5a4a'),
}


def main():
    native = np.load('/tmp/native.npy', allow_pickle=True)
    frames = [np.array(f, dtype=np.uint8) for f in native]
    for s in SIZES:
        place(frames, s).save('%s/dimas_%d.png' % (OUT, s))
    for k, spec in SPECS.items():
        fr = [person(spec, 0), person(spec, 1)]
        for s in SIZES:
            place(fr, s).save('%s/%s_%d.png' % (OUT, k, s))
    # pratinjau
    prev = Image.new('RGBA', (900, 140), (110, 150, 110, 255))
    x = 4
    for k in ['dimas'] + list(SPECS):
        im = Image.open('%s/%s_50.png' % (OUT, k)).crop((0, 0, CELL[50], CELL[50]))
        prev.alpha_composite(im, (x, 70)); x += 52
    prev.resize((1800, 280), Image.NEAREST).save('/tmp/chars_preview.png')


if __name__ == '__main__':
    main()

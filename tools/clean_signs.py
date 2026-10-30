"""마을 그림 간판의 영어 글자를 지우고 작은 그림(아이콘)을 얹어요.
실행: python3 tools/clean_signs.py -> assets/backgrounds/acorn_village.png
"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, '..', 'art', 'raw', '18-acorn-village.png')
OUT = os.path.join(HERE, '..', 'assets', 'backgrounds', 'acorn_village.png')
ITEMS = os.path.join(HERE, '..', 'assets')

# 간판 영역과 얹을 그림
SIGNS = [
    ((465, 55, 605, 150), 'items/flour.png'),
    ((1055, 140, 1165, 225), 'furniture/pink_chair.png'),
    ((730, 280, 825, 365), 'items/butter_cookie.png'),
    ((240, 410, 335, 490), 'items/rolling_pin.png'),
    ((1075, 425, 1210, 520), 'furniture/picture.png'),
]


def clean(a, box):
    x0, y0, x1, y1 = box
    sub = a[y0:y1, x0:x1].astype(float)
    lum = sub.mean(axis=2)
    light = lum > 175
    lab, n = ndimage.label(light)
    if n == 0:
        return None
    sizes = ndimage.sum(light, lab, range(1, n + 1))
    panel = lab == (np.argmax(sizes) + 1)
    filled = ndimage.binary_fill_holes(panel)
    text = filled & ~panel
    text = ndimage.binary_dilation(text, iterations=1) & filled
    # 바깥에서 안쪽으로 주변 색을 번지게 해서 채워요
    known = ~text
    out = sub.copy()
    for _ in range(200):
        if known.all():
            break
        acc = np.zeros_like(out)
        cnt = np.zeros(known.shape)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            sh = np.roll(np.roll(known, dy, 0), dx, 1)
            vals = np.roll(np.roll(out, dy, 0), dx, 1)
            acc += vals * sh[..., None]
            cnt += sh
        grow = (~known) & (cnt > 0)
        out[grow] = acc[grow] / cnt[grow][:, None]
        known = known | grow
    a[y0:y1, x0:x1] = out.astype(np.uint8)
    ys, xs = np.where(filled)
    return (x0 + xs.mean(), y0 + ys.mean(), (xs.max() - xs.min()), (ys.max() - ys.min()))


def main():
    im = Image.open(SRC).convert('RGB')
    a = np.array(im)
    centers = [clean(a, b) for b, _ in SIGNS]
    im = Image.fromarray(a).convert('RGBA')
    for (box, icon), c in zip(SIGNS, centers):
        if c is None:
            continue
        ic = Image.open(os.path.join(ITEMS, icon)).convert('RGBA')
        bb = ic.getbbox()
        ic = ic.crop(bb)
        s = min(c[3] * 0.5, 26) / ic.height
        ic = ic.resize((max(1, int(ic.width * s)), max(1, int(ic.height * s))), Image.LANCZOS)
        im.alpha_composite(ic, (int(c[0] - ic.width / 2), int(c[1] - ic.height / 2)))
    im.convert('RGB').save(OUT)


if __name__ == '__main__':
    main()

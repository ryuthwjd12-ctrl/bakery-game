"""두 번째 아이콘·몬스터 시트에서 그림을 잘라요. python3 tools/icons2.py
- 41-cookie-bread-icons.png: 스페셜 요리 아이콘 (글자 아래 줄은 빼고 그림만)
- 39-ingredient-icons-2.png: 새 재료 아이콘
- 40-monsters.png: 몬스터 (왼쪽 그림=앞, 오른쪽=옆)"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..')
RAW = os.path.join(ROOT, 'art', 'raw')
OUT = os.path.join(ROOT, 'assets')


def cutout(sheet, box, tol=30, min_part=0.04):
    a = np.asarray(Image.open(os.path.join(RAW, sheet)).convert('RGB').crop(box)).astype(int)
    edge = np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]])
    bg = np.median(edge, axis=0)
    near = np.abs(a - bg).sum(axis=2) < tol
    lab, n = ndimage.label(near)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    fg = ~np.isin(lab, list(border))
    fg = ndimage.binary_opening(fg, iterations=1)
    l2, n2 = ndimage.label(fg)
    if n2:
        sz = ndimage.sum(fg, l2, range(1, n2 + 1))
        fg = np.isin(l2, [i + 1 for i, s in enumerate(sz) if s >= min_part * sz.max()])
    alpha = ndimage.gaussian_filter(fg.astype(float), 0.6) * 255
    im = Image.fromarray(np.dstack([a.astype(np.uint8), alpha.astype(np.uint8)]), 'RGBA')
    return im.crop(im.getbbox())


def fit(im, size):
    s = (size - 6) / max(im.size)
    im = im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.LANCZOS)
    c = Image.new('RGBA', (size, size))
    c.paste(im, ((size - im.width) // 2, (size - im.height) // 2), im)
    return c


# 41: 6열 x 4행, 그림 부분만
COLS = [(55, 220), (275, 440), (495, 662), (715, 882), (937, 1103), (1158, 1325)]
ROWS = [(38, 172), (225, 358), (402, 540), (578, 712)]
COOKIES = {
    'heart_cookie': (4, 0), 'flower_cookie': (0, 1), 'bear_cookie': (1, 1), 'macaron': (2, 1),
    'cinnamon_roll': (4, 2), 'croissant': (0, 2), 'acorn_cookie': (2, 3), 'mushroom_cookie': (3, 3),
    'snow_cookie': (5, 3), 'cream_bun': (0, 3), 'nut_cookie': (5, 1), 'choco_brioche': (5, 2),
}
for name, (c, r) in COOKIES.items():
    fit(cutout('41-cookie-bread-icons.png', (COLS[c][0], ROWS[r][0], COLS[c][1], ROWS[r][1])), 72).save(
        os.path.join(OUT, 'items', name + '.png'))

# 39: 8열 x 4행 칸(칸 테두리 안쪽)
IX = [32, 218, 404, 590, 776, 962, 1148, 1334]
IY = [113, 327, 534, 736]
ING = {'strawberry': (0, 2), 'apple': (4, 2), 'blueberry': (1, 2), 'lemon': (7, 1), 'walnut': (5, 3),
       'honey_jar': (6, 0), 'matcha': (2, 1), 'peach': (5, 2), 'grape': (7, 2), 'almond': (1, 3)}
for name, (c, r) in ING.items():
    fit(cutout('39-ingredient-icons-2.png', (IX[c] + 6, IY[r] + 6, IX[c] + 168, IY[r] + 176)), 72).save(
        os.path.join(OUT, 'items', name + '.png'))

# 40: 몬스터 (1536x1024) 2x3 쌍
os.makedirs(os.path.join(OUT, 'monsters'), exist_ok=True)
MON = {
    'squirrel': [(90, 80, 360, 330), (420, 80, 700, 330)],
    'mushroom': [(830, 80, 1090, 330), (1180, 80, 1430, 330)],
    'slime': [(110, 390, 360, 640), (430, 390, 670, 640)],
    'bee': [(830, 400, 1090, 640), (1190, 400, 1440, 640)],
    'dragon': [(110, 690, 370, 950), (420, 690, 690, 950)],
    'sheep': [(830, 720, 1090, 950), (1180, 720, 1440, 950)],
}
for name, boxes in MON.items():
    for tag, box in zip(['front', 'side'], boxes):
        im = cutout('40-monsters.png', box, tol=10 if name == 'sheep' else 26, min_part=0.02)
        s = 110 / im.height
        im = im.resize((round(im.width * s), 110), Image.LANCZOS)
        im.save(os.path.join(OUT, 'monsters', f'{name}_{tag}.png'))
print('done')

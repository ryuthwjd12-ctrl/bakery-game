"""4차 제미나이 그림(art/raw/44-52)을 게임에 넣어요. python3 tools/round4.py
- 44 큰 도토리 마을(영어 글자·생성 표시 지움, 1408x768로 맞춤)
- 45 다람쥐 주민 6마리 x 앞/뒤/옆(별을 지운 45u.png에서 잘라요), 46 다람쥐 가게 주인 5마리
- 47-51 가게 안 5곳, 52 새 주방(그릇장·냉장고·찬장은 눌렀을 때 통통 튀도록 따로 잘라요)"""
import os, sys
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import unstar as U
ROOT = os.path.join(HERE, '..')
RAW = os.path.join(ROOT, 'art', 'raw')
A = os.path.join(ROOT, 'assets')
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



for d in ['shops', 'animals', 'backgrounds', 'kitchen']:
    os.makedirs(os.path.join(A, d), exist_ok=True)


def load(i):
    return np.array(Image.open(os.path.join(RAW, '%d.png' % i)).convert('RGB')).astype(float)


def unstar(im):
    """오른쪽 아래 반투명 별(생성 표시)을 찾아 지워요. 별은 가장자리에서 120px 안쪽에 있어요."""
    h, w = im.shape[:2]
    cx0, cy0 = w - 120, h - 120
    box = (cx0 - 34, cy0 - 34, cx0 + 34, cy0 + 34)
    best = None
    for a in np.arange(0.15, 0.55, 0.05):
        for r in [22, 24, 26, 28]:
            for dx in [-3, 0, 3]:
                for dy in [-3, 0, 3]:
                    am = U.amap(cx0 + dx, cy0 + dy, r, 0.65, a, size=(h, w))
                    v = U.tv(U.restore(im, am), box)
                    if best is None or v < best[0]:
                        best = (v, a, r, cx0 + dx, cy0 + dy)
    _, a, r, cx, cy = best
    out = U.restore(im, U.amap(cx, cy, r, 0.65, a, size=(h, w)))
    return U.diffuse(out, U.ringmask(cx, cy, r, 0.65, band=0.12, size=(h, w)))


def save(im, rel):
    Image.fromarray(np.clip(im, 0, 255).astype(np.uint8)).save(os.path.join(A, rel))


# --- 44 마을 ---
v = load(44)
lum = v.mean(axis=2)
text = np.zeros(lum.shape, bool)
for x0, y0, x1, y1 in [(1145, 322, 1255, 346), (1035, 358, 1142, 382)]:
    text[y0:y1, x0:x1] = lum[y0:y1, x0:x1] < 130
text = ndimage.binary_dilation(text, iterations=2)
v = U.diffuse(v, text, 300)
v[text] += np.random.default_rng(2).normal(0, 2.5, (text.sum(), 3))
v = unstar(v)
Image.fromarray(np.clip(v, 0, 255).astype(np.uint8)).resize((1408, 768), Image.LANCZOS).save(
    os.path.join(A, 'backgrounds', 'acorn_village.png'))

# --- 47-51 가게 안 ---
for i, name in zip(range(47, 52), ['ingredient', 'interior', 'furniture', 'dish', 'weapon']):
    save(unstar(load(i)), 'shops/%s.png' % name)

# --- 52 주방 ---
k = unstar(load(52))
save(k, 'backgrounds/kitchen.png')
KITCHEN = {'cabinet': (84, 58, 468, 452), 'fridge': (470, 170, 705, 452), 'pantry': (730, 120, 975, 452)}
for name, (x0, y0, x1, y1) in KITCHEN.items():
    sub = k[y0:y1, x0:x1]
    al = np.zeros(sub.shape[:2])
    al[3:-3, 3:-3] = 1
    al = ndimage.gaussian_filter(al, 1.2) * 255
    Image.fromarray(np.dstack([np.clip(sub, 0, 255), al]).astype(np.uint8), 'RGBA').save(
        os.path.join(A, 'kitchen', name + '.png'))

# --- 45 다람쥐 주민: 2묶음 x 3줄, 묶음마다 앞/뒤/옆 ---
COLS = [[(55, 255), (262, 445), (452, 645)], [(735, 935), (940, 1115), (1120, 1325)]]
ROWS = [(35, 260), (275, 500), (515, 740)]
lines = ['class_name SpriteDataR4', 'extends RefCounted', '## tools/round4.py가 만든 파일이에요. 직접 고치지 말아요.', '',
         'const STRIPS := {']
n = 0
for r in ROWS:
    for grp in COLS:
        n += 1
        for (x0, x1), pose in zip(grp, ['front', 'back', 'right']):
            im = cutout('45u.png', (x0, r[0], x1, r[1]), tol=24)
            im.save(os.path.join(A, 'animals', 'sq%d_%s.png' % (n, pose)))
            lines.append('\t"sq%d_%s": ["animals/sq%d_%s", %d, %d, 1],' % (n, pose, n, pose, im.width, im.height))
lines.append('}')
open(os.path.join(ROOT, 'scripts', 'sprite_data_r4.gd'), 'w').write('\n'.join(lines) + '\n')

# --- 46 가게 주인(웃는 얼굴, 눈 감고 웃는 얼굴) ---
s46 = Image.fromarray(np.clip(unstar(load(46)), 0, 255).astype(np.uint8))
s46.save(os.path.join(RAW, '46-clean.png'))
KEEPERS = {
    'ingredient': [(60, 40, 255, 255), (295, 40, 490, 255)],
    'interior': [(60, 280, 255, 495), (295, 280, 490, 495)],
    'furniture': [(705, 280, 935, 495)],
    'dish': [(975, 280, 1175, 495)],
    'weapon': [(700, 520, 935, 740), (945, 520, 1180, 740)],
}
for name, boxes in KEEPERS.items():
    for j, b in enumerate(boxes):
        cutout('46-clean.png', b, tol=24).save(os.path.join(A, 'shops', 'keeper_%s%s.png' % (name, '' if j == 0 else '_happy')))
print('done')

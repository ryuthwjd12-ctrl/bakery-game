"""4차 그림 둘째 묶음(art/raw/54-57). python3 tools/round4b.py
- 54 남자 주인공 휘두르기 3장 + 마법 3장 → characters/male_attack, male_cast
- 55 몬스터 동작(걷기 3장, 아파함, 쓰러짐) → monsters/<종류>_w1..w3, _hurt, _faint
- 56 무기 아이콘 8개, 57 그릇·인테리어 아이콘"""
import os, sys
import numpy as np
from PIL import Image
from scipy import ndimage
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..')
RAW = os.path.join(ROOT, 'art', 'raw')
A = os.path.join(ROOT, 'assets')
src = open(os.path.join(HERE, 'icons2.py')).read()
exec(src[src.index('def cutout'):src.index('# 41:')])  # cutout, fit


def pad(box, p=8):
    return (box[0] - p, box[1] - p, box[2] + p, box[3] + p)


# --- 54 주인공: 걷기 그림과 키를 맞추고(서 있는 키 300px → 223px), 발이 같은 높이에 오게 ---
WALK_H = 223
S = WALK_H / 300.0


def strip(boxes, name):
    ims = [cutout('54.png', pad(b), tol=26) for b in boxes]
    ims = [im.resize((round(im.width * S), round(im.height * S)), Image.LANCZOS) for im in ims]
    # 다리(아래쪽 1/3)의 가운데를 몸 중심으로 봐요
    cxs = []
    for im in ims:
        al = np.asarray(im)[..., 3]
        legs = al[int(im.height * 0.7):] > 100
        xs = np.where(legs.any(axis=0))[0]
        cxs.append((xs.min() + xs.max()) / 2)
    half_w = int(max(max(c, im.width - c) for c, im in zip(cxs, ims))) + 4
    top = max(im.height for im in ims) - WALK_H / 2  # 가운데 위로 필요한 높이
    h = int(2 * max(top, WALK_H / 2)) + 4
    foot = h / 2 + WALK_H / 2
    out = Image.new('RGBA', (half_w * 2 * len(ims), h))
    for i, (im, c) in enumerate(zip(ims, cxs)):
        out.paste(im, (int(i * half_w * 2 + half_w - c), int(foot - im.height)), im)
    out.save(os.path.join(A, 'characters', name + '.png'))
    return '\t"%s": ["characters/%s", %d, %d, %d],' % (name, name, half_w * 2, h, len(ims))


lines = [strip([(94, 49, 330, 365), (531, 48, 793, 365), (957, 48, 1293, 364)], 'male_attack'),
         strip([(89, 427, 316, 733), (495, 427, 719, 731), (968, 436, 1192, 731)], 'male_cast')]

# --- 55 몬스터: 3줄 x 12칸 ---
X = [(40, 146), (191, 297), (342, 447), (487, 604), (653, 759), (794, 941), (1009, 1140), (1159, 1283),
     (1309, 1443), (1473, 1617), (1644, 1782), (1793, 1961)]
Y = [(18, 158), (190, 342), (359, 506)]
MON = {
    'slime': {'w': [(0, 0), (0, 1), (0, 2)], 'hurt': (0, 4), 'faint': (0, 5)},
    'mushroom': {'w': [(1, 0), (1, 1), (1, 2)], 'hurt': (1, 4)},
    'bee': {'w': [(2, 1), (2, 2), (0, 8)], 'hurt': (0, 9)},
    'dragon': {'w': [(0, 6), (0, 7), (1, 7)], 'hurt': (0, 10)},
    'sheep': {'w': [(1, 6), (1, 8), (1, 9)], 'hurt': (1, 10), 'faint': (1, 11)},
    'squirrel': {'w': [(2, 6), (2, 7), (2, 8)], 'hurt': (2, 10), 'faint': (2, 11)},
}
for k, d in MON.items():
    cells = [('w%d' % (i + 1), rc) for i, rc in enumerate(d['w'])] + [(n, d[n]) for n in ['hurt', 'faint'] if n in d]
    for n, (r, c) in cells:
        im = cutout('55.png', (X[c][0] - 6, Y[r][0] - 6, X[c][1] + 6, Y[r][1] + 6), tol=26)
        im.save(os.path.join(A, 'monsters', '%s_%s.png' % (k, n)))

# --- 56 무기 아이콘 ---
W = ['spatula', 'rolling_pin', 'piping_bag', 'cake_tin', 'star_cutter', 'honey_staff', 'walnut_hammer', 'candy_cane']
WB = [(92, 90, 309, 331), (413, 87, 641, 336), (738, 89, 962, 336), (1065, 87, 1293, 336),
      (91, 439, 309, 687), (419, 433, 633, 687), (739, 433, 965, 687), (1076, 433, 1277, 687)]
for n, b in zip(W, WB):
    fit(cutout('56.png', pad(b, 12), tol=26, min_part=0.02), 72).save(os.path.join(A, 'items', 'w_%s.png' % n))

# --- 57 그릇·인테리어 아이콘(칸마다 크림색 판) ---
PX = [(20, 312), (353, 645), (686, 978), (1019, 1311), (1352, 1644), (1685, 1964)]
PY = [(20, 248), (292, 508)]
ICONS = {'dish_flower': (0, 0), 'dish_acorn': (0, 1), 'dish_gold': (0, 2), 'deco_plant_big': (0, 3),
         'deco_plant': (0, 4), 'deco_lantern': (0, 5), 'deco_succulent': (1, 0), 'deco_wallpaper': (1, 1),
         'deco_rug': (1, 2), 'deco_lamp': (1, 3), 'deco_clock': (1, 4)}
for n, (r, c) in ICONS.items():
    fit(cutout('57.png', (PX[c][0], PY[r][0], PX[c][1], PY[r][1]), tol=22, min_part=0.02), 72).save(
        os.path.join(A, 'items', n + '.png'))

# 남자 주인공 공격 그림 정보를 SpriteDataR4에 더해요
p = os.path.join(ROOT, 'scripts', 'sprite_data_r4.gd')
t = open(p).read().rstrip()
t = '\n'.join(l for l in t.split('\n') if 'male_attack' not in l and 'male_cast' not in l)
t = t[:t.rindex('}')] + '\n'.join(lines) + '\n}\n'
open(p, 'w').write(t)
print('done')

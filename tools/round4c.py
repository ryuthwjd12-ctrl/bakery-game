"""4차 그림 셋째 묶음: 숲길(58), 마을마다 다른 지도(66 꽃잎 언덕, 67 조개 해변, 65 과수원, 68 눈꽃 마을), 넓은 홀(53). python3 tools/round4c.py [--annex|--orchard]
생성 표시(별)를 지우고, 조개 해변 간판의 영어 글자를 지워 빈 간판으로 만들어요.
63(네 칸 참고 그림)은 글자가 들어 있고 동물이 달라서 쓰지 않아요."""
import os, sys
import numpy as np
from PIL import Image
from scipy import ndimage
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import unstar as U
ROOT = os.path.join(HERE, '..')
src = open(os.path.join(HERE, 'round4.py')).read()
exec(src[src.index('def unstar'):src.index('def save')])

MAPS = {58: "forest_path", 66: "petal_hill", 67: "seashell_beach", 68: "snowflake_village"} if not ({"--annex", "--orchard"} & set(sys.argv)) else {}
for i, name in MAPS.items():
    im = np.array(Image.open(os.path.join(ROOT, 'art', 'raw', '%d.png' % i)).convert('RGB')).astype(float)
    if i == 60:  # 예전 조개 해변 그림(지금은 67을 써요)
        # 간판 테두리(가장자리에 닿는 큰 선)는 두고, 그 안에 떠 있는 글자 덩어리만 간판 바탕색으로 칠해요
        lum = im.mean(axis=2)
        for x0, y0, x1, y1 in [(812, 262, 882, 320), (874, 312, 974, 384)]:  # Fish Shop, Surf Shack
            sub = im[y0:y1, x0:x1]
            dark = lum[y0:y1, x0:x1] < 175
            lab, n = ndimage.label(dark)
            edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]])))
            sizes = ndimage.sum(dark, lab, range(1, n + 1))
            text = np.isin(lab, [i + 1 for i in range(n) if (i + 1) not in edge and sizes[i] < 600])
            text = ndimage.binary_dilation(text, iterations=1) & ~np.isin(lab, list(edge - {0}))
            board = np.median(sub[(lum[y0:y1, x0:x1] > 190)], axis=0)
            if x0 == 812:
                board_fish = board
            sub[text] = board + np.random.default_rng(3).normal(0, 2, (text.sum(), 3))
            im[y0:y1, x0:x1] = sub
        # 테두리에 붙어 남은 "p" 한 글자
        x0, y0, x1, y1 = 845, 285, 859, 304
        sub = im[y0:y1, x0:x1]
        m = sub.mean(axis=2) < 175
        sub[m] = board_fish + np.random.default_rng(4).normal(0, 2, (m.sum(), 3))
    im = unstar(im)
    Image.fromarray(np.clip(im, 0, 255).astype(np.uint8)).resize((1408, 768), Image.LANCZOS).save(
        os.path.join(ROOT, 'assets', 'maps', name + '.png'))
    print(name)

ALL = len(sys.argv) == 1

# 53 넓은 빈 홀 → 가게 별관(1.3배로 키워 2579x686)
if ALL or "--annex" in sys.argv:
    im = unstar(np.array(Image.open(os.path.join(ROOT, 'art', 'raw', '53.png')).convert('RGB')).astype(float))
    Image.fromarray(np.clip(im, 0, 255).astype(np.uint8)).resize((2579, 686), Image.LANCZOS).save(
        os.path.join(ROOT, 'assets', 'backgrounds', 'annex.png'))
    print('annex')

# 65 과일 과수원(여러 과일) → 1408x768로 맞춰 61번 대신 과수원 지도로 써요
if ALL or "--orchard" in sys.argv:
    im = unstar(np.array(Image.open(os.path.join(ROOT, 'art', 'raw', '65.png')).convert('RGB')).astype(float))
    Image.fromarray(np.clip(im, 0, 255).astype(np.uint8)).resize((1408, 768), Image.LANCZOS).save(
        os.path.join(ROOT, 'assets', 'maps', 'apple_orchard.png'))
    print('orchard')

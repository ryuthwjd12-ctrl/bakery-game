"""채집하면 열매가 사라진 모습을 보여 주는 덮개 그림을 만들어요. python3 tools/gather_overlays.py
각 덤불 칸에서 빨간·보라 열매를 찾아 주변 잎 색으로 메운 그림(같은 위치에 덮어씌움)을 저장해요.
결과: assets/gather/<지도>_<id>.png 와 scripts/gather_data.gd (위치·크기)"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import unstar as U
ROOT = os.path.join(HERE, '..')
OUT = os.path.join(ROOT, 'assets', 'gather')
os.makedirs(OUT, exist_ok=True)

SPOTS = {
    'backgrounds/acorn_village': {
        'bush_left': (5, 232, 107, 336), 'bed_west': (290, 408, 408, 496), 'bed_plaza': (768, 503, 890, 592),
    },
    'maps/forest_path': {
        'strawberry_patch': (995, 345, 1205, 515), 'berry_bush': (828, 272, 958, 400),
        'berry_bottom': (692, 350, 888, 556), 'berry_left': (342, 398, 526, 536),
    },
    'maps/apple_orchard': {
        'apple': (660, 490, 775, 605), 'peach': (418, 210, 524, 322), 'lemon': (979, 240, 1085, 332),
        'grape': (0, 285, 158, 422), 'blueberry': (0, 405, 116, 487), 'strawberry': (52, 225, 199, 302),
    },
}
lines = ['class_name GatherData', 'extends RefCounted', '## tools/gather_overlays.py가 만든 파일이에요. 직접 고치지 말아요.',
         '## 지도 → {id: 덮개 왼쪽 위 위치}', '', 'const SPOTS := {']
for mp, spots in SPOTS.items():
    a = np.array(Image.open(os.path.join(ROOT, 'assets', mp + '.png')).convert('RGB')).astype(float)
    lines.append('\t"%s": {' % mp)
    for sid, (x0, y0, x1, y1) in spots.items():
        sub = a[y0:y1, x0:x1].copy()
        r, g, b = sub[..., 0], sub[..., 1], sub[..., 2]
        fruit = ((r > 120) & (r - g > 45) & (r - b > 15)) | ((b > 80) & (r > 80) & (b - g > 25) & (r - g > 10))
        if mp == 'maps/apple_orchard':
            fruit |= ((r > 200) & (g > 170) & (b < 120) & (r - b > 110))  # 레몬
            fruit |= ((b > 110) & (b - r > 35) & (b - g > 25))  # 블루베리
        fruit = ndimage.binary_opening(fruit, iterations=1)
        fruit = ndimage.binary_fill_holes(ndimage.binary_closing(fruit, iterations=2))
        fruit = ndimage.binary_dilation(fruit, iterations=4)  # 열매 테두리·꼭지까지
        filled = sub.copy()
        lum = sub.mean(axis=2)
        lab, n = ndimage.label(fruit)
        H, W = fruit.shape
        avoid = ndimage.binary_dilation(fruit, iterations=2)
        offs = sorted([(dx, dy) for dx in range(-40, 41, 2) for dy in range(-40, 41, 2) if (dx, dy) != (0, 0)],
                      key=lambda o: o[0] ** 2 + o[1] ** 2)
        for i in range(1, n + 1):
            blob = lab == i
            ring = ndimage.binary_dilation(blob, iterations=4) & ~ndimage.binary_dilation(blob, iterations=1)
            ring &= (lum > 70) & ~fruit
            if ring.sum() < 5:
                continue
            col = np.median(sub[ring], axis=0)
            ys, xs = np.nonzero(blob)
            # 열매 대신 근처 잎 무늬를 통째로 옮겨 붙여요(흐린 얼룩이 아니라 잎 그림이 이어져 보여요)
            best = None
            for dx, dy in offs[:600]:
                sy, sx = ys + dy, xs + dx
                if sy.min() < 0 or sx.min() < 0 or sy.max() >= H or sx.max() >= W:
                    continue
                if avoid[sy, sx].any():
                    continue
                d = np.abs(sub[sy, sx].mean(axis=0) - col).sum()
                if best is None or d < best[0]:
                    best = (d, dx, dy)
                if d < 25:
                    break
            if best is not None and best[0] < 90:
                filled[ys, xs] = sub[ys + best[2], xs + best[1]]
            else:
                rng = np.random.default_rng(1)
                filled[blob] = col + rng.normal(0, 4, (blob.sum(), 3))
        alpha = ndimage.gaussian_filter(ndimage.binary_dilation(fruit, iterations=1).astype(float), 0.8)
        rgba = np.dstack([np.clip(filled, 0, 255), alpha * 255]).astype(np.uint8)
        name = mp.split('/')[-1] + '_' + sid
        Image.fromarray(rgba, 'RGBA').save(os.path.join(OUT, name + '.png'))
        lines.append('\t\t"%s": Vector2(%d, %d),' % (sid, x0, y0))
        print(name, int(fruit.sum()))
    lines.append('\t},')
lines.append('}')
open(os.path.join(ROOT, 'scripts', 'gather_data.gd'), 'w').write('\n'.join(lines) + '\n')

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
        'bush_left': (0, 250, 90, 350), 'bush_right': (1345, 262, 1408, 350),
        'bush_bottom_left': (290, 628, 605, 768), 'bush_bottom_right': (795, 628, 1118, 768),
    },
    'maps/forest_path': {
        'strawberry_patch': (255, 385, 495, 548), 'berry_bush': (505, 615, 665, 740),
        'berry_bottom': (390, 755, 640, 860),
    },
    'maps/apple_orchard': {
        'apple_tree_a': (110, 175, 240, 330), 'apple_tree_b': (285, 385, 425, 530),
        'apple_tree_c': (115, 785, 260, 930),
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
        fruit = ndimage.binary_opening(fruit, iterations=1)
        fruit = ndimage.binary_fill_holes(ndimage.binary_closing(fruit, iterations=2))
        fruit = ndimage.binary_dilation(fruit, iterations=5)  # 열매 테두리·꼭지까지
        filled = sub.copy()
        lum = sub.mean(axis=2)
        lab, n = ndimage.label(fruit)
        rng = np.random.default_rng(1)
        for i in range(1, n + 1):
            blob = lab == i
            ring = ndimage.binary_dilation(blob, iterations=5) & ~ndimage.binary_dilation(blob, iterations=1)
            ring &= (lum > 85) & ~fruit
            if ring.sum() < 5:
                continue
            col = np.median(sub[ring], axis=0)
            filled[blob] = col + rng.normal(0, 4, (blob.sum(), 3))
        filled = filled * 0.85 + ndimage.gaussian_filter(filled, (1.5, 1.5, 0)) * 0.15
        alpha = ndimage.gaussian_filter(ndimage.binary_dilation(fruit, iterations=2).astype(float), 1.2)
        rgba = np.dstack([np.clip(filled, 0, 255), alpha * 255]).astype(np.uint8)
        name = mp.split('/')[-1] + '_' + sid
        Image.fromarray(rgba, 'RGBA').save(os.path.join(OUT, name + '.png'))
        lines.append('\t\t"%s": Vector2(%d, %d),' % (sid, x0, y0))
        print(name, int(fruit.sum()))
    lines.append('\t},')
lines.append('}')
open(os.path.join(ROOT, 'scripts', 'gather_data.gd'), 'w').write('\n'.join(lines) + '\n')

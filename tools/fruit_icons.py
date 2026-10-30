"""과일 디저트 임시 아이콘: 41번 쿠키 시트의 그림에 색을 입히고 과일 아이콘을 작게 얹어요.
제미나이 과일 디저트 아이콘이 오면 바꿔요. python3 tools/fruit_icons.py"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..')
A = os.path.join(ROOT, 'assets', 'items')
src = open(os.path.join(HERE, 'icons2.py')).read()
exec(src[src.index('RAW ='):src.index('# 41:')].replace("os.path.join(ROOT, 'art', 'raw')", "os.path.join(ROOT, 'art', 'raw')"))
exec(src[src.index('# 41:'):src.index('COOKIES')])


def tint(im, rgb, amount):
    a = np.asarray(im).astype(float)
    lum = a[..., :3].mean(axis=2, keepdims=True) / 255
    col = np.array(rgb, float) * (0.55 + 0.6 * lum)
    a[..., :3] = a[..., :3] * (1 - amount) + col * amount
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), 'RGBA')


DESSERTS = {  # 이름: (시트 칸, 색, 색 세기, 얹을 과일)
    'lemon_cookie': ((3, 0), (250, 220, 90), 0.45, 'lemon'),
    'peach_tart': ((4, 1), (245, 160, 120), 0.4, 'peach'),
    'blueberry_muffin': ((1, 3), (150, 120, 200), 0.35, 'blueberry'),
    'grape_roll': ((4, 2), (170, 110, 190), 0.4, 'grape'),
}
for name, ((c, r), rgb, amt, fruit) in DESSERTS.items():
    base = fit(cutout('41-cookie-bread-icons.png', (COLS[c][0], ROWS[r][0], COLS[c][1], ROWS[r][1])), 72)
    base = tint(base, rgb, amt)
    f = Image.open(os.path.join(A, fruit + '.png')).resize((34, 34), Image.LANCZOS)
    base.alpha_composite(f, (38, 38))
    base.save(os.path.join(A, name + '.png'))
print('ok')

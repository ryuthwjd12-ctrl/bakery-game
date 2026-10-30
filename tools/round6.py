"""6차 그림(art/raw/80-82). python3 tools/round6.py
- 80 다른 마을 가게 주인 4명(토끼·고양이·사슴·펭귄), 웃음/기쁨 두 표정 → shops/keeper_<마을>(_happy)
- 81 눈꽃 마을 얼음 수정 상점 안 → shops/snow
- 82 버튼 아이콘(글자 포함) 중 장비·지도·업적·설정·도감만 → ui/btn_*"""
import os, sys
import numpy as np
from PIL import Image
from scipy import ndimage
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import unstar as U
ROOT = os.path.join(HERE, '..')
RAW = os.path.join(ROOT, 'art', 'raw')
A = os.path.join(ROOT, 'assets')
src = open(os.path.join(HERE, 'icons2.py')).read()
exec(src[src.index('def cutout'):src.index('# 41:')])
r4 = open(os.path.join(HERE, 'round4.py')).read()
exec(r4[r4.index('def unstar'):r4.index('def save')])

# 80: 한 줄에 두 마리씩, 각자 웃음/기쁨
K = [('petal', (95, 30, 265, 377), (405, 30, 575, 377)),
     ('beach', (753, 61, 958, 377), (1075, 61, 1281, 377)),
     ('orchard', (78, 425, 285, 749), (392, 425, 598, 749)),
     ('snow', (774, 459, 993, 749), (1096, 459, 1315, 749))]
for name, a, b in K:
    for box, suf in [(a, ''), (b, '_happy')]:
        cutout('80.png', (box[0] - 6, box[1] - 6, box[2] + 6, box[3] + 6), tol=22).save(
            os.path.join(A, 'shops', 'keeper_%s%s.png' % (name, suf)))

im = unstar(np.array(Image.open(os.path.join(RAW, '81.png')).convert('RGB')).astype(float))
Image.fromarray(np.clip(im, 0, 255).astype(np.uint8)).resize((1408, 768)).save(os.path.join(A, 'shops', 'snow.png'))

# 82: 동그라미 버튼만 잘라서 바깥은 투명하게
sheet = Image.open(os.path.join(RAW, '82.png')).convert('RGBA')
os.makedirs(os.path.join(A, 'ui'), exist_ok=True)
CX, CY, R = [181, 521, 860, 1195], [140, 384, 628], 104
yy, xx = np.mgrid[0:2 * R, 0:2 * R]
mask = (np.hypot(xx - R + 0.5, yy - R + 0.5) <= R - 1).astype(np.uint8) * 255
for name, c, r in [('achieve', 0, 0), ('equip', 1, 0), ('map', 0, 1), ('settings', 2, 2), ('book', 0, 2)]:
    cell = sheet.crop((CX[c] - R, CY[r] - R, CX[c] + R, CY[r] + R))
    cell.putalpha(Image.fromarray(mask))
    cell.resize((96, 96), Image.LANCZOS).save(os.path.join(A, 'ui', 'btn_%s.png' % name))
print('ok')

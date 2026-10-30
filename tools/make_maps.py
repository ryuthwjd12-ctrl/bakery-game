"""다른 지역 지도 그림을 만들어요. python3 tools/make_maps.py
- 20-26 시트의 작은 지도들을 3배로 키워 숲길·사과 과수원·조개 해변 지도로
- 19(꽃잎 언덕), 37(눈꽃 마을)은 그대로 쓰고 생성 표시를 지워요
- 세계 지도는 영어 글자를 지워요(한국어 이름은 게임에서 올려요)"""
import os, sys
import numpy as np
from PIL import Image, ImageFilter, ImageDraw
from scipy import ndimage
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import unstar as U
ROOT = os.path.join(HERE, '..')
RAW = os.path.join(ROOT, 'art', 'raw')
OUT = os.path.join(ROOT, 'assets', 'maps')
os.makedirs(OUT, exist_ok=True)
sheet = Image.open(os.path.join(RAW, '20-26-maps-worldmap-boss.png')).convert('RGB')


def up(box, name, k=3):
    c = sheet.crop(box)
    u = c.resize((c.width * k, c.height * k), Image.LANCZOS).filter(ImageFilter.UnsharpMask(2, 70, 2))
    u.save(os.path.join(OUT, name + '.png'))
    print(name, u.size)


up((16, 432, 474, 728), 'forest_path')
up((490, 47, 936, 383), 'apple_orchard')
up((16, 47, 474, 383), 'seashell_beach')

for src, name in [('19-petal-hill.png', 'petal_hill'), ('37-snowflake-village.png', 'snowflake_village')]:
    im = np.array(Image.open(os.path.join(RAW, src)).convert('RGB')).astype(float)
    out = U.restore(im, U.amap(1287, 648, 24, 0.65, 0.3))
    out = U.diffuse(out, U.ringmask(1287, 648, 24, 0.65, band=0.12))
    Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).save(os.path.join(OUT, name + '.png'))

# 꽃잎 언덕 그림의 사람(남자아이)을 지워요: 사람은 주인공 혼자여야 해요. 그 자리에는 게임에서 토끼 상인이 서요.
ph = np.array(Image.open(os.path.join(OUT, 'petal_hill.png')).convert('RGB')).astype(float)
m = Image.new('L', (1408, 768), 0)
ImageDraw.Draw(m).ellipse((1036, 258, 1088, 362), fill=1)
ph = U.diffuse(ph, np.array(m).astype(bool), 500)
Image.fromarray(np.clip(ph, 0, 255).astype(np.uint8)).save(os.path.join(OUT, 'petal_hill.png'))

# 세계 지도: 글자 지우기
wm = sheet.crop((515, 425, 945, 728))
a = np.array(wm).astype(float)
lum = a.mean(axis=2)
yy, xx = np.mgrid[0:a.shape[0], 0:a.shape[1]]
text = np.zeros(lum.shape, bool)
for (x0, y0, x1, y1) in [(20, 66, 110, 86), (168, 66, 262, 86), (330, 66, 420, 86), (2, 172, 145, 210),
                         (160, 160, 280, 196), (300, 170, 425, 192), (162, 270, 280, 292), (300, 270, 425, 292)]:
    text[y0:y1, x0:x1] = True
dark = (lum < 120) & text
dark = ndimage.binary_dilation(dark, iterations=2) & text
out = U.diffuse(a, dark, 300)
w2 = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))
w2 = w2.resize((w2.width * 2, w2.height * 2), Image.LANCZOS)
w2.save(os.path.join(OUT, 'world_map.png'))
print('done')

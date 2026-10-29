"""배경 그림 정리: 홀 메뉴판의 영어 글자를 지우고, 모든 배경 오른쪽 아래의 생성 표시(반투명 별)를 지워요.
python3 tools/clean_backgrounds.py  (clean_signs.py, draw_kitchen.py 다음에 실행)"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import unstar as U
ROOT = os.path.join(HERE, '..')
BG = os.path.join(ROOT, 'assets', 'backgrounds')


def erase_menu_text(im):
    poly = [(590, 281), (652, 253), (668, 360), (603, 387)]
    m = Image.new('L', (im.shape[1], im.shape[0]), 0)
    ImageDraw.Draw(m).polygon(poly, fill=1)
    inside = ndimage.binary_erosion(np.array(m).astype(bool), iterations=3)
    lum = im.mean(axis=2)
    yy = np.mgrid[0:im.shape[0], 0:im.shape[1]][0]
    letters = inside & (lum > 95) & (yy < 294)
    letters = ndimage.binary_dilation(letters, iterations=2) & inside & (yy < 294)
    out = U.diffuse(im, letters, 400)
    out[letters] += np.random.default_rng(1).normal(0, 2.0, (letters.sum(), 3))
    return out


def unstar(im):
    out = U.restore(im, U.amap(1287, 648, 24, 0.65, 0.3))
    return U.diffuse(out, U.ringmask(1287, 648, 24, 0.65, band=0.12))


def save(im, name):
    Image.fromarray(np.clip(im, 0, 255).astype(np.uint8)).save(os.path.join(BG, name))


hall = np.array(Image.open(os.path.join(ROOT, 'art/raw/16-bakery-hall.png')).convert('RGB')).astype(float)
save(unstar(erase_menu_text(hall)), 'hall.png')
for name in ['kitchen.png', 'acorn_village.png', 'title.png']:
    im = np.array(Image.open(os.path.join(BG, name)).convert('RGB')).astype(float)
    save(unstar(im), name)
print('done')

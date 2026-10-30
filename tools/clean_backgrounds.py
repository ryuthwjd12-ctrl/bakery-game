"""배경 그림 정리: 홀 메뉴판의 영어 글자를 지우고, 모든 배경 오른쪽 아래의 생성 표시(반투명 별)를 지워요.
python3 tools/clean_backgrounds.py [--all]  (--all 은 clean_signs.py, draw_kitchen.py 를 다시 돌린 뒤에만)"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
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
empty = np.array(Image.open(os.path.join(ROOT, 'art/raw/33-bakery-empty-room.png')).convert('RGB')).astype(float)


def open_right_door(im):
    """오른쪽 안쪽 문 너머(원래 개수대)를 빈 방 그림의 밝은 통로로 바꿔 별관으로 이어지게 해요."""
    m = Image.new('L', (im.shape[1], im.shape[0]), 0)
    ImageDraw.Draw(m).polygon([(903, 70), (998, 120), (998, 345), (903, 300)], fill=255)
    m = np.array(m.filter(ImageFilter.GaussianBlur(1.5))).astype(float)[..., None] / 255
    return im * (1 - m) + empty * m


save(unstar(open_right_door(erase_menu_text(hall))), 'hall.png')
save(unstar(empty), 'annex.png')
# 주방·마을·제목 그림은 다른 스크립트가 만든 결과를 고쳐요. 두 번 지우면 안 되니 --all 일 때만.
for name in (['kitchen.png', 'acorn_village.png', 'title.png'] if '--all' in sys.argv else []):
    im = np.array(Image.open(os.path.join(BG, name)).convert('RGB')).astype(float)
    save(unstar(im), name)
print('done')

"""가구 있는 가게 그림(16)과 빈 방 그림(33)의 차이로 가구를 떼어내요. 그림체·원근이 방과 똑같은 가구 스프라이트가 생겨요.
python3 tools/cut_furniture.py"""
import os
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..')
a = np.array(Image.open(os.path.join(ROOT, 'art/raw/16-bakery-hall.png')).convert('RGB')).astype(float)
b = np.array(Image.open(os.path.join(ROOT, 'art/raw/33-bakery-empty-room.png')).convert('RGB')).astype(float)
d = ndimage.gaussian_filter(np.abs(a - b).sum(axis=2), 1.0)


def cut(box, name, thr=22, keep_poly=None, drop_poly=None):
    x0, y0, x1, y1 = box
    m = d[y0:y1, x0:x1] > thr
    m = ndimage.binary_opening(m, iterations=1)
    m = ndimage.binary_closing(m, iterations=4)
    m = ndimage.binary_fill_holes(m)
    W, H = x1 - x0, y1 - y0
    for poly, val in ((keep_poly, 0), (drop_poly, 1)):
        if poly:
            pm = Image.new('L', (W, H), 0)
            ImageDraw.Draw(pm).polygon([(x - x0, y - y0) for x, y in poly], fill=1)
            pm = np.array(pm).astype(bool)
            m = m & ~pm if val else m & pm
    lab, n = ndimage.label(m)
    if n > 1:
        sizes = ndimage.sum(m, lab, range(1, n + 1))
        m = lab == (int(np.argmax(sizes)) + 1)
    alpha = ndimage.gaussian_filter(m.astype(float), 0.8)
    rgba = np.dstack([a[y0:y1, x0:x1], alpha * 255]).astype(np.uint8)
    im = Image.fromarray(rgba, 'RGBA')
    bb = im.getbbox()
    im.crop(bb).save(os.path.join(ROOT, 'assets/furniture', name + '.png'))
    # 발 기준점(바닥 중심)을 출력해요
    print(name, 'origin_in_scene', (x0 + bb[0], y0 + bb[1]), 'size', (bb[2] - bb[0], bb[3] - bb[1]))


cut((682, 368, 926, 596), 'table_set', thr=30)
cut((1228, 345, 1340, 545), 'plant_big')
cut((90, 395, 190, 530), 'plant_small')

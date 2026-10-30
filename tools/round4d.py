"""마을 주민 시트(art/raw/69 펭귄, 70 토끼, 71 사슴)를 잘라 동물 그림 줄로 만들어요. python3 tools/round4d.py
줄마다 한 마리(4마리), 칸 순서: 앞, 뒤, 옆(소품 있음) ..., 앉아 기다리기, 먹기, 웃기.
걷는 그림 칸은 소품이 빠져 있어서, 옆모습(소품 있는 칸)을 통통 튀게 걸려요."""
import os
import numpy as np
from PIL import Image, ImageOps
from scipy import ndimage
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..')
RAW = os.path.join(ROOT, 'art', 'raw')
A = os.path.join(ROOT, 'assets', 'animals')
src = open(os.path.join(HERE, 'icons2.py')).read()
exec(src[src.index('def cutout'):src.index('def fit')])

SHEETS = {  # 시트: (이름 앞글자, 칸 수, {동작: [칸...]})
    '69.png': ('pg', 10, {'front': [0], 'back': [1], 'right': [2, 3], 'wait': [7], 'eat': [8], 'happy': [9]}),
    '70.png': ('rb', 10, {'front': [0], 'back': [1], 'right': [2, 3], 'wait': [7], 'eat': [8], 'happy': [9]}),
    '71.png': ('dr', 8, {'front': [0], 'back': [1], 'right': [2], 'wait': [5], 'eat': [6], 'happy': [7]}),
}


def boxes(sheet, cols):
    a = np.asarray(Image.open(os.path.join(RAW, sheet)).convert('RGB')).astype(int)
    bg = np.median(np.concatenate([a[0], a[-1]]), axis=0)
    fg = ndimage.binary_closing(np.abs(a - bg).sum(2) > 45, iterations=3)
    lab, n = ndimage.label(fg)
    sz = ndimage.sum(fg, lab, range(1, n + 1))
    objs = [o for o, s in zip(ndimage.find_objects(lab), sz) if s > 2500]
    bb = [(o[1].start, o[0].start, o[1].stop, o[0].stop) for o in objs]
    rows = sorted(bb, key=lambda b: (b[1] + b[3]) / 2)
    out = []
    for r in range(4):
        row = sorted(rows[r * cols:(r + 1) * cols], key=lambda b: b[0])
        out.append(row)
    return out


lines = ['class_name SpriteDataR5', 'extends RefCounted', '## tools/round4d.py가 만든 파일이에요. 직접 고치지 말아요.', '',
         'const STRIPS := {']
for sheet, (pre, cols, poses) in SHEETS.items():
    grid = boxes(sheet, cols)
    for r in range(4):
        for pose, cs in poses.items():
            ims = []
            for c in cs:
                x0, y0, x1, y1 = grid[r][c]
                ims.append(cutout(sheet, (x0 - 6, y0 - 6, x1 + 6, y1 + 6), tol=22))
            w = max(i.width for i in ims)
            h = max(i.height for i in ims)
            strip = Image.new('RGBA', (w * len(ims), h))
            for k, im in enumerate(ims):
                strip.paste(im, (k * w + (w - im.width) // 2, h - im.height), im)
            name = '%s%d_%s' % (pre, r + 1, pose)
            strip.save(os.path.join(A, name + '.png'))
            lines.append('\t"%s": ["animals/%s", %d, %d, %d],' % (name, name, w, h, len(ims)))
lines.append('}')
open(os.path.join(ROOT, 'scripts', 'sprite_data_r5.gd'), 'w').write('\n'.join(lines) + '\n')
print('ok')

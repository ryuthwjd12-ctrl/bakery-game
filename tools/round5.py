"""5차 그림(art/raw/72-78). python3 tools/round5.py
- 72 고양이 주민 4마리 → round4d.py가 잘라요(ct1~4)
- 73 강아지 알바생 → characters/puppy_* (예전 그림 대신)
- 74 눈사람 거인 → monsters/snowman_*(서기·걷기·던지기·아파함·녹음)
- 75 과일 디저트 아이콘(머핀·타르트·롤; 레몬 칸은 그냥 레몬이라 안 써요)
- 76 버섯·벌·아기 용의 걷기·아파함·쓰러짐
- 77 꽃잎 언덕 꿀가게 안, 78 조개 해변 가게 안"""
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


def pad(b, p=6):
    return (b[0] - p, b[1] - p, b[2] + p, b[3] + p)


def strip(sheet, boxes, out, foot=True):
    ims = [cutout(sheet, pad(b), tol=22) for b in boxes]
    w = max(i.width for i in ims)
    h = max(i.height for i in ims)
    s = Image.new('RGBA', (w * len(ims), h))
    for k, im in enumerate(ims):
        s.paste(im, (k * w + (w - im.width) // 2, h - im.height if foot else (h - im.height) // 2), im)
    s.save(os.path.join(A, out + '.png'))
    return w, h, len(ims)


lines = ['class_name SpriteDataR6', 'extends RefCounted', '## tools/round5.py가 만든 파일이에요. 직접 고치지 말아요.', '',
         'const STRIPS := {']
# 73 강아지: 1줄(앞, 뒤, 옆 걷기 5장), 4줄(쟁반 앞, 쟁반 옆 3장, 빗자루 2장, 기쁨)
P = {
    'front': [(52, 45, 164, 196)], 'back': [(202, 45, 314, 196)],
    'right': [(335, 47, 437, 195), (583, 47, 685, 196), (706, 46, 805, 196), (826, 46, 926, 196)],
    'tray': [(197, 594, 349, 751), (407, 590, 558, 751), (597, 590, 748, 751)],
    'sweep': [(827, 589, 965, 751), (1035, 589, 1148, 751)],
}
for k, bs in P.items():
    w, h, n = strip('73.png', bs, 'characters/puppy_' + k)
    lines.append('\t"puppy_%s": ["characters/puppy_%s", %d, %d, %d],' % (k, k, w, h, n))
lines.append('}')
open(os.path.join(ROOT, 'scripts', 'sprite_data_r6.gd'), 'w').write('\n'.join(lines) + '\n')

# 74 눈사람: 4줄 = 서기, 서기2, 걷기, 던지기, 쿵쿵, 아파함, 녹음 / 2줄 옆 걷기
M = os.path.join(A, 'monsters')
for name, b in [('snowman_idle', (54, 592, 162, 751)), ('snowman_throw', (593, 589, 719, 751)),
                ('snowman_stomp', (829, 589, 958, 751)), ('snowman_hurt', (1035, 593, 1153, 751)),
                ('snowman_faint', (1184, 661, 1351, 750)), ('snowman_down', (1184, 661, 1351, 750)),
                ('snowman_w1', (596, 233, 688, 380)), ('snowman_w2', (717, 231, 810, 380)), ('snowman_w3', (840, 231, 930, 380))]:
    cutout('74.png', pad(b), tol=22).save(os.path.join(M, name + '.png'))

# 76 몬스터: 버섯(1줄), 벌(2줄), 아기 용(4줄)
MON = {
    'mushroom': {'w': [(48, 45, 182, 196), (330, 44, 462, 196), (590, 45, 722, 196)], 'hurt': (852, 43, 987, 196), 'faint': (1160, 68, 1321, 196)},
    'bee': {'w': [(45, 230, 182, 379), (332, 234, 472, 379), (597, 236, 741, 377)], 'hurt': (859, 237, 1009, 377), 'faint': (1149, 277, 1331, 386)},
    'dragon': {'w': [(221, 590, 343, 751), (405, 589, 525, 751), (590, 590, 716, 751)], 'hurt': (817, 598, 948, 751), 'faint': (1160, 646, 1332, 751)},
}
for k, d in MON.items():
    for i, b in enumerate(d['w']):
        cutout('76.png', pad(b), tol=22).save(os.path.join(M, '%s_w%d.png' % (k, i + 1)))
    cutout('76.png', pad(d['hurt']), tol=22).save(os.path.join(M, k + '_hurt.png'))
    cutout('76.png', pad(d['faint']), tol=22).save(os.path.join(M, k + '_faint.png'))

# 75 디저트 아이콘(위 줄)
for name, b in [('blueberry_muffin', (410, 105, 640, 335)), ('peach_tart', (720, 115, 990, 335)), ('grape_roll', (1060, 100, 1310, 330))]:
    fit(cutout('75.png', b, tol=22, min_part=0.02), 72).save(os.path.join(A, 'items', name + '.png'))

# 77, 78 다른 마을 가게 안
for i, name in [(77, 'petal'), (78, 'beach')]:
    im = unstar(np.array(Image.open(os.path.join(RAW, '%d.png' % i)).convert('RGB')).astype(float))
    Image.fromarray(np.clip(im, 0, 255).astype(np.uint8)).save(os.path.join(A, 'shops', name + '.png'))
print('ok')

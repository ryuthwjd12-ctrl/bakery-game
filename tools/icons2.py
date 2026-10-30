"""두 번째 아이콘·몬스터 시트에서 그림을 잘라요. python3 tools/icons2.py
- 41-cookie-bread-icons.png: 스페셜 요리 아이콘 (글자 아래 줄은 빼고 그림만)
- 39-ingredient-icons-2.png: 새 재료 아이콘
- 40-monsters.png: 몬스터 (왼쪽 그림=앞, 오른쪽=옆)"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..')
RAW = os.path.join(ROOT, 'art', 'raw')
OUT = os.path.join(ROOT, 'assets')


def cutout(sheet, box, tol=30, min_part=0.04):
    a = np.asarray(Image.open(os.path.join(RAW, sheet)).convert('RGB').crop(box)).astype(int)
    edge = np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]])
    bg = np.median(edge, axis=0)
    near = np.abs(a - bg).sum(axis=2) < tol
    lab, n = ndimage.label(near)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    fg = ~np.isin(lab, list(border))
    fg = ndimage.binary_opening(fg, iterations=1)
    l2, n2 = ndimage.label(fg)
    if n2:
        sz = ndimage.sum(fg, l2, range(1, n2 + 1))
        fg = np.isin(l2, [i + 1 for i, s in enumerate(sz) if s >= min_part * sz.max()])
    alpha = ndimage.gaussian_filter(fg.astype(float), 0.6) * 255
    im = Image.fromarray(np.dstack([a.astype(np.uint8), alpha.astype(np.uint8)]), 'RGBA')
    return im.crop(im.getbbox())


def fit(im, size):
    s = (size - 6) / max(im.size)
    im = im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.LANCZOS)
    c = Image.new('RGBA', (size, size))
    c.paste(im, ((size - im.width) // 2, (size - im.height) // 2), im)
    return c


# 41: 6열 x 4행, 그림 부분만
COLS = [(55, 220), (275, 440), (495, 662), (715, 882), (937, 1103), (1158, 1325)]
ROWS = [(38, 172), (225, 358), (402, 540), (578, 712)]
COOKIES = {
    'heart_cookie': (4, 0), 'flower_cookie': (0, 1), 'bear_cookie': (1, 1), 'macaron': (2, 1),
    'cinnamon_roll': (4, 2), 'croissant': (0, 2), 'acorn_cookie': (2, 3), 'mushroom_cookie': (3, 3),
    'snow_cookie': (5, 3), 'cream_bun': (0, 3), 'nut_cookie': (5, 1), 'choco_brioche': (5, 2),
}
for name, (c, r) in COOKIES.items():
    fit(cutout('41-cookie-bread-icons.png', (COLS[c][0], ROWS[r][0], COLS[c][1], ROWS[r][1])), 72).save(
        os.path.join(OUT, 'items', name + '.png'))

# 39: 8열 x 4행 칸(칸 테두리 안쪽)
IX = [32, 218, 404, 590, 776, 962, 1148, 1334]
IY = [113, 327, 534, 736]
ING = {'strawberry': (0, 2), 'apple': (4, 2), 'blueberry': (1, 2), 'lemon': (7, 1), 'walnut': (5, 3),
       'honey_jar': (6, 0), 'matcha': (2, 1), 'peach': (5, 2), 'grape': (7, 2), 'almond': (1, 3)}
for name, (c, r) in ING.items():
    fit(cutout('39-ingredient-icons-2.png', (IX[c] + 6, IY[r] + 6, IX[c] + 168, IY[r] + 176)), 72).save(
        os.path.join(OUT, 'items', name + '.png'))

# 40: 몬스터 (1536x1024) 2x3 쌍
os.makedirs(os.path.join(OUT, 'monsters'), exist_ok=True)
MON = {
    'squirrel': [(90, 80, 360, 330), (420, 80, 700, 330)],
    'mushroom': [(830, 80, 1090, 330), (1180, 80, 1430, 330)],
    'slime': [(110, 390, 360, 640), (430, 390, 670, 640)],
    'bee': [(830, 400, 1090, 640), (1190, 400, 1440, 640)],
    'dragon': [(110, 690, 370, 950), (420, 690, 690, 950)],
    'sheep': [(830, 720, 1090, 950), (1180, 720, 1440, 950)],
}
for name, boxes in MON.items():
    for tag, box in zip(['front', 'side'], boxes):
        im = cutout('40-monsters.png', box, tol=10 if name == 'sheep' else 26, min_part=0.02)
        s = 110 / im.height
        im = im.resize((round(im.width * s), 110), Image.LANCZOS)
        im.save(os.path.join(OUT, 'monsters', f'{name}_{tag}.png'))
print('done')

# ---- 주인공 공격 동작(05-11 시트 오른쪽): 뒤집개 휘두르기, 반짝이 마법
WALK_H = 219  # 걷기 그림 속 몸 높이
ATK = {
    'female_attack': [(1000, 308, 1122, 428), (1128, 308, 1252, 428), (1258, 308, 1382, 428)],
    'female_cast': [(1000, 438, 1122, 592), (1128, 438, 1252, 592), (1258, 438, 1382, 592)],
    'male_attack': [(985, 608, 1112, 757)],
    'male_cast': [(1128, 608, 1252, 757), (1258, 608, 1385, 757)],
}
STAND = {'female': 143, 'male': 146}  # 시트에서 서 있는 몸 높이
extra = {}
for key, boxes in ATK.items():
    hero = key.split('_')[0]
    s = WALK_H / STAND[hero]
    frames = []
    for b in boxes:
        im = cutout('05-11-hero-mixed.png', b, tol=24, min_part=0.002)
        frames.append(im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS))
    fw = max(f.width for f in frames) + 4
    fh = max(f.height for f in frames) + 2
    strip = Image.new('RGBA', (fw * len(frames), fh))
    for i, f in enumerate(frames):
        strip.paste(f, (i * fw + (fw - f.width) // 2, fh - f.height), f)
    strip.save(os.path.join(OUT, 'characters', key + '.png'))
    extra[key] = ('characters/' + key, fw, fh, len(frames))
with open(os.path.join(ROOT, 'scripts', 'sprite_data_extra.gd'), 'w') as f:
    f.write('class_name SpriteDataExtra\nextends RefCounted\n## tools/icons2.py가 만든 파일이에요. 직접 고치지 말아요.\n\nconst STRIPS := {\n')
    for k, v in extra.items():
        f.write('\t"%s": ["%s", %d, %d, %d],\n' % (k, *v))
    f.write('}\n')
print('attack strips', extra)

# 뒤집개 아이콘: 공격 그림에서 뒤집개만 떼어내요(손 위쪽)
atk = Image.open(os.path.join(OUT, 'characters', 'female_attack.png')).crop((128, 4, 186, 80))
a = np.array(atk)
# 손(살색)과 소매를 빼고 나무색만 남겨요
r, g, b, al = [a[..., i].astype(int) for i in range(4)]
wood = (r > 120) & (r - b > 50) & (g > 70) & (r - g < 75) | ((r < 120) & (r > 60) & (r - b > 30))
a[..., 3] = np.where(wood, a[..., 3], 0)
lab, n = ndimage.label(a[..., 3] > 0)
if n:
    sz = ndimage.sum(a[..., 3] > 0, lab, range(1, n + 1))
    a[..., 3] = np.where(lab == int(np.argmax(sz)) + 1, a[..., 3], 0)
sp = Image.fromarray(a, 'RGBA')
sp = sp.crop(sp.getbbox())
sp = sp.crop((0, 0, sp.width, int(sp.height * 0.86)))
fit(sp, 72).save(os.path.join(OUT, 'items', 'spatula.png'))

# 눈사람 거인 보스(20-26 시트 오른쪽 아래): 서기, 걷기, 쓰러짐
for tag, box in {'idle': (982, 598, 1104, 766), 'walk': (1110, 598, 1252, 766), 'down': (1262, 598, 1402, 766)}.items():
    im = cutout('20-26-maps-worldmap-boss.png', box, tol=22, min_part=0.02)
    s = 200 / im.height
    im.resize((round(im.width * s), 200), Image.LANCZOS).save(os.path.join(OUT, 'monsters', f'snowman_{tag}.png'))

"""다람쥐 주민(sq1~6) 앉은 모습. python3 tools/sq_sit.py
제미나이 다람쥐 그림에는 앉은 자세가 없어서, 앞모습(옆모습엔 안경·모자가 빠져 있어요)의 다리 아래를 잘라
둥근 엉덩이를 그리고 발끝만 아래에 붙여요.
→ assets/animals/sq<n>_sit.png, scripts/sprite_data_r7.gd"""
import os
import numpy as np
from PIL import Image, ImageDraw
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
A = os.path.join(ROOT, 'assets', 'animals')


def sit(a):
    a = a.convert('RGBA')
    w, h = a.size
    px = np.array(a)
    cut = int(h * 0.74)
    xs = np.where(px[cut - 3][:, 3] > 200)[0]
    # 잘린 줄에서 몸통과 꼬리 구간을 따로 찾아 각각 둥글게 마무리해요
    runs, s, p = [], xs[0], xs[0]
    for x in xs[1:]:
        if x > p + 3:
            runs.append((s, p))
            s = x
        p = x
    runs.append((s, p))
    im = Image.new('RGBA', (w, cut + 22), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for x0, x1 in runs:
        if x1 - x0 < 12:
            continue
        c = tuple(int(v) for v in px[cut - 8, (x0 + x1) // 2][:3])
        d.ellipse((x0, cut - 24, x1, cut + 16), fill=c + (255,), outline=(110, 66, 40, 255), width=3)
    body = a.crop((0, 0, w, cut))
    foot = a.crop((0, int(h * 0.88), w, h))
    im.paste(body, (0, 0), body)
    im.paste(foot, (0, cut + 20 - foot.height), foot)
    return im


lines = ['class_name SpriteDataR7', 'extends RefCounted', '## tools/sq_sit.py가 만든 파일이에요. 직접 고치지 말아요.', '',
         'const STRIPS := {']
for n in range(1, 7):
    im = sit(Image.open(os.path.join(A, 'sq%d_front.png' % n)))
    im.save(os.path.join(A, 'sq%d_sit.png' % n))
    lines.append('\t"sq%d_sit": ["animals/sq%d_sit", %d, %d, 1],' % (n, n, im.width, im.height))
lines.append('}')
open(os.path.join(ROOT, 'scripts', 'sprite_data_r7.gd'), 'w').write('\n'.join(lines) + '\n')
print('ok')

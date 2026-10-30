"""주방 수납장(그릇장·냉장고·찬장)을 게임 그림체에 맞춰 그려요.
실행: python3 tools/draw_kitchen.py -> assets/kitchen/*.png, assets/backgrounds/kitchen.png
두 배 크기로 그린 뒤 줄여서 선을 부드럽게 해요.
"""
import os
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..')
OUT = os.path.join(ROOT, 'assets', 'kitchen')
os.makedirs(OUT, exist_ok=True)
K = 2  # 그릴 때 배율
LINE = (122, 78, 60, 255)
LW = 4 * K


def C(h, a=255):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (a,)


def rr(d, box, r, fill, outline=LINE, w=LW):
    d.rounded_rectangle([v * K for v in box], radius=r * K, fill=fill, outline=outline, width=w)


def shade(img, box, side='right', width=0.18, color=(90, 50, 30), alpha=40):
    # 오른쪽(또는 왼쪽)에 은은한 그늘
    x0, y0, x1, y1 = [v * K for v in box]
    layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    w = int((x1 - x0) * width)
    for i in range(w):
        a = int(alpha * (i / w))
        x = x1 - w + i if side == 'right' else x0 + w - i
        ld.line([(x, y0), (x, y1)], fill=color + (a,))
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).rectangle([x0, y0, x1, y1], fill=255)
    img.alpha_composite(Image.composite(layer, Image.new('RGBA', img.size, (0, 0, 0, 0)), mask))


def finish(img, name):
    img = img.resize((img.width // K, img.height // K), Image.LANCZOS)
    img.save(os.path.join(OUT, name + '.png'))
    return img


def ground_shadow(d, cx, y, w):
    d.ellipse([(cx - w / 2) * K, (y - 10) * K, (cx + w / 2) * K, (y + 8) * K], fill=(90, 55, 35, 45))


def cabinet():
    W, H = 280, 500
    img = Image.new('RGBA', (W * K, H * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ground_shadow(d, W / 2, H - 12, W - 30)
    wood, dark, light = C('#C98F5E'), C('#A8714A'), C('#E0AE7C')
    rr(d, (14, 34, W - 14, H - 18), 10, wood)                 # 몸통
    rr(d, (4, 10, W - 4, 40), 8, light)                       # 위 장식
    rr(d, (26, 46, W - 26, 300), 8, dark)                     # 유리문 틀 안쪽
    glass = C('#E6F2F6')
    for gx in (34, W / 2 + 4):
        rr(d, (gx, 54, gx + (W / 2 - 38), 292), 6, glass)
    # 선반
    for sy in (128, 210):
        d.line([(30 * K, sy * K), ((W - 30) * K, sy * K)], fill=LINE, width=3 * K)
    # 접시와 그릇, 머그
    plate, rim, bowl, mug = C('#FFFDF7'), C('#F2A9B4'), C('#F7EDCB'), C('#E07A86')
    for i, px in enumerate((50, 76, 102)):
        d.ellipse([px * K, 66 * K, (px + 34) * K, 124 * K], fill=plate, outline=LINE, width=3 * K)
        d.ellipse([(px + 7) * K, 78 * K, (px + 27) * K, 112 * K], outline=rim, width=3 * K)
    for bx in (W / 2 + 14, W / 2 + 64):
        d.chord([bx * K, 92 * K, (bx + 44) * K, 140 * K], 0, 180, fill=bowl, outline=LINE, width=3 * K)
        d.line([bx * K, 116 * K, (bx + 44) * K, 116 * K], fill=LINE, width=3 * K)
    for mx in (44, 92):
        rr(d, (mx, 168, mx + 32, 206), 6, mug)
        d.arc([(mx + 26) * K, 176 * K, (mx + 42) * K, 196 * K], -90, 90, fill=LINE, width=3 * K)
    rr(d, (W / 2 + 16, 176, W / 2 + 96, 206), 8, C('#D9D4CC'))  # 케이크 틀
    d.line([(W / 2 + 22) * K, 186 * K, (W / 2 + 90) * K, 186 * K], fill=LINE, width=2 * K)
    star = [(64, 230), (70, 244), (84, 244), (73, 253), (77, 268), (64, 259), (51, 268), (55, 253), (44, 244), (58, 244)]
    d.polygon([(x * K, y * K) for x, y in star], fill=C('#D9D4CC'), outline=LINE, width=3 * K)
    d.line([(W / 2 + 20) * K, 270 * K, (W / 2 + 100) * K, 236 * K], fill=C('#C98F5E'), width=12 * K)
    d.line([(W / 2 + 20) * K, 270 * K, (W / 2 + 100) * K, 236 * K], fill=LINE, width=2 * K)
    # 유리 반사
    for gx in (40, W / 2 + 10):
        d.line([(gx + 10) * K, 70 * K, (gx + 50) * K, 60 * K], fill=(255, 255, 255, 170), width=5 * K)
    # 문 가운데 선과 손잡이
    d.line([(W / 2) * K, 46 * K, (W / 2) * K, 300 * K], fill=LINE, width=LW)
    for kx in (W / 2 - 12, W / 2 + 8):
        d.ellipse([kx * K, 170 * K, (kx + 6) * K, 182 * K], fill=C('#F7EDCB'), outline=LINE, width=2 * K)
    # 서랍
    for i, dy in enumerate((316, 390)):
        rr(d, (26, dy, W - 26, dy + 64), 8, light)
        rr(d, (W / 2 - 22, dy + 26, W / 2 + 22, dy + 38), 6, C('#F7EDCB'))
    rr(d, (20, H - 40, W - 20, H - 22), 4, dark)
    shade(img, (14, 34, W - 14, H - 18))
    return finish(img, 'cabinet')


def fridge():
    W, H = 250, 520
    img = Image.new('RGBA', (W * K, H * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ground_shadow(d, W / 2, H - 10, W - 20)
    body, side = C('#F6EBD3'), C('#E8D6B4')
    rr(d, (12, 10, W - 12, H - 24), 46, body)
    shade(img, (12, 10, W - 12, H - 24), alpha=55)
    d.line([(16 * K, 170 * K), ((W - 16) * K, 170 * K)], fill=LINE, width=LW)     # 냉동고와 냉장고 경계
    chrome = C('#D9D3C9')
    rr(d, (W - 46, 70, W - 32, 140), 7, chrome)       # 냉동고 손잡이
    rr(d, (W - 46, 200, W - 32, 330), 7, chrome)      # 냉장고 손잡이
    # 냉동고 눈꽃
    cx, cy, r = 70, 94, 22
    snow = C('#A9CFE8')
    for ang in range(0, 180, 60):
        import math
        dx, dy = r * math.cos(math.radians(ang)), r * math.sin(math.radians(ang))
        d.line([(cx - dx) * K, (cy - dy) * K, (cx + dx) * K, (cy + dy) * K], fill=snow, width=5 * K)
    d.ellipse([(cx - 5) * K, (cy - 5) * K, (cx + 5) * K, (cy + 5) * K], fill=C('#FFFFFF'))
    # 냉장고 하트 장식
    hx, hy = 70, 232
    d.ellipse([(hx - 14) * K, (hy - 10) * K, hx * K, (hy + 4) * K], fill=C('#E07A86'))
    d.ellipse([hx * K, (hy - 10) * K, (hx + 14) * K, (hy + 4) * K], fill=C('#E07A86'))
    d.polygon([((hx - 14) * K, (hy - 1) * K), ((hx + 14) * K, (hy - 1) * K), (hx * K, (hy + 16) * K)], fill=C('#E07A86'))
    # 반짝임
    d.line([30 * K, 50 * K, 30 * K, 130 * K], fill=(255, 255, 255, 190), width=6 * K)
    d.line([30 * K, 200 * K, 30 * K, 380 * K], fill=(255, 255, 255, 190), width=6 * K)
    # 다리
    for fx in (40, W - 60):
        rr(d, (fx, H - 28, fx + 20, H - 8), 4, C('#B98A5E'))
    return finish(img, 'fridge')


def pantry():
    W, H = 400, 450
    img = Image.new('RGBA', (W * K, H * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ground_shadow(d, W / 2, H - 10, W - 30)
    wood, dark, light = C('#B9814F'), C('#9E6A3F'), C('#D6A06C')
    # 위에 놓인 병
    rr(d, (60, 18, 108, 76), 10, C('#F2F2EC'))
    rr(d, (64, 8, 104, 22), 4, C('#C98F5E'))
    rr(d, (64, 44, 104, 72), 6, C('#FFFFFF'), outline=None)
    rr(d, (300, 30, 346, 76), 10, C('#F7EDCB'))
    rr(d, (296, 22, 350, 34), 4, C('#E07A86'))
    rr(d, (10, 70, W - 10, 96), 8, light)              # 위판
    rr(d, (20, 92, W - 20, H - 24), 8, wood)           # 몸통
    for x0 in (36, W / 2 + 6):                         # 문 두 짝
        rr(d, (x0, 108, x0 + W / 2 - 42, H - 46), 8, light)
        rr(d, (x0 + 18, 128, x0 + W / 2 - 60, H - 66), 6, dark)
        rr(d, (x0 + 30, 142, x0 + W / 2 - 72, H - 80), 4, wood)
    for kx in (W / 2 - 22, W / 2 + 12):
        d.ellipse([kx * K, 250 * K, (kx + 12) * K, 262 * K], fill=C('#F7EDCB'), outline=LINE, width=2 * K)
    # 도토리 장식
    ax, ay = W / 2, 80
    d.ellipse([(ax - 12) * K, (ay - 6) * K, (ax + 12) * K, (ay + 18) * K], fill=C('#C98F5E'), outline=LINE, width=2 * K)
    d.chord([(ax - 15) * K, (ay - 14) * K, (ax + 15) * K, (ay + 6) * K], 180, 360, fill=C('#8E5A3A'), outline=LINE, width=2 * K)
    rr(d, (24, H - 34, W - 24, H - 18), 4, dark)
    shade(img, (20, 92, W - 20, H - 24))
    return finish(img, 'pantry')


def background():
    """원래 주방 그림에서 선반과 도구 줄을 지우고 벽으로 채워요."""
    bg = Image.open(os.path.join(ROOT, 'art', 'raw', '17-kitchen.png')).convert('RGBA')
    wall = Image.new('RGBA', (1000, 520))
    wd = ImageDraw.Draw(wall)
    top, bottom = (246, 234, 212), (236, 218, 190)
    for y in range(520):
        t = y / 519
        wd.line([(0, y), (999, y)], fill=tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3)) + (255,))
    # 벽 아래 나무 판자
    for x in range(0, 1000, 46):
        wd.rectangle([x, 380, x + 44, 520], fill=(214, 168, 120, 255))
        wd.line([(x, 380), (x, 520)], fill=(170, 120, 80, 255), width=2)
    wd.rectangle([0, 372, 999, 384], fill=(185, 129, 79, 255))
    # 창으로 들어오는 빛
    glow = Image.new('RGBA', wall.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).polygon([(0, 40), (260, 40), (520, 380), (160, 380)], fill=(255, 250, 230, 60))
    wall.alpha_composite(glow.filter(ImageFilter.GaussianBlur(20)))
    bg.alpha_composite(wall, (118, 30))
    # 위쪽 들보
    d = ImageDraw.Draw(bg)
    d.rectangle([100, 0, 1140, 34], fill=(150, 98, 62, 255))
    d.line([(100, 34), (1140, 34)], fill=LINE, width=4)
    bg.convert('RGB').save(os.path.join(ROOT, 'assets', 'backgrounds', 'kitchen.png'))


if __name__ == '__main__':
    background()
    cabinet()
    fridge()
    pantry()
    print('ok')

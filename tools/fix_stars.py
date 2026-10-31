"""이미 만든 큰 그림에 남은 별 자국을 정확한 모델(unstar2)로 다시 지워요. python3 tools/fix_stars.py
그림마다 같은 크기 원본(art/raw)을 찾아, 별 둘레가 원본과 같으면 별 자리만 원본에서 새로 지운 것으로 바꿔요.
(별 자리 말고 나머지는 그대로라서, 길 칠하기·글자 지우기 같은 뒤 작업이 남아요.)"""
import glob, os
import numpy as np
from PIL import Image
import unstar2

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
raws = [(f, Image.open(f).size) for f in glob.glob(os.path.join(ROOT, 'art', 'raw', '*.png'))]


def load(rf, size):
    """원본을 그림 크기로 맞춰요(크기를 바꿔 쓴 그림도 있어서)."""
    raw = np.array(Image.open(rf).convert('RGB')).astype(float)
    pair = [raw]
    if raw.shape[1] != size[0] or raw.shape[0] != size[1]:
        pair = [np.array(Image.fromarray(x.astype(np.uint8)).resize(size, Image.LANCZOS)).astype(float) for x in pair]
    return pair

for f in sorted(glob.glob(os.path.join(ROOT, 'assets', '**', '*.png'), recursive=True)):
    im = Image.open(f)
    if im.size[0] < 1000 or 'characters' in f:
        continue
    cur = np.array(im.convert('RGBA')).astype(float)
    h, w = cur.shape[:2]
    best = None
    for rf, sz in raws:
        if abs(sz[0] / sz[1] - w / h) > 0.06:
            continue
        sc = w / sz[0]
        cx, cy = w - 120.5 * sc, h - 120.5 * sc
        yy, xx = np.mgrid[0:h, 0:w]
        dist = (np.abs(xx - cx) / (26.5 * sc)) ** 0.65 + (np.abs(yy - cy) / (26.5 * sc)) ** 0.65
        star = dist < 1.15
        ring = (dist > 1.3) & (dist < 2.2)
        raw, = load(rf, (w, h))
        e = np.abs(raw[ring] - cur[..., :3][ring]).mean()
        if best is None or e < best[0]:
            best = (e, rf, None, star)
    name = os.path.relpath(f, ROOT)
    if best is None or best[0] > 3.0:
        print('%-36s 원본 못 찾음 (%.1f)' % (name, best[0] if best else -1))
        continue
    _, rf, _, star = best
    raw = np.array(Image.open(rf).convert('RGB')).astype(float)
    fixed = unstar2.unstar(raw)
    if fixed.shape[:2] != (h, w):
        fixed = np.array(Image.fromarray(fixed.astype(np.uint8)).resize((w, h), Image.LANCZOS)).astype(float)
    cur[..., :3][star] = fixed[star]
    Image.fromarray(np.clip(cur, 0, 255).astype(np.uint8)).save(f)
    print('%-36s ← %s (둘레 차이 %.2f)' % (name, os.path.basename(best[1]), best[0]))

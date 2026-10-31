"""큰 그림에 남은 제미나이 생성 표시(오른쪽 아래 반투명 별)를 지워요. python3 tools/destar.py [파일...]
별 자리를 찾아서, 별 밑 바탕을 추정하고, 별의 투명도를 맞춘 뒤 그만큼 빼서 원래 무늬를 살려요.
인자를 안 주면 assets 안 가로 1000px 넘는 그림을 모두 검사해요. 별이 없는 곳은 바탕과 차이가 없어서 거의 그대로 남아요."""
import glob, os, sys
import cv2
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')


def prof(h, w, cx, cy, r, p):
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    return (np.abs(xx - cx) / r) ** p + (np.abs(yy - cy) / r) ** p


def find(img, s):
    h, w = img.shape[:2]
    g = img.mean(2)
    x0, y0 = int(w - 200 * s), int(h - 200 * s)
    sub = g[y0:int(h - 40 * s), x0:int(w - 40 * s)]
    hp = sub - ndimage.median_filter(sub, size=int(31 * s) | 1)
    r = 26 * s
    n = int(r * 2.4) | 1
    d = prof(n, n, n // 2, n // 2, r, 0.65)
    t = np.clip(1.2 - d, 0, 1)
    t = (t - t.mean()).astype(np.float32)
    m = cv2.matchTemplate(hp.astype(np.float32), t, cv2.TM_CCOEFF_NORMED)
    _, score, _, loc = cv2.minMaxLoc(m)
    return x0 + loc[0] + n // 2, y0 + loc[1] + n // 2, score


def clean(path, cx=None, cy=None):
    """별 자리(기본: 오른쪽·아래 가장자리에서 120px 안쪽)의 하얀 덧칠을 픽셀마다 추정해서 빼요.
    예전에 한 번 지운 그림은 테두리만 남아 있어서, 모양을 가정하지 않고 바탕과의 차이로 투명도를 구해요."""
    im = np.array(Image.open(path).convert('RGBA')).astype(float)
    img = im[..., :3]
    h, w = img.shape[:2]
    cx = w - 120 if cx is None else cx
    cy = h - 120 if cy is None else cy
    big = prof(h, w, cx, cy, 36, 0.7) < 1.0
    ys, xs = np.where(big)
    y0, y1, x0, x1 = ys.min() - 10, ys.max() + 11, xs.min() - 10, xs.max() + 11
    crop = img[y0:y1, x0:x1].copy()
    sel = big[y0:y1, x0:x1]
    mk = sel.astype(np.uint8) * 255
    bg = cv2.inpaint(np.clip(crop, 0, 255).astype(np.uint8), mk, 8, cv2.INPAINT_TELEA).astype(float)
    ap = ((crop - bg) / np.maximum(255 - bg, 8)).min(2)  # 하얀 덧칠은 세 색 모두 밝게 해요
    ap = np.where(sel, np.clip(ap, 0, 0.8), 0)
    ap = cv2.GaussianBlur(ap, (0, 0), 1.6)
    a = ap[..., None]
    out = np.clip((crop - a * 255) / (1 - a), 0, 255)
    img[y0:y1, x0:x1] = out
    im[..., :3] = img
    Image.fromarray(np.clip(im, 0, 255).astype(np.uint8)).save(path)
    return float(ap.max())


if __name__ == '__main__':
    fs = sys.argv[1:] or [f for f in sorted(glob.glob(os.path.join(ROOT, 'assets', '**', '*.png'), recursive=True))
                          if Image.open(f).size[0] >= 1000 and 'characters' not in f]
    for f in fs:
        print('%-40s 가장 진한 곳 %.2f' % (os.path.relpath(f, ROOT), clean(f)))

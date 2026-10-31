"""제미나이 생성 표시(오른쪽 아래 하얀 별) 지우기, 정확한 모델.
깨끗한 크림색 시트에서 재 보니 별은 하얀색, 투명도는 한 장 안에서 고르고(그림마다 0.2~0.29), 가장자리는 1px 정도로 날카로워요.
중심은 그림 오른쪽·아래 끝에서 120.5px 안쪽, 반지름 26.5, 모양 지수 0.65(네 꼭짓점이 오목한 별)."""
import numpy as np

A, R, P = 0.29, 26.5, 0.65


def alpha(h, w, cx=None, cy=None, a=A):
    cx = w - 120.5 if cx is None else cx
    cy = h - 120.5 if cy is None else cy
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    d = (np.abs(xx - cx) / R) ** P + (np.abs(yy - cy) / R) ** P
    return a * np.clip((1 - d) * R * P + 0.5, 0, 1)


def fit_a(im, cx=None, cy=None):
    """그림마다 별의 진하기가 조금씩 달라요(0.2~0.34). 별 밑 바탕을 둘레에서 메워 추정하고,
    별 안쪽 픽셀마다 진하기를 구해 가운데 값을 써요."""
    import cv2
    h, w = im.shape[:2]
    y0, x0 = h - 175, w - 175
    sub = np.clip(im[y0:h - 65, x0:w - 65], 0, 255)
    m = alpha(h, w, cx, cy, 1.0)[y0:h - 65, x0:w - 65]
    mask = (m > 0.01).astype(np.uint8) * 255
    mask = cv2.dilate(mask, np.ones((3, 3), np.uint8))
    bg = cv2.inpaint(sub.astype(np.uint8), mask, 5, cv2.INPAINT_TELEA).astype(float)
    inn = m > 0.99
    room = 255 - bg[inn]
    est = (sub[inn] - bg[inn]) / np.maximum(room, 1)
    est = est[room > 40]
    return float(np.clip(np.median(est), 0.26, 0.32)) if est.size > 50 else A


def unstar(im, cx=None, cy=None):
    """im: float RGB 배열(0~255). 별을 뺀 배열을 돌려줘요."""
    h, w = im.shape[:2]
    from scipy import ndimage
    m = alpha(h, w, cx, cy, 1.0)
    a = (m * fit_a(im, cx, cy))[..., None]
    out = np.clip((im - a * 255) / (1 - a), 0, 255)
    # 가장자리 1~2px에 남는 가는 선은 주변 값의 가운데로 메워요
    edge = ndimage.binary_dilation((m > 0.02) & (m < 0.98), iterations=1)
    ys, xs = np.where(edge)
    y0, y1, x0, x1 = ys.min() - 3, ys.max() + 4, xs.min() - 3, xs.max() + 4
    sub = out[y0:y1, x0:x1]
    med = np.stack([ndimage.median_filter(sub[..., c], size=5) for c in range(3)], -1)
    e = edge[y0:y1, x0:x1]
    sub[e] = med[e]
    return out

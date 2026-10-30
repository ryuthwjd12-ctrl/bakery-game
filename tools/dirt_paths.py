"""마을의 자갈길을 흙길로 바꿔요. python3 tools/dirt_paths.py (clean_signs.py 다음, 마을 그림에)
자갈(밝은 회베이지 돌)을 찾아 그 사이 틈까지 메운 길 모양을 만들고, 흙 색과 부드러운 얼룩으로 칠한 뒤 가장자리에 갈색 선을 둘러요."""
import os
import numpy as np
from PIL import Image
from scipy import ndimage
HERE = os.path.dirname(os.path.abspath(__file__))
P = os.path.join(HERE, '..', 'assets', 'backgrounds', 'acorn_village.png')
SRC = os.path.join(HERE, '..', 'art', 'raw', '18-acorn-village.png')  # 경계 판단은 원본 기준


def main(path_in, path_out):
    a = np.array(Image.open(path_in).convert('RGB')).astype(float)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    stone = (b > 138) & (b < 192) & (r > 175) & (r < 240) & (r - b < 80) & (r - b > 15) & (g - b < 55)
    stone = ndimage.binary_opening(stone, iterations=1)
    lab, n = ndimage.label(stone)
    sz = ndimage.sum(stone, lab, range(1, n + 1))
    # 자갈 하나 크기(작은 덩어리)만 남겨요: 건물 벽 같은 큰 면은 빼요
    keep = [i + 1 for i, s in enumerate(sz) if 25 < s < 1400]
    stone = np.isin(lab, keep)
    path = ndimage.binary_closing(stone, structure=np.ones((3, 3)), iterations=7)
    path = ndimage.binary_opening(path, iterations=3)
    lab, n = ndimage.label(path)
    sz = ndimage.sum(path, lab, range(1, n + 1))
    path = np.isin(lab, [i + 1 for i, s in enumerate(sz) if s > 3000])
    # 가장자리를 매끈하게
    path = ndimage.gaussian_filter(path.astype(float), 4) > 0.5
    # 차양·간판처럼 길 위로 겹친 물건은 지키기: 원래 색이 선명하거나 아주 밝은 곳은 칠하지 않아요
    vivid = (np.max(a, axis=2) - np.min(a, axis=2) > 120) | (b > 205)
    vivid = ndimage.binary_dilation(vivid, iterations=2)
    path &= ~vivid
    # 흙 색: 따뜻한 황토 + 큰 얼룩 + 작은 알갱이
    rng = np.random.default_rng(3)
    big = ndimage.gaussian_filter(rng.normal(0, 1, r.shape), 18)
    big = big / (np.abs(big).max() + 1e-6)
    grain = ndimage.gaussian_filter(rng.normal(0, 1, r.shape), 1.2)
    base = np.array([226, 182, 124], float)
    dirt = base[None, None, :] + big[..., None] * np.array([14, 12, 10]) + grain[..., None] * 9
    # 작은 돌멩이 점과 짧은 줄무늬(그림 느낌)
    dots = (rng.random(r.shape) < 0.0009)
    dots = ndimage.binary_dilation(dots, iterations=1)
    dirt[dots] = [196, 150, 98]
    soft = ndimage.gaussian_filter(path.astype(float), 1.5)
    out = a * (1 - soft[..., None]) + dirt * soft[..., None]
    edge = path ^ ndimage.binary_erosion(path, iterations=2)
    edge = ndimage.gaussian_filter(edge.astype(float), 0.8)
    out = out * (1 - edge[..., None] * 0.75) + np.array([140, 96, 62]) * (edge[..., None] * 0.75)
    Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).save(path_out)
    print('path pixels', int(path.sum()))


if __name__ == '__main__':
    main(P, P)

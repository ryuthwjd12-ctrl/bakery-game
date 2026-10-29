"""배경음악과 효과음을 코드로 직접 만들어요 (외부 음원이 없어서 저작권 걱정이 없어요).
실행: python3 tools/make_audio.py  ->  assets/audio/*.ogg
필요: numpy, scipy, ffmpeg
"""
import os, subprocess, tempfile
import numpy as np
from scipy.io import wavfile
from scipy.signal import lfilter

SR = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'assets', 'audio')
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)

NOTE = {'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3, 'E': 4, 'F': 5, 'F#': 6, 'Gb': 6,
        'G': 7, 'G#': 8, 'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11}


def hz(n):
    name, octv = n[:-1], int(n[-1])
    return 440.0 * 2 ** ((NOTE[name] + 12 * (octv + 1) - 69) / 12)


def env(n, a=0.005, d=1.0):
    t = np.arange(n) / SR
    e = np.exp(-t / d)
    na = max(1, int(a * SR))
    e[:na] *= np.linspace(0, 1, na)
    return e


def musicbox(f, dur, vol=0.3):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = (np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * f * 2.0 * t) * np.exp(-t * 3)
         + 0.12 * np.sin(2 * np.pi * f * 3.01 * t) * np.exp(-t * 6))
    return vol * s * env(n, 0.003, 0.55)


def pad(freqs, dur, vol=0.05):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = sum(np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * 2 * f * t) for f in freqs)
    e = np.minimum(1, t / 0.4) * np.minimum(1, (dur - t) / 0.4)
    return vol * s * np.clip(e, 0, 1)


def flute(f, dur, vol=0.18):
    n = int(dur * SR)
    t = np.arange(n) / SR
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5 * t) * np.minimum(1, t / 0.3)
    ph = 2 * np.pi * np.cumsum(f * vib) / SR
    s = np.sin(ph) + 0.2 * np.sin(2 * ph) + 0.05 * np.sin(3 * ph)
    breath = lfilter([1], [1, -0.97], rng.normal(0, 0.01, n))
    e = np.minimum(1, t / 0.06) * np.clip((dur - t) / 0.12, 0, 1)
    return vol * (s + breath) * e


def pluck(f, dur, vol=0.25):
    # 카플러스-스트롱 기타 소리
    n = int(dur * SR)
    p = max(2, int(SR / f))
    buf = rng.uniform(-1, 1, p)
    out = np.zeros(n)
    for i in range(n):
        out[i] = buf[i % p]
        buf[i % p] = 0.5 * (buf[i % p] + buf[(i + 1) % p]) * 0.996
    return vol * out


def reverb(x, wet=0.25, length=1.6):
    n = int(length * SR)
    ir = rng.normal(0, 1, n) * np.exp(-np.arange(n) / SR * 3.5)
    ir = lfilter([1], [1, -0.6], ir)
    ir /= np.abs(ir).sum() / 8
    y = np.convolve(x, ir)[:len(x) + n]
    out = np.zeros(len(y))
    out[:len(x)] = x
    return (1 - wet) * out + wet * y


def place(track, sig, at):
    i = int(at * SR)
    end = min(len(track), i + len(sig))
    track[i:end] += sig[:end - i]


def loop_tail(x, loop_len):
    # 끝에 남은 울림을 앞쪽에 겹쳐서 이음새 없이 반복되게
    n = int(loop_len * SR)
    out = x[:n].copy()
    tail = x[n:]
    out[:len(tail)] += tail[:n]
    return out


def save(name, x, loop=False):
    x = x / max(1e-6, np.abs(x).max()) * 0.85
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as f:
        wavfile.write(f.name, SR, (x * 32767).astype(np.int16))
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', f.name, '-c:a', 'libvorbis',
                        '-q:a', '5', os.path.join(OUT, name + '.ogg')], check=True)
        os.unlink(f.name)
    print(name, round(len(x) / SR, 1), 's')


CHORDS = {
    'F': ['F', 'A', 'C'], 'Dm': ['D', 'F', 'A'], 'Bb': ['Bb', 'D', 'F'], 'C': ['C', 'E', 'G'],
    'Am': ['A', 'C', 'E'], 'Gm': ['G', 'Bb', 'D'], 'C7': ['C', 'E', 'Bb'],
    'G': ['G', 'B', 'D'], 'Em': ['E', 'G', 'B'], 'D': ['D', 'F#', 'A'], 'Bm': ['B', 'D', 'F#'],
}


def shop_theme():
    """가게 음악: 3/4박자 오르골 왈츠, F장조."""
    bpm = 96
    beat = 60 / bpm
    bars = [
        ('F', [('C5', 1), ('A4', 1), ('C5', 1)]), ('Dm', [('D5', 2), ('F5', 1)]),
        ('Bb', [('D5', 1), ('C5', 1), ('Bb4', 1)]), ('C', [('C5', 3)]),
        ('F', [('A4', 1), ('C5', 1), ('F5', 1)]), ('Am', [('E5', 2), ('C5', 1)]),
        ('Bb', [('D5', 1), ('C5', 1), ('Bb4', 1)]), ('C7', [('G4', 2), ('Bb4', 1)]),
        ('F', [('A4', 1), ('C5', 1), ('F5', 1)]), ('Gm', [('G5', 1), ('F5', 1), ('D5', 1)]),
        ('C', [('E5', 2), ('C5', 1)]), ('F', [('F5', 3)]),
        ('Bb', [('D5', 1), ('F5', 1), ('D5', 1)]), ('F', [('C5', 2), ('A4', 1)]),
        ('Gm', [('Bb4', 1), ('D5', 1), ('G5', 1)]), ('C', [('E5', 3)]),
        ('Dm', [('F5', 1), ('E5', 1), ('D5', 1)]), ('Am', [('C5', 2), ('E5', 1)]),
        ('Bb', [('D5', 1), ('C5', 1), ('Bb4', 1)]), ('C', [('A4', 2), ('G4', 1)]),
        ('F', [('A4', 1), ('C5', 1), ('F5', 1)]), ('Dm', [('F5', 2), ('D5', 1)]),
        ('C', [('Bb4', 1), ('C5', 1), ('E5', 1)]), ('F', [('F5', 3)]),
    ]
    total = len(bars) * 3 * beat
    tr = np.zeros(int((total + 3) * SR))
    for i, (ch, mel) in enumerate(bars):
        t0 = i * 3 * beat
        tones = CHORDS[ch]
        place(tr, musicbox(hz(tones[0] + '3'), 2.0, 0.22), t0)
        place(tr, musicbox(hz(tones[1] + '4'), 1.2, 0.10), t0 + beat)
        place(tr, musicbox(hz(tones[2] + '4'), 1.2, 0.10), t0 + 2 * beat)
        place(tr, pad([hz(n + '3') for n in tones], 3 * beat + 0.3), t0)
        t = t0
        for n, b in mel:
            place(tr, musicbox(hz(n), 1.6, 0.30), t)
            t += b * beat
    save('bgm_shop', loop_tail(reverb(tr, 0.3), total), True)


def village_theme():
    """마을 음악: 4/4박자 피리와 기타, G장조."""
    bpm = 108
    beat = 60 / bpm
    prog = ['G', 'Em', 'C', 'D', 'G', 'Em', 'C', 'D', 'C', 'D', 'Bm', 'Em', 'C', 'D', 'G', 'G']
    mel = [
        [('B4', 1), ('D5', 1), ('G5', 2)], [('E5', 1), ('D5', 1), ('B4', 2)],
        [('C5', 1), ('E5', 1), ('G5', 1), ('E5', 1)], [('D5', 3), ('A4', 1)],
        [('B4', 1), ('D5', 1), ('G5', 1.5), ('A5', 0.5)], [('G5', 1), ('E5', 1), ('B4', 2)],
        [('C5', 1), ('E5', 1), ('D5', 1), ('C5', 1)], [('A4', 3), ('D5', 1)],
        [('E5', 1.5), ('D5', 0.5), ('C5', 2)], [('D5', 1.5), ('E5', 0.5), ('F#5', 2)],
        [('D5', 1), ('F#5', 1), ('B5', 2)], [('G5', 2), ('E5', 2)],
        [('E5', 1), ('G5', 1), ('C5', 1), ('E5', 1)], [('D5', 1), ('F#5', 1), ('A5', 1), ('F#5', 1)],
        [('G5', 4)], [('D5', 1), ('B4', 1), ('G4', 2)],
    ]
    total = len(prog) * 4 * beat
    tr = np.zeros(int((total + 3) * SR))
    for i, ch in enumerate(prog):
        t0 = i * 4 * beat
        tones = CHORDS[ch]
        place(tr, pluck(hz(tones[0] + '2'), 1.6, 0.25), t0)
        place(tr, pluck(hz(tones[0] + '2'), 1.6, 0.18), t0 + 2 * beat)
        for k, b in enumerate([0.5, 1, 1.5, 2.5, 3, 3.5]):
            place(tr, pluck(hz(tones[k % 3] + '3'), 0.8, 0.10), t0 + b * beat)
        t = t0
        for n, b in mel[i]:
            place(tr, flute(hz(n), b * beat * 0.95, 0.16), t)
            t += b * beat
    save('bgm_village', loop_tail(reverb(tr, 0.25), total), True)


def tone(f, dur, vol=0.5, decay=0.15, partials=(1,)):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = sum(np.sin(2 * np.pi * f * p * t) / (k + 1) for k, p in enumerate(partials))
    return vol * s * env(n, 0.002, decay)


def sfx():
    save('click', tone(1800, 0.06, 0.4, 0.015, (1, 2)))
    n = int(0.12 * SR)
    t = np.arange(n) / SR
    f = 900 * np.exp(-t * 9) + 350
    save('pop', 0.6 * np.sin(2 * np.pi * np.cumsum(f) / SR) * env(n, 0.002, 0.04))
    x = np.zeros(int(1.4 * SR))
    for k, nt in enumerate(['E6', 'B6']):
        place(x, tone(hz(nt), 1.2, 0.4, 0.4, (1, 2.76, 5.4)), k * 0.12)
    save('ding', reverb(x, 0.2)[:len(x)])
    x = np.zeros(int(0.5 * SR))
    place(x, tone(hz('B5'), 0.2, 0.35, 0.06, (1, 3)), 0)
    place(x, tone(hz('E6'), 0.4, 0.35, 0.15, (1, 3)), 0.07)
    save('coin', x)
    x = np.zeros(int(1.2 * SR))
    for k, nt in enumerate(['A6', 'E6', 'A6']):
        place(x, tone(hz(nt), 0.8, 0.25, 0.25, (1, 2.4)), k * 0.09)
    save('door', reverb(x, 0.2)[:len(x)])
    x = np.zeros(int(1.0 * SR))
    for k in range(3):
        m = int(0.22 * SR)
        nz = lfilter([1, -1], [1, -0.7], rng.normal(0, 1, m)) * np.sin(np.linspace(0, np.pi, m)) ** 2
        place(x, 0.25 * nz, k * 0.3)
    save('sweep', x)
    x = np.zeros(int(0.6 * SR))
    place(x, tone(330, 0.25, 0.4, 0.1, (1, 2)), 0)
    place(x, tone(247, 0.35, 0.4, 0.15, (1, 2)), 0.18)
    save('fail', x)
    x = np.zeros(int(0.5 * SR))
    place(x, tone(hz('G5'), 0.2, 0.3, 0.06, (1, 2)), 0)
    place(x, tone(hz('C6'), 0.3, 0.3, 0.1, (1, 2)), 0.1)
    save('order', x)
    x = np.zeros(int(1.4 * SR))
    for k, nt in enumerate(['C6', 'E6', 'G6', 'C7']):
        place(x, tone(hz(nt), 0.9, 0.3, 0.3, (1, 2.76)), k * 0.08)
    save('sparkle', reverb(x, 0.25)[:len(x)])
    x = np.zeros(int(0.4 * SR))
    place(x, tone(hz('E5'), 0.15, 0.3, 0.05, (1, 2)), 0)
    place(x, tone(hz('A5'), 0.25, 0.3, 0.08, (1, 2)), 0.08)
    save('pick', x)


if __name__ == '__main__':
    sfx()
    shop_theme()
    village_theme()

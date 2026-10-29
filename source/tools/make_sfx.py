"""เสียงเอฟเฟกต์ + เสียงบรรยากาศ Eldoria (0.32) — สังเคราะห์ด้วยโค้ดล้วน (ไม่มีลิขสิทธิ์ผู้อื่น)
รัน: python3 source/tools/make_sfx.py → source/assets/sfx/<ชื่อ>.wav (22050 Hz 16-bit mono)
หลักทำให้สมจริง: เสียงกระทบ = โหมดสั่นหลายความถี่ (modal) ลดทอนต่างกัน + เสียงคลิกจากสัญญาณรบกวนกรองแถบ
ลมหวือ = noise ผ่านตัวกรองที่กวาดความถี่ · ทุกเสียงมีหลายแบบ (_0 _1 ...) ให้เกมสุ่ม + เพิ่ม reverb สั้นตามสถานที่
"""
import os
import numpy as np
from scipy import signal
import wave

SR = 22050
HERE = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.join(HERE, "..", "assets", "sfx")
rng = np.random.default_rng(7)

def t_(dur):
    return np.arange(int(SR * dur)) / SR

def noise(dur):
    return rng.standard_normal(int(SR * dur))

def bp(x, lo, hi, order=2):
    b, a = signal.butter(order, [lo / (SR / 2), min(hi, SR / 2 - 50) / (SR / 2)], "band")
    return signal.lfilter(b, a, x)

def lp(x, f, order=2):
    b, a = signal.butter(order, min(f, SR / 2 - 50) / (SR / 2), "low")
    return signal.lfilter(b, a, x)

def hp(x, f, order=2):
    b, a = signal.butter(order, f / (SR / 2), "high")
    return signal.lfilter(b, a, x)

def env_exp(dur, tau, attack=0.002):
    t = t_(dur)
    e = np.exp(-t / tau)
    a = int(SR * attack)
    if a > 0:
        e[:a] *= np.linspace(0, 1, a)
    return e

def modal(dur, modes, attack=0.0008):
    """โหมดสั่น: [(ความถี่, เวลาลดทอน, ความดัง)]"""
    t = t_(dur)
    out = np.zeros_like(t)
    for f, tau, amp in modes:
        out += amp * np.sin(2 * np.pi * f * t + rng.uniform(0, 6.28)) * np.exp(-t / tau)
    a = int(SR * attack)
    out[:a] *= np.linspace(0, 1, a)
    return out

def sweep_bp(x, f0, f1, f2, q=1.6):
    """ตัวกรองแถบที่กวาดความถี่ f0→f1→f2 (ลมหวือ) — state-variable filter"""
    n = len(x)
    fc = np.concatenate([np.linspace(f0, f1, n // 2), np.linspace(f1, f2, n - n // 2)])
    y = np.zeros(n)
    low = band = 0.0
    for i in range(n):
        f = 2 * np.sin(np.pi * fc[i] / SR)
        high = x[i] - low - band / q
        band += f * high
        low += f * band
        y[i] = band
    return y

def reverb(x, size=0.25, mix=0.2, damp=3000):
    ir_t = t_(size)
    ir = rng.standard_normal(len(ir_t)) * np.exp(-ir_t / (size / 5))
    ir = lp(ir, damp)
    wet = signal.fftconvolve(x, ir)[: len(x) + len(ir) - 1]
    dry = np.concatenate([x, np.zeros(len(ir) - 1)])
    wet = wet / (np.max(np.abs(wet)) + 1e-9) * np.max(np.abs(x))
    return dry * (1 - mix) + wet * mix

def norm(x, peak=0.85):
    m = np.max(np.abs(x)) + 1e-9
    x = x / m * peak
    f = min(len(x), int(SR * 0.004))
    x[-f:] *= np.linspace(1, 0, f)
    return x

def save(name, x, peak=0.85):
    x = norm(np.asarray(x, dtype=np.float64), peak)
    d = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(os.path.join(DEST, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(d.tobytes())

def pad(x, dur):
    n = int(SR * dur)
    return np.concatenate([x, np.zeros(max(0, n - len(x)))])[:n]

def at(dst, src, sec, gain=1.0):
    i = int(SR * sec)
    j = min(len(dst), i + len(src))
    dst[i:j] += src[: j - i] * gain
    return dst

# ---------------- เสียงเท้า ----------------
def step_grass(v):
    out = np.zeros(int(SR * 0.32))
    for k, (tt, g) in enumerate([(0.0, 1.0), (0.055 + v * 0.01, 0.7)]):
        n = noise(0.16)
        grains = (rng.random(len(n)) < 0.08) * rng.standard_normal(len(n)) * 3
        s = bp(n * 0.6 + grains, 900 + v * 150, 6500) * env_exp(0.16, 0.035 + 0.01 * k, 0.004)
        thud = lp(noise(0.08), 180) * env_exp(0.08, 0.02) * 0.8
        at(out, s + pad(thud, 0.16), tt, g)
    return out

def step_stone(v):
    out = np.zeros(int(SR * 0.28))
    for k, (tt, g) in enumerate([(0.0, 1.0), (0.045 + v * 0.008, 0.55)]):
        thump = modal(0.12, [(85 + v * 6, 0.025, 1.0), (170 + v * 9, 0.012, 0.4)])
        click = bp(noise(0.05), 1800, 5200) * env_exp(0.05, 0.006) * 0.9
        grit = bp(noise(0.1), 3000, 8000) * env_exp(0.1, 0.015) * 0.25
        at(out, thump + pad(click, 0.12) + pad(grit, 0.12), tt, g)
    return reverb(out, 0.18, 0.15)

def step_dirt(v):
    out = np.zeros(int(SR * 0.3))
    for k, (tt, g) in enumerate([(0.0, 1.0), (0.05 + v * 0.01, 0.6)]):
        thump = lp(noise(0.1), 260) * env_exp(0.1, 0.025) * 1.4
        crunch = bp(noise(0.12) * (1 + (rng.random(int(SR * 0.12)) < 0.05) * 4), 700, 4000) * env_exp(0.12, 0.03)
        at(out, thump + pad(crunch, 0.1)[: len(thump)], tt, g)
    return reverb(out, 0.4, 0.25, 2000)

# ---------------- ต่อสู้ ----------------
def swing(v, heavy=False):
    d = 0.42 if heavy else 0.3
    n = noise(d)
    f1 = (900 if heavy else 1500) + v * 180
    s = sweep_bp(n, 300, f1, 450, 1.3) * np.sin(np.linspace(0, np.pi, len(n))) ** 1.6
    return s + hp(s, 2500) * 0.3

def hit_flesh(v):
    thump = modal(0.25, [(95 + v * 10, 0.05, 1.0), (60, 0.08, 0.6)])
    slap = bp(noise(0.08), 900, 3500) * env_exp(0.08, 0.012) * 1.3
    squish = lp(noise(0.2), 900) * env_exp(0.2, 0.05) * 0.5
    return thump + pad(slap, 0.25) + pad(squish, 0.25)

def hit_metal(v):
    ring = modal(0.6, [(830 + v * 40, 0.18, 0.6), (1590 + v * 70, 0.12, 0.5), (2710, 0.09, 0.4), (4160, 0.05, 0.3)])
    clank = bp(noise(0.05), 2000, 7000) * env_exp(0.05, 0.006) * 1.2
    return reverb(ring + pad(clank, 0.6) + pad(modal(0.15, [(110, 0.03, 0.8)]), 0.6), 0.25, 0.18)

def slime_hop(v):
    t = t_(0.28)
    f = 210 + v * 25 - 120 * t / 0.28
    tone = np.sin(2 * np.pi * np.cumsum(f) / SR + 3 * np.sin(2 * np.pi * 18 * t)) * env_exp(0.28, 0.07, 0.01)
    wet = lp(noise(0.28), 700) * env_exp(0.28, 0.05) * 0.7
    return lp(tone * 0.7 + wet, 1600)

def slime_die(v):
    t = t_(0.55)
    f = 260 - 200 * t / 0.55
    gl = np.sin(2 * np.pi * np.cumsum(f + 25 * np.sin(2 * np.pi * 23 * t)) / SR) * env_exp(0.55, 0.15, 0.005)
    splat = lp(noise(0.55), 1200) * env_exp(0.55, 0.08) * 1.2
    drops = np.zeros(len(t))
    for k in range(5):
        dt_ = 0.12 + k * 0.07 + rng.uniform(0, 0.03)
        at(drops, modal(0.08, [(rng.uniform(500, 900), 0.015, 0.4)]), dt_)
    return lp(gl * 0.6 + splat + drops, 2400)

def hurt(v):
    thump = modal(0.3, [(70 + v * 6, 0.06, 1.0), (140, 0.03, 0.4)])
    grunt = bp(noise(0.3), 300, 1200) * env_exp(0.3, 0.06, 0.01) * 0.5
    return thump + grunt

def die():
    thud = modal(0.9, [(55, 0.15, 1.0), (90, 0.1, 0.5)])
    body = lp(noise(0.9), 400) * env_exp(0.9, 0.12) * 0.8
    clatter = np.zeros(len(thud))
    for k in range(4):
        at(clatter, modal(0.2, [(rng.uniform(900, 2400), 0.05, 0.3), (rng.uniform(2500, 4000), 0.03, 0.2)]), 0.18 + k * 0.09)
    return reverb(thud + body + clatter, 0.4, 0.2)

def roll(v):
    cloth = sweep_bp(noise(0.38), 400, 1300, 500, 1.0) * np.sin(np.linspace(0, np.pi, int(SR * 0.38))) * 0.8
    land = pad(np.zeros(int(SR * 0.26)), 0.26)
    land = np.concatenate([land, lp(noise(0.12), 250) * env_exp(0.12, 0.03) * 1.2])
    return cloth + pad(land, 0.38)

def bow_shot(v):
    # หน้าไม้: กลไกคลิก + สายดีด (Karplus-Strong) + ลูกศรหวือ
    n = int(SR * 0.4)
    p = int(SR / (95 + v * 8))
    buf = rng.uniform(-1, 1, p)
    out = np.zeros(n)
    for i in range(n):
        out[i] = buf[i % p]
        buf[i % p] = 0.5 * (buf[i % p] + buf[(i + 1) % p]) * 0.994
    click = bp(noise(0.03), 2500, 7000) * env_exp(0.03, 0.004) * 1.5
    whiz = sweep_bp(noise(0.25), 2500, 4000, 1500, 3.0) * env_exp(0.25, 0.08) * 0.4
    return out * env_exp(0.4, 0.09) * 0.8 + pad(click, 0.4) + pad(np.concatenate([np.zeros(int(SR * 0.03)), whiz]), 0.4)

def magic_cast(v):
    t = t_(0.7)
    sh = np.zeros(len(t))
    for k in range(6):
        f = 880 * 2 ** ((k * 3 + v) / 12)
        sh += np.sin(2 * np.pi * f * t * (1 + 0.003 * np.sin(2 * np.pi * 6 * t))) * np.exp(-((t - 0.08 * k - 0.1) ** 2) / 0.01)
    swirl = sweep_bp(noise(0.7), 600, 3500, 900, 2.0) * np.sin(np.linspace(0, np.pi, len(t))) * 0.6
    return reverb(sh * 0.35 + swirl, 0.5, 0.3, 5000)

def fireball():
    t = t_(0.8)
    roar = lp(noise(0.8), 600) * np.sin(np.linspace(0, np.pi, len(t))) ** 0.7
    crackle = (rng.random(len(t)) < 0.01) * rng.standard_normal(len(t)) * 3
    crackle = hp(crackle, 2000) * env_exp(0.8, 0.4)
    whoosh = sweep_bp(noise(0.8), 200, 1200, 300, 1.2) * np.sin(np.linspace(0, np.pi, len(t)))
    return roar + crackle * 0.6 + whoosh * 0.7

def boom():
    t = t_(1.2)
    low = modal(1.2, [(48, 0.3, 1.0), (75, 0.2, 0.6)])
    rumble = lp(noise(1.2), 300) * env_exp(1.2, 0.35) * 1.4
    debris = hp(noise(1.2), 1500) * env_exp(1.2, 0.12) * 0.4
    return reverb(low + rumble + debris, 0.8, 0.3, 1500)

def heal():
    t = t_(1.1)
    out = np.zeros(len(t))
    for k, semi in enumerate([0, 4, 7, 12, 16]):
        f = 660 * 2 ** (semi / 12)
        s = np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * f * 2.01 * t)
        out += s * np.exp(-np.maximum(t - k * 0.09, 0) / 0.35) * (t >= k * 0.09)
    sparkle = hp(noise(1.1), 6000) * env_exp(1.1, 0.4) * 0.15
    return reverb(out * 0.3 + sparkle, 0.6, 0.35, 6000)

# ---------------- เก็บของ ----------------
def chop(v):
    thunk = modal(0.35, [(120 + v * 12, 0.05, 1.0), (310 + v * 20, 0.04, 0.6), (540 + v * 30, 0.03, 0.5), (870, 0.02, 0.35), (1320, 0.015, 0.25)])
    bite = bp(noise(0.06), 1200, 5000) * env_exp(0.06, 0.008) * 1.3
    splinter = bp(noise(0.2), 2500, 8000) * env_exp(0.2, 0.03) * 0.25
    return reverb(thunk + pad(bite, 0.35) + pad(splinter, 0.35), 0.35, 0.18, 3500)

def tree_fall():
    d = 2.2
    out = np.zeros(int(SR * d))
    # เสียงไม้ปริ ลั่นเอี๊ยด แล้วล้มกระแทก ใบไม้ซู่
    for k in range(14):
        tt = 0.05 + k * 0.045 + rng.uniform(0, 0.02)
        at(out, bp(noise(0.03), 1500, 6000) * env_exp(0.03, 0.006), tt, 0.5 + k * 0.03)
    t = t_(0.6)
    creak = np.sin(2 * np.pi * np.cumsum(140 + 60 * np.sin(2 * np.pi * 3 * t) + rng.standard_normal(len(t)) * 20) / SR)
    creak = bp(creak * (1 + 0.5 * np.sign(np.sin(2 * np.pi * 35 * t))), 200, 1500) * np.sin(np.linspace(0, np.pi, len(t)))
    at(out, creak, 0.5, 0.5)
    swish = lp(noise(0.9), 3000) * np.sin(np.linspace(0, np.pi, int(SR * 0.9))) ** 2
    at(out, swish, 0.9, 0.45)
    impact = modal(0.9, [(42, 0.25, 1.0), (70, 0.15, 0.7), (115, 0.08, 0.4)]) + lp(noise(0.9), 500) * env_exp(0.9, 0.18) * 1.2
    at(out, impact, 1.3, 1.2)
    leaves = hp(noise(0.8), 2500) * env_exp(0.8, 0.25) * 0.35
    at(out, leaves, 1.32, 1.0)
    return reverb(out, 0.6, 0.2, 2500)

def mine(v):
    # พลั่วกระทบหิน: เสียงกริ๊งโลหะ (inharmonic) + หินแตกเป็นเม็ด
    ring = modal(0.45, [(1850 + v * 90, 0.09, 0.7), (3120 + v * 110, 0.06, 0.55), (4870, 0.04, 0.4), (6900, 0.025, 0.3)])
    knock = modal(0.2, [(260 + v * 20, 0.025, 1.0), (620, 0.015, 0.5)])
    click = hp(noise(0.03), 3000) * env_exp(0.03, 0.003) * 1.5
    grit = np.zeros(int(SR * 0.45))
    for k in range(8):
        at(grit, bp(noise(0.02), 2000, 8000) * env_exp(0.02, 0.004), 0.02 + k * 0.025 + rng.uniform(0, 0.02), 0.35)
    return reverb(ring + pad(knock, 0.45) + pad(click, 0.45) + grit, 0.5, 0.28, 4000)

def rock_break():
    d = 1.1
    out = np.zeros(int(SR * d))
    at(out, modal(0.5, [(70, 0.08, 1.0), (140, 0.05, 0.6)]), 0.0, 1.0)
    at(out, lp(noise(0.5), 800) * env_exp(0.5, 0.08), 0.0, 1.2)
    for k in range(40):
        tt = rng.uniform(0.02, 0.8) ** 1.5
        f = rng.uniform(1200, 6000)
        at(out, modal(0.06, [(f, 0.01, 1.0)]) + bp(noise(0.06), f * 0.7, min(f * 1.5, 10000)) * env_exp(0.06, 0.008), tt, rng.uniform(0.1, 0.35))
    return reverb(out, 0.6, 0.3, 3000)

def pickup():
    t = t_(0.18)
    f = 520 + 900 * t / 0.18
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env_exp(0.18, 0.05) + lp(noise(0.18), 2000) * env_exp(0.18, 0.01) * 0.3

def coin():
    out = np.zeros(int(SR * 0.6))
    for k, (f0, tt) in enumerate([(2093, 0.0), (2637, 0.075)]):
        bell = modal(0.5, [(f0, 0.12, 0.7), (f0 * 2.76, 0.05, 0.35), (f0 * 5.4, 0.025, 0.2), (f0 * 0.5, 0.08, 0.15)])
        at(out, bell + pad(hp(noise(0.01), 4000) * 0.6, 0.5), tt)
    return reverb(out, 0.25, 0.15, 7000)

def splash():
    d = 0.9
    out = lp(noise(d), 2500) * env_exp(d, 0.12, 0.004) * 1.2
    for k in range(10):
        tt = 0.08 + rng.uniform(0, 0.6)
        tt_ = t_(0.06)
        f = rng.uniform(600, 1400) * (1 + 3 * tt_ / 0.06)
        at(out, np.sin(2 * np.pi * np.cumsum(f) / SR) * env_exp(0.06, 0.015), tt, 0.3)
    return out

# ---------------- UI ----------------
def ui_click():
    return modal(0.08, [(1600, 0.012, 1.0), (3200, 0.006, 0.4)]) + pad(bp(noise(0.01), 3000, 9000) * 0.5, 0.08)

def ui_open():
    paper = sweep_bp(noise(0.28), 1500, 4500, 2500, 1.2) * np.sin(np.linspace(0, np.pi, int(SR * 0.28))) * 0.7
    thock = modal(0.2, [(420, 0.03, 0.7), (900, 0.015, 0.3)])
    return pad(paper, 0.3) + pad(thock, 0.3)

def ui_close():
    return pad(modal(0.15, [(340, 0.025, 0.8), (720, 0.012, 0.3)]), 0.2) + pad(lp(noise(0.12), 2000) * env_exp(0.12, 0.02) * 0.4, 0.2)

def buy():
    c = coin()
    bag = lp(noise(0.25), 1200) * env_exp(0.25, 0.05, 0.02) * 0.6
    return pad(c, 0.7) + pad(np.concatenate([np.zeros(int(SR * 0.12)), bag]), 0.7)

def level_up():
    t = t_(1.8)
    out = np.zeros(len(t))
    for k, semi in enumerate([0, 4, 7, 12, 16, 19, 24]):
        f = 523.25 * 2 ** (semi / 12)
        st = k * 0.085
        tt = np.maximum(t - st, 0)
        s = (np.sin(2 * np.pi * f * tt) + 0.4 * np.sin(2 * np.pi * f * 2 * tt) + 0.15 * np.sin(2 * np.pi * f * 3.01 * tt)) * np.exp(-tt / 0.5) * (t >= st)
        out += s
    shimmer = hp(noise(1.8), 5000) * env_exp(1.8, 0.6) * 0.12
    return reverb(out * 0.25 + shimmer, 0.9, 0.35, 6000)

def warp():
    t = t_(1.2)
    f = 200 * 2 ** (4 * t / 1.2)
    tone = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.linspace(0, np.pi, len(t)))
    swirl = sweep_bp(noise(1.2), 300, 5000, 2000, 2.5) * np.sin(np.linspace(0, np.pi, len(t)))
    return reverb(tone * 0.3 + swirl * 0.8, 0.7, 0.4, 6000)

def door():
    t = t_(0.9)
    creak = np.sin(2 * np.pi * np.cumsum(180 + 90 * t / 0.9 + rng.standard_normal(len(t)) * 15) / SR)
    creak = bp(creak * (1 + 0.6 * np.sign(np.sin(2 * np.pi * 28 * t))), 250, 2200) * np.sin(np.linspace(0, np.pi, len(t))) * 0.5
    latch = pad(np.concatenate([np.zeros(int(SR * 0.7)), modal(0.2, [(900, 0.02, 1.0), (2100, 0.01, 0.5)])]), 0.9)
    return reverb(creak + latch, 0.4, 0.2)

# ---------------- บรรยากาศ (วนซ้ำได้) ----------------
def loopify(x, xf=1.0):
    n = int(SR * xf)
    a = x[:n] * np.linspace(0, 1, n)
    body = x[n:].copy()
    body[-n:] = body[-n:] * np.linspace(1, 0, n) + a
    return body

def wind(dur):
    w = lp(noise(dur), 500, 1)
    w = lp(w, 900)
    mod = 0.55 + 0.45 * np.sin(2 * np.pi * np.cumsum(0.07 + 0.05 * np.sin(2 * np.pi * 0.03 * t_(dur))) / SR)
    gust = hp(noise(dur), 1500) * mod ** 3 * 0.05
    return w * mod + gust

def bird(f0):
    out = np.zeros(int(SR * 0.6))
    tt = 0.0
    for k in range(rng.integers(2, 5)):
        d = rng.uniform(0.05, 0.11)
        t = t_(d)
        f = f0 * (1 + rng.uniform(-0.15, 0.25)) * (1 + 0.35 * np.sin(np.pi * t / d * rng.uniform(1, 2)))
        ch = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * t / d) ** 2
        at(out, ch, tt)
        tt += d + rng.uniform(0.02, 0.07)
    return out

def amb_field():
    dur = 16
    out = wind(dur) * 0.6
    for k in range(9):
        at(out, bird(rng.uniform(2600, 4200)), rng.uniform(0.5, dur - 1.5), rng.uniform(0.08, 0.2))
    leaves = hp(noise(dur), 3000) * (0.3 + 0.7 * np.abs(np.sin(2 * np.pi * 0.09 * t_(dur)))) * 0.03
    return loopify(out + leaves)

def amb_town():
    dur = 16
    out = wind(dur) * 0.35
    water = bp(noise(dur), 300, 4000) * (0.8 + 0.2 * np.sin(2 * np.pi * 0.7 * t_(dur))) * 0.12
    out += water
    for k in range(5):
        at(out, bird(rng.uniform(2800, 4000)), rng.uniform(0.5, dur - 1.5), rng.uniform(0.05, 0.12))
    murmur = lp(bp(noise(dur), 180, 900), 700) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.21 * t_(dur))) * 0.25
    return loopify(out + murmur)

def amb_night():
    dur = 12
    out = wind(dur) * 0.3
    t = t_(dur)
    for k in range(3):
        f = rng.uniform(4200, 5200)
        rate = rng.uniform(2.5, 4.0)
        gate = (np.sin(2 * np.pi * rate * t + k) > 0.6).astype(float)
        gate = lp(gate, 60)
        chirp = np.sin(2 * np.pi * f * t) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 45 * t))) * gate
        out += lp(chirp, 7000) * 0.05
    return loopify(out)

def amb_mine():
    dur = 14
    t = t_(dur)
    drone = lp(noise(dur), 160) * 2.0 + np.sin(2 * np.pi * 55 * t) * 0.05
    out = drone * (0.7 + 0.3 * np.sin(2 * np.pi * 0.05 * t))
    for k in range(10):
        tt = rng.uniform(0.3, dur - 1.0)
        d = t_(0.25)
        f = rng.uniform(900, 1500) * (1 - 0.4 * d / 0.25)
        drip = np.sin(2 * np.pi * np.cumsum(f) / SR) * env_exp(0.25, 0.04)
        at(out, drip, tt, rng.uniform(0.15, 0.3))
    return loopify(reverb(out, 1.2, 0.45, 2500))

def main():
    os.makedirs(DEST, exist_ok=True)
    for v in range(4):
        save("step_grass_%d" % v, step_grass(v), 0.6)
        save("step_stone_%d" % v, step_stone(v), 0.6)
        save("step_dirt_%d" % v, step_dirt(v), 0.6)
    for v in range(3):
        save("swing_%d" % v, swing(v))
        save("swing_heavy_%d" % v, swing(v, True))
        save("hit_flesh_%d" % v, hit_flesh(v))
        save("hit_metal_%d" % v, hit_metal(v))
        save("slime_hop_%d" % v, slime_hop(v), 0.5)
        save("slime_die_%d" % v, slime_die(v))
        save("hurt_%d" % v, hurt(v))
        save("roll_%d" % v, roll(v))
        save("bow_%d" % v, bow_shot(v))
        save("magic_%d" % v, magic_cast(v))
        save("chop_%d" % v, chop(v))
        save("mine_%d" % v, mine(v))
    save("die", die())
    save("fireball", fireball())
    save("boom", boom())
    save("heal", heal(), 0.7)
    save("tree_fall", tree_fall())
    save("rock_break", rock_break())
    save("pickup", pickup(), 0.6)
    save("coin", coin(), 0.65)
    save("splash", splash())
    save("ui_click", ui_click(), 0.55)
    save("ui_open", ui_open(), 0.6)
    save("ui_close", ui_close(), 0.55)
    save("buy", buy(), 0.7)
    save("level_up", level_up(), 0.75)
    save("warp", warp())
    save("door", door(), 0.7)
    save("amb_field", amb_field(), 0.5)
    save("amb_town", amb_town(), 0.5)
    save("amb_night", amb_night(), 0.45)
    save("amb_mine", amb_mine(), 0.5)
    print("sfx:", len([f for f in os.listdir(DEST) if f.endswith(".wav")]))

if __name__ == "__main__":
    main()

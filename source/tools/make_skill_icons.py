"""ภาพสกิล Eldoria (0.30) — วาดด้วยโค้ดล้วน (แนวเดียวกับ SKART ของเกม 2D แต่เขียนใหม่)
รัน: python3 source/tools/make_skill_icons.py  → source/assets/icons/sk_<อาชีพ>_<ช่อง>.png และ sk_whirl/fireball/heal
ทุกรูป: ป้ายเหลี่ยมมนพื้นไล่สีตามอาชีพ + ขอบทอง + สัญลักษณ์สีสว่างมีเงาเข้มและแสงเรือง · วาดใหญ่ 4 เท่าแล้วย่อให้คม
"""
import math, os, sys
from PIL import Image, ImageDraw, ImageFilter

S = 384               # วาดใหญ่ แล้วย่อเป็น OUT
OUT = 128
HERE = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.join(HERE, "..", "assets", "icons")

CLS_COL = {
    "sword": (255, 138, 107), "archer": (125, 255, 138), "mage": (178, 140, 255), "rogue": (201, 160, 255),
    "paladin": (255, 233, 160), "dragoon": (255, 106, 90), "sniper": (255, 210, 58), "summoner": (154, 223, 106),
    "cleric": (191, 240, 255), "necro": (122, 255, 176), "ninja": (138, 154, 255), "monk": (255, 180, 106),
    "none": (200, 200, 200),
}

def P(x, y):
    return (x * S, y * S)

def rot(pt, ang, c=(0.5, 0.5)):
    x, y = pt[0] - c[0], pt[1] - c[1]
    ca, sa = math.cos(ang), math.sin(ang)
    return (c[0] + x * ca - y * sa, c[1] + x * sa + y * ca)

def poly(d, pts, fill, ang=0.0, c=(0.5, 0.5), outline=None, w=0):
    pts = [P(*rot(p, ang, c)) for p in pts]
    d.polygon(pts, fill=fill, outline=outline, width=w)

def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

# ---------------- พื้นป้าย ----------------
def badge(col):
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dark = mix(col, (10, 12, 24), 0.78)
    mid = mix(col, (20, 20, 40), 0.45)
    bg = Image.new("RGBA", (S, S))
    px = bg.load()
    for y in range(S):
        for x in range(S):
            dx, dy = (x - S * 0.5) / S, (y - S * 0.42) / S
            t = min(1.0, math.sqrt(dx * dx + dy * dy) * 1.9)
            c = mix(mid, dark, t)
            px[x, y] = c + (255,)
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle((10, 10, S - 10, S - 10), radius=70, fill=255)
    im.paste(bg, (0, 0), mask)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((10, 10, S - 10, S - 10), radius=70, outline=(214, 178, 98, 255), width=14)
    d.rounded_rectangle((26, 26, S - 26, S - 26), radius=58, outline=mix(col, (255, 255, 255), 0.2) + (110,), width=4)
    return im

# ---------------- สัญลักษณ์ (วาดลงชั้นแยก แล้วใส่เงา/เรือง) ----------------
def blade(d, cx, cy, ang, ln, wd, col, guard=True, hilt=(110, 70, 40)):
    """ดาบ/มีด: ปลายชี้ตาม ang (0 = ขึ้น)"""
    c = (cx, cy)
    tip = (cx, cy - ln * 0.62)
    pts = [(cx - wd, cy - ln * 0.05), (cx - wd, cy - ln * 0.48), tip, (cx + wd, cy - ln * 0.48), (cx + wd, cy - ln * 0.05)]
    poly(d, pts, col, ang, c)
    poly(d, [(cx - wd * 0.15, cy - ln * 0.05), (cx - wd * 0.15, cy - ln * 0.5), tip, (cx + wd * 0.1, cy - ln * 0.5), (cx + wd * 0.1, cy - ln * 0.05)], mix(col, (255, 255, 255), 0.55), ang, c)
    if guard:
        poly(d, [(cx - wd * 3.2, cy - ln * 0.02), (cx + wd * 3.2, cy - ln * 0.02), (cx + wd * 3.2, cy + ln * 0.05), (cx - wd * 3.2, cy + ln * 0.05)], (214, 178, 98), ang, c)
    poly(d, [(cx - wd * 0.7, cy + ln * 0.05), (cx + wd * 0.7, cy + ln * 0.05), (cx + wd * 0.7, cy + ln * 0.3), (cx - wd * 0.7, cy + ln * 0.3)], hilt, ang, c)
    poly(d, [(cx - wd * 1.1, cy + ln * 0.3), (cx + wd * 1.1, cy + ln * 0.3), (cx + wd * 1.1, cy + ln * 0.37), (cx - wd * 1.1, cy + ln * 0.37)], (214, 178, 98), ang, c)

def arrow(d, cx, cy, ang, ln, col, head=(235, 235, 245), feather=(240, 80, 70)):
    c = (cx, cy)
    poly(d, [(cx - 0.008, cy - ln * 0.45), (cx + 0.008, cy - ln * 0.45), (cx + 0.008, cy + ln * 0.45), (cx - 0.008, cy + ln * 0.45)], col, ang, c)
    poly(d, [(cx, cy - ln * 0.6), (cx - 0.035, cy - ln * 0.42), (cx + 0.035, cy - ln * 0.42)], head, ang, c)
    for s in (-1, 1):
        poly(d, [(cx, cy + ln * 0.3), (cx + s * 0.04, cy + ln * 0.42), (cx + s * 0.04, cy + ln * 0.52), (cx, cy + ln * 0.42)], feather, ang, c)

def arc(d, cx, cy, r, a0, a1, col, w):
    d.arc((P(cx - r, cy - r), P(cx + r, cy + r)), a0, a1, fill=col, width=int(w * S))

def circle(d, cx, cy, r, col, outline=None, w=0):
    d.ellipse((P(cx - r, cy - r), P(cx + r, cy + r)), fill=col, outline=outline, width=int(w * S) if w else 0)

def flame(d, cx, cy, sc, cols=((255, 90, 30), (255, 170, 40), (255, 245, 170))):
    for i, col in enumerate(cols):
        k = 1.0 - i * 0.28
        pts = []
        for j in range(24):
            a = j / 24 * math.tau
            r = 0.16 * sc * k
            x = math.sin(a) * r * 0.8
            y = -math.cos(a) * r
            if y < 0:
                y *= 1.0 + 0.9 * (1 - abs(math.sin(a)))
                x *= 0.75
            pts.append((cx + x, cy + y + i * 0.02 * sc))
        poly(d, pts, col)

def star4(d, cx, cy, r, ang, col):
    pts = []
    for i in range(8):
        a = ang + i * math.pi / 4
        rr = r if i % 2 == 0 else r * 0.32
        pts.append((cx + math.sin(a) * rr, cy - math.cos(a) * rr))
    poly(d, pts, col)
    circle(d, cx, cy, r * 0.16, (40, 40, 60))

def bolt(d, pts, col, w):
    d.line([P(*p) for p in pts], fill=col, width=int(w * S), joint="curve")

def skull(d, cx, cy, sc, col=(235, 235, 220)):
    circle(d, cx, cy - 0.02 * sc, 0.15 * sc, col)
    d.rounded_rectangle((P(cx - 0.09 * sc, cy + 0.06 * sc), P(cx + 0.09 * sc, cy + 0.16 * sc)), radius=int(0.03 * sc * S), fill=col)
    for s in (-1, 1):
        circle(d, cx + s * 0.055 * sc, cy - 0.01 * sc, 0.042 * sc, (30, 20, 40))
    poly(d, [(cx, cy + 0.03 * sc), (cx - 0.02 * sc, cy + 0.07 * sc), (cx + 0.02 * sc, cy + 0.07 * sc)], (30, 20, 40))
    for i in range(3):
        x = cx - 0.05 * sc + i * 0.05 * sc
        d.line([P(x, cy + 0.1 * sc), P(x, cy + 0.16 * sc)], fill=(30, 20, 40), width=int(0.012 * sc * S))

def shield(d, cx, cy, sc, col, rim=(214, 178, 98)):
    pts = [(cx - 0.17 * sc, cy - 0.18 * sc), (cx + 0.17 * sc, cy - 0.18 * sc), (cx + 0.17 * sc, cy + 0.02 * sc), (cx, cy + 0.22 * sc), (cx - 0.17 * sc, cy + 0.02 * sc)]
    poly(d, pts, rim)
    pts2 = [(cx - 0.135 * sc, cy - 0.15 * sc), (cx + 0.135 * sc, cy - 0.15 * sc), (cx + 0.135 * sc, cy + 0.01 * sc), (cx, cy + 0.17 * sc), (cx - 0.135 * sc, cy + 0.01 * sc)]
    poly(d, pts2, col)

def cross(d, cx, cy, sc, col):
    d.rectangle((P(cx - 0.035 * sc, cy - 0.15 * sc), P(cx + 0.035 * sc, cy + 0.15 * sc)), fill=col)
    d.rectangle((P(cx - 0.12 * sc, cy - 0.07 * sc), P(cx + 0.12 * sc, cy - 0.0 * sc)), fill=col)

def plus(d, cx, cy, sc, col):
    d.rounded_rectangle((P(cx - 0.05 * sc, cy - 0.17 * sc), P(cx + 0.05 * sc, cy + 0.17 * sc)), radius=int(0.02 * S * sc), fill=col)
    d.rounded_rectangle((P(cx - 0.17 * sc, cy - 0.05 * sc), P(cx + 0.17 * sc, cy + 0.05 * sc)), radius=int(0.02 * S * sc), fill=col)

def rays(d, cx, cy, r0, r1, n, col, w, a0=0.0):
    for i in range(n):
        a = a0 + i * math.tau / n
        d.line([P(cx + math.sin(a) * r0, cy - math.cos(a) * r0), P(cx + math.sin(a) * r1, cy - math.cos(a) * r1)], fill=col, width=int(w * S))

def fist(d, cx, cy, sc, col):
    d.rounded_rectangle((P(cx - 0.13 * sc, cy - 0.1 * sc), P(cx + 0.11 * sc, cy + 0.12 * sc)), radius=int(0.05 * S * sc), fill=col)
    for i in range(4):
        y = cy - 0.08 * sc + i * 0.05 * sc
        d.line([P(cx + 0.02 * sc, y), P(cx + 0.11 * sc, y)], fill=mix(col, (60, 30, 20), 0.5), width=int(0.01 * S))
    d.rounded_rectangle((P(cx - 0.17 * sc, cy - 0.04 * sc), P(cx - 0.05 * sc, cy + 0.04 * sc)), radius=int(0.03 * S * sc), fill=mix(col, (255, 255, 255), 0.15))

def paw(d, cx, cy, sc, col):
    circle(d, cx, cy + 0.05 * sc, 0.1 * sc, col)
    for i, (dx, dy) in enumerate([(-0.12, -0.06), (-0.045, -0.13), (0.045, -0.13), (0.12, -0.06)]):
        circle(d, cx + dx * sc, cy + dy * sc, 0.045 * sc, col)

def claws(d, cx, cy, sc, col):
    for i in range(3):
        x = cx - 0.1 * sc + i * 0.1 * sc
        d.line([P(x - 0.06 * sc, cy - 0.17 * sc), P(x - 0.01 * sc, cy), P(x + 0.04 * sc, cy + 0.17 * sc)], fill=col, width=int(0.035 * S * sc), joint="curve")

def spear(d, cx, cy, ang, ln, col):
    c = (cx, cy)
    poly(d, [(cx - 0.012, cy - ln * 0.38), (cx + 0.012, cy - ln * 0.38), (cx + 0.012, cy + ln * 0.5), (cx - 0.012, cy + ln * 0.5)], (120, 80, 45), ang, c)
    poly(d, [(cx, cy - ln * 0.62), (cx - 0.045, cy - ln * 0.4), (cx, cy - ln * 0.34), (cx + 0.045, cy - ln * 0.4)], col, ang, c)
    poly(d, [(cx - 0.05, cy - ln * 0.36), (cx + 0.05, cy - ln * 0.36), (cx + 0.05, cy - ln * 0.32), (cx - 0.05, cy - ln * 0.32)], (214, 178, 98), ang, c)

def crosshair(d, cx, cy, r, col, w=0.022):
    circle(d, cx, cy, r, None, col, w)
    circle(d, cx, cy, r * 0.45, None, col, w * 0.7)
    for a in range(4):
        aa = a * math.pi / 2
        d.line([P(cx + math.sin(aa) * r * 0.6, cy - math.cos(aa) * r * 0.6), P(cx + math.sin(aa) * r * 1.25, cy - math.cos(aa) * r * 1.25)], fill=col, width=int(w * S))

def meteor(d, cx, cy, r, ang=-0.8):
    for i in range(5):
        t = i / 5
        circle(d, cx - math.sin(ang) * r * (1.2 + t * 2.2), cy + math.cos(ang) * r * (-1.2 - t * 2.2) * -1, r * (0.85 - t * 0.15), (255, 140 - i * 20, 40, 255 - i * 45))
    circle(d, cx, cy, r, (255, 120, 40))
    circle(d, cx - r * 0.25, cy - r * 0.25, r * 0.55, (255, 220, 120))

def shard(d, cx, cy, sc, ang, col=(170, 230, 255)):
    poly(d, [(cx, cy - 0.16 * sc), (cx + 0.05 * sc, cy), (cx, cy + 0.08 * sc), (cx - 0.05 * sc, cy)], col, ang, (cx, cy))
    poly(d, [(cx, cy - 0.16 * sc), (cx + 0.02 * sc, cy), (cx, cy + 0.08 * sc)], (240, 252, 255), ang, (cx, cy))

def wing(d, cx, cy, s, col):
    # ปีก 5 ชั้นขนนก กางจากจุดกลางออกด้านข้าง
    for i in range(5):
        y0 = cy - 0.06 + i * 0.05
        pts = [(cx + s * 0.03, cy + 0.02), (cx + s * (0.12 + i * 0.03), y0 - 0.2 + i * 0.02), (cx + s * (0.36 - i * 0.04), y0 - 0.16 + i * 0.03), (cx + s * (0.3 - i * 0.05), y0 - 0.06 + i * 0.03), (cx + s * 0.05, cy + 0.08)]
        poly(d, pts, mix(col, (200, 225, 255), 0.18 * i))

def silhouette(d, cx, cy, sc, col):
    circle(d, cx, cy - 0.13 * sc, 0.055 * sc, col)
    poly(d, [(cx - 0.07 * sc, cy - 0.07 * sc), (cx + 0.07 * sc, cy - 0.07 * sc), (cx + 0.09 * sc, cy + 0.08 * sc), (cx + 0.05 * sc, cy + 0.2 * sc), (cx - 0.05 * sc, cy + 0.2 * sc), (cx - 0.09 * sc, cy + 0.08 * sc)], col)

def spiral(d, cx, cy, r, col, w, turns=1.6):
    pts = []
    for i in range(80):
        t = i / 79
        a = t * turns * math.tau
        rr = r * (0.15 + 0.85 * t)
        pts.append(P(cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    d.line(pts, fill=col, width=int(w * S), joint="curve")

def slashes(d, n, col, w=0.03):
    for i in range(n):
        y = 0.3 + i * 0.16
        arc(d, 0.5 + 0.05 * (i - 1), y + 0.25, 0.32, 200, 320, col, w)

# ---------------- รายการสกิล ----------------
W = (255, 255, 255)
GOLD = (255, 214, 110)

def g_sword0(d):  # กระทืบปฐพี
    for i, r in enumerate([0.36, 0.28, 0.2]):
        arc(d, 0.5, 0.72, r, 190, 350, mix((255, 200, 120), (255, 120, 60), i / 2), 0.03)
    poly(d, [(0.5, 0.62), (0.44, 0.74), (0.5, 0.71), (0.47, 0.84), (0.56, 0.7), (0.5, 0.73), (0.55, 0.62)], (90, 60, 40))
    d.rectangle((P(0.18, 0.74), P(0.82, 0.8)), fill=(120, 85, 55))
    blade(d, 0.5, 0.42, 0.0, 0.42, 0.03, (220, 225, 235))

def g_sword1(d):  # ดาบสามจังหวะ
    slashes(d, 3, (255, 210, 150), 0.028)
    blade(d, 0.42, 0.55, 0.6, 0.6, 0.032, (225, 230, 240))

def g_sword2(d):  # พายุดาบ
    spiral(d, 0.5, 0.5, 0.34, (255, 190, 130), 0.035, 1.8)
    for i in range(3):
        blade(d, 0.5 + math.sin(i * 2.1) * 0.22, 0.5 - math.cos(i * 2.1) * 0.22, i * 2.1 + 1.5, 0.3, 0.02, (230, 235, 245), False)

def g_mage0(d):  # วงแหวนเพลิง
    for i in range(8):
        a = i * math.tau / 8
        flame(d, 0.5 + math.sin(a) * 0.27, 0.53 - math.cos(a) * 0.27, 0.55)
    circle(d, 0.5, 0.5, 0.1, (255, 230, 160))

def g_mage1(d):  # เวทธาตุสามสาย
    shard(d, 0.27, 0.42, 1.0, -0.4)
    bolt(d, [(0.52, 0.22), (0.44, 0.45), (0.56, 0.45), (0.46, 0.7)], (255, 245, 120), 0.035)
    meteor(d, 0.74, 0.62, 0.075)

def g_mage2(d):  # พายุอุกกาบาต
    meteor(d, 0.35, 0.36, 0.07)
    meteor(d, 0.66, 0.5, 0.09)
    meteor(d, 0.42, 0.7, 0.06)

def g_archer0(d):  # ยิงกระจาย
    for a in [-0.6, -0.3, 0, 0.3, 0.6]:
        arrow(d, 0.5 + math.sin(a) * 0.12, 0.55 - math.cos(a) * 0.05, a, 0.55, (180, 130, 80))

def g_archer1(d):  # ธนูวิญญาณ
    spiral(d, 0.5, 0.5, 0.3, (140, 255, 190), 0.025, 1.3)
    arrow(d, 0.5, 0.5, 0.78, 0.7, (200, 255, 220), (230, 255, 240), (120, 255, 170))

def g_archer2(d):  # ฝนธนู
    for i, (x, y) in enumerate([(0.3, 0.36), (0.5, 0.3), (0.7, 0.38), (0.4, 0.62), (0.62, 0.64)]):
        arrow(d, x, y, math.pi + 0.15, 0.3, (180, 130, 80))
    d.rectangle((P(0.15, 0.82), P(0.85, 0.85)), fill=(120, 90, 60))

def g_rogue0(d):  # มีดพิษคู่
    blade(d, 0.42, 0.55, -0.45, 0.48, 0.025, (220, 225, 240))
    blade(d, 0.58, 0.55, 0.45, 0.48, 0.025, (220, 225, 240))
    poly(d, [(0.5, 0.2), (0.56, 0.3), (0.5, 0.35), (0.44, 0.3)], (120, 255, 120))
    circle(d, 0.5, 0.3, 0.05, (120, 255, 120))

def g_rogue1(d):  # ใบมีดสามจังหวะ
    slashes(d, 3, (210, 170, 255), 0.026)
    blade(d, 0.55, 0.55, 0.9, 0.42, 0.024, (225, 230, 245))

def g_rogue2(d):  # พายุมีดบิน
    for i in range(8):
        a = i * math.tau / 8
        blade(d, 0.5 + math.sin(a) * 0.25, 0.5 - math.cos(a) * 0.25, a, 0.22, 0.016, (225, 225, 245), False)
    circle(d, 0.5, 0.5, 0.07, (210, 170, 255))

def g_ninja0(d):  # ดาวกระจายพายุ
    star4(d, 0.5, 0.5, 0.3, 0.3, (215, 220, 240))
    for i in range(4):
        arc(d, 0.5, 0.5, 0.37, i * 90 + 20, i * 90 + 60, (160, 170, 255), 0.02)

def g_ninja1(d):  # เงาพริบตา
    silhouette(d, 0.38, 0.52, 1.3, (60, 60, 110))
    silhouette(d, 0.6, 0.5, 1.3, (30, 30, 50))
    blade(d, 0.72, 0.5, 0.9, 0.3, 0.02, (220, 225, 245), False)

def g_ninja2(d):  # พันเงาสังหาร
    for i, x in enumerate([0.28, 0.5, 0.72]):
        silhouette(d, x, 0.53 - (i == 1) * 0.04, 1.1, (40 + i * 25, 40 + i * 25, 90 + i * 30))
    slashes(d, 2, (170, 180, 255), 0.02)

def g_sniper0(d):  # กระสุนเจาะเกราะ
    crosshair(d, 0.5, 0.5, 0.24, (255, 220, 90))
    arrow(d, 0.5, 0.5, 1.2, 0.75, (230, 200, 120), (255, 255, 255), (255, 200, 60))

def g_sniper1(d):  # ยิงสามจังหวะ
    crosshair(d, 0.5, 0.5, 0.26, (255, 220, 90))
    for x in [0.42, 0.5, 0.58]:
        circle(d, x, 0.5, 0.025, (255, 90, 60))

def g_sniper2(d):  # ห่ากระสุนพิฆาต
    for i in range(7):
        x = 0.24 + i * 0.087
        d.line([P(x, 0.2 + (i % 2) * 0.08), P(x - 0.04, 0.62 + (i % 3) * 0.05)], fill=(255, 220, 110), width=int(0.018 * S))
    for x in [0.3, 0.52, 0.72]:
        circle(d, x, 0.74, 0.06, (255, 140, 50))

def g_paladin0(d):  # ค้อนศักดิ์สิทธิ์
    rays(d, 0.5, 0.42, 0.2, 0.36, 12, (255, 240, 170), 0.018)
    d.rectangle((P(0.475, 0.36), P(0.525, 0.82)), fill=(150, 100, 60))
    d.rounded_rectangle((P(0.32, 0.24), P(0.68, 0.42)), radius=int(0.03 * S), fill=(230, 225, 210))
    d.rectangle((P(0.32, 0.3), P(0.68, 0.34)), fill=(214, 178, 98))

def g_paladin1(d):  # ดาบแห่งแสง
    rays(d, 0.5, 0.45, 0.16, 0.38, 16, (255, 245, 190), 0.012)
    blade(d, 0.5, 0.56, 0.0, 0.62, 0.035, (255, 250, 220))

def g_paladin2(d):  # ปราการเทพ
    circle(d, 0.5, 0.5, 0.36, None, (255, 240, 170), 0.02)
    shield(d, 0.5, 0.5, 1.3, (230, 225, 210))
    cross(d, 0.5, 0.52, 0.9, (214, 178, 98))

def g_cleric0(d):  # แสงรักษา
    circle(d, 0.5, 0.5, 0.3, (140, 230, 255, 120))
    plus(d, 0.5, 0.5, 1.4, (150, 255, 170))

def g_cleric1(d):  # พิพากษาสวรรค์
    poly(d, [(0.4, 0.12), (0.6, 0.12), (0.68, 0.8), (0.32, 0.8)], (255, 250, 210))
    poly(d, [(0.46, 0.12), (0.54, 0.12), (0.58, 0.8), (0.42, 0.8)], (255, 255, 255))
    arc(d, 0.5, 0.82, 0.22, 180, 360, (255, 240, 170), 0.025)

def g_cleric2(d):  # อวยพรเทวา
    wing(d, 0.5, 0.6, -1, (245, 250, 255))
    wing(d, 0.5, 0.6, 1, (245, 250, 255))
    circle(d, 0.5, 0.3, 0.1, None, (255, 230, 120), 0.025)
    circle(d, 0.5, 0.52, 0.06, (255, 240, 180))

def g_necro0(d):  # ปลุกโครงกระดูก
    skull(d, 0.5, 0.48, 1.6)
    circle(d, 0.42, 0.47, 0.025, (120, 255, 170))
    circle(d, 0.58, 0.47, 0.025, (120, 255, 170))

def g_necro1(d):  # คำสาปวิญญาณ
    spiral(d, 0.5, 0.52, 0.32, (160, 90, 255), 0.04, 1.7)
    spiral(d, 0.5, 0.52, 0.22, (120, 255, 170), 0.02, 1.4)

def g_necro2(d):  # กองทัพมรณะ
    skull(d, 0.3, 0.6, 0.9)
    skull(d, 0.7, 0.6, 0.9)
    skull(d, 0.5, 0.42, 1.2)

def g_monk0(d):  # หมัดพันครั้ง
    for i in range(5):
        d.line([P(0.12, 0.3 + i * 0.1), P(0.38, 0.3 + i * 0.1)], fill=(255, 210, 150), width=int(0.018 * S))
    fist(d, 0.58, 0.5, 1.4, (240, 190, 150))

def g_monk1(d):  # ฝ่ามือมังกร
    for i in range(3):
        arc(d, 0.62, 0.5, 0.12 + i * 0.09, 300, 420, (255, 200, 110), 0.025)
    d.rounded_rectangle((P(0.24, 0.3), P(0.44, 0.72)), radius=int(0.05 * S), fill=(240, 190, 150))
    for i in range(4):
        d.rounded_rectangle((P(0.25 + i * 0.05, 0.18), P(0.29 + i * 0.05, 0.36)), radius=int(0.02 * S), fill=(240, 190, 150))

def g_monk2(d):  # จิตอรหันต์
    rays(d, 0.5, 0.48, 0.2, 0.38, 14, (255, 210, 110), 0.016)
    for i in range(5):
        a = (i - 2) * 0.45
        poly(d, [(0.5, 0.7), (0.5 + math.sin(a) * 0.08, 0.62), (0.5 + math.sin(a) * 0.2, 0.48 + abs(a) * 0.08), (0.5 + math.sin(a) * 0.05, 0.66)], (255, 170, 200))
    silhouette(d, 0.5, 0.4, 0.9, (255, 220, 140))

def g_dragoon0(d):  # แทงทะลวง
    for i in range(3):
        d.line([P(0.15, 0.4 + i * 0.1), P(0.4, 0.4 + i * 0.1)], fill=(255, 160, 120), width=int(0.016 * S))
    spear(d, 0.55, 0.5, math.pi / 2, 0.8, (230, 230, 240))

def g_dragoon1(d):  # กระโดดมังกร
    arc(d, 0.5, 0.75, 0.3, 200, 340, (255, 140, 110), 0.03)
    spear(d, 0.52, 0.45, math.pi + 0.35, 0.65, (230, 230, 240))

def g_dragoon2(d):  # มังกรเทพลงมา
    flame(d, 0.5, 0.62, 1.6)
    poly(d, [(0.3, 0.3), (0.5, 0.18), (0.7, 0.3), (0.62, 0.42), (0.5, 0.36), (0.38, 0.42)], (200, 60, 50))
    for s in (-1, 1):
        poly(d, [(0.5 + s * 0.12, 0.24), (0.5 + s * 0.22, 0.1), (0.5 + s * 0.18, 0.26)], (240, 220, 180))
        circle(d, 0.5 + s * 0.07, 0.3, 0.022, (255, 240, 120))

def g_summoner0(d):  # เรียกหมาป่า
    paw(d, 0.5, 0.52, 1.6, (220, 240, 200))

def g_summoner1(d):  # สัญชาตญาณป่า
    claws(d, 0.5, 0.5, 1.4, (190, 255, 150))

def g_summoner2(d):  # ราชสีห์วิญญาณ
    rays(d, 0.5, 0.52, 0.16, 0.34, 18, (255, 200, 80), 0.03)
    circle(d, 0.5, 0.52, 0.17, (255, 215, 120))
    for s in (-1, 1):
        circle(d, 0.5 + s * 0.06, 0.48, 0.022, (80, 50, 20))
    poly(d, [(0.46, 0.57), (0.54, 0.57), (0.5, 0.61)], (80, 50, 20))

def g_whirl(d):
    for i in range(3):
        arc(d, 0.5, 0.5, 0.18 + i * 0.08, i * 60, i * 60 + 230, (220, 230, 255), 0.025)
    blade(d, 0.5, 0.5, 0.8, 0.4, 0.025, (230, 235, 245))

def g_fireball(d):
    meteor(d, 0.56, 0.44, 0.13)

def g_heal(d):
    circle(d, 0.5, 0.5, 0.28, (120, 255, 160, 110))
    plus(d, 0.5, 0.5, 1.2, (170, 255, 190))

SKILLS = {
    "sword": [g_sword0, g_sword1, g_sword2], "mage": [g_mage0, g_mage1, g_mage2], "archer": [g_archer0, g_archer1, g_archer2],
    "rogue": [g_rogue0, g_rogue1, g_rogue2], "ninja": [g_ninja0, g_ninja1, g_ninja2], "sniper": [g_sniper0, g_sniper1, g_sniper2],
    "paladin": [g_paladin0, g_paladin1, g_paladin2], "cleric": [g_cleric0, g_cleric1, g_cleric2], "necro": [g_necro0, g_necro1, g_necro2],
    "monk": [g_monk0, g_monk1, g_monk2], "dragoon": [g_dragoon0, g_dragoon1, g_dragoon2], "summoner": [g_summoner0, g_summoner1, g_summoner2],
}
BASIC = {"whirl": (g_whirl, "sword"), "fireball": (g_fireball, "mage"), "heal": (g_heal, "cleric")}

def render(fn, col):
    im = badge(col)
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    fn(ImageDraw.Draw(layer))
    a = layer.split()[3]
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    shadow.putalpha(a.filter(ImageFilter.GaussianBlur(8)).point(lambda v: min(255, int(v * 1.4))))
    glow = Image.new("RGBA", (S, S), mix(col, (255, 255, 255), 0.4) + (0,))
    glow.putalpha(a.filter(ImageFilter.GaussianBlur(18)).point(lambda v: int(v * 0.8)))
    im.alpha_composite(glow)
    im.alpha_composite(shadow, (5, 7))
    im.alpha_composite(layer)
    return im.resize((OUT, OUT), Image.LANCZOS)

def main():
    os.makedirs(DEST, exist_ok=True)
    n = 0
    for k, fns in SKILLS.items():
        for i, fn in enumerate(fns):
            render(fn, CLS_COL[k]).save(os.path.join(DEST, "sk_%s_%d.png" % (k, i)))
            n += 1
    for k, (fn, c) in BASIC.items():
        render(fn, CLS_COL[c]).save(os.path.join(DEST, "sk_%s.png" % k))
        n += 1
    sheet = Image.new("RGBA", (OUT * 6, OUT * 7), (20, 22, 30, 255))
    files = sorted(f for f in os.listdir(DEST) if f.startswith("sk_") and f.endswith(".png"))
    for j, f in enumerate(files):
        sheet.paste(Image.open(os.path.join(DEST, f)), ((j % 6) * OUT, (j // 6) * OUT))
    if len(sys.argv) > 1:
        sheet.save(sys.argv[1])
    print("icons:", n)

if __name__ == "__main__":
    main()

"""สร้างโมเดลสไลม์ Eldoria (.glb) + ภาพตัวอย่าง (.png) ด้วย numpy ล้วน
รัน: python3 make_slime.py <โฟลเดอร์ปลายทาง>
"""
import sys, json, struct, math
import numpy as np
from PIL import Image, ImageFilter

OUT = sys.argv[1] if len(sys.argv) > 1 else "."

# ---------------- รูปทรง ----------------
def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)

def body_mesh(nu=64, nv=40):
    """ทรงหยดน้ำ ฐานแบนกว้าง ยอดแหลมเล็กโค้งไปด้านหลัง สูงราว 1 หน่วย"""
    verts, cols = [], []
    for j in range(nv + 1):
        v = j / nv * math.pi  # 0=ก้น 1=ยอด
        for i in range(nu + 1):
            u = i / nu * 2 * math.pi
            s = math.sin(v)
            r = s ** 0.6
            h = (1 - math.cos(v)) / 2  # 0..1
            # ก้นยุบแบน + ท้องย้วยออกด้านข้าง
            y = h ** 1.0
            if h < 0.5:
                y = 0.5 - (0.5 - h) * 0.55
                y = max(y, 0.0)
            sag = 1 + 0.12 * (1 - h) ** 2
            r *= sag
            # ยอดแหลมเล็ก (จุกครีม)
            tip = smooth(0.86, 1.0, h)
            r *= 1 - 0.5 * tip
            y += 0.16 * tip ** 1.6
            # จุกโค้งไปด้านหลัง
            zoff = -0.10 * tip ** 2
            x = r * math.cos(u) * 0.62
            z = r * math.sin(u) * 0.58 + zoff
            verts.append((x, y * 1.12, z))
    verts = np.array(verts, np.float32)
    # ทำให้ก้นแบน: จุดล่างสุดอยู่ที่ y=0
    verts[:, 1] -= verts[:, 1].min()
    idx = []
    for j in range(nv):
        for i in range(nu):
            a = j * (nu + 1) + i
            b = a + nu + 1
            idx += [a, a + 1, b, a + 1, b + 1, b]
    return verts, np.array(idx, np.uint32)

def ellipsoid(center, rad, nu=20, nv=12):
    vs = []
    for j in range(nv + 1):
        v = j / nv * math.pi
        for i in range(nu + 1):
            u = i / nu * 2 * math.pi
            vs.append((math.sin(v) * math.cos(u), -math.cos(v), math.sin(v) * math.sin(u)))
    vs = np.array(vs, np.float32) * np.array(rad, np.float32) + np.array(center, np.float32)
    idx = []
    for j in range(nv):
        for i in range(nu):
            a = j * (nu + 1) + i
            b = a + nu + 1
            idx += [a, b, a + 1, a + 1, b, b + 1]
    return vs, np.array(idx, np.uint32)

def normals(v, f):
    n = np.zeros_like(v)
    t = f.reshape(-1, 3)
    fn = np.cross(v[t[:, 1]] - v[t[:, 0]], v[t[:, 2]] - v[t[:, 0]])
    for k in range(3):
        np.add.at(n, t[:, k], fn)
    # รวม normal ของจุดซ้ำตรงรอยต่อ ให้ผิวเนียนไม่มีเส้น
    key = np.round(v, 4)
    _, inv = np.unique(key, axis=0, return_inverse=True)
    acc = np.zeros((inv.max() + 1, 3), np.float32)
    np.add.at(acc, inv, n)
    n = acc[inv]
    return n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-8)

def surface_point(v, x, ytarget):
    """หา z หน้าสุดของตัวที่ความสูง/ตำแหน่ง x ที่กำหนด เพื่อแปะหน้าให้ติดผิว"""
    sel = v[(np.abs(v[:, 0] - x) < 0.04) & (np.abs(v[:, 1] - ytarget) < 0.04)]
    return float(sel[:, 2].max())

# ---------------- ประกอบชิ้นส่วน ----------------
bv, bf = body_mesh()
bn = normals(bv, bf)
H = bv[:, 1].max()
hy = bv[:, 1] / H
TOP = np.array([0.42, 0.78, 1.0]); DEEP = np.array([0.08, 0.30, 0.85])
bc = DEEP + (TOP - DEEP) * np.clip(hy * 1.3 - 0.05, 0, 1)[:, None]

parts = [("body", bv, bf, bn, bc)]
ey = 0.47 * H
for sx in (-1, 1):
    ex = sx * 0.15
    ez = surface_point(bv, ex, ey) - 0.035
    v, f = ellipsoid((ex, ey, ez), (0.085, 0.125, 0.05))
    parts.append(("eye", v, f, normals(v, f), np.tile([0.03, 0.05, 0.14], (len(v), 1))))
    v, f = ellipsoid((ex + sx * 0.0 + 0.022, ey + 0.045, ez + 0.042), (0.026, 0.03, 0.012))
    parts.append(("shine", v, f, normals(v, f), np.tile([1, 1, 1], (len(v), 1))))
    v, f = ellipsoid((ex - 0.018, ey - 0.04, ez + 0.044), (0.012, 0.012, 0.008), 10, 6)
    parts.append(("shine", v, f, normals(v, f), np.tile([1, 1, 1], (len(v), 1))))
    cx = sx * 0.30
    cz = surface_point(bv, cx, ey - 0.12) - 0.02
    v, f = ellipsoid((cx, ey - 0.12, cz), (0.06, 0.03, 0.025), 14, 8)
    parts.append(("blush", v, f, normals(v, f), np.tile([1.0, 0.55, 0.75], (len(v), 1))))
# ปากยิ้มเล็ก ๆ: ทรงรีแบนสีเข้ม
mz = surface_point(bv, 0.0, ey - 0.13) - 0.012
v, f = ellipsoid((0, ey - 0.13, mz), (0.045, 0.022, 0.015), 14, 8)
parts.append(("mouth", v, f, normals(v, f), np.tile([0.05, 0.08, 0.22], (len(v), 1))))

# ---------------- เรนเดอร์ตัวอย่าง (rasterizer ซอฟต์แวร์) ----------------
def render(parts, W=900, Hh=900, yaw=-0.45, pitch=0.28, ss=2):
    W2, H2 = W * ss, Hh * ss
    col = np.zeros((H2, W2, 3), np.float32)
    # พื้นหลังไล่สีทุ่งหญ้ายามเช้า
    yy = np.linspace(0, 1, H2)[:, None, None]
    col[:] = (np.array([0.80, 0.90, 0.98]) * (1 - yy) + np.array([0.55, 0.75, 0.48]) * yy)
    zb = np.full((H2, W2), np.inf, np.float32)
    cy, sy_ = math.cos(yaw), math.sin(yaw)
    cp, sp = math.cos(pitch), math.sin(pitch)
    R = np.array([[cy, 0, sy_], [0, 1, 0], [-sy_, 0, cy]]) @ np.eye(3)
    Rp = np.array([[1, 0, 0], [0, cp, -sp], [0, sp, cp]])
    M = Rp @ R
    scale = W2 * 0.62
    ox, oy = W2 / 2, H2 * 0.70
    L = np.array([-0.5, 0.8, 0.6]); L /= np.linalg.norm(L)
    V = np.array([0, 0, 1.0])
    Hv = (L + V); Hv /= np.linalg.norm(Hv)
    # เงาบนพื้น
    gy, gx = np.mgrid[0:H2, 0:W2]
    shc = (ox, oy + scale * 0.02)
    d = ((gx - shc[0]) / (scale * 0.5)) ** 2 + ((gy - shc[1]) / (scale * 0.12)) ** 2
    col *= (1 - 0.35 * np.exp(-d * 2.2))[..., None]
    for name, v, f, n, c in parts:
        pv = (v - np.array([0, H / 2, 0])) @ M.T + np.array([0, H / 2, 0])
        pn = n @ M.T
        sx = ox + pv[:, 0] * scale
        syv = oy - pv[:, 1] * scale
        depth = -pv[:, 2]
        for t in f.reshape(-1, 3):
            xs, ys = sx[t], syv[t]
            x0, x1 = int(max(xs.min(), 0)), int(min(xs.max() + 1, W2))
            y0, y1 = int(max(ys.min(), 0)), int(min(ys.max() + 1, H2))
            if x1 <= x0 or y1 <= y0:
                continue
            den = (ys[1] - ys[2]) * (xs[0] - xs[2]) + (xs[2] - xs[1]) * (ys[0] - ys[2])
            if abs(den) < 1e-9:
                continue
            px, py = np.meshgrid(np.arange(x0, x1) + 0.5, np.arange(y0, y1) + 0.5)
            w0 = ((ys[1] - ys[2]) * (px - xs[2]) + (xs[2] - xs[1]) * (py - ys[2])) / den
            w1 = ((ys[2] - ys[0]) * (px - xs[2]) + (xs[0] - xs[2]) * (py - ys[2])) / den
            w2 = 1 - w0 - w1
            m = (w0 >= -1e-4) & (w1 >= -1e-4) & (w2 >= -1e-4)
            if not m.any():
                continue
            z = w0 * depth[t[0]] + w1 * depth[t[1]] + w2 * depth[t[2]]
            zsub = zb[y0:y1, x0:x1]
            m &= z < zsub
            if not m.any():
                continue
            nn = (w0[..., None] * pn[t[0]] + w1[..., None] * pn[t[1]] + w2[..., None] * pn[t[2]])
            nn /= np.linalg.norm(nn, axis=-1, keepdims=True) + 1e-8
            cc = w0[..., None] * c[t[0]] + w1[..., None] * c[t[1]] + w2[..., None] * c[t[2]]
            ndl = np.clip(nn @ L, 0, 1)
            ndv = np.clip(nn @ V, 0, 1)
            fres = (1 - ndv) ** 2.2
            if name in ("shine", "gloss"):
                out = cc * (0.85 + 0.15 * ndl[..., None])
            elif name == "body":
                spec = np.clip(nn @ Hv, 0, 1) ** 120 * 1.6 + np.clip(nn @ Hv, 0, 1) ** 12 * 0.18
                wrap = np.clip((nn @ L + 0.5) / 1.5, 0, 1)  # แสงทะลุแบบเยลลี่
                out = cc * (0.3 + 0.6 * wrap[..., None]) + cc * fres[..., None] * 0.7 + spec[..., None]
            else:
                spec = np.clip(nn @ Hv, 0, 1) ** 60 * 0.6
                out = cc * (0.4 + 0.6 * ndl[..., None]) + spec[..., None]
            zsub[m] = z[m]
            col[y0:y1, x0:x1][m] = out[m]
    img = Image.fromarray((np.clip(col, 0, 1) ** (1 / 1.1) * 255).astype(np.uint8))
    return img.resize((W, Hh), Image.LANCZOS)

# ---------------- ส่งออก glTF (.glb) ----------------
def write_glb(path, parts):
    """แยกเป็น mesh ตามกลุ่มวัสดุ: body / face ( ตา ปาก แก้ม ไฮไลต์ ) ใช้สีจุดยอด"""
    groups = {"SlimeBody": ["body"], "SlimeFace": ["eye", "mouth", "blush"], "SlimeShine": ["shine", "gloss"]}
    bin_ = bytearray(); views = []; accs = []; meshes = []; nodes = []
    def add(arr, target, comp, typ, mm=False):
        while len(bin_) % 4: bin_.append(0)
        off = len(bin_); b = arr.tobytes(); bin_.extend(b)
        views.append({"buffer": 0, "byteOffset": off, "byteLength": len(b), "target": target})
        a = {"bufferView": len(views) - 1, "componentType": comp, "count": len(arr), "type": typ}
        if mm: a["min"] = arr.min(0).tolist(); a["max"] = arr.max(0).tolist()
        accs.append(a); return len(accs) - 1
    mats = [
        {"name": "SlimeBody", "pbrMetallicRoughness": {"baseColorFactor": [1, 1, 1, 0.85], "metallicFactor": 0, "roughnessFactor": 0.12}, "alphaMode": "BLEND"},
        {"name": "SlimeFace", "pbrMetallicRoughness": {"baseColorFactor": [1, 1, 1, 1], "metallicFactor": 0, "roughnessFactor": 0.25}},
        {"name": "SlimeShine", "pbrMetallicRoughness": {"baseColorFactor": [1, 1, 1, 1], "metallicFactor": 0, "roughnessFactor": 1}, "extensions": {"KHR_materials_unlit": {}}},
    ]
    for mi, (gname, names) in enumerate(groups.items()):
        V, N, C, I = [], [], [], []; base = 0
        for name, v, f, n, c in parts:
            if name in names:
                V.append(v); N.append(n); C.append(np.c_[c, np.ones(len(c))]); I.append(f + base); base += len(v)
        V = np.concatenate(V).astype(np.float32); N = np.concatenate(N).astype(np.float32)
        C = np.concatenate(C).astype(np.float32); I = np.concatenate(I).astype(np.uint32)
        pa = add(V, 34962, 5126, "VEC3", True); na = add(N, 34962, 5126, "VEC3")
        ca = add(C, 34962, 5126, "VEC4"); ia = add(I, 34963, 5125, "SCALAR")
        meshes.append({"name": gname, "primitives": [{"attributes": {"POSITION": pa, "NORMAL": na, "COLOR_0": ca}, "indices": ia, "material": mi}]})
        nodes.append({"name": gname, "mesh": mi})
    nodes.append({"name": "Slime", "children": list(range(len(meshes)))})
    gl = {"asset": {"version": "2.0", "generator": "Eldoria slime tool"}, "extensionsUsed": ["KHR_materials_unlit"],
          "scene": 0, "scenes": [{"nodes": [len(nodes) - 1]}], "nodes": nodes, "meshes": meshes, "materials": mats,
          "accessors": accs, "bufferViews": views, "buffers": [{"byteLength": len(bin_)}]}
    js = json.dumps(gl, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    while len(bin_) % 4: bin_.append(0)
    with open(path, "wb") as fh:
        fh.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(bin_)))
        fh.write(struct.pack("<II", len(js), 0x4E4F534A)); fh.write(js)
        fh.write(struct.pack("<II", len(bin_), 0x004E4942)); fh.write(bin_)

write_glb(f"{OUT}/slime.glb", parts)
a = render(parts, yaw=-0.5)
b = render(parts, yaw=0.9)
sheet = Image.new("RGB", (1800, 900)); sheet.paste(a, (0, 0)); sheet.paste(b, (900, 0))
sheet.save(f"{OUT}/slime_preview.png")
print("tris:", sum(len(p[2]) // 3 for p in parts))

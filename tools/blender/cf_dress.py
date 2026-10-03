"""Court figures: hair, beards and the clothes of each age.

Everything here is a solid described by signed distance (cf_sdf) and meshed
as a thick shell, so hems, cuffs and edges have a carved, rounded thickness.
Each piece is a Piece: a mesh name, a material slot and two functions:
  solid(P)  the space the piece encloses (used to hide the skin it covers),
  shell(P)  the piece itself.
Outfits (one per age of dress; Godot shows one set at a time):
  hide   hide wrap over one shoulder, fur cape, cord belt, foot wraps
  tunic  woven tunic with short sleeves, belt, banded hems, shoes
  robe   long robe with wide sleeves, sash, banded hems, mantle, shoes
Hair: cropped, long, bun, braids, tail, curls, topknot; beards: short, full, long.
"""
import math
import numpy as np
import bpy
from mathutils import Vector, Quaternion

import cf_sdf as S
from cf_body import torso_profile, build_head, FACE, set_material, surface_hit


def _v(a):
    return np.asarray(tuple(a), dtype=np.float32)


def sm(x):
    x = np.clip(x, 0.0, 1.0)
    return x * x * (3.0 - 2.0 * x)


class Piece:
    def __init__(self, name, slot, solid, shell, lo, hi, voxel=0.003, cover=True, outer=None, keep=None):
        self.name, self.slot = name, slot
        self.outer, self.keep = outer, keep
        self.sleeve = None   # distance to the sleeves alone (for binding)
        self.trunk = None    # distance to the body of the garment alone
        self.solid, self.shell = solid, shell
        self.lo, self.hi, self.voxel = _v(lo), _v(hi), voxel
        self.cover = cover

    def build(self):
        obj = S.mesh_fn(self.name, self.shell, self.lo, self.hi, self.voxel)
        if obj is None:
            return None
        set_material(obj, self.slot)
        return obj


def shell_fn(outer, keep, t, k=0.0025, lift=0.0):
    """A shell t thick inside the outer surface, trimmed where keep(P) > 0."""
    def fn(P):
        o = outer(P) - lift
        sh = np.maximum(o, -(o + t))
        return S.smax(sh, keep(P), k) if keep is not None else sh
    return fn


def solid_fn(outer, keep, k=0.0025):
    def fn(P):
        o = outer(P)
        return S.smax(o, keep(P), k) if keep is not None else o
    return fn


def keep_all(*gs):
    def fn(P):
        out = None
        for g in gs:
            v = g(P)
            out = v if out is None else np.maximum(out, v)
        return out
    return fn


def remove(region):
    """Keep everything outside a region (a distance function)."""
    return lambda P: -region(P)


def above(zfun):
    """Keep where z is above zfun(theta, P)."""
    return lambda P: zfun(P) - P[..., 2]


def below(zfun):
    return lambda P: P[..., 2] - zfun(P)


def theta(P, cy=0.0):
    """Angle about the figure's vertical axis: 0 at its front, +-pi at its back."""
    return np.arctan2(P[..., 0], -(P[..., 1] - cy))


def sleeved(trunk, sleeves, z_join, k=0.018):
    """Sleeves melt into the garment at the shoulders only, never into a skirt below."""
    def fn(P):
        kz = np.where(P[..., 2] > z_join, k, 0.002).astype(np.float32)
        return S.smin(trunk(P), sleeves(P), kz)
    return fn


def union_fn(*fns, k=0.0):
    def fn(P):
        d = None
        for g in fns:
            v = g(P)
            d = v if d is None else S.smin(d, v, k)
        return d
    return fn


def prim(p):
    return p.eval


# --- the body's sections ----------------------------------------------------------------

def profile_at(f, z):
    keys = torso_profile(f)
    zs = [q[0] for q in keys]
    z = min(max(z, zs[0]), zs[-1])
    for i in range(len(zs) - 1):
        if z <= zs[i + 1]:
            t = (z - zs[i]) / max(zs[i + 1] - zs[i], 1e-6)
            t = t * t * (3 - 2 * t)
            return tuple(keys[i][j] * (1 - t) + keys[i + 1][j] * t for j in range(1, 5))
    return tuple(keys[-1][1:])


def eased(f, z, w=0.0, fr=0.0, bk=0.0, wmin=None):
    bw, bf, bb, cy = profile_at(f, z)
    if wmin is not None:
        bw = max(bw, wmin)
    return (z, bw + w, bf + fr, bb + bk, cy)


def hip_w(f):
    """Half width a skirt needs at the hips to hold both thighs."""
    p = f.p
    return max(p["pelvis"], p["hip_joint"] + p["thigh"] * 1.18) + 0.020


def loft(sections, folds=(), seed=0.0, cap=0.02):
    sections = sorted(sections, key=lambda q: q[0])
    return S.FoldLoft([q[0] for q in sections], [q[1] for q in sections], [q[2] for q in sections],
                      [q[3] for q in sections], [q[4] for q in sections], cap_round=cap, folds=folds, seed=seed)


def box_of(f, z0, z1, x=0.5, y0=-0.32, y1=0.34):
    return (-x, y0, z0), (x, y1, z1)


# =====================================================================================
# Hair

HAIRLINE = ((0, 0.34), (30, 0.28), (55, 0.06), (80, -0.14), (98, -0.24), (112, -0.50), (140, -0.72), (180, -0.80))


class Head:
    def __init__(self, f):
        self.f = f
        s = f.head_h / 0.282
        self.s = s
        self.c = _v(f.head_point(0, 0.014 * s, 0.640))
        self.r = _v((0.087 * s, 0.097 * s, 0.100 * s))
        self.recipe = S.Recipe()
        build_head(self.recipe, f)

    def sdf(self, P):
        return self.recipe.eval(P)

    def coords(self, P):
        th = np.degrees(np.abs(np.arctan2(P[..., 0] - self.c[0], -(P[..., 1] - self.c[1]))))
        Z = (P[..., 2] - self.c[2]) / self.r[2]
        return th, Z

    def hairline(self, th):
        a = np.asarray([q[0] for q in HAIRLINE], dtype=np.float32)
        b = np.asarray([q[1] for q in HAIRLINE], dtype=np.float32)
        return np.interp(th, a, b)

    def point(self, th_deg, Z, out=0.0):
        """A point on the cranium at an angle (0 front) and height, pushed out."""
        th = math.radians(th_deg)
        rxy = math.sqrt(max(1.0 - Z * Z, 0.0))
        return Vector((float(self.c[0]) + (float(self.r[0]) + out) * rxy * math.sin(th),
                       float(self.c[1]) - (float(self.r[1]) + out) * rxy * math.cos(th),
                       float(self.c[2]) + Z * float(self.r[2])))

    def box(self, below=0.10, wide=0.06):
        s = self.s
        c = self.c
        return (c[0] - 0.14 * s - wide, c[1] - 0.15 * s, c[2] - 0.40 * s - below), (c[0] + 0.14 * s + wide, c[1] + 0.15 * s + wide, c[2] + 0.14 * s)


def hair_cap(head, t, grooves=44, depth=0.0016, part=False, edge=0.30, lift_back=0.0, puff=0.0, temples=0.0, ragged=0.0):
    """Hair lying on the scalp inside the hairline.
    part: strands fall to each side of a parting (else they are combed back);
    puff: extra volume over the ears and at the back, so it stands off the skull;
    temples: how far the hair comes down over the temples (softens the line)."""
    s = head.s

    def fn(P):
        h = head.sdf(P)
        th, Z = head.coords(P)
        H = head.hairline(th) - temples * np.exp(-((th - 42.0) / 22.0) ** 2)
        if ragged:
            # a hairline that is not drawn with a rule: little points and gaps
            H = H + ragged * (np.sin(np.radians(th) * 23.0) * 0.6 + np.sin(np.radians(th) * 41.0 + 1.3) * 0.4)
        above_line = Z - H
        side = sm((th - 35.0) / 70.0)
        thick = t * (0.30 + 0.70 * sm(above_line / edge)) * (1.0 + puff * side * sm((0.55 - Z) / 0.6))
        thick = thick + lift_back * sm((th - 100.0) / 60.0)
        if part:
            # strands run down from the parting: grooves are spaced front to back
            # on the top and sides, and side to side at the back of the head
            ry = (P[..., 1] - head.c[1]) / head.r[1]
            rx = (P[..., 0] - head.c[0]) / head.r[0]
            back = sm((th - 115.0) / 40.0)
            g_side = 0.5 - 0.5 * np.cos(ry * grooves * 0.55 + 0.6 * np.sin(rx * 5.0))
            g_back = 0.5 - 0.5 * np.cos(rx * grooves * 0.45)
            g = g_side * (1.0 - back) + g_back * back
        else:
            g = 0.5 - 0.5 * np.cos(np.radians(th) * grooves * 0.5)
        thick = thick - depth * s * g * sm((Z + 0.2) / 0.6)
        d = np.maximum(h - thick, -(h + 0.004 * s))
        d = S.smax(d, (H - Z) * head.r[2], 0.004 * s)
        if part:
            groove = 0.0020 * s - np.abs(P[..., 0] - head.c[0])
            groove = np.where((P[..., 1] < head.c[1] + 0.02 * s) & (Z > 0.15), groove, -1.0)
            d = S.smax(d, groove, 0.0015 * s)
        return d
    return fn


def lock(a, b, c, ra, rb, rc):
    return union_fn(prim(S.RoundCone(a, b, ra, rb)), prim(S.RoundCone(b, c, rb, rc)), k=0.004)


def hair_style(f, style):
    """A hair Piece for a style, or None for 'bald'."""
    head = Head(f)
    s = head.s
    lo, hi = head.box()
    k_lock = 0.0045 * s
    if style == "bald":
        return None
    if style == "cropped":
        shell = hair_cap(head, 0.0048 * s, grooves=60, depth=0.0012, edge=0.45, ragged=0.05, puff=0.15)
    elif style == "shaved":
        shell = hair_cap(head, 0.0019 * s, grooves=0, depth=0.0, edge=0.10, ragged=0.03)
        return Piece("hair_shaved", "STUBBLE", shell, shell, lo, hi, voxel=0.0010 * s, cover=False)
    elif style in ("long", "long_framed"):
        cap = hair_cap(head, 0.010 * s, grooves=34, depth=0.0030, part=True, puff=0.9, temples=0.16 if style == "long_framed" else 0.08, edge=0.42, ragged=0.03)
        parts = [cap]
        z_end = f.z_shoulder + 0.030 * s
        count = 17
        for i in range(count):
            th = 74.0 + i * (212.0 / (count - 1))
            back = max(0.0, -math.cos(math.radians(th)))
            wob = math.sin(i * 2.3) * 0.5 + 0.5
            a = head.point(th, 0.42, 0.004 * s)
            m = head.point(th, -0.50, 0.026 * s + 0.012 * s * back)
            e = head.point(th, -0.9, 0.050 * s)
            e.z = z_end - 0.10 * s * back * back - 0.035 * s * wob
            outward = (Vector((e.x - float(head.c[0]), e.y - float(head.c[1]), 0.0))).normalized()
            e += outward * (0.022 * s + 0.012 * s * back)
            r0 = (0.017 + 0.006 * wob) * s
            parts.append(lock(a, m, e, r0, r0 * 0.95, 0.0045 * s))
        if style == "long_framed":
            for sd in (1, -1):
                for j, th in enumerate((58.0, 68.0)):
                    a = head.point(th, 0.34 - 0.06 * j, 0.006 * s)
                    m = head.point(th, -0.30, 0.020 * s)
                    a = Vector((sd * abs(a.x), a.y, a.z))
                    m = Vector((sd * abs(m.x), m.y, m.z))
                    e = Vector((sd * (abs(m.x) + 0.014 * s), m.y + 0.012 * s, f.z_chin - (0.020 + 0.030 * j) * s))
                    parts.append(lock(a, m, e, 0.015 * s, 0.014 * s, 0.0040 * s))
        shell = union_fn(*parts, k=k_lock)
        lo = (lo[0] - 0.04, lo[1], f.z_shoulder - 0.10)
        hi = (hi[0] + 0.04, hi[1] + 0.06, hi[2])
    elif style == "bun":
        cap = hair_cap(head, 0.010 * s, grooves=60, depth=0.0018)
        bun_c = head.point(180.0, 0.05, 0.030 * s)
        bun = prim(S.Ellipsoid(bun_c, (0.040 * s, 0.034 * s, 0.036 * s)))
        band = prim(S.Ellipsoid(head.point(180.0, 0.08, 0.008 * s), (0.026 * s, 0.020 * s, 0.024 * s)))
        shell = union_fn(cap, bun, band, k=0.008 * s)
        hi = (hi[0], hi[1] + 0.06, hi[2])
    elif style == "topknot":
        cap = hair_cap(head, 0.007 * s, grooves=60, depth=0.0016)
        knot = prim(S.Sphere(head.point(0.0, 0.93, 0.024 * s), 0.026 * s))
        tie = prim(S.Ellipsoid(head.point(0.0, 0.97, 0.004 * s), (0.018 * s, 0.018 * s, 0.010 * s)))
        shell = union_fn(cap, knot, tie, k=0.006 * s)
        hi = (hi[0], hi[1], hi[2] + 0.06)
    elif style == "tail":
        cap = hair_cap(head, 0.010 * s, grooves=60, depth=0.0018)
        a = head.point(180.0, -0.40, 0.012 * s)
        b = Vector((0.0, f.neck.y + 0.085 * s, f.z_shoulder + 0.010))
        bw, bf, bb, cy = profile_at(f, f.z_chest)
        c = Vector((0.0, cy + bb + 0.026 * s, f.z_chest - 0.020))
        tail = lock(a, b, c, 0.024 * s, 0.020 * s, 0.010 * s)
        tie = prim(S.Sphere(a + Vector((0, 0.012 * s, -0.012 * s)), 0.017 * s))
        shell = union_fn(cap, tail, tie, k=0.008 * s)
        lo = (lo[0], lo[1], f.z_chest - 0.08)
        hi = (hi[0], hi[1] + 0.10, hi[2])
    elif style == "braids":
        cap = hair_cap(head, 0.010 * s, grooves=34, depth=0.0026, part=True, puff=0.3, temples=0.06)
        parts = [cap]
        for sd in (1.0, -1.0):
            p0 = head.point(112.0, -0.45, 0.010 * s)
            p0 = Vector((sd * abs(p0.x), p0.y, p0.z))
            p1 = Vector((sd * 0.112, f.neck.y + 0.004, f.z_shoulder + 0.058))
            zm = f.z_shoulder - 0.050
            bw, bf, bb, cy = profile_at(f, zm)
            xm = sd * min(0.122, bw * 0.80)
            pm = Vector((xm, cy - bf * math.sqrt(max(0.0, 1 - (xm / bw) ** 2)) - 0.026, zm))
            zc = f.z_chest + 0.020
            bw, bf, bb, cy = profile_at(f, zc)
            x2 = sd * min(0.118, bw * 0.78)
            y2 = cy - bf * math.sqrt(max(0.0, 1 - (x2 / bw) ** 2)) - 0.024 * s
            p2 = Vector((x2, y2, zc))
            pts = []
            for seg in ((p0, p1), (p1, pm), (pm, p2)):
                n = max(2, int((seg[1] - seg[0]).length / (0.017 * s)))
                for j in range(n):
                    pts.append(seg[0].lerp(seg[1], j / n))
            pts.append(p2)
            for j, p in enumerate(pts):
                if j + 1 < len(pts):
                    d = (pts[j + 1] - p).normalized()
                else:
                    d = (p - pts[j - 1]).normalized()
                side = d.cross(Vector((0, 1, 0))).normalized()
                off = side * (0.0055 * s * (1 if j % 2 else -1))
                r = 0.0145 * s * (1.0 - 0.25 * j / len(pts))
                parts.append(prim(S.Ellipsoid(p + off, (r * 1.15, r * 0.95, r * 0.85), rot=Vector((0, 0, 1)).rotation_difference(d))))
            parts.append(prim(S.Sphere(p2 + Vector((0, 0, -0.010 * s)), 0.010 * s)))
            parts.append(prim(S.RoundCone(p2 + Vector((0, 0, -0.016 * s)), p2 + Vector((0, -0.004, -0.050 * s)), 0.009 * s, 0.003 * s)))
        shell = union_fn(*parts, k=0.004 * s)
        lo = (lo[0] - 0.08, lo[1] - 0.06, f.z_chest - 0.06)
        hi = (hi[0] + 0.08, hi[1], hi[2])
    elif style == "curls":
        t = 0.016 * s
        cap = hair_cap(head, t, grooves=0, depth=0.0, edge=0.2)
        parts = [cap]
        n = 260
        golden = math.pi * (3 - math.sqrt(5))
        for i in range(n):
            Z = 1 - 2 * (i + 0.5) / n
            th = (i * golden) % (2 * math.pi)
            th_deg = abs(math.degrees(math.atan2(math.sin(th), math.cos(th))))
            H = float(np.interp(th_deg, [q[0] for q in HAIRLINE], [q[1] for q in HAIRLINE]))
            if Z < H + 0.10:
                continue
            p = head.point(math.degrees(th), Z, t * 0.85)
            parts.append(prim(S.Sphere(p, 0.0125 * s * (0.85 + 0.3 * ((i * 7919) % 13) / 13.0))))
        shell = union_fn(*parts, k=0.004 * s)
        lo = (lo[0] - 0.02, lo[1] - 0.02, lo[2])
        hi = (hi[0] + 0.02, hi[1] + 0.02, hi[2] + 0.02)
    else:
        raise ValueError(style)
    return Piece("hair_" + style, "HAIR", shell, shell, lo, hi, voxel=0.0022 * s, cover=False)


def beard_style(f, style):
    """Beards that follow the jaw with clean edges, each its own shape:
    stubble (a shadow on the skin), short (trimmed close), chin (around the
    mouth and on the chin), moustache, full (thick but trimmed), long (an
    elder's beard, braided below the chin)."""
    head = Head(f)
    s = head.s
    mouth_u = FACE["mouth_u"]
    mc = getattr(f, "mouth_center", None)
    my = float(mc.y) if mc is not None else float(head.c[1]) - 0.10 * s
    t = {"beard_stubble": 0.0011, "beard_short": 0.0042, "beard_chin": 0.0055, "beard_full": 0.0085,
         "beard_long": 0.0065, "beard_moustache": 0.0}[style] * s

    def u_of(P):
        return (P[..., 2] - f.z_chin) / f.head_h

    def region(P):
        th, Z = head.coords(P)
        u = u_of(P)
        if style == "beard_chin":
            # around the mouth and down the chin only
            top = np.interp(th, [0, 18, 30, 40], [0.16, 0.24, 0.24, -0.5])
            lowest = -0.06
        else:
            top = np.interp(th, [0, 22, 55, 92, 110], [0.120, 0.215, 0.30, 0.40, 0.34]) if style in ("beard_short", "beard_stubble")                 else np.interp(th, [0, 22, 55, 92, 110], [0.135, 0.235, 0.36, 0.44, 0.38])
            lowest = {"beard_full": -0.12, "beard_long": -0.07}.get(style, -0.035)
        g = np.maximum(u - top, lowest - u) * f.head_h
        return np.maximum(g, (th - 104.0) * 0.001)

    def mouth_hole(P):
        return S.Ellipsoid((0.0, my, f.face(mouth_u)), (0.024 * s, 0.024 * s, 0.011 * s)).eval(P)

    hang = S.Ellipsoid(Vector((0, my + 0.028 * s, f.z_chin - 0.004 * s)), (0.040 * s, 0.034 * s, 0.034 * s)) if style == "beard_full" else None
    braid = []
    if style == "beard_long":
        top = Vector((0.0, my + 0.020 * s, f.z_chin - 0.016 * s))
        bottom = Vector((0.0, my + 0.004 * s, f.z_chin - 0.20 * s))
        n = 9
        for i in range(n):
            q = top.lerp(bottom, i / (n - 1))
            r = (0.019 - 0.010 * i / (n - 1)) * s
            side = (1 if i % 2 else -1) * 0.004 * s
            braid.append(S.Ellipsoid(q + Vector((side, 0, 0)), (r * 1.1, r * 0.85, r * 0.95)))
        braid.append(S.Sphere(bottom + Vector((0, 0, -0.010 * s)), 0.007 * s))

    def moustache(P, thick, droop):
        d = None
        for sd in (1.0, -1.0):
            a = Vector((sd * 0.004 * s, my - 0.005 * s, f.face(mouth_u + 0.052)))
            b = Vector((sd * 0.025 * s, my + 0.004 * s, f.face(mouth_u - 0.010 - droop)))
            v = S.RoundCone(a, b, thick * s, 0.0026 * s).eval(P)
            d = v if d is None else np.minimum(d, v)
        return d

    def fn(P):
        if style == "beard_moustache":
            return moustache(P, 0.0062, 0.040)
        h = head.sdf(P)
        d = np.maximum(h - t, -(h + 0.0025 * s))
        d = S.smax(d, region(P), 0.0018 * s)
        if hang is not None:
            hv = np.maximum(hang.eval(P), P[..., 2] - (f.z_chin + 0.015 * s))
            d = S.smin(d, hv, 0.008 * s)
        for part in braid:
            d = S.smin(d, part.eval(P), 0.003 * s)
        d = S.smax(d, -mouth_hole(P), 0.002 * s)
        if style != "beard_stubble":
            d = S.smin(d, moustache(P, 0.0040 if style == "beard_short" else 0.0052, 0.0), 0.003 * s)
        return d

    c = head.c
    lo = (c[0] - 0.13 * s, c[1] - 0.16 * s, f.z_chin - (0.24 if style == "beard_long" else 0.07) * s)
    hi = (c[0] + 0.13 * s, c[1] + 0.10 * s, f.face(0.62))
    slot = "STUBBLE" if style == "beard_stubble" else "HAIR"
    voxel = 0.0012 * s if style == "beard_stubble" else 0.0020 * s
    return Piece(style, slot, fn, fn, lo, hi, voxel=voxel, cover=False)


HAIR_STYLES = ("cropped", "shaved", "long", "long_framed", "bun", "braids", "tail", "curls", "topknot")
BEARD_STYLES = ("beard_stubble", "beard_short", "beard_chin", "beard_moustache", "beard_full", "beard_long")


# =====================================================================================
# Clothes

def _hem(base, amp=0.0, jag=0.0, count=7, tilt=0.0, seed=0.0):
    """A hem height around the figure: level, tilted, or cut in points (hide)."""
    def fn(P):
        th = theta(P)
        z = base + tilt * np.sin(th + seed)
        if amp:
            z = z + amp * np.sin(2 * th + 0.7 + seed)
        if jag:
            tri = np.abs(((count * th / math.pi + seed) % 2.0) - 1.0)
            z = z + jag * (tri - 0.5) + 0.3 * jag * np.sin(3 * count * th + seed)
        return np.full(P.shape[:-1], z) if np.isscalar(z) else z
    return fn


def _sleeve(f, side, length, r0, r1, flare=0.0):
    sh, el = f.shoulder[side], f.elbow[side]
    d = (el - sh).normalized()
    a = sh + d * 0.004
    b = sh + d * length
    return S.RoundCone(a, b + d * 0.02, r0, r1 + flare), sh, d


def _sleeve_cut(sh, d, length, R):
    """Removed: beyond `length` along the arm, within R of its axis."""
    shv, dv = _v(sh), _v(d)

    def fn(P):
        Q = P - shv
        along = Q @ dv
        radial = np.linalg.norm(Q - along[..., None] * dv, axis=-1)
        return np.maximum(length - along, radial - R)
    return fn


def _neck_hole(f, rx, ry, rz, drop=0.0, front=0.0):
    c = Vector((0.0, f.neck.y - 0.012 - front, f.z_shoulder + 0.034 - drop))
    return S.Ellipsoid(c, (rx, ry, rz)).eval


def _band_near(dist_fn, width):
    """Keep only within `width` of a surface (dist_fn positive away from it)."""
    return lambda P: np.abs(dist_fn(P)) - width


def _trimmed(outer, keep, band_keep, t, lift=0.0020):
    def fn(P):
        o = outer(P) - lift
        sh = np.maximum(o, -(o + t + 0.002))
        return S.smax(S.smax(sh, keep(P), 0.002), band_keep(P), 0.002)
    return fn


def outfit(f, kind):
    """The pieces of one age's dress for a body. Returns [Piece]."""
    if kind == "hide":
        return _hide(f)
    if kind == "tunic":
        return _tunic(f)
    if kind == "robe":
        return _robe(f)
    raise ValueError(kind)


OUTFITS = ("hide", "tunic", "robe")


def _shoes(f, name, slot, top=0.075, wraps=0):
    k = f.H / 1.72
    parts = []
    for side in ("L", "R"):
        an, ball, toe = f.ankle[side], f.ball[side], f.toe[side]
        heel = Vector((an.x, an.y + 0.026 * k, 0.034 * k))
        e = 0.008
        parts += [prim(S.Sphere(heel, 0.036 * k + e)),
                  prim(S.RoundCone(heel + Vector((0, -0.01, 0.004)), ball + Vector((0, 0, 0.016)), 0.034 * k + e, 0.030 * k + e)),
                  prim(S.Ellipsoid(ball.lerp(toe, 0.35) + Vector((0, 0, 0.012)), (0.044 * k + e, 0.040 * k + e, 0.020 * k + e))),
                  prim(S.RoundCone(an + Vector((0, 0, -0.03)), an + Vector((0, -0.004, top * k + 0.02)), f.p["shin"] * 0.70 + e, f.p["shin"] * 0.74 + e))]
    outer = union_fn(*parts, k=0.012)
    zt = f.z_ankle + top * k

    def keep(P):
        g = P[..., 2] - zt
        if wraps:
            g = g + 0.0  # a spiral of hide bands, cut as shallow grooves
        return np.maximum(g, -P[..., 2])

    def shell(P):
        o = outer(P)
        if wraps:
            th = theta(P)
            o = o + 0.0022 * (0.5 + 0.5 * np.sin(wraps * 2 * math.pi * P[..., 2] / 0.09 + th))
        return S.smax(o, keep(P), 0.004)

    return Piece(name, slot, solid_fn(outer, keep), shell, (-0.25, -0.24, -0.01), (0.25, 0.12, zt + 0.02), voxel=0.0025)


def _hide(f):
    p = f.p
    k = f.H / 1.72
    fem = p["female"]
    zs, zc, zw, zh, zk = f.z_shoulder, f.z_chest, f.z_waist, f.z_hip, f.z_knee
    hem = zk + (0.07 if not fem else -0.06) * k
    secs = [
        (hem, p["pelvis"] + 0.050, 0.118, 0.132, 0.004),
        eased(f, zh - 0.12 * k, 0.026, 0.040, 0.046, wmin=hip_w(f)),
        eased(f, zh, 0.022, 0.024, 0.026, wmin=hip_w(f) - 0.010),
        eased(f, zw, 0.012, 0.012, 0.012),
        eased(f, zc, 0.016, 0.016, 0.030),
        eased(f, zs - 0.072 * k, 0.014, 0.012, 0.030),
        eased(f, zs + 0.010, 0.012, 0.010, 0.010),
    ]
    folds = ((6, 0.4, 3.0, [(hem, 0.07), (zh, 0.02), (zw, 0.0)]),)
    outer = loft(secs, folds, seed=0.6).eval
    # over the left shoulder, under the right arm
    top = lambda P: (zc + 0.050 * k) + 0.30 * np.clip(P[..., 0], -0.20, 0.25) + 0.25 * np.maximum(P[..., 0] - 0.04, 0)
    neck = _neck_hole(f, 0.062 * k, 0.060 * k, 0.050 * k)
    hem_fn = _hem(hem, amp=0.012, jag=0.038 * k, count=6, tilt=0.030 * k, seed=0.4)
    keep = keep_all(above(hem_fn), below(top), remove(neck),
                    remove(_sleeve_cut(f.shoulder["L"], (f.elbow["L"] - f.shoulder["L"]).normalized(), 0.010, 0.09)))
    lo, hi = box_of(f, hem - 0.08, zs + 0.06, x=0.36)
    wrap = Piece("hide_wrap", "CLOTH_A", solid_fn(outer, keep), shell_fn(outer, keep, 0.0075), lo, hi, outer=outer, keep=keep)
    # the fur cape about the shoulders, open at the throat
    cs = [
        (zc - 0.045 * k, 0.322 * k, 0.150 * k, 0.160 * k, 0.012),
        (zs - 0.090 * k, 0.290 * k, 0.130 * k, 0.140 * k, 0.012),
        (zs - 0.010, 0.255 * k, 0.098 * k, 0.110 * k, 0.012),
        (zs + 0.030 * k, 0.150 * k, 0.074 * k, 0.088 * k, 0.014),
        (zs + 0.052 * k, 0.088 * k, 0.062 * k, 0.074 * k, 0.016),
    ]
    cape_outer_l = loft(cs, ((9, 0.2, 0.0, [(zc - 0.05, 0.06), (zs, 0.01)]),), seed=1.1).eval

    def cape_outer(P):
        d = cape_outer_l(P)
        n = np.sin(P[..., 0] * 160.0) * np.sin(P[..., 1] * 140.0 + 1.0) * np.sin(P[..., 2] * 150.0 + 2.0)
        return d + 0.0035 * n
    cape_hem = _hem(zc - 0.020 * k, jag=0.036 * k, count=11, seed=0.2)
    cape_keep = keep_all(above(cape_hem), _front_slit(f, 0.030, 0.50, zs + 0.05))
    lo, hi = box_of(f, zc - 0.12, zs + 0.09, x=0.40)
    cape = Piece("hide_cape", "CLOTH_B", solid_fn(cape_outer, cape_keep), shell_fn(cape_outer, cape_keep, 0.011), lo, hi, cover=False)
    # a cord belt with hanging ends
    belt = _cord_belt(f, zw - 0.012 * k, outer, "hide_cord", "CLOTH_C")
    feet = _shoes(f, "hide_footwraps", "CLOTH_B", top=0.11, wraps=3)
    return [wrap, cape, belt, feet]


def _front_slit(f, half, spread, z_top):
    """Removed: an opening down the front that widens as it falls."""
    def fn(P):
        w = half + spread * np.maximum(z_top - P[..., 2], 0.0)
        region = np.maximum(np.abs(P[..., 0]) - w, P[..., 1] + 0.01)
        return -region
    return fn


def _cord_belt(f, z, garment_outer, name, slot, r=0.0065, sash=False):
    """A cord (or sash) round the garment at height z, tied at the front."""
    k = f.H / 1.72
    # find the garment's surface at this height around the figure
    pts = []
    for i in range(36):
        th = 2 * math.pi * i / 36
        lo_r, hi_r = 0.0, 0.5
        dirv = np.array([math.sin(th), -math.cos(th), 0.0], dtype=np.float32)
        for _ in range(24):
            mid = (lo_r + hi_r) / 2
            P = np.array([[dirv[0] * mid, dirv[1] * mid, z]], dtype=np.float32)
            if garment_outer(P)[0] < 0:
                lo_r = mid
            else:
                hi_r = mid
        pts.append(Vector((float(dirv[0] * lo_r), float(dirv[1] * lo_r), z)))
    parts = []
    for i in range(36):
        a, b = pts[i], pts[(i + 1) % 36]
        oa = Vector((a.x, a.y, 0)).normalized() * (r * 0.7)
        ob = Vector((b.x, b.y, 0)).normalized() * (r * 0.7)
        if sash:
            parts.append(prim(S.RoundBox((a + b) / 2 + oa, (r * 0.6, (b - a).length * 0.55 + 0.002, 0.026 * k), 0.004,
                                         rot=Vector((0, 1, 0)).rotation_difference((b - a).normalized()))))
        else:
            parts.append(prim(S.RoundCone(a + oa, b + ob, r, r)))
    front = pts[0] + Vector((0.03 * k, -r, 0))
    knot = prim(S.Sphere(front + Vector((0, -0.004, 0)), r * (1.8 if not sash else 2.6)))
    hang1 = prim(S.RoundCone(front + Vector((0, -0.004, -0.006)), front + Vector((0.010, -0.010, -0.15 * k)), r * (0.9 if not sash else 1.6), r * 0.7))
    hang2 = prim(S.RoundCone(front + Vector((-0.004, -0.004, -0.006)), front + Vector((-0.014, -0.008, -0.11 * k)), r * (0.9 if not sash else 1.6), r * 0.7))
    shell = union_fn(*parts, knot, hang1, hang2, k=0.003)
    return Piece(name, slot, shell, shell, (-0.32, -0.32, z - 0.25), (0.32, 0.32, z + 0.06), voxel=0.0022, cover=False)


def _tunic(f):
    p = f.p
    k = f.H / 1.72
    fem = p["female"]
    zs, zc, zw, zh, zk = f.z_shoulder, f.z_chest, f.z_waist, f.z_hip, f.z_knee
    hem = zk + (0.05 if not fem else -0.17) * k
    flare = 0.060 if not fem else 0.085
    secs = [
        (hem, p["pelvis"] + flare, 0.130 + flare * 0.3, 0.145 + flare * 0.3, 0.004),
        eased(f, zh - 0.12 * k, 0.030, 0.044, 0.050, wmin=hip_w(f)),
        eased(f, zh, 0.026, 0.028, 0.030, wmin=hip_w(f) - 0.008),
        eased(f, zw - 0.040 * k, 0.018, 0.018, 0.016),
        eased(f, zw, 0.012, 0.012, 0.012),
        eased(f, zw + 0.060 * k, 0.020, 0.020, 0.016, wmin=p["chest_w"] * 0.94),
        eased(f, zc, 0.018, 0.016, 0.030),
        eased(f, zs - 0.072 * k, 0.016, 0.014, 0.030),
        eased(f, zs + 0.012, 0.014, 0.012, 0.012),
    ]
    folds = ((12, 0.0, 4.0, [(hem, 0.085), (zh, 0.03), (zw, 0.0), (zw + 0.06, 0.025), (zc, 0.0)]),)
    body = loft(secs, folds, seed=0.2).eval
    parts = [body]
    cuts = []
    for side in ("L", "R"):
        L = (f.elbow[side] - f.shoulder[side]).length * 0.52
        sl, sh, d = _sleeve(f, side, L, p["arm"] * 1.04 + 0.008, p["arm"] * 0.92 + 0.012, flare=0.005)
        parts.append(sl.eval)
        cuts.append((sh, d, L))
    outer = sleeved(body, union_fn(*parts[1:]), zc - 0.02, k=0.020)
    neck = _neck_hole(f, 0.066 * k, 0.064 * k, 0.054 * k, drop=0.010, front=0.022)
    hem_fn = _hem(hem, amp=0.006)
    keeps = [above(hem_fn), remove(neck)] + [remove(_sleeve_cut(sh, d, L, 0.11)) for sh, d, L in cuts]
    keep = keep_all(*keeps)
    lo, hi = box_of(f, hem - 0.06, zs + 0.08, x=0.40)
    tunic = Piece("tunic_body", "CLOTH_A", solid_fn(outer, keep), shell_fn(outer, keep, 0.0065), lo, hi, outer=outer, keep=keep)
    sleeves = union_fn(*parts[1:])
    tunic.sleeve, tunic.trunk = sleeves, body
    # bands of the third colour at the hem, the neck and the sleeves
    hem_band = _trimmed(outer, keep, lambda P: (P[..., 2] - hem_fn(P)) - 0.034 * k, 0.0065)
    neck_band = _trimmed(outer, keep, lambda P: neck(P) - 0.016 * k, 0.0065)
    cuff_bands = [_trimmed(outer, keep, (lambda sh, d, L: lambda P: _sleeve_cut(sh, d, L - 0.026 * k, 0.11)(P))(sh, d, L), 0.0065)
                  for sh, d, L in cuts]
    trim = union_fn(hem_band, neck_band, *cuff_bands)
    trims = Piece("tunic_trim", "CLOTH_C", trim, trim, lo, hi, cover=False)
    trims.sleeve, trims.trunk = sleeves, body
    belt = _cord_belt(f, zw, body, "tunic_belt", "LEATHER", r=0.006, sash=True)
    shoes = _shoes(f, "tunic_shoes", "LEATHER", top=0.07)
    return [tunic, trims, belt, shoes]


def _robe(f):
    p = f.p
    k = f.H / 1.72
    fem = p["female"]
    zs, zc, zw, zh, zk = f.z_shoulder, f.z_chest, f.z_waist, f.z_hip, f.z_knee
    hem = f.z_ankle + 0.030 * k
    secs = [
        (hem, p["pelvis"] + 0.105, 0.180, 0.205, 0.006),
        (zk, p["pelvis"] + 0.070, 0.140, 0.160, 0.005),
        eased(f, zh - 0.12 * k, 0.034, 0.048, 0.054, wmin=hip_w(f)),
        eased(f, zh, 0.028, 0.030, 0.032, wmin=hip_w(f) - 0.006),
        eased(f, zw, 0.014, 0.014, 0.014),
        eased(f, zw + 0.060 * k, 0.020, 0.020, 0.016, wmin=p["chest_w"] * 0.94),
        eased(f, zc, 0.018, 0.016, 0.030),
        eased(f, zs - 0.072 * k, 0.016, 0.014, 0.030),
        eased(f, zs + 0.012, 0.014, 0.012, 0.012),
    ]
    folds = ((14, 0.3, 2.5, [(hem, 0.090), (zk, 0.06), (zh, 0.025), (zw, 0.0), (zw + 0.06, 0.022), (zc, 0.0)]),)
    body = loft(secs, folds, seed=1.7).eval
    parts = [body]
    cuts = []
    for side in ("L", "R"):
        sh, el, wr = f.shoulder[side], f.elbow[side], f.wrist[side]
        up = S.RoundCone(sh + (el - sh).normalized() * 0.004, el, p["arm"] * 1.04 + 0.008, p["forearm"] * 1.08 + 0.012)
        d2 = (wr - el).normalized()
        L2 = (wr - el).length - 0.030 * k
        lowr = S.RoundCone(el, el + d2 * (L2 + 0.02), p["forearm"] * 1.08 + 0.012, 0.045 * k)
        parts += [up.eval, lowr.eval]
        cuts.append((el, d2, L2))
    outer = sleeved(body, union_fn(*parts[1:], k=0.012), zc - 0.02, k=0.018)
    neck = _neck_hole(f, 0.064 * k, 0.064 * k, 0.052 * k, drop=0.008, front=0.020)
    hem_fn = _hem(hem, amp=0.004)
    keeps = [above(hem_fn), remove(neck)] + [remove(_sleeve_cut(el, d, L, 0.13)) for el, d, L in cuts]
    keep = keep_all(*keeps)
    lo, hi = box_of(f, hem - 0.05, zs + 0.08, x=0.52)
    robe = Piece("robe_body", "CLOTH_A", solid_fn(outer, keep), shell_fn(outer, keep, 0.0065), lo, hi, outer=outer, keep=keep)
    sleeves = union_fn(*parts[1:])
    robe.sleeve, robe.trunk = sleeves, body
    hem_band = _trimmed(outer, keep, lambda P: (P[..., 2] - hem_fn(P)) - 0.050 * k, 0.0065)
    neck_band = _trimmed(outer, keep, lambda P: neck(P) - 0.018 * k, 0.0065)
    cuff_bands = [_trimmed(outer, keep, (lambda el, d, L: lambda P: _sleeve_cut(el, d, L - 0.034 * k, 0.13)(P))(el, d, L), 0.0065)
                  for el, d, L in cuts]
    trim = union_fn(hem_band, neck_band, *cuff_bands)
    trims = Piece("robe_trim", "CLOTH_C", trim, trim, lo, hi, cover=False)
    trims.sleeve, trims.trunk = sleeves, body
    sash = _cord_belt(f, zw, body, "robe_sash", "CLOTH_C", r=0.007, sash=True)
    mantle, mantle_edge = _mantle(f)
    shoes = _shoes(f, "robe_shoes", "LEATHER", top=0.06)
    return [robe, trims, sash, mantle, mantle_edge, shoes]


def _mantle(f):
    """A mantle over the shoulders, falling behind the arms to the calves."""
    p = f.p
    k = f.H / 1.72
    zs, zc, zh, zk = f.z_shoulder, f.z_chest, f.z_hip, f.z_knee
    reach = p["shoulder"] + p["arm"] * 1.1 + 0.022
    hem = zk - 0.13 * k
    cy = 0.020
    secs = [
        (hem, reach + 0.030, 0.150, 0.235, cy + 0.03),
        (zk, reach + 0.022, 0.150, 0.215, cy + 0.025),
        (zh, reach + 0.014, 0.150, 0.185, cy + 0.02),
        (zc - 0.05 * k, reach + 0.010, 0.150, 0.160, cy + 0.01),
        (zs - 0.090 * k, reach + 0.026, 0.140, 0.158, cy + 0.01),
        (zs - 0.010, reach + 0.016, 0.112, 0.130, cy),
        (zs + 0.032 * k, 0.140 * k, 0.078 * k, 0.096 * k, 0.012),
        (zs + 0.056 * k, 0.094 * k, 0.068 * k, 0.082 * k, 0.012),
    ]
    folds = ((10, 0.9, 2.0, [(hem, 0.075), (zh, 0.05), (zc, 0.02), (zs - 0.05, 0.0)]),)
    outer = loft(secs, folds, seed=2.3).eval

    def open_front(P):
        # how far round from the back the mantle reaches, by height
        z = P[..., 2]
        back = np.degrees(np.abs(np.arctan2(P[..., 0], P[..., 1] - cy)))
        reachdeg = np.interp(z, [hem - 0.1, zc - 0.02, zs - 0.10 * k, zs - 0.02 * k, zs + 0.030 * k, zs + 0.2],
                             [79.0, 79.0, 92.0, 150.0, 172.0, 172.0])
        return (back - reachdeg) * 0.0035

    hem_fn = _hem(hem, amp=0.010, tilt=0.0)
    keep = keep_all(above(hem_fn), open_front)
    lo, hi = box_of(f, hem - 0.06, zs + 0.10, x=0.56, y0=-0.24, y1=0.36)
    body = Piece("robe_mantle", "CLOTH_B", solid_fn(outer, keep), shell_fn(outer, keep, 0.0060), lo, hi, cover=False)

    def edge_band(P):
        a = -open_front(P)               # distance in from the front edge
        b = P[..., 2] - hem_fn(P)        # height above the hem
        return np.minimum(a, b) - 0.026 * k
    edge = _trimmed(outer, keep, edge_band, 0.0060)
    clasp = S.Ellipsoid(Vector((0.0, -0.068 * k, zs + 0.012 * k)), (0.016 * k, 0.008 * k, 0.016 * k))
    edge_all = union_fn(edge, clasp.eval, k=0.002)
    trim = Piece("robe_mantle_edge", "CLOTH_C", edge_all, edge_all, lo, hi, cover=False)
    return body, trim


# --- what the clothes cover ----------------------------------------------------------

def coverage(body, pieces, strict=None, margin=0.010, reach=0.016, edge=0.014):
    """For each body vertex: True where these pieces hide it.
    Skin inside a piece is hidden; skin poking up to `reach` out through it is
    hidden too (the cloth is drawn there), but never within `edge` of a hem,
    cuff or neckline. strict (per vertex, e.g. arms) only hides what is inside."""
    co = np.array([v.co[:] for v in body.data.vertices], dtype=np.float32)
    covered = np.zeros(len(co), dtype=bool)
    if strict is None:
        strict = np.zeros(len(co), dtype=bool)
    for pc in pieces:
        if not pc.cover:
            continue
        inside = np.all((co >= pc.lo) & (co <= pc.hi), axis=-1)
        if not inside.any():
            continue
        idx = np.nonzero(inside)[0]
        P = co[inside]
        if pc.outer is not None and pc.keep is not None:
            o = pc.outer(P)
            kp = pc.keep(P)
            loose = (o < reach) & (kp < -edge)
            tight = (o < 0.010) & (kp < -edge)
            hit = np.where(strict[idx], tight, loose)
        else:
            hit = pc.solid(P) < -margin
        covered[idx[hit]] = True
    return covered

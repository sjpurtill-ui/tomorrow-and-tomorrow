"""Pieces for the court sets (tools/blender/court_set.py).

Everything is authored in the game's frame (Godot: x right, y up, z toward
the god) and converted here to Blender's (x, -z, y), so the numbers in
court_set.py read the same as the marks Godot gets in court_sets.json.

Materials are named by slot (GROUND, BARK, WOOD, WOOD_END, CHAR, ASH, EMBER,
STONE, HIDE, HIDE_DARK, HIDE_PALE, CORD, REED, THATCH, CLAY, MUD, PLANK,
SHIELD_*, WEAVE_*, food slots...); the game colours each slot for the era and
the people, and paints patterns (bark, end grain, stitched hides, painted
shields, woven bands) from the UVs:
  tubes (logs, posts, poles)  UV = (around, along) in metres;
  their cut ends              UV = the cut's own disc, -1..1 (rings, checks);
  sheets (hides, hangings)    UV = 0..1 across and up the sheet;
  lathes (pots, shields)      UV = (turn 0..1, profile 0..1);
  everything else             UV = a planar projection in metres.
Vertex colour (COLOR_0): R baked ambient occlusion, G a wear mask (trodden
earth, polished wood), B a per-piece variation (0..1).
"""
import math
import random

import bpy
import bmesh
import numpy as np
from mathutils import Vector, Matrix, Quaternion, Euler
from mathutils.noise import noise as _noise, fractal as _fractal

SLOT_COLOURS = {
    "GROUND": (0.47, 0.39, 0.27), "BARK": (0.33, 0.25, 0.18), "WOOD": (0.55, 0.42, 0.29),
    "WOOD_END": (0.72, 0.58, 0.40), "CHAR": (0.10, 0.08, 0.07), "ASH": (0.55, 0.52, 0.48),
    "EMBER": (1.0, 0.45, 0.12), "STONE": (0.52, 0.49, 0.44), "HIDE": (0.62, 0.48, 0.33),
    "HIDE_DARK": (0.40, 0.29, 0.20), "HIDE_PALE": (0.76, 0.66, 0.50), "CORD": (0.36, 0.27, 0.18),
    "REED": (0.66, 0.56, 0.34), "THATCH": (0.58, 0.47, 0.28), "CLAY": (0.62, 0.38, 0.24),
    "MUD": (0.56, 0.44, 0.31), "PLANK": (0.50, 0.37, 0.24), "FOOD_ROOT": (0.60, 0.42, 0.25),
    "FOOD_GRAIN": (0.80, 0.66, 0.38), "MEAT": (0.48, 0.18, 0.13), "FISH": (0.62, 0.58, 0.48),
    "BONE": (0.86, 0.80, 0.68), "OCHRE": (0.66, 0.28, 0.14), "FLINT": (0.30, 0.30, 0.32),
    "LEAF": (0.30, 0.36, 0.20), "GRASS": (0.45, 0.48, 0.26), "BERRY": (0.42, 0.10, 0.16),
    "BLANKET": (0.55, 0.32, 0.22), "SOOT": (0.30, 0.27, 0.24), "BREAD": (0.72, 0.52, 0.30),
    "SHIELD_A": (0.6, 0.4, 0.3), "SHIELD_B": (0.6, 0.4, 0.3), "SHIELD_C": (0.6, 0.4, 0.3),
    "WEAVE_A": (0.6, 0.3, 0.2), "WEAVE_B": (0.3, 0.4, 0.5), "WEAVE_C": (0.7, 0.6, 0.3),
    "FAR_0": (0.5, 0.55, 0.5), "FAR_1": (0.6, 0.65, 0.6), "FAR_2": (0.7, 0.72, 0.7),
    "PLASTER": (0.85, 0.80, 0.70), "BRICK": (0.62, 0.48, 0.34), "LIME": (0.9, 0.88, 0.82),
    "BRONZE": (0.62, 0.42, 0.20), "TABLET": (0.66, 0.54, 0.40), "CARPET": (0.55, 0.18, 0.15),
    "GOLD": (0.8, 0.6, 0.2), "ROPE": (0.6, 0.5, 0.3), "ONION": (0.8, 0.7, 0.5),
    "FLAGS": (0.6, 0.57, 0.52), "STONE_BLOCK": (0.68, 0.63, 0.55), "STONE_DARK": (0.35, 0.33, 0.3),
}
UV = "UVMap"


def B(g):
    """Game point (x, y-up, z-toward-the-god) -> Blender vector."""
    return Vector((g[0], -g[2], g[1]))


def G(b):
    """Blender vector -> game point."""
    return (b[0], b[2], -b[1])


def material(slot):
    m = bpy.data.materials.get(slot)
    if m is None:
        m = bpy.data.materials.new(slot)
        c = SLOT_COLOURS.get(slot, (0.5, 0.5, 0.5))
        m.diffuse_color = (c[0], c[1], c[2], 1.0)
    return m


def log(*a):
    print("[court_set]", *a, flush=True)


def _uv_layer(bm):
    lay = bm.loops.layers.uv.get(UV)
    if lay is None:
        lay = bm.loops.layers.uv.new(UV)
    return lay


def planar_uv(bm, scale=1.0):
    lay = _uv_layer(bm)
    for f in bm.faces:
        n = f.normal
        for lp in f.loops:
            co = lp.vert.co
            # project on the plane the face mostly faces
            if abs(n.z) >= abs(n.x) and abs(n.z) >= abs(n.y):
                lp[lay].uv = (co.x * scale, co.y * scale)
            elif abs(n.x) >= abs(n.y):
                lp[lay].uv = (co.y * scale, co.z * scale)
            else:
                lp[lay].uv = (co.x * scale, co.z * scale)
    return bm


class Builder:
    """Collects bmesh pieces per object name; each piece carries its slot."""

    def __init__(self, seed=7):
        self.rng = random.Random(seed)
        self.objects = {}   # name -> (bm, [slots])
        self.extras = {}    # name -> dict of custom props

    def bm(self, name):
        if name not in self.objects:
            bm = bmesh.new()
            _uv_layer(bm)
            self.objects[name] = (bm, [])
        return self.objects[name]

    def slot_index(self, name, slot):
        _, slots = self.bm(name)
        if slot not in slots:
            slots.append(slot)
        return slots.index(slot)

    def add(self, name, src_bm, slot, wear=0.0, var=None):
        """Merge a finished bmesh (in Blender coords) into object `name`."""
        dst, _ = self.bm(name)
        idx = self.slot_index(name, slot)
        if var is None:
            var = self.rng.random()
        if src_bm.loops.layers.uv.get(UV) is None:
            src_bm.normal_update()
            planar_uv(src_bm)
        me = bpy.data.meshes.new("_tmp")
        src_bm.to_mesh(me)
        for p in me.polygons:
            p.material_index = idx
        n = len(me.vertices)
        wv = me.attributes.new("wear", 'FLOAT', 'POINT')
        vv = me.attributes.new("var", 'FLOAT', 'POINT')
        if callable(wear):
            wv.data.foreach_set("value", [float(wear(v.co)) for v in me.vertices])
        else:
            wv.data.foreach_set("value", [float(wear)] * n)
        vv.data.foreach_set("value", [float(var)] * n)
        dst.from_mesh(me)
        bpy.data.meshes.remove(me)
        src_bm.free()

    def finish(self, collection=None, flat_slots=()):
        made = {}
        for name, (bm, slots) in self.objects.items():
            me = bpy.data.meshes.new(name)
            bm.to_mesh(me)
            bm.free()
            obj = bpy.data.objects.new(name, me)
            (collection or bpy.context.scene.collection).objects.link(obj)
            for s in slots:
                me.materials.append(material(s))
            for p in me.polygons:
                p.use_smooth = slots[p.material_index] not in flat_slots
            if name in self.extras:
                for k, v in self.extras[name].items():
                    obj[k] = v
            made[name] = obj
        self.objects = {}
        return made


# --- primitives (all return a bmesh in Blender coordinates) -------------------------

def _bm_from(verts, faces, uvs=None):
    """uvs: one (u, v) per vertex, or None."""
    bm = bmesh.new()
    vs = [bm.verts.new(v) for v in verts]
    lay = _uv_layer(bm) if uvs is not None else None
    for f in faces:
        try:
            face = bm.faces.new([vs[i] for i in f])
        except ValueError:
            continue
        if lay is not None:
            for lp, i in zip(face.loops, f):
                lp[lay].uv = uvs[i]
    bm.normal_update()
    return bm


def tube(path, radii, segs=10, caps=True, wobble=0.0, seed=0.0, twist=0.0, flat=1.0, cut=(0.0, 0.0)):
    """A tube along `path` (game coords) with a radius per point; `flat`
    squashes the section (1 round); `cut` tilts the two ends (tan of the
    angle), as an axe or a split leaves them. Returns (bm, caps) where caps is
    a bmesh of the two ends (UV = their own disc) or None."""
    pts = [B(p) for p in path]
    n = len(pts)
    frames = []
    up = Vector((0, 0, 1))
    for i in range(n):
        if i == 0:
            t = (pts[1] - pts[0]).normalized()
        elif i == n - 1:
            t = (pts[-1] - pts[-2]).normalized()
        else:
            t = (pts[i + 1] - pts[i - 1]).normalized()
        a = up if abs(t.dot(up)) < 0.9 else Vector((1, 0, 0))
        u = t.cross(a).normalized()
        v = t.cross(u).normalized()
        frames.append((t, u, v))
    along = [0.0]
    for i in range(1, n):
        along.append(along[-1] + (pts[i] - pts[i - 1]).length)
    rings = []
    for i in range(n):
        t, u, v = frames[i]
        ring = []
        for k in range(segs + 1):
            ang = 2 * math.pi * (k % segs) / segs + twist * i
            r = radii[i]
            if wobble:
                r *= 1.0 + wobble * _noise(Vector((math.cos(ang) * 1.7, math.sin(ang) * 1.7, i * 0.9 + seed)))
            off = u * math.cos(ang) * r + v * math.sin(ang) * r * flat
            p = pts[i] + off
            if i == 0 and cut[0]:
                p = p - t * off.dot(u) * cut[0]
            if i == n - 1 and cut[1]:
                p = p + t * off.dot(u) * cut[1]
            ring.append(p)
        rings.append(ring)
    verts = []
    uvs = []
    rmean = sum(radii) / len(radii)
    for i in range(n):
        for k in range(segs + 1):
            verts.append(rings[i][k])
            uvs.append((k / segs * 2 * math.pi * rmean, along[i]))
    faces = []
    w = segs + 1
    for i in range(n - 1):
        for k in range(segs):
            a = i * w + k
            faces.append((a, a + 1, a + 1 + w, a + w))
    bm = _bm_from(verts, faces, uvs)
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-6)
    cap_bm = None
    if caps:
        cv = []
        cf = []
        cuv = []
        for which, i in ((0, 0), (1, n - 1)):
            base = len(cv)
            t, u, v = frames[i]
            centre = sum(rings[i][:segs], Vector()) / segs
            r = radii[i]
            cv.append(centre)
            cuv.append((0.0, 0.0))
            for k in range(segs):
                p = rings[i][k]
                d = p - centre
                cv.append(p)
                cuv.append((d.dot(u) / max(r, 1e-6), d.dot(v) / max(r * flat, 1e-6)))
            for k in range(segs):
                a = base + 1 + k
                b = base + 1 + (k + 1) % segs
                cf.append((base, b, a) if which == 0 else (base, a, b))
        cap_bm = _bm_from(cv, cf, cuv)
    return bm, cap_bm


def log_piece(bld, name, a, b, r, seed=0.0, segs=11, bend=0.04, slot="BARK", end_slot="WOOD_END", wear=0.0, knots=True,
              flat=None, stubs=None, cut=None):
    """A log from a to b (game coords): bark that is never quite round, a slight
    bend, lumps and knots, a branch stub or two, ends cut on a slant."""
    a = Vector(a)
    b = Vector(b)
    rng = random.Random(int(seed * 1000) + 17)
    steps = 9
    path = []
    radii = []
    d = b - a
    side = Vector((-d.z, 0.0, d.x)).normalized() if abs(d.x) + abs(d.z) > 1e-4 else Vector((1, 0, 0))
    for i in range(steps):
        t = i / (steps - 1)
        p = a.lerp(b, t)
        p += side * math.sin(t * math.pi) * bend * d.length
        p.y += math.sin(t * math.pi) * bend * 0.3 * d.length
        path.append(tuple(p))
        rr = r * (1.0 + 0.09 * _noise(Vector((t * 3.0, seed, 0.3))) - 0.08 * t)
        if knots and 0.15 < t < 0.85 and abs(_noise(Vector((t * 9.0, seed * 2.0, 1.1)))) > 0.3:
            rr *= 1.08
        radii.append(rr)
    if flat is None:
        flat = rng.uniform(0.84, 0.97)
    if cut is None:
        cut = (rng.uniform(-0.35, 0.35), rng.uniform(-0.35, 0.35))
    bm, caps = tube(path, radii, segs=segs, caps=True, wobble=0.09, seed=seed, flat=flat, cut=cut, twist=rng.uniform(-0.05, 0.05))
    bld.add(name, bm, slot, wear=wear)
    bld.add(name, caps, end_slot, wear=wear)
    # branch stubs, trimmed with an axe
    count = stubs if stubs is not None else (rng.randint(0, 2) if d.length > 0.8 and r > 0.06 else 0)
    for k in range(count):
        t = rng.uniform(0.25, 0.75)
        c = Vector(path[int(t * (steps - 1))])
        ang = rng.uniform(0, math.tau)
        dirv = (side * math.cos(ang) + Vector((0, 1, 0)) * math.sin(ang)).normalized()
        dirv = (dirv + d.normalized() * 0.5).normalized()
        sr = r * rng.uniform(0.28, 0.42)
        sb, sc = tube([tuple(c), tuple(c + dirv * (r + sr * 1.8))], [sr * 1.3, sr], segs=7, caps=True, flat=0.9, cut=(0.0, 0.25))
        bld.add(name, sb, slot, wear=wear)
        bld.add(name, sc, end_slot, wear=wear)
    return path


def post(bld, name, foot, height, r, lean=(0.0, 0.0), seed=0.0, slot="WOOD", pointed=True, segs=8, wear=0.0):
    """A stake or post standing at foot (game coords)."""
    foot = Vector(foot)
    top = foot + Vector((lean[0], height, lean[1]))
    n = 6
    path = [tuple(foot.lerp(top, i / (n - 1))) for i in range(n)]
    radii = [r * (1.0 - 0.08 * i / (n - 1)) for i in range(n)]
    if pointed:
        radii[-1] = r * 0.15
        path[-1] = tuple(foot.lerp(top, 1.0) + Vector((0, r * 1.5, 0)))
    path[0] = tuple(Vector(path[0]) - Vector((0, 0.08, 0)))
    bm, caps = tube(path, radii, segs=segs, caps=True, wobble=0.06, seed=seed)
    bld.add(name, bm, slot, wear=wear)
    bld.add(name, caps, "WOOD_END" if not pointed else slot, wear=wear)
    return top


def rock(bld, name, at, size, seed=0.0, slot="STONE", flat=0.6, subdiv=2, wear=0.0):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=1.0)
    s = Vector(size) if hasattr(size, "__len__") else Vector((size, size * flat, size))
    for v in bm.verts:
        n = v.co.copy()
        d = 1.0 + 0.28 * _fractal(n * 1.3 + Vector((seed, seed * 0.7, 0.0)), 0.8, 2.0, 3)
        v.co = Vector((n.x * s[0], n.y * s[2], n.z * s[1])) * d
        if v.co.z < -s[1] * 0.35:
            v.co.z = -s[1] * 0.35
    rot = Matrix.Rotation(seed * 2.3, 4, 'Z')
    bmesh.ops.transform(bm, matrix=Matrix.Translation(B(at)) @ rot, verts=bm.verts)
    bm.normal_update()
    bld.add(name, bm, slot, wear=wear)


def sheet(cols, rows, fn):
    """A grid sheet; fn(u, v) -> Blender point. UV = (u, v). Returns bmesh."""
    verts = []
    uvs = []
    for j in range(rows + 1):
        for i in range(cols + 1):
            verts.append(fn(i / cols, j / rows))
            uvs.append((i / cols, j / rows))
    faces = []
    w = cols + 1
    for j in range(rows):
        for i in range(cols):
            a = j * w + i
            faces.append((a, a + 1, a + 1 + w, a + w))
    return _bm_from(verts, faces, uvs)


def thicken(bm, t):
    """Close a sheet into a thin solid (no open edge for the ink to show through)."""
    bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=t)
    bm.normal_update()
    return bm


def hide_panel(bld, name, p0, p1, h0, h1, seed=0.0, slot="HIDE", sag=0.10, droop=0.0, tear=0.0):
    """A hide stretched between two stakes: lower edge h0, upper edge h1 above
    ground; it bows and sags, its top edge droops between the lacings, and a
    torn corner or a ragged edge shows it is a skin, not a sheet."""
    a = Vector(p0)
    b = Vector(p1)
    nrm = Vector((-(b - a).z, 0.0, (b - a).x)).normalized()

    def f(u, v):
        p = a.lerp(b, u)
        y = h0 + (h1 - h0) * v
        bow = math.sin(u * math.pi) * sag * (0.5 + 0.5 * v)
        ripple = 0.03 * _noise(Vector((u * 4.0 + seed, v * 3.0, seed)))
        q = p + nrm * (bow + ripple)
        edge = 0.0
        if v > 0.9:
            edge = -0.06 * abs(_noise(Vector((u * 7.0, seed, 2.0)))) - droop * math.sin(u * math.pi)
        if v < 0.1:
            edge = 0.05 * abs(_noise(Vector((u * 6.0, seed, 5.0))))
        if tear and u > 0.75 and v > 0.7:
            edge -= tear * (u - 0.75) * (v - 0.7) * 8.0
        q.y = y + edge - math.sin(u * math.pi) * 0.05 * v
        return B(q)

    bm = sheet(10, 5, f)
    thicken(bm, 0.014)
    bld.add(name, bm, slot)


def disc_fn(r, segs, fn):
    verts = [fn(0.0, 0.0)]
    uvs = [(0.0, 0.0)]
    for k in range(segs):
        ang = 2 * math.pi * k / segs
        verts.append(fn(math.cos(ang) * r, math.sin(ang) * r))
        uvs.append((math.cos(ang), math.sin(ang)))
    faces = [(0, 1 + k, 1 + (k + 1) % segs) for k in range(segs)]
    return _bm_from(verts, faces, uvs)


def lathe(profile, segs=14, at=(0, 0, 0), wobble=0.0, seed=0.0, cap_bottom=True, closed=False, wall=0.0):
    """Surface of revolution: profile [(radius, height)...] bottom to top (game
    coords). UV = (turn, profile). wall > 0 makes it a solid vessel (an inner
    wall wall-thick inside, joined at the rim), so nothing open shows the ink."""
    base = Vector(at)
    prof = list(profile)
    if wall > 0.0:
        inner = []
        for r, h in reversed(prof[:-1]):
            inner.append((max(r - wall, 0.002), max(h, prof[0][1] + wall)))
        prof = prof + inner
    verts = []
    uvs = []
    n = len(prof)
    for i, (r, h) in enumerate(prof):
        for k in range(segs + 1):
            ang = 2 * math.pi * (k % segs) / segs
            rr = r * (1.0 + wobble * _noise(Vector((math.cos(ang), math.sin(ang), h * 3.0 + seed))))
            verts.append(B(base + Vector((math.cos(ang) * rr, h, math.sin(ang) * rr))))
            uvs.append((k / segs, i / max(n - 1, 1)))
    faces = []
    w = segs + 1
    for i in range(n - 1):
        for k in range(segs):
            a = i * w + k
            faces.append((a, a + w, a + w + 1, a + 1))
    if cap_bottom:
        faces.append(tuple(i * 1 for i in range(segs)))
    if wall > 0.0:
        # close the inner bottom too
        last = (n - 1) * w
        faces.append(tuple(last + k for k in reversed(range(segs))))
    bm = _bm_from(verts, faces, uvs)
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-6)
    bm.normal_update()
    return bm


def basket(bld, name, at, r, h, seed=0.0, slot="REED"):
    """An open woven basket, a real wall thick (a rim roll at the top)."""
    prof = [(r * 0.72, 0.0), (r * 0.92, h * 0.15), (r, h * 0.55), (r * 1.04, h * 0.92), (r * 1.08, h)]
    bm = lathe(prof, segs=16, at=at, wobble=0.03, seed=seed, wall=0.018)
    bld.add(name, bm, slot)


def pot(bld, name, at, r, h, seed=0.0, slot="CLAY", neck=0.65):
    """A round-bellied pot with a neck and a lip, walls of real thickness."""
    prof = [(r * 0.45, 0.0), (r * 0.85, h * 0.12), (r, h * 0.42), (r * 0.82, h * 0.78), (r * neck, h * 0.9), (r * neck * 1.12, h * 0.98), (r * neck * 1.1, h)]
    bm = lathe(prof, segs=16, at=at, wobble=0.02, seed=seed, wall=0.016)
    bld.add(name, bm, slot)


def tray(bld, name, at, r, h, seed=0.0, slot="BARK"):
    prof = [(r * 0.85, 0.0), (r, h * 0.6), (r * 1.02, h)]
    bld.add(name, lathe(prof, segs=14, at=at, wobble=0.04, seed=seed, wall=0.012), slot)


def heap(bld, name, at, r, h, seed=0.0, slot="FOOD_ROOT", lumps=7):
    """A mound of food (roots, nuts, grain) sitting in a basket at `at` (top centre)."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=12, v_segments=6, radius=1.0)
    for v in bm.verts:
        n = v.co.copy()
        bump = 1.0 + 0.18 * _noise(n * 3.0 + Vector((seed, 0, 0)))
        z = max(n.z, -0.05)
        v.co = Vector((n.x * r * bump, n.y * r * bump, z * h * bump))
    bmesh.ops.transform(bm, matrix=Matrix.Translation(B(at)), verts=bm.verts)
    bm.normal_update()
    bld.add(name, bm, slot)


def lumps(bld, name, at, r, h, count, size, seed=0.0, slot="FOOD_ROOT", squash=0.8):
    """Separate pieces heaped up (roots, onions, loaves): small lumpy spheres."""
    rng = random.Random(int(seed * 100) + 5)
    c = Vector(at)
    for k in range(count):
        ang = rng.uniform(0, math.tau)
        rr = r * math.sqrt(rng.random())
        y = h * (1.0 - (rr / max(r, 1e-6)) ** 2) * rng.uniform(0.5, 1.0)
        p = c + Vector((math.cos(ang) * rr, y + size * 0.5, math.sin(ang) * rr))
        rock(bld, name, tuple(p), (size * rng.uniform(0.8, 1.2), size * squash, size * rng.uniform(0.7, 1.0)), seed=seed + k * 1.7, slot=slot, subdiv=1)


def strip(bld, name, top, length, width, seed=0.0, slot="MEAT"):
    """A strip of drying meat or a split fish hanging from a rack bar."""
    t = Vector(top)

    def f(u, v):
        x = (u - 0.5) * width * (1.0 - 0.3 * v)
        y = -v * length
        z = 0.02 * math.sin(v * 3.0 + seed) + 0.01 * _noise(Vector((u * 3, v * 3, seed)))
        return B(t + Vector((x, y, z)))

    bm = sheet(2, 4, f)
    thicken(bm, 0.014)
    bld.add(name, bm, slot)


def spear(bld, name, butt, tip, seed=0.0, head_slot="FLINT", shaft_slot="WOOD", r=0.016, head=0.16, binding=True):
    a = Vector(butt)
    b = Vector(tip)
    d = (b - a).normalized()
    shaft_end = b - d * head
    path = [tuple(a.lerp(shaft_end, i / 4)) for i in range(5)]
    bm, caps = tube(path, [r * 0.9, r, r, r, r * 0.95], segs=6, caps=True)
    bld.add(name, bm, shaft_slot)
    bld.add(name, caps, shaft_slot)
    side = d.cross(Vector((0, 1, 0)))
    if side.length < 0.1:
        side = Vector((1, 0, 0))
    side.normalize()
    flat = d.cross(side).normalized()
    hw = head * 0.32
    pts = [shaft_end - d * 0.01, shaft_end + d * head * 0.35 + side * hw, b, shaft_end + d * head * 0.35 - side * hw]
    thick = flat * 0.008
    verts = [B(p + thick) for p in pts] + [B(p - thick) for p in pts]
    faces = [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
    bld.add(name, _bm_from(verts, faces), head_slot)
    if binding:
        pb = [tuple(shaft_end - d * 0.05), tuple(shaft_end + d * 0.01)]
        bm, caps = tube(pb, [r * 1.5, r * 1.4], segs=6, caps=True)
        bld.add(name, bm, "CORD")
        bld.add(name, caps, "CORD")


def cord(bld, name, a, b, r=0.008, sag=0.05, slot="CORD"):
    a = Vector(a)
    b = Vector(b)
    path = []
    for i in range(6):
        t = i / 5
        p = a.lerp(b, t)
        p.y -= math.sin(t * math.pi) * sag
        path.append(tuple(p))
    bm, caps = tube(path, [r] * 6, segs=5, caps=True)
    bld.add(name, bm, slot)
    bld.add(name, caps, slot)


def ground(bld, name, inner, outer, step_in, rings_out, height_fn, wear_fn, slot="GROUND"):
    """A square core grid of half-size `inner` at `step_in`, then rings out to `outer`."""
    verts = []
    faces = []
    n = int(round(2 * inner / step_in))
    idx = {}
    for j in range(n + 1):
        for i in range(n + 1):
            x = -inner + i * step_in
            z = -inner + j * step_in
            idx[(i, j)] = len(verts)
            verts.append(B((x, height_fn(x, z), z)))
    for j in range(n):
        for i in range(n):
            faces.append((idx[(i, j)], idx[(i, j + 1)], idx[(i + 1, j + 1)], idx[(i + 1, j)]))
    border = []
    for i in range(n):
        border.append(idx[(i, 0)])
    for j in range(n):
        border.append(idx[(n, j)])
    for i in range(n, 0, -1):
        border.append(idx[(i, n)])
    for j in range(n, 0, -1):
        border.append(idx[(0, j)])
    prev = border
    prev_pts = [Vector(G(verts[k])) for k in border]
    for ring in range(1, rings_out + 1):
        t = ring / rings_out
        rad = inner * 1.42 + (outer - inner * 1.42) * (t ** 1.6)
        cur = []
        for p in prev_pts:
            ang = math.atan2(p.z, p.x)
            q = Vector((math.cos(ang) * rad, 0, math.sin(ang) * rad))
            if ring == 1:
                q = p.lerp(q, 0.5) if p.length < rad else q
            cur.append(len(verts))
            verts.append(B((q.x, height_fn(q.x, q.z), q.z)))
        m = len(prev)
        for k in range(m):
            faces.append((prev[k], cur[k], cur[(k + 1) % m], prev[(k + 1) % m]))
        prev = cur
        prev_pts = [Vector(G(verts[k])) for k in cur]
    uvs = [(v.x, v.y) for v in verts]
    bm = _bm_from(verts, faces, uvs)
    bld.add(name, bm, slot, wear=lambda co: wear_fn(co.x, -co.y), var=0.5)


def grass_tufts(bld, name, centre, count, r_in, r_out, seed=1, avoid=None, height=(0.18, 0.42), slot="GRASS"):
    rng = random.Random(seed)
    made = 0
    tries = 0
    while made < count and tries < count * 6:
        tries += 1
        ang = rng.random() * math.tau
        rr = r_in + (r_out - r_in) * math.sqrt(rng.random())
        x = centre[0] + math.cos(ang) * rr
        z = centre[2] + math.sin(ang) * rr
        if avoid and avoid(x, z):
            continue
        h = rng.uniform(*height)
        blades = rng.randint(5, 9)
        bm = bmesh.new()
        lay = _uv_layer(bm)
        for k in range(blades):
            a = rng.random() * math.tau
            lean = rng.uniform(0.15, 0.5)
            bx = math.cos(a)
            bz = math.sin(a)
            w = 0.022
            p0 = Vector((x + bx * 0.03, 0.0, z + bz * 0.03))
            tip = Vector((x + bx * lean * h, h * rng.uniform(0.7, 1.15), z + bz * lean * h))
            side = Vector((-bz, 0, bx)) * w
            vs = [bm.verts.new(B(p0 - side)), bm.verts.new(B(p0 + side)), bm.verts.new(B(tip))]
            face = bm.faces.new(vs)
            for lp, uv in zip(face.loops, ((0, 0), (1, 0), (0.5, 1))):
                lp[lay].uv = uv
        bm.normal_update()
        bld.add(name, bm, slot, var=rng.random())
        made += 1


def far_layer(bld, name, radius, base_y, arc, hills, trees, seed=0.0, slot="FAR_0", step_deg=0.25):
    """One layer of the distance, as an ink-wash silhouette: a curtain round the
    set at `radius` from phi arc[0] to arc[1] (degrees; 0 toward the god, 180
    the back). Its top is the ridge (hills: (low, high, scale)) with a tree
    line on it (trees: (height, width, density) or None), canopies as rounded
    bumps. UV.x runs along it in metres; UV.y is the depth below the ridge in
    metres (0 on the ridge), so the shader can ink the ridge and wash down."""
    rng = random.Random(int(seed * 100) + 9)
    lo, hi, scale = hills
    canopies = []
    if trees:
        th, tw, dens = trees
        phi = arc[0]
        while phi < arc[1]:
            gap = rng.random() > dens
            w = tw * rng.uniform(0.6, 1.4)
            if not gap:
                canopies.append((phi, w / (radius * math.pi / 180.0), th * rng.uniform(0.7, 1.25)))
            phi += (w / (radius * math.pi / 180.0)) * rng.uniform(0.45, 0.85)
    verts = []
    uvs = []
    steps = int((arc[1] - arc[0]) / step_deg)
    for k in range(steps + 1):
        phi = arc[0] + (arc[1] - arc[0]) * k / steps
        p = math.radians(phi)
        x = math.sin(p) * radius
        z = math.cos(p) * radius
        ridge = lo + (hi - lo) * (0.5 + 0.5 * _fractal(Vector((phi * scale * 0.05 + seed, seed * 0.3, 0.0)), 0.6, 2.0, 4))
        top = ridge
        for cphi, cw, ch in canopies:
            dx = (phi - cphi) / (cw * 0.5)
            if abs(dx) < 1.0:
                # a crown: rounded, its edge broken into leaf clumps
                bump = ch * (1.0 - dx * dx) ** 0.42
                bump *= 0.9 + 0.1 * _noise(Vector((phi * 9.0, cphi, seed)))
                bump += ch * 0.06 * _noise(Vector((phi * 31.0, cphi * 2.0, seed + 1.0)))
                top = max(top, ridge + bump)
        bottom = base_y - 4.0
        verts.append(B((x, top, z)))
        verts.append(B((x, bottom, z)))
        along = math.radians(phi) * radius
        uvs.append((along, 0.0))
        uvs.append((along, top - bottom))
    faces = []
    for k in range(steps):
        a = k * 2
        faces.append((a, a + 1, a + 3, a + 2))
    bm = _bm_from(verts, faces, uvs)
    bld.add(name, bm, slot, var=0.5)


def tree(bld, name, foot, height, crown, seed=0.0, leaf_slot="LEAF", clumps=None):
    """A painterly tree: a forked trunk, branches, and a crown of many lumpy
    clumps (the outline breaks up like leaves, not a ball)."""
    f = Vector(foot)
    rng = random.Random(int(seed * 1000) + 3)
    path = [tuple(f + Vector((0.06 * math.sin(i + seed), height * 0.55 * i / 4, 0.05 * math.cos(i * 1.3 + seed)))) for i in range(5)]
    bm, _ = tube(path, [crown * 0.09, crown * 0.07, crown * 0.06, crown * 0.05, crown * 0.04], segs=7, caps=False, wobble=0.12, seed=seed)
    bld.add(name, bm, "BARK")
    tips = []
    for k in range(4):
        a = rng.uniform(0, math.tau)
        b0 = f + Vector((0, height * rng.uniform(0.35, 0.5), 0))
        b1 = f + Vector((math.cos(a) * crown * 0.6, height * rng.uniform(0.62, 0.8), math.sin(a) * crown * 0.6))
        bm, _ = tube([tuple(b0), tuple(b0.lerp(b1, 0.5) + Vector((0, 0.15, 0))), tuple(b1)], [crown * 0.04, crown * 0.03, crown * 0.018], segs=5, caps=False)
        bld.add(name, bm, "BARK")
        tips.append(b1)
    centre = f + Vector((0, height * 0.72, 0))
    count = clumps or 16
    for k in range(count):
        # clumps on an ellipsoid shell about the crown's centre, more on top
        u = rng.uniform(-0.35, 1.0)
        a = rng.uniform(0, math.tau)
        rr = math.sqrt(max(0.0, 1.0 - u * u))
        c = centre + Vector((math.cos(a) * rr * crown, u * crown * 0.62, math.sin(a) * rr * crown))
        sc = crown * rng.uniform(0.26, 0.4)
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
        for v in bm.verts:
            n = v.co.copy()
            d = 1.0 + 0.22 * _fractal(n * 2.6 + Vector((seed + k, k, 0)), 0.8, 2.0, 3)
            v.co = n * sc * d
            v.co.z *= 0.78
        bmesh.ops.transform(bm, matrix=Matrix.Translation(B(c)), verts=bm.verts)
        bm.normal_update()
        bld.add(name, bm, leaf_slot, var=rng.uniform(0.3, 0.7))


def shrub(bld, name, foot, size, seed=0.0, slot="LEAF"):
    """A low bush: a cluster of small leaf clumps, its outline broken."""
    rng = random.Random(int(seed * 1000) + 11)
    f = Vector(foot)
    for k in range(9):
        a = rng.uniform(0, math.tau)
        rr = size * rng.uniform(0.0, 0.75)
        c = f + Vector((math.cos(a) * rr, size * rng.uniform(0.25, 0.75) * (1.0 - rr / (size * 1.2)), math.sin(a) * rr))
        sc = size * rng.uniform(0.28, 0.42)
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0)
        for v in bm.verts:
            n = v.co.copy()
            v.co = n * sc * (1.0 + 0.3 * _noise(n * 2.0 + Vector((seed, k, 0))))
        bmesh.ops.transform(bm, matrix=Matrix.Translation(B(c)), verts=bm.verts)
        bm.normal_update()
        bld.add(name, bm, slot, var=rng.uniform(0.2, 0.8))


def shield(bld, name, centre, normal, r, slot="SHIELD_A", boss_slot="WOOD"):
    """A round hide-and-wood shield hung on a wall, its face toward `normal`
    (game coords); its face carries the painted motif (UV: turn, radius)."""
    prof = [(r * i / 9.0, 0.01 + 0.035 * (i / 9.0) ** 2) for i in range(10)]
    sh = lathe(prof, segs=28, at=(0, 0, 0), cap_bottom=False)
    thicken(sh, 0.025)
    n = Vector(normal).normalized()
    # the lathe's axis is the game's +y; turn it to point along `normal`
    q = Vector((0, 1, 0)).rotation_difference(n)
    m = Matrix.Translation(B(tuple(Vector(centre)))) @ _game_rot(q)
    bmesh.ops.transform(sh, matrix=m, verts=sh.verts)
    sh.normal_update()
    bld.add(name, sh, slot)
    rock(bld, name, tuple(Vector(centre) + n * 0.06), (r * 0.2, r * 0.2, r * 0.12), seed=r * 7, slot=boss_slot, subdiv=1)


def _game_rot(q):
    """A rotation given in the game's frame, as a Blender-frame matrix."""
    conv = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))
    return (conv @ q.to_matrix() @ conv.inverted()).to_4x4()


def hanging(bld, name, top_left, top_right, drop, seed=0.0, slot="WEAVE_A", sag=0.03, fringe=True):
    """A woven hanging from a pole: it falls in soft folds; the shader weaves
    its bands from UV (u across, v down from the pole)."""
    a = Vector(top_left)
    b = Vector(top_right)
    nrm = Vector((-(b - a).z, 0.0, (b - a).x)).normalized()

    def f(u, v):
        p = a.lerp(b, u)
        fold = 0.035 * math.sin(u * math.pi * 7.0 + seed) * (0.4 + 0.6 * v)
        q = p + nrm * (fold + 0.02 * v) - Vector((0, drop * v + sag * math.sin(u * math.pi) * (1 - v), 0))
        return B(q)

    bm = sheet(14, 4, f)
    thicken(bm, 0.01)
    bld.add(name, bm, slot)
    log_piece(bld, name, tuple(a - (b - a).normalized() * 0.12 + Vector((0, 0.03, 0))), tuple(b + (b - a).normalized() * 0.12 + Vector((0, 0.03, 0))), 0.022, seed=seed + 3, slot="WOOD", knots=False, bend=0.0, stubs=0)
    if fringe:
        for k in range(12):
            u = (k + 0.5) / 12
            p = a.lerp(b, u) + nrm * (0.035 * math.sin(u * math.pi * 7.0 + seed) + 0.02) - Vector((0, drop, 0))
            cord(bld, name, tuple(p), tuple(p - Vector((0, 0.07, 0))), r=0.006, sag=0.0, slot="CORD")


# --- ambient occlusion and colour attributes -------------------------------------------

def write_colors(objs, ao=None):
    """COLOR_0 from the per-vertex wear/var attributes and the AO (dict obj->array)."""
    for obj in objs:
        me = obj.data
        n = len(me.vertices)
        wear = np.zeros(n, dtype=np.float32)
        var = np.full(n, 0.5, dtype=np.float32)
        if "wear" in me.attributes:
            me.attributes["wear"].data.foreach_get("value", wear)
        if "var" in me.attributes:
            me.attributes["var"].data.foreach_get("value", var)
        aov = np.ones(n, dtype=np.float32) if ao is None or obj.name not in ao else ao[obj.name]
        if "Col" in me.color_attributes:
            me.color_attributes.remove(me.color_attributes["Col"])
        attr = me.color_attributes.new("Col", 'FLOAT_COLOR', 'POINT')
        vals = np.zeros(n * 4, dtype=np.float32)
        vals[0::4] = aov
        vals[1::4] = np.clip(wear, 0, 1)
        vals[2::4] = np.clip(var, 0, 1)
        vals[3::4] = 1.0
        attr.data.foreach_set("color", vals)
        me.color_attributes.active_color = attr
        me.color_attributes.render_color_index = me.color_attributes.find("Col")
        for k in ("wear", "var"):
            if k in me.attributes:
                me.attributes.remove(me.attributes[k])


def bake_ao(objs, distance=0.9, samples=24, strength=0.75, floor=0.32):
    """Cycles AO to vertex colours over all objects together (they shade each other)."""
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.device = 'CPU'
    sc.cycles.samples = samples
    if sc.world is None:
        sc.world = bpy.data.worlds.new("World")
    sc.world.light_settings.distance = distance
    out = {}
    for obj in objs:
        me = obj.data
        if "AO" in me.color_attributes:
            me.color_attributes.remove(me.color_attributes["AO"])
        a = me.color_attributes.new("AO", 'FLOAT_COLOR', 'POINT')
        me.color_attributes.active_color = a
    for o in bpy.context.selected_objects:
        o.select_set(False)
    for obj in objs:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    try:
        bpy.ops.object.bake(type='AO', target='VERTEX_COLORS', use_clear=True)
    except Exception as e:
        log("AO bake failed", e)
    for obj in objs:
        me = obj.data
        n = len(me.vertices)
        vals = np.zeros(n * 4, dtype=np.float32)
        me.color_attributes["AO"].data.foreach_get("color", vals)
        ao = np.clip(vals[0::4], 0.0, 1.0)
        out[obj.name] = floor + (1.0 - floor) * (1.0 - strength * (1.0 - ao ** 0.9))
        me.color_attributes.remove(me.color_attributes["AO"])
    return out


def export_glb(objs, path, extra_objs=()):
    for o in bpy.context.selected_objects:
        o.select_set(False)
    for o in list(objs) + list(extra_objs):
        o.select_set(True)
    bpy.context.view_layer.objects.active = list(objs)[0]
    bpy.ops.export_scene.gltf(
        filepath=path, export_format='GLB', use_selection=True, export_apply=False,
        export_yup=True, export_texcoords=True, export_normals=True, export_materials='EXPORT',
        export_vertex_color='ACTIVE', export_all_vertex_colors=False, export_extras=True,
        export_animations=False)


def clear_scene():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.armatures, bpy.data.actions):
        for d in list(coll):
            coll.remove(d)


def tri_count(objs):
    return sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objs)

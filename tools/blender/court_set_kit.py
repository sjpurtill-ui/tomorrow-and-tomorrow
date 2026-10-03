"""Pieces for the court sets (tools/blender/court_set.py).

Everything is authored in the game's frame (Godot: x right, y up, z toward
the god) and converted here to Blender's (x, -z, y), so the numbers in
court_set.py read the same as the marks Godot gets in court_sets.json.

Materials are named by slot (GROUND, BARK, WOOD, WOOD_END, CHAR, ASH, EMBER,
STONE, HIDE, HIDE_DARK, CORD, REED, THATCH, CLAY, MUD, PLANK, FOOD_ROOT,
FOOD_GRAIN, MEAT, FISH, BONE, OCHRE, FLINT, LEAF, GRASS, HILL_NEAR,
HILL_FAR); the game colours each slot for the era and the people.
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
    "HIDE_DARK": (0.40, 0.29, 0.20), "CORD": (0.36, 0.27, 0.18), "REED": (0.66, 0.56, 0.34),
    "THATCH": (0.58, 0.47, 0.28), "CLAY": (0.62, 0.38, 0.24), "MUD": (0.56, 0.44, 0.31),
    "PLANK": (0.50, 0.37, 0.24), "FOOD_ROOT": (0.60, 0.42, 0.25), "FOOD_GRAIN": (0.80, 0.66, 0.38),
    "MEAT": (0.48, 0.18, 0.13), "FISH": (0.62, 0.58, 0.48), "BONE": (0.86, 0.80, 0.68),
    "OCHRE": (0.66, 0.28, 0.14), "FLINT": (0.30, 0.30, 0.32), "LEAF": (0.30, 0.36, 0.20),
    "GRASS": (0.45, 0.48, 0.26), "HILL_NEAR": (0.47, 0.50, 0.38), "HILL_FAR": (0.58, 0.62, 0.60),
    "BERRY": (0.42, 0.10, 0.16), "BLANKET": (0.55, 0.32, 0.22), "SOOT": (0.30, 0.27, 0.24),
}


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
        m.use_nodes = True
        bsdf = m.node_tree.nodes.get("Principled BSDF")
        if bsdf is not None:
            bsdf.inputs["Base Color"].default_value = (c[0], c[1], c[2], 1.0)
            bsdf.inputs["Roughness"].default_value = 1.0
    return m


def log(*a):
    print("[court_set]", *a, flush=True)


class Builder:
    """Collects bmesh pieces per object name; each piece carries its slot."""

    def __init__(self, seed=7):
        self.rng = random.Random(seed)
        self.objects = {}   # name -> (bm, [slots])
        self.extras = {}    # name -> dict of custom props

    def bm(self, name):
        if name not in self.objects:
            self.objects[name] = (bmesh.new(), [])
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
        me = bpy.data.meshes.new("_tmp")
        src_bm.to_mesh(me)
        for p in me.polygons:
            p.material_index = idx
        # stash wear / variation in a float attribute pair, read back at the end
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

    def finish(self, collection=None, smooth_slots=()):
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
                p.use_smooth = slots[p.material_index] in smooth_slots if smooth_slots else True
            if name in self.extras:
                for k, v in self.extras[name].items():
                    obj[k] = v
            made[name] = obj
        self.objects = {}
        return made


# --- primitives (all return a bmesh in Blender coordinates) -------------------------

def _bm_from(verts, faces):
    bm = bmesh.new()
    vs = [bm.verts.new(v) for v in verts]
    for f in faces:
        try:
            bm.faces.new([vs[i] for i in f])
        except ValueError:
            pass
    bm.normal_update()
    return bm


def tube(path, radii, segs=10, caps=True, wobble=0.0, seed=0.0, twist=0.0, end_slot_cb=None):
    """A tube along `path` (game coords) with a radius per point. Returns
    (bm, cap_faces) where cap_faces are the two end polygons' indices."""
    pts = [B(p) for p in path]
    n = len(pts)
    verts = []
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
        frames.append((u, v))
        for k in range(segs):
            ang = 2 * math.pi * k / segs + twist * i
            r = radii[i]
            if wobble:
                r *= 1.0 + wobble * _noise(Vector((math.cos(ang) * 1.7, math.sin(ang) * 1.7, i * 0.9 + seed)))
            verts.append(pts[i] + (u * math.cos(ang) + v * math.sin(ang)) * r)
    faces = []
    for i in range(n - 1):
        for k in range(segs):
            a = i * segs + k
            b = i * segs + (k + 1) % segs
            faces.append((a, b, b + segs, a + segs))
    caps_idx = []
    if caps:
        faces.append(tuple(reversed(range(segs))))
        faces.append(tuple(range((n - 1) * segs, n * segs)))
        caps_idx = [len(faces) - 2, len(faces) - 1]
    bm = _bm_from(verts, faces)
    return bm, caps_idx


def split_caps(bm, count_tail=2):
    """Pull the last `count_tail` faces (the caps) into their own bmesh."""
    bm.faces.ensure_lookup_table()
    caps = [bm.faces[i] for i in range(len(bm.faces) - count_tail, len(bm.faces))]
    cap_bm = bmesh.new()
    for f in caps:
        vs = [cap_bm.verts.new(v.co) for v in f.verts]
        cap_bm.faces.new(vs)
    for f in caps:
        bm.faces.remove(f)
    cap_bm.normal_update()
    bm.normal_update()
    return cap_bm


def log_piece(bld, name, a, b, r, seed=0.0, segs=11, bend=0.04, slot="BARK", end_slot="WOOD_END", char=0.0, wear=0.0, knots=True):
    """A log from a to b (game coords): bark with a slight bend and lumps, cut ends."""
    a = Vector(a)
    b = Vector(b)
    steps = 7
    path = []
    radii = []
    side = Vector((-(b - a).z, 0.0, (b - a).x)).normalized() if abs((b - a).x) + abs((b - a).z) > 1e-4 else Vector((1, 0, 0))
    for i in range(steps):
        t = i / (steps - 1)
        p = a.lerp(b, t)
        p += side * math.sin(t * math.pi) * bend * (b - a).length
        p.y += math.sin(t * math.pi) * bend * 0.3 * (b - a).length
        path.append(tuple(p))
        rr = r * (1.0 + 0.08 * _noise(Vector((t * 3.0, seed, 0.3))) - 0.06 * t)
        if knots and 0.2 < t < 0.8 and abs(_noise(Vector((t * 9.0, seed * 2.0, 1.1)))) > 0.32:
            rr *= 1.07
        radii.append(rr)
    bm, _ = tube(path, radii, segs=segs, caps=True, wobble=0.07, seed=seed)
    cap = split_caps(bm)
    bld.add(name, bm, slot, wear=wear)
    bld.add(name, cap, end_slot, wear=wear)
    if char > 0:
        pass
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
    bm, _ = tube(path, radii, segs=segs, caps=True, wobble=0.06, seed=seed)
    bld.add(name, bm, slot, wear=wear)
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
    """A grid sheet; fn(u, v) -> Blender point. Returns bmesh."""
    verts = []
    for j in range(rows + 1):
        for i in range(cols + 1):
            verts.append(fn(i / cols, j / rows))
    faces = []
    w = cols + 1
    for j in range(rows):
        for i in range(cols):
            a = j * w + i
            faces.append((a, a + 1, a + 1 + w, a + w))
    return _bm_from(verts, faces)


def thicken(bm, t):
    bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=t)
    bm.normal_update()
    return bm


def hide_panel(bld, name, p0, p1, h0, h1, seed=0.0, slot="HIDE", sag=0.10, top=None):
    """A hide stretched between two stakes: lower edge h0, upper edge h1 above ground."""
    a = Vector(p0)
    b = Vector(p1)

    def f(u, v):
        p = a.lerp(b, u)
        y = h0 + (h1 - h0) * v
        bow = math.sin(u * math.pi) * sag * (0.6 + 0.4 * v)
        nrm = Vector((-(b - a).z, 0.0, (b - a).x)).normalized()
        ripple = 0.025 * _noise(Vector((u * 4.0 + seed, v * 3.0, seed)))
        edge = 0.0
        # ragged edges, a hide's outline is never straight
        if v > 0.95:
            edge = -0.05 * abs(_noise(Vector((u * 6.0, seed, 2.0))))
        q = p + nrm * (bow + ripple)
        q.y = y + edge - math.sin(u * math.pi) * 0.06 * v
        return B(q)

    bm = sheet(8, 4, f)
    thicken(bm, 0.012)
    bld.add(name, bm, slot)


def disc_fn(r, segs, fn):
    verts = [fn(0.0, 0.0)]
    for k in range(segs):
        ang = 2 * math.pi * k / segs
        verts.append(fn(math.cos(ang) * r, math.sin(ang) * r))
    faces = [(0, 1 + k, 1 + (k + 1) % segs) for k in range(segs)]
    return _bm_from(verts, faces)


def lathe(profile, segs=14, at=(0, 0, 0), wobble=0.0, seed=0.0, cap_bottom=True):
    """Surface of revolution: profile [(radius, height)...] bottom to top (game coords)."""
    base = Vector(at)
    verts = []
    n = len(profile)
    for i, (r, h) in enumerate(profile):
        for k in range(segs):
            ang = 2 * math.pi * k / segs
            rr = r * (1.0 + wobble * _noise(Vector((math.cos(ang), math.sin(ang), h * 3.0 + seed))))
            verts.append(B(base + Vector((math.cos(ang) * rr, h, math.sin(ang) * rr))))
    faces = []
    for i in range(n - 1):
        for k in range(segs):
            a = i * segs + k
            b = i * segs + (k + 1) % segs
            faces.append((a, a + segs, b + segs, b))
    if cap_bottom:
        faces.append(tuple(range(segs)))
    return _bm_from(verts, faces)


def basket(bld, name, at, r, h, seed=0.0, slot="REED"):
    """An open woven basket (lathe with a rim roll)."""
    prof = [(r * 0.72, 0.0), (r * 0.92, h * 0.15), (r, h * 0.55), (r * 1.04, h * 0.92), (r * 1.08, h), (r * 0.98, h * 1.02), (r * 0.94, h * 0.9)]
    bm = lathe(prof, segs=14, at=at, wobble=0.03, seed=seed)
    bld.add(name, bm, slot)


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


def strip(bld, name, top, length, width, seed=0.0, slot="MEAT"):
    """A strip of drying meat or a split fish hanging from a rack bar."""
    t = Vector(top)

    def f(u, v):
        x = (u - 0.5) * width * (1.0 - 0.3 * v)
        y = -v * length
        z = 0.02 * math.sin(v * 3.0 + seed) + 0.01 * _noise(Vector((u * 3, v * 3, seed)))
        return B(t + Vector((x, y, z)))

    bm = sheet(2, 4, f)
    thicken(bm, 0.012)
    bld.add(name, bm, slot)


def spear(bld, name, butt, tip, seed=0.0, head_slot="FLINT", shaft_slot="WOOD", r=0.016, head=0.16, binding=True):
    a = Vector(butt)
    b = Vector(tip)
    d = (b - a).normalized()
    shaft_end = b - d * head
    path = [tuple(a.lerp(shaft_end, i / 4)) for i in range(5)]
    bm, _ = tube(path, [r * 0.9, r, r, r, r * 0.95], segs=6, caps=True)
    bld.add(name, bm, shaft_slot)
    # a leaf-shaped head (flattened diamond)
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
        bm, _ = tube(pb, [r * 1.5, r * 1.4], segs=6, caps=True)
        bld.add(name, bm, "CORD")


def cord(bld, name, a, b, r=0.008, sag=0.05, slot="CORD"):
    a = Vector(a)
    b = Vector(b)
    path = []
    for i in range(6):
        t = i / 5
        p = a.lerp(b, t)
        p.y -= math.sin(t * math.pi) * sag
        path.append(tuple(p))
    bm, _ = tube(path, [r] * 6, segs=5, caps=False)
    bld.add(name, bm, slot)


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
    # border loop of the square, counter-clockwise
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
            x = math.cos(ang) * rad
            z = math.sin(ang) * rad
            # blend from the square's own point outward
            q = Vector((x, 0, z))
            if ring == 1:
                q = p.lerp(q, 0.5) if p.length < rad else q
            cur.append(len(verts))
            verts.append(B((q.x, height_fn(q.x, q.z), q.z)))
        m = len(prev)
        for k in range(m):
            faces.append((prev[k], cur[k], cur[(k + 1) % m], prev[(k + 1) % m]))
        prev = cur
        prev_pts = [Vector(G(verts[k])) for k in cur]
    bm = _bm_from(verts, faces)
    # trodden earth where people walk and sit
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
        blades = rng.randint(4, 7)
        bm = bmesh.new()
        for k in range(blades):
            a = rng.random() * math.tau
            lean = rng.uniform(0.15, 0.45)
            bx = math.cos(a)
            bz = math.sin(a)
            w = 0.025
            p0 = Vector((x + bx * 0.03, 0.0, z + bz * 0.03))
            tip = Vector((x + bx * lean * h, h * rng.uniform(0.75, 1.1), z + bz * lean * h))
            side = Vector((-bz, 0, bx)) * w
            vs = [bm.verts.new(B(p0 - side)), bm.verts.new(B(p0 + side)), bm.verts.new(B(tip))]
            bm.faces.new(vs)
        bm.normal_update()
        bld.add(name, bm, slot, var=rng.random())
        made += 1


def hill_band(bld, name, radius, base_y, heights, segs, seed=0.0, slot="HILL_FAR", depth=6.0):
    """A ring of hill silhouettes far off (a band of quads with a noisy top)."""
    verts = []
    faces = []
    for k in range(segs + 1):
        ang = 2 * math.pi * k / segs
        x = math.cos(ang) * radius
        z = math.sin(ang) * radius
        h = heights[0] + (heights[1] - heights[0]) * (0.5 + 0.5 * _fractal(Vector((math.cos(ang) * 2.0 + seed, math.sin(ang) * 2.0, seed)), 0.7, 2.0, 4))
        xo = math.cos(ang) * (radius + depth)
        zo = math.sin(ang) * (radius + depth)
        verts.append(B((x, base_y, z)))
        verts.append(B((x, base_y + h * 0.7, z)))
        verts.append(B((xo, base_y + h, zo)))
    for k in range(segs):
        a = k * 3
        b = (k + 1) * 3
        faces.append((a, b, b + 1, a + 1))
        faces.append((a + 1, b + 1, b + 2, a + 2))
    bm = _bm_from(verts, faces)
    bld.add(name, bm, slot, var=0.5)


def tree(bld, name, foot, height, crown, seed=0.0):
    """A painterly tree: a trunk and a few lumpy crown masses."""
    f = Vector(foot)
    path = [tuple(f + Vector((0.05 * math.sin(i + seed), height * 0.6 * i / 4, 0.04 * math.cos(i * 1.3 + seed)))) for i in range(5)]
    bm, _ = tube(path, [0.16, 0.12, 0.10, 0.08, 0.06], segs=7, caps=False, wobble=0.1, seed=seed)
    bld.add(name, bm, "BARK")
    rng = random.Random(int(seed * 1000) + 3)
    # branches up into the crown
    for k in range(3):
        a = rng.uniform(0, math.tau)
        b0 = f + Vector((0, height * 0.42, 0))
        b1 = f + Vector((math.cos(a) * crown * 0.55, height * 0.68, math.sin(a) * crown * 0.55))
        bm, _ = tube([tuple(b0), tuple(b0.lerp(b1, 0.5) + Vector((0, 0.15, 0))), tuple(b1)], [0.07, 0.05, 0.03], segs=5, caps=False)
        bld.add(name, bm, "BARK")
    for k in range(7):
        ang = k / 7 * math.tau + rng.uniform(-0.3, 0.3)
        rad = crown * (0.15 if k == 0 else rng.uniform(0.35, 0.7))
        c = f + Vector((math.cos(ang) * rad, height * (0.88 if k == 0 else rng.uniform(0.62, 0.82)), math.sin(ang) * rad))
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
        sc = crown * (0.62 if k == 0 else rng.uniform(0.38, 0.55))
        for v in bm.verts:
            n = v.co.copy()
            d = 1.0 + 0.32 * _fractal(n * 2.1 + Vector((seed + k, k, 0)), 0.8, 2.0, 3)
            v.co = n * sc * d
            v.co.z *= 0.72
            if v.co.z < -sc * 0.35:
                v.co.z = -sc * 0.35 + (v.co.z + sc * 0.35) * 0.3
        bmesh.ops.transform(bm, matrix=Matrix.Translation(B(c)), verts=bm.verts)
        bm.normal_update()
        bld.add(name, bm, "LEAF")


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
        export_yup=True, export_texcoords=False, export_normals=True, export_materials='EXPORT',
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

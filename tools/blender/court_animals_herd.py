"""The court's bigger beasts, for the executions (EXECUTIONS.md): pigs (act 9),
cattle and oxen (acts 7, 8, 12), the bear (act 17) and the elephant (act 18).
tools/blender/court_animals.py runs them ("--species pig,cattle,bear,elephant").

Each is built like the goat: modelled in the dog's frame (cf_sdf), bound to
the dog's skeleton and region (with its own exceptions: a snout, a trunk, big
ears), then the whole stretched by its SCALE to its own size, so the dog's
posing helpers serve it. Clips, each beast its own:
  pig       idle (rooting), walk, trot, eat (a frenzy), squeal
  cattle    idle (chewing), walk, gallop (a stampede), pull (into the yoke),
            shake_hoof, look
  bear      idle, walk (a lumber), rear, gulp, burp, spit
  elephant  idle (ears fanning), walk, stomp, shake_foot, trumpet
"""
import math

import bpy
from mathutils import Vector, Quaternion, Matrix
from mathutils.noise import noise as _noise

import cf_sdf as S


def A():
    import court_animals as mod
    return mod


def _stretch(objs, scale):
    for o in objs:
        o.data.transform(o.matrix_world)
        o.matrix_world = Matrix.Identity(4)
        for v in o.data.vertices:
            v.co = Vector((v.co.x * scale[0], v.co.y * scale[1], v.co.z * scale[2]))


def _scaled_bones(scale):
    out = {}
    for name, (h, t, parent, deform) in A().dog_bones().items():
        out[name] = (tuple(h[i] * scale[i] for i in range(3)), tuple(t[i] * scale[i] for i in range(3)), parent, deform)
    return out


def _s(p, scale):
    out = {}
    for b, e in p.items():
        e2 = dict(e)
        if "loc" in e2:
            e2["loc"] = tuple(e2["loc"][i] * scale[i] for i in range(3))
        out[b] = e2
    return out


def _eyes(extras, at, r, slot="EYE", shine=True):
    for s in (-1, 1):
        c = Vector((s * at[0], at[1], at[2]))
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=r, location=c)
        e = bpy.context.active_object
        e.name = "Eye.%s" % ("L" if s > 0 else "R")
        e.data.materials.append(A().material(slot))
        extras.append(e)
        if shine:
            bpy.ops.mesh.primitive_uv_sphere_add(segments=6, ring_count=4, radius=r * 0.32, location=c + Vector((s * r * 0.35, -r * 0.75, r * 0.4)))
            g = bpy.context.active_object
            g.name = "Shine.%s" % ("L" if s > 0 else "R")
            g.data.materials.append(A().material("EYE_SHINE"))
            extras.append(g)


def _tube_mesh(name, pts, radii, slot, voxel=0.004, tris=300):
    lo = [min(p[i] - 0.05 for p in pts) for i in range(3)]
    hi = [max(p[i] + 0.05 for p in pts) for i in range(3)]
    f = S.Field(tuple(lo), tuple(hi), voxel)
    for i in range(len(pts) - 1):
        f.union(S.RoundCone(tuple(pts[i]), tuple(pts[i + 1]), radii[i], radii[i + 1]), 0.006)
    o = f.mesh(name)
    S.finish_mesh(o, target_tris=tris, smooth=1)
    o.data.materials.append(A().material(slot))
    return o


def _paint(body, slots, slot_fn):
    me = body.data
    for slot in slots:
        me.materials.append(A().material(slot))
    order = {s: i for i, s in enumerate(slots)}
    for p in me.polygons:
        p.material_index = order[slot_fn(tuple(p.center), tuple(p.normal))]


def _patches(x, y, z, k=1.0):
    return _noise(Vector((x * 9.0 * k + 3.0, y * 7.0 * k, z * 8.0 * k))) + 0.4 * _noise(Vector((x * 22.0, y * 20.0, z * 18.0)))


# =====================================================================================
# The pig: a long round barrel on short legs, a snout with a flat disc nose,
# flappy ears forward over the eyes, a curly tail.

PIG_SCALE = (1.3, 1.15, 1.2)


def pig_field(voxel):
    f = S.Field((-0.22, -0.66, -0.02), (0.22, 0.48, 0.66), voxel)
    f.union(S.Ellipsoid((0, -0.03, 0.39), (0.15, 0.33, 0.15)), 0.0)
    f.union(S.Ellipsoid((0, 0.2, 0.39), (0.135, 0.13, 0.14)), 0.05)
    f.union(S.Ellipsoid((0, -0.22, 0.40), (0.13, 0.11, 0.14)), 0.05)
    # the head, low and heavy, the snout out in front
    f.union(S.Ellipsoid((0, -0.37, 0.44), (0.09, 0.1, 0.095)), 0.05)
    f.union(S.RoundCone((0, -0.42, 0.42), (0, -0.55, 0.40), 0.062, 0.048), 0.03)
    f.union(S.Ellipsoid((0, -0.565, 0.40), (0.05, 0.014, 0.042)), 0.01)
    for s in (-1, 1):
        q = Quaternion((1, 0, 0), math.radians(-35)) @ Quaternion((0, 1, 0), math.radians(s * 25))
        f.union(S.Ellipsoid((s * 0.06, -0.39, 0.53), (0.045, 0.012, 0.055), rot=q), 0.012)
    for s in (-0.075, 0.075):
        f.union(S.RoundCone((s, -0.19, 0.33), (s, -0.2, 0.07), 0.04, 0.026), 0.03)
        f.union(S.Ellipsoid((s, -0.205, 0.03), (0.024, 0.03, 0.032)), 0.01)
        f.union(S.RoundCone((s, 0.2, 0.33), (s, 0.21, 0.07), 0.045, 0.026), 0.03)
        f.union(S.Ellipsoid((s, 0.215, 0.03), (0.024, 0.03, 0.032)), 0.01)
    # a curl of a tail
    pts = [(0, 0.33, 0.44)]
    for k in range(1, 7):
        t = k / 6 * math.pi * 1.6
        pts.append((0.025 * math.sin(t), 0.36 + 0.025 * (1 - math.cos(t)), 0.46 + 0.012 * k))
    for i in range(len(pts) - 1):
        f.union(S.RoundCone(pts[i], pts[i + 1], 0.011, 0.009), 0.006)
    return f


def pig_slot(c, n):
    x, y, z = c
    if y < -0.555 and n[1] < -0.4:
        return "NOSE"
    if z < 0.05:
        return "HOOF"
    return "COAT_DARK" if _patches(x, y, z, 1.2) > 0.32 else "COAT"


def pig_region(P):
    import numpy as np
    P = np.asarray(P) / np.asarray(PIG_SCALE)
    out = []
    base = A().dog_region(P)
    for i, (x, y, z) in enumerate(P):
        if y < -0.3 and z > 0.3:
            out.append(["jaw", "head"] if (y < -0.45 and z < 0.4) else ["head", "neck"])
        elif y > 0.31 and z > 0.4:
            out.append(["tail1", "tail2", "pelvis"])
        else:
            out.append(base[i])
    return out


def pig_idle(t):
    a = A()
    p = a.merge(a.d_breath(t, 1.6, 0.6), a.d_ears(t, (0.7, 2.1), side="L"))
    root = a.wave(t, 0.9)
    a.add(p, "neck", rot=(30 + 6 * root, 0, 8 * a.wave(t, 2.4)))
    a.add(p, "head", rot=(14, 0, 4 * a.wave(t, 0.45)))
    a.add(p, "jaw", rot=(3 * abs(a.wave(t, 0.3)), 0, 0))
    a.add(p, "tail1", rot=(0, 0, 20 * a.wave(t, 0.35)))
    return p


def pig_eat(t):
    """A feeding frenzy: head down, jerking and chomping, the tail going."""
    a = A()
    p = a.d_breath(t, 0.5, 0.8)
    a.add(p, "neck", rot=(42 + 10 * a.wave(t, 0.22), 0, 14 * a.wave(t, 0.5)))
    a.add(p, "head", rot=(18 + 12 * a.wave(t, 0.17, 0.3), 0, 10 * a.wave(t, 0.29)))
    a.add(p, "jaw", rot=(16 * abs(a.wave(t, 0.14)), 0, 0))
    a.add(p, "chest", rot=(5, 0, 4 * a.wave(t, 0.4)))
    a.add(p, "tail1", rot=(0, 0, 30 * a.wave(t, 0.12)))
    for side in ("L", "R"):
        a.add(p, "upperarm." + side, rot=(-6 + 4 * a.wave(t, 0.33, 0.5 if side == "L" else 0.0), 0, 0))
    return p


def pig_squeal(t):
    a = A()
    k = a.env(t, 0.0, 0.1, 0.8, 1.0)
    p = a.d_breath(t, 0.6, 0.8)
    a.add(p, "neck", rot=(-24 * k, 0, 0))
    a.add(p, "head", rot=(-14 * k, 0, 6 * a.wave(t, 0.08) * k))
    a.add(p, "jaw", rot=(20 * k, 0, 0))
    a.add(p, "ear.L", rot=(28 * k, 0, 0))
    a.add(p, "ear.R", rot=(28 * k, 0, 0))
    a.add(p, "tail1", rot=(0, 0, 40 * a.wave(t, 0.1)))
    return p


def pig_walk(t):
    a = A()
    p = a.d_gait(t, 0.6, {("L", False): 0.0, ("L", True): 0.25, ("R", False): 0.5, ("R", True): 0.75}, 24.0, 30.0, 0.01, 4.0, 6.0)
    a.add(p, "neck", rot=(18, 0, 0))
    return p


def pig_trot(t):
    a = A()
    p = a.d_gait(t, 0.36, {("L", True): 0.0, ("R", False): 0.0, ("R", True): 0.5, ("L", False): 0.5}, 32.0, 40.0, 0.02, 5.0, 10.0)
    a.add(p, "neck", rot=(10, 0, 0))
    return p


PIG = {
    "scale": PIG_SCALE, "field": pig_field, "slots": ("COAT", "COAT_DARK", "NOSE", "HOOF"), "slot": pig_slot,
    "region": pig_region, "tris": 5200, "height": 0.7, "eyes": ((0.055, -0.43, 0.49), 0.011),
    "clips": {"idle": (2.7, pig_idle), "walk": (0.6, pig_walk), "trot": (0.36, pig_trot), "eat": (1.32, pig_eat), "squeal": (1.0, pig_squeal)},
    "loops": {"idle", "walk", "trot", "eat"}, "speeds": {"walk": 0.7, "trot": 1.9},
}


# =====================================================================================
# Cattle (and oxen: the same beast in a yoke): a deep barrel on long thin
# legs, a dewlap, a long face and a wet dark muzzle, horns, a tufted tail.

CATTLE_SCALE = (2.9, 2.55, 2.6)


def cattle_field(voxel):
    f = S.Field((-0.2, -0.62, -0.02), (0.2, 0.45, 0.64), voxel)
    f.union(S.Ellipsoid((0, -0.03, 0.40), (0.12, 0.31, 0.135)), 0.0)
    f.union(S.Ellipsoid((0, 0.21, 0.42), (0.11, 0.1, 0.11)), 0.05)
    f.union(S.Ellipsoid((0, -0.2, 0.44), (0.105, 0.1, 0.12)), 0.05)
    f.union(S.Ellipsoid((0, -0.27, 0.32), (0.03, 0.05, 0.07)), 0.04)
    f.union(S.RoundCone((0, -0.24, 0.45), (0, -0.35, 0.5), 0.075, 0.055), 0.04)
    f.union(S.RoundCone((0, -0.37, 0.52), (0, -0.5, 0.43), 0.055, 0.042), 0.03)
    f.union(S.Ellipsoid((0, -0.37, 0.545), (0.055, 0.04, 0.035)), 0.02)
    f.union(S.Ellipsoid((0, -0.515, 0.415), (0.047, 0.035, 0.035)), 0.02)
    for s in (-1, 1):
        q = Quaternion((0, 0, 1), math.radians(s * 70))
        f.union(S.Ellipsoid((s * 0.068, -0.375, 0.525), (0.042, 0.012, 0.018), rot=q), 0.01)
    for s in (-0.068, 0.068):
        f.union(S.RoundCone((s, -0.19, 0.34), (s, -0.19, 0.2), 0.035, 0.02), 0.03)
        f.union(S.RoundCone((s, -0.19, 0.2), (s, -0.2, 0.05), 0.017, 0.015), 0.01)
        f.union(S.Ellipsoid((s, -0.205, 0.022), (0.02, 0.024, 0.025)), 0.008)
        f.union(S.RoundCone((s * 0.95, 0.2, 0.37), (s, 0.15, 0.21), 0.05, 0.022), 0.03)
        f.union(S.RoundCone((s, 0.15, 0.21), (s, 0.25, 0.1), 0.02, 0.015), 0.01)
        f.union(S.RoundCone((s, 0.25, 0.1), (s, 0.235, 0.03), 0.015, 0.015), 0.008)
        f.union(S.Ellipsoid((s, 0.225, 0.02), (0.02, 0.024, 0.024)), 0.008)
    f.union(S.RoundCone((0, 0.31, 0.47), (0, 0.345, 0.2), 0.012, 0.007), 0.01)
    f.union(S.Ellipsoid((0, 0.35, 0.18), (0.016, 0.016, 0.035)), 0.006)
    return f


def cattle_slot(c, n):
    x, y, z = c
    if y < -0.5 and z < 0.45:
        return "NOSE"
    if z < 0.045:
        return "HOOF"
    pat = _patches(x, y, z, 0.8)
    if pat > 0.3:
        return "COAT_DARK"
    if y < -0.48 or (z < 0.3 and y < -0.25 and y > -0.32):
        return "COAT_LIGHT"
    return "COAT"


def cattle_region(P):
    import numpy as np
    P = np.asarray(P) / np.asarray(CATTLE_SCALE)
    out = []
    base = A().dog_region(P)
    for i, (x, y, z) in enumerate(P):
        if y < -0.34 and z > 0.36:
            out.append(["head", "neck"])
        elif y > 0.3 and z < 0.47 and abs(x) < 0.03:
            out.append(["tail1", "pelvis"])
        else:
            out.append(base[i])
    return out


def cattle_extras(extras):
    for s in (-1, 1):
        pts = [(s * 0.04, -0.37, 0.56), (s * 0.085, -0.36, 0.575), (s * 0.11, -0.35, 0.61), (s * 0.115, -0.36, 0.645)]
        h = _tube_mesh("Horn.%s" % ("L" if s > 0 else "R"), pts, [0.013, 0.011, 0.008, 0.003], "HORN")
        extras.append(h)


def cattle_idle(t):
    a = A()
    p = a.merge(a.d_breath(t, 2.6, 0.8), a.d_ears(t, (1.1, 3.0), side="L"))
    a.add(p, "jaw", rot=(3 * (0.5 + 0.5 * a.wave(t, 0.8)), 0, 5 * a.wave(t, 0.8, 0.25)))
    look = a.env(t, 1.0, 1.6, 2.8, 3.4)
    a.add(p, "neck", rot=(6, 0, 14 * look))
    a.add(p, "tail1", rot=(0, 0, 14 * a.wave(t, 1.3)))
    return p


def cattle_walk(t):
    a = A()
    p = a.d_gait(t, 1.2, {("L", False): 0.0, ("L", True): 0.25, ("R", False): 0.5, ("R", True): 0.75}, 20.0, 26.0, 0.006, 3.0, 3.0)
    a.add(p, "neck", rot=(8, 0, 0))
    return p


def cattle_gallop(t):
    """A stampede: a rolling gallop, head low and tossing."""
    a = A()
    per = 0.5
    p = a.d_gait(t, per, {("L", False): 0.0, ("R", False): 0.08, ("L", True): 0.45, ("R", True): 0.55}, 44.0, 50.0, 0.03, 8.0, 10.0)
    a.add(p, "pelvis", rot=(6 * a.wave(t, per), 0, 0))
    a.add(p, "neck", rot=(14 + 8 * a.wave(t, per, 0.25), 0, 0))
    a.add(p, "tail1", rot=(-30, 0, 10 * a.wave(t, per)))
    return p


def cattle_pull(t):
    """Leaning into a yoke: head low, slow heavy steps, braced."""
    a = A()
    p = a.d_gait(t, 1.6, {("L", False): 0.0, ("L", True): 0.25, ("R", False): 0.5, ("R", True): 0.75}, 16.0, 20.0, 0.004, 2.0, 2.0)
    a.add(p, "chest", rot=(10, 0, 0))
    a.add(p, "neck", rot=(22, 0, 0))
    a.add(p, "head", rot=(-12, 0, 0))
    return p


def cattle_shake_hoof(t):
    """Something underfoot: up comes a forefoot and shakes, then down."""
    a = A()
    k = a.env(t, 0.0, 0.25, 1.1, 1.4)
    p = a.d_breath(t, 1.4, 0.5)
    a.add(p, "upperarm.R", rot=(-35 * k, 0, 0))
    a.add(p, "forearm.R", rot=(-60 * k, 0, 0))
    a.add(p, "fpaw.R", rot=((40 + 25 * a.wave(t, 0.12)) * k, 0, 10 * a.wave(t, 0.09) * k))
    a.add(p, "neck", rot=(18 * k, 0, -10 * k))
    a.add(p, "head", rot=(10 * k, 0, 0))
    a.add(p, "pelvis", rot=(0, -3 * k, 0))
    return p


def cattle_look(t):
    a = A()
    k = a.sm(t / 0.4)
    p = a.d_breath(t, 1.8, 0.4)
    a.add(p, "neck", rot=(-20 * k, 0, 0))
    a.add(p, "head", rot=(-10 * k, 0, 6 * k))
    return p


CATTLE = {
    "scale": CATTLE_SCALE, "field": cattle_field, "slots": ("COAT", "COAT_DARK", "COAT_LIGHT", "NOSE", "HOOF"), "slot": cattle_slot,
    "region": cattle_region, "tris": 6400, "height": 1.45, "eyes": ((0.05, -0.41, 0.515), 0.009), "extras": cattle_extras,
    "clips": {"idle": (3.4, cattle_idle), "walk": (1.2, cattle_walk), "gallop": (0.5, cattle_gallop), "pull": (1.6, cattle_pull),
              "shake_hoof": (1.4, cattle_shake_hoof), "look": (0.6, cattle_look)},
    "loops": {"idle", "walk", "gallop", "pull"}, "speeds": {"walk": 1.1, "gallop": 5.5, "pull": 0.6},
}


# =====================================================================================
# The bear: a heavy hump-shouldered body on thick legs, a broad round head
# with a short muzzle and round ears; it rears, swallows, burps and spits.

BEAR_SCALE = (2.5, 2.25, 2.2)


def bear_field(voxel):
    f = S.Field((-0.24, -0.62, -0.02), (0.24, 0.42, 0.7), voxel)
    f.union(S.Ellipsoid((0, -0.04, 0.39), (0.155, 0.3, 0.16)), 0.0)
    f.union(S.Ellipsoid((0, 0.18, 0.39), (0.14, 0.14, 0.15)), 0.05)
    f.union(S.Ellipsoid((0, -0.18, 0.48), (0.12, 0.11, 0.09)), 0.05)
    f.union(S.RoundCone((0, -0.24, 0.45), (0, -0.34, 0.5), 0.09, 0.075), 0.05)
    f.union(S.Ellipsoid((0, -0.38, 0.52), (0.085, 0.085, 0.08)), 0.04)
    f.union(S.RoundCone((0, -0.42, 0.5), (0, -0.52, 0.47), 0.048, 0.034), 0.03)
    f.union(S.Sphere((0, -0.535, 0.475), 0.02), 0.01)
    for s in (-1, 1):
        f.union(S.Sphere((s * 0.06, -0.35, 0.6), 0.026), 0.015)
    for s in (-0.085, 0.085):
        f.union(S.RoundCone((s, -0.19, 0.38), (s, -0.2, 0.08), 0.06, 0.042), 0.04)
        f.union(S.Ellipsoid((s, -0.22, 0.03), (0.046, 0.058, 0.032)), 0.015)
        f.union(S.RoundCone((s, 0.2, 0.38), (s, 0.18, 0.2), 0.07, 0.045), 0.04)
        f.union(S.RoundCone((s, 0.18, 0.2), (s, 0.22, 0.06), 0.045, 0.04), 0.02)
        f.union(S.Ellipsoid((s, 0.2, 0.03), (0.046, 0.065, 0.032)), 0.015)
    f.union(S.Sphere((0, 0.31, 0.43), 0.03), 0.02)
    return f


def bear_slot(c, n):
    x, y, z = c
    if y < -0.52 and z > 0.45:
        return "NOSE"
    if y < -0.44 and z > 0.43:
        return "COAT_LIGHT"
    if z < 0.06:
        return "COAT_DARK"
    return "COAT_DARK" if _patches(x, y, z, 0.6) > 0.45 else "COAT"


def bear_region(P):
    import numpy as np
    P = np.asarray(P) / np.asarray(BEAR_SCALE)
    out = []
    base = A().dog_region(P)
    for i, (x, y, z) in enumerate(P):
        if y < -0.33 and z > 0.4:
            if y < -0.44 and z < 0.49:
                out.append(["jaw", "head"])
            elif z > 0.58 and abs(x) > 0.035:
                out.append(["ear." + ("L" if x > 0 else "R"), "head"])
            else:
                out.append(["head", "neck"])
        else:
            out.append(base[i])
    return out


def bear_idle(t):
    a = A()
    p = a.merge(a.d_breath(t, 2.2, 1.0), a.d_ears(t, (1.3,), side="R"))
    a.add(p, "neck", rot=(10, 0, 12 * a.wave(t, 3.2)))
    a.add(p, "head", rot=(-6 * a.env(t % 1.6, 0.1, 0.3, 0.5, 0.8), 0, 6 * a.wave(t, 1.6)))
    return p


def bear_walk(t):
    """A lumber: heavy, rolling, the head swinging low."""
    a = A()
    per = 1.1
    p = a.d_gait(t, per, {("L", False): 0.0, ("L", True): 0.25, ("R", False): 0.5, ("R", True): 0.75}, 22.0, 28.0, 0.01, 2.0, 2.0)
    a.add(p, "pelvis", rot=(0, 7 * a.wave(t, per), 0))
    a.add(p, "chest", rot=(0, -9 * a.wave(t, per), 0))
    a.add(p, "neck", rot=(12, 0, 10 * a.wave(t, per)))
    return p


def _rear_pose(k):
    """Up on its hind legs, forepaws raised (k 0..1)."""
    a = A()
    p = {}
    # (for the forward-pointing spine bones -x lifts the front; the hind legs
    # turn back the other way so the feet stay planted under it)
    a.add(p, "pelvis", loc=(0, 0.02 * k, 0.08 * k), rot=(-62 * k, 0, 0))
    a.add(p, "spine", rot=(-8 * k, 0, 0))
    a.add(p, "neck", rot=(40 * k, 0, 0))
    a.add(p, "head", rot=(14 * k, 0, 0))
    for side in ("L", "R"):
        a.add(p, "thigh." + side, rot=(62 * k, 0, 0))
        a.add(p, "upperarm." + side, rot=(-40 * k, 0, 18 * k * (1 if side == "L" else -1)))
        a.add(p, "forearm." + side, rot=(-30 * k, 0, 0))
    return p


def bear_rear(t):
    a = A()
    k = a.sm(min(1.0, t / 0.8))
    p = a.merge(_rear_pose(k), a.d_breath(t, 1.2, 0.8))
    a.add(p, "jaw", rot=(20 * a.env(t, 0.6, 0.9, 1.4, 1.7), 0, 0))
    return p


def bear_gulp(t):
    """Down it goes whole: head thrust forward, jaws wide, then up and swallow."""
    a = A()
    lunge = a.env(t, 0.0, 0.25, 0.45, 0.6)
    up = a.env(t, 0.55, 0.8, 1.3, 1.6)
    p = a.d_breath(t, 0.8, 0.6)
    a.add(p, "chest", rot=(10 * lunge, 0, 0))
    a.add(p, "neck", rot=(20 * lunge - 40 * up, 0, 0))
    a.add(p, "head", rot=(-10 * up, 0, 0))
    a.add(p, "jaw", rot=(38 * lunge + 6 * up * abs(a.wave(t, 0.18)), 0, 0))
    return p


def bear_burp(t):
    a = A()
    k = a.env(t, 0.15, 0.35, 0.8, 1.1)
    p = a.d_breath(t, 0.5, 1.0)
    a.add(p, "chest", rot=(-8 * k, 0, 0))
    a.add(p, "neck", rot=(-16 * k, 0, 0))
    a.add(p, "head", rot=(-14 * k, 0, 4 * a.wave(t, 0.1) * k))
    a.add(p, "jaw", rot=(30 * k, 0, 0))
    a.add(p, "ear.L", rot=(20 * k, 0, 0))
    a.add(p, "ear.R", rot=(20 * k, 0, 0))
    return p


def bear_spit(t):
    a = A()
    k = a.env(t, 0.0, 0.12, 0.3, 0.6)
    p = a.d_breath(t, 0.8, 0.5)
    a.add(p, "neck", rot=(14 * k, 0, 0))
    a.add(p, "head", rot=(18 * k, 0, 0))
    a.add(p, "jaw", rot=(26 * k, 0, 0))
    return p


BEAR = {
    "scale": BEAR_SCALE, "field": bear_field, "slots": ("COAT", "COAT_DARK", "COAT_LIGHT", "NOSE"), "slot": bear_slot,
    "region": bear_region, "tris": 6400, "height": 1.15, "eyes": ((0.038, -0.455, 0.545), 0.009),
    "clips": {"idle": (3.2, bear_idle), "walk": (1.1, bear_walk), "rear": (2.0, bear_rear), "gulp": (1.7, bear_gulp),
              "burp": (1.2, bear_burp), "spit": (0.7, bear_spit)},
    "loops": {"idle", "walk"}, "speeds": {"walk": 1.0},
}


# =====================================================================================
# The elephant: a vast body on pillar legs, a domed head, great ears that fan,
# a trunk hanging to the ground (it rides the head), tusks; it stomps.

ELE_SCALE = (5.0, 3.9, 5.0)


def ele_field(voxel):
    f = S.Field((-0.22, -0.62, -0.02), (0.22, 0.42, 0.74), voxel)
    f.union(S.Ellipsoid((0, -0.02, 0.45), (0.15, 0.29, 0.17)), 0.0)
    f.union(S.Ellipsoid((0, -0.2, 0.5), (0.13, 0.12, 0.15)), 0.06)
    f.union(S.Ellipsoid((0, -0.36, 0.56), (0.09, 0.085, 0.1)), 0.06)
    f.union(S.Ellipsoid((0, -0.38, 0.64), (0.07, 0.06, 0.05)), 0.04)
    trunk = [(0, -0.43, 0.52), (0, -0.48, 0.4), (0, -0.505, 0.28), (0, -0.51, 0.16), (0, -0.495, 0.07), (0, -0.47, 0.04)]
    rad = [0.04, 0.032, 0.026, 0.02, 0.016, 0.014]
    for i in range(len(trunk) - 1):
        f.union(S.RoundCone(trunk[i], trunk[i + 1], rad[i], rad[i + 1]), 0.02 if i == 0 else 0.008)
    for s in (-1, 1):
        q = Quaternion((0, 0, 1), math.radians(s * -20))
        f.union(S.Ellipsoid((s * 0.1, -0.31, 0.55), (0.014, 0.075, 0.1), rot=q), 0.015)
    for s in (-0.085, 0.085):
        f.union(S.RoundCone((s, -0.19, 0.38), (s, -0.19, 0.05), 0.06, 0.052), 0.04)
        f.union(S.Ellipsoid((s, -0.19, 0.025), (0.058, 0.058, 0.028)), 0.01)
        f.union(S.RoundCone((s, 0.18, 0.4), (s, 0.19, 0.05), 0.065, 0.052), 0.04)
        f.union(S.Ellipsoid((s, 0.19, 0.025), (0.058, 0.058, 0.028)), 0.01)
    f.union(S.RoundCone((0, 0.28, 0.48), (0, 0.31, 0.25), 0.012, 0.008), 0.01)
    return f


def ele_slot(c, n):
    x, y, z = c
    if z < 0.03:
        return "HOOF"
    return "COAT_DARK" if _patches(x, y, z, 0.7) > 0.4 else "COAT"


def ele_region(P):
    import numpy as np
    P = np.asarray(P) / np.asarray(ELE_SCALE)
    out = []
    base = A().dog_region(P)
    for i, (x, y, z) in enumerate(P):
        if abs(x) > 0.075 and -0.42 < y < -0.2 and z > 0.42:
            out.append(["ear." + ("L" if x > 0 else "R"), "head"])
        elif y < -0.4 and z < 0.56:
            out.append(["head"])
        elif y < -0.3 and z > 0.42:
            out.append(["head", "neck"])
        else:
            out.append(base[i])
    return out


def ele_extras(extras):
    for s in (-1, 1):
        pts = [(s * 0.035, -0.45, 0.47), (s * 0.045, -0.5, 0.42), (s * 0.05, -0.56, 0.42), (s * 0.045, -0.6, 0.45)]
        extras.append(_tube_mesh("Tusk.%s" % ("L" if s > 0 else "R"), pts, [0.011, 0.01, 0.008, 0.003], "TUSK"))


def _ears(p, t, amount=1.0):
    a = A()
    fan = 18 * amount * a.wave(t, 1.4)
    a.add(p, "ear.L", rot=(0, 0, fan))
    a.add(p, "ear.R", rot=(0, 0, -fan))


def ele_idle(t):
    a = A()
    p = a.d_breath(t, 3.0, 0.6)
    _ears(p, t)
    a.add(p, "neck", rot=(4, 0, 6 * a.wave(t, 4.2)))
    a.add(p, "head", rot=(4 * a.wave(t, 2.1), 0, 0))
    a.add(p, "tail1", rot=(0, 0, 14 * a.wave(t, 1.05)))
    return p


def ele_walk(t):
    a = A()
    p = a.d_gait(t, 1.8, {("L", False): 0.0, ("L", True): 0.25, ("R", False): 0.5, ("R", True): 0.75}, 16.0, 22.0, 0.004, 2.0, 2.0)
    _ears(p, t, 0.6)
    return p


def ele_stomp(t):
    """Up comes a great forefoot, held, then down: POP."""
    a = A()
    up = a.env(t, 0.1, 0.7, 1.0, 1.12)
    p = a.d_breath(t, 1.6, 0.6)
    a.add(p, "pelvis", rot=(-6 * up, 0, 0), loc=(0, 0, -0.01 * up))
    a.add(p, "upperarm.R", rot=(-55 * up, 0, 0))
    a.add(p, "forearm.R", rot=(-50 * up, 0, 0))
    a.add(p, "fpaw.R", rot=(30 * up, 0, 0))
    a.add(p, "neck", rot=(-14 * up, 0, 0))
    _ears(p, t, 1.0 + up)
    jolt = a.env(t, 1.1, 1.14, 1.2, 1.4)
    a.add(p, "chest", rot=(4 * jolt, 0, 0))
    return p


def ele_shake_foot(t):
    a = A()
    k = a.env(t, 0.0, 0.3, 1.4, 1.7)
    p = a.d_breath(t, 1.6, 0.5)
    a.add(p, "upperarm.R", rot=(-25 * k, 0, 0))
    a.add(p, "forearm.R", rot=(-40 * k, 0, 0))
    a.add(p, "fpaw.R", rot=((25 + 20 * a.wave(t, 0.14)) * k, 0, 12 * a.wave(t, 0.1) * k))
    a.add(p, "neck", rot=(16 * k, 0, -8 * k))
    _ears(p, t, 0.5)
    return p


def ele_trumpet(t):
    a = A()
    k = a.env(t, 0.0, 0.3, 1.2, 1.5)
    p = a.d_breath(t, 0.8, 1.0)
    a.add(p, "neck", rot=(-26 * k, 0, 0))
    a.add(p, "head", rot=(-24 * k, 0, 0))
    _ears(p, t * 3.0, 1.5 * k + 0.3)
    return p


ELEPHANT = {
    "scale": ELE_SCALE, "field": ele_field, "slots": ("COAT", "COAT_DARK", "HOOF"), "slot": ele_slot,
    "region": ele_region, "tris": 7000, "height": 3.1, "eyes": ((0.07, -0.41, 0.58), 0.007), "extras": ele_extras,
    "clips": {"idle": (4.2, ele_idle), "walk": (1.8, ele_walk), "stomp": (1.5, ele_stomp), "shake_foot": (1.7, ele_shake_foot),
              "trumpet": (1.5, ele_trumpet)},
    "loops": {"idle", "walk"}, "speeds": {"walk": 1.1},
}

SPECIES = {"pig": PIG, "cattle": CATTLE, "bear": BEAR, "elephant": ELEPHANT}


def make(species, quick):
    a = A()
    spec = SPECIES[species]
    a.clear()
    voxel = 0.011 if quick else 0.0075
    f = spec["field"](voxel)
    body = f.mesh(species.capitalize())
    S.finish_mesh(body, target_tris=spec["tris"], smooth=2)
    _paint(body, spec["slots"], spec["slot"])
    extras = []
    if "extras" in spec:
        spec["extras"](extras)
    e = spec["eyes"]
    _eyes(extras, e[0], e[1])
    scale = spec["scale"]
    _stretch([body] + extras, scale)
    bn = _scaled_bones(scale)
    rig = a.build_armature(bn, species.capitalize())
    a.bake_ao([body])
    for o in extras:
        a.ensure_color(o)
    a.bind(body, rig, bn, spec["region"])
    for o in extras:
        a.bind_rigid(o, rig, "head")
    clips = {n: (d, (lambda fn: (lambda t: _s(fn(t), scale)))(fn)) for n, (d, fn) in spec["clips"].items()}
    a.write_actions(rig, clips, spec["loops"])
    import os
    path = os.path.join(a.OUT, "court_%s.glb" % species)
    a.export(rig, [body] + extras, path)
    tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
    return {"glb": "court_%s.glb" % species, "triangles": tris, "height": spec["height"],
            "clips": {n: {"seconds": d, "loop": n in spec["loops"]} for n, (d, _) in spec["clips"].items()},
            "speeds": spec["speeds"]}

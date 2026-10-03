"""The court's goat (tools/blender/court_animals.py runs it): a piebald herd goat,
for peoples who keep animals (the 'dairy' era tag). It is built on the dog's
skeleton and modeller, stretched to a goat's height and length, so the dog's
binding and posing serve it; it has its own coat, horns, beard and clips:
idle (chewing the cud), graze, bleat, walk, startle (a jump and a stiff
stare at the god's wrath), lie, lie_idle, look, stand_up.
"""
import math

import bpy
from mathutils import Vector, Quaternion, Matrix
from mathutils.noise import noise as _noise

import cf_sdf as S

# the goat is the dog's frame stretched: across, along, up
SCALE = (1.12, 1.22, 1.42)


def A():
    import court_animals as mod
    return mod


def goat_field(voxel):
    f = S.Field((-0.2, -0.66, -0.02), (0.2, 0.5, 0.86), voxel)
    # a deep barrel of a body, no tucked waist; thin legs; a strong neck
    f.union(S.Ellipsoid((0, -0.13, 0.405), (0.11, 0.17, 0.125)), 0.0)
    f.union(S.RoundCone((0, -0.12, 0.40), (0, 0.19, 0.405), 0.118, 0.105), 0.05)
    f.union(S.Ellipsoid((0, 0.2, 0.41), (0.1, 0.11, 0.105)), 0.04)
    f.union(S.RoundCone((0, -0.22, 0.44), (0, -0.35, 0.58), 0.062, 0.045), 0.04)
    # a long face, the brow flat, the muzzle square
    f.union(S.Ellipsoid((0, -0.385, 0.6), (0.052, 0.07, 0.06)), 0.03)
    f.union(S.RoundCone((0, -0.41, 0.585), (0, -0.54, 0.535), 0.043, 0.03), 0.03)
    f.union(S.Sphere((0, -0.548, 0.532), 0.03), 0.015)
    for s in (-1, 1):
        # ears stick out sideways and droop a little
        q = Quaternion((0, 1, 0), math.radians(s * 75)) @ Quaternion((1, 0, 0), math.radians(18))
        f.union(S.Ellipsoid((s * 0.075, -0.38, 0.63), (0.04, 0.012, 0.018), rot=q), 0.012)
    for s in (-0.072, 0.072):
        f.union(S.RoundCone((s, -0.19, 0.36), (s, -0.19, 0.20), 0.036, 0.022), 0.03)
        f.union(S.RoundCone((s, -0.19, 0.20), (s, -0.2, 0.05), 0.019, 0.017), 0.012)
        f.union(S.Ellipsoid((s, -0.21, 0.025), (0.02, 0.026, 0.024)), 0.01)
        f.union(S.RoundCone((s * 0.95, 0.2, 0.37), (s, 0.15, 0.22), 0.05, 0.026), 0.03)
        f.union(S.RoundCone((s, 0.15, 0.22), (s, 0.25, 0.10), 0.022, 0.016), 0.012)
        f.union(S.RoundCone((s, 0.25, 0.10), (s, 0.235, 0.03), 0.016, 0.015), 0.01)
        f.union(S.Ellipsoid((s, 0.225, 0.022), (0.02, 0.026, 0.022)), 0.01)
    # a short tail held up
    f.union(S.RoundCone((0, 0.29, 0.45), (0, 0.33, 0.52), 0.025, 0.015), 0.015)
    # an udder-less, sturdy belly; a little dewlap
    f.union(S.Ellipsoid((0, -0.24, 0.36), (0.035, 0.04, 0.05)), 0.03)
    return f


def goat_slot(c, n):
    x, y, z = c
    if y < -0.535 and z > 0.5 and n[1] < -0.3:
        return "NOSE"
    if z < 0.045:
        return "HOOF"
    patch = _noise(Vector((x * 9.0 + 3.0, y * 7.0, z * 8.0))) + 0.4 * _noise(Vector((x * 22.0, y * 20.0, z * 18.0)))
    # a dark head and patches on a cream coat
    if y < -0.34 and z > 0.5:
        return "COAT_DARK" if (abs(x) > 0.02 or y > -0.45) else "COAT"
    return "COAT_DARK" if patch > 0.18 else "COAT"


def build(quick=False):
    voxel = 0.011 if quick else 0.0075
    f = goat_field(voxel)
    body = f.mesh("Goat")
    S.finish_mesh(body, target_tris=6400, smooth=2)
    me = body.data
    for slot in ("COAT", "COAT_DARK", "NOSE", "HOOF"):
        me.materials.append(A().material(slot))
    order = {"COAT": 0, "COAT_DARK": 1, "NOSE": 2, "HOOF": 3}
    for p in me.polygons:
        p.material_index = order[goat_slot(tuple(p.center), tuple(p.normal))]
    extras = []
    # horns sweeping back from the brow
    for s in (-1, 1):
        pts = [Vector((s * 0.026, -0.4, 0.645)), Vector((s * 0.04, -0.37, 0.71)), Vector((s * 0.056, -0.31, 0.75)), Vector((s * 0.066, -0.25, 0.74)), Vector((s * 0.07, -0.22, 0.71))]
        rad = [0.017, 0.014, 0.011, 0.007, 0.003]
        hf = S.Field((s * 0.1 - 0.1, -0.45, 0.6), (s * 0.1 + 0.1, -0.18, 0.8), 0.004)
        for i in range(len(pts) - 1):
            hf.union(S.RoundCone(tuple(pts[i]), tuple(pts[i + 1]), rad[i], rad[i + 1]), 0.006)
        horn = hf.mesh("Horn.%s" % ("L" if s > 0 else "R"))
        S.finish_mesh(horn, target_tris=400, smooth=1)
        horn.data.materials.append(A().material("HORN"))
        extras.append(horn)
    # a beard under the chin
    bf = S.Field((-0.05, -0.56, 0.42), (0.05, -0.44, 0.56), 0.004)
    bf.union(S.RoundCone((0, -0.5, 0.52), (0, -0.49, 0.45), 0.016, 0.004), 0.0)
    beard = bf.mesh("Beard")
    S.finish_mesh(beard, target_tris=200, smooth=1)
    beard.data.materials.append(A().material("COAT_DARK"))
    extras.append(beard)
    # eyes: amber, the pupil a bar (a goat is a goat)
    for s in (-1, 1):
        c = Vector((s * 0.047, -0.44, 0.615))
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=0.0135, location=c)
        e = bpy.context.active_object
        e.name = "Eye.%s" % ("L" if s > 0 else "R")
        e.data.materials.append(A().material("EYE_AMBER"))
        extras.append(e)
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=c + Vector((s * 0.011, -0.004, 0.0)))
        b = bpy.context.active_object
        b.scale = (0.004, 0.012, 0.0045)
        bpy.ops.object.transform_apply(scale=True)
        b.name = "Pupil.%s" % ("L" if s > 0 else "R")
        b.data.materials.append(A().material("EYE"))
        extras.append(b)
    # stretch everything from the dog's frame to the goat's (pieces placed by
    # location are first baked into their vertices, so they stretch with it)
    for o in [body] + extras:
        o.data.transform(o.matrix_world)
        o.matrix_world = Matrix.Identity(4)
        for v in o.data.vertices:
            v.co = Vector((v.co.x * SCALE[0], v.co.y * SCALE[1], v.co.z * SCALE[2]))
    return body, extras


def bones():
    out = {}
    for name, (h, t, parent, deform) in A().dog_bones().items():
        out[name] = (tuple(h[i] * SCALE[i] for i in range(3)), tuple(t[i] * SCALE[i] for i in range(3)), parent, deform)
    return out


def region(P):
    import numpy as np
    return A().dog_region(np.asarray(P) / np.asarray(SCALE))


# --- clips (the dog's helpers; hip travel stretched to the goat's height) -----------

def _s(p):
    out = {}
    for b, e in p.items():
        e2 = dict(e)
        if "loc" in e2:
            e2["loc"] = tuple(e2["loc"][i] * SCALE[i] for i in range(3))
        out[b] = e2
    return out


def chew(t, rate=2.6, amount=1.0):
    p = {}
    A().add(p, "jaw", rot=(4 * amount * (0.5 + 0.5 * A().wave(t, 1.0 / rate)), 0, 5 * amount * A().wave(t, 1.0 / rate, 0.25)))
    return p


def g_idle(t):
    a = A()
    p = a.merge(a.d_breath(t, 2.4, 0.8), chew(t), a.d_ears(t, (0.9, 2.7), side="R"))
    a.add(p, "tail1", rot=(-18, 0, 6 * a.wave(t, 0.7)))
    look = a.env(t, 1.5, 1.9, 3.0, 3.5)
    a.add(p, "neck", rot=(-6, 0, 18 * look))
    a.add(p, "head", rot=(-4, 0, 10 * look))
    return _s(p)


def g_graze(t):
    a = A()
    p = a.merge(a.d_breath(t, 1.8, 0.5), chew(t, 3.2))
    a.add(p, "chest", rot=(6, 0, 0))
    a.add(p, "neck", rot=(58, 0, 10 * a.wave(t, 3.0)))
    a.add(p, "head", rot=(26, 0, 4 * a.wave(t, 1.4)))
    tug = a.env(t % 1.5, 0.2, 0.3, 0.4, 0.6)
    a.add(p, "head", rot=(-8 * tug, 0, 0))
    a.add(p, "tail1", rot=(-14, 0, 0))
    return _s(p)


def g_bleat(t):
    """Head up and forward, mouth open, the voice wobbling."""
    a = A()
    k = a.env(t, 0.0, 0.15, 0.85, 1.1)
    p = a.d_breath(t, 1.0, 0.6)
    a.add(p, "neck", rot=(-28 * k, 0, 0))
    a.add(p, "head", rot=(-18 * k, 0, 0))
    a.add(p, "jaw", rot=((22 + 6 * a.wave(t, 0.09)) * k, 0, 0))
    a.add(p, "ear.L", rot=(-20 * k, 0, 0))
    a.add(p, "ear.R", rot=(-20 * k, 0, 0))
    a.add(p, "tail1", rot=(-20 * k, 0, 0))
    return _s(p)


def g_walk(t):
    a = A()
    p = a.d_gait(t, 1.0, {("L", False): 0.0, ("L", True): 0.25, ("R", False): 0.5, ("R", True): 0.75}, 22.0, 30.0, 0.01, 4.0, 4.0)
    a.add(p, "tail1", rot=(-16, 0, 0))
    return _s(p)


def g_startle(t):
    """A jump on the spot at a noise, then a stiff stare, legs braced."""
    a = A()
    hop = a.env(t, 0.0, 0.08, 0.14, 0.32)
    brace = a.ramp(t, 0.25, 0.45)
    p = {}
    a.add(p, "pelvis", loc=(0, 0.03 * hop, 0.12 * hop - 0.02 * brace))
    a.add(p, "neck", rot=(-30 * max(hop, brace), 0, 0))
    a.add(p, "head", rot=(-10 * max(hop, brace), 0, 0))
    a.add(p, "ear.L", rot=(-25, 0, -10))
    a.add(p, "ear.R", rot=(-25, 0, 10))
    for side in ("L", "R"):
        a.add(p, "upperarm." + side, rot=(-10 * brace + 14 * hop, 0, 0))
        a.add(p, "thigh." + side, rot=(10 * brace - 14 * hop, 0, 0))
    a.add(p, "tail1", rot=(-30, 0, 0))
    return _s(p)


def g_lie_pose(k=1.0):
    """Down on its folded legs, chin up, chewing."""
    a = A()
    p = {}
    a.add(p, "pelvis", loc=(0, 0, -0.26 * k), rot=(0, 8 * k, 0))
    a.add(p, "chest", rot=(-4 * k, 0, 0))
    a.add(p, "neck", rot=(-8 * k, 0, 0))
    for side in ("L", "R"):
        a.add(p, "upperarm." + side, rot=(40 * k, 0, 0))
        a.add(p, "forearm." + side, rot=(-150 * k, 0, 0))
        a.add(p, "fpaw." + side, rot=(30 * k, 0, 0))
        a.add(p, "thigh." + side, rot=(-70 * k, 0, 0))
        a.add(p, "shin." + side, rot=(150 * k, 0, 0))
        a.add(p, "hock." + side, rot=(-70 * k, 0, 0))
    return p


def g_lie(t):
    return _s(g_lie_pose(A().sm(t / 1.0)))


def g_lie_idle(t):
    a = A()
    return _s(a.merge(g_lie_pose(1.0), a.d_breath(t, 2.6, 1.0), chew(t), a.d_ears(t, (1.4,), side="L")))


def g_look(t):
    """Something above speaks: up comes the head, stock still, staring."""
    a = A()
    k = a.sm(t / 0.3)
    p = a.d_breath(t, 1.6, 0.3)
    a.add(p, "neck", rot=(-24 * k, 0, 0))
    a.add(p, "head", rot=(-16 * k, 0, 8 * k))
    a.add(p, "ear.L", rot=(-14 * k, 0, 0))
    a.add(p, "ear.R", rot=(-14 * k, 0, 0))
    return _s(p)


def g_stand_up(t):
    return _s(g_lie_pose(1.0 - A().sm(t / 0.7)))


CLIPS = {"idle": (3.6, g_idle), "graze": (3.0, g_graze), "bleat": (1.2, g_bleat), "walk": (1.0, g_walk),
         "startle": (0.9, g_startle), "lie": (1.0, g_lie), "lie_idle": (5.0, g_lie_idle), "look": (0.6, g_look),
         "stand_up": (0.7, g_stand_up)}
LOOPS = {"idle", "graze", "walk", "lie_idle"}
SPEEDS = {"walk": 0.6}


def make(quick):
    a = A()
    a.clear()
    body, extras = build(quick)
    bn = bones()
    rig = a.build_armature(bn, "Goat")
    a.bake_ao([body])
    for o in extras:
        a.ensure_color(o)
    a.bind(body, rig, bn, region)
    for o in extras:
        a.bind_rigid(o, rig, "head")
    a.write_actions(rig, CLIPS, LOOPS)
    import os
    path = os.path.join(a.OUT, "court_goat.glb")
    a.export(rig, [body] + extras, path)
    tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
    return {"glb": "court_goat.glb", "triangles": tris, "height": 0.95,
            "clips": {n: {"seconds": d, "loop": n in LOOPS} for n, (d, _) in CLIPS.items()},
            "speeds": SPEEDS}

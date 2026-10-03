"""Build the court's animals and export them for Godot.

Run headless with Blender 5.2 (never opens a window):
  blender --background --factory-startup --python tools/blender/court_animals.py -- [--species dog] [--quick]

Each species becomes assets/court_sets/animals/court_<species>.glb holding one
armature, its mesh (materials by slot: COAT, COAT_LIGHT, NOSE, EYE,
EYE_SHINE) and every clip as its own animation; court_animals.json lists the
clips (seconds, loop) and the walking speeds. Clips are written pose by pose
for a body at rest facing the god (+z in the game); the game moves the body
about and plays them (scripts/hud/court_animal_3d.gd).

The dog: a lean camp dog of the early bands, tan with a cream bib, one ear up
and one ear that never quite stands, a tail curled over its back.
Its clips: idle, wag, sniff, walk, trot, sit, sit_idle, scratch, lie,
lie_idle, cower, cower_idle, look_up, tilt, bark, grab, stand_up.
"""
import os
import sys
import json
import math
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True

import bpy
import numpy as np
from mathutils import Vector, Quaternion, Euler, Matrix

import cf_sdf as S

OUT = os.path.join(ROOT, "assets", "court_sets", "animals")
FPS = 30

SLOT_COLOURS = {"COAT": (0.62, 0.42, 0.24), "COAT_LIGHT": (0.86, 0.76, 0.58), "NOSE": (0.08, 0.06, 0.05),
                "EYE": (0.07, 0.05, 0.04), "EYE_SHINE": (0.98, 0.96, 0.9), "COAT_DARK": (0.30, 0.20, 0.12),
                "HORN": (0.55, 0.5, 0.42), "HOOF": (0.2, 0.17, 0.14), "EYE_AMBER": (0.75, 0.55, 0.2)}


def log(*a):
    print("[court_animals]", *a, flush=True)


def args():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    opts = {"species": ["dog"], "quick": False}
    i = 0
    while i < len(a):
        if a[i] == "--species":
            opts["species"] = a[i + 1].split(",")
            i += 1
        elif a[i] == "--quick":
            opts["quick"] = True
        i += 1
    return opts


def clear():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.armatures, bpy.data.actions, bpy.data.materials):
        for d in list(coll):
            coll.remove(d)


def material(slot):
    m = bpy.data.materials.get(slot)
    if m is None:
        m = bpy.data.materials.new(slot)
        c = SLOT_COLOURS.get(slot, (0.5, 0.5, 0.5))
        m.diffuse_color = (c[0], c[1], c[2], 1.0)
    return m


# =====================================================================================
# The dog (Blender frame: facing -Y, up +Z; the game sees it facing +z)

SIDE = 0.072


def dog_bones():
    """name: (head, tail, parent, deform)"""
    b = {
        "root": ((0, 0, 0), (0, 0, 0.12), None, False),
        "pelvis": ((0, 0.23, 0.40), (0, 0.05, 0.41), "root", True),
        "spine": ((0, 0.05, 0.41), (0, -0.14, 0.42), "pelvis", True),
        "chest": ((0, -0.14, 0.42), (0, -0.25, 0.45), "spine", True),
        "neck": ((0, -0.25, 0.45), (0, -0.36, 0.565), "chest", True),
        "head": ((0, -0.36, 0.565), (0, -0.50, 0.60), "neck", True),
        "jaw": ((0, -0.43, 0.555), (0, -0.55, 0.535), "head", True),
        "ear.L": ((0.048, -0.385, 0.65), (0.06, -0.39, 0.735), "head", True),
        "ear.R": ((-0.048, -0.385, 0.65), (-0.06, -0.39, 0.735), "head", True),
        "tail1": ((0, 0.30, 0.44), (0, 0.38, 0.53), "pelvis", True),
        "tail2": ((0, 0.38, 0.53), (0, 0.395, 0.63), "tail1", True),
        "tail3": ((0, 0.395, 0.63), (0, 0.33, 0.69), "tail2", True),
    }
    for sname, s in (("L", SIDE), ("R", -SIDE)):
        b["upperarm." + sname] = ((s, -0.19, 0.37), (s, -0.19, 0.20), "chest", True)
        b["forearm." + sname] = ((s, -0.19, 0.20), (s, -0.205, 0.05), "upperarm." + sname, True)
        b["fpaw." + sname] = ((s, -0.205, 0.05), (s, -0.25, 0.018), "forearm." + sname, True)
        b["thigh." + sname] = ((s, 0.21, 0.38), (s, 0.15, 0.22), "pelvis", True)
        b["shin." + sname] = ((s, 0.15, 0.22), (s, 0.255, 0.10), "thigh." + sname, True)
        b["hock." + sname] = ((s, 0.255, 0.10), (s, 0.24, 0.03), "shin." + sname, True)
        b["hpaw." + sname] = ((s, 0.24, 0.03), (s, 0.20, 0.016), "hock." + sname, True)
    return b


def dog_field(voxel):
    lo = (-0.2, -0.65, -0.02)
    hi = (0.2, 0.5, 0.82)
    f = S.Field(lo, hi, voxel)
    k = 0.035
    f.union(S.Ellipsoid((0, -0.17, 0.405), (0.115, 0.15, 0.135)), 0.0)
    f.union(S.RoundCone((0, -0.14, 0.41), (0, 0.19, 0.415), 0.115, 0.095), 0.05)
    f.union(S.Ellipsoid((0, 0.21, 0.405), (0.10, 0.115, 0.11)), 0.04)
    # a tucked belly line: subtract a soft cylinder under the waist
    f.subtract(S.RoundCone((-0.3, 0.06, 0.205), (0.3, 0.06, 0.205), 0.075, 0.075), 0.06)
    # neck, head, muzzle
    f.union(S.RoundCone((0, -0.24, 0.45), (0, -0.36, 0.565), 0.075, 0.058), 0.04)
    f.union(S.Ellipsoid((0, -0.395, 0.60), (0.075, 0.085, 0.07)), 0.03)
    f.union(S.RoundCone((0, -0.43, 0.585), (0, -0.555, 0.556), 0.048, 0.03), 0.03)
    f.union(S.RoundCone((0, -0.43, 0.548), (0, -0.54, 0.536), 0.036, 0.022), 0.02)
    f.union(S.Sphere((0, -0.566, 0.562), 0.022), 0.01)
    # brow and cheeks
    for s in (-1, 1):
        f.union(S.Ellipsoid((s * 0.045, -0.43, 0.62), (0.022, 0.03, 0.018)), 0.02)
        f.union(S.Ellipsoid((s * 0.05, -0.415, 0.575), (0.03, 0.035, 0.03)), 0.025)
    # ears: the left stands, the right never quite does (it folds at the tip)
    qL = Quaternion((0, 1, 0), math.radians(-14)) @ Quaternion((1, 0, 0), math.radians(-6))
    f.union(S.Ellipsoid((0.054, -0.388, 0.69), (0.03, 0.011, 0.052), rot=qL), 0.012)
    qR = Quaternion((0, 1, 0), math.radians(22)) @ Quaternion((1, 0, 0), math.radians(-10))
    f.union(S.Ellipsoid((-0.06, -0.385, 0.678), (0.03, 0.011, 0.042), rot=qR), 0.012)
    qR2 = Quaternion((0, 1, 0), math.radians(95)) @ Quaternion((1, 0, 0), math.radians(-30))
    f.union(S.Ellipsoid((-0.092, -0.395, 0.705), (0.024, 0.009, 0.03), rot=qR2), 0.01)
    # legs
    for s in (-SIDE, SIDE):
        f.union(S.RoundCone((s, -0.19, 0.37), (s, -0.19, 0.20), 0.05, 0.032), 0.035)
        f.union(S.RoundCone((s, -0.19, 0.20), (s, -0.205, 0.05), 0.031, 0.024), 0.015)
        f.union(S.Ellipsoid((s, -0.228, 0.024), (0.03, 0.043, 0.024)), 0.015)
        f.union(S.RoundCone((s * 0.95, 0.21, 0.38), (s, 0.15, 0.22), 0.068, 0.036), 0.035)
        f.union(S.RoundCone((s, 0.15, 0.22), (s, 0.255, 0.10), 0.034, 0.022), 0.015)
        f.union(S.RoundCone((s, 0.255, 0.10), (s, 0.24, 0.03), 0.022, 0.02), 0.01)
        f.union(S.Ellipsoid((s, 0.215, 0.024), (0.029, 0.042, 0.023)), 0.015)
    # the tail, curled over the back
    pts = [(0, 0.30, 0.44), (0, 0.38, 0.53), (0, 0.395, 0.63), (0, 0.33, 0.69), (0, 0.27, 0.665)]
    rad = [0.04, 0.034, 0.028, 0.022, 0.016]
    for i in range(len(pts) - 1):
        f.union(S.RoundCone(pts[i], pts[i + 1], rad[i], rad[i + 1]), 0.02)
    return f


def dog_slot(c, n):
    """Which paint a point of the dog's coat takes: a tan camp dog with a dark
    saddle and mask, cream bib, belly, socks and tail tip, a blaze up the brow."""
    from mathutils.noise import noise as _n
    x, y, z = c
    wob = 0.012 * _n(Vector((x * 30.0, y * 30.0, z * 30.0)))
    if y < -0.555 and z > 0.53:
        return "NOSE"
    # the blaze: a cream stripe up the middle of the brow
    if abs(x) < 0.014 + wob * 0.5 and -0.47 < y < -0.37 and z > 0.6 and n[2] > 0.2:
        return "COAT_LIGHT"
    # a dark mask over the top of the muzzle and about the eyes
    if y < -0.44 and z > 0.565 + wob and n[2] > -0.1:
        return "COAT_DARK"
    if -0.48 < y < -0.42 and z > 0.6 and abs(x) > 0.03:
        return "COAT_DARK"
    # cream: socks, the muzzle's underside, the bib, the belly, the tail's tip
    if z < 0.075 + wob:
        return "COAT_LIGHT"
    if y < -0.45 and z < 0.56:
        return "COAT_LIGHT"
    if y < -0.24 and z < 0.48 + wob and abs(x) < 0.075 and n[2] < 0.55 and y > -0.40:
        return "COAT_LIGHT"
    if -0.22 < y < 0.25 and z < 0.34 and abs(x) < 0.09 and n[2] < -0.15:
        return "COAT_LIGHT"
    if y > 0.25 and z > 0.655:
        return "COAT_LIGHT"
    # the dark saddle along the back, the ears' backs and tips
    if z > 0.47 + wob and -0.24 < y < 0.27 and n[2] > 0.35:
        return "COAT_DARK"
    if z > 0.7:
        return "COAT_DARK"
    if y > 0.29 and z > 0.47 and n[2] > 0.3:
        return "COAT_DARK"
    return "COAT"


def build_dog(quick=False):
    voxel = 0.011 if quick else 0.0075
    f = dog_field(voxel)
    body = f.mesh("Dog")
    S.finish_mesh(body, target_tris=7200, smooth=2)
    me = body.data
    for slot in ("COAT", "COAT_LIGHT", "COAT_DARK", "NOSE"):
        me.materials.append(material(slot))
    order = {"COAT": 0, "COAT_LIGHT": 1, "COAT_DARK": 2, "NOSE": 3}
    for p in me.polygons:
        p.material_index = order[dog_slot(tuple(p.center), tuple(p.normal))]
    # eyes: dark beads with a glint
    eyes = []
    for s in (-1, 1):
        c = Vector((s * 0.043, -0.462, 0.618))
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=0.0145, location=c)
        e = bpy.context.active_object
        e.name = "Eye.%s" % ("L" if s > 0 else "R")
        e.data.materials.append(material("EYE"))
        eyes.append(e)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=6, ring_count=4, radius=0.0042, location=c + Vector((s * 0.004, -0.011, 0.006)))
        g = bpy.context.active_object
        g.name = "Glint.%s" % ("L" if s > 0 else "R")
        g.data.materials.append(material("EYE_SHINE"))
        eyes.append(g)
    bpy.ops.object.select_all(action='DESELECT')
    for e in eyes:
        e.select_set(True)
    bpy.context.view_layer.objects.active = eyes[0]
    bpy.ops.object.join()
    eye_obj = bpy.context.active_object
    eye_obj.name = "Eyes"
    return body, eye_obj


# --- rig and weights ------------------------------------------------------------------

def build_armature(bones, name):
    arm = bpy.data.armatures.new(name)
    rig = bpy.data.objects.new(name, arm)
    bpy.context.scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode='EDIT')
    made = {}
    for bname, (h, t, parent, deform) in bones.items():
        eb = arm.edit_bones.new(bname)
        eb.head = Vector(h)
        eb.tail = Vector(t)
        eb.use_deform = deform
        made[bname] = eb
    for bname, (h, t, parent, deform) in bones.items():
        if parent:
            made[bname].parent = made[parent]
            made[bname].use_connect = False
    bpy.ops.object.mode_set(mode='OBJECT')
    return rig


def _seg_dist(P, a, b):
    a = np.asarray(a, dtype=np.float64)
    b = np.asarray(b, dtype=np.float64)
    ab = b - a
    t = np.clip(((P - a) @ ab) / max(ab @ ab, 1e-9), 0.0, 1.0)
    q = a + t[:, None] * ab
    return np.linalg.norm(P - q, axis=1)


def dog_region(P):
    """Candidate bones per vertex: a list of bone-name lists."""
    out = []
    for x, y, z in P:
        side = "L" if x > 0 else "R"
        if z > 0.635 and y < -0.33 and abs(x) > 0.025:
            out.append(["ear." + side, "head"])
        elif y < -0.33 and z > 0.47:
            if y < -0.445 and z < 0.553:
                out.append(["jaw", "head"])
            else:
                out.append(["head", "neck"])
        elif (y > 0.285 and z > 0.43) or (y > 0.2 and z > 0.56):
            # the tail, including its tip curled forward over the back
            out.append(["tail1", "tail2", "tail3", "pelvis"])
        elif z < 0.33 and abs(x) > 0.018 and y < 0.0:
            out.append(["upperarm." + side, "forearm." + side, "fpaw." + side, "chest"])
        elif z < 0.33 and abs(x) > 0.018 and y >= 0.0:
            out.append(["thigh." + side, "shin." + side, "hock." + side, "hpaw." + side, "pelvis"])
        else:
            out.append(["pelvis", "spine", "chest", "neck"])
    return out


def bind(obj, rig, bones, region_fn, power=4.0):
    me = obj.data
    P = np.array([v.co[:] for v in me.vertices], dtype=np.float64)
    names = [n for n, v in bones.items() if v[3]]
    dists = {n: _seg_dist(P, bones[n][0], bones[n][1]) for n in names}
    regions = region_fn(P)
    for n in names:
        obj.vertex_groups.new(name=n)
    groups = {g.name: g for g in obj.vertex_groups}
    for i, cand in enumerate(regions):
        ws = []
        for n in cand:
            d = max(dists[n][i], 0.004)
            ws.append((n, 1.0 / d ** power))
        ws.sort(key=lambda t: -t[1])
        ws = ws[:3]
        tot = sum(w for _, w in ws)
        for n, w in ws:
            if w / tot > 0.02:
                groups[n].add([i], w / tot, 'REPLACE')
    mod = obj.modifiers.new("Armature", 'ARMATURE')
    mod.object = rig
    obj.parent = rig


def bind_rigid(obj, rig, bone):
    obj.vertex_groups.new(name=bone).add(list(range(len(obj.data.vertices))), 1.0, 'REPLACE')
    mod = obj.modifiers.new("Armature", 'ARMATURE')
    mod.object = rig
    obj.parent = rig


# --- posing -------------------------------------------------------------------------

class Poser:
    """Rotations given about the armature's axes (degrees, about each bone's head)."""

    def __init__(self, rig):
        self.rig = rig
        self.rest = {b.name: b.matrix_local.to_quaternion() for b in rig.data.bones}

    def apply(self, pose):
        for pb in self.rig.pose.bones:
            pb.rotation_mode = 'QUATERNION'
            pb.rotation_quaternion = Quaternion()
            pb.location = Vector()
        for name, e in pose.items():
            pb = self.rig.pose.bones.get(name)
            if pb is None:
                continue
            R = self.rest[name]
            rot = e.get("rot")
            if rot and any(abs(a) > 1e-6 for a in rot):
                Q = Euler([math.radians(a) for a in rot], 'XYZ').to_quaternion()
                pb.rotation_quaternion = R.inverted() @ Q @ R
            loc = e.get("loc")
            if loc and any(abs(a) > 1e-7 for a in loc):
                pb.location = R.inverted() @ Vector(loc)

    def key(self, frame):
        for pb in self.rig.pose.bones:
            pb.keyframe_insert("rotation_quaternion", frame=frame)
            pb.keyframe_insert("location", frame=frame)


def sm(x):
    x = max(0.0, min(1.0, x))
    return x * x * (3 - 2 * x)


def ramp(t, a, b):
    return sm((t - a) / max(b - a, 1e-6))


def env(t, a, b, c, d):
    """0 before a, up to 1 by b, held to c, down to 0 by d."""
    return ramp(t, a, b) * (1.0 - ramp(t, c, d))


def wave(t, period, phase=0.0):
    return math.sin(2 * math.pi * (t / period + phase))


def add(p, bone, rot=None, loc=None):
    e = p.setdefault(bone, {})
    if rot:
        r = e.get("rot", (0, 0, 0))
        e["rot"] = tuple(r[i] + rot[i] for i in range(3))
    if loc:
        l = e.get("loc", (0, 0, 0))
        e["loc"] = tuple(l[i] + loc[i] for i in range(3))


def scaled(p, k):
    out = {}
    for b, e in p.items():
        out[b] = {key: tuple(v * k for v in val) for key, val in e.items()}
    return out


def merge(*poses):
    out = {}
    for p in poses:
        for b, e in p.items():
            add(out, b, e.get("rot"), e.get("loc"))
    return out


def mix(a, b, t):
    return merge(scaled(a, 1.0 - t), scaled(b, t))


# --- the dog's clips (x: nose down +, z: turn toward its left +, y: roll) -----------

def d_breath(t, period=1.9, amount=1.0):
    p = {}
    b = wave(t, period) * amount
    add(p, "chest", rot=(-0.8 * b, 0, 0), loc=(0, 0, 0.003 * b))
    add(p, "spine", loc=(0, 0, 0.002 * b))
    return p


def d_tail(t, period=1.2, amount=14.0, height=0.0):
    p = {}
    w = wave(t, period)
    add(p, "tail1", rot=(-height, 0, amount * w))
    add(p, "tail2", rot=(0, 0, amount * 0.8 * wave(t, period, -0.08)))
    add(p, "tail3", rot=(0, 0, amount * 0.6 * wave(t, period, -0.16)))
    return p


def d_ears(t, twitch_times=(), back=0.0, side="L"):
    p = {}
    add(p, "ear.L", rot=(-back * 1.0, 0, -back * 0.4))
    add(p, "ear.R", rot=(-back * 0.8, 0, back * 0.4))
    for t0 in twitch_times:
        k = env(t, t0, t0 + 0.05, t0 + 0.1, t0 + 0.22)
        add(p, "ear." + side, rot=(-14 * k, 0, 10 * k))
    return p


def d_idle(t):
    p = merge(d_breath(t), d_tail(t, 2.6, 9.0), d_ears(t, (1.3, 3.1), side="L"))
    look = env(t, 0.8, 1.3, 2.2, 2.8)
    add(p, "neck", rot=(2 * wave(t, 4.0), 0, 10 * look))
    add(p, "head", rot=(-3 * look, 4 * look, 8 * look))
    return p


def d_wag(t):
    p = merge(d_breath(t, 0.9, 1.3), d_tail(t, 0.32, 30.0, height=-8), d_ears(t, back=6))
    add(p, "pelvis", rot=(0, 0, 4 * wave(t, 0.32, 0.25)))
    add(p, "chest", rot=(0, 0, -2 * wave(t, 0.32, 0.25)))
    add(p, "head", rot=(-6, 0, 3 * wave(t, 0.64)))
    add(p, "jaw", rot=(6 + 2 * wave(t, 0.3), 0, 0))
    return p


def d_sniff(t):
    """Head down to the ground, the nose working, a slow sweep side to side."""
    p = merge(d_breath(t, 0.5, 0.4), d_tail(t, 1.6, 10.0, height=-6))
    add(p, "chest", rot=(9, 0, 0), loc=(0, 0, -0.02))
    add(p, "neck", rot=(44, 0, 14 * wave(t, 2.0)))
    add(p, "head", rot=(22 + 3 * abs(wave(t, 0.18)), 0, 6 * wave(t, 2.0, 0.2)))
    add(p, "jaw", rot=(2 * abs(wave(t, 0.18)), 0, 0))
    for side, s in (("L", 1), ("R", -1)):
        add(p, "upperarm." + side, rot=(-6, 0, 0))
        add(p, "forearm." + side, rot=(10, 0, 0))
    return p


def _leg(p, side, front, ph, stride, lift):
    """One leg through its step: ph 0..1, stance the first 60%."""
    s = ph % 1.0
    if s < 0.6:
        u = s / 0.6
        swing = stride * (0.5 - u)         # forward to back on the ground
        up = 0.0
    else:
        u = (s - 0.6) / 0.4
        swing = stride * (-0.5 + u)        # back to forward in the air
        up = math.sin(u * math.pi)
    # +x rotation swings the foot back; forward is negative
    if front:
        add(p, "upperarm." + side, rot=(swing, 0, 0))
        add(p, "forearm." + side, rot=(-lift * 1.0 * up, 0, 0))
        add(p, "fpaw." + side, rot=(lift * 1.4 * up, 0, 0))
    else:
        add(p, "thigh." + side, rot=(swing, 0, 0))
        add(p, "shin." + side, rot=(lift * 0.9 * up, 0, 0))
        add(p, "hock." + side, rot=(-lift * 0.9 * up, 0, 0))


def d_gait(t, period, phases, stride, lift, bob, head_bob, tail_amt):
    p = merge(d_tail(t, period, tail_amt, height=-5), d_ears(t, back=4))
    k = t / period
    for (side, front), ph in phases.items():
        _leg(p, side, front, k + ph, stride, lift)
    b = math.cos(4 * math.pi * k)
    add(p, "pelvis", loc=(0, 0, -bob * 0.5 * (1 + b)), rot=(0, 3 * wave(t, period), 0))
    add(p, "chest", rot=(0, -3 * wave(t, period), 0))
    add(p, "neck", rot=(head_bob * b, 0, 0))
    add(p, "head", rot=(-head_bob * 0.6 * b, 0, 0))
    return p


def d_walk(t):
    return d_gait(t, 0.9, {("L", False): 0.0, ("L", True): 0.25, ("R", False): 0.5, ("R", True): 0.75}, 26.0, 34.0, 0.012, 3.0, 8.0)


def d_trot(t):
    p = d_gait(t, 0.5, {("L", True): 0.0, ("R", False): 0.0, ("R", True): 0.5, ("L", False): 0.5}, 34.0, 44.0, 0.02, 4.0, 14.0)
    add(p, "chest", rot=(-3, 0, 0))
    return p


SIT_T = 0.8


def sit_pose(k=1.0):
    p = {}
    # hips drop and tuck under, front legs stay straight, chest lifts
    add(p, "pelvis", rot=(-48 * k, 0, 0), loc=(0, 0.02 * k, -0.15 * k))
    add(p, "spine", rot=(-12 * k, 0, 0))
    add(p, "chest", rot=(-6 * k, 0, 0), loc=(0, 0, 0.0))
    add(p, "neck", rot=(-4 * k, 0, 0))
    add(p, "head", rot=(14 * k, 0, 0))
    for side in ("L", "R"):
        add(p, "thigh." + side, rot=(-58 * k, 0, 0))
        add(p, "shin." + side, rot=(118 * k, 0, 0))
        add(p, "hock." + side, rot=(-60 * k, 0, 0))
        add(p, "upperarm." + side, rot=(58 * k, 0, 0))
        add(p, "forearm." + side, rot=(-6 * k, 0, 0))
        add(p, "fpaw." + side, rot=(-4 * k, 0, 0))
    add(p, "tail1", rot=(-45 * k, 0, 12 * k))
    add(p, "tail2", rot=(-12 * k, 0, 10 * k))
    return p


def d_sit(t):
    k = sm(t / SIT_T)
    return merge(sit_pose(k), d_breath(t, 1.6, k))


def d_sit_idle(t):
    p = merge(sit_pose(1.0), d_breath(t, 1.7), d_ears(t, (1.8,), side="R"))
    sweep = wave(t, 3.0)
    add(p, "tail3", rot=(0, 0, 10 * sweep))
    look = env(t, 1.0, 1.4, 2.4, 2.9)
    add(p, "head", rot=(-4 * look, 0, -14 * look))
    return p


def d_scratch(t):
    """Seated, a hind leg pedals at the ear, head tilted into it, eyes half shut."""
    p = merge(sit_pose(1.0), d_breath(t, 0.8, 0.6))
    beat = wave(t, 0.16)
    add(p, "pelvis", rot=(0, 0, 6), loc=(0.01, 0, 0))
    add(p, "spine", rot=(0, 0, -6))
    add(p, "neck", rot=(10, -4, -26))
    add(p, "head", rot=(4, -28, -10 + 3 * beat))
    add(p, "ear.R", rot=(-10 + 8 * beat, 0, 0))
    add(p, "thigh.R", rot=(-48, 0, -14))
    add(p, "shin.R", rot=(-30 + 22 * beat, 0, 0))
    add(p, "hock.R", rot=(-30 + 14 * beat, 0, 0))
    add(p, "hpaw.R", rot=(-30, 0, 0))
    add(p, "jaw", rot=(5, 0, 0))
    return p


LIE_T = 1.2


def curled():
    """Lying curled: belly on the ground, forelegs out in front with the head
    laid on the paws, hind legs folded to one side, the body bent round and
    the tail wrapped about the hind feet."""
    p = {}
    add(p, "pelvis", rot=(0, 16, 14), loc=(0.0, 0.0, -0.255))
    add(p, "spine", rot=(0, -4, 10))
    add(p, "chest", rot=(2, -8, 8))
    add(p, "neck", rot=(54, 0, 14))
    add(p, "head", rot=(-14, -6, 4))
    add(p, "jaw", rot=(0, 0, 0))
    for side, s in (("L", 1), ("R", -1)):
        add(p, "upperarm." + side, rot=(-72, 0, 3 * s))
        add(p, "forearm." + side, rot=(-22, 0, 0))
        add(p, "fpaw." + side, rot=(80, 0, 0))
    # both hind legs folded and laid over to the dog's left
    add(p, "thigh.L", rot=(-78, -40, 0))
    add(p, "shin.L", rot=(150, 0, 0))
    add(p, "hock.L", rot=(-70, 0, 0))
    add(p, "thigh.R", rot=(-70, -30, 0))
    add(p, "shin.R", rot=(146, 0, 0))
    add(p, "hock.R", rot=(-66, 0, 0))
    # the tail comes down off the back and lies round the hind feet
    add(p, "tail1", rot=(-66, 0, 58))
    add(p, "tail2", rot=(-14, 0, 40))
    add(p, "tail3", rot=(0, 0, 30))
    add(p, "ear.L", rot=(28, 0, -10))
    add(p, "ear.R", rot=(34, 0, 14))
    return p


def lie_pose(k=1.0):
    """From standing: down onto the haunches first, then the front, then the curl."""
    if k < 0.45:
        return sit_pose(sm(k / 0.45) * 0.75)
    return mix(sit_pose(0.75), curled(), sm((k - 0.45) / 0.55))


def d_lie(t):
    return lie_pose(sm(t / LIE_T))


def d_lie_idle(t):
    """Asleep, or nearly: slow deep breaths, an ear that flicks at a fly, and
    once in a while the head comes up off the paws to look, and goes down."""
    p = merge(curled(), d_breath(t, 2.6, 1.6), d_ears(t, (1.1, 4.2), side="L"))
    look = env(t, 2.4, 2.8, 3.6, 4.2)
    add(p, "neck", rot=(-22 * look, 0, -6 * look))
    add(p, "head", rot=(-6 * look, 0, -8 * look))
    add(p, "tail3", rot=(0, 0, 8 * wave(t, 5.2)))
    return p


COWER_T = 0.5


def cower_pose(k=1.0):
    p = {}
    add(p, "pelvis", rot=(18 * k, 0, 0), loc=(0, 0.04 * k, -0.10 * k))
    add(p, "spine", loc=(0, 0, -0.06 * k))
    add(p, "chest", rot=(8 * k, 0, 0), loc=(0, 0.02 * k, -0.08 * k))
    add(p, "neck", rot=(30 * k, 0, 0))
    add(p, "head", rot=(14 * k, 0, 0))
    add(p, "ear.L", rot=(60 * k, 0, -20 * k))
    add(p, "ear.R", rot=(55 * k, 0, 20 * k))
    # the tail tucked down between the hind legs
    add(p, "tail1", rot=(-150 * k, 0, 0))
    add(p, "tail2", rot=(-25 * k, 0, 0))
    add(p, "tail3", rot=(-15 * k, 0, 0))
    for side in ("L", "R"):
        add(p, "upperarm." + side, rot=(28 * k, 0, 0))
        add(p, "forearm." + side, rot=(-44 * k, 0, 0))
        add(p, "fpaw." + side, rot=(20 * k, 0, 0))
        add(p, "thigh." + side, rot=(-38 * k, 0, 0))
        add(p, "shin." + side, rot=(56 * k, 0, 0))
        add(p, "hock." + side, rot=(-20 * k, 0, 0))
    return p


def d_cower(t):
    return cower_pose(sm(t / COWER_T))


def d_cower_idle(t):
    """Low, ears flat, tail tucked; a tremble and now and then a glance up."""
    p = cower_pose(1.0)
    tremble = math.sin(t * 2 * math.pi * 9.0) * 0.6 + math.sin(t * 2 * math.pi * 13.0) * 0.4
    add(p, "chest", rot=(0, 1.2 * tremble, 0))
    add(p, "pelvis", rot=(0, -1.0 * tremble, 0))
    glance = env(t, 1.2, 1.4, 1.9, 2.2)
    add(p, "head", rot=(-14 * glance, 0, 6 * glance))
    add(p, "neck", rot=(-8 * glance, 0, 0))
    add(p, "jaw", rot=(3 * env(t, 0.3, 0.4, 0.6, 0.8), 0, 0))
    return p


def d_look_up(t):
    """Something above speaks: the head comes up, ears prick, the tail stills."""
    k = sm(t / 0.35)
    p = merge(d_breath(t, 1.4, 0.6))
    add(p, "neck", rot=(-26 * k, 0, 0))
    add(p, "head", rot=(-22 * k, 0, 0))
    add(p, "ear.L", rot=(-16 * k, 0, 0))
    add(p, "ear.R", rot=(-22 * k, 0, 8 * k))
    add(p, "tail1", rot=(-10 * k, 0, 0))
    return p


def d_tilt(t):
    """The curious tilt: up, then the head cocks one way, then the other."""
    p = d_look_up(min(t, 0.35))
    a = env(t, 0.35, 0.55, 1.1, 1.3)
    b = env(t, 1.3, 1.5, 2.1, 2.4)
    add(p, "head", rot=(0, 26 * a - 22 * b, 0))
    add(p, "ear.R", rot=(-12 * (a + b), 0, 0))
    return p


def d_bark(t):
    """One bark: a dip and a jerk of the head up, the jaw snapping open."""
    p = d_breath(t, 0.8, 0.5)
    dip = env(t, 0.0, 0.08, 0.1, 0.18)
    jerk = env(t, 0.12, 0.17, 0.24, 0.42)
    add(p, "chest", rot=(4 * dip - 3 * jerk, 0, 0), loc=(0, 0.01 * dip, -0.01 * dip))
    add(p, "neck", rot=(12 * dip - 16 * jerk, 0, 0))
    add(p, "head", rot=(4 * dip - 8 * jerk, 0, 0))
    add(p, "jaw", rot=(34 * jerk, 0, 0))
    add(p, "ear.L", rot=(10 * jerk, 0, 0))
    add(p, "ear.R", rot=(10 * jerk, 0, 0))
    add(p, "tail1", rot=(-12 * jerk, 0, 0))
    return p


def d_grab(t):
    """A quick dip to the ground and up, jaw closing on something."""
    p = d_tail(t, 0.3, 18.0, height=-6)
    dip = env(t, 0.05, 0.25, 0.35, 0.6)
    add(p, "chest", rot=(10 * dip, 0, 0), loc=(0, 0, -0.03 * dip))
    add(p, "neck", rot=(52 * dip, 0, 0))
    add(p, "head", rot=(24 * dip, 0, 0))
    add(p, "jaw", rot=(22 * env(t, 0.1, 0.2, 0.28, 0.34), 0, 0))
    for side in ("L", "R"):
        add(p, "upperarm." + side, rot=(-8 * dip, 0, 0))
        add(p, "forearm." + side, rot=(14 * dip, 0, 0))
    return p


def d_stand_up(t):
    """From sitting (or lying) back up onto four feet."""
    k = 1.0 - sm(t / 0.6)
    return merge(sit_pose(k), d_breath(t, 1.2, 1.0 - k))


def d_tug(t):
    """Braced and pulling back at something held in the teeth: haunches down,
    forelegs planted forward, head low and wrenching side to side, tail up."""
    p = d_breath(t, 0.5, 0.6)
    yank = wave(t, 0.42)
    add(p, "pelvis", rot=(-14, 0, 4 * yank), loc=(0, 0.05, -0.07))
    add(p, "chest", rot=(10, 0, -3 * yank), loc=(0, 0.02, -0.04))
    add(p, "neck", rot=(30, 0, 18 * yank))
    add(p, "head", rot=(14, 22 * yank, 8 * yank))
    add(p, "jaw", rot=(3, 0, 0))
    for side in ("L", "R"):
        add(p, "upperarm." + side, rot=(-32, 0, 0))
        add(p, "forearm." + side, rot=(-8, 0, 0))
        add(p, "fpaw." + side, rot=(20, 0, 0))
        add(p, "thigh." + side, rot=(-34, 0, 0))
        add(p, "shin." + side, rot=(52, 0, 0))
        add(p, "hock." + side, rot=(-22, 0, 0))
    add(p, "tail1", rot=(-30, 0, 20 * wave(t, 0.21)))
    add(p, "tail2", rot=(0, 0, 14 * wave(t, 0.21, -0.1)))
    add(p, "ear.L", rot=(20, 0, 0))
    add(p, "ear.R", rot=(20, 0, 0))
    return p


def d_crunch(t):
    """Lying on its front over something, gnawing: head down and sideways,
    the jaw working, the whole head jerking with each bite."""
    p = cower_pose(0.55)
    bite = abs(wave(t, 0.36))
    add(p, "tail1", rot=(-80, 0, 10 * wave(t, 1.1)))
    add(p, "neck", rot=(20, 0, -10))
    add(p, "head", rot=(16 + 6 * bite, -28, -6 + 4 * bite))
    add(p, "jaw", rot=(18 * bite, 0, 0))
    add(p, "ear.L", rot=(-30, 0, 10))
    add(p, "ear.R", rot=(-30, 0, -10))
    return p


def d_carry(t):
    """Trotting proudly with something in the mouth: head high, tail up."""
    p = d_trot(t)
    add(p, "neck", rot=(-14, 0, 0))
    add(p, "head", rot=(-6, 0, 0))
    add(p, "jaw", rot=(7, 0, 0))
    add(p, "tail1", rot=(-30, 0, 0))
    return p


DOG_CLIPS = {
    "idle": (4.2, d_idle), "wag": (1.28, d_wag), "sniff": (2.0, d_sniff),
    "walk": (0.9, d_walk), "trot": (0.5, d_trot),
    "sit": (SIT_T, d_sit), "sit_idle": (6.0, d_sit_idle), "scratch": (0.64, d_scratch),
    "lie": (LIE_T, d_lie), "lie_idle": (5.2, d_lie_idle),
    "cower": (COWER_T, d_cower), "cower_idle": (2.4, d_cower_idle),
    "look_up": (0.6, d_look_up), "tilt": (2.6, d_tilt), "bark": (0.5, d_bark),
    "grab": (0.7, d_grab), "stand_up": (0.6, d_stand_up),
    "tug": (0.84, d_tug), "crunch": (0.72, d_crunch), "carry": (0.5, d_carry),
}
DOG_LOOPS = {"idle", "wag", "sniff", "walk", "trot", "sit_idle", "scratch", "lie_idle", "cower_idle", "tug", "crunch", "carry"}
DOG_SPEEDS = {"walk": 0.78, "trot": 1.7, "carry": 1.7}


def write_actions(rig, clips, loops):
    poser = Poser(rig)
    if rig.animation_data is None:
        rig.animation_data_create()
    made = []
    for name, (dur, fn) in clips.items():
        act = bpy.data.actions.new(name)
        act.use_fake_user = True
        rig.animation_data.action = act
        frames = int(round(dur * FPS))
        for fr in range(frames + 1):
            t = fr / FPS
            if name in loops:
                t = t % dur if fr < frames else 0.0
            poser.apply(fn(t))
            poser.key(fr)
        made.append(act)
    rig.animation_data.action = None
    for act in made:
        tr = rig.animation_data.nla_tracks.new()
        tr.name = act.name
        tr.strips.new(act.name, 0, act)
        tr.mute = True
    poser.apply({})
    return made


def ensure_color(obj, ao=None):
    me = obj.data
    if "Col" in me.color_attributes:
        me.color_attributes.remove(me.color_attributes["Col"])
    attr = me.color_attributes.new("Col", 'FLOAT_COLOR', 'POINT')
    n = len(me.vertices)
    vals = np.zeros(n * 4, dtype=np.float32)
    vals[0::4] = 1.0 if ao is None else ao
    vals[1::4] = 0.0
    vals[2::4] = 0.5
    vals[3::4] = 1.0
    attr.data.foreach_set("color", vals)
    me.color_attributes.active_color = attr
    me.color_attributes.render_color_index = me.color_attributes.find("Col")


def bake_ao(objs):
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.device = 'CPU'
    sc.cycles.samples = 32
    if sc.world is None:
        sc.world = bpy.data.worlds.new("World")
    sc.world.light_settings.distance = 0.12
    for o in objs:
        ensure_color(o)
    for o in bpy.context.selected_objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    try:
        bpy.ops.object.bake(type='AO', target='VERTEX_COLORS', use_clear=True)
    except Exception as e:
        log("AO bake failed", e)
        return
    for o in objs:
        me = o.data
        n = len(me.vertices)
        vals = np.zeros(n * 4, dtype=np.float32)
        me.color_attributes["Col"].data.foreach_get("color", vals)
        ao = 0.42 + 0.58 * np.clip(vals[0::4], 0, 1) ** 0.85
        ensure_color(o, ao)


def export(rig, objs, path):
    for o in bpy.context.selected_objects:
        o.select_set(False)
    rig.select_set(True)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.gltf(
        filepath=path, export_format='GLB', use_selection=True, export_apply=False,
        export_yup=True, export_texcoords=False, export_normals=True, export_materials='EXPORT',
        export_vertex_color='ACTIVE', export_all_vertex_colors=False,
        export_skins=True, export_influence_nb=4, export_def_bones=False,
        export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True,
        export_optimize_animation_size=True, export_reset_pose_bones=True, export_rest_position_armature=True,
        export_extras=True)


def make_dog(quick):
    clear()
    body, eyes = build_dog(quick)
    bones = dog_bones()
    rig = build_armature(bones, "Dog")
    bake_ao([body])
    ensure_color(eyes)
    bind(body, rig, bones, dog_region)
    bind_rigid(eyes, rig, "head")
    write_actions(rig, DOG_CLIPS, DOG_LOOPS)
    path = os.path.join(OUT, "court_dog.glb")
    export(rig, [body, eyes], path)
    tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
    return {"glb": "court_dog.glb", "triangles": tris, "height": 0.74,
            "clips": {n: {"seconds": d, "loop": n in DOG_LOOPS} for n, (d, _) in DOG_CLIPS.items()},
            "speeds": DOG_SPEEDS}


def make_goat(quick):
    import court_animals_goat as goat
    return goat.make(quick)


MAKERS = {"dog": make_dog, "goat": make_goat}


def main():
    opts = args()
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, "court_animals.json")
    manifest = {"generator": "tools/blender/court_animals.py", "species": {}}
    if os.path.exists(path):
        try:
            with open(path, encoding="utf-8") as fh:
                manifest = json.load(fh)
        except Exception:
            pass
    for sp in opts["species"]:
        t0 = time.time()
        manifest["species"][sp] = MAKERS[sp](opts["quick"])
        log(sp, "done", manifest["species"][sp]["triangles"], "tris", "%.1fs" % (time.time() - t0))
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=1)


if __name__ == "__main__":
    main()

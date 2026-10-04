"""Build the props of the court's executions and its trophies, for Godot.

Run headless with Blender 5.2 (never opens a window):
  blender --background --factory-startup --python tools/blender/court_exec_props.py

Writes assets/court_sets/exec/court_exec_props.glb: one object per prop, its
origin where the prop is held or stands (a club and an axe at the grip's
end, a pot on its base, a stake at its foot), in the game's frame (x right,
y up, z toward the god), painted by slot like the sets (court_set_kit.py),
so scripts/hud/court_set_3d.gd dresses them in the set's own paint and ink.
assets/court_sets/exec/court_exec_props.json lists each prop: its size, where
it is held (grip), what sits on it (lid seat, head seat), and its era needs.
Props (more follow, act by act; docs in EXECUTIONS.md):
  cook_pot, cook_pot_lid, cook_ladle     the camp's cooking pot (act 2)
  cook_bag, cook_bag_lid                 before pottery: a paunch hung from a
                                         tripod, boiled with hot stones (act 2)
  club                                   a knobbed war club (act 2)
  block, axe_bronze                      a chopping block, a bronze axe (act 10)
  thighbone, skull                       what the dogs bring back (act 4)
  skull_stake                            a trophy by the door
  boulder, boulder_ledge                 a great stone, and the ledge two men tip it off (act 1)
  ash_pile                               what the fire leaves (act 3)
  spear_flint, spear_bronze              the watch's throwing spears (act 5)
  stone_a, stone_b, stone_c              stones for the whole court to throw (act 6)
  cauldron_clay, cauldron_bronze         the great cauldron over its coals (act 14)
  impaling_stake                         the stake (act 15)
  bow, arrow                             the archers' bow and arrows (act 16)
  gallows, noose_rope                    posts and beam, and a rope to stretch (act 11)
  wheel_solid                            a solid plank cart wheel (act 19; never name it
                                         "..._wheel": Godot takes that for a vehicle wheel)
  catapult, catapult_arm                 the frame, and its arm to swing (act 21)
  cannon, cannon_barrel                  the carriage, and its barrel (act 25)
  blade_frame, blade_knife               the falling blade's frame and basket, its blade (act 23)
  crucible, hoist                        glowing bronze in its furnace, the hoist over it (act 20)
  monolith, monolith_rig                 the great stone roped, and its timber rig (act 22)
  pit_gate, pit_gate_door                the beast pit's gate, and its door to swing (act 17)
  plinth                                 the bronze statue's plinth by the door (act 20)
"""
import os
import sys
import json
import math
import random

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True

import bpy
import bmesh
from mathutils import Vector, Matrix
from mathutils.noise import noise as _noise, fractal as _fractal

import court_set_kit as K

OUT = os.path.join(ROOT, "assets", "court_sets", "exec")
INFO = {}


def ellipsoid(bld, name, centre, radii, slot, segs=12, rings=8):
    """A smooth ellipsoid in the game frame (x right, y up, z to the god)."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=rings, radius=1.0)
    c = Vector(centre)
    for v in bm.verts:
        g = Vector(K.G(v.co))
        v.co = K.B(c + Vector((g.x * radii[0], g.y * radii[1], g.z * radii[2])))
    bm.normal_update()
    bld.add(name, bm, slot)


def cook_pot(bld):
    # a cooking pot: a round, wide belly on a rounded base, a narrow neck and
    # a rolled lip, sooted black up the belly from the fire, on three stones
    lift = 0.14
    for k in range(3):
        a = k / 3 * math.tau + 0.4
        K.rock(bld, "cook_pot", (math.cos(a) * 0.3, 0.05, math.sin(a) * 0.3), (0.15, 0.13, 0.14), seed=k * 2.1, slot="SOOT")
    lower = [(0.05, 0.0), (0.24, 0.035), (0.38, 0.12), (0.455, 0.25), (0.465, 0.33)]
    upper = [(0.465, 0.33), (0.44, 0.44), (0.35, 0.55), (0.24, 0.62), (0.195, 0.67), (0.215, 0.73), (0.245, 0.765), (0.21, 0.772), (0.185, 0.73)]
    bld.add("cook_pot", K.lathe(lower, segs=18, at=(0.0, lift, 0.0), wobble=0.015, seed=3.0, cap_bottom=True), "SOOT")
    bld.add("cook_pot", K.lathe(upper, segs=18, at=(0.0, lift, 0.0), wobble=0.015, seed=3.0, cap_bottom=False), "CLAY")
    # a sooty smudge feathering up from the black
    smudge = K.lathe([(0.466, 0.33), (0.452, 0.4), (0.425, 0.46)], segs=18, at=(0.0, lift, 0.0), wobble=0.015, seed=3.0, cap_bottom=False)
    K.thicken(smudge, 0.002)
    bld.add("cook_pot", smudge, "SOOT")
    surface = K.disc_fn(0.19, 16, lambda x, z: K.B((x, lift + 0.725 + 0.004 * _noise(Vector((x * 9, z * 9, 1.0))), z)))
    bld.add("cook_pot", surface, "BROTH")
    for k in range(4):
        a = k * 1.6
        K.lumps(bld, "cook_pot", (math.cos(a) * 0.08, lift + 0.725, math.sin(a) * 0.08), 0.04, 0.01, 1, 0.035, seed=k, slot="FOOD_ROOT")
    INFO["cook_pot"] = {"size": [0.95, 0.92, 0.95], "lid_seat": [0.0, lift + 0.772, 0.0], "head_seat": [0.0, lift + 0.72, 0.0],
                        "broth": [0.0, lift + 0.727, 0.0], "broth_radius": 0.19, "needs": ["pottery"], "acts": [2, 14]}
    # the lid: a wooden disc with a knob, sat on the pot's lip
    lid = K.lathe([(0.0, 0.0), (0.27, 0.0), (0.28, 0.025), (0.2, 0.045), (0.05, 0.05), (0.06, 0.1), (0.0, 0.11)], segs=20, at=(0, 0, 0))
    bld.add("cook_pot_lid", lid, "PLANK")
    INFO["cook_pot_lid"] = {"size": [0.56, 0.11, 0.56], "needs": ["pottery"], "acts": [2]}
    # a long stirring paddle
    K.log_piece(bld, "cook_ladle", (0.0, 0.0, 0.0), (0.0, 1.05, 0.0), 0.018, seed=4, slot="WOOD", end_slot="WOOD_END", knots=False, bend=0.02, stubs=0, cut=(0.0, 0.0))
    blade = K.sheet(2, 3, lambda u, v: K.B(((u - 0.5) * 0.09 * (1.0 - 0.3 * v), -0.18 * v, 0.0)))
    K.thicken(blade, 0.014)
    bld.add("cook_ladle", blade, "WOOD")
    INFO["cook_ladle"] = {"size": [0.1, 1.25, 0.02], "grip": [0.0, 1.0, 0.0], "acts": [2, 14]}


def cook_bag(bld):
    # before pots: a paunch slung from a tripod of poles, broth boiled in it by
    # dropping in hot stones from the fire (the heap beside it, the tongs)
    apex = Vector((0.0, 1.5, 0.0))
    for k in range(3):
        a = k / 3 * math.tau + 0.3
        foot = Vector((math.cos(a) * 0.62, 0.0, math.sin(a) * 0.62))
        top = apex + (apex - foot).normalized() * 0.16
        K.log_piece(bld, "cook_bag", tuple(foot), tuple(top), 0.024, seed=k * 1.7, slot="WOOD", end_slot="WOOD_END", knots=False, bend=0.03, stubs=0, cut=(0.0, 0.0))
    lash, lcaps = K.tube([(0.0, 1.44, 0.0), (0.0, 1.55, 0.0)], [0.05, 0.05], segs=9, caps=True)
    bld.add("cook_bag", lash, "CORD")
    bld.add("cook_bag", lcaps, "CORD")
    r, bottom, rim = 0.3, 0.46, 0.98
    prof = [(0.02, bottom), (r * 0.72, bottom + 0.06), (r, bottom + 0.24), (r * 0.98, bottom + 0.4), (r * 0.86, rim - 0.04), (r * 0.92, rim)]
    bag = K.lathe(prof, segs=16, at=(0.0, 0.0, 0.0), wobble=0.07, seed=2.0, wall=0.012)
    bld.add("cook_bag", bag, "HIDE")
    for k in range(4):
        a = k / 4 * math.tau
        K.cord(bld, "cook_bag", (math.cos(a) * r * 0.9, rim, math.sin(a) * r * 0.9), (0.0, 1.46, 0.0), r=0.007, sag=0.01)
    surface = K.disc_fn(r * 0.8, 16, lambda x, z: K.B((x, rim - 0.1 + 0.006 * _noise(Vector((x * 9, z * 9, 2.0))), z)))
    bld.add("cook_bag", surface, "BROTH")
    # hot stones by the bag, and a pair of green-stick tongs
    for k in range(6):
        a = 2.4 + k * 0.5
        K.rock(bld, "cook_bag", (math.cos(a) * 0.55 + 0.1, 0.05, math.sin(a) * 0.4 + 0.25), (0.07, 0.055, 0.065), seed=k * 1.3 + 4, slot="SOOT", subdiv=1)
    for s in (-1, 1):
        K.log_piece(bld, "cook_bag", (0.45, 0.02, 0.55 + s * 0.02), (0.9, 0.05, 0.3 + s * 0.05), 0.011, seed=s + 7, slot="WOOD", end_slot="WOOD_END", knots=False, bend=0.02, stubs=0, cut=(0.0, 0.0))
    INFO["cook_bag"] = {"size": [1.3, 1.6, 1.3], "lid_seat": [0.0, rim, 0.0], "head_seat": [0.0, rim - 0.1, 0.0],
                        "broth": [0.0, rim - 0.097, 0.0], "broth_radius": r * 0.8, "acts": [2, 14]}
    # its lid: a round of stiff hide with a wooden toggle
    lid = K.lathe([(0.0, 0.0), (r * 0.98, 0.0), (r * 1.02, 0.02), (r * 0.7, 0.045), (0.05, 0.055), (0.0, 0.06)], segs=16, at=(0, 0, 0), wobble=0.05, seed=5.0)
    bld.add("cook_bag_lid", lid, "HIDE_DARK")
    tog, tcaps = K.tube([(-0.05, 0.065, 0.0), (0.05, 0.065, 0.0)], [0.012, 0.012], segs=6, caps=True)
    bld.add("cook_bag_lid", tog, "WOOD")
    bld.add("cook_bag_lid", tcaps, "WOOD_END")
    INFO["cook_bag_lid"] = {"size": [0.62, 0.08, 0.62], "acts": [2]}


def club(bld):
    # a war club: a tapering haft swelling into a knotty head, a leather grip
    path = [(0.0, 0.0, 0.0), (0.0, 0.25, 0.0), (0.0, 0.5, 0.01), (0.01, 0.72, 0.0), (0.0, 0.86, 0.0)]
    bm, caps = K.tube(path, [0.022, 0.025, 0.032, 0.05, 0.07], segs=10, caps=True, wobble=0.12, seed=2.0)
    bld.add("club", bm, "WOOD")
    bld.add("club", caps, "WOOD_END")
    for k in range(6):
        a = k * 1.1
        y = 0.68 + 0.035 * k
        K.rock(bld, "club", (math.cos(a) * 0.06, y, math.sin(a) * 0.06), (0.03, 0.025, 0.03), seed=k + 9, slot="WOOD", subdiv=1)
    wrap, wcaps = K.tube([(0.0, 0.02, 0.0), (0.0, 0.2, 0.0)], [0.027, 0.028], segs=10, caps=True)
    bld.add("club", wrap, "HIDE_DARK")
    bld.add("club", wcaps, "HIDE_DARK")
    INFO["club"] = {"size": [0.16, 0.92, 0.16], "grip": [0.0, 0.1, 0.0], "head": [0.0, 0.78, 0.0], "acts": [2]}


def block(bld):
    # a squat stump on its roots, chopped flat, scored by old blows, darkly stained
    path = [(0.0, -0.04, 0.0), (0.0, 0.2, 0.0), (0.0, 0.44, 0.0)]
    bm, caps = K.tube(path, [0.27, 0.24, 0.23], segs=16, caps=True, wobble=0.06, seed=5.0, flat=0.92)
    bld.add("block", bm, "BARK")
    bld.add("block", caps, "WOOD_END")
    rng = random.Random(7)
    for k in range(5):
        a = k / 5 * math.tau + rng.uniform(-0.3, 0.3)
        root, rcaps = K.tube([(math.cos(a) * 0.18, 0.06, math.sin(a) * 0.18), (math.cos(a) * 0.38, -0.02, math.sin(a) * 0.38)], [0.07, 0.03], segs=7, caps=True, wobble=0.1, seed=k)
        bld.add("block", root, "BARK")
        bld.add("block", rcaps, "BARK")
    # gashes across the top: thin dark wedges
    for k in range(6):
        a = rng.uniform(0, math.pi)
        c = Vector((rng.uniform(-0.08, 0.08), 0.443, rng.uniform(-0.08, 0.08)))
        d = Vector((math.cos(a), 0, math.sin(a))) * rng.uniform(0.08, 0.15)
        side = Vector((-d.z, 0, d.x)).normalized() * 0.006
        verts = [K.B(c - d - side), K.B(c + d - side), K.B(c + d + side), K.B(c - d + side)]
        bld.add("block", K._bm_from(verts, [(0, 1, 2, 3)]), "SOCKET")
    stain = K.disc_fn(0.14, 14, lambda x, z: K.B((x + 0.03, 0.444, z * 0.7 + 0.04)))
    bld.add("block", stain, "BLOOD_DRY")
    INFO["block"] = {"size": [0.6, 0.45, 0.6], "neck_seat": [0.0, 0.45, 0.12], "axe_bite": [0.0, 0.44, 0.02], "acts": [10]}


def axe_bronze(bld):
    # a bronze crescent axe on a long haft, lashed through a socket
    path = [(0.0, 0.0, 0.0), (0.0, 0.45, 0.0), (0.0, 0.9, 0.0)]
    bm, caps = K.tube(path, [0.022, 0.021, 0.02], segs=9, caps=True, wobble=0.03, seed=1.0)
    bld.add("axe_bronze", bm, "WOOD")
    bld.add("axe_bronze", caps, "WOOD_END")
    sock, scaps = K.tube([(0.0, 0.76, 0.0), (0.0, 0.88, 0.0)], [0.032, 0.03], segs=10, caps=True)
    bld.add("axe_bronze", sock, "BRONZE")
    bld.add("axe_bronze", scaps, "BRONZE")
    # the blade: a crescent fanned out in front (+z), thin
    pts = []
    for k in range(13):
        t = k / 12
        a = (t - 0.5) * 2.0
        y = 0.82 + a * 0.13
        z = 0.04 + 0.2 * math.cos(a * 1.15) ** 0.6
        pts.append((y, z))
    outline = [(0.86, 0.035), (0.79, 0.035)] + [(pts[k][0], pts[k][1]) for k in range(13)]
    verts = []
    for th in (0.008, -0.008):
        for y, z in outline:
            verts.append(K.B((th, y, z)))
    n = len(outline)
    faces = [tuple(range(n)), tuple(reversed(range(n, 2 * n)))]
    for k in range(n):
        a, b = k, (k + 1) % n
        faces.append((a, b, b + n, a + n))
    bld.add("axe_bronze", K._bm_from(verts, faces), "BRONZE")
    for k in range(3):
        wrap, wcaps = K.tube([(0.0, 0.74 - k * 0.025, 0.0), (0.0, 0.75 - k * 0.025, 0.0)], [0.026, 0.026], segs=8, caps=True)
        bld.add("axe_bronze", wrap, "CORD")
        bld.add("axe_bronze", wcaps, "CORD")
    INFO["axe_bronze"] = {"size": [0.06, 0.96, 0.3], "grip": [0.0, 0.08, 0.0], "edge": [0.0, 0.82, 0.24], "needs": ["metal"], "acts": [10]}


def thighbone(bld):
    # a cartoon femur: a shaft with knobbed ends, a few gnaw marks
    bm, caps = K.tube([(-0.17, 0.0, 0.0), (0.0, 0.004, 0.0), (0.17, 0.0, 0.0)], [0.024, 0.02, 0.024], segs=10, caps=True, wobble=0.04, seed=3)
    bld.add("thighbone", bm, "BONE")
    bld.add("thighbone", caps, "BONE")
    for s in (-1, 1):
        for k in (-1, 1):
            K.rock(bld, "thighbone", (s * 0.19, 0.0, k * 0.022), (0.035, 0.033, 0.035), seed=s + k * 3, slot="BONE", subdiv=2)
    INFO["thighbone"] = {"size": [0.45, 0.07, 0.1], "bite": [0.0, 0.0, 0.0], "acts": [4]}


def skull(bld, name="skull", at=(0.0, 0.0, 0.0), scale=1.0, seed=0.0):
    """A cartoon skull that reads across a hall: a round cranium, big dark eye
    sockets, a nose hole, a dark band of shadow under the cheekbones with a
    row of teeth, and a jaw below. Origin at the bottom of the jaw; it looks
    toward +z."""
    c = Vector(at)
    sc = scale
    cr = c + Vector((0.0, 0.118, 0.0)) * sc
    rx, ry, rz = 0.085 * sc, 0.088 * sc, 0.097 * sc
    ellipsoid(bld, name, tuple(cr), (rx, ry, rz), "SKULL", segs=12, rings=8)
    # cheekbones: the face's front a little wider than the cranium's curve
    ellipsoid(bld, name, tuple(c + Vector((0.0, 0.085, 0.045)) * sc), (0.07 * sc, 0.035 * sc, 0.05 * sc), "SKULL", segs=8, rings=5)
    # the jaw
    ellipsoid(bld, name, tuple(c + Vector((0.0, 0.032, 0.04)) * sc), (0.052 * sc, 0.03 * sc, 0.048 * sc), "SKULL", segs=8, rings=5)

    def on_face(dx, dy, out=0.004):
        d = Vector((dx, dy, math.sqrt(max(0.0, 1.0 - dx * dx - dy * dy))))
        return cr + Vector((d.x * rx, d.y * ry, d.z * rz)) + d * out * sc
    for side in (-1, 1):
        ellipsoid(bld, name, tuple(on_face(side * 0.4, -0.05)), (0.027 * sc, 0.026 * sc, 0.012 * sc), "SOCKET", segs=8, rings=5)
    ellipsoid(bld, name, tuple(on_face(0.0, -0.36, 0.006)), (0.012 * sc, 0.017 * sc, 0.009 * sc), "SOCKET", segs=6, rings=4)
    # the shadow under the cheekbones, the teeth across it
    ellipsoid(bld, name, tuple(c + Vector((0.0, 0.056, 0.085)) * sc), (0.046 * sc, 0.016 * sc, 0.014 * sc), "SOCKET", segs=8, rings=5)
    for k in range(4):
        x = (k - 1.5) * 0.017
        ellipsoid(bld, name, tuple(c + Vector((x, 0.056, 0.094 - abs(x) * 0.25)) * sc), (0.0075 * sc, 0.012 * sc, 0.006 * sc), "SKULL", segs=5, rings=3)


def skull_stake(bld):
    K.post(bld, "skull_stake", (0.0, 0.0, 0.0), 1.55, 0.03, seed=2, slot="WOOD", pointed=True)
    skull(bld, "skull_stake", at=(0.0, 1.42, 0.0), scale=1.0, seed=4.0)
    INFO["skull_stake"] = {"size": [0.2, 1.7, 0.2], "acts": []}


def boulder(bld):
    K.rock(bld, "boulder", (0.0, 0.17, 0.0), (0.5, 0.46, 0.46), seed=12.0, slot="STONE", flat=1.0, subdiv=3)
    INFO["boulder"] = {"size": [1.0, 0.78, 0.9], "acts": [1]}


def ash_pile(bld):
    # what the fire leaves (act 3): a grey heap, coals still glowing in it, a
    # charred stick or two; the elder warms his hands over it
    K.heap(bld, "ash_pile", (0.0, 0.0, 0.0), 0.34, 0.17, seed=2.0, slot="ASH")
    K.lumps(bld, "ash_pile", (0.0, 0.1, 0.0), 0.2, 0.06, 7, 0.035, seed=3, slot="EMBER")
    for k in range(2):
        a = 0.6 + k * 2.2
        K.log_piece(bld, "ash_pile", (math.cos(a) * 0.32, 0.03, math.sin(a) * 0.32), (math.cos(a) * 0.05, 0.12, math.sin(a) * 0.05), 0.025,
                    seed=k + 2, slot="CHAR", end_slot="CHAR", knots=False, bend=0.03, stubs=0, cut=(0.0, 0.0))
    INFO["ash_pile"] = {"size": [0.7, 0.2, 0.7], "acts": [3]}


def spears(bld):
    # throwing spears for the watch (act 5): a flint head, or once they have
    # metal a bronze one; held at the balance, they fly tip first
    K.spear(bld, "spear_flint", (0.0, 0.0, 0.0), (0.0, 2.0, 0.0), seed=1.0, head_slot="FLINT", r=0.017, head=0.2)
    INFO["spear_flint"] = {"size": [0.07, 2.0, 0.02], "grip": [0.0, 0.85, 0.0], "tip": [0.0, 2.0, 0.0], "acts": [5]}
    K.spear(bld, "spear_bronze", (0.0, 0.0, 0.0), (0.0, 2.0, 0.0), seed=2.0, head_slot="BRONZE", r=0.017, head=0.24)
    INFO["spear_bronze"] = {"size": [0.08, 2.0, 0.02], "grip": [0.0, 0.85, 0.0], "tip": [0.0, 2.0, 0.0], "needs": ["metal"], "acts": [5]}


def stones(bld):
    # stones for the whole court to throw (act 6): fist-sized and bigger
    for k, (name, size) in enumerate([("stone_a", 0.075), ("stone_b", 0.095), ("stone_c", 0.13)]):
        K.rock(bld, name, (0.0, 0.0, 0.0), (size, size * 0.8, size * 0.9), seed=k * 3.7 + 1, slot="STONE", flat=1.0, subdiv=2)
        INFO[name] = {"size": [size * 2, size * 1.6, size * 1.8], "acts": [6]}


def boulder_ledge(bld):
    # a ledge of piled rock for two men to tip the boulder off (act 1)
    rng = random.Random(4)
    for k in range(7):
        x = (k % 4 - 1.5) * 0.36 + rng.uniform(-0.05, 0.05)
        z = (k // 4) * 0.35 - 0.15 + rng.uniform(-0.05, 0.05)
        K.rock(bld, "boulder_ledge", (x, 0.12, z), (0.26, 0.3, 0.24), seed=k * 1.9 + 5, slot="STONE", flat=1.0, subdiv=2)
    for k in range(3):
        x = (k - 1) * 0.42
        K.rock(bld, "boulder_ledge", (x, 0.5, 0.0), (0.3, 0.22, 0.3), seed=k * 2.3 + 11, slot="STONE_DARK", flat=1.0, subdiv=2)
    # a flat slab on top, and the lever pole leaning ready
    K.rock(bld, "boulder_ledge", (0.0, 0.72, 0.0), (0.62, 0.1, 0.42), seed=17.0, slot="STONE", flat=1.0, subdiv=2)
    K.log_piece(bld, "boulder_ledge", (-0.9, 0.0, 0.45), (-0.25, 1.5, 0.1), 0.035, seed=3, slot="WOOD", end_slot="WOOD_END", knots=True, bend=0.03, stubs=0, cut=(0.0, 0.0))
    INFO["boulder_ledge"] = {"size": [1.6, 0.85, 1.0], "boulder_seat": [0.0, 0.8, 0.0], "tip_edge": [0.0, 0.8, 0.45], "acts": [1]}


def cauldron_clay(bld):
    # a great clay vat on four stones over a bed of coals (act 14, pottery)
    lift = 0.24
    for k in range(4):
        a = k / 4 * math.tau + 0.78
        K.rock(bld, "cauldron_clay", (math.cos(a) * 0.48, 0.08, math.sin(a) * 0.48), (0.2, 0.26, 0.18), seed=k * 1.7, slot="SOOT", flat=1.0)
    for k in range(3):
        a = k / 3 * math.tau + 0.2
        K.log_piece(bld, "cauldron_clay", (math.cos(a) * 0.62, 0.05, math.sin(a) * 0.62), (math.cos(a) * 0.08, 0.1, math.sin(a) * 0.08), 0.045,
                    seed=k + 9, slot="BARK", end_slot="CHAR", knots=False, bend=0.03, stubs=0, cut=(0.0, 0.0))
    K.lumps(bld, "cauldron_clay", (0.0, 0.05, 0.0), 0.25, 0.04, 6, 0.04, seed=1, slot="EMBER")
    prof = [(0.2, 0.0), (0.42, 0.08), (0.56, 0.26), (0.6, 0.46), (0.62, 0.6), (0.66, 0.65)]
    bld.add("cauldron_clay", K.lathe(prof, segs=22, at=(0.0, lift, 0.0), wobble=0.02, seed=6.0, wall=0.035), "CLAY")
    soot = K.lathe([(0.2 * 1.01, 0.0), (0.424, 0.08), (0.565, 0.26), (0.603, 0.4)], segs=22, at=(0.0, lift, 0.0), wobble=0.02, seed=6.0, cap_bottom=True)
    K.thicken(soot, 0.004)
    bld.add("cauldron_clay", soot, "SOOT")
    surface = K.disc_fn(0.575, 22, lambda x, z: K.B((x, lift + 0.52 + 0.006 * _noise(Vector((x * 6, z * 6, 3.0))), z)))
    bld.add("cauldron_clay", surface, "BROTH")
    INFO["cauldron_clay"] = {"size": [1.35, 0.9, 1.35], "broth": [0.0, lift + 0.522, 0.0], "broth_radius": 0.57, "fire_seat": [0.0, 0.06, 0.0],
                             "body_seat": [0.0, lift + 0.12, 0.0], "rim": [0.0, lift + 0.65, 0.0], "needs": ["pottery"], "acts": [14]}


def cauldron_bronze(bld):
    # a bronze cauldron on three cast legs, ring handles at the rim (act 14, metal)
    lift = 0.36
    prof = [(0.1, 0.0), (0.36, 0.05), (0.52, 0.2), (0.56, 0.38), (0.52, 0.54), (0.56, 0.6)]
    bld.add("cauldron_bronze", K.lathe(prof, segs=24, at=(0.0, lift, 0.0), wobble=0.005, seed=2.0, wall=0.025), "BRONZE")
    soot = K.lathe([(0.1 * 1.01, 0.0), (0.363, 0.05), (0.5245, 0.2)], segs=24, at=(0.0, lift, 0.0), wobble=0.005, seed=2.0, cap_bottom=True)
    K.thicken(soot, 0.004)
    bld.add("cauldron_bronze", soot, "SOOT")
    for k in range(3):
        a = k / 3 * math.tau + 0.5
        top = (math.cos(a) * 0.4, lift + 0.08, math.sin(a) * 0.4)
        foot = (math.cos(a) * 0.5, 0.0, math.sin(a) * 0.5)
        leg, caps = K.tube([top, ((top[0] + foot[0]) / 2, lift * 0.45, (top[2] + foot[2]) / 2), foot], [0.045, 0.035, 0.05], segs=8, caps=True)
        bld.add("cauldron_bronze", leg, "BRONZE")
        bld.add("cauldron_bronze", caps, "BRONZE")
    for s in (-1, 1):
        ring = []
        for k in range(9):
            t = k / 8 * math.pi
            ring.append((s * (0.56 + 0.1 * math.sin(t)), lift + 0.6 + 0.1 * math.cos(t) - 0.02, 0.0))
        bm, caps = K.tube(ring, [0.018] * len(ring), segs=6, caps=True)
        bld.add("cauldron_bronze", bm, "BRONZE")
        bld.add("cauldron_bronze", caps, "BRONZE")
    for k in range(3):
        a = k / 3 * math.tau + 1.5
        K.log_piece(bld, "cauldron_bronze", (math.cos(a) * 0.5, 0.05, math.sin(a) * 0.5), (math.cos(a) * 0.06, 0.1, math.sin(a) * 0.06), 0.04,
                    seed=k + 4, slot="BARK", end_slot="CHAR", knots=False, bend=0.03, stubs=0, cut=(0.0, 0.0))
    K.lumps(bld, "cauldron_bronze", (0.0, 0.05, 0.0), 0.22, 0.04, 5, 0.04, seed=2, slot="EMBER")
    surface = K.disc_fn(0.51, 22, lambda x, z: K.B((x, lift + 0.48 + 0.005 * _noise(Vector((x * 6, z * 6, 5.0))), z)))
    bld.add("cauldron_bronze", surface, "BROTH")
    INFO["cauldron_bronze"] = {"size": [1.32, 0.98, 1.15], "broth": [0.0, lift + 0.482, 0.0], "broth_radius": 0.5, "fire_seat": [0.0, 0.06, 0.0],
                               "body_seat": [0.0, lift + 0.1, 0.0], "rim": [0.0, lift + 0.6, 0.0], "needs": ["metal"], "acts": [14]}


def bow_and_arrow(bld):
    # a self bow, its back bowed toward the mark (+z), the string toward the
    # archer; an arrow with a flint head and three pale feathers (act 16)
    path = []
    radii = []
    for k in range(11):
        y = (k / 10 - 0.5) * 1.4
        t = abs(y) / 0.7
        path.append((0.0, y, 0.11 * (1.0 - t * t)))
        radii.append(0.016 * (1.0 - 0.5 * t))
    bm, caps = K.tube(path, radii, segs=7, caps=True)
    bld.add("bow", bm, "WOOD")
    bld.add("bow", caps, "WOOD_END")
    grip, gcaps = K.tube([(0.0, -0.06, 0.112), (0.0, 0.06, 0.112)], [0.02, 0.02], segs=7, caps=True)
    bld.add("bow", grip, "HIDE_DARK")
    bld.add("bow", gcaps, "HIDE_DARK")
    K.cord(bld, "bow", (0.0, -0.69, 0.0), (0.0, 0.69, 0.0), r=0.003, sag=0.0)
    INFO["bow"] = {"size": [0.04, 1.4, 0.13], "grip": [0.0, 0.0, 0.112], "acts": [16], "known_any": ["bow_craft", "composite_bow"]}
    K.spear(bld, "arrow", (0.0, 0.0, 0.0), (0.0, 0.78, 0.0), seed=3.0, head_slot="FLINT", r=0.0055, head=0.05, binding=False)
    for k in range(3):
        a = k / 3 * math.tau
        d = Vector((math.cos(a), 0.0, math.sin(a)))
        pts = [Vector((0.0, 0.03, 0.0)) + d * 0.005, Vector((0.0, 0.14, 0.0)) + d * 0.005, Vector((0.0, 0.1, 0.0)) + d * 0.03, Vector((0.0, 0.035, 0.0)) + d * 0.028]
        fin = K._bm_from([K.B(p) for p in pts], [(0, 1, 2, 3)])
        K.thicken(fin, 0.002)
        bld.add("arrow", fin, "FLETCH")
    INFO["arrow"] = {"size": [0.06, 0.78, 0.06], "tip": [0.0, 0.78, 0.0], "grip": [0.0, 0.05, 0.0], "acts": [16], "known_any": ["bow_craft", "composite_bow"]}


def impaling_stake(bld):
    # the stake (act 15): a tall pole sharpened to a point, its top darkly
    # stained, planted in a heap of wedging stones
    K.post(bld, "impaling_stake", (0.0, 0.0, 0.0), 2.6, 0.055, seed=6, slot="WOOD", pointed=True, segs=9)
    stain, scaps = K.tube([(0.0, 2.0, 0.0), (0.0, 2.35, 0.0), (0.0, 2.6, 0.0)], [0.058, 0.055, 0.03], segs=9, caps=False, wobble=0.05, seed=2.0)
    bld.add("impaling_stake", stain, "BLOOD_DRY")
    for k in range(6):
        a = k / 6 * math.tau + 0.3
        K.rock(bld, "impaling_stake", (math.cos(a) * 0.22, 0.04, math.sin(a) * 0.22), (0.13, 0.12, 0.12), seed=k * 1.3 + 2, slot="STONE", flat=1.0, subdiv=1)
    INFO["impaling_stake"] = {"size": [0.6, 2.7, 0.6], "top": [0.0, 2.68, 0.0], "eye_level": [0.0, 1.6, 0.0], "acts": [15]}


def box(bld, name, centre, half, slot, rot_y=0.0):
    """An axis-aligned (then turned about y) box in the game frame."""
    c = Vector(centre)
    hx, hy, hz = half
    cy, sy = math.cos(rot_y), math.sin(rot_y)
    pts = []
    for dx, dy, dz in [(-1, -1, -1), (1, -1, -1), (1, 1, -1), (-1, 1, -1), (-1, -1, 1), (1, -1, 1), (1, 1, 1), (-1, 1, 1)]:
        x, z = dx * hx, dz * hz
        pts.append(K.B(c + Vector((x * cy + z * sy, dy * hy, -x * sy + z * cy))))
    faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (2, 3, 7, 6), (1, 2, 6, 5), (0, 4, 7, 3)]
    bld.add(name, K._bm_from(pts, faces), slot)


def beam(bld, name, a, b, r, slot="WOOD", seed=0.0, end_slot="WOOD_END"):
    K.log_piece(bld, name, a, b, r, seed=seed, slot=slot, end_slot=end_slot, knots=False, bend=0.01, stubs=0, cut=(0.0, 0.0))


def gallows(bld):
    # act 11: two posts and a beam, a stump to stand on; the rope is its own
    # prop (noose_rope) hung from the beam's middle, so it can be stretched
    for x in (-1.3, 1.3):
        K.post(bld, "gallows", (x, 0.0, 0.0), 3.0, 0.08, seed=x + 3, slot="WOOD", pointed=False, segs=9)
        for k in range(4):
            a = k / 4 * math.tau + 0.4
            K.rock(bld, "gallows", (x + math.cos(a) * 0.18, 0.04, math.sin(a) * 0.18), (0.11, 0.1, 0.1), seed=k + x * 3, slot="STONE", flat=1.0, subdiv=1)
        brace = (x * 0.62, 2.55, 0.0)
        beam(bld, "gallows", (x, 2.3, 0.0), brace, 0.04, seed=x + 9)
    beam(bld, "gallows", (-1.55, 2.95, 0.0), (1.55, 2.95, 0.0), 0.09, seed=5)
    K.log_piece(bld, "gallows", (-0.22, 0.0, 0.0), (0.22, 0.0, 0.0), 0.19, seed=8, slot="BARK", end_slot="WOOD_END", knots=False, bend=0.0, stubs=0, cut=(0.0, 0.0))
    for k in range(5):
        a = k / 5 * math.tau
        K.cord(bld, "gallows", (math.cos(a) * 0.1, 2.97, math.sin(a) * 0.1 - 0.0), (math.cos(a + 0.6) * 0.1, 2.93, math.sin(a + 0.6) * 0.1), r=0.012, sag=0.0, slot="ROPE")
    INFO["gallows"] = {"size": [3.2, 3.1, 0.5], "rope_seat": [0.0, 2.86, 0.0], "stand_seat": [0.0, 0.19, 0.0], "acts": [11], "known_any": ["cordage"]}
    # the rope: from the beam down a metre, a noose at its end (scale y to stretch)
    rope, rcaps = K.tube([(0.0, 0.0, 0.0), (0.0, -0.5, 0.005), (0.0, -0.85, 0.0)], [0.016, 0.016, 0.016], segs=6, caps=True)
    bld.add("noose_rope", rope, "ROPE")
    bld.add("noose_rope", rcaps, "ROPE")
    loop = []
    for k in range(13):
        t = k / 12 * math.tau
        loop.append((0.11 * math.sin(t), -0.98 + 0.13 * math.cos(t), 0.04 * math.sin(t * 2.0)))
    lb, lcaps = K.tube(loop, [0.016] * 13, segs=6, caps=True)
    bld.add("noose_rope", lb, "ROPE")
    bld.add("noose_rope", lcaps, "ROPE")
    wrap, wcaps = K.tube([(0.0, -0.82, 0.0), (0.0, -0.9, 0.0)], [0.026, 0.026], segs=6, caps=True)
    bld.add("noose_rope", wrap, "ROPE")
    bld.add("noose_rope", wcaps, "ROPE")
    INFO["noose_rope"] = {"size": [0.24, 1.12, 0.1], "noose": [0.0, -0.98, 0.0], "acts": [11], "known_any": ["cordage"]}


def cart_wheel(bld):
    # act 19: a solid wheel of three planks clamped by battens, a hub and an
    # axle hole; it stands in the x-y plane and rolls along x
    r = 0.52
    for k, (x0, x1) in enumerate([(-r, -0.17), (-0.17, 0.17), (0.17, r)]):
        verts = []
        prof = []
        for i in range(9):
            y = -r + 2 * r * i / 8
            w = math.sqrt(max(0.0, r * r - y * y))
            prof.append((max(x0, -w), min(x1, w), y))
        top = [K.B((a, y, 0.04)) for a, b, y in prof] + [K.B((b, y, 0.04)) for a, b, y in reversed(prof)]
        bot = [K.B((a, y, -0.04)) for a, b, y in prof] + [K.B((b, y, -0.04)) for a, b, y in reversed(prof)]
        n = len(top)
        faces = [tuple(range(n)), tuple(reversed(range(n, 2 * n)))]
        for i in range(n):
            faces.append((i, (i + 1) % n, (i + 1) % n + n, i + n))
        bld.add("wheel_solid", K._bm_from(top + bot, faces), "PLANK")
    for y in (-0.28, 0.28):
        w = math.sqrt(r * r - y * y) * 0.9
        box(bld, "wheel_solid", (0.0, y, 0.055), (w, 0.04, 0.015), "WOOD")
    hub, hcaps = K.tube([(0.0, 0.0, -0.16), (0.0, 0.0, 0.16)], [0.1, 0.1], segs=12, caps=True)
    bld.add("wheel_solid", hub, "WOOD")
    bld.add("wheel_solid", hcaps, "SOCKET")
    INFO["wheel_solid"] = {"size": [1.04, 1.04, 0.32], "radius": r, "axle": [0.0, 0.0, 0.0], "needs": ["wheel"], "acts": [19]}


def catapult(bld):
    # act 21: a frame on runners, and its throwing arm as its own prop
    # (catapult_arm, pivot at the arm's origin): it rests with the cup low
    # behind (-z) and is turned about x to fling over the front
    for x in (-0.55, 0.55):
        beam(bld, "catapult", (x, 0.08, -1.3), (x, 0.08, 1.3), 0.08, seed=x + 1)
        beam(bld, "catapult", (x, 0.08, -0.7), (x * 0.7, 1.55, 0.0), 0.06, seed=x + 2)
        beam(bld, "catapult", (x, 0.08, 0.7), (x * 0.7, 1.55, 0.0), 0.06, seed=x + 3)
    beam(bld, "catapult", (-0.6, 0.12, -1.1), (0.6, 0.12, -1.1), 0.05, seed=4)
    beam(bld, "catapult", (-0.6, 0.12, 1.1), (0.6, 0.12, 1.1), 0.05, seed=5)
    axle, acaps = K.tube([(-0.5, 1.5, 0.0), (0.5, 1.5, 0.0)], [0.05, 0.05], segs=9, caps=True)
    bld.add("catapult", axle, "WOOD")
    bld.add("catapult", acaps, "WOOD_END")
    # the stop bar the arm slams into
    beam(bld, "catapult", (-0.45, 1.25, 0.75), (0.45, 1.25, 0.75), 0.06, seed=7)
    INFO["catapult"] = {"size": [1.3, 1.6, 2.7], "arm_pivot": [0.0, 1.5, 0.0], "acts": [21], "needs": ["wheel", "metal"]}
    beam(bld, "catapult_arm", (0.0, 0.0, 0.7), (0.0, -0.05, -2.3), 0.07, seed=8)
    cup = K.lathe([(0.04, 0.0), (0.22, 0.02), (0.3, 0.12), (0.32, 0.16)], segs=14, at=(0.0, -0.08, -2.35), wall=0.02)
    bld.add("catapult_arm", cup, "WOOD")
    for k in range(4):
        a = k / 4 * math.tau + 0.4
        K.cord(bld, "catapult_arm", (math.cos(a) * 0.04, 0.0, 0.7), (math.cos(a) * 0.3, -0.6, 0.7 + math.sin(a) * 0.3), r=0.01, sag=0.02, slot="ROPE")
    INFO["catapult_arm"] = {"size": [0.64, 0.7, 3.1], "cup": [0.0, 0.0, -2.35], "acts": [21]}


def cannon(bld):
    # act 25: a cast barrel on a wheeled carriage; the barrel is its own
    # prop (cannon_barrel, origin at the trunnions, the muzzle toward +z)
    for x in (-0.28, 0.28):
        box(bld, "cannon", (x, 0.5, -0.25), (0.05, 0.16, 0.85), "WOOD")
        hub, hcaps = K.tube([(x * 1.9 - 0.06, 0.45, 0.25), (x * 1.9 + 0.06, 0.45, 0.25)], [0.07, 0.07], segs=10, caps=True)
        bld.add("cannon", hub, "WOOD")
        bld.add("cannon", hcaps, "IRON")
        rim = []
        for k in range(25):
            t = k / 24 * math.tau
            rim.append((x * 1.9, 0.45 + 0.44 * math.cos(t), 0.25 + 0.44 * math.sin(t)))
        rb, rcaps = K.tube(rim, [0.04] * 25, segs=6, caps=False)
        bld.add("cannon", rb, "WOOD")
        for k in range(8):
            t = k / 8 * math.tau
            sp, scaps = K.tube([(x * 1.9, 0.45, 0.25), (x * 1.9, 0.45 + 0.42 * math.cos(t), 0.25 + 0.42 * math.sin(t))], [0.022, 0.018], segs=5, caps=False)
            bld.add("cannon", sp, "WOOD")
    ax, acaps = K.tube([(-0.6, 0.45, 0.25), (0.6, 0.45, 0.25)], [0.045, 0.045], segs=8, caps=True)
    bld.add("cannon", ax, "IRON")
    bld.add("cannon", acaps, "IRON")
    beam(bld, "cannon", (0.0, 0.32, -0.9), (0.0, 0.03, -1.7), 0.07, seed=3)
    INFO["cannon"] = {"size": [1.3, 1.0, 2.6], "barrel_seat": [0.0, 0.72, 0.15], "acts": [25], "needs": ["gunpowder"]}
    prof = [(0.0, -0.55), (0.12, -0.55), (0.2, -0.48), (0.22, -0.3), (0.2, 0.2), (0.17, 0.9), (0.16, 1.2), (0.2, 1.24), (0.2, 1.32), (0.1, 1.32), (0.1, 1.0)]
    barrel = K.lathe(prof, segs=18, at=(0.0, 0.0, 0.0), cap_bottom=False)
    rot = Matrix.Rotation(math.radians(-90.0), 4, 'X')
    bmesh.ops.transform(barrel, matrix=rot, verts=barrel.verts)
    bld.add("cannon_barrel", barrel, "BRONZE")
    bore = K.disc_fn(0.1, 12, lambda x, z: K.B((x, z, 1.0)))
    bld.add("cannon_barrel", bore, "SOCKET")
    knob = K.lathe([(0.0, -0.75), (0.07, -0.72), (0.06, -0.6), (0.12, -0.55)], segs=12, at=(0.0, 0.0, 0.0), cap_bottom=False)
    bmesh.ops.transform(knob, matrix=rot, verts=knob.verts)
    bld.add("cannon_barrel", knob, "BRONZE")
    tr, tcaps = K.tube([(-0.3, 0.0, 0.0), (0.3, 0.0, 0.0)], [0.06, 0.06], segs=8, caps=True)
    bld.add("cannon_barrel", tr, "BRONZE")
    bld.add("cannon_barrel", tcaps, "BRONZE")
    INFO["cannon_barrel"] = {"size": [0.6, 0.44, 2.1], "muzzle": [0.0, 0.0, 1.32], "acts": [25], "needs": ["gunpowder"]}


def falling_blade(bld):
    # act 23: two tall grooved uprights and a crossbar, the neck stock low
    # between them, a plank to lie on, a wicker basket before it; the blade
    # (blade_knife, origin at its lowest point) slides down the grooves
    for x in (-0.32, 0.32):
        box(bld, "blade_frame", (x, 1.75, 0.0), (0.06, 1.75, 0.06), "WOOD")
        box(bld, "blade_frame", (x, 0.04, 0.0), (0.12, 0.04, 0.4), "WOOD")
    box(bld, "blade_frame", (0.0, 3.52, 0.0), (0.45, 0.07, 0.08), "WOOD")
    box(bld, "blade_frame", (0.0, 0.62, 0.0), (0.3, 0.12, 0.05), "WOOD")
    neck = K.disc_fn(0.085, 14, lambda x, z: K.B((x, 0.62 + z, 0.052)))
    bld.add("blade_frame", neck, "SOCKET")
    box(bld, "blade_frame", (0.0, 0.48, -0.85), (0.22, 0.04, 0.8), "PLANK")
    for z in (-1.5, -0.35):
        box(bld, "blade_frame", (0.0, 0.23, z), (0.2, 0.23, 0.04), "WOOD")
    K.basket(bld, "blade_frame", (0.0, 0.0, 0.42), 0.3, 0.38, seed=3.0, slot="WICKER")
    INFO["blade_frame"] = {"size": [1.0, 3.6, 2.4], "blade_top": [0.0, 3.25, 0.0], "blade_bottom": [0.0, 0.74, 0.0], "neck": [0.0, 0.62, 0.0],
                           "basket": [0.0, 0.05, 0.42], "acts": [23], "needs": ["metal", "writing"]}
    verts = [K.B(p) for p in [(-0.27, 0.0, -0.025), (0.27, 0.22, -0.025), (0.27, 0.52, -0.025), (-0.27, 0.52, -0.025),
                              (-0.27, 0.0, 0.025), (0.27, 0.22, 0.025), (0.27, 0.52, 0.025), (-0.27, 0.52, 0.025)]]
    faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (2, 3, 7, 6), (1, 2, 6, 5), (0, 4, 7, 3)]
    bld.add("blade_knife", K._bm_from(verts, faces), "IRON")
    box(bld, "blade_knife", (0.0, 0.6, 0.0), (0.27, 0.08, 0.05), "WOOD")
    INFO["blade_knife"] = {"size": [0.54, 0.68, 0.1], "acts": [23], "needs": ["metal", "writing"]}


def crucible(bld):
    # act 20: a crucible of glowing bronze sunk in a stone furnace, bellows at
    # its side; a hoist tripod with rope and hook stands over it (hoist)
    for k in range(10):
        a = k / 10 * math.tau
        K.rock(bld, "crucible", (math.cos(a) * 0.62, 0.22, math.sin(a) * 0.62), (0.2, 0.42, 0.18), seed=k * 1.1 + 3, slot="SOOT", flat=1.0, subdiv=1)
    prof = [(0.3, 0.0), (0.5, 0.15), (0.56, 0.5), (0.58, 0.7)]
    bld.add("crucible", K.lathe(prof, segs=20, at=(0.0, 0.0, 0.0), wobble=0.03, seed=4.0, wall=0.05), "CLAY")
    melt = K.disc_fn(0.52, 20, lambda x, z: K.B((x, 0.62 + 0.008 * _noise(Vector((x * 7, z * 7, 2.0))), z)))
    bld.add("crucible", melt, "MELT")
    bel, bcaps = K.tube([(0.85, 0.25, 0.3), (1.25, 0.32, 0.5)], [0.14, 0.1], segs=10, caps=True, flat=0.5)
    bld.add("crucible", bel, "HIDE_DARK")
    bld.add("crucible", bcaps, "HIDE_DARK")
    noz, ncaps = K.tube([(0.85, 0.25, 0.3), (0.55, 0.2, 0.15)], [0.04, 0.03], segs=6, caps=True)
    bld.add("crucible", noz, "CLAY")
    bld.add("crucible", ncaps, "SOCKET")
    INFO["crucible"] = {"size": [1.6, 0.8, 1.6], "melt": [0.0, 0.62, 0.0], "dip_seat": [0.0, 0.2, 0.0], "acts": [20], "needs": ["metal"]}
    apex = Vector((0.0, 3.2, 0.0))
    for k in range(3):
        a = k / 3 * math.tau + 0.3
        foot = Vector((math.cos(a) * 1.3, 0.0, math.sin(a) * 1.3))
        beam(bld, "hoist", tuple(foot), tuple(apex + (apex - foot).normalized() * 0.15), 0.06, seed=k + 3)
    lash, lcaps = K.tube([(0.0, 3.1, 0.0), (0.0, 3.25, 0.0)], [0.09, 0.09], segs=9, caps=True)
    bld.add("hoist", lash, "ROPE")
    bld.add("hoist", lcaps, "ROPE")
    pul, pcaps = K.tube([(-0.05, 3.0, 0.0), (0.05, 3.0, 0.0)], [0.08, 0.08], segs=10, caps=True)
    bld.add("hoist", pul, "WOOD")
    bld.add("hoist", pcaps, "WOOD_END")
    K.cord(bld, "hoist", (0.0, 2.92, 0.0), (0.0, 1.6, 0.0), r=0.014, sag=0.0, slot="ROPE")
    hook = []
    for k in range(9):
        t = k / 8 * math.pi * 1.4
        hook.append((0.0, 1.55 - 0.08 * math.sin(t), 0.08 * math.cos(t) - 0.08))
    hb, hcaps = K.tube(hook, [0.016] * 9, segs=6, caps=True)
    bld.add("hoist", hb, "IRON")
    bld.add("hoist", hcaps, "IRON")
    INFO["hoist"] = {"size": [2.6, 3.3, 2.6], "hook": [0.0, 1.5, 0.0], "acts": [20]}


def monolith(bld):
    # act 22: the great stone, roped, and the timber rig it hangs from: two
    # A-frames and a beam, a block at each rope; the team hauls on the ends
    K.standing_stone(bld, "monolith", (0.0, 0.0, 0.0), 2.6, 1.1, 0.75, seed=5.0, slot="STONE_BLOCK")
    for y in (0.6, 1.9):
        band = []
        for k in range(17):
            t = k / 16 * math.tau
            band.append((0.6 * math.cos(t), y, 0.42 * math.sin(t)))
        bb, bcaps = K.tube(band, [0.03] * 17, segs=5, caps=False)
        bld.add("monolith", bb, "ROPE")
    K.cord(bld, "monolith", (-0.4, 1.9, 0.0), (0.0, 2.75, 0.0), r=0.025, sag=0.0, slot="ROPE")
    K.cord(bld, "monolith", (0.4, 1.9, 0.0), (0.0, 2.75, 0.0), r=0.025, sag=0.0, slot="ROPE")
    INFO["monolith"] = {"size": [1.2, 2.8, 0.85], "lift": [0.0, 2.75, 0.0], "acts": [22]}
    for x in (-1.6, 1.6):
        beam(bld, "monolith_rig", (x, 0.0, -0.9), (x, 4.6, 0.0), 0.1, seed=x + 1)
        beam(bld, "monolith_rig", (x, 0.0, 0.9), (x, 4.6, 0.0), 0.1, seed=x + 2)
        beam(bld, "monolith_rig", (x, 1.4, -0.65), (x, 1.4, 0.65), 0.06, seed=x + 3)
    beam(bld, "monolith_rig", (-1.9, 4.55, 0.0), (1.9, 4.55, 0.0), 0.14, seed=6)
    blk, bcaps = K.tube([(-0.1, 4.3, 0.0), (0.1, 4.3, 0.0)], [0.12, 0.12], segs=10, caps=True)
    bld.add("monolith_rig", blk, "WOOD")
    bld.add("monolith_rig", bcaps, "WOOD_END")
    K.cord(bld, "monolith_rig", (0.0, 4.5, 0.0), (0.0, 4.3, 0.0), r=0.025, sag=0.0, slot="ROPE")
    for s in (-1, 1):
        K.cord(bld, "monolith_rig", (0.0, 4.3, 0.0), (s * 3.4, 0.9, 0.6 * s), r=0.025, sag=0.25, slot="ROPE")
    INFO["monolith_rig"] = {"size": [3.8, 4.7, 1.9], "hang": [0.0, 4.2, 0.0], "haul": [[-3.4, 0.9, -0.6], [3.4, 0.9, 0.6]], "acts": [22]}


def pit_gate(bld):
    # act 17: the beast pit's gate: stone jambs and a lintel, the door leaf
    # its own prop (pit_gate_door, origin at its hinge), iron-strapped
    for x in (-0.95, 0.95):
        box(bld, "pit_gate", (x, 1.15, 0.0), (0.22, 1.15, 0.3), "STONE_BLOCK")
    box(bld, "pit_gate", (0.0, 2.45, 0.0), (1.25, 0.18, 0.34), "STONE_BLOCK")
    box(bld, "pit_gate", (0.0, 1.1, -0.29), (0.74, 1.1, 0.01), "SOCKET")
    INFO["pit_gate"] = {"size": [2.5, 2.65, 0.7], "hinge": [-0.72, 0.0, 0.05], "acts": [17], "needs": ["masonry"]}
    for k in range(6):
        box(bld, "pit_gate_door", (0.12 + k * 0.24, 1.1, 0.0), (0.115, 1.08, 0.05), "PLANK")
    for y in (0.4, 1.8):
        box(bld, "pit_gate_door", (0.72, y, 0.06), (0.72, 0.05, 0.012), "IRON")
    ring = []
    for k in range(13):
        t = k / 12 * math.tau
        ring.append((1.2 + 0.08 * math.cos(t), 1.1 + 0.08 * math.sin(t), 0.09))
    rb, rcaps = K.tube(ring, [0.012] * 13, segs=5, caps=False)
    bld.add("pit_gate_door", rb, "IRON")
    INFO["pit_gate_door"] = {"size": [1.44, 2.2, 0.12], "acts": [17]}


def plinth(bld):
    # a plinth for the bronze statue by the door (act 20's trophy, it stays)
    box(bld, "plinth", (0.0, 0.05, 0.0), (0.5, 0.05, 0.5), "STONE_BLOCK")
    box(bld, "plinth", (0.0, 0.33, 0.0), (0.42, 0.25, 0.42), "STONE_BLOCK")
    box(bld, "plinth", (0.0, 0.62, 0.0), (0.47, 0.04, 0.47), "STONE_BLOCK")
    INFO["plinth"] = {"size": [1.0, 0.66, 1.0], "stand_seat": [0.0, 0.66, 0.0], "acts": [20]}


def main():
    os.makedirs(OUT, exist_ok=True)
    K.clear_scene()
    bld = K.Builder(seed=31)
    cook_pot(bld)
    cook_bag(bld)
    club(bld)
    block(bld)
    axe_bronze(bld)
    thighbone(bld)
    skull(bld)
    INFO["skull"] = {"size": [0.18, 0.21, 0.2], "acts": [4, 10, 14]}
    skull_stake(bld)
    boulder(bld)
    ash_pile(bld)
    spears(bld)
    stones(bld)
    boulder_ledge(bld)
    cauldron_clay(bld)
    cauldron_bronze(bld)
    bow_and_arrow(bld)
    impaling_stake(bld)
    gallows(bld)
    cart_wheel(bld)
    catapult(bld)
    cannon(bld)
    falling_blade(bld)
    crucible(bld)
    monolith(bld)
    pit_gate(bld)
    plinth(bld)
    objs = list(bld.finish().values())
    ao = K.bake_ao(objs, distance=0.25, samples=16)
    K.write_colors(objs, ao)
    path = os.path.join(OUT, "court_exec_props.glb")
    K.export_glb(objs, path)
    for o in objs:
        INFO.setdefault(o.name, {})["triangles"] = sum(len(p.vertices) - 2 for p in o.data.polygons)
    with open(os.path.join(OUT, "court_exec_props.json"), "w", encoding="utf-8") as fh:
        json.dump({"generator": "tools/blender/court_exec_props.py", "glb": "court_exec_props.glb", "props": INFO}, fh, indent=1)
    K.log("exec props ->", path, "tris", K.tri_count(objs), "objects", len(objs))


if __name__ == "__main__":
    main()

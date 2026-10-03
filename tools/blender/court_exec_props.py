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
  boulder                                a great stone for two to tip (act 1)
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


def cook_pot(bld):
    # a big round-bellied clay pot on three stones, a skin of broth inside
    r, h = 0.42, 0.62
    for k in range(3):
        a = k / 3 * math.tau + 0.4
        K.rock(bld, "cook_pot", (math.cos(a) * 0.36, 0.1, math.sin(a) * 0.36), (0.17, 0.13, 0.15), seed=k * 2.1, slot="SOOT")
    K.pot(bld, "cook_pot", (0.0, 0.16, 0.0), r, h, seed=3, slot="CLAY", neck=0.78)
    # soot up the belly from the fire under it
    soot = K.lathe([(r * 0.47, 0.0), (r * 0.86, h * 0.12), (r * 1.003, h * 0.38)], segs=18, at=(0.0, 0.16, 0.0), cap_bottom=False)
    K.thicken(soot, 0.004)
    bld.add("cook_pot", soot, "SOOT")
    surface = K.disc_fn(r * 0.74, 18, lambda x, z: K.B((x, 0.16 + h * 0.8 + 0.008 * _noise(Vector((x * 9, z * 9, 1.0))), z)))
    bld.add("cook_pot", surface, "BROTH")
    for k in range(5):
        a = k * 1.3
        K.lumps(bld, "cook_pot", (math.cos(a) * 0.12, 0.16 + h * 0.8, math.sin(a) * 0.12), 0.05, 0.01, 1, 0.045, seed=k, slot="FOOD_ROOT")
    INFO["cook_pot"] = {"size": [0.95, 0.85, 0.95], "lid_seat": [0.0, 0.16 + h, 0.0], "head_seat": [0.0, 0.16 + h * 0.8, 0.0],
                        "needs": ["pottery"], "acts": [2, 14]}
    # the lid: a wooden disc with a knob, set on the pot's mouth
    lid = K.lathe([(0.0, 0.0), (r * 0.86, 0.0), (r * 0.88, 0.03), (r * 0.6, 0.05), (0.06, 0.06), (0.07, 0.11), (0.0, 0.12)], segs=20, at=(0, 0, 0))
    bld.add("cook_pot_lid", lid, "PLANK")
    INFO["cook_pot_lid"] = {"size": [0.75, 0.12, 0.75], "needs": ["pottery"], "acts": [2]}
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
    INFO["cook_bag"] = {"size": [1.3, 1.6, 1.3], "lid_seat": [0.0, rim, 0.0], "head_seat": [0.0, rim - 0.1, 0.0], "acts": [2, 14]}
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
        bld.add("block", K._bm_from(verts, [(0, 1, 2, 3)]), "CHAR")
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
    c = Vector(at)
    sc = scale
    # cranium, a jaw, dark sockets and nose, teeth: a cartoon skull
    K.rock(bld, name, tuple(c + Vector((0.0, 0.1 * sc, -0.01 * sc))), (0.085 * sc, 0.085 * sc, 0.1 * sc), seed=seed + 1, slot="BONE", flat=1.0, subdiv=2)
    K.rock(bld, name, tuple(c + Vector((0.0, 0.03 * sc, 0.045 * sc))), (0.06 * sc, 0.035 * sc, 0.05 * sc), seed=seed + 2, slot="BONE", flat=1.0, subdiv=2)
    for s in (-1, 1):
        K.rock(bld, name, tuple(c + Vector((s * 0.034 * sc, 0.095 * sc, 0.075 * sc))), (0.024 * sc, 0.022 * sc, 0.012 * sc), seed=seed + 3 + s, slot="SOCKET", flat=1.0, subdiv=1)
    K.rock(bld, name, tuple(c + Vector((0.0, 0.062 * sc, 0.088 * sc))), (0.01 * sc, 0.014 * sc, 0.008 * sc), seed=seed + 6, slot="SOCKET", flat=1.0, subdiv=1)
    for k in range(5):
        K.rock(bld, name, tuple(c + Vector(((k - 2) * 0.013 * sc, 0.038 * sc, 0.09 * sc))), (0.0065 * sc, 0.011 * sc, 0.006 * sc), seed=seed + 10 + k, slot="BONE", flat=1.0, subdiv=1)


def skull_stake(bld):
    K.post(bld, "skull_stake", (0.0, 0.0, 0.0), 1.55, 0.03, seed=2, slot="WOOD", pointed=True)
    skull(bld, "skull_stake", at=(0.0, 1.42, 0.0), scale=1.0, seed=4.0)
    INFO["skull_stake"] = {"size": [0.2, 1.7, 0.2], "acts": []}


def boulder(bld):
    K.rock(bld, "boulder", (0.0, 0.42, 0.0), (0.5, 0.46, 0.46), seed=12.0, slot="STONE", flat=1.0, subdiv=3)
    INFO["boulder"] = {"size": [1.0, 0.9, 0.9], "acts": [1]}


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
    INFO["skull"] = {"size": [0.18, 0.2, 0.2], "acts": [4, 10]}
    skull_stake(bld)
    boulder(bld)
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

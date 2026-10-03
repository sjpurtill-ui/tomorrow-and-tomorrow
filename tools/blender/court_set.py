"""Build the court's sets and export them for Godot.

Run headless with Blender 5.2 (never opens a window):
  blender --background --factory-startup --python tools/blender/court_set.py -- [--sets fire_ring,longhouse] [--no-ao]

Each set becomes assets/court_sets/court_set_<kind>.glb, and
assets/court_sets/court_sets.json lists, per set, its marks (where people,
animals, the fire and the door are), the props the stage shows or hides
from the facts it is given, and where its lights and smoke come from.
The court grows with the people (scripts/hud/court_set_3d.gd maps the
court's civic stage and era to a set):
  fire_ring  a ring of logs about a fire under the open sky, hide windbreaks
             on stakes (the earliest bands);
  longhouse  a long timber hall, two rows of posts, a long hearth under the
             smoke hole, benches along the walls.
Everything is authored in the game's frame (x right, y up, z toward the god);
court_set_kit.B() turns it into Blender's.
"""
import os
import sys
import json
import math
import random
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True

import bpy
import bmesh
from mathutils import Vector
from mathutils.noise import noise as _noise, fractal as _fractal

import court_set_kit as K

OUT = os.path.join(ROOT, "assets", "court_sets")


def args():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    opts = {"sets": list(BUILDERS.keys()), "ao": True}
    i = 0
    while i < len(a):
        if a[i] == "--sets":
            opts["sets"] = a[i + 1].split(",")
            i += 1
        elif a[i] == "--no-ao":
            opts["ao"] = False
        i += 1
    return opts


def polar(phi_deg, r, y=0.0):
    """phi 0 is toward the god (+z), 90 the right (+x), 180 the back."""
    p = math.radians(phi_deg)
    return (math.sin(p) * r, y, math.cos(p) * r)


def mark(pos, face="throne", sit=False, **kw):
    out = {"pos": [round(v, 3) for v in pos], "face": face if isinstance(face, str) else [round(v, 3) for v in face], "sit": sit}
    out.update(kw)
    return out


# =====================================================================================
# The fire ring: the earliest bands meet about a fire under the sky.

def build_fire_ring(bld):
    rng = random.Random(11)
    R_SEAT = 2.55
    R_WALL = 5.4

    def height(x, z):
        r = math.hypot(x, z)
        base = 0.012 * _noise(Vector((x * 0.7, z * 0.7, 0.3)))
        if r > 6.5:
            t = min(1.0, (r - 6.5) / 30.0)
            base += (t ** 1.4) * 2.8 + 0.5 * t * _fractal(Vector((x * 0.05, z * 0.05, 1.0)), 0.6, 2.0, 3)
        return base

    def wear(x, z):
        r = math.hypot(x, z)
        w = max(0.0, min(1.0, (4.0 - r) / 1.6))
        # a trodden path from the door (left) to the fire, and toward the god
        dl = abs(z - 0.6 + 0.08 * x) if x < 0 else 99
        w = max(w, max(0.0, 1.0 - dl / 0.9) * max(0.0, min(1.0, (7.5 + x) / 3.0)))
        w = max(w, max(0.0, 1.0 - abs(x) / 1.2) * max(0.0, min(1.0, (6.0 - z) / 2.0)) * (1.0 if z > 0 else 0.0))
        w *= 0.75 + 0.25 * _noise(Vector((x * 1.3, z * 1.3, 4.0)))
        return max(0.0, min(1.0, w))

    K.ground(bld, "Ground", inner=8.0, outer=80.0, step_in=0.2, rings_out=9, height_fn=height, wear_fn=wear)

    # --- the hearth: a ring of stones, an ash bed, charred wood, embers
    for k in range(10):
        a = k / 10 * 360 + rng.uniform(-8, 8)
        p = polar(a, 0.66)
        K.rock(bld, "Hearth", p, (0.17 + rng.uniform(-0.03, 0.04), 0.11, 0.14), seed=k * 1.7, slot="SOOT")
    ash = K.disc_fn(0.58, 18, lambda x, z: K.B((x, 0.025 + 0.02 * (1 - (x * x + z * z) / 0.34), z)))
    bld.add("Hearth", ash, "ASH", wear=1.0)
    for k in range(5):
        a = k / 5 * 360 + 20
        foot = Vector(polar(a, 0.42, 0.03))
        top = Vector((0.0, 0.42, 0.0)) + (Vector(polar(a, 0.05)) )
        K.log_piece(bld, "Hearth", tuple(foot), tuple(top), 0.045, seed=k, slot="CHAR", end_slot="EMBER", segs=7, bend=0.02)
    for k in range(9):
        a = rng.uniform(0, 360)
        r = rng.uniform(0.05, 0.4)
        K.rock(bld, "Hearth", polar(a, r, 0.035), (0.05, 0.03, 0.04), seed=30 + k, slot="EMBER", subdiv=1)

    # --- log seats about the fire, the front left open toward the god
    seats = [(70, 2.0, 0.22), (118, 2.2, 0.25), (160, 1.9, 0.24), (200, 2.1, 0.25), (243, 1.9, 0.24), (290, 1.7, 0.21)]
    seat_marks = []
    for i, (phi, length, r) in enumerate(seats):
        c = Vector(polar(phi, R_SEAT, r * 0.82))
        tang = Vector((math.cos(math.radians(phi)), 0, -math.sin(math.radians(phi))))
        a = c - tang * length * 0.5
        b = c + tang * length * 0.5
        K.log_piece(bld, "Seats", tuple(a), tuple(b), r, seed=i * 3.1, wear=0.6)
        seat_marks.append((phi, c, r))

    # --- the windbreak: hides laced between stakes on the far side; the door gap at the left
    stake_phis = [104, 122, 140, 158, 176, 194, 212, 230, 247]
    tops = []
    for i, phi in enumerate(stake_phis):
        h = 1.55 + 0.25 * _noise(Vector((phi * 0.05, 1.0, 0.0))) + (0.25 if phi == 247 else 0.0)
        foot = polar(phi, R_WALL + 0.12 * _noise(Vector((phi * 0.1, 0, 0))))
        lean = (rng.uniform(-0.06, 0.06), rng.uniform(-0.06, 0.06))
        K.post(bld, "Windbreak", foot, h, 0.045, lean=lean, seed=i, slot="WOOD")
        tops.append((foot, h))
    for i in range(len(stake_phis) - 1):
        (f0, h0), (f1, h1) = tops[i], tops[i + 1]
        lo = 0.12 + rng.uniform(0.0, 0.08)
        hi = min(h0, h1) - 0.12 - rng.uniform(0.0, 0.15)
        slot = "HIDE" if i % 3 != 1 else "HIDE_DARK"
        K.hide_panel(bld, "Windbreak", f0, f1, lo, hi, seed=i * 1.3, slot=slot, sag=0.12)
        # lacing at the stakes
        for k in range(3):
            y = lo + (hi - lo) * (0.2 + 0.3 * k)
            a = Vector(f0)
            b = Vector(f1)
            d = (b - a).normalized()
            K.cord(bld, "Windbreak", tuple(a + Vector((0, y, 0))), tuple(a + d * 0.18 + Vector((0, y - 0.03, 0))), sag=0.0)
    # a short windbreak at the front left
    for i, phi in enumerate([282, 300]):
        foot = polar(phi, R_WALL - 0.2)
        K.post(bld, "Windbreak", foot, 1.35, 0.04, seed=40 + i)
    K.hide_panel(bld, "Windbreak", polar(282, R_WALL - 0.2), polar(300, R_WALL - 0.2), 0.15, 1.15, seed=9.1, sag=0.1)

    # the door: two taller stakes; one carries a horned skull
    door = Vector(polar(262, R_WALL + 0.1))
    K.post(bld, "Windbreak", tuple(Vector(polar(256, R_WALL + 0.1))), 2.2, 0.06, seed=50)
    skull_post = Vector(polar(268, R_WALL + 0.1))
    top = K.post(bld, "Windbreak", tuple(skull_post), 2.35, 0.06, seed=51, pointed=False)
    skull_c = skull_post + Vector((0, 2.28, 0.0))
    K.rock(bld, "Windbreak", tuple(skull_c), (0.11, 0.09, 0.15), seed=4.0, slot="BONE", subdiv=2)
    for s in (-1, 1):
        base = skull_c + Vector((0.0, 0.06, s * 0.07))
        path = [base, base + Vector((0.02, 0.12, s * 0.12)), base + Vector((0.06, 0.28, s * 0.18)), base + Vector((0.04, 0.42, s * 0.16))]
        bm, _ = K.tube([tuple(p) for p in path], [0.025, 0.02, 0.014, 0.006], segs=6, caps=True)
        bld.add("Windbreak", bm, "BONE")

    # the god's place is the open side of the ring, toward the viewer: nothing stands there
    god = Vector((0.0, 0.0, 5.2))

    # --- the store: a lean-to of hides at the back right, food baskets under it
    store = Vector(polar(138, 4.15))
    for s in (-1, 1):
        f = store + Vector((s * 0.9, 0, -0.5))
        K.post(bld, "Store", tuple(f), 1.45, 0.04, lean=(0.0, 0.35), seed=60 + s, pointed=False)
    K.log_piece(bld, "Store", tuple(store + Vector((-1.0, 1.4, -0.2))), tuple(store + Vector((1.0, 1.4, -0.2))), 0.035, seed=61, slot="WOOD", knots=False)
    K.hide_panel(bld, "Store", tuple(store + Vector((-0.95, 0, -0.65))), tuple(store + Vector((0.95, 0, -0.65))), 0.0, 1.4, seed=2.2, slot="HIDE_DARK", sag=0.15)
    food_names = []
    baskets = [(-0.55, 0.1, 0.24, 0.26), (0.05, 0.25, 0.27, 0.3), (0.6, 0.05, 0.22, 0.22), (0.25, 0.75, 0.2, 0.2), (-0.35, 0.8, 0.23, 0.24)]
    fills = ["FOOD_ROOT", "FOOD_GRAIN", "BERRY", "FOOD_ROOT", "FOOD_GRAIN"]
    for i, (dx, dz, r, h) in enumerate(baskets):
        at = store + Vector((dx, 0, dz))
        K.basket(bld, "Store", tuple(at), r, h, seed=i)
        name = "food_%d" % i
        K.heap(bld, name, tuple(at + Vector((0, h * 0.95, 0))), r * 0.95, h * 0.55, seed=i * 2.0, slot=fills[i])
        food_names.append(name)

    # --- the drying rack at the back left: two A-frames and a bar, strips hanging
    rack_c = Vector(polar(212, 4.0))
    axis = Vector((math.cos(math.radians(212)), 0, -math.sin(math.radians(212))))
    ends = [rack_c - axis * 1.1, rack_c + axis * 1.1]
    for e in ends:
        for s in (-1, 1):
            foot = e + Vector((axis.z, 0, -axis.x)) * 0.35 * s
            K.log_piece(bld, "Rack", tuple(foot), tuple(e + Vector((0, 1.6, 0))), 0.03, seed=s + e.x, slot="WOOD", end_slot="WOOD", knots=False, bend=0.01)
    K.log_piece(bld, "Rack", tuple(ends[0] + Vector((0, 1.55, 0)) - axis * 0.15), tuple(ends[1] + Vector((0, 1.55, 0)) + axis * 0.15), 0.03, seed=70, slot="WOOD", knots=False, bend=0.01)
    rack_names = []
    for i in range(9):
        t = (i + 0.5) / 9
        top = ends[0].lerp(ends[1], t) + Vector((0, 1.52, 0))
        name = "rack_%d" % i
        if i % 3 == 2:
            K.strip(bld, name, tuple(top), 0.42, 0.13, seed=i, slot="FISH")
        else:
            K.strip(bld, name, tuple(top), 0.55 + 0.1 * math.sin(i), 0.09, seed=i, slot="MEAT")
        rack_names.append(name)

    # --- spears: leaned on the stakes beside the door, more in war
    spear_names = []
    lean_at = [Vector(polar(240, R_WALL - 0.05)), Vector(polar(226, R_WALL - 0.05))]
    for i in range(10):
        base = lean_at[i % 2]
        inward = -base.normalized()
        butt = base + inward * (0.55 + 0.08 * (i // 2)) + Vector((rng.uniform(-0.25, 0.25), 0, rng.uniform(-0.25, 0.25)))
        tip = base + Vector((rng.uniform(-0.12, 0.12), 2.05 + rng.uniform(-0.15, 0.2), rng.uniform(-0.12, 0.12))) + inward * 0.05
        name = "spear_%d" % i
        K.spear(bld, name, tuple(butt), tuple(tip), seed=i)
        spear_names.append(name)

    # --- a hide pegged out to dry on a frame at the right
    frame_c = Vector(polar(112, 4.3))
    fr_axis = Vector((math.cos(math.radians(112)), 0, -math.sin(math.radians(112))))
    for s in (-1, 1):
        K.post(bld, "HideFrame", tuple(frame_c + fr_axis * 0.75 * s), 1.6, 0.035, seed=80 + s, pointed=False)
    for y in (0.25, 1.5):
        K.log_piece(bld, "HideFrame", tuple(frame_c - fr_axis * 0.85 + Vector((0, y, 0))), tuple(frame_c + fr_axis * 0.85 + Vector((0, y, 0))), 0.025, seed=81 + y, slot="WOOD", knots=False, bend=0.0)

    def stretched(u, v):
        p = frame_c + fr_axis * ((u - 0.5) * 1.3) + Vector((0, 0.35 + v * 1.0, 0))
        p += Vector((fr_axis.z, 0, -fr_axis.x)) * 0.02 * _noise(Vector((u * 3, v * 3, 2.0)))
        # a hide's outline: narrower at the legs and neck
        return K.B(p)

    hb = K.sheet(6, 5, stretched)
    K.thicken(hb, 0.01)
    bld.add("HideFrame", hb, "HIDE")
    for k in range(6):
        u = k / 5
        a = frame_c + fr_axis * ((u - 0.5) * 1.3)
        K.cord(bld, "HideFrame", tuple(a + Vector((0, 0.35, 0))), tuple(a + Vector((0, 0.25, 0))), sag=0.0)
        K.cord(bld, "HideFrame", tuple(a + Vector((0, 1.35, 0))), tuple(a + Vector((0, 1.5, 0))), sag=0.0)

    # --- the work hide: a hide on the ground with scrapers, hand-axes and a digging stick
    work = Vector(polar(300, 3.6))

    def rug(x, z):
        rr = math.hypot(x, z)
        return K.B(work + Vector((x * 1.25, 0.012 + 0.006 * _noise(Vector((x * 4, z * 4, 1.0))), z * 0.95)))

    bld.add("Tools", K.disc_fn(0.62, 14, rug), "HIDE", wear=0.2)
    for k in range(4):
        p = work + Vector((rng.uniform(-0.45, 0.45), 0.04, rng.uniform(-0.3, 0.3)))
        K.rock(bld, "Tools", tuple(p), (0.07, 0.035, 0.045), seed=90 + k, slot="FLINT", subdiv=1)
    K.log_piece(bld, "Tools", tuple(work + Vector((-0.7, 0.03, 0.35))), tuple(work + Vector((0.6, 0.03, 0.55))), 0.018, seed=95, slot="WOOD", knots=False, bend=0.03)
    # bark trays and a skin water-bag behind the fire (no pots yet)
    for k, (phi, r) in enumerate([(152, 1.95), (208, 1.85)]):
        c = Vector(polar(phi, r))
        K.basket(bld, "Tools", tuple(c), 0.2, 0.05, seed=k + 4, slot="BARK")
    bag = Vector(polar(128, 3.7))
    K.rock(bld, "Tools", tuple(bag + Vector((0, 0.16, 0))), (0.17, 0.2, 0.14), seed=3.0, slot="HIDE_DARK", flat=1.0)
    K.cord(bld, "Tools", tuple(bag + Vector((0, 0.34, 0))), tuple(bag + Vector((0.05, 0.42, 0))), r=0.02, sag=0.0)

    # --- firewood: a stacked pile against the windbreak at the back, a few sticks by the hearth
    wood = Vector(polar(188, 4.55))
    along = Vector((math.cos(math.radians(188)), 0, -math.sin(math.radians(188))))
    across = along.cross(Vector((0, 1, 0)))
    for layer in range(4):
        for k in range(5 - layer):
            off = (k - (4 - layer) * 0.5) * 0.1
            c = wood + along * off + Vector((0, 0.05 + layer * 0.085, 0))
            K.log_piece(bld, "Firewood", tuple(c - across * 0.42), tuple(c + across * 0.42), rng.uniform(0.035, 0.05), seed=100 + layer * 7 + k, knots=False, bend=0.02)
    for k in range(3):
        a = Vector(polar(232 + k * 9, 1.05, 0.03))
        d = Vector(polar(232 + k * 9 + 90, 0.32))
        K.log_piece(bld, "Firewood", tuple(a - d), tuple(a + d), 0.03, seed=120 + k, knots=False, bend=0.04)

    # --- what lies about a camp: pebbles, twigs, a gnawed bone
    drng = random.Random(31)
    for k in range(40):
        phi = drng.uniform(0, 360)
        r = drng.uniform(1.0, 4.6)
        if r < 3.0 and -60 < ((phi + 180) % 360) - 180 < 60:
            continue
        p = Vector(polar(phi, r, 0.01))
        if k % 3 == 0:
            d = Vector(polar(drng.uniform(0, 360), drng.uniform(0.12, 0.3)))
            K.log_piece(bld, "Debris", tuple(p - d), tuple(p + d), drng.uniform(0.008, 0.014), seed=300 + k, knots=False, bend=0.08, segs=5)
        else:
            K.rock(bld, "Debris", tuple(p), (drng.uniform(0.03, 0.07), 0.025, drng.uniform(0.03, 0.06)), seed=400 + k, subdiv=1)
    bone = Vector(polar(70, 1.6, 0.02))
    K.log_piece(bld, "Debris", tuple(bone - Vector((0.12, 0, 0.04))), tuple(bone + Vector((0.12, 0, 0.04))), 0.018, seed=9, slot="BONE", end_slot="BONE", knots=False, bend=0.0, segs=6)

    # --- a hide rug by the fire where the eldest sits
    eld = Vector(polar(150, 1.7))

    def rug2(x, z):
        return K.B(eld + Vector((x * 1.2, 0.012, z * 0.85)))

    bld.add("Tools", K.disc_fn(0.5, 12, rug2), "HIDE_DARK", wear=0.3)

    # --- the land beyond: tufts of grass, a few trees, hills
    def avoid(x, z):
        r = math.hypot(x, z)
        if 3.4 < r < 3.9:
            return False
        return r < 3.6 or abs(r - R_WALL) < 0.35 or (z > 3.5 and abs(x) < 1.6)

    K.grass_tufts(bld, "Grass", (0, 0, 0), 340, 3.2, 14.0, seed=5, avoid=avoid)
    trng = random.Random(77)
    for k in range(30):
        phi = 85 + k * (190 / 29) + trng.uniform(-3, 3)
        r = trng.uniform(60, 82)
        h = trng.uniform(5.0, 7.5)
        K.tree(bld, "Trees", polar(phi, r), h, h * 0.36, seed=k * 1.37)
    for k in range(14):
        phi = 80 + k * (200 / 13) + trng.uniform(-4, 4)
        r = R_WALL + trng.uniform(1.2, 3.5)
        K.rock(bld, "Shrubs", polar(phi, r, 0.25), (trng.uniform(0.5, 0.9), trng.uniform(0.45, 0.8), trng.uniform(0.5, 0.8)), seed=200 + k, slot="LEAF", flat=1.0)
    K.hill_band(bld, "Hills", 70.0, 1.5, (4.0, 13.0), 64, seed=1.0, slot="HILL_NEAR", depth=10.0)
    K.hill_band(bld, "HillsFar", 140.0, 2.0, (10.0, 30.0), 72, seed=4.0, slot="HILL_FAR", depth=20.0)

    marks = {
        "fire": mark((0, 0, 0), face="throne"),
        "throne_gaze": mark((0.0, 2.3, 5.4), face="fire"),
        "god_stone": mark(tuple(god), face="fire"),
        "petitioner": mark((0.2, 0, 2.15)),
        "officials_0": mark((-1.75, 0, 1.55)),
        "officials_1": mark((1.95, 0, 1.2)),
        "officials_2": mark((-2.85, 0, 0.15)),
        "officials_3": mark((3.05, 0, -0.25)),
        "officials_4": mark((-1.2, 0, -1.75)),
        "officials_5": mark((1.45, 0, -2.0)),
        "envoy_0": mark((-0.55, 0, 2.3)),
        "envoy_1": mark((-1.75, 0, 2.75)),
        "envoy_2": mark((0.75, 0, 2.85)),
        "door": mark(tuple(Vector(polar(262, R_WALL + 0.6))), face="fire"),
        "door_out": mark(tuple(Vector(polar(262, R_WALL + 3.5))), face="fire"),
    }
    # the crowd: some sit on the logs at the back, some stand behind them
    crowd = []
    for phi, c, r in seat_marks:
        if 110 <= phi <= 250:
            inward = Vector((-c.x, 0, -c.z)).normalized()
            crowd.append(mark((c.x, 0.0, c.z), face="fire", sit=True, seat=round(r * 1.82, 3)))
    for phi, r in [(205, 3.6), (150, 3.55), (232, 3.5), (122, 3.7), (178, 3.9)]:
        crowd.append(mark(polar(phi, r), face="fire"))
    for i, m in enumerate(crowd):
        marks["crowd_%d" % i] = m
    for i, (phi, r) in enumerate([(48, 1.15), (138, 3.35), (75, 3.75), (318, 2.4)]):
        marks["animal_%d" % i] = mark(polar(phi, r), face="fire")

    return {
        "marks": marks,
        "props": {"food": food_names, "rack": rack_names, "spears": spear_names, "spears_peace": 3},
        "fx": {
            "fire": {"pos": [0, 0.05, 0], "size": 1.0},
            "smoke_top": 9.0,
            "dust": {"pos": [0.0, 1.4, 1.0], "extent": [4.5, 1.4, 3.0]},
        },
        "light": {
            "open_sky": True,
            "sun_dir": [0.55, -0.58, -0.60],
            "sun_energy": 1.3,
            "sky_energy": 0.7,
            "fire_energy": 1.25,
            "fire_range": 6.0,
            "fog": 0.0035,
        },
        "camera": {"yaw": 22.0, "pitch": -12.0, "fov": 52.0, "centre": [0.1, 0.85, 0.25], "yaw_range": [-40.0, 50.0]},
        "ink": ["Hearth", "Seats", "Windbreak", "Store", "Rack", "HideFrame", "Tools", "Firewood", "GodStone", "Debris", "food_", "rack_", "spear_"],
        "door_side": -1,
    }


# =====================================================================================
# The longhouse: a long timber hall, the hearth down its middle, the smoke hole.

def build_longhouse(bld):
    rng = random.Random(23)
    HALF_L = 9.0      # x from -9 to 9
    HALF_W = 3.9      # z from -3.9 (back) to +3.9 (front, cut away)
    WALL_H = 1.85
    RIDGE_H = 5.4
    POST_Z = 2.25
    BAYS = [-7.8, -5.2, -2.6, 0.0, 2.6, 5.2, 7.8]

    def roof_y(z):
        return RIDGE_H - (RIDGE_H - WALL_H) * min(1.0, abs(z) / HALF_W)

    def height(x, z):
        inside = abs(x) < HALF_L and abs(z) < HALF_W
        base = 0.006 * _noise(Vector((x, z, 0.0)))
        if not inside:
            r = max(abs(x) - HALF_L, abs(z) - HALF_W, 0.0)
            base += min(1.0, r / 20.0) ** 1.5 * 1.5
        return base

    def wear(x, z):
        w = max(0.0, 1.0 - abs(z - 0.4) / 2.6) * max(0.0, 1.0 - abs(x) / 8.0)
        w = max(w, max(0.0, 1.0 - abs(z - 0.5) / 0.8) * (1.0 if x < -3 else 0.0))
        w *= 0.8 + 0.2 * _noise(Vector((x * 1.7, z * 1.7, 2.0)))
        return max(0.0, min(1.0, w))

    K.ground(bld, "Ground", inner=10.0, outer=60.0, step_in=0.25, rings_out=6, height_fn=height, wear_fn=wear)

    # --- the long hearth: a stone kerb, ash and embers, a cooking pot on stones
    for k in range(18):
        t = k / 17
        x = -1.9 + 3.8 * t
        for s in (-1, 1):
            K.rock(bld, "Hearth", (x + rng.uniform(-0.05, 0.05), 0.05, s * 0.55 + rng.uniform(-0.03, 0.03)), (0.13, 0.1, 0.12), seed=k * 1.3 + s, slot="SOOT")
    for s in (-1, 1):
        for k in range(3):
            K.rock(bld, "Hearth", (s * 2.0, 0.05, -0.35 + k * 0.35), (0.12, 0.1, 0.12), seed=60 + k + s)

    def ash_fn(x, z):
        return K.B((x * 3.3, 0.03, z * 0.85))

    bld.add("Hearth", K.disc_fn(0.58, 20, ash_fn), "ASH", wear=1.0)
    for k in range(6):
        x = -0.9 + k * 0.36
        K.log_piece(bld, "Hearth", (x - 0.3, 0.06, rng.uniform(-0.2, 0.2)), (x + 0.3, 0.1, rng.uniform(-0.2, 0.2)), 0.05, seed=k, slot="CHAR", end_slot="EMBER", segs=7)
    for k in range(10):
        K.rock(bld, "Hearth", (rng.uniform(-1.4, 1.4), 0.04, rng.uniform(-0.3, 0.3)), (0.05, 0.03, 0.04), seed=40 + k, slot="EMBER", subdiv=1)
    pot_at = Vector((1.55, 0.16, 0.05))
    for k in range(3):
        K.rock(bld, "Hearth", tuple(pot_at + Vector((math.cos(k * 2.1) * 0.2, -0.1, math.sin(k * 2.1) * 0.2))), (0.08, 0.08, 0.08), seed=70 + k)
    bld.add("Hearth", K.lathe([(0.08, 0.0), (0.2, 0.08), (0.24, 0.2), (0.2, 0.32), (0.17, 0.36), (0.19, 0.39), (0.17, 0.39)], segs=14, at=tuple(pot_at)), "CLAY")

    # --- posts in two rows, plates along them, tie beams, rafters on the back slope
    # the back row of posts and its plate (the front row is cut away for the view)
    for x in BAYS:
        K.post(bld, "Frame", (x, 0, -POST_Z), roof_y(POST_Z) - 0.05, 0.13, seed=x, slot="WOOD", pointed=False, segs=9, wear=0.3)
        # a brace from each post up toward the ridge
        K.log_piece(bld, "Frame", (x, roof_y(POST_Z) - 0.1, -POST_Z), (x, roof_y(0.9) - 0.05, -0.9), 0.07, seed=x + 3, slot="WOOD", bend=0.01, knots=False)
    K.log_piece(bld, "Frame", (-HALF_L, roof_y(POST_Z) - 0.05, -POST_Z), (HALF_L, roof_y(POST_Z) - 0.05, -POST_Z), 0.12, seed=5, slot="WOOD", end_slot="WOOD_END", bend=0.004, knots=False)
    # ridge
    K.log_piece(bld, "Frame", (-HALF_L - 0.3, RIDGE_H, 0.0), (HALF_L + 0.3, RIDGE_H, 0.0), 0.12, seed=9, slot="WOOD", bend=0.002, knots=False)
    # rafters on the back slope (the front slope is cut away for the view)
    for k in range(15):
        x = -HALF_L + 0.6 + k * (2 * HALF_L - 1.2) / 14
        K.log_piece(bld, "Rafters", (x, RIDGE_H + 0.05, 0.1), (x, WALL_H - 0.15, -HALF_W - 0.25), 0.055, seed=k, slot="WOOD", end_slot="WOOD", bend=0.005, knots=False)
    # back roof: thatch underside, with a smoke hole gap at the ridge over the hearth
    def roof_sheet(x0, x1, z0, z1):
        def f(u, v):
            x = x0 + (x1 - x0) * u
            z = z0 + (z1 - z0) * v
            y = roof_y(z) + 0.12 + 0.03 * _noise(Vector((x * 1.5, z * 1.5, 1.0)))
            return K.B((x, y, z))
        return K.sheet(max(2, int((x1 - x0) / 0.7)), 6, f)

    hole_x = 1.1
    hole_z = 0.95
    for (x0, x1, z0, z1) in [(-HALF_L - 0.4, -hole_x, -0.05, -HALF_W - 0.4), (hole_x, HALF_L + 0.4, -0.05, -HALF_W - 0.4), (-hole_x, hole_x, -hole_z, -HALF_W - 0.4)]:
        bm = roof_sheet(x0, x1, z0, z1)
        K.thicken(bm, 0.18)
        bld.add("Roof", bm, "THATCH")
    # outer thatch skin (seen at the gable ends), smoke hole frame
    for s in (-1, 1):
        K.log_piece(bld, "Rafters", (s * hole_x, RIDGE_H + 0.05, 0.0), (s * hole_x, roof_y(hole_z) + 0.1, -hole_z), 0.05, seed=80 + s, slot="WOOD", knots=False, bend=0.0)
    K.log_piece(bld, "Rafters", (-hole_x - 0.1, roof_y(hole_z) + 0.1, -hole_z), (hole_x + 0.1, roof_y(hole_z) + 0.1, -hole_z), 0.05, seed=83, slot="WOOD", knots=False, bend=0.0)

    # --- the back wall: wattle and daub between the posts, low under the eaves
    def wall(x0, x1, z, y0, y1, slot="MUD", seed=0.0):
        def f(u, v):
            x = x0 + (x1 - x0) * u
            y = y0 + (y1 - y0) * v
            return K.B((x, y, z + 0.03 * _noise(Vector((x * 2.0, y * 2.0, seed)))))
        bm = K.sheet(max(2, int(abs(x1 - x0) / 0.5)), 4, f)
        K.thicken(bm, 0.14)
        return bm

    bld.add("Walls", wall(-HALF_L, HALF_L, -HALF_W, 0.0, WALL_H + 0.05, seed=1.0), "MUD", wear=lambda co: max(0.0, 1.0 - co.z / 0.6))
    # the gable ends: plank walls rising to the ridge, a door at the left end
    for s in (-1, 1):
        xg = s * HALF_L
        for k in range(18):
            z0 = -HALF_W + k * (2 * HALF_W) / 18
            z1 = z0 + (2 * HALF_W) / 18 - 0.015
            zm = (z0 + z1) * 0.5
            if s < 0 and -0.2 < zm < 1.25:
                continue  # the door
            top = roof_y(zm)
            if zm > 0.6 and s < 0:
                top = min(top, roof_y(zm))
            bm = K.sheet(1, 3, lambda u, v, z0=z0, z1=z1, top=top, xg=xg: K.B((xg + 0.02 * _noise(Vector((u, v * 3.0, z0))), top * v, z0 + (z1 - z0) * u)))
            K.thicken(bm, 0.06)
            bld.add("Gables", bm, "PLANK", var=rng.random())
    # door frame and lintel at the left end
    for zz in (-0.25, 1.3):
        K.post(bld, "Gables", (-HALF_L, 0, zz), 2.15, 0.09, seed=zz, slot="WOOD", pointed=False)
    K.log_piece(bld, "Gables", (-HALF_L, 2.12, -0.35), (-HALF_L, 2.12, 1.4), 0.08, seed=3, slot="WOOD", knots=False, bend=0.0)
    above = K.sheet(1, 3, lambda u, v: K.B((-HALF_L, 2.15 + (roof_y(0.5) - 2.15) * v, -0.25 + 1.55 * u)))
    K.thicken(above, 0.06)
    bld.add("Gables", above, "PLANK")
    # an open door leaf, swung in
    leaf = K.sheet(1, 3, lambda u, v: K.B((-HALF_L + 0.75 * u, 2.05 * v, -0.25 + 0.22 * u)))
    K.thicken(leaf, 0.05)
    bld.add("Gables", leaf, "PLANK")

    # --- benches along the back wall, hides and blankets on them
    for k in range(5):
        x0 = -HALF_L + 0.3 + k * 3.55
        x1 = x0 + 3.3
        top = 0.45
        bench = K.sheet(6, 2, lambda u, v, x0=x0, x1=x1: K.B((x0 + (x1 - x0) * u, top + 0.01 * _noise(Vector((u * 5, v, x0))), -HALF_W + 0.15 + 0.85 * v)))
        K.thicken(bench, 0.07)
        bld.add("Benches", bench, "PLANK", wear=0.5)
        front = K.sheet(6, 1, lambda u, v, x0=x0, x1=x1: K.B((x0 + (x1 - x0) * u, top * v, -HALF_W + 1.0)))
        K.thicken(front, 0.05)
        bld.add("Benches", front, "PLANK")
        for j in range(2):
            cx = x0 + 0.8 + j * 1.7 + rng.uniform(-0.2, 0.2)
            def blanket(u, v, cx=cx, j=j, k=k):
                x = cx + (u - 0.5) * 1.1
                z = -HALF_W + 0.2 + v * 0.95
                y = top + 0.04 + 0.03 * _noise(Vector((u * 3, v * 3, k + j)))
                if v > 0.92:
                    y -= (v - 0.92) * 3.5
                return K.B((x, y, z if v <= 0.92 else -HALF_W + 1.05 + (v - 0.92) * 0.3))
            bm = K.sheet(5, 5, blanket)
            K.thicken(bm, 0.02)
            bld.add("Benches", bm, "HIDE" if (j + k) % 2 else "BLANKET")

    # --- the high seat: between two carved posts on the back bench, the hides of honour
    hs = Vector((0.0, 0.0, -HALF_W + 0.6))
    for s in (-1, 1):
        K.post(bld, "HighSeat", tuple(hs + Vector((s * 0.65, 0, -0.15))), 2.1, 0.09, seed=110 + s, slot="WOOD", pointed=False, segs=10)
        for k in range(3):
            ring = K.lathe([(0.098, 0.0), (0.104, 0.04), (0.098, 0.08)], segs=12, at=tuple(hs + Vector((s * 0.65, 0.55 + k * 0.5, -0.15))), cap_bottom=False)
            bld.add("HighSeat", ring, "OCHRE")
    seat = K.sheet(3, 2, lambda u, v: K.B((hs.x - 0.55 + 1.1 * u, 0.62, hs.z - 0.35 + 0.6 * v)))
    K.thicken(seat, 0.12)
    bld.add("HighSeat", seat, "WOOD")
    back = K.sheet(3, 2, lambda u, v: K.B((hs.x - 0.55 + 1.1 * u, 0.62 + 0.75 * v, hs.z - 0.38 - 0.06 * v)))
    K.thicken(back, 0.08)
    bld.add("HighSeat", back, "WOOD")
    drape = K.sheet(4, 5, lambda u, v: K.B((hs.x - 0.5 + 1.0 * u, 1.3 - 1.25 * v + 0.03 * _noise(Vector((u * 3, v * 3, 7.0))), hs.z - 0.33 + 0.55 * max(0.0, v - 0.45) * 1.6)))
    K.thicken(drape, 0.02)
    bld.add("HighSeat", drape, "HIDE_DARK")

    # --- shields and spears racked on the back wall
    spear_names = []
    rack_x = [-6.2, 4.4]
    for i in range(10):
        bx = rack_x[i % 2] + (i // 2) * 0.28
        butt = (bx, 0.02, -HALF_W + 0.28)
        tip = (bx + 0.05, 2.45, -HALF_W + 0.12)
        name = "spear_%d" % i
        K.spear(bld, name, butt, tip, seed=i, head_slot="FLINT")
        spear_names.append(name)
    for x in rack_x:
        K.log_piece(bld, "Walls", (x - 0.2, 1.5, -HALF_W + 0.12), (x + 1.4, 1.5, -HALF_W + 0.12), 0.03, seed=x, slot="WOOD", knots=False, bend=0.0)
    for k, x in enumerate([-3.0, -1.6, 1.7, 3.1]):
        c = Vector((x, 1.45, -HALF_W + 0.1))
        sh = K.lathe([(0.0, 0.0), (0.3, 0.02), (0.34, 0.05), (0.33, 0.06)], segs=16, at=(0, 0, 0))
        K.thicken(sh, 0.03)
        # stand the lathe up against the wall, face toward the hall
        import mathutils
        rot = mathutils.Matrix.Rotation(math.radians(90), 4, 'X')
        bmesh.ops.transform(sh, matrix=mathutils.Matrix.Translation(K.B(tuple(c))) @ rot, verts=sh.verts)
        bld.add("Walls", sh, "HIDE" if k % 2 else "OCHRE")
        K.rock(bld, "Walls", tuple(c + Vector((0, 0, 0.07))), (0.07, 0.07, 0.04), seed=k, slot="WOOD", subdiv=1)

    # --- the stores at the left end: grain baskets, jars, a quern; smoked meat on the beam
    food_names = []
    store = Vector((-6.6, 0.0, -2.2))
    jars = [(-0.6, 0.0), (0.1, -0.35), (0.75, 0.1), (-0.2, 0.55), (0.55, 0.75), (-1.1, 0.6)]
    fills = ["FOOD_GRAIN", "FOOD_ROOT", "FOOD_GRAIN", "BERRY", "FOOD_GRAIN", "FOOD_ROOT"]
    for i, (dx, dz) in enumerate(jars):
        at = store + Vector((dx, 0, dz))
        if i % 2 == 0:
            r, h = 0.26, 0.42
            bld.add("Store", K.lathe([(0.12, 0.0), (0.24, 0.12), (0.27, 0.26), (0.2, 0.4), (0.17, h), (0.19, h + 0.02), (0.16, h + 0.01)], segs=14, at=tuple(at), wobble=0.02, seed=i), "CLAY")
            top = at + Vector((0, h - 0.02, 0))
            K.heap(bld, "food_%d" % i, tuple(top), 0.16, 0.08, seed=i, slot=fills[i])
        else:
            r, h = 0.3, 0.3
            K.basket(bld, "Store", tuple(at), r, h, seed=i)
            K.heap(bld, "food_%d" % i, tuple(at + Vector((0, h * 0.95, 0))), r * 0.95, h * 0.6, seed=i, slot=fills[i])
        food_names.append("food_%d" % i)
    K.rock(bld, "Store", tuple(store + Vector((1.6, 0.08, 0.9))), (0.35, 0.1, 0.25), seed=3.3)
    K.rock(bld, "Store", tuple(store + Vector((1.6, 0.2, 0.9))), (0.12, 0.05, 0.1), seed=3.9)
    rack_names = []
    beam_y = roof_y(POST_Z) - 0.17
    for i in range(10):
        x = -7.4 + i * 0.32
        name = "rack_%d" % i
        top = (x, beam_y, -POST_Z)
        if i % 4 == 3:
            K.strip(bld, name, top, 0.5, 0.14, seed=i, slot="FISH")
        else:
            K.strip(bld, name, top, 0.6 + 0.08 * math.sin(i * 1.7), 0.1, seed=i, slot="MEAT")
        rack_names.append(name)

    # --- a loom against the back wall at the right: warp threads and weights
    lx = 6.3
    for s in (-1, 1):
        K.log_piece(bld, "Loom", (lx + s * 0.75, 0.0, -HALF_W + 0.55), (lx + s * 0.75, 2.0, -HALF_W + 0.18), 0.04, seed=130 + s, slot="WOOD", knots=False, bend=0.0)
    K.log_piece(bld, "Loom", (lx - 0.85, 1.95, -HALF_W + 0.2), (lx + 0.85, 1.95, -HALF_W + 0.2), 0.035, seed=133, slot="WOOD", knots=False, bend=0.0)
    cloth = K.sheet(6, 4, lambda u, v: K.B((lx - 0.65 + 1.3 * u, 1.92 - 0.8 * v, -HALF_W + 0.22 + 0.13 * v)))
    K.thicken(cloth, 0.01)
    bld.add("Loom", cloth, "BLANKET")
    for k in range(9):
        x = lx - 0.6 + k * 0.15
        K.cord(bld, "Loom", (x, 1.12, -HALF_W + 0.35), (x, 0.42, -HALF_W + 0.46), r=0.005, sag=0.0)
        K.rock(bld, "Loom", (x, 0.38, -HALF_W + 0.47), (0.04, 0.05, 0.03), seed=140 + k, slot="CLAY", subdiv=1)

    # --- firewood by the hearth's right end, a few pots and a hide by the posts
    for k in range(8):
        a = Vector((3.2 + rng.uniform(-0.2, 0.2), 0.05 + 0.07 * (k % 3), -1.2 + rng.uniform(-0.15, 0.15)))
        d = Vector((0.55, 0.0, 0.15 * math.sin(k)))
        K.log_piece(bld, "Firewood", tuple(a - d), tuple(a + d), rng.uniform(0.03, 0.05), seed=150 + k, knots=False)
    for k, (x, z) in enumerate([(-2.6, -1.9), (2.4, -2.0), (-4.9, 1.9)]):
        bld.add("Pots", K.lathe([(0.1, 0.0), (0.19, 0.1), (0.21, 0.22), (0.15, 0.32), (0.13, 0.35), (0.15, 0.37), (0.13, 0.37)], segs=12, at=(x, 0, z), wobble=0.03, seed=k), "CLAY")

    # --- outside: grass beyond the door, trees, hills (seen through the door and the gable)
    def avoid(x, z):
        return abs(x) < HALF_L + 0.4 and abs(z) < HALF_W + 0.5

    K.grass_tufts(bld, "Grass", (0, 0, 0), 160, 9.5, 18.0, seed=7, avoid=avoid)
    for k, (x, z, h, c) in enumerate([(-15.0, -6.0, 6.0, 2.0), (-17.0, 5.0, 7.0, 2.3), (14.0, -9.0, 6.5, 2.1), (-13.5, 9.5, 5.5, 1.9)]):
        K.tree(bld, "Trees", (x, 0, z), h, c, seed=k * 2.1)
    K.hill_band(bld, "Hills", 60.0, 1.0, (4.0, 12.0), 56, seed=2.0, slot="HILL_NEAR", depth=10.0)

    # shadow casters for what the view cuts away: the front roof slope and front wall
    caster = K.sheet(16, 4, lambda u, v: K.B((-HALF_L - 0.4 + (2 * HALF_L + 0.8) * u, roof_y(v * HALF_W) + 0.15, v * (HALF_W + 0.4))))
    K.thicken(caster, 0.2)
    bld.add("ShadowCaster", caster, "THATCH")
    fwall = K.sheet(16, 2, lambda u, v: K.B((-HALF_L + 2 * HALF_L * u, WALL_H * v, HALF_W)))
    K.thicken(fwall, 0.1)
    bld.add("ShadowCaster", fwall, "MUD")

    marks = {
        "fire": mark((0, 0, 0)),
        "throne_gaze": mark((0.0, 2.5, 6.2), face="fire"),
        "high_seat": mark((0.0, 0.0, -HALF_W + 0.55), face="throne", sit=True, seat=0.68),
        "petitioner": mark((0.25, 0, 1.75)),
        "officials_0": mark((-1.65, 0, 1.35)),
        "officials_1": mark((2.05, 0, 1.05)),
        "officials_2": mark((-2.95, 0, 0.35)),
        "officials_3": mark((3.35, 0, 0.15)),
        "officials_4": mark((-1.35, 0, -1.3)),
        "officials_5": mark((1.6, 0, -1.4)),
        "envoy_0": mark((-0.55, 0, 2.0)),
        "envoy_1": mark((-1.8, 0, 2.55)),
        "envoy_2": mark((0.85, 0, 2.6)),
        "crowd_0": mark((-3.6, 0.0, -3.15), face="fire", sit=True, seat=0.45),
        "crowd_1": mark((-1.25, 0.0, -3.2), face="fire", sit=True, seat=0.45),
        "crowd_2": mark((2.2, 0.0, -3.15), face="fire", sit=True, seat=0.45),
        "crowd_3": mark((4.0, 0.0, -3.2), face="fire", sit=True, seat=0.45),
        "crowd_4": mark((-4.9, 0, -1.1), face="fire"),
        "crowd_5": mark((5.0, 0, -0.9), face="fire"),
        "crowd_6": mark((-4.3, 0, 1.9), face="fire"),
        "crowd_7": mark((4.6, 0, 1.95), face="fire"),
        "door": mark((-HALF_L + 0.6, 0, 0.5), face="fire"),
        "door_out": mark((-HALF_L - 2.5, 0, 0.5), face="fire"),
        "animal_0": mark((1.05, 0, 0.95), face="fire"),
        "animal_1": mark((-5.2, 0, -1.7), face="fire"),
        "animal_2": mark((3.7, 0, 1.6), face="fire"),
        "animal_3": mark((-6.8, 0, 1.0), face="fire"),
    }
    return {
        "marks": marks,
        "props": {"food": food_names, "rack": rack_names, "spears": spear_names, "spears_peace": 4},
        "fx": {
            "fire": {"pos": [0, 0.05, 0], "size": 1.0, "long": 3.4},
            "smoke_top": RIDGE_H + 0.4,
            "smoke_hole": [0.0, RIDGE_H - 0.3, -0.45],
            "dust": {"pos": [0.0, 1.8, 0.6], "extent": [4.0, 1.6, 2.4]},
            "door_light": [-HALF_L + 0.2, 1.2, 0.5],
        },
        "light": {
            "open_sky": False,
            "sun_dir": [0.04, -0.93, 0.36],
            "sun_energy": 2.2,
            "sky_energy": 0.32,
            "fire_energy": 1.35,
            "fire_range": 7.0,
            "fog": 0.012,
        },
        "camera": {"yaw": 18.0, "pitch": -11.0, "fov": 52.0, "centre": [0.1, 0.9, 0.2], "yaw_range": [-35.0, 40.0]},
        "ink": ["Hearth", "Frame", "Rafters", "Benches", "HighSeat", "Store", "Loom", "Firewood", "Pots", "food_", "rack_", "spear_", "Gables"],
        "shadow_only": ["ShadowCaster"],
        "door_side": -1,
    }


BUILDERS = {"fire_ring": build_fire_ring, "longhouse": build_longhouse}


def main():
    opts = args()
    os.makedirs(OUT, exist_ok=True)
    manifest_path = os.path.join(OUT, "court_sets.json")
    manifest = {"generator": "tools/blender/court_set.py", "sets": {}}
    if os.path.exists(manifest_path):
        try:
            with open(manifest_path, encoding="utf-8") as fh:
                manifest = json.load(fh)
        except Exception:
            pass
    for kind in opts["sets"]:
        t0 = time.time()
        K.clear_scene()
        bld = K.Builder(seed=sum(ord(c) for c in kind))
        info = BUILDERS[kind](bld)
        objs = list(bld.finish().values())
        meshes = [o for o in objs if o.type == 'MESH']
        ao = None
        if opts["ao"]:
            bake = [o for o in meshes if o.name not in ("HillsFar", "Hills", "ShadowCaster")]
            ao = K.bake_ao(bake, distance=0.9, samples=20)
        K.write_colors(meshes, ao)
        path = os.path.join(OUT, "court_set_%s.glb" % kind)
        K.export_glb(meshes, path)
        info["glb"] = "court_set_%s.glb" % kind
        info["triangles"] = K.tri_count(meshes)
        info["objects"] = sorted(o.name for o in meshes)
        manifest["sets"][kind] = info
        K.log(kind, "->", path, "tris", info["triangles"], "objects", len(meshes), "%.1fs" % (time.time() - t0))
    with open(manifest_path, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=1)


if __name__ == "__main__":
    main()

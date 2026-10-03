"""Build the court's sets and export them for Godot.

Run headless with Blender 5.2 (never opens a window):
  blender --background --factory-startup --python tools/blender/court_set.py -- [--sets fire_ring,longhouse] [--no-ao]

Each set becomes assets/court_sets/court_set_<kind>.glb, and
assets/court_sets/court_sets.json lists, per set, its marks (where people,
animals, the fire and the door are), the props the stage shows or hides from
the facts it is given (food, spears, and what the people know how to make),
and where its lights, shafts of sun and smoke come from.
The court grows with the people (scripts/hud/court_set_3d.gd maps the
court's civic stage and era to a set):
  fire_ring      logs about a fire under the open sky, hide windbreaks on
                 stakes (the earliest bands);
  shelter        a reed-roofed shelter on posts over the fire, reed screens,
                 carved seats for the eldest, standing stones beyond;
  longhouse      the chief's long timber hall: posts, benches, the high seat,
                 one long hearth under the smoke hole;
  mudbrick_hall  plastered mudbrick, a light well, a stepped dais with the
                 seat-place facing the god, an offering table;
  grand_hall     dressed stone, a row of columns, high windows, a carpet to
                 the dais under a canopy, banners and braziers.
Everything is authored in the game's frame (x right, y up, z toward the god);
court_set_kit.B() turns it into Blender's. court_set_halls.py holds the later
halls; this file the shared pieces and the first two.
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


def tangent(phi_deg):
    """The direction along a ring at phi (counter-clockwise seen from above)."""
    p = math.radians(phi_deg)
    return Vector((math.cos(p), 0.0, -math.sin(p)))


def mark(pos, face="throne", sit=False, **kw):
    out = {"pos": [round(v, 3) for v in pos], "face": face if isinstance(face, str) else [round(v, 3) for v in face], "sit": sit}
    out.update(kw)
    return out


# =====================================================================================
# Shared pieces

def distance(bld, arc=(55, 305), near_trees=True, seed=1.0):
    """The land beyond, as ink-wash layers: a dark tree line, then hills with
    copses, then far blue hills, each fainter in the air."""
    K.far_layer(bld, "Far0", 44.0, -0.5, arc, (0.2, 1.1, 2.2), (2.7, 2.4, 0.86), seed=seed, slot="FAR_0", step_deg=0.12)
    K.far_layer(bld, "Far1", 90.0, -1.0, arc, (1.2, 6.0, 1.0), (3.2, 3.6, 0.45), seed=seed + 3.0, slot="FAR_1", step_deg=0.2)
    K.far_layer(bld, "Far2", 180.0, -2.0, arc, (4.0, 14.0, 0.6), None, seed=seed + 7.0, slot="FAR_2", step_deg=0.4)


def meadow(bld, inner, avoid, seed=5, count=380, r_out=20.0):
    K.grass_tufts(bld, "Grass", (0, 0, 0), count, inner, r_out, seed=seed, avoid=avoid)


def near_trees(bld, spots, seed=1.0):
    for k, (phi, r, h, c) in enumerate(spots):
        K.tree(bld, "Trees", polar(phi, r), h, c, seed=seed + k * 1.37, clumps=18)


def store_baskets(bld, centre, spots, fills, prefix="food_"):
    """Food baskets at a store: the baskets always, the food in them as facts say."""
    names = []
    for i, (dx, dz, r, h) in enumerate(spots):
        at = centre + Vector((dx, 0, dz))
        K.basket(bld, "Store", tuple(at), r, h, seed=i)
        name = "%s%d" % (prefix, i)
        slot = fills[i % len(fills)]
        if slot in ("FOOD_ROOT", "ONION"):
            K.lumps(bld, name, tuple(at + Vector((0, h * 0.62, 0))), r * 0.8, h * 0.5, 9, r * 0.32, seed=i * 2.0, slot=slot)
        else:
            K.heap(bld, name, tuple(at + Vector((0, h * 0.92, 0))), r * 0.95, h * 0.55, seed=i * 2.0, slot=slot)
        names.append(name)
    return names


def drying_rack(bld, centre, phi, half=1.1, height=1.6, count=9, prefix="rack_"):
    axis = tangent(phi)
    ends = [centre - axis * half, centre + axis * half]
    across = Vector((axis.z, 0, -axis.x))
    for e in ends:
        for s in (-1, 1):
            foot = e + across * 0.35 * s
            K.log_piece(bld, "Rack", tuple(foot), tuple(e + Vector((0, height, 0))), 0.03, seed=s + e.x, slot="WOOD", end_slot="WOOD", knots=False, bend=0.01, stubs=0)
    K.log_piece(bld, "Rack", tuple(ends[0] + Vector((0, height - 0.05, 0)) - axis * 0.15), tuple(ends[1] + Vector((0, height - 0.05, 0)) + axis * 0.15), 0.03, seed=70, slot="WOOD", knots=False, bend=0.01, stubs=0)
    names = []
    for i in range(count):
        t = (i + 0.5) / count
        top = ends[0].lerp(ends[1], t) + Vector((0, height - 0.08, 0))
        name = "%s%d" % (prefix, i)
        if i % 3 == 2:
            K.strip(bld, name, tuple(top), 0.42, 0.13, seed=i, slot="FISH")
        else:
            K.strip(bld, name, tuple(top), 0.55 + 0.1 * math.sin(i), 0.09, seed=i, slot="MEAT")
        names.append(name)
    return names


def spear_stand(bld, bases, count=10, seed=0, head="FLINT", prefix="spear_", height=2.05):
    rng = random.Random(seed)
    names = []
    for i in range(count):
        base = bases[i % len(bases)]
        inward = Vector((-base.x, 0, -base.z)).normalized()
        butt = base + inward * (0.55 + 0.08 * (i // len(bases))) + Vector((rng.uniform(-0.25, 0.25), 0, rng.uniform(-0.25, 0.25)))
        tip = base + Vector((rng.uniform(-0.12, 0.12), height + rng.uniform(-0.15, 0.2), rng.uniform(-0.12, 0.12))) + inward * 0.05
        name = "%s%d" % (prefix, i)
        K.spear(bld, name, tuple(butt), tuple(tip), seed=i, head_slot=head)
        names.append(name)
    return names


def windbreak(bld, phis, radius, seed=3, name="Windbreak"):
    """Hides laced between stakes: every hide its own (pale, dark, mottled),
    some patched and stitched, some sagging or torn."""
    rng = random.Random(seed)
    tops = []
    for i, phi in enumerate(phis):
        h = 1.5 + 0.3 * _noise(Vector((phi * 0.05, 1.0, 0.0))) + rng.uniform(-0.1, 0.15)
        foot = polar(phi, radius + 0.12 * _noise(Vector((phi * 0.1, 0, 0))))
        lean = (rng.uniform(-0.07, 0.07), rng.uniform(-0.07, 0.07))
        K.post(bld, name, foot, h, 0.045, lean=lean, seed=i, slot="WOOD")
        tops.append((Vector(foot), h))
    kinds = ["HIDE", "HIDE_DARK", "HIDE_PALE", "HIDE", "HIDE_PALE", "HIDE_DARK"]
    for i in range(len(phis) - 1):
        (f0, h0), (f1, h1) = tops[i], tops[i + 1]
        lo = 0.1 + rng.uniform(0.0, 0.12)
        hi = min(h0, h1) - 0.12 - rng.uniform(0.0, 0.2)
        slot = kinds[(i * 5 + seed) % len(kinds)]
        sag = rng.uniform(0.06, 0.2)
        droop = rng.uniform(0.0, 0.18) if i % 3 == 0 else 0.0
        tear = 0.12 if i % 4 == 2 else 0.0
        if i % 3 == 1:
            # two hides sewn together: the seam runs up the middle
            mid = f0.lerp(f1, 0.5 + rng.uniform(-0.1, 0.1))
            K.hide_panel(bld, name, tuple(f0), tuple(mid), lo, hi, seed=i * 1.3, slot=slot, sag=sag * 0.6, droop=droop)
            other = "HIDE_PALE" if slot != "HIDE_PALE" else "HIDE_DARK"
            K.hide_panel(bld, name, tuple(mid), tuple(f1), lo + 0.06, hi - 0.05, seed=i * 1.7, slot=other, sag=sag * 0.6, tear=tear)
            for k in range(7):
                y = lo + 0.1 + (hi - lo - 0.2) * k / 6
                nrm = Vector((-(f1 - f0).z, 0, (f1 - f0).x)).normalized()
                c = mid + Vector((0, y, 0)) + nrm * 0.02
                d = (f1 - f0).normalized() * 0.04
                K.cord(bld, name, tuple(c - d), tuple(c + d), r=0.006, sag=0.0)
        else:
            K.hide_panel(bld, name, tuple(f0), tuple(f1), lo, hi, seed=i * 1.3, slot=slot, sag=sag, droop=droop, tear=tear)
            if i % 4 == 0:
                # a patch sewn over a hole
                nrm = Vector((-(f1 - f0).z, 0, (f1 - f0).x)).normalized()
                c = f0.lerp(f1, rng.uniform(0.35, 0.65)) + nrm * (sag * 0.85 + 0.03)
                pw = rng.uniform(0.22, 0.32)
                d = (f1 - f0).normalized()
                py = lo + (hi - lo) * rng.uniform(0.35, 0.6)
                K.hide_panel(bld, name, tuple(c - d * pw), tuple(c + d * pw), py - pw * 0.7, py + pw * 0.7, seed=i * 3.1, slot="HIDE_PALE" if slot != "HIDE_PALE" else "HIDE_DARK", sag=0.02)
        # lacing at the stakes
        for k in range(3):
            y = lo + (hi - lo) * (0.2 + 0.3 * k)
            d = (f1 - f0).normalized()
            K.cord(bld, name, tuple(f0 + Vector((0, y, 0))), tuple(f0 + d * 0.18 + Vector((0, y - 0.03, 0))), sag=0.0)
            K.cord(bld, name, tuple(f1 + Vector((0, y, 0))), tuple(f1 - d * 0.18 + Vector((0, y - 0.03, 0))), sag=0.0)
    return tops


def scatter_debris(bld, r0, r1, seed=31, avoid_front=True, count=40):
    drng = random.Random(seed)
    for k in range(count):
        phi = drng.uniform(0, 360)
        r = drng.uniform(r0, r1)
        if avoid_front and r < 3.0 and -60 < ((phi + 180) % 360) - 180 < 60:
            continue
        p = Vector(polar(phi, r, 0.01))
        if k % 3 == 0:
            d = Vector(polar(drng.uniform(0, 360), drng.uniform(0.12, 0.3)))
            K.log_piece(bld, "Debris", tuple(p - d), tuple(p + d), drng.uniform(0.008, 0.014), seed=300 + k, knots=False, bend=0.08, segs=5, stubs=0)
        else:
            K.rock(bld, "Debris", tuple(p), (drng.uniform(0.03, 0.07), 0.025, drng.uniform(0.03, 0.06)), seed=400 + k, subdiv=1)


def hearth_ring(bld, r=0.66, count=10, seed=0, name="Hearth"):
    rng = random.Random(seed)
    for k in range(count):
        a = k / count * 360 + rng.uniform(-8, 8)
        K.rock(bld, name, polar(a, r), (0.17 + rng.uniform(-0.03, 0.04), 0.11, 0.14), seed=k * 1.7 + seed, slot="SOOT")
    ash = K.disc_fn(r - 0.08, 18, lambda x, z: K.B((x, 0.025 + 0.02 * (1 - (x * x + z * z) / max((r - 0.08) ** 2, 0.01)), z)))
    bld.add(name, ash, "ASH", wear=1.0)
    for k in range(5):
        a = k / 5 * 360 + 20
        foot = Vector(polar(a, r * 0.64, 0.03))
        top = Vector((0.0, 0.42, 0.0)) + Vector(polar(a, 0.05))
        K.log_piece(bld, name, tuple(foot), tuple(top), 0.034, seed=k + seed, slot="CHAR", end_slot="EMBER", segs=7, bend=0.03, stubs=0, cut=(0.0, 0.0), flat=0.9)
    for k in range(9):
        K.rock(bld, name, polar(rng.uniform(0, 360), rng.uniform(0.05, r * 0.6), 0.035), (0.05, 0.03, 0.04), seed=30 + k + seed, slot="EMBER", subdiv=1)


def gated(info, tag, names, without=False):
    key = ("no_" if without else "") + tag
    info.setdefault("gates", {}).setdefault(key, []).extend(names)


BASE_MARKS = {
    "petitioner": (0.2, 0, 2.15),
    "officials_0": (-1.75, 0, 1.55),
    "officials_1": (1.95, 0, 1.2),
    "officials_2": (-2.85, 0, 0.15),
    "officials_3": (3.05, 0, -0.25),
    "officials_4": (-1.2, 0, -1.75),
    "officials_5": (1.45, 0, -2.0),
    "envoy_0": (-0.55, 0, 2.3),
    "envoy_1": (-1.75, 0, 2.75),
    "envoy_2": (0.75, 0, 2.85),
}


def base_marks(throne=(0.0, 2.3, 5.4)):
    m = {"fire": mark((0, 0, 0)), "throne_gaze": mark(throne, face="fire")}
    for k, p in BASE_MARKS.items():
        m[k] = mark(p)
    return m


# =====================================================================================
# The fire ring: the earliest bands meet about a fire under the sky.

def build_fire_ring(bld):
    rng = random.Random(11)
    R_SEAT = 2.55
    R_WALL = 5.4
    info = {}

    def height(x, z):
        r = math.hypot(x, z)
        base = 0.012 * _noise(Vector((x * 0.7, z * 0.7, 0.3)))
        if r > 6.5:
            t = min(1.0, (r - 6.5) / 36.0)
            base += (t ** 1.6) * 0.9 + 0.3 * t * _fractal(Vector((x * 0.05, z * 0.05, 1.0)), 0.6, 2.0, 3)
        return base

    def wear(x, z):
        r = math.hypot(x, z)
        w = max(0.0, min(1.0, (4.0 - r) / 1.6))
        dl = abs(z - 0.6 + 0.08 * x) if x < 0 else 99
        w = max(w, max(0.0, 1.0 - dl / 0.9) * max(0.0, min(1.0, (7.5 + x) / 3.0)))
        w = max(w, max(0.0, 1.0 - abs(x) / 1.2) * max(0.0, min(1.0, (6.0 - z) / 2.0)) * (1.0 if z > 0 else 0.0))
        w *= 0.75 + 0.25 * _noise(Vector((x * 1.3, z * 1.3, 4.0)))
        return max(0.0, min(1.0, w))

    K.ground(bld, "Ground", inner=8.0, outer=60.0, step_in=0.2, rings_out=9, height_fn=height, wear_fn=wear)
    hearth_ring(bld, seed=0)

    # --- log seats about the fire, the front left open toward the god
    seats = [(70, 2.0, 0.22), (118, 2.2, 0.25), (160, 1.9, 0.24), (200, 2.1, 0.25), (243, 1.9, 0.24), (290, 1.7, 0.21)]
    seat_marks = []
    for i, (phi, length, r) in enumerate(seats):
        c = Vector(polar(phi, R_SEAT, r * 0.82))
        tang = tangent(phi)
        a = c - tang * length * 0.5
        b = c + tang * length * 0.5
        K.log_piece(bld, "Seats", tuple(a), tuple(b), r, seed=i * 3.1, wear=0.6, flat=0.86, stubs=1 if i % 2 else 2)
        seat_marks.append((phi, c, r))

    windbreak(bld, [104, 122, 140, 158, 176, 194, 212, 230, 247], R_WALL, seed=3)
    for i, phi in enumerate([282, 300]):
        K.post(bld, "Windbreak", polar(phi, R_WALL - 0.2), 1.35, 0.04, seed=40 + i)
    K.hide_panel(bld, "Windbreak", polar(282, R_WALL - 0.2), polar(300, R_WALL - 0.2), 0.15, 1.15, seed=9.1, slot="HIDE_DARK", sag=0.1, droop=0.1)

    # the door: two taller stakes; one carries a horned skull
    K.post(bld, "Windbreak", tuple(Vector(polar(256, R_WALL + 0.1))), 2.2, 0.06, seed=50)
    skull_post = Vector(polar(268, R_WALL + 0.1))
    K.post(bld, "Windbreak", tuple(skull_post), 2.35, 0.06, seed=51, pointed=False)
    skull_c = skull_post + Vector((0, 2.28, 0.0))
    K.rock(bld, "Windbreak", tuple(skull_c), (0.11, 0.09, 0.15), seed=4.0, slot="BONE", subdiv=2)
    for s in (-1, 1):
        base = skull_c + Vector((0.0, 0.06, s * 0.07))
        path = [base, base + Vector((0.02, 0.12, s * 0.12)), base + Vector((0.06, 0.28, s * 0.18)), base + Vector((0.04, 0.42, s * 0.16))]
        bm, caps = K.tube([tuple(p) for p in path], [0.025, 0.02, 0.014, 0.006], segs=6, caps=True)
        bld.add("Windbreak", bm, "BONE")
        bld.add("Windbreak", caps, "BONE")

    # --- the store: a lean-to of hides at the back right, food baskets under it
    store = Vector(polar(138, 4.15))
    for s in (-1, 1):
        f = store + Vector((s * 0.9, 0, -0.5))
        K.post(bld, "Store", tuple(f), 1.45, 0.04, lean=(0.0, 0.35), seed=60 + s, pointed=False)
    K.log_piece(bld, "Store", tuple(store + Vector((-1.0, 1.4, -0.2))), tuple(store + Vector((1.0, 1.4, -0.2))), 0.035, seed=61, slot="WOOD", knots=False, stubs=0)
    K.hide_panel(bld, "Store", tuple(store + Vector((-0.95, 0, -0.65))), tuple(store + Vector((0.95, 0, -0.65))), 0.0, 1.4, seed=2.2, slot="HIDE_DARK", sag=0.15)
    food = store_baskets(bld, store, [(-0.55, 0.1, 0.24, 0.26), (0.05, 0.25, 0.27, 0.3), (0.6, 0.05, 0.22, 0.22), (0.25, 0.75, 0.2, 0.2), (-0.35, 0.8, 0.23, 0.24)],
                         ["FOOD_ROOT", "FOOD_GRAIN", "BERRY", "FOOD_ROOT", "FOOD_GRAIN"])
    # pots by the store once the people fire clay; skin bags and bark trays before
    pots = []
    for k, (dx, dz) in enumerate([(1.05, 0.55), (-1.05, 0.45)]):
        nm = "pots_%d" % k
        K.pot(bld, nm, tuple(store + Vector((dx, 0, dz))), 0.2, 0.36, seed=k)
        pots.append(nm)
    gated(info, "pottery", pots)

    rack = drying_rack(bld, Vector(polar(212, 4.0)), 212)
    spears = spear_stand(bld, [Vector(polar(240, R_WALL - 0.05)), Vector(polar(226, R_WALL - 0.05))], seed=4)

    # --- a hide pegged out to dry on a frame at the right
    frame_c = Vector(polar(112, 4.3))
    fr_axis = tangent(112)
    for s in (-1, 1):
        K.post(bld, "HideFrame", tuple(frame_c + fr_axis * 0.75 * s), 1.6, 0.035, seed=80 + s, pointed=False)
    for y in (0.25, 1.5):
        K.log_piece(bld, "HideFrame", tuple(frame_c - fr_axis * 0.85 + Vector((0, y, 0))), tuple(frame_c + fr_axis * 0.85 + Vector((0, y, 0))), 0.025, seed=81 + y, slot="WOOD", knots=False, bend=0.0, stubs=0)
    across = Vector((fr_axis.z, 0, -fr_axis.x))

    def stretched(u, v):
        w = 1.0 - 0.25 * abs(math.sin(v * math.pi * 2.0))
        p = frame_c + fr_axis * ((u - 0.5) * 1.3 * w) + Vector((0, 0.35 + v * 1.0, 0))
        p += across * 0.02 * _noise(Vector((u * 3, v * 3, 2.0)))
        return K.B(p)

    hb = K.sheet(6, 5, stretched)
    K.thicken(hb, 0.012)
    bld.add("HideFrame", hb, "HIDE_PALE")
    for k in range(6):
        u = k / 5
        a = frame_c + fr_axis * ((u - 0.5) * 1.3)
        K.cord(bld, "HideFrame", tuple(a + Vector((0, 0.35, 0))), tuple(a + Vector((0, 0.25, 0))), sag=0.0)
        K.cord(bld, "HideFrame", tuple(a + Vector((0, 1.35, 0))), tuple(a + Vector((0, 1.5, 0))), sag=0.0)

    # --- the work hide: scrapers, hand-axes and a digging stick
    work = Vector(polar(300, 3.6))
    bld.add("Tools", K.disc_fn(0.62, 14, lambda x, z: K.B(work + Vector((x * 1.25, 0.012 + 0.006 * _noise(Vector((x * 4, z * 4, 1.0))), z * 0.95)))), "HIDE", wear=0.2)
    for k in range(4):
        K.rock(bld, "Tools", tuple(work + Vector((rng.uniform(-0.45, 0.45), 0.04, rng.uniform(-0.3, 0.3)))), (0.07, 0.035, 0.045), seed=90 + k, slot="FLINT", subdiv=1)
    K.log_piece(bld, "Tools", tuple(work + Vector((-0.7, 0.03, 0.35))), tuple(work + Vector((0.6, 0.03, 0.55))), 0.018, seed=95, slot="WOOD", knots=False, bend=0.03, stubs=0)
    trays = []
    for k, (phi, r) in enumerate([(152, 1.95), (208, 1.85)]):
        nm = "trays_%d" % k
        K.tray(bld, nm, polar(phi, r), 0.2, 0.06, seed=k + 4)
        trays.append(nm)
    bag = Vector(polar(128, 3.7))
    K.rock(bld, "trays_bag", tuple(bag + Vector((0, 0.16, 0))), (0.17, 0.2, 0.14), seed=3.0, slot="HIDE_DARK", flat=1.0)
    K.cord(bld, "trays_bag", tuple(bag + Vector((0, 0.34, 0))), tuple(bag + Vector((0.05, 0.42, 0))), r=0.02, sag=0.0)
    gated(info, "pottery", trays + ["trays_bag"], without=True)

    # --- firewood: a stacked pile at the back, a few sticks by the hearth
    wood = Vector(polar(188, 4.55))
    along = tangent(188)
    acr = along.cross(Vector((0, 1, 0)))
    for layer in range(4):
        for k in range(5 - layer):
            off = (k - (4 - layer) * 0.5) * 0.1
            c = wood + along * off + Vector((0, 0.05 + layer * 0.085, 0))
            K.log_piece(bld, "Firewood", tuple(c - acr * 0.42), tuple(c + acr * 0.42), rng.uniform(0.035, 0.05), seed=100 + layer * 7 + k, knots=False, bend=0.02, stubs=0)
    for k in range(3):
        a = Vector(polar(232 + k * 9, 1.05, 0.03))
        d = Vector(polar(232 + k * 9 + 90, 0.32))
        K.log_piece(bld, "Firewood", tuple(a - d), tuple(a + d), 0.03, seed=120 + k, knots=False, bend=0.04, stubs=0)

    scatter_debris(bld, 1.0, 4.6)
    bone = Vector(polar(70, 1.6, 0.02))
    K.log_piece(bld, "Debris", tuple(bone - Vector((0.12, 0, 0.04))), tuple(bone + Vector((0.12, 0, 0.04))), 0.018, seed=9, slot="BONE", end_slot="BONE", knots=False, bend=0.0, segs=6, stubs=0)
    eld = Vector(polar(150, 1.7))
    bld.add("Tools", K.disc_fn(0.5, 12, lambda x, z: K.B(eld + Vector((x * 1.2, 0.012, z * 0.85)))), "HIDE_DARK", wear=0.3)

    # --- the land beyond
    def avoid(x, z):
        r = math.hypot(x, z)
        return r < 3.6 or abs(r - R_WALL) < 0.35 or (z > 3.5 and abs(x) < 1.6)

    meadow(bld, 3.2, avoid, count=520, r_out=24.0)
    distance(bld)

    marks = base_marks()
    marks["door"] = mark(tuple(Vector(polar(262, R_WALL + 0.6))), face="fire")
    marks["door_out"] = mark(tuple(Vector(polar(262, R_WALL + 3.5))), face="fire")
    crowd = []
    for phi, c, r in seat_marks:
        if 110 <= phi <= 250:
            crowd.append(mark((c.x, 0.0, c.z), face="fire", sit=True, seat=round(r * 1.82, 3)))
    for phi, r in [(205, 3.6), (150, 3.55), (232, 3.5), (122, 3.7), (178, 3.9)]:
        crowd.append(mark(polar(phi, r), face="fire"))
    for i, m in enumerate(crowd):
        marks["crowd_%d" % i] = m
    for i, (phi, r) in enumerate([(40, 1.6), (138, 3.35), (75, 3.75), (318, 2.4)]):
        marks["animal_%d" % i] = mark(polar(phi, r), face="fire")

    info.update({
        "marks": marks,
        "props": {"food": food, "rack": rack, "spears": spears, "spears_peace": 3},
        "default_tags": [],
        "fx": {
            "fire": {"pos": [0, 0.05, 0], "size": 1.0},
            "smoke_top": 9.0,
            "dust": {"pos": [0.0, 1.4, 1.0], "extent": [4.5, 1.4, 3.0]},
        },
        "light": {"open_sky": True, "sun_dir": [0.55, -0.58, -0.60], "sun_energy": 1.3, "fire_energy": 1.25, "fire_range": 6.0, "fog": 0.002},
        "camera": {"yaw": 22.0, "pitch": -12.0, "fov": 52.0, "centre": [0.1, 0.85, 0.25], "yaw_range": [-40.0, 50.0]},
        "ink": ["Hearth", "Seats", "Windbreak", "Store", "Rack", "HideFrame", "Tools", "Firewood", "Debris", "Trees", "Shrubs", "food_", "rack_", "spear_", "pots_", "trays_"],
        "door_side": -1,
    })
    return info


# =====================================================================================
# The longhouse: a long timber hall, the hearth down its middle, the smoke hole.

def build_longhouse(bld):
    rng = random.Random(23)
    HALF_L = 9.0
    HALF_W = 3.9
    WALL_H = 1.85
    RIDGE_H = 5.4
    POST_Z = 2.25
    BAYS = [-7.8, -5.2, -2.6, 0.0, 2.6, 5.2, 7.8]
    info = {}

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

    K.ground(bld, "Ground", inner=10.0, outer=50.0, step_in=0.25, rings_out=6, height_fn=height, wear_fn=wear)

    # --- the long hearth: a stone kerb, a long bed of ash and embers, one fire
    for k in range(18):
        x = -1.9 + 3.8 * k / 17
        for s in (-1, 1):
            K.rock(bld, "Hearth", (x + rng.uniform(-0.05, 0.05), 0.05, s * 0.55 + rng.uniform(-0.03, 0.03)), (0.13, 0.1, 0.12), seed=k * 1.3 + s, slot="SOOT")
    for s in (-1, 1):
        for k in range(3):
            K.rock(bld, "Hearth", (s * 2.0, 0.05, -0.35 + k * 0.35), (0.12, 0.1, 0.12), seed=60 + k + s, slot="SOOT")
    bld.add("Hearth", K.disc_fn(0.58, 20, lambda x, z: K.B((x * 3.3, 0.03, z * 0.85))), "ASH", wear=1.0)
    # the fire itself burns at the middle; logs laid in toward it, glowing ends
    for k in range(6):
        a = k / 6 * 360
        K.log_piece(bld, "Hearth", polar(a, 0.62, 0.05), (0.0, 0.3, 0.0), 0.04, seed=k, slot="CHAR", end_slot="EMBER", segs=7, stubs=0, cut=(0.0, 0.0))
    for k in range(14):
        K.rock(bld, "Hearth", (rng.uniform(-1.6, 1.6), 0.04, rng.uniform(-0.3, 0.3)), (0.05, 0.03, 0.04), seed=40 + k, slot="EMBER", subdiv=1)
    # a pot on stones at the hearth's end, a spit across the other
    pot_at = Vector((1.55, 0.16, 0.05))
    for k in range(3):
        K.rock(bld, "Hearth", tuple(pot_at + Vector((math.cos(k * 2.1) * 0.2, -0.1, math.sin(k * 2.1) * 0.2))), (0.08, 0.08, 0.08), seed=70 + k, slot="SOOT")
    K.pot(bld, "pots_hearth", tuple(pot_at), 0.24, 0.38, seed=1)
    for s in (-1, 1):
        K.log_piece(bld, "Hearth", (-1.5, 0.0, s * 0.4), (-1.5, 0.75, s * 0.1), 0.025, seed=80 + s, slot="WOOD", knots=False, stubs=0)
    K.log_piece(bld, "Hearth", (-1.5, 0.72, -0.4), (-1.5, 0.72, 0.4), 0.018, seed=83, slot="WOOD", knots=False, bend=0.0, stubs=0)
    K.rock(bld, "rack_spit", (-1.5, 0.66, 0.0), (0.16, 0.1, 0.1), seed=84, slot="MEAT", subdiv=2)
    gated(info, "pottery", ["pots_hearth"])

    # --- the back row of posts, plate and braces (the front is cut away for the view)
    for x in BAYS:
        K.post(bld, "Frame", (x, 0, -POST_Z), roof_y(POST_Z) - 0.05, 0.13, seed=x, slot="WOOD", pointed=False, segs=9, wear=0.3)
        K.log_piece(bld, "Frame", (x, roof_y(POST_Z) - 0.1, -POST_Z), (x, roof_y(0.9) - 0.05, -0.9), 0.07, seed=x + 3, slot="WOOD", bend=0.01, knots=False, stubs=0)
    K.log_piece(bld, "Frame", (-HALF_L, roof_y(POST_Z) - 0.05, -POST_Z), (HALF_L, roof_y(POST_Z) - 0.05, -POST_Z), 0.12, seed=5, slot="WOOD", end_slot="WOOD_END", bend=0.004, knots=False, stubs=0)
    K.log_piece(bld, "Frame", (-HALF_L - 0.3, RIDGE_H, 0.0), (HALF_L + 0.3, RIDGE_H, 0.0), 0.12, seed=9, slot="WOOD", bend=0.002, knots=False, stubs=0)
    for k in range(15):
        x = -HALF_L + 0.6 + k * (2 * HALF_L - 1.2) / 14
        K.log_piece(bld, "Rafters", (x, RIDGE_H + 0.05, 0.1), (x, WALL_H - 0.15, -HALF_W - 0.25), 0.055, seed=k, slot="WOOD", end_slot="WOOD", bend=0.005, knots=False, stubs=0)

    def roof_sheet(x0, x1, z0, z1):
        def f(u, v):
            x = x0 + (x1 - x0) * u
            z = z0 + (z1 - z0) * v
            return K.B((x, roof_y(z) + 0.12 + 0.03 * _noise(Vector((x * 1.5, z * 1.5, 1.0))), z))
        return K.sheet(max(2, int((x1 - x0) / 0.7)), 6, f)

    hole_x = 1.1
    hole_z = 0.95
    for (x0, x1, z0, z1) in [(-HALF_L - 0.4, -hole_x, -0.05, -HALF_W - 0.4), (hole_x, HALF_L + 0.4, -0.05, -HALF_W - 0.4), (-hole_x, hole_x, -hole_z, -HALF_W - 0.4)]:
        bm = roof_sheet(x0, x1, z0, z1)
        K.thicken(bm, 0.18)
        bld.add("Roof", bm, "THATCH")
    for s in (-1, 1):
        K.log_piece(bld, "Rafters", (s * hole_x, RIDGE_H + 0.05, 0.0), (s * hole_x, roof_y(hole_z) + 0.1, -hole_z), 0.05, seed=80 + s, slot="WOOD", knots=False, bend=0.0, stubs=0)
    K.log_piece(bld, "Rafters", (-hole_x - 0.1, roof_y(hole_z) + 0.1, -hole_z), (hole_x + 0.1, roof_y(hole_z) + 0.1, -hole_z), 0.05, seed=83, slot="WOOD", knots=False, bend=0.0, stubs=0)

    def wall(x0, x1, z, y0, y1, seed=0.0):
        def f(u, v):
            x = x0 + (x1 - x0) * u
            y = y0 + (y1 - y0) * v
            return K.B((x, y, z + 0.03 * _noise(Vector((x * 2.0, y * 2.0, seed)))))
        bm = K.sheet(max(2, int(abs(x1 - x0) / 0.5)), 4, f)
        K.thicken(bm, 0.14)
        return bm

    bld.add("Walls", wall(-HALF_L, HALF_L, -HALF_W, 0.0, WALL_H + 0.05, seed=1.0), "MUD", wear=lambda co: max(0.0, 1.0 - co.z / 0.6))
    for s in (-1, 1):
        xg = s * HALF_L
        for k in range(18):
            z0 = -HALF_W + k * (2 * HALF_W) / 18
            z1 = z0 + (2 * HALF_W) / 18 - 0.015
            zm = (z0 + z1) * 0.5
            if s < 0 and -0.2 < zm < 1.25:
                continue
            top = roof_y(zm)
            bm = K.sheet(1, 3, lambda u, v, z0=z0, z1=z1, top=top, xg=xg: K.B((xg + 0.02 * _noise(Vector((u, v * 3.0, z0))), top * v, z0 + (z1 - z0) * u)))
            K.thicken(bm, 0.06)
            bld.add("Gables", bm, "PLANK", var=rng.random())
    for zz in (-0.25, 1.3):
        K.post(bld, "Gables", (-HALF_L, 0, zz), 2.15, 0.09, seed=zz, slot="WOOD", pointed=False)
    K.log_piece(bld, "Gables", (-HALF_L, 2.12, -0.35), (-HALF_L, 2.12, 1.4), 0.08, seed=3, slot="WOOD", knots=False, bend=0.0, stubs=0)
    above = K.sheet(1, 3, lambda u, v: K.B((-HALF_L, 2.15 + (roof_y(0.5) - 2.15) * v, -0.25 + 1.55 * u)))
    K.thicken(above, 0.06)
    bld.add("Gables", above, "PLANK")
    leaf = K.sheet(1, 3, lambda u, v: K.B((-HALF_L + 0.75 * u, 2.05 * v, -0.25 + 0.22 * u)))
    K.thicken(leaf, 0.05)
    bld.add("Gables", leaf, "PLANK")

    # --- benches along the back wall, hides and woven blankets on them
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
                y = top + 0.04 + 0.03 * _noise(Vector((u * 3, v * 3, k + j)))
                z = -HALF_W + 0.2 + v * 0.95
                if v > 0.92:
                    y -= (v - 0.92) * 3.5
                    z = -HALF_W + 1.05 + (v - 0.92) * 0.3
                return K.B((x, y, z))

            bm = K.sheet(5, 5, blanket)
            K.thicken(bm, 0.02)
            weave = (j + k) % 3
            if weave == 0:
                bld.add("Benches", bm, "HIDE")
            else:
                nm = "weave_bench_%d_%d" % (k, j)
                bld.add(nm, bm, "WEAVE_A" if weave == 1 else "WEAVE_B")
                gated(info, "weaving", [nm])

    # --- the high seat between carved posts, the hides of honour
    hs = Vector((0.0, 0.0, -HALF_W + 0.6))
    for s in (-1, 1):
        K.post(bld, "HighSeat", tuple(hs + Vector((s * 0.65, 0, -0.15))), 2.1, 0.09, seed=110 + s, slot="WOOD", pointed=False, segs=10)
        for k in range(3):
            ring = K.lathe([(0.098, 0.0), (0.104, 0.04), (0.098, 0.08)], segs=12, at=tuple(hs + Vector((s * 0.65, 0.55 + k * 0.5, -0.15))), cap_bottom=False)
            K.thicken(ring, 0.01)
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

    # --- woven hangings on the back wall behind the high seat and between posts
    hangs = []
    for k, (x0, x1, slot) in enumerate([(-1.2, -0.75, "WEAVE_A"), (0.75, 1.2, "WEAVE_A"), (-4.8, -3.0, "WEAVE_B"), (3.0, 4.8, "WEAVE_C")]):
        nm = "weave_hang_%d" % k
        K.hanging(bld, nm, (x0, 1.82, -HALF_W + 0.1), (x1, 1.82, -HALF_W + 0.1), 1.05 if k < 2 else 0.9, seed=k * 2.3, slot=slot)
        hangs.append(nm)
    gated(info, "weaving", hangs)

    # --- painted shields and spears racked on the back wall
    spears = []
    rack_x = [-6.2, 6.0]
    for i in range(10):
        bx = rack_x[i % 2] + (i // 2) * 0.28
        name = "spear_%d" % i
        K.spear(bld, name, (bx, 0.02, -HALF_W + 0.28), (bx + 0.05, 2.45, -HALF_W + 0.12), seed=i, head_slot="FLINT")
        spears.append(name)
    for x in rack_x:
        K.log_piece(bld, "Walls", (x - 0.2, 1.5, -HALF_W + 0.12), (x + 1.4, 1.5, -HALF_W + 0.12), 0.03, seed=x, slot="WOOD", knots=False, bend=0.0, stubs=0)
    for k, x in enumerate([-2.5, -1.85, 1.85, 2.5]):
        K.shield(bld, "Shields", (x, 1.32 + 0.1 * (k % 2), -HALF_W + 0.12), (0, 0.15, 1), 0.3, slot=["SHIELD_A", "SHIELD_B", "SHIELD_C", "SHIELD_B"][k])

    # --- the stores at the left end: grain baskets and jars, a quern, meat hung on the plate
    store = Vector((-6.6, 0.0, -2.2))
    jars = [(-0.6, 0.0), (0.1, -0.35), (0.75, 0.1), (-0.2, 0.55), (0.55, 0.75), (-1.1, 0.6)]
    fills = ["FOOD_GRAIN", "FOOD_ROOT", "FOOD_GRAIN", "BERRY", "FOOD_GRAIN", "ONION"]
    food = []
    for i, (dx, dz) in enumerate(jars):
        at = store + Vector((dx, 0, dz))
        if i % 2 == 0:
            nm = "pots_store_%d" % i
            K.pot(bld, nm, tuple(at), 0.27, 0.44, seed=i, neck=0.7)
            gated(info, "pottery", [nm])
            K.heap(bld, "food_%d" % i, tuple(at + Vector((0, 0.42, 0))), 0.16, 0.07, seed=i, slot=fills[i])
        else:
            K.basket(bld, "Store", tuple(at), 0.3, 0.3, seed=i)
            if fills[i] in ("FOOD_ROOT", "ONION"):
                K.lumps(bld, "food_%d" % i, tuple(at + Vector((0, 0.2, 0))), 0.24, 0.15, 10, 0.09, seed=i, slot=fills[i])
            else:
                K.heap(bld, "food_%d" % i, tuple(at + Vector((0, 0.28, 0))), 0.28, 0.17, seed=i, slot=fills[i])
        food.append("food_%d" % i)
    K.rock(bld, "Store", tuple(store + Vector((1.6, 0.08, 0.9))), (0.35, 0.1, 0.25), seed=3.3)
    K.rock(bld, "Store", tuple(store + Vector((1.6, 0.2, 0.9))), (0.12, 0.05, 0.1), seed=3.9)
    rack = []
    beam_y = roof_y(POST_Z) - 0.17
    for i in range(10):
        x = -7.4 + i * 0.32
        name = "rack_%d" % i
        if i % 4 == 3:
            K.strip(bld, name, (x, beam_y, -POST_Z), 0.5, 0.14, seed=i, slot="FISH")
        else:
            K.strip(bld, name, (x, beam_y, -POST_Z), 0.6 + 0.08 * math.sin(i * 1.7), 0.1, seed=i, slot="MEAT")
        rack.append(name)
    rack.append("rack_spit")

    # --- the feast board: a plank on trestles at the right, food on it
    bx, bz = 3.6, -2.7
    board = K.sheet(6, 2, lambda u, v: K.B((bx - 1.1 + 2.2 * u, 0.74, bz - 0.32 + 0.64 * v)))
    K.thicken(board, 0.06)
    bld.add("Board", board, "PLANK", wear=0.6)
    for s in (-1, 1):
        for t in (-1, 1):
            K.log_piece(bld, "Board", (bx + s * 0.9, 0.0, bz + t * 0.25), (bx + s * 0.9, 0.72, bz - t * 0.05), 0.035, seed=s + t * 3, slot="WOOD", knots=False, stubs=0, cut=(0.0, 0.0))
    board_food = []
    nm = "board_0"
    K.lumps(bld, nm, (bx - 0.65, 0.78, bz), 0.18, 0.06, 6, 0.07, seed=1, slot="FOOD_ROOT")
    board_food.append(nm)
    nm = "board_1"
    K.rock(bld, nm, (bx - 0.05, 0.84, bz - 0.05), (0.26, 0.1, 0.14), seed=2, slot="MEAT", subdiv=2)
    K.log_piece(bld, nm, (bx - 0.05, 0.84, bz - 0.05), (bx + 0.28, 0.9, bz - 0.12), 0.018, seed=3, slot="BONE", end_slot="BONE", knots=False, stubs=0)
    board_food.append(nm)
    nm = "board_2"
    for k in range(2):
        K.strip(bld, nm, (bx + 0.45 + k * 0.18, 0.79, bz + 0.12), 0.3, 0.1, seed=k, slot="FISH")
    board_food.append(nm)
    nm = "board_3"
    K.tray(bld, nm, (bx + 0.6, 0.77, bz - 0.15), 0.14, 0.05, seed=4, slot="BARK")
    K.lumps(bld, nm, (bx + 0.6, 0.8, bz - 0.15), 0.1, 0.03, 8, 0.035, seed=4, slot="BERRY")
    board_food.append(nm)
    breads = []
    for k in range(3):
        nmb = "bread_%d" % k
        K.rock(bld, nmb, (bx - 0.35 + k * 0.12, 0.8, bz + 0.18), (0.09, 0.04, 0.09), seed=10 + k, slot="BREAD", subdiv=2)
        breads.append(nmb)
    gated(info, "baking", breads)

    # --- a loom against the back wall, warp threads and weights
    lx = 7.0
    loom = []
    for s in (-1, 1):
        K.log_piece(bld, "loom_frame", (lx + s * 0.75, 0.0, -HALF_W + 0.55), (lx + s * 0.75, 2.0, -HALF_W + 0.18), 0.04, seed=130 + s, slot="WOOD", knots=False, bend=0.0, stubs=0)
    K.log_piece(bld, "loom_frame", (lx - 0.85, 1.95, -HALF_W + 0.2), (lx + 0.85, 1.95, -HALF_W + 0.2), 0.035, seed=133, slot="WOOD", knots=False, bend=0.0, stubs=0)
    cloth = K.sheet(6, 4, lambda u, v: K.B((lx - 0.65 + 1.3 * u, 1.92 - 0.8 * v, -HALF_W + 0.22 + 0.13 * v)))
    K.thicken(cloth, 0.01)
    bld.add("loom_frame", cloth, "WEAVE_C")
    for k in range(9):
        x = lx - 0.6 + k * 0.15
        K.cord(bld, "loom_frame", (x, 1.12, -HALF_W + 0.35), (x, 0.42, -HALF_W + 0.46), r=0.005, sag=0.0)
        K.rock(bld, "loom_frame", (x, 0.38, -HALF_W + 0.47), (0.04, 0.05, 0.03), seed=140 + k, slot="CLAY", subdiv=1)
    gated(info, "weaving", ["loom_frame"])

    for k in range(8):
        a = Vector((3.2 + rng.uniform(-0.2, 0.2), 0.05 + 0.07 * (k % 3), -1.2 + rng.uniform(-0.15, 0.15)))
        d = Vector((0.55, 0.0, 0.15 * math.sin(k)))
        K.log_piece(bld, "Firewood", tuple(a - d), tuple(a + d), rng.uniform(0.03, 0.05), seed=150 + k, knots=False, stubs=0)
    pots = []
    for k, (x, z) in enumerate([(-2.6, -1.9), (2.4, -2.0), (-4.9, 1.9)]):
        nm = "pots_%d" % k
        K.pot(bld, nm, (x, 0, z), 0.2, 0.36, seed=k)
        pots.append(nm)
    gated(info, "pottery", pots)
    # reed mats on the floor before the high seat
    for k, (x, z, w) in enumerate([(-0.2, -2.4, 1.6), (-3.4, -2.3, 1.2)]):
        mat = K.sheet(6, 3, lambda u, v, x=x, z=z, w=w: K.B((x - w * 0.5 + w * u, 0.012, z - 0.45 + 0.9 * v)))
        K.thicken(mat, 0.01)
        bld.add("Mats", mat, "REED", wear=0.3)

    def avoid(x, z):
        return abs(x) < HALF_L + 0.4 and abs(z) < HALF_W + 0.5

    meadow(bld, 9.5, avoid, seed=7, count=160, r_out=18.0)
    for k, (x, z, h, c) in enumerate([(-15.0, -6.0, 6.0, 2.2), (-17.0, 5.0, 7.0, 2.5), (14.0, -9.0, 6.5, 2.3), (-13.5, 9.5, 5.5, 2.0)]):
        K.tree(bld, "Trees", (x, 0, z), h, c, seed=k * 2.1, clumps=16)
    distance(bld, arc=(200, 340), seed=4.0)

    caster = K.sheet(16, 4, lambda u, v: K.B((-HALF_L - 0.4 + (2 * HALF_L + 0.8) * u, roof_y(v * HALF_W) + 0.15, v * (HALF_W + 0.4))))
    K.thicken(caster, 0.2)
    bld.add("ShadowCaster", caster, "THATCH")
    fwall = K.sheet(16, 2, lambda u, v: K.B((-HALF_L + 2 * HALF_L * u, WALL_H * v, HALF_W)))
    K.thicken(fwall, 0.1)
    bld.add("ShadowCaster", fwall, "MUD")

    marks = base_marks((0.0, 2.5, 6.2))
    marks["petitioner"] = mark((0.25, 0, 1.75))
    marks["officials_0"] = mark((-1.65, 0, 1.35))
    marks["officials_1"] = mark((2.05, 0, 1.05))
    marks["officials_2"] = mark((-2.95, 0, 0.35))
    marks["officials_3"] = mark((3.35, 0, 0.15))
    marks["officials_4"] = mark((-1.35, 0, -1.3))
    marks["officials_5"] = mark((1.6, 0, -1.4))
    marks["envoy_0"] = mark((-0.55, 0, 2.0))
    marks["envoy_1"] = mark((-1.8, 0, 2.55))
    marks["envoy_2"] = mark((0.85, 0, 2.6))
    marks["high_seat"] = mark((0.0, 0.0, -HALF_W + 0.55), face="throne", sit=True, seat=0.68)
    for i, (x, z) in enumerate([(-3.6, -3.15), (-1.25, -3.2), (2.2, -3.15), (4.6, -3.2)]):
        marks["crowd_%d" % i] = mark((x, 0.0, z), face="fire", sit=True, seat=0.45)
    for i, (x, z) in enumerate([(-4.9, -1.1), (5.0, -0.9), (-4.3, 1.9), (4.6, 1.95)]):
        marks["crowd_%d" % (i + 4)] = mark((x, 0, z), face="fire")
    marks["door"] = mark((-HALF_L + 0.6, 0, 0.5), face="fire")
    marks["door_out"] = mark((-HALF_L - 2.5, 0, 0.5), face="fire")
    for i, (x, z) in enumerate([(1.35, 1.3), (-5.2, -1.7), (3.7, 1.6), (-6.8, 1.0)]):
        marks["animal_%d" % i] = mark((x, 0, z), face="fire")

    info.update({
        "marks": marks,
        "props": {"food": food + board_food, "rack": rack, "spears": spears, "spears_peace": 4},
        "default_tags": ["pottery", "weaving"],
        "fx": {
            "fire": {"pos": [0, 0.05, 0], "size": 1.25},
            "smoke_top": RIDGE_H + 0.4,
            "shafts": [{"top": [0.0, RIDGE_H - 0.3, -0.45], "radius": 0.62}],
            "dust": {"pos": [0.0, 1.8, 0.6], "extent": [4.0, 1.6, 2.4]},
            "door_light": [-HALF_L + 0.2, 1.2, 0.5],
        },
        "light": {"open_sky": False, "sun_dir": [0.04, -0.93, 0.36], "sun_energy": 2.2, "fire_energy": 1.5, "fire_range": 7.5, "fog": 0.012},
        "camera": {"yaw": 18.0, "pitch": -11.0, "fov": 52.0, "centre": [0.1, 0.9, 0.2], "yaw_range": [-35.0, 40.0]},
        "ink": ["Hearth", "Frame", "Rafters", "Benches", "HighSeat", "Store", "Firewood", "Board", "Shields", "Mats", "Trees", "food_", "rack_", "spear_", "Gables", "pots_", "weave_", "loom_", "board_", "bread_"],
        "shadow_only": ["ShadowCaster"],
        "door_side": -1,
    })
    return info


import court_set_halls as H  # noqa: E402  (the later halls use the pieces above)

BUILDERS = {"fire_ring": build_fire_ring, "shelter": H.build_shelter, "longhouse": build_longhouse,
            "mudbrick_hall": H.build_mudbrick_hall, "grand_hall": H.build_grand_hall}


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
            bake = [o for o in meshes if not o.name.startswith("Far") and o.name not in ("ShadowCaster",)]
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

"""The later court sets (see tools/blender/court_set.py, which runs them):
  shelter        a reed-roofed shelter on posts over the fire, reed screens,
                 carved seats for the eldest, standing stones beyond;
  mudbrick_hall  plastered mudbrick walls, a flat timber roof with a light
                 well, a stepped dais with the seat-place facing the god, an
                 offering table, a raised clay hearth, scribes' tablets;
  grand_hall     dressed stone, columns, high windows, a carpet to a dais
                 under a canopy, banners, braziers, a long side table.
Alternative history: forms that fit each age, no particular real place.
"""
import math
import random

import bmesh
from mathutils import Vector, Matrix
from mathutils.noise import noise as _noise, fractal as _fractal

import court_set_kit as K


def _S():
    import court_set as S  # shared pieces (imported late: court_set imports this file)
    return S


def box(bld, name, centre, size, slot, wear=0.0, var=None, bevel=0.0):
    """An axis-aligned box (game coords: centre, full size), UV planar in metres."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    c = K.B(centre)
    s = (size[0], size[2], size[1])
    bmesh.ops.transform(bm, matrix=Matrix.Translation(c) @ Matrix.Diagonal((s[0], s[1], s[2], 1.0)), verts=bm.verts)
    if bevel > 0.0:
        bmesh.ops.bevel(bm, geom=bm.edges[:] + bm.verts[:], offset=bevel, segments=1, affect='EDGES')
    bm.normal_update()
    bld.add(name, bm, slot, wear=wear, var=var)


def column(bld, name, foot, height, r, slot="STONE", capital_slot="STONE", segs=16, drums=4):
    """A round column with a square base and capital, built in drums."""
    f = Vector(foot)
    box(bld, name, tuple(f + Vector((0, 0.12, 0))), (r * 2.8, 0.24, r * 2.8), capital_slot, bevel=0.02)
    box(bld, name, tuple(f + Vector((0, 0.3, 0))), (r * 2.4, 0.12, r * 2.4), capital_slot, bevel=0.015)
    h0 = 0.36
    h1 = height - 0.42
    for k in range(drums):
        a = f + Vector((0, h0 + (h1 - h0) * k / drums + 0.004, 0))
        b = f + Vector((0, h0 + (h1 - h0) * (k + 1) / drums - 0.004, 0))
        rr = r * (1.0 - 0.06 * (k + 0.5) / drums)
        bm, caps = K.tube([tuple(a), tuple(a.lerp(b, 0.5)), tuple(b)], [rr, rr * 0.995, rr * 0.99], segs=segs, caps=True, wobble=0.01, seed=k)
        bld.add(name, bm, slot)
        bld.add(name, caps, slot)
    box(bld, name, tuple(f + Vector((0, height - 0.32, 0))), (r * 2.3, 0.16, r * 2.3), capital_slot, bevel=0.015)
    box(bld, name, tuple(f + Vector((0, height - 0.1, 0))), (r * 2.9, 0.2, r * 2.9), capital_slot, bevel=0.02)


def steps(bld, name, centre_back, widths, depth, rise, slot, z_dir=1.0):
    """A stepped dais rising toward the back wall: widths from the lowest step up."""
    c = Vector(centre_back)
    n = len(widths)
    for k, w in enumerate(widths):
        d = depth * (n - k)
        box(bld, name, tuple(c + Vector((0, rise * (k + 0.5), z_dir * d * 0.5))), (w, rise, d), slot, wear=0.4 if k == 0 else 0.2, bevel=0.01)


def flame_spot(info, pos, size=0.5):
    info.setdefault("fx", {}).setdefault("flames", []).append({"pos": [round(v, 3) for v in pos], "size": size})


def brazier(bld, name, foot, slot="BRONZE"):
    f = Vector(foot)
    for k in range(3):
        a = k / 3 * math.tau
        leg_foot = f + Vector((math.cos(a) * 0.32, 0, math.sin(a) * 0.32))
        K.log_piece(bld, name, tuple(leg_foot), tuple(f + Vector((math.cos(a) * 0.16, 0.85, math.sin(a) * 0.16))), 0.02, seed=k, slot=slot, end_slot=slot, knots=False, bend=0.03, stubs=0, cut=(0.0, 0.0))
    bowl = K.lathe([(0.08, 0.0), (0.26, 0.06), (0.34, 0.16), (0.36, 0.2)], segs=16, at=tuple(f + Vector((0, 0.82, 0))), wall=0.02)
    bld.add(name, bowl, slot)
    for k in range(6):
        K.rock(bld, name, tuple(f + Vector((math.cos(k) * 0.14, 1.0, math.sin(k) * 0.14))), (0.06, 0.04, 0.05), seed=k + 20, slot="EMBER", subdiv=1)


# =====================================================================================

def build_shelter(bld):
    S = _S()
    rng = random.Random(41)
    info = {}
    R_POST = 3.7
    EAVE = 2.05
    APEX = Vector((0.0, 4.5, -0.2))
    R_SEAT = 2.5

    def height(x, z):
        r = math.hypot(x, z)
        base = 0.012 * _noise(Vector((x * 0.7, z * 0.7, 0.3)))
        if r > 7.5:
            t = min(1.0, (r - 7.5) / 30.0)
            base += (t ** 1.6) * 0.9 + 0.3 * t * _fractal(Vector((x * 0.05, z * 0.05, 1.0)), 0.6, 2.0, 3)
        return base

    def wear(x, z):
        r = math.hypot(x, z)
        w = max(0.0, min(1.0, (4.2 - r) / 1.4))
        w = max(w, max(0.0, 1.0 - abs(z - 0.8 + 0.1 * x) / 0.9) * (1.0 if x < -2 else 0.0) * max(0.0, min(1.0, (9.0 + x) / 3.0)))
        w *= 0.75 + 0.25 * _noise(Vector((x * 1.3, z * 1.3, 4.0)))
        return max(0.0, min(1.0, w))

    K.ground(bld, "Ground", inner=9.0, outer=60.0, step_in=0.22, rings_out=9, height_fn=height, wear_fn=wear)
    S.hearth_ring(bld, seed=5)

    # posts round the back and sides, a ring beam on them, rafters up to the smoke hole
    post_phis = [96, 122, 148, 174, 200, 226, 252]
    tops = []
    for i, phi in enumerate(post_phis):
        foot = Vector(S.polar(phi, R_POST))
        K.post(bld, "Frame", tuple(foot), EAVE, 0.1, seed=i, slot="WOOD", pointed=False, segs=9, wear=0.2)
        tops.append(foot + Vector((0, EAVE, 0)))
    for i in range(len(tops) - 1):
        K.log_piece(bld, "Frame", tuple(tops[i] + Vector((0, -0.05, 0))), tuple(tops[i + 1] + Vector((0, -0.05, 0))), 0.07, seed=10 + i, slot="WOOD", knots=False, bend=0.01, stubs=0)
    rafters = [86 + k * 9.0 for k in range(20)]
    for k, phi in enumerate(rafters):
        eave = Vector(S.polar(phi, R_POST + 0.55, EAVE - 0.2))
        top = APEX + Vector(S.polar(phi, 0.55, -0.15))
        K.log_piece(bld, "Rafters", tuple(eave), tuple(top), 0.045, seed=k, slot="WOOD", knots=False, bend=0.01, stubs=0, cut=(0.0, 0.0))

    # the reed roof over the back, its smoke hole at the top (the front is open to the god)
    def cone(u, v):
        phi = 84 + (276 - 84) * u
        r = (R_POST + 0.7) * (1.0 - v) + 0.6 * v
        y = (EAVE - 0.25) * (1.0 - v) + (APEX.y + 0.05) * v + 0.06 * _noise(Vector((phi * 0.1, v * 4.0, 1.0)))
        p = Vector(S.polar(phi, r, y)) + Vector((0, 0, APEX.z * v))
        # a ragged eave
        if v < 0.05:
            p.y -= 0.12 * abs(_noise(Vector((phi * 0.4, 0, 3.0))))
        return K.B(p)

    roof = K.sheet(40, 8, cone)
    K.thicken(roof, 0.2)
    bld.add("Roof", roof, "THATCH")
    caster = K.sheet(16, 6, lambda u, v: K.B(Vector(S.polar(-84 + 168 * u, (R_POST + 0.7) * (1 - v) + 0.6 * v, (EAVE - 0.25) * (1 - v) + APEX.y * v)) + Vector((0, 0, APEX.z * v))))
    K.thicken(caster, 0.2)
    bld.add("ShadowCaster", caster, "THATCH")

    # woven reed screens between the back posts
    for i in range(1, len(post_phis) - 2):
        f0 = Vector(S.polar(post_phis[i], R_POST))
        f1 = Vector(S.polar(post_phis[i + 1], R_POST))
        nm = "Screens"
        nrm = Vector((-(f1 - f0).z, 0, (f1 - f0).x)).normalized()

        def screen(u, v, f0=f0, f1=f1, nrm=nrm):
            lift = 0.05 + 1.55 * v + 0.02 * _noise(Vector((u * 5, v * 3, f0.x)))
            return K.B(f0.lerp(f1, u) + Vector((0, lift, 0)) + nrm * 0.05 * math.sin(u * math.pi))

        scr = K.sheet(8, 4, screen)
        K.thicken(scr, 0.03)
        bld.add(nm, scr, "REED")
        K.log_piece(bld, nm, tuple(f0 + Vector((0, 1.6, 0))), tuple(f1 + Vector((0, 1.6, 0))), 0.02, seed=i, slot="WOOD", knots=False, bend=0.0, stubs=0)

    # log seats, and carved seats for the eldest at the back
    seat_marks = []
    for i, (phi, length, r) in enumerate([(72, 1.9, 0.22), (116, 2.0, 0.24), (244, 1.8, 0.23), (290, 1.7, 0.21)]):
        c = Vector(S.polar(phi, R_SEAT, r * 0.82))
        t = S.tangent(phi)
        K.log_piece(bld, "Seats", tuple(c - t * length * 0.5), tuple(c + t * length * 0.5), r, seed=i * 3.1, wear=0.6, flat=0.86, stubs=1)
        seat_marks.append((phi, c, r))
    elder_seats = []
    for i, phi in enumerate([158, 180, 202]):
        c = Vector(S.polar(phi, 2.6))
        inward = Vector((-c.x, 0, -c.z)).normalized()
        side = Vector((inward.z, 0, -inward.x))
        # a block of wood, its back carved with notches
        bm, caps = K.tube([tuple(c + Vector((0, 0.0, 0))), tuple(c + Vector((0, 0.44, 0)))], [0.26, 0.25], segs=12, caps=True, flat=0.85, wobble=0.04, seed=i)
        bld.add("ElderSeats", bm, "WOOD", wear=0.5)
        bld.add("ElderSeats", caps, "WOOD_END", wear=0.5)
        back = c - inward * 0.24
        bk = K.sheet(3, 4, lambda u, v, back=back, side=side: K.B(back + side * ((u - 0.5) * 0.46 * (1.0 - 0.3 * v)) + Vector((0, 0.42 + 0.62 * v, 0)) - inward * 0.05 * v))
        K.thicken(bk, 0.07)
        bld.add("ElderSeats", bk, "WOOD", wear=0.3)
        for k in range(3):
            K.rock(bld, "ElderSeats", tuple(back + Vector((0, 0.6 + k * 0.16, 0)) + inward * 0.05), (0.07, 0.02, 0.025), seed=60 + k + i, slot="OCHRE", subdiv=1)
        elder_seats.append((phi, c))

    # the standing stones beyond, ochre about their middles
    for k, phi in enumerate([140, 165, 190, 215, 236]):
        p = Vector(S.polar(phi, 8.2 + 0.6 * math.sin(k * 2.0)))
        h = 1.4 + 0.5 * ((k * 7) % 3) / 2
        K.rock(bld, "Stones", tuple(p + Vector((0, h * 0.45, 0))), (0.32, h, 0.24), seed=7.7 + k, flat=1.0)
        band = K.lathe([(0.3, 0.0), (0.33, 0.08), (0.3, 0.16)], segs=12, at=tuple(p + Vector((0, h * 0.62, 0))), cap_bottom=False)
        K.thicken(band, 0.012)
        bld.add("Stones", band, "OCHRE")

    # the store under the eaves at the back right; the rack outside at the right
    store = Vector(S.polar(128, 3.0))
    food = S.store_baskets(bld, store, [(-0.45, 0.0, 0.24, 0.26), (0.15, -0.1, 0.27, 0.3), (0.55, 0.35, 0.22, 0.22), (-0.15, 0.5, 0.2, 0.2)],
                           ["FOOD_GRAIN", "FOOD_ROOT", "BERRY", "FOOD_GRAIN"])
    pots = []
    for k, (dx, dz) in enumerate([(0.9, -0.3), (-0.9, 0.3), (0.5, -0.65)]):
        nm = "pots_%d" % k
        K.pot(bld, nm, tuple(store + Vector((dx, 0, dz))), 0.22, 0.4, seed=k)
        pots.append(nm)
    S.gated(info, "pottery", pots)
    trays = []
    for k, (phi, r) in enumerate([(150, 1.9), (212, 1.85)]):
        nm = "trays_%d" % k
        K.tray(bld, nm, S.polar(phi, r), 0.2, 0.06, seed=k + 4)
        trays.append(nm)
    S.gated(info, "pottery", trays, without=True)
    quern = Vector(S.polar(228, 3.0))
    K.rock(bld, "quern_0", tuple(quern + Vector((0, 0.08, 0))), (0.38, 0.12, 0.26), seed=3.3)
    K.rock(bld, "quern_0", tuple(quern + Vector((0.05, 0.21, 0))), (0.14, 0.06, 0.1), seed=3.9)
    S.gated(info, "farming", ["quern_0"])
    rack = S.drying_rack(bld, Vector(S.polar(96, 5.6)), 96, count=8)
    spears = S.spear_stand(bld, [Vector(S.polar(252, R_POST)), Vector(S.polar(226, R_POST))], seed=8)

    # firewood stacked against the screens, debris, a mat by the eldest
    wood = Vector(S.polar(186, 3.45))
    along = S.tangent(186)
    acr = along.cross(Vector((0, 1, 0)))
    for layer in range(3):
        for k in range(5 - layer):
            c = wood + along * ((k - (4 - layer) * 0.5) * 0.1) + Vector((0, 0.05 + layer * 0.085, 0))
            K.log_piece(bld, "Firewood", tuple(c - acr * 0.4 + along * 0.6), tuple(c + acr * 0.4 + along * 0.6), rng.uniform(0.035, 0.05), seed=100 + layer * 7 + k, knots=False, bend=0.02, stubs=0)
    S.scatter_debris(bld, 1.0, 4.5, seed=33)
    for k, (phi, r, w) in enumerate([(180, 1.75, 1.2)]):
        c = Vector(S.polar(phi, r))
        mat = K.sheet(5, 3, lambda u, v, c=c, w=w: K.B(c + Vector((w * (u - 0.5), 0.012, 0.8 * (v - 0.5)))))
        K.thicken(mat, 0.01)
        bld.add("Mats", mat, "REED", wear=0.3)

    def avoid(x, z):
        r = math.hypot(x, z)
        return r < 4.4 or (z > 3.5 and abs(x) < 1.6)

    S.meadow(bld, 4.0, avoid, seed=9, count=520, r_out=24.0)
    S.distance(bld, seed=2.0)

    marks = S.base_marks()
    marks["door"] = S.mark(S.polar(272, 4.8), face="fire")
    marks["door_out"] = S.mark(S.polar(272, 8.5), face="fire")
    crowd = []
    for phi, c in elder_seats:
        crowd.append(S.mark((c.x, 0.0, c.z), face="fire", sit=True, seat=0.47))
    for phi, c, r in seat_marks:
        if 100 <= phi <= 260:
            crowd.append(S.mark((c.x, 0.0, c.z), face="fire", sit=True, seat=round(r * 1.82, 3)))
    for phi, r in [(140, 3.3), (220, 3.3), (166, 3.35), (196, 3.4)]:
        crowd.append(S.mark(S.polar(phi, r), face="fire"))
    for i, m in enumerate(crowd):
        marks["crowd_%d" % i] = m
    for i, (phi, r) in enumerate([(40, 1.6), (128, 2.4), (75, 3.6), (318, 2.4)]):
        marks["animal_%d" % i] = S.mark(S.polar(phi, r), face="fire")

    info.update({
        "marks": marks,
        "props": {"food": food, "rack": rack, "spears": spears, "spears_peace": 3},
        "default_tags": ["pottery", "farming"],
        "fx": {"fire": {"pos": [0, 0.05, 0], "size": 1.0}, "smoke_top": 9.0, "dust": {"pos": [0.0, 1.4, 0.8], "extent": [4.0, 1.4, 2.8]}},
        "light": {"open_sky": True, "sun_dir": [0.62, -0.62, -0.48], "sun_energy": 1.3, "fire_energy": 1.35, "fire_range": 6.5, "fog": 0.002},
        "camera": {"yaw": 22.0, "pitch": -12.0, "fov": 52.0, "centre": [0.1, 0.85, 0.25], "yaw_range": [-40.0, 50.0]},
        "ink": ["Hearth", "Seats", "ElderSeats", "Frame", "Rafters", "Roof", "Screens", "Stones", "Store", "Rack", "Firewood", "Debris", "Trees", "Shrubs", "Mats", "food_", "rack_", "spear_", "pots_", "trays_", "quern_"],
        "shadow_only": ["ShadowCaster"],
        "door_side": -1,
    })
    return info


# =====================================================================================

def build_mudbrick_hall(bld):
    S = _S()
    rng = random.Random(53)
    info = {}
    X0, X1 = -7.2, 7.2
    ZB = -4.4
    H = 4.3
    T = 0.45

    def height(x, z):
        inside = X0 < x < X1 and z > ZB
        base = 0.004 * _noise(Vector((x, z, 0.0)))
        if not inside:
            r = max(X0 - x, x - X1, ZB - z, 0.0)
            base += min(1.0, r / 18.0) ** 1.5 * 1.2
        return base

    def wear(x, z):
        w = max(0.0, 1.0 - abs(x) / 1.4) * (1.0 if -3.2 < z < 3.5 else 0.0)
        w = max(w, max(0.0, 1.0 - abs(z - 0.6) / 0.8) * (1.0 if x < -3 else 0.0))
        w = max(w, max(0.0, 1.0 - math.hypot(x, z) / 2.6))
        w *= 0.8 + 0.2 * _noise(Vector((x * 1.7, z * 1.7, 2.0)))
        return max(0.0, min(1.0, w))

    K.ground(bld, "Ground", inner=10.0, outer=50.0, step_in=0.25, rings_out=6, height_fn=height, wear_fn=wear)

    # walls of mudbrick, plastered; the plaster has fallen in places to show the courses
    box(bld, "Walls", ((X0 + X1) * 0.5, H * 0.5, ZB - T * 0.5), (X1 - X0 + 2 * T, H, T), "PLASTER", wear=0.0)
    for side, x in ((-1, X0 - T * 0.5), (1, X1 + T * 0.5)):
        if side < 0:
            # the door in the left wall
            box(bld, "Walls", (x, H * 0.5, (ZB + 0.0) * 0.5), (T, H, 0.0 - ZB), "PLASTER")
            box(bld, "Walls", (x, H * 0.5, (1.5 + 3.4) * 0.5), (T, H, 3.4 - 1.5), "PLASTER")
            box(bld, "Walls", (x, (2.4 + H) * 0.5, 0.75), (T, H - 2.4, 1.5), "PLASTER")
            K.log_piece(bld, "Frame", (x, 2.4, -0.15), (x, 2.4, 1.65), 0.09, seed=1, slot="WOOD", knots=False, bend=0.0, stubs=0)
        else:
            box(bld, "Walls", (x, H * 0.5, (ZB + 3.4) * 0.5), (T, H, 3.4 - ZB), "PLASTER")
    # a dado of darker plaster along the foot of the walls, a painted band above
    box(bld, "Walls", ((X0 + X1) * 0.5, 0.45, ZB + 0.02), (X1 - X0, 0.9, 0.06), "MUD")
    box(bld, "Walls", ((X0 + X1) * 0.5, 2.85, ZB + 0.02), (X1 - X0, 0.22, 0.05), "WEAVE_B")
    box(bld, "Walls", (X1 - 0.02, 0.45, -0.5), (0.06, 0.9, 7.8), "MUD")
    box(bld, "Walls", (X1 - 0.02, 2.85, -0.5), (0.05, 0.22, 7.8), "WEAVE_B")

    # the flat roof: beams across from the back wall, reed matting over them,
    # an open light well over the floor before the dais
    for k in range(13):
        x = X0 + 0.5 + k * (X1 - X0 - 1.0) / 12
        K.log_piece(bld, "Roof", (x, H - 0.1, ZB - 0.2), (x, H - 0.1, 1.8), 0.11, seed=k, slot="WOOD", knots=False, bend=0.005, stubs=0)
    well = (-1.3, 1.3, -2.2, -0.3)
    for (x0, x1, z0, z1) in [(X0, well[0], ZB, 1.6), (well[1], X1, ZB, 1.6), (well[0], well[1], ZB, well[2]), (well[0], well[1], well[3], 1.6)]:
        mat = K.sheet(max(2, int((x1 - x0) / 0.6)), max(2, int((z1 - z0) / 0.6)), lambda u, v, x0=x0, x1=x1, z0=z0, z1=z1: K.B((x0 + (x1 - x0) * u, H + 0.02, z0 + (z1 - z0) * v)))
        K.thicken(mat, 0.08)
        bld.add("Roof", mat, "REED")
    for (x0, x1, z) in [(well[0], well[1], well[2]), (well[0], well[1], well[3])]:
        K.log_piece(bld, "Roof", (x0 - 0.2, H + 0.05, z), (x1 + 0.2, H + 0.05, z), 0.07, seed=x0 + z, slot="WOOD", knots=False, bend=0.0, stubs=0)
    for (x0, x1, z0, z1) in [(X0 - 1, X1 + 1, 1.6, 4.0)]:
        cst = K.sheet(8, 3, lambda u, v, x0=x0, x1=x1, z0=z0, z1=z1: K.B((x0 + (x1 - x0) * u, H + 0.02, z0 + (z1 - z0) * v)))
        K.thicken(cst, 0.1)
        bld.add("ShadowCaster", cst, "REED")
    box(bld, "ShadowCaster", ((X0 + X1) * 0.5, H * 0.5, 3.6), (X1 - X0, H, 0.3), "PLASTER")

    # two timber columns, plastered and painted in bands, a beam across them
    for x in (-3.3, 3.3):
        bm, caps = K.tube([(x, 0, -1.6), (x, H * 0.5, -1.6), (x, H - 0.2, -1.6)], [0.17, 0.16, 0.15], segs=14, caps=True, wobble=0.02, seed=x)
        bld.add("Columns", bm, "PLASTER")
        bld.add("Columns", caps, "WOOD_END")
        for k, (y, slot) in enumerate([(0.5, "OCHRE"), (1.9, "WEAVE_B"), (3.6, "OCHRE")]):
            band = K.lathe([(0.175, 0.0), (0.18, 0.06), (0.175, 0.12)], segs=14, at=(x, y, -1.6), cap_bottom=False)
            K.thicken(band, 0.01)
            bld.add("Columns", band, slot)
    K.log_piece(bld, "Columns", (-3.6, H - 0.25, -1.6), (3.6, H - 0.25, -1.6), 0.14, seed=4, slot="WOOD", knots=False, bend=0.0, stubs=0)

    # the stepped dais against the back wall, the seat-place on it facing the god
    S_W = [3.6, 3.0, 2.4]
    steps(bld, "Dais", (0.0, 0.0, ZB), S_W, 0.42, 0.2, "BRICK")
    seat_c = Vector((0.0, 0.6, ZB + 0.45))
    box(bld, "Dais", tuple(seat_c + Vector((0, 0.22, 0))), (1.2, 0.44, 0.62), "WOOD", bevel=0.02)
    box(bld, "Dais", tuple(seat_c + Vector((0, 0.95, -0.27))), (1.3, 1.5, 0.12), "WOOD", bevel=0.02)
    for s in (-1, 1):
        box(bld, "Dais", tuple(seat_c + Vector((s * 0.62, 0.62, 0.0))), (0.12, 0.3, 0.6), "WOOD", bevel=0.015)
    drape = K.sheet(5, 6, lambda u, v: K.B((-0.6 + 1.2 * u, seat_c.y + 1.62 - 1.2 * v - 0.02 * math.sin(u * math.pi), seat_c.z - 0.2 + 0.62 * max(0.0, v - 0.55) * 2.2)))
    K.thicken(drape, 0.02)
    bld.add("weave_seat", drape, "WEAVE_A")
    S.gated(info, "weaving", ["weave_seat"])
    # behind the seat a woven hanging and a painted disc of the god
    K.hanging(bld, "weave_back", (-1.6, 3.6, ZB + 0.06), (1.6, 3.6, ZB + 0.06), 1.35, seed=2.0, slot="WEAVE_C")
    S.gated(info, "weaving", ["weave_back"])
    K.shield(bld, "Dais", (0.0, 3.05, ZB + 0.12), (0, 0, 1), 0.42, slot="SHIELD_C", boss_slot="GOLD")

    # the offering table before the dais
    tc = Vector((0.0, 0.0, -2.75))
    box(bld, "Table", tuple(tc + Vector((0, 0.55, 0))), (1.6, 0.08, 0.6), "WOOD", wear=0.4, bevel=0.01)
    for sx in (-0.7, 0.7):
        for sz in (-0.22, 0.22):
            box(bld, "Table", tuple(tc + Vector((sx, 0.26, sz))), (0.08, 0.52, 0.08), "WOOD")
    offer = []
    nm = "food_0"
    K.tray(bld, nm, tuple(tc + Vector((-0.45, 0.6, 0.0))), 0.2, 0.05, seed=1, slot="CLAY")
    K.lumps(bld, nm, tuple(tc + Vector((-0.45, 0.62, 0.0))), 0.15, 0.06, 9, 0.05, seed=1, slot="BERRY")
    offer.append(nm)
    nm = "food_1"
    for k in range(3):
        K.rock(bld, nm, tuple(tc + Vector((0.05 + k * 0.14, 0.64, 0.08 - k * 0.05))), (0.09, 0.04, 0.09), seed=10 + k, slot="BREAD", subdiv=2)
    offer.append(nm)
    nm = "food_2"
    K.pot(bld, nm, tuple(tc + Vector((0.55, 0.59, -0.05))), 0.12, 0.26, seed=3)
    offer.append(nm)
    lamps = []
    for k, x in enumerate((-0.75, 0.75)):
        nm = "lamp_%d" % k
        K.tray(bld, nm, tuple(tc + Vector((x, 0.59, 0.22))), 0.07, 0.035, seed=k, slot="CLAY")
        lamps.append(nm)
        flame_spot(info, tuple(tc + Vector((x, 0.66, 0.22))), 0.09)
    S.gated(info, "candles", lamps)

    # the raised clay hearth in the middle, plastered rim
    box(bld, "Hearth", (0.0, 0.12, 0.0), (1.5, 0.24, 1.5), "BRICK", wear=0.3, bevel=0.03)
    bld.add("Hearth", K.disc_fn(0.55, 18, lambda x, z: K.B((x, 0.25, z))), "ASH", wear=1.0)
    for k in range(5):
        a = k / 5 * 360 + 20
        K.log_piece(bld, "Hearth", S.polar(a, 0.45, 0.27), (0.0, 0.6, 0.0), 0.034, seed=k, slot="CHAR", end_slot="EMBER", segs=7, stubs=0, cut=(0.0, 0.0))
    for k in range(8):
        K.rock(bld, "Hearth", S.polar(rng.uniform(0, 360), rng.uniform(0.05, 0.4), 0.27), (0.05, 0.03, 0.04), seed=30 + k, slot="EMBER", subdiv=1)

    # the scribes' corner at the right: a low bench, tablets, a pot of styluses
    sc = Vector((5.3, 0.0, -2.4))
    box(bld, "Scribes", tuple(sc + Vector((0, 0.32, 0))), (1.8, 0.07, 0.55), "WOOD", bevel=0.01)
    for sx in (-0.8, 0.8):
        box(bld, "Scribes", tuple(sc + Vector((sx, 0.16, 0))), (0.1, 0.32, 0.5), "WOOD")
    tabs = []
    for k in range(6):
        nm = "tablet_%d" % k
        box(bld, nm, tuple(sc + Vector((-0.6 + k * 0.24, 0.37, rng.uniform(-0.12, 0.12)))), (0.16, 0.035, 0.11), "TABLET", bevel=0.01)
        tabs.append(nm)
    for k in range(4):
        nm = "tablet_stack_%d" % k
        box(bld, nm, tuple(sc + Vector((0.95, 0.04 + k * 0.04, 0.5))), (0.17, 0.035, 0.12), "TABLET", bevel=0.01)
        tabs.append(nm)
    S.gated(info, "writing", tabs)

    # stores at the back left: tall jars of grain, baskets
    store = Vector((-5.4, 0.0, -3.4))
    food = list(offer)
    for i, (dx, dz) in enumerate([(-0.6, 0.0), (0.05, -0.1), (0.7, 0.05), (-0.25, 0.65), (0.45, 0.7)]):
        at = store + Vector((dx, 0, dz))
        if i < 3:
            nm = "pots_store_%d" % i
            K.pot(bld, nm, tuple(at), 0.28, 0.62, seed=i, neck=0.6)
            S.gated(info, "pottery", [nm])
            K.heap(bld, "food_%d" % (i + 3), tuple(at + Vector((0, 0.6, 0))), 0.15, 0.06, seed=i, slot="FOOD_GRAIN")
        else:
            K.basket(bld, "Store", tuple(at), 0.3, 0.3, seed=i)
            K.lumps(bld, "food_%d" % (i + 3), tuple(at + Vector((0, 0.2, 0))), 0.24, 0.15, 10, 0.09, seed=i, slot="ONION" if i == 3 else "FOOD_ROOT")
        food.append("food_%d" % (i + 3))
    rack = []
    for i in range(7):
        nm = "rack_%d" % i
        K.strip(bld, nm, (-6.6 + i * 0.3, 2.6, ZB + 0.15), 0.55, 0.1 if i % 3 else 0.14, seed=i, slot="FISH" if i % 3 == 0 else "MEAT")
        rack.append(nm)
    K.log_piece(bld, "Store", (-6.8, 2.62, ZB + 0.15), (-4.6, 2.62, ZB + 0.15), 0.03, seed=9, slot="WOOD", knots=False, bend=0.0, stubs=0)

    # benches along the side walls for those who wait
    for x, sgn in ((X0 + 0.45, 1), (X1 - 0.45, -1)):
        for (z0, z1) in ((-3.8, -0.4), (1.8, 3.2)) if sgn > 0 else ((-0.6, 3.2),):
            box(bld, "Benches", (x, 0.42, (z0 + z1) * 0.5), (0.55, 0.08, z1 - z0), "WOOD", wear=0.4, bevel=0.01)
            box(bld, "Benches", (x - sgn * 0.0, 0.2, (z0 + z1) * 0.5), (0.5, 0.4, z1 - z0 - 0.2), "BRICK")
    # spears racked by the door, shields on the wall
    spears = []
    for i in range(10):
        z = -1.7 + (i % 5) * 0.28
        nm = "spear_%d" % i
        K.spear(bld, nm, (X0 + 0.2 + (i // 5) * 0.2, 0.02, z), (X0 + 0.12, 2.5, z + 0.04), seed=i, head_slot="BRONZE")
        spears.append(nm)
    for k, z in enumerate((-3.3, -2.5)):
        K.shield(bld, "Shields", (X0 + 0.08, 1.55, z), (1, 0.12, 0), 0.32, slot=["SHIELD_A", "SHIELD_B"][k])

    # a woven runner from the door side to the dais; reed mats
    run = K.sheet(2, 10, lambda u, v: K.B((-0.55 + 1.1 * u, 0.012, 2.8 - (2.8 - ZB - 1.3) * v)))
    K.thicken(run, 0.01)
    bld.add("weave_runner", run, "CARPET")
    S.gated(info, "weaving", ["weave_runner"])
    for k, (x, z, w) in enumerate([(-3.4, -0.4, 1.4), (3.6, 0.6, 1.2)]):
        mat = K.sheet(6, 3, lambda u, v, x=x, z=z, w=w: K.B((x - w * 0.5 + w * u, 0.012, z - 0.45 + 0.9 * v)))
        K.thicken(mat, 0.01)
        bld.add("Mats", mat, "REED", wear=0.3)

    def avoid(x, z):
        return X0 - 1 < x < X1 + 1 and z > ZB - 1

    S.meadow(bld, 8.5, avoid, seed=11, count=120, r_out=16.0)
    S.distance(bld, arc=(220, 320), seed=6.0)

    marks = S.base_marks((0.0, 2.5, 6.2))
    marks["seat_place"] = S.mark(tuple(seat_c + Vector((0, -0.6, 0.05))), face="throne", sit=True, seat=1.07)
    for i, (x, z) in enumerate([(X0 + 0.45, -3.0), (X0 + 0.45, -1.6), (X1 - 0.45, 0.0), (X1 - 0.45, 1.6)]):
        marks["crowd_%d" % i] = S.mark((x, 0.0, z), face="fire", sit=True, seat=0.46)
    for i, (x, z) in enumerate([(-4.4, -2.6), (4.4, -1.2), (-4.6, 1.6), (2.6, -3.3)]):
        marks["crowd_%d" % (i + 4)] = S.mark((x, 0, z), face="fire")
    marks["door"] = S.mark((X0 + 0.5, 0, 0.75), face="fire")
    marks["door_out"] = S.mark((X0 - 2.5, 0, 0.75), face="fire")
    for i, (x, z) in enumerate([(1.45, 1.25), (-4.6, -2.0), (3.7, 1.6), (-6.0, 1.2)]):
        marks["animal_%d" % i] = S.mark((x, 0, z), face="fire")

    info.update({
        "marks": marks,
        "props": {"food": food, "rack": rack, "spears": spears, "spears_peace": 4},
        "default_tags": ["pottery", "weaving", "writing", "farming", "baking"],
        "fx": {
            "fire": {"pos": [0, 0.27, 0], "size": 0.95},
            "smoke_top": H + 0.6,
            "shafts": [{"top": [0.0, H + 0.1, -1.25], "radius": 0.85}],
            "dust": {"pos": [0.0, 1.8, -0.6], "extent": [3.6, 1.6, 2.4]},
            "door_light": [X0 + 0.1, 1.2, 0.75],
        },
        "light": {"open_sky": False, "sun_dir": [0.05, -0.92, 0.38], "sun_energy": 2.3, "fire_energy": 1.3, "fire_range": 7.0, "fog": 0.01},
        "camera": {"yaw": 16.0, "pitch": -10.0, "fov": 52.0, "centre": [0.1, 0.9, 0.0], "yaw_range": [-30.0, 36.0]},
        "ink": ["Hearth", "Columns", "Dais", "Table", "Scribes", "Store", "Benches", "Shields", "Mats", "Frame", "Roof", "food_", "rack_", "spear_", "pots_", "weave_", "tablet_", "lamp_"],
        "shadow_only": ["ShadowCaster"],
        "door_side": -1,
    })
    return info


# =====================================================================================

def build_grand_hall(bld):
    S = _S()
    rng = random.Random(67)
    info = {}
    X0, X1 = -9.0, 9.0
    ZB = -6.2
    H = 7.2
    T = 0.7

    def height(x, z):
        inside = X0 < x < X1 and z > ZB
        base = 0.003 * _noise(Vector((x, z, 0.0)))
        if not inside:
            base += min(1.0, max(X0 - x, x - X1, ZB - z, 0.0) / 18.0) ** 1.5 * 1.2
        return base

    def wear(x, z):
        w = max(0.0, 1.0 - abs(x) / 1.0) * (1.0 if -4.5 < z < 4.0 else 0.0) * 0.6
        w = max(w, max(0.0, 1.0 - math.hypot(x, z) / 2.2))
        return max(0.0, min(1.0, w))

    K.ground(bld, "Ground", inner=11.0, outer=50.0, step_in=0.25, rings_out=6, height_fn=height, wear_fn=wear)
    # a floor of stone flags inside
    flags = K.sheet(18, 12, lambda u, v: K.B((X0 + (X1 - X0) * u, 0.015, ZB + (3.6 - ZB) * v)))
    K.thicken(flags, 0.03)
    bld.add("Floor", flags, "FLAGS", wear=lambda co: max(0.0, 1.0 - abs(co.x) / 1.2) * 0.6)

    # the walls: dressed stone, high windows in the left wall
    box(bld, "Walls", (0.0, H * 0.5, ZB - T * 0.5), (X1 - X0 + 2 * T, H, T), "STONE_BLOCK")
    box(bld, "Walls", (X1 + T * 0.5, H * 0.5, (ZB + 3.6) * 0.5), (T, H, 3.6 - ZB), "STONE_BLOCK")
    xl = X0 - T * 0.5
    wins = [(-4.6, -3.4), (-1.4, -0.2)]
    zs = [ZB, wins[0][0], wins[0][1], wins[1][0], wins[1][1], 3.6]
    for k in range(0, len(zs) - 1, 2):
        box(bld, "Walls", (xl, H * 0.5, (zs[k] + zs[k + 1]) * 0.5), (T, H, zs[k + 1] - zs[k]), "STONE_BLOCK")
    for (z0, z1) in wins:
        box(bld, "Walls", (xl, 2.2, (z0 + z1) * 0.5), (T, 4.4, z1 - z0), "STONE_BLOCK")
        box(bld, "Walls", (xl, (6.2 + H) * 0.5, (z0 + z1) * 0.5), (T, H - 6.2, z1 - z0), "STONE_BLOCK")
    # the door at the left front
    box(bld, "Walls", (xl, (3.2 + H) * 0.5, 1.6), (T * 1.02, H - 3.2, 1.8), "STONE_BLOCK")
    # a plinth course and a cornice
    box(bld, "Walls", (0.0, 0.3, ZB + 0.05), (X1 - X0, 0.6, 0.12), "STONE", bevel=0.02)
    box(bld, "Walls", (0.0, H - 0.4, ZB + 0.08), (X1 - X0, 0.3, 0.18), "STONE", bevel=0.03)
    box(bld, "Walls", (X1 - 0.05, 0.3, (ZB + 3.6) * 0.5), (0.12, 0.6, 3.6 - ZB), "STONE", bevel=0.02)

    # columns down each side, trusses over, boards above
    for x in (-5.4, 5.4):
        for z in (-4.4, -1.4):
            column(bld, "Columns", (x, 0, z), H - 0.4, 0.36, slot="STONE", capital_slot="STONE")
    for z in (-4.4, -1.4):
        K.log_piece(bld, "Roof", (X0, H - 0.3, z), (X1, H - 0.3, z), 0.2, seed=z, slot="WOOD", knots=False, bend=0.0, stubs=0)
    for k in range(11):
        x = X0 + 0.8 + k * (X1 - X0 - 1.6) / 10
        K.log_piece(bld, "Roof", (x, H - 0.05, ZB), (x, H - 0.05, 1.5), 0.12, seed=k, slot="WOOD", knots=False, bend=0.0, stubs=0)
    boards = K.sheet(10, 6, lambda u, v: K.B((X0 - 0.5 + (X1 - X0 + 1) * u, H + 0.12, ZB - 0.5 + (2.0 - ZB) * v)))
    K.thicken(boards, 0.1)
    bld.add("Roof", boards, "PLANK")
    cst = K.sheet(8, 3, lambda u, v: K.B((X0 - 1 + (X1 - X0 + 2) * u, H + 0.12, 1.5 + 4.0 * v)))
    K.thicken(cst, 0.12)
    bld.add("ShadowCaster", cst, "PLANK")
    box(bld, "ShadowCaster", (0.0, H * 0.5, 3.9), (X1 - X0, H, 0.4), "STONE")

    # the dais and the throne-seat under a canopy
    steps(bld, "Dais", (0.0, 0.0, ZB), [5.4, 4.6, 3.8, 3.0], 0.45, 0.2, "STONE")
    tc = Vector((0.0, 0.8, ZB + 0.55))
    box(bld, "Dais", tuple(tc + Vector((0, 0.24, 0))), (1.3, 0.48, 0.7), "WOOD", bevel=0.02)
    box(bld, "Dais", tuple(tc + Vector((0, 1.35, -0.3))), (1.4, 2.2, 0.14), "WOOD", bevel=0.02)
    for s in (-1, 1):
        box(bld, "Dais", tuple(tc + Vector((s * 0.68, 0.7, 0.0))), (0.14, 0.4, 0.66), "WOOD", bevel=0.02)
        K.rock(bld, "Dais", tuple(tc + Vector((s * 0.68, 0.95, 0.3))), (0.08, 0.08, 0.08), seed=s + 3, slot="GOLD", subdiv=2)
    drape = K.sheet(5, 6, lambda u, v: K.B((-0.62 + 1.24 * u, tc.y + 2.35 - 1.6 * v - 0.02 * math.sin(u * math.pi), tc.z - 0.22 + 0.7 * max(0.0, v - 0.6) * 2.5)))
    K.thicken(drape, 0.02)
    bld.add("weave_throne", drape, "WEAVE_A")
    # the canopy: a cloth on four poles over the seat
    cz = tc.z + 0.1
    for sx in (-1.1, 1.1):
        for sz in (-0.6, 1.0):
            bm, caps = K.tube([(sx, tc.y - 0.0, cz + sz), (sx, tc.y + 3.4, cz + sz)], [0.05, 0.045], segs=8, caps=True)
            bld.add("Canopy", bm, "GOLD")
            bld.add("Canopy", caps, "GOLD")
    can = K.sheet(8, 6, lambda u, v: K.B((-1.2 + 2.4 * u, tc.y + 3.4 - 0.12 * math.sin(u * math.pi) * math.sin(v * math.pi), cz - 0.7 + 1.8 * v)))
    K.thicken(can, 0.02)
    bld.add("Canopy", can, "WEAVE_A")
    def valance(k):
        def f(u, v):
            y = tc.y + 3.4 - 0.4 * v
            if k == 0:
                return K.B((-1.2 + 2.4 * u, y, cz + 1.1))
            return K.B((-1.2 if k == 1 else 1.2, y, cz - 0.7 + 1.8 * u))
        return f

    for k in range(3):
        side = K.sheet(10, 2, valance(k))
        K.thicken(side, 0.015)
        bld.add("Canopy", side, "WEAVE_C")
    S.gated(info, "weaving", ["weave_throne"])

    # banners hung between the columns and on the back wall
    bans = []
    for k, (x, z, slot, drop) in enumerate([(-5.4, -2.9, "WEAVE_B", 3.6), (5.4, -2.9, "WEAVE_B", 3.6), (-3.2, ZB + 0.12, "WEAVE_C", 3.0), (3.2, ZB + 0.12, "WEAVE_C", 3.0)]):
        nm = "weave_banner_%d" % k
        if k < 2:
            K.hanging(bld, nm, (x, H - 0.6, z - 0.55), (x, H - 0.6, z + 0.55), drop, seed=k, slot=slot)
        else:
            K.hanging(bld, nm, (x - 0.6, H - 1.0, z), (x + 0.6, H - 1.0, z), drop, seed=k, slot=slot)
        bans.append(nm)
    S.gated(info, "weaving", bans)

    # the long carpet from the front to the dais
    run = K.sheet(3, 14, lambda u, v: K.B((-1.0 + 2.0 * u, 0.035, 3.2 - (3.2 - ZB - 1.9) * v)))
    K.thicken(run, 0.012)
    bld.add("Carpet", run, "CARPET")

    # the great hearth in the middle, braziers by the dais
    for k in range(14):
        a = k / 14 * 360
        K.rock(bld, "Hearth", S.polar(a, 0.82), (0.2, 0.14, 0.16), seed=k * 1.3, slot="STONE_DARK")
    bld.add("Hearth", K.disc_fn(0.72, 20, lambda x, z: K.B((x, 0.04, z))), "ASH", wear=1.0)
    for k in range(6):
        a = k / 6 * 360 + 15
        K.log_piece(bld, "Hearth", S.polar(a, 0.6, 0.05), (0.0, 0.42, 0.0), 0.04, seed=k, slot="CHAR", end_slot="EMBER", segs=7, stubs=0, cut=(0.0, 0.0))
    for k in range(10):
        K.rock(bld, "Hearth", S.polar(rng.uniform(0, 360), rng.uniform(0.05, 0.5), 0.045), (0.05, 0.03, 0.04), seed=30 + k, slot="EMBER", subdiv=1)
    for x in (-2.4, 2.4):
        brazier(bld, "Braziers", (x, 0.0, ZB + 2.4))
        flame_spot(info, (x, 1.05, ZB + 2.4), 0.4)

    # benches along the sides; a long table of food at the right
    for x in (X0 + 0.55, X1 - 0.55):
        for (z0, z1) in ((-5.6, -2.0), (-0.8, 2.8)):
            box(bld, "Benches", (x, 0.44, (z0 + z1) * 0.5), (0.5, 0.08, z1 - z0), "WOOD", wear=0.4, bevel=0.01)
            for zz in (z0 + 0.2, z1 - 0.2):
                box(bld, "Benches", (x, 0.2, zz), (0.4, 0.4, 0.1), "WOOD")
    tb = Vector((6.9, 0.0, -0.4))
    box(bld, "Table", tuple(tb + Vector((0, 0.78, 0))), (0.8, 0.07, 3.0), "WOOD", wear=0.4, bevel=0.01)
    for sz in (-1.3, 1.3):
        box(bld, "Table", tuple(tb + Vector((0, 0.38, sz))), (0.7, 0.76, 0.1), "WOOD")
    food = []
    for i, (dz, kind) in enumerate([(-1.1, "bread"), (-0.45, "fruit"), (0.15, "meat"), (0.75, "jar"), (1.2, "fish")]):
        nm = "food_%d" % i
        at = tb + Vector((0, 0.82, dz))
        if kind == "bread":
            for k in range(4):
                K.rock(bld, nm, tuple(at + Vector((rng.uniform(-0.15, 0.15), 0.03, k * 0.1 - 0.15))), (0.09, 0.045, 0.1), seed=k, slot="BREAD", subdiv=2)
        elif kind == "fruit":
            K.tray(bld, nm, tuple(at), 0.2, 0.05, seed=i, slot="BRONZE")
            K.lumps(bld, nm, tuple(at + Vector((0, 0.03, 0))), 0.15, 0.06, 9, 0.05, seed=i, slot="BERRY")
        elif kind == "meat":
            K.tray(bld, nm, tuple(at), 0.26, 0.04, seed=i, slot="WOOD")
            K.rock(bld, nm, tuple(at + Vector((0, 0.08, 0))), (0.24, 0.1, 0.14), seed=2, slot="MEAT", subdiv=2)
        elif kind == "jar":
            K.pot(bld, nm, tuple(at), 0.12, 0.3, seed=i, slot="CLAY", neck=0.5)
        else:
            for k in range(2):
                K.strip(bld, nm, tuple(at + Vector((k * 0.12 - 0.06, 0.02, -0.15))), 0.32, 0.1, seed=k, slot="FISH")
        food.append(nm)

    # spears racked by the door
    spears = []
    for i in range(12):
        z = 2.7 + (i % 6) * 0.13 - 0.6
        nm = "spear_%d" % i
        K.spear(bld, nm, (X0 + 0.3 + (i // 6) * 0.22, 0.02, z), (X0 + 0.16, 2.9, z + 0.03), seed=i, head_slot="BRONZE", head=0.22)
        spears.append(nm)
    for k, z in enumerate((-2.6, -0.8)):
        K.shield(bld, "Shields", (X1 - 0.08, 2.3, z), (-1, 0.1, 0), 0.4, slot=["SHIELD_A", "SHIELD_B"][k], boss_slot="BRONZE")

    S.distance(bld, arc=(230, 330), seed=8.0)

    marks = S.base_marks((0.0, 2.7, 7.0))
    marks["petitioner"] = S.mark((0.2, 0, 2.3))
    marks["officials_4"] = S.mark((-1.6, 0, -1.9))
    marks["officials_5"] = S.mark((1.7, 0, -2.2))
    marks["seat_place"] = S.mark(tuple(tc + Vector((0, -0.8, 0.05))), face="throne", sit=True, seat=1.27)
    for i, (x, z) in enumerate([(X0 + 0.55, -4.6), (X0 + 0.55, -3.0), (X1 - 0.55, -4.4), (X1 - 0.55, 1.6)]):
        marks["crowd_%d" % i] = S.mark((x, 0.0, z), face="fire", sit=True, seat=0.48)
    for i, (x, z) in enumerate([(-4.4, -3.4), (4.4, -3.6), (-4.2, 0.6), (4.6, 0.2)]):
        marks["crowd_%d" % (i + 4)] = S.mark((x, 0, z), face="fire")
    marks["door"] = S.mark((X0 + 0.6, 0, 1.6), face="fire")
    marks["door_out"] = S.mark((X0 - 2.5, 0, 1.6), face="fire")
    for i, (x, z) in enumerate([(1.55, 1.35), (-4.6, -2.0), (3.9, 1.8), (6.0, 1.6)]):
        marks["animal_%d" % i] = S.mark((x, 0, z), face="fire")

    info.update({
        "marks": marks,
        "props": {"food": food, "rack": [], "spears": spears, "spears_peace": 5},
        "default_tags": ["pottery", "weaving", "writing", "farming", "baking", "metal", "masonry"],
        "fx": {
            "fire": {"pos": [0, 0.05, 0], "size": 1.15},
            "smoke_top": H,
            "shafts": [{"top": [X0 - 0.2, 5.4, -4.0], "dir": [0.62, -0.62, 0.24], "radius": 0.42, "strength": 0.045},
                       {"top": [X0 - 0.2, 5.4, -0.8], "dir": [0.62, -0.62, 0.24], "radius": 0.42, "strength": 0.045}],
            "dust": {"pos": [-3.0, 3.0, -1.6], "extent": [4.0, 2.5, 2.4]},
            "door_light": [X0 + 0.1, 1.3, 1.6],
        },
        "light": {"open_sky": False, "sun_dir": [0.62, -0.62, 0.24], "sun_energy": 1.9, "fire_energy": 1.5, "fire_range": 8.0, "fog": 0.008},
        "camera": {"yaw": 16.0, "pitch": -10.0, "fov": 52.0, "centre": [0.1, 1.0, -0.2], "yaw_range": [-30.0, 36.0]},
        "ink": ["Hearth", "Columns", "Dais", "Canopy", "Table", "Benches", "Shields", "Braziers", "Carpet", "Roof", "food_", "spear_", "weave_"],
        "shadow_only": ["ShadowCaster"],
        "door_side": -1,
    })
    return info

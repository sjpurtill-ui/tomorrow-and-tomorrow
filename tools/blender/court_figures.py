"""Build the court figures and export them for Godot.

Run headless with Blender 5.2 (never opens a window):
  blender --background --factory-startup --python tools/blender/court_figures.py -- [options]
Options:
  --variants male_adult,female_adult,...   (default: all six bodies)
  --out assets/court_figures               where the .glb files go
  --quick                                  coarser fields, for trying things
  --no-ao                                  skip the ambient-occlusion bake

Each body variant becomes one court_figure_<variant>.glb holding:
  one armature "Figure" (bones listed in cf_rig.py) with every clip in
  cf_anim.CLIPS as its own animation;
  meshes: Body, Eyes, Brows, Mouth; hair_<style> for every style in
  cf_dress.HAIR_STYLES; beard_<style> (male bodies); and the pieces of each
  outfit (hide_*, tunic_*, robe_*). Godot shows one hair, at most one beard
  and one outfit's pieces per person, and hides the rest.
Materials are named by slot (SKIN, HAIR, CLOTH_A, CLOTH_B, CLOTH_C, LEATHER,
EYES, EYE_SHINE, MOUTH) so the game recolours them per people.
Vertex colour (COLOR_0): R is baked ambient occlusion; on the Body, G, B and A
are 1 where the hide, tunic and robe outfits cover the skin (the game's skin
shader discards what the worn outfit covers, so skin never shows through).
"""
import os
import sys
import time
import json
import math

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True

import bpy
import numpy as np
from mathutils import Vector

import cf_body
import cf_sdf
import cf_rig
import cf_anim
import cf_dress

OUTFIT_CHANNEL = {"hide": 1, "tunic": 2, "robe": 3}
# Triangles a part may keep (the court shows eight to twenty people at once;
# a person should come to about 10-12 thousand triangles all told).
BUDGET = {"body": 8000, "piece": 2800, "hair": 2000, "small": 700}


def args():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    opts = {"variants": list(cf_body.VARIANTS.keys()), "out": os.path.join(ROOT, "assets", "court_figures"),
            "quick": False, "ao": True}
    i = 0
    while i < len(a):
        if a[i] == "--variants":
            opts["variants"] = a[i + 1].split(",")
            i += 1
        elif a[i] == "--out":
            opts["out"] = os.path.abspath(a[i + 1])
            i += 1
        elif a[i] == "--quick":
            opts["quick"] = True
        elif a[i] == "--no-ao":
            opts["ao"] = False
        i += 1
    return opts


def clear_scene():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.armatures, bpy.data.actions, bpy.data.materials):
        for d in list(coll):
            coll.remove(d)


def log(*a):
    print("[court_figures]", *a, flush=True)


def build_variant(variant, quick=False, ao=True):
    t0 = time.time()
    f = cf_body.Frame(cf_body.params(variant))
    k = f.H / 1.72
    body = cf_body.build_body(f, "Body", voxel=0.0045 if quick else 0.003)
    cf_sdf.finish_mesh(body, BUDGET["body"], 2)
    cf_body.set_material(body, "SKIN")
    face = cf_body.build_face(f, body)
    eyes = cf_body.join(face["eyes"], "Eyes")
    brows = cf_body.join(face["brows"], "Brows")
    mouth = face["mouth"][0]
    log(variant, "body", len(body.data.polygons), "faces", round(time.time() - t0, 1), "s")
    rig = cf_rig.build_armature(f, face, name="Figure")
    missing = cf_rig.bind_body(body, rig)
    if missing:
        log("WARNING bones without weights:", missing)
    for part in (eyes, brows, mouth):
        _bind_face_part(part, rig)
    sets = {"body": [body, eyes, brows, mouth]}
    # hair and beards
    styles = list(cf_dress.HAIR_STYLES) + (list(cf_dress.BEARD_STYLES) if not f.p["female"] and not f.p.get("child") else [])
    if f.p.get("child"):
        styles = [st for st in styles if st not in ("balding", "shaved")]
    for st in styles:
        pc = cf_dress.beard_style(f, st) if st.startswith("beard") else cf_dress.hair_style(f, st)
        if pc is None:
            continue
        if quick:
            pc.voxel *= 1.5
        o = pc.build()
        if o is None:
            log("WARNING empty", st)
            continue
        cf_sdf.finish_mesh(o, BUDGET["hair"], 1)
        o.name = o.data.name = pc.name if pc.name.startswith(("hair_", "beard_")) else "hair_" + pc.name
        if st.startswith("beard"):
            o.name = o.data.name = st
        else:
            o = _hair_cards(o, st, f, body)
        cf_rig.bind_head_hair(o, rig, f)
        sets[o.name] = [o]
    log(variant, "hair", round(time.time() - t0, 1), "s")
    # clothes
    proxy = _armless_proxy(body)
    arms = _arm_vertices(body)
    masks = {}
    for kind in cf_dress.OUTFITS:
        pieces = cf_dress.outfit(f, kind)
        objs = []
        for pc in pieces:
            if quick:
                pc.voxel *= 1.5
            o = pc.build()
            if o is None:
                log("WARNING empty", pc.name)
                continue
            small = pc.name.endswith(("_belt", "_sash", "_cord", "_shoes", "_footwraps", "_trim", "_edge"))
            cf_sdf.finish_mesh(o, BUDGET["small"] if small else BUDGET["piece"], 1)
            _bind_garment(o, pc, body, proxy, rig, f)
            objs.append(o)
        sets[kind] = objs
        masks[kind] = cf_dress.coverage(body, pieces, strict=arms)
        log(variant, kind, [o.name for o in objs], "covers", int(masks[kind].sum()), "skin vertices",
            round(time.time() - t0, 1), "s")
    bpy.data.objects.remove(proxy, do_unlink=True)
    # occlusion and coverage into vertex colour
    for objs in sets.values():
        for o in objs:
            _ensure_color(o)
    if ao:
        _bake_ao(sets, body)
    _write_masks(body, masks)
    _write_hair_edges(sets, body)
    _write_face_uv(body, f)
    # each person's own face, and their mood, as morph targets
    heads = [body, eyes, brows, mouth] + [o for key, objs in sets.items() if key.startswith(("hair_", "beard_")) for o in objs]
    cf_body.face_morphs(f, heads)
    cf_body.mood_morphs(f, mouth, brows)
    riders = [o for key, objs in sets.items() if key.startswith("beard_") for o in objs]
    cf_body.expression_morphs(f, body, eyes, brows, mouth, face.get("eye_center", {}), riders)
    cf_body.gaze_morphs(eyes)
    cf_anim.write_actions(rig, k, frame=f)
    sets["props"] = build_props(rig, f)
    log(variant, "clips", len(cf_anim.CLIPS), round(time.time() - t0, 1), "s")
    rig["variant"] = variant
    rig["height"] = f.H
    rig["head_top"] = f.z_top
    return rig, f, sets


def _bundle(rig, k):
    """A hide sack, lumpy with what is in it, gathered and tied at the top, with
    the gathered ends flaring above the tie. Centre at the origin, +Z up."""
    import bmesh
    import random
    rnd = random.Random(7)
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=20, v_segments=14, radius=1.0)
    rx, ry, rz = 0.155 * k, 0.120 * k, 0.120 * k
    lumps = [(Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-0.7, 0.4))).normalized(), rnd.uniform(0.05, 0.11)) for _ in range(7)]
    for v in bm.verts:
        d = v.co.normalized()
        bump = sum(a * max(0.0, d.dot(c)) ** 6 for c, a in lumps)
        z = v.co.z
        # gathered to a neck at the top, flat-ish where it sits
        neck = 1.0
        if z > 0.55:
            t = (z - 0.55) / 0.45
            neck = 1.0 - 0.80 * t ** 0.8
        flat = 0.82 if z < -0.75 else 1.0
        v.co = Vector((v.co.x * rx * neck * (1 + bump), v.co.y * ry * neck * (1 + bump), (z * rz * flat) * (1 + 0.5 * bump)))
    me = bpy.data.meshes.new("bundle_sack")
    bm.to_mesh(me)
    bm.free()
    sack = bpy.data.objects.new("bundle_sack", me)
    bpy.context.scene.collection.objects.link(sack)
    for poly in me.polygons:
        poly.use_smooth = True
    cf_body.set_material(sack, "LEATHER")
    # the tie about the neck
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=False, segments=14, radius1=0.040 * k, radius2=0.036 * k, depth=0.022 * k)
    for v in bm.verts:
        v.co.z += 0.118 * k
    me = bpy.data.meshes.new("bundle_tie")
    bm.to_mesh(me)
    bm.free()
    tie = bpy.data.objects.new("bundle_tie", me)
    bpy.context.scene.collection.objects.link(tie)
    sol = tie.modifiers.new("wall", 'SOLIDIFY')
    sol.thickness = 0.010 * k
    for o in bpy.context.selected_objects:
        o.select_set(False)
    bpy.context.view_layer.objects.active = tie
    tie.select_set(True)
    bpy.ops.object.modifier_apply(modifier=sol.name)
    cf_body.set_material(tie, "CLOTH_C")
    # the gathered ends, flaring above the tie
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=False, segments=10, radius1=0.034 * k, radius2=0.062 * k, depth=0.060 * k)
    for v in bm.verts:
        a = math.atan2(v.co.y, v.co.x)
        if v.co.z > 0:
            v.co.z += 0.012 * k * math.sin(a * 5.0)
        v.co.z += 0.150 * k
    me = bpy.data.meshes.new("bundle_top")
    bm.to_mesh(me)
    bm.free()
    top = bpy.data.objects.new("bundle_top", me)
    bpy.context.scene.collection.objects.link(top)
    sol = top.modifiers.new("wall", 'SOLIDIFY')
    sol.thickness = 0.006 * k
    for o in bpy.context.selected_objects:
        o.select_set(False)
    bpy.context.view_layer.objects.active = top
    top.select_set(True)
    bpy.ops.object.modifier_apply(modifier=sol.name)
    cf_body.set_material(top, "LEATHER")
    bundle = cf_body.join([sack, tie, top], "prop_bundle")
    bundle.parent = rig
    return bundle


def _cord(rig, k):
    """A short loop of knotted cord, about its middle (carried between the hands)."""
    import bmesh
    bm = bmesh.new()
    pts = []
    n = 36
    for i in range(n):
        a = 2.0 * math.pi * i / n
        # a loop drooping between two hands, a knot or two along it
        pts.append(Vector((0.11 * k * math.cos(a), 0.02 * k * math.sin(2 * a), -0.07 * k * max(0.0, math.sin(a)) + 0.01 * k * math.sin(a))))
    ring = []
    r = 0.0045 * k
    segs = 6
    for i, c in enumerate(pts):
        t = (pts[(i + 1) % n] - pts[i - 1]).normalized()
        u = t.cross(Vector((0, 0, 1)))
        if u.length < 1e-4:
            u = Vector((1, 0, 0))
        u.normalize()
        w = t.cross(u).normalized()
        knot = 1.8 if i in (8, 9, 26) else 1.0
        ring.append([bm.verts.new(c + (u * math.cos(2 * math.pi * j / segs) + w * math.sin(2 * math.pi * j / segs)) * r * knot) for j in range(segs)])
    for i in range(n):
        a, b = ring[i], ring[(i + 1) % n]
        for j in range(segs):
            bm.faces.new((a[j], a[(j + 1) % segs], b[(j + 1) % segs], b[j]))
    me = bpy.data.meshes.new("prop_cord")
    bm.to_mesh(me)
    bm.free()
    cord = bpy.data.objects.new("prop_cord", me)
    bpy.context.scene.collection.objects.link(cord)
    for poly in me.polygons:
        poly.use_smooth = True
    cf_body.set_material(cord, "CLOTH_C")
    cord.parent = rig
    return cord


def build_props(rig, f):
    """What some stances hold: a staff, a bowl, a seat. Each is made where the
    stance's hands (or seat) are, then carried back to the rest pose so it
    rides that hand in the clip."""
    import bmesh
    k = f.H / 1.72
    poser = cf_anim.Poser(rig, k)
    made = []

    def posed(stance):
        cf_anim.FRAME = f
        poser.apply(cf_anim._scaled(cf_anim.clip_stance(stance, 0.0), k))
        bpy.context.view_layer.update()

    def to_rest(obj, bone):
        pb = rig.pose.bones[bone]
        m = pb.bone.matrix_local @ pb.matrix.inverted()
        for v in obj.data.vertices:
            v.co = m @ v.co
        g = obj.vertex_groups.new(name=bone)
        g.add(list(range(len(obj.data.vertices))), 1.0, 'REPLACE')
        cf_rig._armature_parent(obj, rig)

    def cylinder(name, a, b, r1, r2, segs=10, caps=True):
        bm = bmesh.new()
        d = (Vector(b) - Vector(a))
        bmesh.ops.create_cone(bm, cap_ends=caps, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=d.length)
        q = Vector((0, 0, 1)).rotation_difference(d.normalized())
        for v in bm.verts:
            v.co = q @ v.co + (Vector(a) + Vector(b)) * 0.5
        me = bpy.data.meshes.new(name)
        bm.to_mesh(me)
        bm.free()
        obj = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(obj)
        for poly in me.polygons:
            poly.use_smooth = True
        return obj

    # a staff in the right hand, its foot on the ground
    posed("staff")
    pb = rig.pose.bones["hand.R"]
    grip = pb.matrix @ Vector((0.0, f.hand_len * 0.42, 0.0))
    staff = cylinder("prop_staff", (grip.x, grip.y, 0.0), (grip.x, grip.y + 0.004, grip.z + 0.30 * k), 0.016 * k, 0.019 * k)
    knob = cylinder("knob", (grip.x, grip.y + 0.004, grip.z + 0.29 * k), (grip.x, grip.y + 0.004, grip.z + 0.36 * k), 0.026 * k, 0.012 * k)
    staff = cf_body.join([staff, knob], "prop_staff")
    cf_body.set_material(staff, "WOOD")
    to_rest(staff, "hand.R")
    made.append(staff)
    # a bowl held in both hands before the waist (it rides the right)
    posed("bowl")
    pl = rig.pose.bones["hand.L"].matrix @ Vector((0.0, f.hand_len * 0.40, 0.0))
    pr = rig.pose.bones["hand.R"].matrix @ Vector((0.0, f.hand_len * 0.40, 0.0))
    c = (pl + pr) * 0.5 + Vector((0.0, 0.0, 0.028 * k))
    bowl = cylinder("prop_bowl", c + Vector((0, 0, -0.030 * k)), c + Vector((0, 0, 0.030 * k)), 0.050 * k, 0.090 * k, segs=16, caps=False)
    sol = bowl.modifiers.new("wall", 'SOLIDIFY')
    sol.thickness = 0.008 * k
    for o in bpy.context.selected_objects:
        o.select_set(False)
    bpy.context.view_layer.objects.active = bowl
    bowl.select_set(True)
    bpy.ops.object.modifier_apply(modifier=sol.name)
    bottom = cylinder("bowl_base", c + Vector((0, 0, -0.034 * k)), c + Vector((0, 0, -0.026 * k)), 0.050 * k, 0.050 * k, segs=16)
    bowl = cf_body.join([bowl, bottom], "prop_bowl")
    cf_body.set_material(bowl, "CLAY")
    to_rest(bowl, "hand.R")
    made.append(bowl)
    # a log to sit on, under the seated hips (it does not move)
    posed("sit")
    hips = rig.pose.bones["hips"].matrix.translation
    seat = hips.z - 0.085 * k
    stool = cylinder("prop_stool", (0.0, hips.y + 0.020 * k, 0.0), (0.0, hips.y + 0.020 * k, seat), 0.165 * k, 0.155 * k, segs=14)
    cf_body.set_material(stool, "WOOD")
    stool.parent = rig
    made.append(stool)
    # a bundle of food wrapped in hide, tied at the neck: the game carries it
    # between the hands (court_figure_3d.gd), so it is made about its middle
    made.append(_bundle(rig, k))
    # a knotted cord to fidget with, carried between the hands like the bundle
    made.append(_cord(rig, k))
    poser.apply({})
    bpy.context.view_layer.update()
    for o in made:
        _ensure_color(o)
    return made


def _bind_face_part(obj, rig):
    """Joined face parts keep each source's bone in its own vertex group."""
    groups = {}
    for v in obj.data.vertices:
        pass
    # parts were tagged per object before joining: rebuild from positions
    bones = {}
    for v in obj.data.vertices:
        x = v.co.x
        if obj.name == "Mouth":
            b = "jaw"
        elif obj.name == "Eyes":
            b = "eye.L" if x > 0 else "eye.R"
        else:
            b = "brow.L" if x > 0 else "brow.R"
        bones.setdefault(b, []).append(v.index)
    obj.vertex_groups.clear()
    for b, idx in bones.items():
        g = obj.vertex_groups.new(name=b)
        g.add(idx, 1.0, 'REPLACE')
    cf_rig._armature_parent(obj, rig)


def _arm_vertices(body):
    """Vertices that belong to the arms and hands (more than half their weight)."""
    groups = {g.index for g in body.vertex_groups if g.name.split(".")[0] in
              ("upper_arm", "forearm", "hand", "thumb", "index", "fingers")}
    out = np.zeros(len(body.data.vertices), dtype=bool)
    for v in body.data.vertices:
        out[v.index] = sum(ge.weight for ge in v.groups if ge.group in groups) > 0.5
    return out


def _armless_proxy(body):
    """The body without arms and hands: skirts and mantles copy weights from it."""
    proxy = body.copy()
    proxy.data = body.data.copy()
    proxy.name = "ArmlessProxy"
    bpy.context.scene.collection.objects.link(proxy)
    arm_groups = {g.index for g in proxy.vertex_groups if g.name.split(".")[0] in
                  ("upper_arm", "forearm", "hand", "thumb", "index", "fingers")}
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(proxy.data)
    deform = bm.verts.layers.deform.active
    kill = []
    for v in bm.verts:
        w = sum(val for gi, val in v[deform].items() if gi in arm_groups)
        if w > 0.35:
            kill.append(v)
    bmesh.ops.delete(bm, geom=kill, context='VERTS')
    bm.to_mesh(proxy.data)
    bm.free()
    return proxy


def _bind_garment(obj, pc, body, proxy, rig, f):
    name = pc.name
    hangs = any(t in name for t in ("robe_body", "robe_trim", "tunic_body", "tunic_trim", "hide_wrap", "mantle"))
    in_sleeve = _sleeve_vertices(obj, pc)
    # a knee-length skirt's front follows the thighs and lies over the shins:
    # a knee raised to kneel, sit or crouch stays under the cloth instead of
    # coming out from under it (that skin is hidden, so the legs looked cut
    # off at the knee). Not the long robe: its hem would split at every step.
    front = _front_of_legs(obj, f) if hangs and name.startswith(("tunic_", "hide_")) else None

    def ease(co, i):
        if in_sleeve is not None and in_sleeve[i]:
            return []
        z = co.z
        if "mantle" in name:
            # the mantle rides the shoulders and falls from them
            t = min(1.0, max(0.0, (f.z_shoulder - 0.08 - z) / 0.25))
            return [("chest", 0.75 * t)] if t > 0 else []
        if hangs and z < f.z_hip:
            # below the hips a skirt moves with the hips more than either leg
            t = min(1.0, max(0.0, (f.z_hip - z) / 0.20))
            return [("hips", 0.55 * t * (1.0 - 0.8 * (front[i] if front is not None else 0.0)))]
        return []

    if in_sleeve is not None:
        # sleeves take the arms' weights; the rest of the garment the armless body's
        cf_rig.bind_from_body(obj, body, rig, ease=None)
        _retransfer(obj, proxy, ~in_sleeve)
    else:
        cf_rig.bind_from_body(obj, proxy if name != "hide_cape" else body, rig, ease=None)
    if hangs:
        cf_rig._ease_weights(obj, ease)
        _skirt_off_shins(obj, in_sleeve, front)
        cf_rig._normalize(obj)
        cf_rig.smooth_weights(obj, repeat=6, factor=0.5)


def _skirt_off_shins(obj, in_sleeve, front=None):
    """A skirt hangs from the hips and thighs: what the shins and feet held
    goes to the thigh above them, so a knee bent forward never splits the hem.
    Where `front` (0..1 a vertex) is given, that share stays on the shins: a
    skirt's front lies over the shins of someone kneeling or sitting."""
    table = cf_rig._weights_table(obj)
    for i, w in enumerate(table):
        if in_sleeve is not None and in_sleeve[i]:
            continue
        keep = front[i] if front is not None else 0.0
        for low in [n for n in w if n.split(".")[0] in ("shin", "foot", "toe")]:
            side = low.split(".")[-1]
            val = w.pop(low)
            w["thigh." + side] = w.get("thigh." + side, 0.0) + val * (1.0 - keep)
            if keep > 0.0:
                w["shin." + side] = w.get("shin." + side, 0.0) + val * keep
    cf_rig._write_table(obj, table)


def _front_of_legs(obj, f):
    """How much each vertex is the garment's front (1 straight ahead of the
    legs, fading to 0 by the sides), below the hips only."""
    co = np.array([v.co[:] for v in obj.data.vertices], dtype=np.float32)
    th = np.arctan2(co[:, 0], -(co[:, 1] - f.pelvis.y))
    below = np.clip((f.z_hip - co[:, 2]) / 0.10, 0.0, 1.0)
    return np.clip(1.5 * np.cos(th) - 0.2, 0.0, 1.0) * below


def _sleeve_vertices(obj, pc):
    """Which vertices of a garment belong to its sleeves (None: it has none)."""
    if pc.sleeve is None or pc.trunk is None:
        return None
    co = np.array([v.co[:] for v in obj.data.vertices], dtype=np.float32)
    return pc.sleeve(co) < pc.trunk(co)


def _near_arm(co, f, reach=0.085):
    """Whether a point lies within a sleeve's reach of either arm."""
    for side in ("L", "R"):
        for a, b in ((f.shoulder[side], f.elbow[side]), (f.elbow[side], f.wrist[side])):
            ab = b - a
            t = max(0.0, min(1.0, (co - a).dot(ab) / ab.length_squared))
            if (a + ab * t - co).length < reach:
                return True
    return False


def _retransfer(obj, proxy, mask):
    """Vertices in mask take weights from the armless proxy's nearest surface."""
    names = [g.name for g in proxy.vertex_groups]
    pw = []
    for v in proxy.data.vertices:
        pw.append({names[ge.group]: ge.weight for ge in v.groups if ge.weight > 1e-4})
    polys = proxy.data.polygons
    table = cf_rig._weights_table(obj)
    for i, v in enumerate(obj.data.vertices):
        if not mask[i]:
            continue
        ok, loc, nor, fi = proxy.closest_point_on_mesh(v.co)
        if not ok:
            continue
        acc = {}
        tot = 0.0
        for vid in polys[fi].vertices:
            wt = 1.0 / ((proxy.data.vertices[vid].co - loc).length + 1e-5)
            tot += wt
            for n, val in pw[vid].items():
                acc[n] = acc.get(n, 0.0) + val * wt
        if tot > 0 and acc:
            table[i] = {n: val / tot for n, val in acc.items()}
    for n in names:
        if obj.vertex_groups.get(n) is None:
            obj.vertex_groups.new(name=n)
    cf_rig._write_table(obj, table)


def _ensure_color(obj):
    me = obj.data
    if "Col" not in me.color_attributes:
        me.color_attributes.new("Col", 'FLOAT_COLOR', 'POINT')
    attr = me.color_attributes["Col"]
    me.color_attributes.active_color = attr
    me.color_attributes.render_color_index = me.color_attributes.find("Col")
    n = len(me.vertices)
    vals = np.zeros(n * 4, dtype=np.float32)
    vals[0::4] = 1.0
    attr.data.foreach_set("color", vals)


def _bake_ao(sets, body):
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.device = 'CPU'
    sc.cycles.samples = 48
    if sc.world is None:
        sc.world = bpy.data.worlds.new("World")
    sc.world.light_settings.distance = 0.14
    every = [o for objs in sets.values() for o in objs]
    for key, objs in sets.items():
        meshes = [o for o in objs if o.type == 'MESH' and o.name not in ("Eyes", "Brows", "Mouth")]
        if not meshes:
            continue
        others = set(sets["body"][:1]) | set(objs)
        for o in every:
            o.hide_render = o not in others
        for o in bpy.context.selected_objects:
            o.select_set(False)
        for o in meshes:
            o.select_set(True)
        bpy.context.view_layer.objects.active = meshes[0]
        # the armature deforms at rest; bake the rest pose
        try:
            bpy.ops.object.bake(type='AO', target='VERTEX_COLORS', use_clear=True)
        except Exception as e:
            log("AO bake failed for", key, e)
    for o in every:
        o.hide_render = False
    # keep AO in red only; soften it so it reads as painted shade, not grime
    for o in every:
        me = o.data
        attr = me.color_attributes.get("Col")
        if attr is None:
            continue
        n = len(me.vertices)
        vals = np.zeros(n * 4, dtype=np.float32)
        attr.data.foreach_get("color", vals)
        ao = vals[0::4].copy()
        if o.name in ("Eyes", "Brows", "Mouth"):
            ao[:] = 1.0
        ao = 0.35 + 0.65 * np.clip(ao, 0.0, 1.0) ** 0.8
        out = np.zeros(n * 4, dtype=np.float32)
        out[0::4] = ao
        attr.data.foreach_set("color", out)


# How far in from its edge hair thins out (metres, at a 1.72 m body): the
# game stipples it there (vertex colour G), so a hairline or a beard's edge is
# broken into strokes over the skin, never a cut edge of a cap.
HAIR_EDGE = {"hair_cropped": 0.0095, "hair_balding": 0.0045, "hair_shaved": 0.004, "beard_stubble": 0.006,
             "beard_short": 0.0100, "beard_chin": 0.0090, "beard_full": 0.0120, "beard_long": 0.0100,
             "beard_moustache": 0.0030}
# Hair that is stippled all over (stubble): a shadow of dots on the skin.
HAIR_STIPPLE_ALL = {"hair_shaved": 0.42, "beard_stubble": 0.50}


# Hair cards: thin strips of painted strands laid over a hair shell, so the
# hair's outline breaks into wisps and its hairline into a fringe, never a
# helmet's edge. Per style: [count, length range (m), width (m), lift, flow,
# fringe count, flyaways]. flow: "crown" (out from the crown), "down"
# (hanging), "back" (pulled back to a knot or tail).
CARD_STYLE = {
    "cropped": [150, (0.012, 0.022), 0.0085, 0.45, "crown", 60, 0],
    "balding": [80, (0.010, 0.016), 0.0080, 0.40, "crown", 0, 0],
    "long": [240, (0.040, 0.090), 0.0130, 0.18, "down", 26, 10],
    "long_framed": [240, (0.040, 0.090), 0.0130, 0.18, "down", 34, 10],
    "bun": [120, (0.016, 0.028), 0.0080, 0.30, "back", 22, 10],
    "topknot": [120, (0.016, 0.028), 0.0080, 0.30, "back", 20, 10],
    "tail": [120, (0.016, 0.028), 0.0080, 0.30, "back", 22, 10],
    "braids": [100, (0.016, 0.028), 0.0080, 0.30, "back", 24, 10],
}


def _hair_cards(shell, style, f, body):
    """Lays cards of strands over a hair shell and joins them into it (their
    own material slot HAIR_CARD; point attribute is_card marks them)."""
    import bmesh
    import random
    spec = CARD_STYLE.get(style)
    if spec is None:
        return shell
    count, (l0, l1), width, lift, flow, fringe, flyaways = spec
    k = f.H / 1.72
    s = f.head_h / 0.282
    rnd = random.Random(hash(style) & 0xffff)
    me = shell.data
    me.calc_loop_triangles()
    c = Vector((0.0, f.head_base.y + 0.004, f.z_chin + 0.62 * f.head_h))
    crown = Vector((0.0, c.y + 0.020 * s, f.z_top - 0.01 * s))
    knot = Vector((0.0, c.y + 0.11 * s, f.z_chin + 0.62 * f.head_h))
    # the outer surface: faces whose normal looks away from the head
    cands = []
    for poly in me.polygons:
        q = poly.center
        n = poly.normal
        rel = q - c
        if rel.length < 1e-4 or n.dot(rel.normalized()) < 0.35:
            continue
        cands.append((q.copy(), n.copy(), poly.area))
    if not cands:
        return shell
    zs = [q.z for q, n, a in cands]
    z_min = min(zs)
    weights = [a for q, n, a in cands]
    bm = bmesh.new()
    made = 0
    from mathutils.bvhtree import BVHTree
    surface = BVHTree.FromObject(shell, bpy.context.evaluated_depsgraph_get())

    def card(root, n, along, length, w, rise):
        """A card of strands laid ON the hair: each row is walked along the
        hair's own surface (never out into the air), lying a hair's breadth
        above it; only the very tip may lift, a little."""
        nonlocal made
        rows = []
        here, nor = root, n
        step = length / 2.0
        for j, t in enumerate((0.0, 0.5, 1.0)):
            if j > 0:
                want = here + along * step
                hit = surface.find_nearest(want)
                if hit[0] is not None:
                    here, nor = hit[0], hit[1]
                    along = (want - here + along * step)
                    along = (along - nor * along.dot(nor))
                    if along.length < 1e-6:
                        break
                    along.normalize()
                else:
                    here = want
            side = nor.cross(along)
            if side.length < 1e-5:
                break
            side.normalize()
            centre = here + nor * (0.0009 * s + rise * 0.0025 * s * t * t)
            half = w * (1.0 - 0.55 * t) * 0.5
            rows.append((bm.verts.new(centre - side * half), bm.verts.new(centre + side * half), t))
        if len(rows) < 3:
            for a0, a1, _ in rows:
                bm.verts.remove(a0)
                bm.verts.remove(a1)
            return
        for (a0, a1, ta), (b0, b1, tb) in zip(rows, rows[1:]):
            face = bm.faces.new((a0, a1, b1, b0))
            face.smooth = True
        made += 1

    def flow_at(q, n):
        if flow == "down":
            want = Vector((0.0, 0.25 * (q.y - c.y), -1.0))
        elif flow == "back":
            want = knot - q
        else:
            want = q - crown
        want = want - n * want.dot(n)
        if want.length < 1e-5:
            want = Vector((0.0, 0.0, -1.0)) - n * (-n.z)
        return want.normalized()

    picks = rnd.choices(cands, weights=weights, k=count)
    for q, n, a in picks:
        jitter = n.cross(Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1)))) * 0.002 * s
        root = q + jitter - n * 0.0012 * s
        along = flow_at(q, n)
        # a little turn, so the strands do not lie like combed rows
        turn = n.cross(along) * rnd.uniform(-0.35, 0.35)
        along = (along + turn).normalized()
        card(root, n, along, rnd.uniform(l0, l1) * k, width * k * rnd.uniform(0.8, 1.2), lift * rnd.uniform(0.6, 1.4))
    # a fringe at the hairline: short locks falling forward over the brow and temples
    front = [x for x in cands if x[0].y < c.y - 0.03 * s and x[0].z > f.face(0.62) and x[0].z < f.face(0.86)]
    for i in range(fringe if front else 0):
        q, n, a = rnd.choice(front)
        down = Vector((rnd.uniform(-0.25, 0.25), -0.25, -1.0))
        down = (down - n * down.dot(n)).normalized()
        card(q - n * 0.001 * s, n, down, rnd.uniform(0.012, 0.024) * k * (1.6 if flow == "down" else 1.0), width * k, 0.18)
    # (no strands standing out from the head: those read as quills)
    if made == 0:
        bm.free()
        return shell
    cm = bpy.data.meshes.new(shell.name + "_cards")
    bm.to_mesh(cm)
    bm.free()
    uv = cm.uv_layers.new(name="UVMap")
    for poly in cm.polygons:
        for li in poly.loop_indices:
            vi = cm.loops[li].vertex_index
            row = (vi % 6) // 2
            uv.data[li].uv = (float(vi % 2), row * 0.5)
    flag = cm.attributes.new("is_card", 'BOOLEAN', 'POINT')
    for i in range(len(cm.vertices)):
        flag.data[i].value = True
    cards = bpy.data.objects.new(shell.name + "_cards", cm)
    bpy.context.scene.collection.objects.link(cards)
    cf_body.set_material(cards, "HAIR_CARD")
    if "is_card" not in shell.data.attributes:
        shell.data.attributes.new("is_card", 'BOOLEAN', 'POINT')
    if not shell.data.uv_layers:
        shell.data.uv_layers.new(name="UVMap")
    name = shell.name
    joined = cf_body.join([shell, cards], name)
    log(name, "cards", made)
    return joined


def _write_face_uv(body, f):
    """The body's face coordinates for the game's painted face (UV: across
    and up the face from the chin, in a 0.282 m head's metres; UV2: how much
    the skin faces forward, and whether it is the head or neck)."""
    me = body.data
    s = f.head_h / 0.282
    while len(me.uv_layers) < 2:
        me.uv_layers.new(name="UVMap" if not me.uv_layers else "Face2")
    a = me.uv_layers[0].data
    b = me.uv_layers[1].data
    z_lo = f.z_shoulder + 0.010 * s
    for loop in me.loops:
        v = me.vertices[loop.vertex_index]
        co, n = v.co, v.normal
        a[loop.index].uv = (co.x / s, (co.z - f.z_chin) / s)
        on = 1.0 if (co.z > z_lo and abs(co.x) < 0.11 * s) else 0.0
        b[loop.index].uv = (max(0.0, -n.y), on)


def _write_hair_edges(sets, body):
    """Vertex colour G of hair and beards: how near the edge where they meet
    the skin (1 at the edge), and a UV of the rest position, so the game's
    stipple keeps still on the head as it moves."""
    from mathutils.bvhtree import BVHTree
    from mathutils.kdtree import KDTree
    tree = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get())
    k = body.dimensions.z / 1.72 if body.dimensions.z > 0.5 else 1.0
    for key, objs in sets.items():
        for o in objs:
            if o.type != 'MESH' or not o.name.startswith(("hair_", "beard_")):
                continue
            me = o.data
            n = len(me.vertices)
            co = [o.matrix_world @ v.co for v in me.vertices]
            signed = np.zeros(n, dtype=np.float32)
            for i, c in enumerate(co):
                hit = tree.find_nearest(c)
                if hit[0] is None:
                    signed[i] = 1.0
                    continue
                loc, nor = hit[0], hit[1]
                signed[i] = (c - loc).dot(nor)
            flags = me.attributes.get("is_card")
            is_card = [bool(flags.data[i].value) for i in range(n)] if flags is not None else [False] * n
            rim = [i for i in range(n) if signed[i] < 0.0008 * k and not is_card[i]]
            edge = np.zeros(n, dtype=np.float32)
            width = HAIR_EDGE.get(o.name, 0.0045) * k
            if rim and len(rim) < n:
                kd = KDTree(len(rim))
                for j, i in enumerate(rim):
                    kd.insert(co[i], j)
                kd.balance()
                for i in range(n):
                    _, _, dist = kd.find(co[i])
                    x = min(max(dist / width, 0.0), 1.0)
                    edge[i] = 1.0 - x * x * (3.0 - 2.0 * x)
            edge = np.maximum(edge, HAIR_STIPPLE_ALL.get(o.name, 0.0))
            card_id = np.zeros(n, dtype=np.float32)
            for i in range(n):
                if is_card[i]:
                    edge[i] = 0.0
                    card_id[i] = ((i // 6) * 0.618034) % 1.0
            attr = me.color_attributes.get("Col")
            if attr is None:
                continue
            vals = np.zeros(n * 4, dtype=np.float32)
            attr.data.foreach_get("color", vals)
            vals[1::4] = edge
            vals[2::4] = card_id
            attr.data.foreach_set("color", vals)
            # the rest position as a UV: across the head and down it
            if not me.uv_layers:
                me.uv_layers.new(name="UVMap")
            uv = me.uv_layers.active.data
            for loop in me.loops:
                if is_card[loop.vertex_index]:
                    continue
                c = co[loop.vertex_index]
                uv[loop.index].uv = (c.x * 0.8 + c.y * 0.6, c.z)


def _write_masks(body, masks):
    me = body.data
    attr = me.color_attributes["Col"]
    n = len(me.vertices)
    vals = np.zeros(n * 4, dtype=np.float32)
    attr.data.foreach_get("color", vals)
    for kind, cov in masks.items():
        vals[OUTFIT_CHANNEL[kind]::4] = cov.astype(np.float32)
    attr.data.foreach_set("color", vals)


def export(rig, sets, path):
    # Every morph rests at 0: the file's default weights come from these values.
    for objs in sets.values():
        for o in objs:
            keys = o.data.shape_keys if o.type == 'MESH' else None
            if keys is not None:
                for kb in keys.key_blocks:
                    kb.value = 0.0
    for o in bpy.context.selected_objects:
        o.select_set(False)
    rig.select_set(True)
    for objs in sets.values():
        for o in objs:
            o.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.gltf(
        filepath=path, export_format='GLB', use_selection=True, export_apply=False,
        export_yup=True, export_texcoords=True, export_normals=True, export_materials='EXPORT',
        export_vertex_color='ACTIVE', export_all_vertex_colors=False,
        export_skins=True, export_influence_nb=4, export_def_bones=False,
        export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True,
        export_optimize_animation_size=True, export_reset_pose_bones=True, export_rest_position_armature=True,
        export_morph=True, export_morph_normal=True, export_morph_animation=False, export_extras=True)


def manifest(entries, out_dir):
    data = {
        "generator": "tools/blender/court_figures.py",
        "variants": entries,
        "hair": list(cf_dress.HAIR_STYLES),
        "beards": list(cf_dress.BEARD_STYLES),
        "outfits": {k: [] for k in cf_dress.OUTFITS},
        "outfit_mask_channel": {k: "rgba"[v] for k, v in OUTFIT_CHANNEL.items()},
        "clips": {n: {"seconds": d, "loop": n in cf_anim.LOOP_CLIPS} for n, (d, _) in cf_anim.CLIPS.items()},
        "stances": list(cf_anim.STANCES),
        "free_hands": dict(cf_anim.FREE_HANDS),
        "props": {"staff": "prop_staff", "bowl": "prop_bowl", "sit": "prop_stool"},
        "carried": {"bundle": "prop_bundle", "cord": "prop_cord"},
        "fps": 30,
        "walk_speed_mps": {"walk_in": 1.18, "walk_out": 0.92, "at_height": 1.72},
        "gaze": list(cf_body.GAZE.keys()),
        "face_shapes": ["face_" + n for n in cf_body.FACE_SHAPES],
        "moods": ["mood_smile", "mood_tight", "mood_worry", "mood_stern"],
        "expressions": list(cf_body.EXPRESSIONS),
        "visemes": list(cf_body.VISEMES),
        "slots": list(cf_body.SLOT_DEFAULTS.keys()),
    }
    # bodies built in separate runs keep their entries
    path = os.path.join(out_dir, "court_figures.json")
    if os.path.exists(path):
        try:
            with open(path, encoding="utf-8") as fh:
                old = json.load(fh)
            built = {e["variant"] for e in entries}
            data["variants"] = [e for e in old.get("variants", []) if e.get("variant") not in built] + entries
            order = list(cf_body.VARIANTS.keys())
            data["variants"].sort(key=lambda e: order.index(e["variant"]) if e["variant"] in order else 99)
        except (OSError, ValueError, KeyError):
            pass
    for e in data["variants"]:
        for kind, names in e.get("outfits", {}).items():
            data["outfits"][kind] = sorted(set(data["outfits"][kind]) | set(names))
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=1)


def main():
    o = args()
    os.makedirs(o["out"], exist_ok=True)
    entries = []
    for v in o["variants"]:
        clear_scene()
        # Clips are sampled at 30 a second (cf_anim.FPS); the exporter turns
        # frames into seconds by the scene's rate, which defaults to 24: at
        # 24 every clip played 1.25 times slow (and the walk slid).
        sc = bpy.context.scene
        sc.render.fps = 30
        sc.render.fps_base = 1.0
        rig, f, sets = build_variant(v, o["quick"], o["ao"])
        path = os.path.join(o["out"], "court_figure_%s.glb" % v)
        export(rig, sets, path)
        size = os.path.getsize(path)
        log("exported", path, round(size / 1024), "KB")
        entries.append({"variant": v, "file": os.path.basename(path), "height": round(f.H, 3),
                        "head_top": round(f.z_top, 3), "chin": round(f.z_chin, 3),
                        "outfits": {k: [ob.name for ob in sets[k]] for k in cf_dress.OUTFITS},
                        "hair": [k for k in sets if k.startswith("hair_")],
                        "beards": [k for k in sets if k.startswith("beard_")]})
    manifest(entries, o["out"])
    log("done", len(entries), "variants")


if __name__ == "__main__":
    main()

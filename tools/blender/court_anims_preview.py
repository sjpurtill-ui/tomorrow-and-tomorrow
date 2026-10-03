"""Court acting (K): film strips of the clip library on J's dressed figures.

  blender --background --factory-startup --python tools/blender/court_anims_preview.py -- \
      [--clips gasp,flinch] [--variant male_adult] [--out reports/court_acting] [--engine eevee|workbench]

Imports J's exported figure (assets/court_figures/court_figure_<variant>.glb,
so it is the real body), dresses it as court_figures_preview does, and for
each clip lays copies of it side by side, each posed at one moment of the
clip (straight from court_anims_clips, face included: jaw, lids, brows and
the mood morphs), with the time written over each. One 1536x864 PNG a clip:
  strip_<clip>.png
"""
import os
import sys
import math

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True

import bpy
from mathutils import Vector, Euler

import cf_body
import cf_anim
import court_anims_lib as L
import court_anims_clips as C
import court_figures_preview as P

SPECS = {
    "male_adult": ("male_adult", "hide", "hair_long", "beard_full", 0.62, "1b1511", ("a8782a", "6e5541", "a8432f"), ()),
    "female_adult": ("female_adult", "tunic", "hair_braids", None, 0.35, "4a2a1a", ("b07a35", "6e5541", "8e2f3a"), ()),
    "male_old": ("male_old", "robe", "hair_cropped", "beard_long", 0.5, "a8a49c", ("2f4a6e", "8e2f3a", "c9a43c"), ()),
    "female_old": ("female_old", "hide", "hair_bun", None, 0.7, "b5b0a6", ("9c7a52", "5b4130", "c9a43c"), ()),
    "male_young": ("male_young", "tunic", "hair_curls", None, 0.9, "0f0d0c", ("4f7a68", "5b4130", "d08a2b"), ()),
    "female_young": ("female_young", "tunic", "hair_tail", None, 0.2, "6a3320", ("a8432f", "5b4130", "d9ccb0"), ()),
    "child": ("child", "tunic", "hair_cropped", None, 0.55, "3a2a1c", ("b07a35", "6e5541", "4f7a68"), ()),
}

# moments shown for each clip (seconds); default: evenly through it
MOMENTS = {
    "gasp": (0.0, 0.10, 0.27, 0.6, 1.1, 1.5),
    "flinch": (0.0, 0.08, 0.3, 0.8, 1.15, 1.5),
    "laugh": (0.16, 0.42, 0.95, 1.5, 1.66, 2.3),
    "laugh_stifled": (0.12, 0.34, 0.8, 1.3, 2.0, 2.4),
    "side_eye_l": (0.0, 0.42, 0.9, 1.6, 2.0, 2.5),
    "bow_shallow": (0.0, 0.18, 0.62, 1.0, 1.5, 1.9),
    "bow_deep": (0.0, 0.32, 0.98, 1.6, 2.4, 2.9),
    "bow_overdeep": (0.16, 0.70, 1.2, 1.55, 2.7, 3.2, 3.8),
    "kneel": (0.0, 0.28, 0.62, 0.9, 1.1, 2.4),
    "defiant": (0.0, 0.22, 0.5, 0.72, 1.1, 2.1),
    "talk_explain": (0.0, 0.45, 0.7, 0.92, 1.3, 1.8),
    "talk_emphatic": (0.0, 0.28, 0.44, 0.56, 0.9, 1.5),
    "talk_hesitant": (0.0, 0.3, 0.6, 1.2, 1.8, 2.1),
    "talk_plead": (0.0, 0.5, 0.95, 1.45, 1.9, 2.3),
    "talk_one": (0.0, 0.4, 0.62, 0.8, 1.4, 1.9),
    "talk_dismiss": (0.0, 0.25, 0.43, 0.6, 1.0, 1.5),
    "scratch_head": (0.0, 0.62, 0.8, 1.2, 2.2, 2.8),
    "exec_club_victim": (0.45, 1.85, 2.9, 3.66, 4.8, 6.4),
    "exec_club_batter": (0.45, 1.8, 3.0, 3.3, 3.62, 3.85, 4.6, 5.2),
    "exec_cook_lid": (2.0, 5.05, 5.7, 6.6, 7.6, 7.9),
    "exec_block_victim": (0.5, 2.6, 5.6, 7.0, 8.75, 10.6),
    "exec_axe_headsman": (1.7, 1.95, 3.1, 3.55, 5.55, 7.1, 8.5, 8.75, 10.3),
    "exec_dog_down": (0.0, 0.1, 0.3, 0.5, 0.7, 1.2),
    "exec_dog_grip": (0.2, 0.5, 1.7, 1.95, 2.2, 2.6),
}


def args():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    o = {"clips": None, "variant": "male_adult", "out": os.path.join(ROOT, "reports", "court_acting"), "engine": "eevee"}
    i = 0
    while i < len(a):
        key = a[i].lstrip("-")
        val = a[i + 1] if i + 1 < len(a) else ""
        if key == "clips":
            o["clips"] = val.split(",")
        elif key == "out":
            o["out"] = os.path.abspath(val)
        elif key in ("variant", "engine"):
            o[key] = val
        i += 2
    return o


def copy_figure(rig, meshes, n):
    """n posable copies of a dressed figure (mesh data shared; the painted
    face parts get their own so each copy wears its own expression)."""
    out = [(rig, meshes)]
    for i in range(1, n):
        r = rig.copy()
        r.data = rig.data.copy()
        r.animation_data_clear()
        bpy.context.scene.collection.objects.link(r)
        ms = []
        for m in meshes:
            c = m.copy()
            if m.name.split(".")[0] in ("Mouth", "Brows", "Eyes"):
                c.data = m.data.copy()
            c.parent = r
            for mod in c.modifiers:
                if mod.type == 'ARMATURE':
                    mod.object = r
            bpy.context.scene.collection.objects.link(c)
            ms.append(c)
        out.append((r, ms))
    return out


def set_face(meshes, fc):
    for m in meshes:
        base = m.name.split(".")[0]
        keys = m.data.shape_keys
        if keys is None:
            continue
        kb = keys.key_blocks
        if base == "Mouth":
            for name, ch in (("mood_smile", "smile"), ("mood_tight", "tight")):
                if name in kb:
                    kb[name].value = max(0.0, min(1.0, fc.get(ch, 0.0)))
        if base == "Brows":
            for name, ch in (("mood_worry", "worry"), ("mood_stern", "stern")):
                if name in kb:
                    kb[name].value = max(0.0, min(1.0, fc.get(ch, 0.0)))


def face_pose(fc, k):
    p = {}
    jaw = fc.get("jaw", 0.0)
    p["jaw"] = {"open": 1.0 + 1.5 * jaw}
    lids = fc.get("lids", 1.0)
    p["eye.L"] = {"open": max(0.06, lids)}
    p["eye.R"] = {"open": max(0.06, lids)}
    b = fc.get("brows", 0.0) * 0.0045
    p["brow.L"] = {"lift": b}
    p["brow.R"] = {"lift": b}
    return p


# --- stand-ins for the props an execution holds (M makes the real ones) -----------

def fist_frame(r, s):
    """Where a closed fist holds a handle, from the posed bones alone (the same
    sum court_acting.gd fist_frame does): origin in the curled fingers, +Y out
    of the thumb side along the handle, +Z where the knuckles point."""
    from mathutils import Matrix
    mw = r.matrix_world
    W = mw @ r.pose.bones["hand." + s].head
    P = mw @ r.pose.bones["fingers." + s].head
    I = mw @ r.pose.bones["index." + s].head
    u = (I - P).normalized()
    a = (P - W) - u * (P - W).dot(u)
    a.normalize()
    n = a.cross(u) if s == "L" else u.cross(a)
    d = (I - P).length
    C = P - a * (0.39 * d) + n * (0.65 * d)
    x = u.cross(a)
    m = Matrix((x, u, a)).transposed().to_4x4()
    m.translation = C
    return m


def _mat(name, hexcol):
    m = bpy.data.materials.get(name)
    if m is None:
        m = P.toon(name, P.srgb(hexcol), shade=(0.6, 0.5, 0.45), ao=False)
    return m


def make_prop(kind):
    """A stand-in prop: origin at the grip, +Y along the handle, +Z the blade."""
    import bmesh
    me = bpy.data.meshes.new("standin_" + kind)
    bm = bmesh.new()
    from mathutils import Matrix

    def cyl(r, y0, y1, seg=12):
        g = bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r, radius2=r, depth=y1 - y0)
        bmesh.ops.transform(bm, verts=g["verts"], matrix=Matrix.Translation((0, (y0 + y1) / 2, 0)) @ Matrix.Rotation(math.radians(-90), 4, 'X'))

    def ball(r, y, sy=1.0):
        g = bmesh.ops.create_uvsphere(bm, u_segments=14, v_segments=8, radius=r)
        bmesh.ops.transform(bm, verts=g["verts"], matrix=Matrix.Translation((0, y, 0)) @ Matrix.Diagonal((1, sy, 1, 1)))

    def box(cx, cy, cz, sx, sy, sz):
        g = bmesh.ops.create_cube(bm, size=1.0)
        bmesh.ops.transform(bm, verts=g["verts"], matrix=Matrix.Translation((cx, cy, cz)) @ Matrix.Diagonal((sx, sy, sz, 1)))
    col = "6b4a2e"
    if kind == "club":
        cyl(0.022, -0.12, 0.62)
        ball(0.075, 0.72, 1.6)
    elif kind == "axe":
        cyl(0.02, -0.08, 0.76)
        box(0.0, 0.66, 0.07, 0.03, 0.15, 0.16)
        col = "8a8f96"
    elif kind == "ladle":
        cyl(0.012, -0.05, 0.42)
        ball(0.055, 0.47)
    elif kind == "lid":
        cyl(0.02, -0.03, 0.03)
        g = bmesh.ops.create_cone(bm, cap_ends=True, segments=24, radius1=0.20, radius2=0.20, depth=0.02)
        bmesh.ops.transform(bm, verts=g["verts"], matrix=Matrix.Translation((0, 0.05, 0)) @ Matrix.Rotation(math.radians(-90), 4, 'X'))
        col = "8a6a4a"
    else:
        cyl(0.02, -0.1, 0.6)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new("standin_" + kind, me)
    bpy.context.scene.collection.objects.link(ob)
    me.materials.append(_mat("PROP_" + kind, col))
    return ob


def stage_thing(kind, at_godot, r, k, top=None):
    """The block or the pot for a preview, in figure r's frame."""
    from mathutils import Matrix
    x, y, z = at_godot
    pos = r.matrix_world @ Vector((x * k, -z * k, 0.0))
    if kind == "block":
        h = (top if top is not None else 0.45) * k
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(pos.x, pos.y, h / 2))
        ob = bpy.context.object
        ob.scale = (0.40, 0.40, h)
        ob.data.materials.append(_mat("PROP_block", "7a5a3a"))
    else:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.26, depth=0.55, location=(pos.x, pos.y, 0.275))
        ob = bpy.context.object
        ob.data.materials.append(_mat("PROP_pot", "5a3a2a"))
    return ob


def label(text, at, size=0.09):
    cu = bpy.data.curves.new("lbl", 'FONT')
    cu.body = text
    cu.size = size
    cu.align_x = 'CENTER'
    ob = bpy.data.objects.new("lbl", cu)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = Vector(at)
    ob.rotation_euler = Euler((math.radians(90), 0, 0))
    mat = bpy.data.materials.get("LABEL") or P.toon("LABEL", P.srgb("3a2c1e"), ao=False, flat=True)
    cu.materials.append(mat)
    return ob


def main():
    o = args()
    os.makedirs(o["out"], exist_ok=True)
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    cam = P.stage()
    sc = bpy.context.scene
    if o["engine"] == "workbench":
        sc.render.engine = 'BLENDER_WORKBENCH'
    v = o["variant"]
    f = cf_body.Frame(cf_body.params(v))
    L.set_frame(f)
    k = f.H / 1.72
    clips = C.all_clips()
    names = o["clips"] or list(clips.keys())
    rig, objs, acts = P.import_figure(os.path.join(ROOT, "assets", "court_figures", "court_figure_%s.glb" % v))
    P.dress(rig, objs, SPECS[v], 0)
    keep = []
    for ob in objs:
        if ob.type == 'MESH':
            base_name = ob.name.split(".")[0]
            if base_name in ("prop_staff", "prop_bowl"):
                ob.hide_render = True
                ob.hide_viewport = False
                for i, slot in enumerate(ob.material_slots):
                    slot.material = P.toon("PROP_%d" % i, P.srgb("6b4a2e" if "staff" in base_name else "a0603a"))
                keep.append(ob)
            elif ob.hide_render:
                bpy.data.objects.remove(ob, do_unlink=True)
            else:
                keep.append(ob)
    if rig.animation_data:
        rig.animation_data.action = None
    most = max(len(MOMENTS.get(n, ())) or 6 for n in names)
    people = copy_figure(rig, keep, most)
    posers = [cf_anim.Poser(r, k) for r, _ in people]
    gap = 0.80
    labels = []
    standins = {}
    things = []
    for name in names:
        clip = clips.get(name)
        if clip is None:
            print("[acting preview] no clip", name)
            continue
        times = MOMENTS.get(name) or tuple(round(clip.length * i / 5.0, 2) for i in range(6))
        n = len(times)
        for lb in labels + things:
            bpy.data.objects.remove(lb, do_unlink=True)
        labels = []
        things = []
        for ob in standins.values():
            ob.hide_render = True
        held = dict(clip.meta.get("props", {}) or {})
        held_from = dict(clip.meta.get("props_from", {}) or {})
        held_until = dict(clip.meta.get("props_until", {}) or {})
        splits = [e["t"] for e in clip.meta.get("events", []) if e.get("name") == "split" and e.get("part") == "head"]
        stage = clip.meta.get("stage", {}) or {}
        for i, (r, ms) in enumerate(people):
            show = i < n
            r.location = Vector(((i - (n - 1) / 2.0) * gap, 0.0, 0.0))
            want_prop = "prop_" + str(clip.meta.get("prop", "-"))
            for m in ms:
                nm_ = m.name.split(".")[0]
                m.hide_render = (not show) or (nm_.startswith("prop_") and nm_ != want_prop)
            if not show:
                continue
            t = times[i]
            fc = clip.face(t)
            pose = dict(clip.pose(t))
            pose.update(face_pose(fc, k))
            posers[i].apply(cf_anim._scaled(pose, k))
            if splits and t >= splits[0] - 1e-4:
                r.pose.bones["head"].scale = Vector((0.001, 0.001, 0.001))
            set_face(ms, fc)
            bpy.context.view_layer.update()
            for s_, kind in held.items():
                key = (i, s_, kind)
                if key not in standins:
                    standins[key] = make_prop(kind)
                ob = standins[key]
                if t >= float(held_until.get(s_, 1e9)) and "pot" in stage:
                    from mathutils import Matrix
                    gx, gy, gz = stage["pot"]
                    on = r.matrix_world @ Vector((gx * k, -gz * k, 0.0))
                    ob.matrix_world = Matrix.Translation((on.x, on.y, 0.62)) @ Matrix.Rotation(math.radians(90), 4, 'X')
                    ob.hide_render = False
                elif t >= float(held_from.get(s_, -1.0)):
                    ob.matrix_world = fist_frame(r, s_)
                    ob.hide_render = False
                elif kind == "lid":
                    from mathutils import Matrix
                    side_at = r.matrix_world @ Vector((0.34 * k, -0.30 * k, 0.03))
                    ob.matrix_world = Matrix.Translation(side_at) @ Matrix.Rotation(math.radians(180), 4, 'X') @ Matrix.Translation((0, -0.05, 0))
                    ob.hide_render = False
            if "block_top" in stage and "neck" in stage:
                things.append(stage_thing("block", stage["neck"], r, k, stage["block_top"]))
            if "pot" in stage:
                things.append(stage_thing("pot", stage["pot"], r, k))
            labels.append(label("%.2fs" % t, (r.location.x, -0.2, f.H + 0.16)))
        labels.append(label(name.replace("_", " "), (0.0, -0.2, f.H + 0.42), 0.14))
        bpy.context.view_layer.update()
        width = n * gap
        P.look_at(cam, (0, 0, 0.98 * k), (0.9, -8.0, 1.75))
        cam.data.sensor_fit = 'HORIZONTAL'
        cam.data.sensor_width = 36.0
        cam.data.lens = 36.0 * 8.1 / max(width + 0.5, 3.2)
        P.render(os.path.join(o["out"], "strip_%s.png" % name), 1536, 864)


if __name__ == "__main__":
    main()

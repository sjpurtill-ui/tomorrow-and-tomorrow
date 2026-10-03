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
    for name in names:
        clip = clips.get(name)
        if clip is None:
            print("[acting preview] no clip", name)
            continue
        times = MOMENTS.get(name) or tuple(round(clip.length * i / 5.0, 2) for i in range(6))
        n = len(times)
        for lb in labels:
            bpy.data.objects.remove(lb, do_unlink=True)
        labels = []
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
            set_face(ms, fc)
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

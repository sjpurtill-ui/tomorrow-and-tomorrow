"""Court acting (K): build the clip library every court figure shares.

Run headless with Blender 5.2 (never opens a window):
  blender --background --factory-startup --python tools/blender/court_anims.py -- [options]
Options:
  --variants male_adult,female_adult,...   (default: all six bodies)
  --only gasp,flinch                       write only these clips (for trying things)
  --out assets/court_figures/anims         where the files go

For each body variant it builds that body's armature exactly as J's
court_figures.py does (cf_rig.build_armature on the same cf_body.Frame), so
the rests match the figure's own skeleton, writes every clip in
court_anims_clips onto it (hand contacts solved on that body's own measure)
and exports an armature-only court_anims_<variant>.glb: one Skeleton3D
"Figure" and one animation per clip (body bones only: rotations, and the
hips' travel). The face is not in the .glb: court_anims.json carries each
clip's face channels as curves, with what the game needs to play it
(length, loop/hold, which parts of the body it drives, which hands it needs,
blends, its beat and what it shows). scripts/hud/court_acting.gd plays them.
"""
import os
import sys
import json
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True

import bpy
from mathutils import Vector, Quaternion

import cf_body
import cf_rig
import cf_anim
import court_anims_lib as L
import court_anims_clips as C

FPS = 30
FACE_FPS = 15
FACE_BONES = ("jaw", "eye.L", "eye.R", "brow.L", "brow.R")
VERSION = 1


def args():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    o = {"variants": list(cf_body.VARIANTS.keys()), "only": None, "out": os.path.join(ROOT, "assets", "court_figures", "anims")}
    i = 0
    while i < len(a):
        if a[i] == "--variants":
            o["variants"] = a[i + 1].split(",")
            i += 1
        elif a[i] == "--only":
            o["only"] = a[i + 1].split(",")
            i += 1
        elif a[i] == "--out":
            o["out"] = os.path.abspath(a[i + 1])
            i += 1
        i += 1
    return o


def log(*a):
    print("[court_anims]", *a, flush=True)


def clear_scene():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.armatures, bpy.data.actions, bpy.data.materials):
        for d in list(coll):
            coll.remove(d)


def body_bones(rig):
    return [pb for pb in rig.pose.bones if pb.name not in FACE_BONES and pb.name != "root"]


def stub_mesh(rig):
    """A speck skinned to the armature, so the exporter writes a skin and
    Godot makes a Skeleton3D (bones with no skin import as plain nodes)."""
    me = bpy.data.meshes.new("acting_stub")
    me.from_pydata([(0, 0, 0.0), (0.001, 0, 0.0), (0, 0.001, 0.0)], [], [(0, 1, 2)])
    ob = bpy.data.objects.new("acting_stub", me)
    bpy.context.scene.collection.objects.link(ob)
    g = ob.vertex_groups.new(name="hips")
    g.add([0, 1, 2], 1.0, 'REPLACE')
    ob.parent = rig
    mod = ob.modifiers.new("Armature", 'ARMATURE')
    mod.object = rig
    return ob


def write_clips(rig, f, clips, only=None):
    k = f.H / 1.72
    poser = cf_anim.Poser(rig, k)
    if rig.animation_data is None:
        rig.animation_data_create()
    bones = body_bones(rig)
    made = []
    for name, clip in clips.items():
        if only and name not in only:
            continue
        act = bpy.data.actions.new(name)
        act.use_fake_user = True
        rig.animation_data.action = act
        frames = int(round(clip.length * FPS))
        for fr in range(frames + 1):
            t = fr / FPS
            if clip.meta.get("loop") and fr == frames:
                t = 0.0
            pose = {b: e for b, e in clip.pose(t).items() if b not in FACE_BONES}
            poser.apply(cf_anim._scaled(pose, k))
            for pb in bones:
                pb.keyframe_insert("rotation_quaternion", frame=fr)
                if pb.name == "hips":
                    pb.keyframe_insert("location", frame=fr)
        for fc in cf_anim._fcurves(act):
            for kp in fc.keyframe_points:
                kp.interpolation = 'LINEAR'
        made.append(act)
    rig.animation_data.action = None
    for act in made:
        tr = rig.animation_data.nla_tracks.new()
        tr.name = act.name
        tr.strips.new(act.name, 0, act)
        tr.mute = True
    poser.apply({})
    return made


def export(rig, stub, path):
    for o in bpy.context.selected_objects:
        o.select_set(False)
    rig.select_set(True)
    stub.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.gltf(
        filepath=path, export_format='GLB', use_selection=True, export_apply=False,
        export_yup=True, export_texcoords=False, export_normals=False, export_materials='NONE',
        export_skins=True, export_influence_nb=4, export_def_bones=False,
        export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True,
        export_optimize_animation_size=True, export_reset_pose_bones=True, export_rest_position_armature=True,
        export_morph=False, export_extras=False)


def face_curves(clip):
    n = int(round(clip.length * FACE_FPS))
    rows = [clip.face(min(i / FACE_FPS, clip.length)) for i in range(n + 1)]
    out = {}
    for ch, rest in L.DEFAULT_FACE.items():
        vals = [round(float(r.get(ch, rest)), 3) for r in rows]
        if any(abs(v - rest) > 1e-3 for v in vals):
            out[ch] = vals
    return out


def manifest(clips, variants, out_dir):
    data = {
        "generator": "tools/blender/court_anims.py",
        "version": VERSION,
        "fps": FPS,
        "face_fps": FACE_FPS,
        "face_rest": dict(L.DEFAULT_FACE),
        "files": {v: "court_anims_%s.glb" % v for v in variants},
        "groups": {
            "legs": ["hips", "thigh.L", "thigh.R", "shin.L", "shin.R", "foot.L", "foot.R", "toe.L", "toe.R"],
            "torso": ["spine", "chest"],
            "head": ["neck", "head"],
            "arm_L": [b + ".L" for b in cf_anim.ARM_BONES],
            "arm_R": [b + ".R" for b in cf_anim.ARM_BONES],
        },
        "clips": {},
    }
    for name, clip in clips.items():
        meta = {k: v for k, v in clip.meta.items()}
        meta["length"] = round(clip.length, 3)
        meta["face"] = face_curves(clip)
        data["clips"][name] = meta
    path = os.path.join(out_dir, "court_anims.json")
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=1, sort_keys=True)
    log("wrote", path)


def main():
    o = args()
    os.makedirs(o["out"], exist_ok=True)
    clips = None
    for v in o["variants"]:
        t0 = time.time()
        clear_scene()
        f = cf_body.Frame(cf_body.params(v))
        L.set_frame(f)
        clips = C.all_clips()
        rig = cf_rig.build_armature(f, None, name="Figure")
        rig["variant"] = v
        stub = stub_mesh(rig)
        made = write_clips(rig, f, clips, o["only"])
        path = os.path.join(o["out"], "court_anims_%s.glb" % v)
        export(rig, stub, path)
        log(v, len(made), "clips", round(os.path.getsize(path) / 1024), "KB", round(time.time() - t0, 1), "s")
    # face curves and meta do not depend on the body (written on the last one)
    if clips is not None and not o["only"]:
        manifest(clips, list(cf_body.VARIANTS.keys()), o["out"])
    log("done")


if __name__ == "__main__":
    main()

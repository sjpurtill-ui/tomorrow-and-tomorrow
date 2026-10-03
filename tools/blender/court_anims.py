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
import math
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True

import bpy
import numpy as np
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
    o = {"variants": list(cf_body.VARIANTS.keys()), "only": None, "out": os.path.join(ROOT, "assets", "court_figures", "anims"), "no_manifest": False}
    i = 0
    while i < len(a):
        if a[i] == "--variants":
            o["variants"] = a[i + 1].split(",")
            i += 1
        elif a[i] == "--only":
            o["only"] = a[i + 1].split(",")
            i += 1
        elif a[i] == "--no-manifest":
            o["no_manifest"] = True
            i -= 1
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
    # keys are written a frame each 1/30 s: the exporter turns frames into
    # seconds by the scene's rate, which must be 30 too (Blender's default is 24,
    # which would play every clip 1.25 times slower in the game)
    bpy.context.scene.render.fps = FPS
    bpy.context.scene.render.fps_base = 1.0
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
        rots = {pb.name: [] for pb in bones}
        locs = []
        for fr in range(frames + 1):
            t = fr / FPS
            if clip.meta.get("loop") and fr == frames:
                t = 0.0
            pose = {b: e for b, e in clip.pose(t).items() if b not in FACE_BONES}
            poser.apply(cf_anim._scaled(pose, k))
            for pb in bones:
                q = pb.rotation_quaternion.copy()
                prev = rots[pb.name][-1] if rots[pb.name] else None
                if prev is not None and prev.dot(q) < 0.0:
                    q.negate()
                rots[pb.name].append(q)
            locs.append(rig.pose.bones["hips"].location.copy())
        # each bone keeps only the keys it needs: a frame goes when the slerp of
        # its neighbours is within a fraction of a degree of it (fingers and
        # slow bones need few; a snap keeps every frame it moves in)
        for pb in bones:
            tol = TOL_FINGER if pb.name.split(".")[0] in ("fingers", "index", "thumb", "toe") else TOL_BODY
            keep = _simplify_rot(rots[pb.name], tol)
            for fr in keep:
                pb.rotation_quaternion = rots[pb.name][fr]
                pb.keyframe_insert("rotation_quaternion", frame=fr)
        hips = rig.pose.bones["hips"]
        for fr in _simplify_loc(locs, TOL_LOC * k):
            hips.location = locs[fr]
            hips.keyframe_insert("location", frame=fr)
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


# Clips whose right-hand twin the file leaves out: the game makes each from
# its left one in a mirror at load (court_acting.gd mirrored()). Only twins
# that are true mirrors (a whisper to the left, to the right); the manifest
# still lists the twin, with its own face, and "mirror_of".
# (not the faint and the catch: those two bodies meet where the clips put them,
# and each was built against the other's own side)
MIRRORED = ("point", "cover_eyes", "whisper", "hide_behind", "peek_out", "side_eye",
            "elbow", "bolt", "keep_apart", "make_room", "grab", "shoo", "tug_sleeve",
            "child_hide_behind", "child_peek_out", "child_cling")


def mark_mirrors(clips):
    for stem in MIRRORED:
        if stem + "_l" in clips and stem + "_r" in clips:
            clips[stem + "_r"].meta["mirror_of"] = stem + "_l"


TOL_BODY = 0.35     # degrees a bone may differ from the slerp between its kept keys
TOL_FINGER = 1.5
TOL_LOC = 0.0015    # metres (the hips' travel), for a 1.72 m body


def _rdp(err, n, tol):
    """Ramer-Douglas-Peucker over frames 0..n-1: err(a, b) gives the error of
    each frame strictly between a and b (an array) when a and b are kept."""
    if n <= 2:
        return list(range(n))
    keep = {0, n - 1}
    stack = [(0, n - 1)]
    while stack:
        a, b = stack.pop()
        if b - a < 2:
            continue
        e = err(a, b)
        i = int(np.argmax(e))
        if e[i] > tol:
            at = a + 1 + i
            keep.add(at)
            stack.append((a, at))
            stack.append((at, b))
    return sorted(keep)


def _simplify_rot(qs, tol_deg):
    """The frames to key so that slerping between them stays within tol_deg of
    every frame (Ramer-Douglas-Peucker on the rotation's path)."""
    Q = np.array([(q.w, q.x, q.y, q.z) for q in qs], dtype=np.float64)

    def err(a, b):
        qa, qb = Q[a], Q[b]
        u = (np.arange(a + 1, b) - a) / float(b - a)
        d = float(np.clip(np.dot(qa, qb), -1.0, 1.0))
        th = math.acos(abs(d))
        if th < 1e-6:
            q = qa[None, :] * (1 - u)[:, None] + qb[None, :] * u[:, None]
        else:
            sb = qb if d >= 0 else -qb
            q = (np.sin((1 - u) * th)[:, None] * qa[None, :] + np.sin(u * th)[:, None] * sb[None, :]) / math.sin(th)
        q /= np.linalg.norm(q, axis=1)[:, None]
        dots = np.clip(np.abs(np.sum(q * Q[a + 1:b], axis=1)), 0.0, 1.0)
        return 2.0 * np.arccos(dots)
    return _rdp(err, len(qs), math.radians(tol_deg))


def _simplify_loc(ps, tol):
    P = np.array([tuple(p) for p in ps], dtype=np.float64)

    def err(a, b):
        u = (np.arange(a + 1, b) - a) / float(b - a)
        line = P[a][None, :] * (1 - u)[:, None] + P[b][None, :] * u[:, None]
        return np.linalg.norm(line - P[a + 1:b], axis=1)
    return _rdp(err, len(ps), tol)


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
        export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=False,
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
    every = {}
    for v in o["variants"]:
        t0 = time.time()
        clear_scene()
        f = cf_body.Frame(cf_body.params(v))
        L.set_frame(f)
        clips = C.all_clips()
        rig = cf_rig.build_armature(f, None, name="Figure")
        rig["variant"] = v
        stub = stub_mesh(rig)
        clips = {n: c for n, c in clips.items() if v in c.meta.get("bodies", [v])}
        mark_mirrors(clips)
        for n, c in clips.items():
            every.setdefault(n, c)
        made = write_clips(rig, f, {n: c for n, c in clips.items() if not c.meta.get("mirror_of")}, o["only"])
        path = os.path.join(o["out"], "court_anims_%s.glb" % v)
        export(rig, stub, path)
        log(v, len(made), "clips", round(os.path.getsize(path) / 1024), "KB", round(time.time() - t0, 1), "s")
    # face curves and meta do not depend on the body (written on the last one;
    # --no-manifest when building one body at a time)
    if every and not o["only"] and not o["no_manifest"]:
        manifest(every, list(cf_body.VARIANTS.keys()), o["out"])
    log("done")


if __name__ == "__main__":
    main()

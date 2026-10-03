"""Preview renders of the exported court figures (Eevee, toon light, ink line).

  blender --background --factory-startup --python tools/blender/court_figures_preview.py -- \
      --figures assets/court_figures --out reports/court_figures

Imports the .glb files (so the export itself is what is seen), dresses a
lineup of people of different peoples and ages, and writes:
  preview_lineup.png       eight people side by side, at rest
  preview_lineup_back.png  the same from behind and to one side
  preview_talk.png         one speaker through a talk clip, four moments
  preview_bow.png          a bow and a kneel, four moments each
  preview_faces.png        heads close up
Colours come from the same palettes the game's appearance profiles use
(scripts/people_appearance.gd: skin ramp, hair colours, dyes).
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

SKIN_RAMP = [(0.0, "f3dccb"), (0.15, "e8c3a5"), (0.30, "d6a37c"), (0.45, "bd8659"), (0.60, "9f6a43"),
             (0.75, "7d4e2f"), (0.90, "5b3622"), (1.0, "3f2519")]
INK = "2a2217"
# the vertex-colour layer as Blender's glTF importer names it
COLOR_LAYER = "Color"
HIDE = ("9c7a52", "6e5541")

# variant, outfit, hair, beard, skin depth, hair colour, dyes (A, B, C), extra pieces to hide
LINEUP = [
    ("male_adult", "hide", "hair_long", "beard_full", 0.85, "1b1511", ("a8782a", "6e5541", "a8432f"), ()),
    ("female_adult", "hide", "hair_braids", None, 0.30, "4a2a1a", ("b07a35", "6e5541", "8e2f3a"), ("hide_cape",)),
    ("male_old", "tunic", "hair_cropped", "beard_long", 0.52, "a8a49c", ("5a7894", "5b4130", "c9a43c"), ()),
    ("female_young", "tunic", "hair_curls", None, 0.95, "0f0d0c", ("a8432f", "5b4130", "d9ccb0"), ()),
    ("male_young", "tunic", "hair_tail", None, 0.10, "0e1016", ("4f7a68", "5b4130", "d08a2b"), ()),
    ("female_old", "robe", "hair_bun", None, 0.66, "b5b0a6", ("6d4b6b", "2f4a6e", "c9a43c"), ()),
    ("male_adult", "robe", "hair_topknot", "beard_short", 0.46, "6b5a48", ("2f4a6e", "8e2f3a", "c9a43c"), ()),
    ("female_adult", "robe", "hair_long_framed", None, 0.40, "8a6a48", ("d9ccb0", "4f7a68", "a8432f"), ()),
]


def args():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    o = {"figures": os.path.join(ROOT, "assets", "court_figures"), "out": os.path.join(ROOT, "reports", "court_figures")}
    a = [x for x in a if x != "--faces16"]
    for i in range(0, len(a) - 1, 2):
        key = a[i].lstrip("-").replace("-", "_")
        o[key] = a[i + 1] if key == "force_variant" else os.path.abspath(a[i + 1])
    return o


def srgb(h):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)


def skin_at(d):
    for i in range(1, len(SKIN_RAMP)):
        a, b = SKIN_RAMP[i - 1], SKIN_RAMP[i]
        if d <= b[0]:
            t = (d - a[0]) / max(b[0] - a[0], 1e-6)
            ca, cb = srgb(a[1]), srgb(b[1])
            return tuple(ca[j] * (1 - t) + cb[j] * t for j in range(3))
    return srgb(SKIN_RAMP[-1][1])


# --- toon material ---------------------------------------------------------------

def toon(name, color, shade=(0.50, 0.40, 0.40), ao=True, flat=False, rim=0.18):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    emit = nt.nodes.new("ShaderNodeEmission")
    nt.links.new(emit.outputs[0], out.inputs[0])
    base = nt.nodes.new("ShaderNodeRGB")
    base.outputs[0].default_value = (*color, 1)
    col = base.outputs[0]
    if ao:
        attr = nt.nodes.new("ShaderNodeVertexColor")
        attr.layer_name = COLOR_LAYER
        sep = nt.nodes.new("ShaderNodeSeparateColor")
        nt.links.new(attr.outputs["Color"], sep.inputs[0])
        mul = nt.nodes.new("ShaderNodeMix")
        mul.data_type = 'RGBA'
        mul.blend_type = 'MULTIPLY'
        mul.inputs["Factor"].default_value = 1.0
        nt.links.new(col, mul.inputs[6])
        gray = nt.nodes.new("ShaderNodeCombineColor")
        for i in range(3):
            nt.links.new(sep.outputs[0], gray.inputs[i])
        nt.links.new(gray.outputs[0], mul.inputs[7])
        col = mul.outputs[2]
    if flat:
        nt.links.new(col, emit.inputs["Color"])
        return m
    dif = nt.nodes.new("ShaderNodeBsdfDiffuse")
    s2r = nt.nodes.new("ShaderNodeShaderToRGB")
    nt.links.new(dif.outputs[0], s2r.inputs[0])
    bw = nt.nodes.new("ShaderNodeRGBToBW")
    nt.links.new(s2r.outputs[0], bw.inputs[0])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = 'EASE'
    e = ramp.color_ramp.elements
    e[0].position, e[0].color = 0.10, (0, 0, 0, 1)
    e[1].position, e[1].color = 0.24, (1, 1, 1, 1)
    mid = e.new(0.16)
    mid.color = (0.42, 0.42, 0.42, 1)
    nt.links.new(bw.outputs[0], ramp.inputs[0])
    shadow = nt.nodes.new("ShaderNodeMix")
    shadow.data_type = 'RGBA'
    shadow.blend_type = 'MULTIPLY'
    shadow.inputs["Factor"].default_value = 1.0
    nt.links.new(col, shadow.inputs[6])
    shadow.inputs[7].default_value = (*shade, 1)
    lit = nt.nodes.new("ShaderNodeMix")
    lit.data_type = 'RGBA'
    nt.links.new(ramp.outputs[0], lit.inputs["Factor"])
    nt.links.new(shadow.outputs[2], lit.inputs[6])
    nt.links.new(col, lit.inputs[7])
    # a warm rim where the form turns away
    lw = nt.nodes.new("ShaderNodeLayerWeight")
    lw.inputs[0].default_value = 0.35
    rr = nt.nodes.new("ShaderNodeValToRGB")
    rr.color_ramp.elements[0].position = 0.55
    rr.color_ramp.elements[1].position = 0.75
    nt.links.new(lw.outputs["Facing"], rr.inputs[0])
    rimmix = nt.nodes.new("ShaderNodeMix")
    rimmix.data_type = 'RGBA'
    rimmix.blend_type = 'SCREEN'
    nt.links.new(rr.outputs[0], rimmix.inputs["Factor"])
    rimmix.inputs["Factor"].default_value = 0.0
    fac = nt.nodes.new("ShaderNodeMath")
    fac.operation = 'MULTIPLY'
    nt.links.new(rr.outputs[0], fac.inputs[0])
    fac.inputs[1].default_value = rim
    nt.links.new(fac.outputs[0], rimmix.inputs["Factor"])
    nt.links.new(lit.outputs[2], rimmix.inputs[6])
    rimmix.inputs[7].default_value = (1.0, 0.86, 0.62, 1)
    nt.links.new(rimmix.outputs[2], emit.inputs["Color"])
    return m


def ink_material():
    m = bpy.data.materials.get("INK_LINE")
    if m:
        return m
    m = bpy.data.materials.new("INK_LINE")
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    emit = nt.nodes.new("ShaderNodeEmission")
    emit.inputs["Color"].default_value = (*srgb(INK), 1)
    nt.links.new(emit.outputs[0], out.inputs[0])
    m.use_backface_culling = True
    return m


def outline(obj, width=0.0038):
    if obj.name.split(".")[0] in ("Eyes", "Brows", "Mouth", "hair_shaved", "beard_stubble"):
        return
    obj.data.materials.append(ink_material())
    mod = obj.modifiers.new("ink", 'SOLIDIFY')
    mod.thickness = width
    mod.offset = 1.0
    mod.use_flip_normals = True
    mod.use_rim = False
    mod.material_offset = len(obj.data.materials) - 1
    mod.material_offset_rim = len(obj.data.materials) - 1


# --- figures --------------------------------------------------------------------

def import_figure(path):
    before_obj = set(bpy.data.objects)
    before_act = set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=path)
    objs = [o for o in bpy.data.objects if o not in before_obj]
    acts = {a.name.split(".")[0].split("|")[-1]: a for a in bpy.data.actions if a not in before_act}
    rig = next(o for o in objs if o.type == 'ARMATURE')
    return rig, objs, acts


def dress(rig, objs, spec, idx):
    variant, kind, hair, beard, depth, hair_col, dyes, hide_extra = spec
    skin = skin_at(depth)
    old = variant.endswith("_old")
    cols = {
        "SKIN": skin, "HAIR": srgb(hair_col), "EYES": srgb("22170f"), "EYE_SHINE": srgb("fbf6ea"), "EYE_WHITE": srgb("e9dfca"),
        "MOUTH": tuple(c * 0.45 for c in skin_at(min(1.0, depth + 0.25))),
        "LEATHER": srgb("5b3b24"), "WOOD": srgb("6b4a2e"), "CLAY": srgb("a0603a"),
        "STUBBLE": tuple(0.55 * a + 0.45 * b for a, b in zip(skin, srgb(hair_col))),
    }
    if kind == "hide":
        cols.update({"CLOTH_A": srgb(HIDE[0]), "CLOTH_B": srgb(HIDE[1]), "CLOTH_C": srgb(dyes[2])})
        cols["CLOTH_A"] = tuple(0.7 * a + 0.3 * b for a, b in zip(srgb(HIDE[0]), srgb(dyes[0])))
    else:
        cols.update({"CLOTH_A": srgb(dyes[0]), "CLOTH_B": srgb(dyes[1]), "CLOTH_C": srgb(dyes[2])})
    mats = {}
    for slot, c in cols.items():
        flat = slot in ("EYES", "EYE_SHINE", "EYE_WHITE", "MOUTH")
        shade = (0.62, 0.48, 0.44) if slot == "SKIN" else (0.48, 0.40, 0.40)
        mats[slot] = toon("%s_%d" % (slot, idx), c, shade=shade, ao=not flat, flat=flat)
    keep_prefix = {"Body", "Eyes", "Brows", "Mouth", hair, beard} | set(spec[8] if len(spec) > 8 else ())
    for o in objs:
        if o.type != 'MESH':
            continue
        base = o.name.split(".")[0]
        show = base in keep_prefix or (base.startswith(kind + "_") and base not in hide_extra)
        o.hide_render = not show
        o.hide_viewport = not show
        if not show:
            continue
        for i, slot in enumerate(o.material_slots):
            nm = slot.material.name.split(".")[0] if slot.material else ""
            if nm in mats:
                o.material_slots[i].material = mats[nm]
        if base == "Body":
            _skin_mask(o, kind, mats["SKIN"])
        outline(o)


def _skin_mask(body, kind, mat):
    """Hide skin the worn outfit covers (as the game's shader does)."""
    channel = {"hide": "Green", "tunic": "Blue", "robe": "Alpha"}[kind]
    nt = mat.node_tree
    attr = nt.nodes.new("ShaderNodeVertexColor")
    attr.layer_name = COLOR_LAYER
    out = next(n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL')
    surf = out.inputs[0].links[0].from_socket
    mix = nt.nodes.new("ShaderNodeMixShader")
    tr = nt.nodes.new("ShaderNodeBsdfTransparent")
    if channel == "Alpha":
        val = attr.outputs["Alpha"]
    else:
        sep = nt.nodes.new("ShaderNodeSeparateColor")
        nt.links.new(attr.outputs["Color"], sep.inputs[0])
        val = sep.outputs[channel]
    gt = nt.nodes.new("ShaderNodeMath")
    gt.operation = 'GREATER_THAN'
    gt.inputs[1].default_value = 0.5
    nt.links.new(val, gt.inputs[0])
    nt.links.new(gt.outputs[0], mix.inputs[0])
    nt.links.new(surf, mix.inputs[1])
    nt.links.new(tr.outputs[0], mix.inputs[2])
    nt.links.new(mix.outputs[0], out.inputs[0])
    mat.surface_render_method = 'DITHERED'


def pose(rig, acts, clip, t):
    a = acts.get(clip)
    if a is None:
        return
    if rig.animation_data is None:
        rig.animation_data_create()
    rig.animation_data.action = a
    try:
        if a.slots:
            rig.animation_data.action_slot = a.slots[0]
    except AttributeError:
        pass
    bpy.context.scene.frame_set(int(round(t * 30)))


# --- stage -------------------------------------------------------------------

def stage():
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_EEVEE'
    sc.render.film_transparent = False
    sc.view_settings.view_transform = 'Standard'
    sc.view_settings.look = 'None'
    world = sc.world or bpy.data.worlds.new("World")
    sc.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    bg.inputs[0].default_value = (*srgb("e9dcc2"), 1)
    bg.inputs[1].default_value = 1.0
    # a paper ground the figures stand on
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
    ground = bpy.context.object
    gm = toon("ground", srgb("d8c7a6"), shade=(0.82, 0.76, 0.70), ao=False)
    ground.data.materials.append(gm)
    # firelight key from the front, cool sky from above-behind, a warm kicker
    key = bpy.data.lights.new("key", 'SUN')
    key.energy = 3.0
    key.angle = math.radians(8)
    ko = bpy.data.objects.new("key", key)
    sc.collection.objects.link(ko)
    ko.rotation_euler = Euler((math.radians(58), 0, math.radians(-32)))
    fill = bpy.data.lights.new("fill", 'SUN')
    fill.energy = 0.6
    fo = bpy.data.objects.new("fill", fill)
    sc.collection.objects.link(fo)
    fo.rotation_euler = Euler((math.radians(-50), 0, math.radians(150)))
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    sc.collection.objects.link(cam)
    sc.camera = cam
    cam.data.lens = 50
    try:
        sc.eevee.use_shadows = True
    except AttributeError:
        pass
    return cam


def look_at(cam, target, frm):
    cam.location = Vector(frm)
    d = Vector(target) - Vector(frm)
    cam.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()


def render(path, w, h):
    sc = bpy.context.scene
    sc.render.resolution_x = w
    sc.render.resolution_y = h
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("[preview] wrote", path, flush=True)


def main():
    o = args()
    os.makedirs(o["out"], exist_ok=True)
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    cam = stage()
    people = []
    gap = 0.78
    for i, spec in enumerate(LINEUP):
        variant = o.get("force_variant") or spec[0]
        path = os.path.join(o["figures"], "court_figure_%s.glb" % variant)
        rig, objs, acts = import_figure(path)
        dress(rig, objs, spec, i)
        rig.location.x = (i - (len(LINEUP) - 1) / 2) * gap
        people.append((rig, objs, acts, spec))
    # at rest, each a little different
    rests = ["idle", "idle_clasped", "idle", "listen_r", "idle", "idle_clasped", "idle", "listen_l"]
    for (rig, objs, acts, spec), clip in zip(people, rests):
        pose(rig, acts, clip, 1.3)
    width = len(LINEUP) * gap
    look_at(cam, (0, 0, 0.92), (0, -9.6, 1.55))
    cam.data.lens = 50 * 9.6 / (width * 1.6)
    render(os.path.join(o["out"], "preview_lineup.png"), 2400, 900)
    look_at(cam, (0, 0, 0.92), (5.2, 8.0, 1.8))
    render(os.path.join(o["out"], "preview_lineup_back.png"), 2400, 900)
    _faces(people, cam, o["out"])
    for p in people:
        _show(p, False)
    _moments(people[6], cam, "talk", (0.2, 1.0, 1.8, 2.9), os.path.join(o["out"], "preview_talk.png"))
    _moments(people[1], cam, "bow", (0.0, 0.6, 1.2, 2.2), os.path.join(o["out"], "preview_bow.png"),
             second=(people[2], "kneel", (0.0, 0.5, 0.9, 2.4)))
    for p in people:
        _show(p, True)


def _show(person, on):
    rig, objs, acts, spec = person
    variant, kind, hair, beard, *_ = spec
    hide_extra = spec[7]
    for ob in objs:
        if ob.type != 'MESH':
            continue
        base = ob.name.split(".")[0]
        show = base in ("Body", "Eyes", "Brows", "Mouth", hair, beard) or (base.startswith(kind + "_") and base not in hide_extra)
        ob.hide_render = not (on and show)


def _faces(people, cam, out):
    import numpy as np
    shots = []
    for idx in range(len(people)):
        for j, p in enumerate(people):
            _show(p, j == idx)
        rig = people[idx][0]
        top = float(rig.get("head_top", 1.6))
        x = rig.location.x
        look_at(cam, (x, 0, top - 0.15), (x + 0.55, -1.35, top - 0.05))
        cam.data.lens = 85
        path = os.path.join(out, "_face_%d.png" % idx)
        render(path, 520, 600)
        shots.append(path)
    for p in people:
        _show(p, True)
    _sheet(shots, os.path.join(out, "preview_faces.png"), cols=4)


def _moments(person, cam, clip, times, path, second=None):
    shots = []
    seqs = [(person, clip, times)] + ([second] if second else [])
    for p, c, ts in seqs:
        for q in (person,) + ((second[0],) if second else ()):
            _show(q, False)
        _show(p, True)
        rig = p[0]
        x = rig.location.x
        for t in ts:
            pose(rig, p[2], c, t)
            look_at(cam, (x, 0, 0.88), (x + 1.9, -4.6, 1.35))
            cam.data.lens = 50
            fp = path.replace(".png", "_%s_%d.png" % (c, int(t * 100)))
            render(fp, 600, 900)
            shots.append(fp)
        _show(p, False)
    _sheet(shots, path, cols=4)


def _sheet(paths, out, cols=4):
    imgs = [bpy.data.images.load(p) for p in paths]
    w, h = imgs[0].size
    rows = (len(imgs) + cols - 1) // cols
    sheet = bpy.data.images.new("sheet", w * cols, h * rows, alpha=False)
    import numpy as np
    buf = np.zeros((h * rows, w * cols, 4), dtype=np.float32)
    for i, im in enumerate(imgs):
        px = np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4)
        r, c = i // cols, i % cols
        buf[(rows - 1 - r) * h:(rows - r) * h, c * w:(c + 1) * w] = px
    sheet.pixels = buf.ravel()
    sheet.filepath_raw = out
    sheet.file_format = 'PNG'
    sheet.save()
    for p in paths:
        try:
            os.remove(p)
        except OSError:
            pass
    print("[preview] wrote", out, flush=True)


# --- Sixteen faces from three peoples ---------------------------------------------

# A people's family face (the game makes these from each people's appearance
# profile); each person then differs within it.
PEOPLES = {
    "kilnfold": {"depth": (0.80, 0.92), "hair": ("1b1511", "2b2018"), "coiled": True,
                 "face": {"nose_wide": 0.6, "lips": 0.6, "jaw": 0.15, "cheek": 0.35, "brow": 0.2}},
    "thornbank": {"depth": (0.04, 0.14), "hair": ("0e1016", "1a1c24"), "coiled": False,
                  "face": {"nose": 0.2, "bridge": 0.55, "long": 0.35, "cheek": -0.25, "lips": -0.35, "nose_wide": -0.4}},
    "ochrestep": {"depth": (0.58, 0.72), "hair": ("c2a878", "a88d5e"), "coiled": False,
                  "face": {"cheek": 0.7, "nose": 0.3, "round": -0.15, "brow": 0.35, "jaw": 0.25, "lips": 0.1}},
}

SIXTEEN = [
    # people, variant, hair, beard, outfit, mood
    ("kilnfold", "male_adult", "hair_curls", None, "hide", "mood_smile"),
    ("kilnfold", "male_old", "hair_shaved", "beard_short", "tunic", None),
    ("kilnfold", "male_young", "hair_cropped", None, "tunic", None),
    ("thornbank", "male_adult", "hair_tail", "beard_moustache", "tunic", None),
    ("thornbank", "male_old", "hair_long", "beard_long", "robe", "mood_worry"),
    ("thornbank", "male_young", "hair_topknot", "beard_stubble", "hide", "mood_smile"),
    ("ochrestep", "male_adult", "hair_cropped", "beard_chin", "robe", "mood_stern"),
    ("ochrestep", "male_adult", "hair_long", "beard_stubble", "hide", None),
    ("kilnfold", "female_adult", "hair_braids", None, "tunic", "mood_smile"),
    ("kilnfold", "female_old", "hair_bun", None, "robe", None),
    ("kilnfold", "female_young", "hair_curls", None, "hide", None),
    ("thornbank", "female_adult", "hair_long_framed", None, "robe", None),
    ("thornbank", "female_young", "hair_braids", None, "tunic", "mood_smile"),
    ("ochrestep", "female_adult", "hair_bun", None, "tunic", "mood_worry"),
    ("ochrestep", "female_old", "hair_long", None, "hide", None),
    ("ochrestep", "female_young", "hair_tail", None, "robe", "mood_smile"),
]


def _person_face(people, idx):
    import random
    rnd = random.Random(idx * 7919 + 13)
    face = dict(PEOPLES[people]["face"])
    for name in ("jaw", "chin", "cheek", "nose", "bridge", "nose_wide", "brow", "lips", "ears", "long", "round"):
        face[name] = max(-1.0, min(1.0, face.get(name, 0.0) + rnd.uniform(-0.55, 0.55)))
    return face


def faces16(figures, out):
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    cam = stage()
    shots = []
    for idx, (people, variant, hair, beard, outfit, mood) in enumerate(SIXTEEN):
        import random
        rnd = random.Random(idx)
        look = PEOPLES[people]
        depth = rnd.uniform(*look["depth"])
        hair_col = rnd.choice(look["hair"])
        if variant.endswith("_old"):
            hair_col = "b8b2a6"
        dyes = (("a8432f", "5b4130", "c9a43c"), ("2f4a6e", "8e2f3a", "d9ccb0"), ("4f7a68", "6d4b6b", "d08a2b"))[idx % 3]
        path = os.path.join(figures, "court_figure_%s.glb" % variant)
        if not os.path.exists(path):
            path = os.path.join(figures, "court_figure_male_adult.glb")
        rig, objs, acts = import_figure(path)
        dress(rig, objs, (variant, outfit, hair, beard, depth, hair_col, dyes, ("hide_cape",)), 100 + idx)
        face = _person_face(people, idx)
        for o in objs:
            keys = o.data.shape_keys if o.type == 'MESH' else None
            if keys is None:
                continue
            for kb in keys.key_blocks:
                n = kb.name
                if n.startswith("face_"):
                    kb.slider_min = -1.0
                    kb.value = face.get(n[5:], 0.0)
                elif n == mood:
                    kb.value = 0.8
        stance = ("stand", "folded", "clasped", "hip", "belt")[idx % 5]
        pose(rig, acts, stance, 1.0)
        top = 1.62 if not variant.endswith(("_young", "_old")) else 1.52
        rig.location = (0, 0, 0)
        look_at(cam, (0.0, 0.0, top - 0.06), (0.42, -1.25, top + 0.02))
        cam.data.lens = 85
        path = os.path.join(out, "_f16_%d.png" % idx)
        render(path, 360, 420)
        shots.append(path)
        for ob in objs:
            bpy.data.objects.remove(ob, do_unlink=True)
    _sheet(shots, os.path.join(out, "preview_faces16.png"), cols=8)


if __name__ == "__main__":
    if "--faces16" in sys.argv:
        o = args()
        faces16(o["figures"], o["out"])
    else:
        main()

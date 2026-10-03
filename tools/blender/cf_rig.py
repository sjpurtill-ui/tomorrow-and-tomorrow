"""Court figures: the armature and how each mesh is bound to it.

Bones (glTF/Godot names): root, hips, spine, chest, neck, head, jaw,
eye.L/R, brow.L/R, shoulder.L/R, upper_arm.L/R, forearm.L/R, hand.L/R,
thumb.L/R, index.L/R, fingers.L/R, thigh.L/R, shin.L/R, foot.L/R, toe.L/R.

The body is bound by Blender's bone heat; face parts follow one bone each;
clothes and hair copy the body's weights from the nearest skin, then are
eased so a skirt moves with the hips more than with either leg.
"""
import math
import bpy
from mathutils import Vector

FACE_BONES = ("jaw", "eye.L", "eye.R", "brow.L", "brow.R")


def _mode(obj, mode):
    for o in bpy.context.selected_objects:
        o.select_set(False)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    if obj.mode != mode:
        bpy.ops.object.mode_set(mode=mode)


def build_armature(f, face=None, name="Figure"):
    arm = bpy.data.armatures.new(name)
    obj = bpy.data.objects.new(name, arm)
    bpy.context.scene.collection.objects.link(obj)
    obj.show_in_front = True
    _mode(obj, 'EDIT')
    eb = arm.edit_bones
    k = f.H / 1.72

    def bone(n, head, tail, parent=None, deform=True, roll=0.0, connect=False):
        b = eb.new(n)
        b.head = Vector(head)
        b.tail = Vector(tail)
        b.roll = roll
        b.use_deform = deform
        if parent:
            b.parent = eb[parent]
            b.use_connect = connect
        return b

    bone("root", (0, 0, 0), (0, 0.0, 0.12 * k), deform=False)
    bone("hips", f.pelvis, f.waist, "root")
    bone("spine", f.waist, f.chest, "hips", connect=True)
    bone("chest", f.chest, f.neck, "spine", connect=True)
    bone("neck", f.neck, f.head_base, "chest", connect=True)
    bone("head", f.head_base, Vector((f.head_base.x, f.head_base.y, f.z_top)), "neck", connect=True)
    s = f.head_h / 0.282
    mc = getattr(f, "mouth_center", Vector((0, -0.10 * s, f.face(0.2))))
    bone("jaw", mc + Vector((0, 0.020 * s, 0)), mc + Vector((0, -0.010 * s, 0)), "head")
    for side, sd in (("L", 1.0), ("R", -1.0)):
        ec = f.head_point(sd * 0.034 * s, -0.090 * s, 0.470)
        if face and face.get("eye_center"):
            ec = face["eye_center"][side]
        bone("eye." + side, ec + Vector((0, 0.010 * s, 0)), ec + Vector((0, -0.010 * s, 0)), "head")
        bc = f.head_point(sd * 0.036 * s, -0.086 * s, 0.575)
        if face and face.get("brow_center"):
            bc = face["brow_center"][side]
        bone("brow." + side, bc + Vector((0, 0.012 * s, 0)), bc + Vector((0, -0.008 * s, 0)), "head")
        bone("shoulder." + side, f.clavicle[side], f.shoulder[side], "chest")
        bone("upper_arm." + side, f.shoulder[side], f.elbow[side], "shoulder." + side, connect=True)
        bone("forearm." + side, f.elbow[side], f.wrist[side], "upper_arm." + side, connect=True)
        along, front, out = f.hand_frame(side)
        L = f.hand_len
        palm_end = f.wrist[side] + along * (L * 0.56)
        bone("hand." + side, f.wrist[side], palm_end, "forearm." + side, connect=True)
        hs = f.p["hand"] * k
        ib = palm_end + front * (0.025 * hs)
        bone("index." + side, ib, ib + along * (0.064 * hs) - out * (0.010 * hs), "hand." + side)
        fb = palm_end + front * (-0.006 * hs)
        bone("fingers." + side, fb, fb + along * (0.068 * hs) - out * (0.010 * hs), "hand." + side)
        tb = f.wrist[side] + along * (L * 0.20) + front * (0.028 * hs) - out * (0.006 * hs)
        bone("thumb." + side, tb, tb + along * (0.040 * hs) + front * (0.020 * hs) - out * (0.016 * hs), "hand." + side)
        bone("thigh." + side, f.hip[side], f.knee[side], "hips")
        bone("shin." + side, f.knee[side], f.ankle[side], "thigh." + side, connect=True)
        bone("foot." + side, f.ankle[side], f.ball[side] + Vector((0, 0, 0.01)), "shin." + side, connect=True)
        bone("toe." + side, f.ball[side] + Vector((0, 0, 0.01)), f.toe[side] + Vector((0, 0, 0.01)), "foot." + side, connect=True)
    # Rolls: every bone's local Z faces the figure's front where it can, so
    # look-at and bend axes read the same way on every bone.
    for b in eb:
        if b.name in ("root",):
            continue
        try:
            b.align_roll(Vector((0, -1, 0)) if abs(b.vector.normalized().y) < 0.9 else Vector((0, 0, 1)))
        except Exception:
            pass
    _mode(obj, 'OBJECT')
    obj.data.display_type = 'STICK'
    return obj


def bind_body(body, rig):
    """Bone heat for the body; face bones are kept out of it."""
    for b in rig.data.bones:
        if b.name in FACE_BONES:
            b.use_deform = False
    for o in bpy.context.selected_objects:
        o.select_set(False)
    body.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.parent_set(type='ARMATURE_AUTO')
    for b in rig.data.bones:
        if b.name in FACE_BONES:
            b.use_deform = True
    missing = [b.name for b in rig.data.bones if b.use_deform and b.name not in FACE_BONES
               and body.vertex_groups.get(b.name) is None]
    return missing


def bind_rigid(obj, rig, bone_name):
    """A part that follows one bone entirely (eyes, brows, mouth)."""
    obj.vertex_groups.clear()
    g = obj.vertex_groups.new(name=bone_name)
    g.add(list(range(len(obj.data.vertices))), 1.0, 'REPLACE')
    _armature_parent(obj, rig)


def _armature_parent(obj, rig):
    obj.parent = rig
    obj.matrix_parent_inverse = rig.matrix_world.inverted()
    for m in list(obj.modifiers):
        if m.type == 'ARMATURE':
            obj.modifiers.remove(m)
    mod = obj.modifiers.new("Armature", 'ARMATURE')
    mod.object = rig


def bind_from_body(obj, body, rig, ease=None):
    """Copy weights from the nearest skin; ease(v_co) may return (bone, amount)
    pairs to blend toward, e.g. a skirt toward the hips."""
    obj.vertex_groups.clear()
    for g in body.vertex_groups:
        obj.vertex_groups.new(name=g.name)
    _mode(obj, 'OBJECT')
    mod = obj.modifiers.new("copy_weights", 'DATA_TRANSFER')
    mod.object = body
    mod.use_vert_data = True
    mod.data_types_verts = {'VGROUP_WEIGHTS'}
    mod.vert_mapping = 'POLYINTERP_NEAREST'
    mod.layers_vgroup_select_src = 'ALL'
    mod.layers_vgroup_select_dst = 'NAME'
    bpy.ops.object.modifier_apply(modifier=mod.name)
    if ease is not None:
        _ease_weights(obj, ease)
    _normalize(obj)
    _armature_parent(obj, rig)


def _weights_table(obj):
    names = [g.name for g in obj.vertex_groups]
    table = []
    for v in obj.data.vertices:
        w = {}
        for ge in v.groups:
            if ge.weight > 1e-4:
                w[names[ge.group]] = ge.weight
        table.append(w)
    return table


def _write_table(obj, table):
    for g in obj.vertex_groups:
        g.remove(list(range(len(obj.data.vertices))))
    groups = {g.name: g for g in obj.vertex_groups}
    for i, w in enumerate(table):
        for n, val in w.items():
            if n not in groups:
                groups[n] = obj.vertex_groups.new(name=n)
            if val > 1e-4:
                groups[n].add([i], val, 'REPLACE')


def _ease_weights(obj, ease):
    table = _weights_table(obj)
    for i, v in enumerate(obj.data.vertices):
        pulls = ease(v.co, i)
        if not pulls:
            continue
        w = table[i]
        for bone, amount in pulls:
            if amount <= 0:
                continue
            total = sum(w.values()) or 1.0
            for n in list(w.keys()):
                w[n] = w[n] / total * (1.0 - amount)
            w[bone] = w.get(bone, 0.0) + amount
    _write_table(obj, table)


def _normalize(obj, limit=4):
    table = _weights_table(obj)
    for w in table:
        items = sorted(w.items(), key=lambda kv: -kv[1])[:limit]
        total = sum(v for _, v in items) or 1.0
        w.clear()
        for n, val in items:
            w[n] = val / total
    _write_table(obj, table)


def smooth_weights(obj, repeat=6, factor=0.5):
    _mode(obj, 'WEIGHT_PAINT')
    obj.data.use_paint_mask_vertex = False
    bpy.ops.object.vertex_group_smooth(group_select_mode='ALL', factor=factor, repeat=repeat)
    _mode(obj, 'OBJECT')
    _normalize(obj)


def bind_head_hair(obj, rig, f, hang_from=None):
    """Hair: the head carries it; long hair below the jaw eases onto the chest."""
    obj.vertex_groups.clear()
    head = obj.vertex_groups.new(name="head")
    chest = obj.vertex_groups.new(name="chest")
    neck = obj.vertex_groups.new(name="neck")
    z_jaw = f.z_chin + 0.02
    z_low = f.z_shoulder - 0.02
    for v in obj.data.vertices:
        z = v.co.z
        if z >= z_jaw:
            head.add([v.index], 1.0, 'REPLACE')
        else:
            t = max(0.0, min(1.0, (z_jaw - z) / max(z_jaw - z_low, 1e-3)))
            t = t * t * (3 - 2 * t)
            hw = 1.0 - 0.75 * t
            head.add([v.index], hw, 'REPLACE')
            neck.add([v.index], 0.25 * t, 'REPLACE')
            chest.add([v.index], 0.50 * t, 'REPLACE')
    _normalize(obj)
    _armature_parent(obj, rig)

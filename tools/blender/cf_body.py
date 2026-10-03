"""Court figures: body proportions, the clay body and its face.

One set of landmarks (Frame) drives the body mesh, the armature, the clothes
and the hair, so they always line up. Units are metres, Z up, the figure
faces -Y (its left hand is +X), feet on Z=0.

The body is modelled as clay: signed-distance forms (cf_sdf) melted together
with a chosen fillet radius and meshed as one watertight surface. Eyes,
brows and the mouth are separate small meshes so the rig can blink, lift
the brows and open the mouth.
"""
import math
import bpy
import bmesh
from mathutils import Vector, Quaternion, Matrix

from cf_sdf import Field, Loft, Ellipsoid, RoundCone, Sphere, RoundBox, finish_mesh

# --- Variants ---------------------------------------------------------------------

BASE = {
    # overall
    "height": 1.72, "head_ratio": 7.1, "neck": 0.060,
    # half widths (metres)
    "shoulder": 0.186, "hip_joint": 0.086, "pelvis": 0.150, "waist": 0.128,
    "chest_w": 0.156, "chest_d": 0.108, "belly": 0.0, "bust": 0.0, "pecs": 1.0,
    # limb radii
    "arm": 0.046, "forearm": 0.039, "thigh": 0.074, "shin": 0.048, "hand": 1.15,
    # posture and face
    "stoop": 0.0, "arm_angle": 24.0, "jaw": 1.0, "brow_ridge": 1.0,
}

VARIANTS = {
    "male_adult": {},
    "female_adult": {"height": 1.62, "head_ratio": 6.9, "neck": 0.064, "shoulder": 0.160, "hip_joint": 0.090,
                     "pelvis": 0.164, "waist": 0.108, "chest_w": 0.132, "chest_d": 0.096, "bust": 1.0, "pecs": 0.0,
                     "arm": 0.038, "forearm": 0.032, "thigh": 0.074, "shin": 0.044, "hand": 1.06,
                     "jaw": 0.80, "brow_ridge": 0.45},
    "male_old": {"height": 1.66, "head_ratio": 6.9, "stoop": 1.0, "belly": 0.8, "arm": 0.042, "forearm": 0.036, "thigh": 0.066,
                 "shin": 0.044, "chest_w": 0.150, "waist": 0.136, "pelvis": 0.150, "pecs": 0.4, "arm_angle": 20.0},
    "female_old": {"height": 1.55, "head_ratio": 6.8, "neck": 0.056, "shoulder": 0.154, "hip_joint": 0.090,
                   "pelvis": 0.164, "waist": 0.124, "chest_w": 0.134, "chest_d": 0.098, "bust": 0.8, "pecs": 0.0,
                   "arm": 0.037, "forearm": 0.032, "thigh": 0.068, "shin": 0.042, "hand": 1.05,
                   "jaw": 0.80, "brow_ridge": 0.45, "stoop": 1.0, "belly": 0.5, "arm_angle": 20.0},
    "male_young": {"height": 1.64, "head_ratio": 6.8, "neck": 0.062, "shoulder": 0.168, "hip_joint": 0.082,
                   "pelvis": 0.140, "waist": 0.116, "chest_w": 0.138, "chest_d": 0.096, "pecs": 0.4,
                   "arm": 0.040, "forearm": 0.034, "thigh": 0.066, "shin": 0.044, "jaw": 0.86, "brow_ridge": 0.6},
    "female_young": {"height": 1.56, "head_ratio": 6.6, "neck": 0.062, "shoulder": 0.150, "hip_joint": 0.086,
                     "pelvis": 0.152, "waist": 0.102, "chest_w": 0.124, "chest_d": 0.090, "bust": 0.6, "pecs": 0.0,
                     "arm": 0.035, "forearm": 0.030, "thigh": 0.068, "shin": 0.041, "hand": 1.0,
                     "jaw": 0.76, "brow_ridge": 0.35},
}


def params(variant):
    p = dict(BASE)
    p.update(VARIANTS[variant])
    p["variant"] = variant
    p["female"] = variant.startswith("female")
    p["old"] = variant.endswith("_old")
    p["young"] = variant.endswith("_young")
    return p


# --- Landmarks -------------------------------------------------------------------

class Frame:
    """Every joint and landmark of one body, in metres."""

    def __init__(self, p):
        self.p = p
        H = p["height"]
        self.H = H
        k = H / 1.72
        hh = H / p["head_ratio"]
        self.head_h = hh
        st = p["stoop"]
        drop = 0.020 * st
        self.z_top = H - drop
        self.z_chin = H - hh - drop
        self.z_shoulder = H - hh - p["neck"] - 0.6 * drop
        self.z_hip = 0.505 * H
        self.z_knee = 0.275 * H
        self.z_ankle = 0.045 * H
        self.z_waist = self.z_hip + 0.40 * (self.z_shoulder - self.z_hip)
        self.z_chest = self.z_hip + 0.73 * (self.z_shoulder - self.z_hip)
        # The spine (pelvis, waist, chest, neck base, head base). An old back
        # rounds: the shoulders go back (+Y) and the head comes forward (-Y).
        self.pelvis = Vector((0.0, 0.004, self.z_hip + 0.045 * k))
        self.waist = Vector((0.0, 0.004 + 0.008 * st, self.z_waist))
        self.chest = Vector((0.0, 0.006 + 0.028 * st, self.z_chest))
        self.neck = Vector((0.0, 0.012 + 0.050 * st, self.z_shoulder + 0.004))
        self.head_base = Vector((0.0, 0.006 + 0.010 * st, self.z_chin + 0.035 * k))
        # the face sits this far forward of the frame's head line
        self.head_offset = Vector((0.0, -0.020 * st, 0.0))
        sw = p["shoulder"]
        self.shoulder_z = self.z_shoulder - 0.012 * k
        self.clavicle, self.shoulder, self.elbow, self.wrist, self.knuckle = {}, {}, {}, {}, {}
        self.hip, self.knee, self.ankle, self.ball, self.toe = {}, {}, {}, {}, {}
        a = math.radians(p["arm_angle"])
        upper = 0.186 * H
        fore = 0.150 * H
        self.hand_len = 0.062 * H * p["hand"]
        for side, s in (("L", 1.0), ("R", -1.0)):
            sh = Vector((s * sw, 0.000 + 0.040 * st, self.shoulder_z))
            self.clavicle[side] = Vector((s * 0.030 * k, -0.010 + 0.040 * st, self.z_shoulder - 0.010 * k))
            self.shoulder[side] = sh
            d1 = Vector((s * math.sin(a), 0.0, -math.cos(a)))
            el = sh + d1 * upper
            # the forearm hangs a little forward and in, as arms do at rest
            d2 = Vector((s * math.sin(a * 0.70), -0.16, -math.cos(a * 0.70))).normalized()
            wr = el + d2 * fore
            self.elbow[side] = el
            self.wrist[side] = wr
            self.knuckle[side] = wr + d2 * self.hand_len
            self.hip[side] = Vector((s * p["hip_joint"], 0.004, self.z_hip))
            self.knee[side] = Vector((s * p["hip_joint"] * 0.92, -0.010, self.z_knee))
            self.ankle[side] = Vector((s * p["hip_joint"] * 0.88, 0.014, self.z_ankle))
            self.ball[side] = Vector((s * p["hip_joint"] * 1.00, -0.100 * k, 0.020 * k))
            self.toe[side] = Vector((s * p["hip_joint"] * 1.04, -0.158 * k, 0.016 * k))

    def face(self, u):
        """A height on the head, 0 at the chin and 1 at the crown."""
        return self.z_chin + u * self.head_h

    def head_point(self, x, y, u):
        return Vector((x, y + self.head_offset.y, self.face(u)))

    def hand_frame(self, side):
        """Hand axes: along the fingers, toward the thumb (front), out of the back of the hand."""
        along = (self.knuckle[side] - self.wrist[side]).normalized()
        front = Vector((0.0, -1.0, 0.0))
        front = (front - along * front.dot(along)).normalized()
        out = along.cross(front) if side == "L" else front.cross(along)
        return along, front, out.normalized()


def _quat_from_axes(x_axis, y_axis):
    x = Vector(x_axis).normalized()
    y = (Vector(y_axis) - x * Vector(y_axis).dot(x)).normalized()
    z = x.cross(y)
    m = Matrix((x, y, z)).transposed()
    return m.to_quaternion()


def _up_to(d):
    """Rotate a form whose long axis is Z to lie along d."""
    return Vector((0, 0, 1)).rotation_difference(Vector(d).normalized())


# --- The body --------------------------------------------------------------------

def torso_profile(f):
    """Trunk sections: (z, half width, front depth, back depth, centre y)."""
    p = f.p
    k = f.H / 1.72
    fem = p["female"]
    st = p["stoop"]
    zc = f.z_hip - 0.070 * k
    zs = f.z_shoulder
    belly = p["belly"]
    return [
        (zc, p["pelvis"] * 0.78, 0.062 * k, 0.078 * k, 0.004),
        (f.z_hip, p["pelvis"], 0.080 * k + 0.010 * belly * k, 0.102 * k + (0.010 if fem else 0.0), 0.004),
        (f.z_hip + 0.115 * k, p["pelvis"] * 0.92, 0.086 * k + 0.030 * belly * k, 0.084 * k, 0.002),
        (f.z_waist, p["waist"], 0.086 * k + 0.040 * belly * k, 0.076 * k, 0.002 + 0.006 * st),
        (f.z_waist + 0.085 * k, (p["waist"] + p["chest_w"]) * 0.5, 0.092 * k + 0.022 * belly * k, 0.082 * k, 0.004 + 0.016 * st),
        (f.z_chest, p["chest_w"], p["chest_d"], 0.092 * k, 0.006 + 0.030 * st),
        (zs - 0.072 * k, p["chest_w"] * 1.02, p["chest_d"] * 0.88, 0.094 * k, 0.008 + 0.042 * st),
        (zs + 0.006, p["shoulder"] * 0.60, 0.056 * k, 0.062 * k, 0.012 + 0.052 * st),
    ]


def build_body(f, name="Body", voxel=0.003):
    """The clay body for a frame, as one watertight mesh."""
    p = f.p
    H = f.H
    k = H / 1.72
    fem = p["female"]
    st = p["stoop"]
    reach = max(abs(f.knuckle["L"].x), abs(f.shoulder["L"].x) + 0.08) + 0.07
    fld = Field((-reach, -0.26 * k, -0.01), (reach, 0.22 * k, f.z_top + 0.02), voxel)
    keys = torso_profile(f)
    fld.union(Loft([q[0] for q in keys], [q[1] for q in keys], [q[2] for q in keys], [q[3] for q in keys],
                   [q[4] for q in keys], cap_round=0.035 * k))
    if p["bust"] > 0:
        b = p["bust"]
        for s in (1, -1):
            fld.union(Sphere(f.chest + Vector((s * 0.054 * k, -p["chest_d"] * 0.58 + 0.014 * st, 0.008 * k - 0.026 * st)),
                             0.048 * k * (0.70 + 0.30 * b)), 0.030 * k)
    if p["pecs"] > 0:
        for s in (1, -1):
            fld.union(Ellipsoid(f.chest + Vector((s * 0.058 * k, -p["chest_d"] * 0.60 + 0.012 * st, 0.044 * k)),
                                (0.058 * k, 0.028 * k * p["pecs"] + 0.008, 0.044 * k)), 0.030 * k)
    # shoulder blades and the slope of the shoulders into the neck
    for side, s in (("L", 1), ("R", -1)):
        fld.union(Ellipsoid(f.chest + Vector((s * 0.060 * k, 0.068 * k + 0.012 * st, 0.060 * k)), (0.058 * k, 0.030 * k, 0.070 * k)), 0.040 * k)
        fld.union(RoundCone(Vector((s * 0.040 * k, f.neck.y + 0.010, f.z_shoulder + 0.026 * k)),
                            Vector((s * (p["shoulder"] - 0.024 * k), f.shoulder[side].y + 0.006, f.shoulder_z + 0.010 * k)),
                            0.036 * k, 0.034 * k), 0.035 * k)
    nr = (0.050 if not fem else 0.043) * k
    fld.union(RoundCone(f.neck + Vector((0, 0.006, -0.050 * k)), f.head_base + Vector((0, 0.016, -0.006)), nr, nr * 0.84), 0.022 * k)
    build_head(fld, f)
    for side, s in (("L", 1.0), ("R", -1.0)):
        sh, el, wr = f.shoulder[side], f.elbow[side], f.wrist[side]
        arm_dir = (el - sh).normalized()
        fld.union(Ellipsoid(sh + arm_dir * 0.030 * k + Vector((s * 0.006 * k, 0, 0.004)),
                            (p["arm"] * 1.22, p["arm"] * 1.18, 0.074 * k), rot=_up_to(arm_dir)), 0.030 * k)
        fld.union(RoundCone(sh, el, p["arm"] * 1.02, p["arm"] * 0.80), 0.016 * k)
        fld.union(Ellipsoid(sh.lerp(el, 0.50) + Vector((0, -0.004, 0)), (p["arm"] * 1.00, p["arm"] * 1.04, (el - sh).length * 0.34),
                            rot=_up_to(el - sh)), 0.020 * k)
        fld.union(RoundCone(el, wr, p["forearm"] * 0.98, p["forearm"] * 0.66), 0.014 * k)
        fld.union(Ellipsoid(el.lerp(wr, 0.28), (p["forearm"] * 1.14, p["forearm"] * 1.04, (wr - el).length * 0.30),
                            rot=_up_to(wr - el)), 0.020 * k)
        build_hand(fld, f, side)
    for side, s in (("L", 1.0), ("R", -1.0)):
        hp, kn, an = f.hip[side], f.knee[side], f.ankle[side]
        th = p["thigh"]
        fld.union(RoundCone(hp + Vector((s * 0.006, 0.004, 0.025)), kn, th * 1.10, p["shin"] * 1.04), 0.040 * k)
        fld.union(Ellipsoid(hp.lerp(kn, 0.36) + Vector((s * 0.006, -0.006, 0)), (th * 0.98, th * 1.02, (kn - hp).length * 0.36),
                            rot=_up_to(kn - hp)), 0.030 * k)
        fld.union(Sphere(kn + Vector((0, -0.008, 0)), p["shin"] * 1.04), 0.016 * k)
        fld.union(RoundCone(kn, an, p["shin"] * 0.96, p["shin"] * 0.66), 0.014 * k)
        fld.union(Ellipsoid(kn.lerp(an, 0.30) + Vector((s * 0.003, 0.016 * k, 0)), (p["shin"] * 1.12, p["shin"] * 1.16, (an - kn).length * 0.30),
                            rot=_up_to(an - kn)), 0.020 * k)
        build_foot(fld, f, side)
    return fld.mesh(name)


# Face layout, as heights on the head (0 chin, 1 crown) and offsets in metres
# for a head 0.282 m tall. A figurine's face: eyes a little low and wide set,
# a small nose, a soft jaw.
FACE = {"eye_u": 0.470, "eye_x": 0.035, "brow_u": 0.565, "nose_u": 0.335, "mouth_u": 0.195}


# A face's own shape, each from -1 to 1 (0 the variant's own face). The
# game mixes these per person as morph targets (face_<name>), so a people
# shares a family look and every person differs within it.
FACE_SHAPES = ("jaw", "chin", "cheek", "nose", "bridge", "nose_wide", "brow", "lips", "ears", "long", "round", "aged")


def build_head(fld, f, shape=None):
    p = f.p
    sh = shape or {}
    g = lambda k: float(sh.get(k, 0.0))
    s = f.head_h / 0.282
    hp = lambda x, y, u: f.head_point(x * s, y * s, u)
    jaw = p["jaw"] * (1.0 + 0.20 * g("jaw"))
    fem = p["female"]
    long_ = g("long")
    aged = max(0.0, g("aged")) + (0.55 if p.get("old") else 0.0)
    rnd = g("round")
    # cranium: round, the back of the head full
    fld.union(Ellipsoid(hp(0, 0.014, 0.640), (0.087 * s, 0.097 * s, 0.100 * s)), 0.03 * s)
    # the face: an egg narrowing to the chin
    fld.union(Ellipsoid(hp(0, -0.030, 0.410 - 0.010 * long_), (0.069 * s * (1.0 + 0.06 * rnd - 0.02 * long_), 0.066 * s, 0.104 * s * (1.0 + 0.06 * long_))), 0.034 * s)
    fld.union(Ellipsoid(hp(0, -0.040, 0.185 - 0.025 * long_ - 0.012 * aged),
                        (0.049 * s * (0.88 + 0.16 * jaw) * (1.0 + 0.05 * rnd), 0.054 * s, 0.062 * s * (1.0 + 0.10 * long_))), 0.030 * s)
    fld.union(Sphere(hp(0, -0.066 - 0.010 * g("chin"), 0.070 - 0.030 * long_ - 0.006 * g("chin")),
                     0.020 * s * (0.88 + 0.16 * jaw) * (1.0 + 0.22 * g("chin"))), 0.016 * s)
    for sd in (1, -1):
        if jaw > 0.9 or g("jaw") > 0.3:
            fld.union(Ellipsoid(hp(sd * 0.044 * (1.0 + 0.10 * g("jaw")), -0.008, 0.200 - 0.030 * aged - 0.02 * long_),
                                (0.018 * s * (1.0 + 0.4 * max(0.0, g("jaw"))), 0.026 * s, 0.022 * s)), 0.020 * s)
        # cheekbones: higher and fuller, or soft; the old lose the flesh under them
        fld.union(Sphere(hp(sd * (0.046 + 0.006 * g("cheek")), -0.050 - 0.004 * g("cheek"), 0.405 + 0.02 * g("cheek")),
                         0.021 * s * (1.0 + 0.25 * g("cheek") + 0.15 * rnd)), 0.020 * s)
        if aged > 0.05:
            fld.subtract(Ellipsoid(hp(sd * 0.044, -0.058, 0.300), (0.016 * s, 0.010 * s, 0.024 * s)), 0.012 * s * min(1.0, aged))
        fld.union(Ellipsoid(hp(sd * 0.084, 0.014, 0.445), (0.011 * s * (1 + 0.2 * g("ears")), 0.019 * s * (1 + 0.3 * g("ears")),
                                                            0.028 * s * (1 + 0.3 * g("ears"))),
                            rot=Quaternion((0, 0, 1), math.radians(sd * (22 + 8 * g("ears"))))), 0.007 * s)
        fld.union(RoundCone(hp(sd * 0.012, -0.085 - 0.004 * g("brow"), FACE["brow_u"]), hp(sd * 0.054, -0.071, FACE["brow_u"] - 0.012),
                            0.011 * s * (0.6 + 0.4 * p["brow_ridge"]) * (1.0 + 0.45 * g("brow")), 0.008 * s), 0.014 * s)
        fld.subtract(Sphere(hp(sd * FACE["eye_x"], -0.099, FACE["eye_u"]), 0.0110 * s), 0.008 * s)
        # the wings of the nose
        fld.union(Sphere(hp(sd * 0.012 * (1.0 + 0.30 * g("nose_wide")), -0.093, FACE["nose_u"] - 0.004),
                         0.0085 * s * (1.0 + 0.25 * g("nose_wide") + 0.15 * g("nose"))), 0.006 * s)
        if aged > 0.05:
            # the lines from the nose to the mouth, and at the eyes' corners
            fld.subtract(RoundCone(hp(sd * 0.020, -0.090, FACE["nose_u"] - 0.012), hp(sd * 0.030, -0.078, FACE["mouth_u"] - 0.015),
                                   0.0016 * s * min(1.0, aged), 0.0012 * s * min(1.0, aged)), 0.002 * s)
            fld.subtract(RoundCone(hp(sd * 0.054, -0.080, FACE["eye_u"] + 0.010), hp(sd * 0.062, -0.074, FACE["eye_u"] - 0.020),
                                   0.0010 * s * min(1.0, aged), 0.0008 * s * min(1.0, aged)), 0.0015 * s)
    nose = 1.0 + 0.28 * g("nose")
    fld.union(RoundCone(hp(0, -0.087 - 0.006 * g("bridge"), 0.505), hp(0, -0.102 - 0.010 * g("nose") - 0.006 * g("bridge"), FACE["nose_u"] + 0.015),
                        0.0070 * s * (1.0 + 0.2 * g("bridge")), 0.0098 * s * nose), 0.010 * s)
    if g("bridge") > 0.05:
        fld.union(Sphere(hp(0, -0.096 - 0.008 * g("bridge"), 0.445), 0.0080 * s * g("bridge")), 0.008 * s)
    fld.union(Sphere(hp(0, -0.100 - 0.010 * g("nose"), FACE["nose_u"] - 0.004 * g("nose")), 0.0130 * s * (0.92 if fem else 1.0) * nose), 0.008 * s)
    lips = 1.0 + 0.35 * g("lips")
    fld.union(Ellipsoid(hp(0, -0.078 - 0.003 * g("lips"), FACE["mouth_u"] + 0.006), (0.022 * s * (1.0 + 0.08 * g("lips")), 0.011 * s * lips, 0.016 * s * lips)), 0.010 * s)
    if aged > 0.05:
        # lines across the brow
        for i in range(2):
            fld.subtract(RoundCone(hp(-0.030, -0.092, 0.645 + 0.03 * i), hp(0.030, -0.092, 0.648 + 0.03 * i),
                                   0.0009 * s * min(1.0, aged), 0.0009 * s * min(1.0, aged)), 0.0015 * s)


def head_recipe(f, shape=None):
    """The head alone as a signed distance (for face morphs)."""
    from cf_sdf import Recipe
    r = Recipe(far=0.05)
    build_head(r, f, shape)
    return r


def build_hand(fld, f, side):
    p = f.p
    k = f.H / 1.72
    hs = p["hand"] * k
    along, front, out = f.hand_frame(side)
    wr = f.wrist[side]
    L = f.hand_len
    q = _quat_from_axes(along, front)
    fld.union(RoundBox(wr + along * (L * 0.34), (L * 0.27, 0.036 * hs, 0.012 * hs), 0.011 * hs, rot=q), 0.012 * hs)
    base = wr + along * (L * 0.55)
    for i, (offset, spread, length, r) in enumerate(((0.026, 0.010, 0.062, 1.0), (0.0075, 0.003, 0.068, 1.04),
                                                      (-0.0105, -0.003, 0.063, 1.0), (-0.027, -0.009, 0.050, 0.90))):
        a = base + front * (offset * hs) - out * (0.002 * hs)
        b = a + along * (length * hs) - out * (0.011 * hs) + front * (spread * hs)
        fld.union(RoundCone(a, b, 0.0092 * hs * r, 0.0074 * hs * r), 0.0018 * hs)
    tb = wr + along * (L * 0.18) + front * (0.028 * hs) - out * (0.006 * hs)
    tt = tb + along * (0.044 * hs) + front * (0.024 * hs) - out * (0.016 * hs)
    fld.union(RoundCone(tb, tt, 0.0140 * hs, 0.0100 * hs), 0.008 * hs)


def build_foot(fld, f, side):
    k = f.H / 1.72
    an, ball, toe = f.ankle[side], f.ball[side], f.toe[side]
    heel = Vector((an.x, an.y + 0.026 * k, 0.034 * k))
    fld.union(Sphere(heel, 0.036 * k), 0.016 * k)
    fld.union(RoundCone(heel + Vector((0, -0.01, 0.004)), ball + Vector((0, 0, 0.016)), 0.034 * k, 0.030 * k), 0.012 * k)
    fld.union(Ellipsoid(ball.lerp(toe, 0.35) + Vector((0, 0, 0.012)), (0.044 * k, 0.040 * k, 0.020 * k)), 0.010 * k)


# --- Face parts -----------------------------------------------------------------

def surface_hit(obj, origin, direction, dist=2.0):
    """First hit on obj's surface from origin along direction (world)."""
    mw = obj.matrix_world
    inv = mw.inverted()
    o = inv @ Vector(origin)
    d = (inv.to_3x3() @ Vector(direction)).normalized()
    ok, loc, nor, _ = obj.ray_cast(o, d, distance=dist)
    if not ok:
        return None, None
    return mw @ loc, (mw.to_3x3() @ nor).normalized()


def ellipsoid_mesh(name, center, semi, rot=None, segs=16, rings=10):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=rings, radius=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * semi[0], v.co.y * semi[1], v.co.z * semi[2]))
        if rot is not None:
            v.co = rot @ v.co
        v.co += Vector(center)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    for poly in me.polygons:
        poly.use_smooth = True
    return obj


def join(objs, name):
    for o in bpy.context.selected_objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    out = bpy.context.view_layer.objects.active
    out.name = name
    out.data.name = name
    return out


def decal(name, body, outline, centre, offset, rings=3):
    """A painted mark on the skin: a flat outline (x, z pairs, world) filled
    with rings about its centre, each point dropped onto the body along +Y
    and lifted off it by `offset`."""
    bm = bmesh.new()
    cx, cz = centre
    n = len(outline)
    grid = []
    centre_v = None
    pts = []
    for r in range(rings + 1):
        t = r / rings
        if r == 0:
            pts.append([(cx, cz)])
        else:
            pts.append([(cx + (x - cx) * t, cz + (z - cz) * t) for x, z in outline])
    made = []
    for ring in pts:
        row = []
        for x, z in ring:
            hit, nor = surface_hit(body, Vector((x, -1.0, z)), Vector((0, 1, 0)))
            if hit is None:
                hit, nor = Vector((x, -0.09, z)), Vector((0, -1, 0))
            row.append(bm.verts.new(hit + nor * offset))
        made.append(row)
    c = made[0][0]
    for i in range(n):
        bm.faces.new((c, made[1][i], made[1][(i + 1) % n]))
    for r in range(1, rings):
        a, b = made[r], made[r + 1]
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((a[i], b[i], b[j], a[j]))
    bm.normal_update()
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    for poly in me.polygons:
        poly.use_smooth = True
    # face the viewer (out of the skin)
    if me.polygons and me.polygons[0].normal.y > 0:
        me.flip_normals()
    return obj


EYE = {"w": 0.034, "up": 0.0072, "up_f": 0.0080, "low": 0.0056, "tilt": 0.06}


def _eye_curves(cx, cz, sd, s, female, n=12):
    """Upper and lower lid lines (inner corner first) of one eye."""
    W = EYE["w"] * s
    hu = (EYE["up_f"] if female else EYE["up"]) * s
    hl = EYE["low"] * s
    up, lo = [], []
    for i in range(n + 1):
        u = i / n
        x = cx + sd * (u - 0.5) * W
        zt = cz + EYE["tilt"] * (u - 0.5) * W
        up.append((x, zt + hu * math.sin(math.pi * u) ** 0.80 * (1.0 + 0.30 * (u - 0.45))))
        lo.append((x, zt - hl * math.sin(math.pi * u) ** 1.15))
    return up, lo


def _eye_outline(cx, cz, sd, s, female):
    up, lo = _eye_curves(cx, cz, sd, s, female)
    outline = up + lo[-2:0:-1]
    if sd < 0:
        outline = outline[::-1]
    return outline


def _clip_to_eye(points, up, lo, sd):
    """Keeps a shape inside the lids (the iris is cut by them, never on the skin)."""
    xs = [q[0] for q in up]
    out = []
    for x, z in points:
        if sd > 0:
            x = min(max(x, xs[0]), xs[-1])
        else:
            x = max(min(x, xs[0]), xs[-1])
        t = (x - xs[0]) / (xs[-1] - xs[0]) if xs[-1] != xs[0] else 0.0
        i = min(int(t * (len(up) - 1)), len(up) - 2)
        k = t * (len(up) - 1) - i
        zt = up[i][1] * (1 - k) + up[i + 1][1] * k - 0.0003
        zb = lo[i][1] * (1 - k) + lo[i + 1][1] * k + 0.0003
        out.append((x, min(max(z, zb), zt)))
    return out


# Where the eyes look: the iris, pupil and shine slide inside the white
# (morphs eyes_left/right/up/down; the figure's left is +X). Across, the iris
# reaches the corner; up and down, about half of it hides under a lid.
GAZE = {"eyes_left": (1.0, 0.0), "eyes_right": (-1.0, 0.0), "eyes_up": (0.0, 1.0), "eyes_down": (0.0, -1.0)}
GAZE_REACH = (0.0082, 0.0036)


def _gaze_keys(obj, make, s):
    """Stores where each vertex of an eye part goes for each gaze as a point
    attribute (gz_<key>), which survives joining; gaze_morphs() turns them into
    shape keys. make(dx, dz) builds the part again, moved; None: it stays."""
    me = obj.data
    for key, (gx, gz) in GAZE.items():
        if make is None:
            co = [v.co.copy() for v in me.vertices]
        else:
            tmp = make(gx * GAZE_REACH[0] * s, gz * GAZE_REACH[1] * s)
            co = [v.co.copy() for v in tmp.data.vertices]
            bpy.data.objects.remove(tmp, do_unlink=True)
            if len(co) != len(me.vertices):
                co = [v.co.copy() for v in me.vertices]
        attr = me.attributes.new("gz_" + key, 'FLOAT_VECTOR', 'POINT')
        for i, c in enumerate(co):
            attr.data[i].vector = c


def gaze_morphs(eyes):
    """The gaze attributes of the joined eyes as shape keys (then dropped)."""
    me = eyes.data
    if me.shape_keys is None:
        eyes.shape_key_add(name="Basis", from_mix=False)
    for key in GAZE:
        attr = me.attributes.get("gz_" + key)
        if attr is None:
            continue
        sk = eyes.shape_key_add(name=key, from_mix=False)
        for i, d in enumerate(attr.data):
            sk.data[i].co = d.vector
        sk.value = 0.0
    for key in GAZE:
        attr = me.attributes.get("gz_" + key)
        if attr is not None:
            me.attributes.remove(attr)


def _oval(cx, cz, rx, rz, n=14):
    return [(cx + rx * math.cos(2 * math.pi * i / n), cz + rz * math.sin(2 * math.pi * i / n)) for i in range(n)]


def _stroke_outline(points, widths):
    """A tapered stroke along points (x, z) with widths; returns its outline."""
    top, bot = [], []
    for i, (p, w) in enumerate(zip(points, widths)):
        a = points[max(i - 1, 0)]
        b = points[min(i + 1, len(points) - 1)]
        dx, dz = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dz) or 1.0
        nx, nz = -dz / L, dx / L
        top.append((p[0] + nx * w * 0.5, p[1] + nz * w * 0.5))
        bot.append((p[0] - nx * w * 0.5, p[1] - nz * w * 0.5))
    return top + bot[::-1]


def build_face(f, body):
    """Painted eyes (with a catch of light), brows and a mouth that opens.

    Returns {part: [objects], 'eye_center': {L,R}, 'brow_center': {L,R}};
    each object carries custom property 'bone' naming the bone that moves it."""
    s = f.head_h / 0.282
    fem = f.p["female"]
    out = {"eyes": [], "brows": [], "mouth": [], "eye_center": {}, "brow_center": {}}
    shines = []
    for side, sd in (("L", 1.0), ("R", -1.0)):
        cx = sd * FACE["eye_x"] * s
        cz = f.face(FACE["eye_u"])
        white = decal("EyeWhite_" + side, body, _eye_outline(cx, cz, sd, s, fem), (cx, cz), 0.0010 * s)
        white["bone"] = "eye." + side
        out["eyes"].append(white)
        ix, iz = cx + sd * 0.0006 * s, cz + 0.0006 * s
        # The iris and pupil are whole discs: the game draws them only over
        # the white (a stencil), so they can roll about inside the lids.
        def iris_at(dx, dz, ix=ix, iz=iz):
            return decal("Eye_" + side, body, _oval(ix + dx, iz + dz, 0.0074 * s, 0.0080 * s, n=24), (ix + dx, iz + dz), 0.0016 * s, rings=2)

        def pupil_at(dx, dz, ix=ix, iz=iz):
            return decal("EyePupil_" + side, body, _oval(ix + dx, iz + dz, 0.0034 * s, 0.0037 * s, n=16), (ix + dx, iz + dz), 0.0019 * s, rings=1)
        iris = iris_at(0.0, 0.0)
        _gaze_keys(iris, iris_at, s)
        iris["bone"] = "eye." + side
        out["eyes"].append(iris)
        pupil = pupil_at(0.0, 0.0)
        _gaze_keys(pupil, pupil_at, s)
        pupil["bone"] = "eye." + side
        out["eyes"].append(pupil)
        _gaze_keys(white, None, s)
        # the upper lid: a firm line that runs a little past the outer corner
        up, lo = _eye_curves(cx, cz, sd, s, fem)
        lid = [(x, z + 0.0004 * s) for x, z in up]
        lid.append((up[-1][0] + sd * 0.0030 * s, up[-1][1] - 0.0012 * s))
        widths = [(0.0014 + 0.0018 * math.sin(math.pi * min(1.0, i / (len(lid) - 1) * 1.1))) * s for i in range(len(lid))]
        lidm = decal("EyeLid_" + side, body, _stroke_outline(lid, widths), lid[len(lid) // 2], 0.0020 * s, rings=1)
        lidm["bone"] = "eye." + side
        _gaze_keys(lidm, None, s)
        out["eyes"].append(lidm)
        hit, nor = surface_hit(body, Vector((cx, -1.0, cz)), Vector((0, 1, 0)))
        out["eye_center"][side] = hit if hit is not None else Vector((cx, -0.09 * s, cz))
        r = 0.0017 * s
        sx, sz = ix + sd * 0.0024 * s, iz + 0.0018 * s

        def shine_at(dx, dz, sx=sx, sz=sz):
            ring = [(sx + dx + r * math.cos(a * math.pi / 6), sz + dz + r * math.sin(a * math.pi / 6)) for a in range(12)]
            return decal("EyeShine_" + side, body, ring, (sx + dx, sz + dz), 0.0024 * s, rings=1)
        shine = shine_at(0.0, 0.0)
        _gaze_keys(shine, shine_at, s)
        shine["bone"] = "eye." + side
        shines.append(shine)
        # the brow: thick at the nose end, thinning outward, a slight arch
        bz = f.face(FACE["brow_u"] + 0.006)
        line, widths = [], []
        for i in range(9):
            u = i / 8.0
            x = sd * (0.011 + 0.050 * u) * s
            arch = (0.0060 if fem else 0.0042) * math.sin(math.pi * min(1.0, u * 1.15)) - 0.0030 * u
            line.append((x, bz + arch * s))
            widths.append(((0.0072 if not fem else 0.0056) * (1.0 - u) + 0.0022 * u) * s)
        brow = decal("Brow_" + side, body, _stroke_outline(line, widths), line[3], 0.0011 * s, rings=2)
        brow["bone"] = "brow." + side
        out["brows"].append(brow)
        hb, nb = surface_hit(body, Vector((line[3][0], -1.0, line[3][1])), Vector((0, 1, 0)))
        out["brow_center"][side] = hb if hb is not None else Vector((line[3][0], -0.088 * s, line[3][1]))
    out["eyes"] += shines
    for e in out["eyes"]:
        slot = "EYES"
        for prefix, named in (("EyeWhite_", "EYE_WHITE"), ("EyeShine_", "EYE_SHINE"), ("EyePupil_", "PUPIL"), ("Eye_", "IRIS")):
            if e.name.startswith(prefix):
                slot = named
                break
        set_material(e, slot)
    for b in out["brows"]:
        set_material(b, "HAIR")
    # the mouth: lips just parted at rest; the jaw bone opens it
    mz = f.face(FACE["mouth_u"])
    Wm = 0.033 * s
    up, lo = [], []
    N = 14
    for i in range(N + 1):
        u = i / N
        x = (u - 0.5) * Wm
        bow = 0.0010 * s * math.exp(-((u - 0.5) / 0.12) ** 2)  # the dip of the upper lip
        lift = 0.0009 * s * (2.0 * abs(u - 0.5)) ** 2
        up.append((x, mz + lift + 0.0016 * s * math.sin(math.pi * u) ** 0.9 - bow * 0.6))
        lo.append((x, mz + lift - 0.0022 * s * math.sin(math.pi * u) ** 0.8))
    outline = up + lo[-2:0:-1]
    mouth = decal("Mouth", body, outline[::-1], (0.0, mz), 0.0012 * s, rings=2)
    mouth["bone"] = "jaw"
    set_material(mouth, "MOUTH")
    out["mouth"].append(mouth)
    hit, nor = surface_hit(body, Vector((0, -1.0, mz)), Vector((0, 1, 0)))
    f.mouth_center = hit.copy() if hit is not None else Vector((0, -0.10 * s, mz))
    return out


# --- Materials ------------------------------------------------------------------

SLOT_DEFAULTS = {
    "SKIN": (0.62, 0.42, 0.30), "HAIR": (0.10, 0.07, 0.05), "CLOTH_A": (0.55, 0.42, 0.28),
    "CLOTH_B": (0.40, 0.27, 0.18), "CLOTH_C": (0.66, 0.30, 0.20), "EYES": (0.035, 0.026, 0.020),
    "EYE_SHINE": (0.95, 0.92, 0.85), "EYE_WHITE": (0.90, 0.86, 0.78), "IRIS": (0.20, 0.12, 0.07), "PUPIL": (0.02, 0.015, 0.01), "STUBBLE": (0.30, 0.22, 0.17),
    "WOOD": (0.36, 0.24, 0.14), "CLAY": (0.55, 0.32, 0.20), "MOUTH": (0.24, 0.08, 0.07), "LEATHER": (0.30, 0.19, 0.11),
}


def material(slot):
    """The one export material for a slot (flat colour; Godot recolours it)."""
    m = bpy.data.materials.get(slot)
    if m is not None:
        return m
    col = SLOT_DEFAULTS.get(slot, (0.5, 0.5, 0.5))
    m = bpy.data.materials.new(slot)
    m.diffuse_color = (*col, 1.0)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*col, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.85
    return m


def set_material(obj, slot):
    obj.data.materials.clear()
    obj.data.materials.append(material(slot))


# --- Morph targets ----------------------------------------------------------------

def _head_mask(f, z):
    lo, hi = f.z_chin - 0.07 * f.H / 1.72, f.z_chin - 0.015 * f.H / 1.72
    t = (z - lo) / (hi - lo)
    return 0.0 if t <= 0 else (1.0 if t >= 1 else t * t * (3 - 2 * t))


def face_morphs(f, objs):
    """Adds face_<shape> morph targets to every object near the head: each
    point moves as the skin under it moves when that one shape is pushed
    to 1. Hair, beards and the painted features ride the skin."""
    import numpy as np
    from mathutils.kdtree import KDTree
    base = head_recipe(f)
    eps = 0.0006
    skin = {}   # the body's own movement per shape, for features painted on it
    painted = [o for o in objs if o.name.split(".")[0] in ("Eyes", "Brows", "Mouth")]
    objs = [o for o in objs if o not in painted]
    for o in objs:
        me = o.data
        if not me.vertices:
            continue
        co = np.array([v.co[:] for v in me.vertices], dtype=np.float32)
        mask = np.array([_head_mask(f, z) for z in co[:, 2]], dtype=np.float32)
        near = mask > 0.0
        if not near.any():
            continue
        P = co[near]
        d0 = base.eval(P)
        grad = np.zeros_like(P)
        for axis in range(3):
            dp = np.zeros(3, dtype=np.float32)
            dp[axis] = eps
            grad[:, axis] = (base.eval(P + dp) - base.eval(P - dp)) / (2 * eps)
        grad /= np.maximum(np.linalg.norm(grad, axis=1, keepdims=True), 1e-6)
        if o.data.shape_keys is None:
            o.shape_key_add(name="Basis", from_mix=False)
        for name in FACE_SHAPES:
            var = head_recipe(f, {name: 1.0})
            delta = var.eval(P) - d0
            # only where the skin is near: far points (a long beard) follow less
            reach = np.clip(1.0 - np.abs(d0) / 0.05, 0.0, 1.0)
            move = -(delta * reach * mask[near])[:, None] * grad
            key = o.shape_key_add(name="face_" + name, from_mix=False)
            flat = co.copy()
            flat[near] += move
            key.data.foreach_set("co", flat.ravel())
            if o.name.split(".")[0] == "Body":
                skin[name] = flat - co
        if o.name.split(".")[0] == "Body":
            skin["_co"] = co
    # what is painted on the skin moves exactly as the skin under it
    if "_co" in skin and painted:
        tree = KDTree(len(skin["_co"]))
        for i, c in enumerate(skin["_co"]):
            tree.insert(c, i)
        tree.balance()
        for o in painted:
            me = o.data
            co = np.array([v.co[:] for v in me.vertices], dtype=np.float32)
            near = [tree.find_n(Vector(c), 4) for c in co]
            if o.data.shape_keys is None:
                o.shape_key_add(name="Basis", from_mix=False)
            for name in FACE_SHAPES:
                move = np.zeros_like(co)
                for i, hits in enumerate(near):
                    wsum = 0.0
                    for (_, idx, dist) in hits:
                        w = 1.0 / (dist + 1e-4)
                        move[i] += skin[name][idx] * w
                        wsum += w
                    move[i] /= max(wsum, 1e-6)
                key = o.shape_key_add(name="face_" + name, from_mix=False)
                key.data.foreach_set("co", (co + move).ravel())


def mood_morphs(f, mouth, brows):
    """Mood on the painted features: the mouth smiles or tightens, the brows
    worry (inner ends up) or set hard (inner ends down)."""
    s = f.head_h / 0.282
    mz = f.face(FACE["mouth_u"])
    hw = 0.0165 * s
    for o, keys in ((mouth, ("mood_smile", "mood_tight")), (brows, ("mood_worry", "mood_stern"))):
        if o.data.shape_keys is None:
            o.shape_key_add(name="Basis", from_mix=False)
        for name in keys:
            k = o.shape_key_add(name=name, from_mix=False)
            for v, kv in zip(o.data.vertices, k.data):
                x, y, z = v.co
                if name == "mood_smile":
                    t = min(1.0, abs(x) / hw)
                    kv.co = Vector((x * 1.06, y, z + 0.0024 * s * t * t - 0.0004 * s * (1 - t)))
                elif name == "mood_tight":
                    kv.co = Vector((x * 0.88, y, mz + (z - mz) * 0.45 - 0.0004 * s))
                else:
                    inner = max(0.0, 1.0 - (abs(x) - 0.011 * s) / (0.050 * s))
                    if name == "mood_worry":
                        kv.co = Vector((x, y, z + 0.0034 * s * inner * inner - 0.0006 * s * (1 - inner)))
                    else:
                        kv.co = Vector((x - math.copysign(0.0010 * s * inner, x), y, z - 0.0026 * s * inner * inner + 0.0004 * s * (1 - inner)))


EXPRESSIONS = ("smile", "frown", "brows_up", "brows_down", "brows_worried", "eyes_wide", "eyes_narrow", "blink",
               "jaw_open", "lips_pressed", "sneer", "cheeks_puff")
VISEMES = ("v_aa", "v_ee", "v_oo", "v_mm", "v_fv")


def _smooth(x):
    x = max(0.0, min(1.0, x))
    return x * x * (3 - 2 * x)


def expression_morphs(f, body, eyes, brows, mouth, eye_centers, riders=()):
    """Expressions and visemes as morph targets, each 0..1, on the meshes they
    move: the mouth (its painted lens), the skin of the jaw and cheeks, the
    eyes and the brows. Beards and hair near the jaw (riders) move with the
    skin under them."""
    import numpy as np
    from mathutils.kdtree import KDTree
    s = f.head_h / 0.282
    mz = f.face(FACE["mouth_u"])
    hw = 0.0165 * s
    my = float(getattr(f, "mouth_center", Vector((0, -0.1 * s, mz))).y)

    def add_key(o, name, fn):
        if o.data.shape_keys is None:
            o.shape_key_add(name="Basis", from_mix=False)
        k = o.shape_key_add(name=name, from_mix=False)
        for v, kv in zip(o.data.vertices, k.data):
            kv.co = fn(v.co.copy())
        return k

    # --- the painted mouth
    def mouth_shape(name):
        def fn(c):
            x, y, z = c
            t = min(1.0, abs(x) / hw)
            up = z >= mz
            if name == "smile":
                return Vector((x * 1.08, y, z + 0.0028 * s * t * t - 0.0003 * s * (1 - t)))
            if name == "frown":
                return Vector((x * 0.97, y, z - 0.0024 * s * t * t + 0.0003 * s * (1 - t)))
            if name == "lips_pressed":
                return Vector((x * 0.92, y, mz + (z - mz) * 0.30))
            if name == "sneer":
                side = 1.0 if x < 0 else 0.25
                return Vector((x, y, z + (0.0018 * s * side if up else 0.0004 * s * side)))
            open_ = {"jaw_open": (0.0095, 0.0012, 1.00), "v_aa": (0.0075, 0.0010, 0.96), "v_ee": (0.0030, 0.0008, 1.14),
                     "v_oo": (0.0045, 0.0016, 0.62), "v_mm": (0.0, 0.0, 0.96), "v_fv": (0.0016, -0.0007, 1.00)}[name]
            low, high, wide = open_
            round_ = math.sqrt(max(0.0, 1.0 - t * t))
            if name == "v_mm":
                return Vector((x * wide, y, mz + (z - mz) * 0.22))
            dz = (high * s * round_) if up else (-low * s * round_)
            return Vector((x * wide, y + (0.0006 * s if not up else 0.0), z + dz))
        return fn

    for name in ("smile", "frown", "lips_pressed", "sneer", "jaw_open") + VISEMES:
        add_key(mouth, name, mouth_shape(name))

    # --- the skin: the jaw drops, cheeks lift or puff, a lip curls
    hy = float(f.head_point(0, 0, 0.5).y)

    def skin_shape(name):
        def fn(c):
            x, y, z = c
            if z < f.z_chin - 0.06 * s or z > f.face(0.62) or y > hy + 0.02 * s:
                return c
            u = (z - f.z_chin) / f.head_h
            ax = abs(x)
            if name in ("jaw_open", "v_aa", "v_oo", "v_ee"):
                amount = {"jaw_open": 1.0, "v_aa": 0.8, "v_oo": 0.45, "v_ee": 0.3}[name]
                below = _smooth((FACE["mouth_u"] - 0.01 - u) / 0.08)
                across = 1.0 - _smooth((ax - 0.040 * s) / (0.030 * s))
                w = below * across
                return Vector((x, y + 0.0020 * s * w * amount, z - 0.0110 * s * w * amount))
            if name in ("smile", "cheeks_puff", "sneer", "frown"):
                cheek = _smooth(1.0 - abs(u - 0.33) / 0.12) * _smooth(1.0 - abs(ax - 0.040 * s) / (0.025 * s))
                if name == "smile":
                    return Vector((x, y - 0.0008 * s * cheek, z + 0.0016 * s * cheek))
                if name == "cheeks_puff":
                    out = Vector((x, y, 0)).normalized() if ax > 1e-5 else Vector((0, -1, 0))
                    return c + (Vector((math.copysign(0.0035 * s, x), -0.0018 * s, 0)) * cheek)
                if name == "frown":
                    corner = _smooth(1.0 - abs(u - FACE["mouth_u"]) / 0.05) * _smooth(1.0 - abs(ax - 0.020 * s) / (0.012 * s))
                    return Vector((x, y, z - 0.0012 * s * corner))
                lip = _smooth(1.0 - abs(u - 0.27) / 0.06) * (1.0 if x < 0 else 0.0) * _smooth(1.0 - abs(ax - 0.012 * s) / (0.012 * s))
                return Vector((x, y - 0.0005 * s * lip, z + 0.0018 * s * lip))
            return c
        return fn

    skin_keys = ("jaw_open", "v_aa", "v_oo", "v_ee", "smile", "cheeks_puff", "sneer", "frown")
    base = np.array([v.co[:] for v in body.data.vertices], dtype=np.float32)
    moves = {}
    for name in skin_keys:
        k = add_key(body, name, skin_shape(name))
        after = np.zeros_like(base)
        k.data.foreach_get("co", after.ravel())
        moves[name] = after - base
    # beards and the lower hair ride the skin under them
    if riders:
        tree = KDTree(len(base))
        for i, c in enumerate(base):
            tree.insert(c, i)
        tree.balance()
        for o in riders:
            co = np.array([v.co[:] for v in o.data.vertices], dtype=np.float32)
            near = [tree.find_n(Vector(c), 4) for c in co]
            for name in skin_keys:
                move = np.zeros_like(co)
                for i, hits in enumerate(near):
                    wsum = 0.0
                    for (_, idx, dist) in hits:
                        if dist > 0.04:
                            continue
                        w = 1.0 / (dist + 1e-4)
                        move[i] += moves[name][idx] * w
                        wsum += w
                    if wsum > 0:
                        move[i] /= wsum
                if o.data.shape_keys is None:
                    o.shape_key_add(name="Basis", from_mix=False)
                k = o.shape_key_add(name=name, from_mix=False)
                k.data.foreach_set("co", (co + move).ravel())

    # --- the eyes: wide, narrowed, shut (about each eye's own middle)
    def eye_shape(name):
        factor = {"eyes_wide": 1.28, "eyes_narrow": 0.55, "blink": 0.06}[name]

        def fn(c):
            side = "L" if c.x > 0 else "R"
            mid = eye_centers.get(side, c)
            return Vector((c.x, c.y, mid.z + (c.z - mid.z) * factor))
        return fn

    for name in ("eyes_wide", "eyes_narrow", "blink"):
        add_key(eyes, name, eye_shape(name))

    # --- the brows
    def brow_shape(name):
        def fn(c):
            x, y, z = c
            inner = max(0.0, 1.0 - (abs(x) - 0.011 * s) / (0.050 * s))
            if name == "brows_up":
                return Vector((x, y, z + 0.0032 * s))
            if name == "brows_down":
                return Vector((x - math.copysign(0.0010 * s * inner, x), y, z - 0.0024 * s * inner - 0.0008 * s))
            return Vector((x, y, z + 0.0036 * s * inner * inner - 0.0007 * s * (1 - inner)))
        return fn

    for name in ("brows_up", "brows_down", "brows_worried"):
        add_key(brows, name, brow_shape(name))

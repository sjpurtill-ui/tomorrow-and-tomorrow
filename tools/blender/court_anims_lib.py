"""Court acting (K): the machinery the clip library is written with.

Clips are written in the same pose language as cf_anim (J's rig): a pose maps
a bone to {"rot": (x, y, z) degrees about the figure's own axes in the bone's
rest frame, "loc": (x, y, z) metres (hips only)}. Figure axes (Blender): +X is
the figure's left, -Y its front, +Z up. A bone's rotation is a delta carried
by its parent's delta, so a pose composes down each chain.

What this adds to cf_anim, so movement is acted rather than tweened:
  * Seq: key poses on a timeline, each reached with its own ease (in, out,
    snap, back = overshoot, settle = a damped spring). Overshoot extrapolates,
    so a bone can pass its key and come back.
  * Overlap: every bone samples the timeline a little late the farther it is
    from the hips (the head after the chest, the hand after the forearm), so
    motion rolls through the body and things drag and follow through.
  * Arms in target space: an arm key is a wrist position, an elbow pole and a
    hand direction (from IK, or read off an FK pose); between keys the wrist
    travels an arc (a bezier through a bulge) and the arm is solved each
    frame, so hands move in arcs and land exactly on a mouth, a chest, a hip.
    The forearm takes half of any wrist twist (no candy-wrapper wrists).
  * Planted feet: legs solved by two-bone IK from wherever the hips are to
    where the feet stand, so a body can dip, bow, sway and knock its knees
    without its feet skating.
  * Face channels (jaw, smile, tight, worry, stern, brows, lids, puff, sneer,
    eyes_x, eyes_y): keyed like the body and exported as curves in the
    library's JSON; the game drives the face from them (court_acting.gd).
"""
import math
from mathutils import Euler, Quaternion, Vector, Matrix

import cf_anim
from cf_anim import add, both, side, merge, wave, relaxed

FRAME = None          # cf_body.Frame of the body being written
K = 1.0               # FRAME.H / 1.72


def set_frame(f):
    global FRAME, K
    FRAME = f
    K = f.H / 1.72 if f is not None else 1.0
    cf_anim.FRAME = f


# --- small math -------------------------------------------------------------------

def Q(rot):
    return Euler([math.radians(a) for a in rot], 'XYZ').to_quaternion()


def R(q):
    e = q.to_euler('XYZ')
    return (math.degrees(e.x), math.degrees(e.y), math.degrees(e.z))


def qof(p, bone):
    e = p.get(bone)
    return Q(e["rot"]) if e and "rot" in e else Quaternion()


def mv(v, s):
    """A left-side vector put on side s."""
    return Vector((v[0] if s == "L" else -v[0], v[1], v[2]))


def mq(q, s):
    """A left-side rotation put on side s (mirror across the figure's midline)."""
    return q.copy() if s == "L" else Quaternion((q.w, q.x, -q.y, -q.z))


def clamp01(x):
    return 0.0 if x < 0.0 else (1.0 if x > 1.0 else x)


def lerp(a, b, u):
    return a + (b - a) * u


def lerp3(a, b, u):
    return (a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u, a[2] + (b[2] - a[2]) * u)


def basis_q(along, palm):
    """A rotation whose Y is `along` and Z is `palm` (orthonormalised)."""
    y = Vector(along).normalized()
    z = Vector(palm) - y * Vector(palm).dot(y)
    z = z.normalized() if z.length > 1e-6 else y.orthogonal().normalized()
    x = y.cross(z)
    return Matrix((x, y, z)).transposed().to_quaternion()


def twist_about(q, axis):
    """The twist part of q about a unit axis (swing-twist decomposition)."""
    a = Vector(axis).normalized()
    v = Vector((q.x, q.y, q.z))
    proj = a * v.dot(a)
    t = Quaternion((q.w, proj.x, proj.y, proj.z))
    if t.magnitude < 1e-8:
        return Quaternion()
    t.normalize()
    return t


def scale_q(q, k):
    axis, ang = q.to_axis_angle()
    if abs(ang) < 1e-9:
        return Quaternion()
    if ang > math.pi:
        ang -= 2 * math.pi
    return Quaternion(axis, ang * k)


# --- easing -----------------------------------------------------------------------

def curve(kind, x):
    """How a key is reached: 0..1 over the segment (overshooting kinds pass 1)."""
    x = clamp01(x)
    if kind == "linear":
        return x
    if kind == "ease":
        return 0.5 - 0.5 * math.cos(math.pi * x)
    if kind == "smooth":
        return x * x * x * (x * (6 * x - 15) + 10)
    if kind == "in":          # gathering speed: a fall, a drop
        return x * x
    if kind == "in3":
        return x * x * x
    if kind == "out":         # fast away, slowing in: most reaches
        return 1 - (1 - x) ** 2
    if kind == "out3":
        return 1 - (1 - x) ** 3
    if kind == "snap":        # a reflex: nearly all of it at once
        return 1 - (1 - x) ** 5
    if kind == "back":        # passes the key a little and comes back
        c1 = 1.70158
        c3 = c1 + 1
        return 1 + c3 * (x - 1) ** 3 + c1 * (x - 1) ** 2
    if kind == "back2":       # a bigger overshoot
        c1 = 2.6
        c3 = c1 + 1
        return 1 + c3 * (x - 1) ** 3 + c1 * (x - 1) ** 2
    if kind == "settle":      # a damped spring: over, under, still
        return 1 - math.exp(-6.5 * x) * math.cos(2.6 * math.pi * x) if x < 1 else 1.0
    if kind == "hold":
        return 0.0 if x < 1 else 1.0
    return 0.5 - 0.5 * math.cos(math.pi * x)


class Seq:
    """Keys on a timeline: [(t, value, kind)], kind is how the key is reached."""

    def __init__(self, keys, period=None):
        self.keys = [(k[0], k[1], k[2] if len(k) > 2 else "ease") + tuple(k[3:]) for k in keys]
        self.keys.sort(key=lambda k: k[0])
        self.period = period   # a loop: times wrap (so lagging bones close the loop too)

    def seg(self, t):
        if self.period:
            t = t % self.period
        ks = self.keys
        if t <= ks[0][0]:
            return ks[0], ks[0], 0.0
        for i in range(1, len(ks)):
            if t < ks[i][0]:
                a, b = ks[i - 1], ks[i]
                return a, b, curve(b[2], (t - a[0]) / max(b[0] - a[0], 1e-6))
        return ks[-1], ks[-1], 1.0

    def end(self):
        return self.keys[-1][0]


# How late each bone follows the hips (seconds): motion rolls up the body.
LAG = {
    "root": 0.0, "hips": 0.0, "spine": 0.018, "chest": 0.036, "neck": 0.060, "head": 0.080,
    "shoulder.L": 0.030, "shoulder.R": 0.030,
    "thigh.L": 0.0, "thigh.R": 0.0, "shin.L": 0.0, "shin.R": 0.0, "foot.L": 0.0, "foot.R": 0.0,
    "toe.L": 0.02, "toe.R": 0.02,
}
ARM_LAG = 0.045       # the wrist after the chest
HAND_LAG = 0.050      # the hand's turn after the wrist
FINGER_LAG = 0.080    # the fingers after the hand


def pose_seq(seq, t, drag=1.0, lags=None):
    """A pose sampled from a Seq of poses, each bone a little late (overlap)."""
    bones = set()
    for k in seq.keys:
        bones.update(k[1].keys())
    out = {}
    for bone in bones:
        lag = (lags or {}).get(bone, LAG.get(bone, 0.03)) * drag
        a, b, u = seq.seg(t - lag)
        ea, eb = a[1].get(bone, {}), b[1].get(bone, {})
        e = {}
        ra, rb = ea.get("rot"), eb.get("rot")
        if ra is not None or rb is not None:
            e["rot"] = lerp3(ra or (0, 0, 0), rb or (0, 0, 0), u)
        la, lb = ea.get("loc"), eb.get("loc")
        if la is not None or lb is not None:
            e["loc"] = lerp3(la or (0, 0, 0), lb or (0, 0, 0), u)
        out[bone] = e
    return out


def value_seq(seq, t, lag=0.0):
    """A dict of numbers (face channels, weights) sampled from a Seq."""
    a, b, u = seq.seg(t - lag)
    out = {}
    for key in set(a[1]) | set(b[1]):
        out[key] = lerp(a[1].get(key, DEFAULT_FACE.get(key, 0.0)), b[1].get(key, DEFAULT_FACE.get(key, 0.0)), u)
    return out


# --- the body's landmarks -----------------------------------------------------------

def hand_rest(s):
    """The hand's rest axes: along the fingers, and the way the palm faces."""
    f = FRAME
    along, front, out = f.hand_frame(s)
    palm = -out
    return along.normalized(), palm.normalized()


def landmarks():
    """Points on the body at rest that hands go to (figure axes, metres)."""
    f = FRAME
    s = f.head_h / 0.282
    oy = f.head_offset.y
    k = K
    belly = f.p.get("belly", 0.0)
    return {
        "mouth": Vector((0.0, -0.100 * s + oy, f.face(0.195))),
        "chin": Vector((0.0, -0.085 * s + oy, f.face(0.08))),
        "nose": Vector((0.0, -0.110 * s + oy, f.face(0.33))),
        "eyes": Vector((0.0, -0.098 * s + oy, f.face(0.47))),
        "brow": Vector((0.0, -0.092 * s + oy, f.face(0.60))),
        "crown": Vector((0.0, 0.010 * s + oy, f.face(0.97))),
        "cheek": Vector((0.060 * s, -0.070 * s + oy, f.face(0.32))),
        "ear": Vector((0.088 * s, 0.010 * s + oy, f.face(0.44))),
        "nape": Vector((0.0, 0.060 * s + oy, f.face(0.05))),
        "chest": Vector((0.0, -(f.p["chest_d"] + 0.010 * k) + f.chest.y, f.z_chest + 0.010 * k)),
        "heart": Vector((0.045 * k, -(f.p["chest_d"] + 0.008 * k) + f.chest.y, f.z_chest - 0.005 * k)),
        "belly": Vector((0.0, -(0.086 * k + 0.040 * belly * k) - 0.012 * k, f.z_waist - 0.030 * k)),
        "hip": Vector((f.p["pelvis"] * 0.98, -0.020 * k, f.z_hip + 0.105 * k)),
        "thigh": Vector((f.p["hip_joint"] * 1.05, -0.080 * k, f.z_hip - 0.150 * k)),
        "knee": Vector((f.p["hip_joint"] * 0.92, -0.060 * k, f.z_knee + 0.030 * k)),
    }


def chest_frame(p):
    """Where the chest is in a pose: (its head in figure axes, its delta)."""
    f = FRAME
    P = f.pelvis
    loc = Vector(p.get("hips", {}).get("loc", (0, 0, 0))) * K
    Qh, Qs, Qc = qof(p, "hips"), qof(p, "spine"), qof(p, "chest")
    spine_head = P + loc + Qh @ (f.waist - P)
    chest_head = spine_head + (Qh @ Qs) @ (f.chest - f.waist)
    return chest_head, Qh @ Qs @ Qc


def chest_space(p, w):
    """A point in the hall (figure axes) as the chest's rest frame sees it,
    so an arm can reach it while the body is bent, sunk or turned."""
    head, D = chest_frame(p)
    return FRAME.chest + D.inverted() @ (Vector(w) - head)


def chest_dir(p, d):
    head, D = chest_frame(p)
    return D.inverted() @ Vector(d)


def chest_to_world(p, w):
    """A point in the chest's rest frame, where it is in the hall in pose p."""
    head, D = chest_frame(p)
    return head + D @ (Vector(w) - FRAME.chest)


def world_key(p, key):
    """An ArmKey written in the hall (figure axes) for a body posed as p,
    turned into the chest frame the arm solver works in."""
    return ArmKey(chest_space(p, key.w), chest_dir(p, key.pole), chest_dir(p, key.along), chest_dir(p, key.palm),
                  key.curl, key.sh, key.arc)


def key_to_world(p, key):
    """The other way: an ArmKey in the chest frame, as it lies in the hall in pose p."""
    head, D = chest_frame(p)
    return ArmKey(chest_to_world(p, key.w), D @ key.pole, D @ key.along, D @ key.palm, key.curl, key.sh, key.arc)


def place_hand(contact, along, palm, reach=0.45, off=0.016):
    """Where the wrist goes so the palm's middle rests on `contact`."""
    along = Vector(along).normalized()
    palm = Vector(palm).normalized()
    centre = Vector(contact) - palm * (off * K)
    return centre - along * (FRAME.hand_len * reach)


# --- arms ---------------------------------------------------------------------------

class ArmKey:
    """Where one arm is: the wrist, the elbow's way out (pole), where the
    fingers point and the palm faces, how curled the hand is, the shoulder's
    own rotation (a shrug, a hunch) and, for the segment into this key, the
    bulge of the wrist's arc."""

    def __init__(self, w, pole, along, palm, curl=(30.0, 22.0, 10.0), sh=(0.0, 0.0, 0.0), arc=None):
        self.w = Vector(w)
        self.pole = Vector(pole).normalized()
        self.along = Vector(along).normalized()
        self.palm = Vector(palm).normalized()
        self.curl = tuple(curl)
        self.sh = tuple(sh)
        self.arc = Vector(arc) if arc is not None else None

    def copy(self, **kw):
        k = ArmKey(self.w, self.pole, self.along, self.palm, self.curl, self.sh, self.arc)
        for name, val in kw.items():
            if name in ("w", "pole", "along", "palm", "arc") and val is not None:
                val = Vector(val)
                if name in ("pole", "along", "palm"):
                    val = val.normalized()
            setattr(k, name, val)
        return k


def arm_fk(p, s):
    """An ArmKey read off a pose's arm rotations (side s)."""
    f = FRAME
    C, S, E0, W0 = f.clavicle[s], f.shoulder[s], f.elbow[s], f.wrist[s]
    Qs, Qu, Qf, Qh = qof(p, "shoulder." + s), qof(p, "upper_arm." + s), qof(p, "forearm." + s), qof(p, "hand." + s)
    S1 = C + Qs @ (S - C)
    U = Qs @ Qu
    E1 = S1 + U @ (E0 - S)
    F = U @ Qf
    W1 = E1 + F @ (W0 - E0)
    H = F @ Qh
    a0, p0 = hand_rest(s)
    axis = (W1 - S1)
    perp = (E1 - S1) - axis.normalized() * (E1 - S1).dot(axis.normalized())
    pole = perp if perp.length > 1e-5 else mv((0.6, 0.6, -0.5), s)
    sg = 1.0 if s == "L" else -1.0

    def curl(bone):
        e = p.get(bone + "." + s)
        return (e["rot"][1] * sg) if e and "rot" in e else 0.0
    sh = p.get("shoulder." + s, {}).get("rot", (0.0, 0.0, 0.0))
    sh = sh if s == "L" else (sh[0], -sh[1], -sh[2])
    return ArmKey(W1, pole, H @ a0, H @ p0, (curl("fingers"), curl("index"), curl("thumb")), sh)


def arm_solve(s, key, twist_share=0.5):
    """Pose entries for one arm reaching an ArmKey (shoulder, upper arm,
    forearm, hand, fingers)."""
    f = FRAME
    C, S, E0, W0 = f.clavicle[s], f.shoulder[s], f.elbow[s], f.wrist[s]
    sh = key.sh if s == "L" else (key.sh[0], -key.sh[1], -key.sh[2])
    Qs = Q(sh)
    S1 = C + Qs @ (S - C)
    a = (E0 - S).length
    b = (W0 - E0).length
    T = Vector(key.w)
    d = (T - S1).length
    d = max(min(d, a + b - 0.0015), abs(a - b) + 0.01)
    u = (T - S1).normalized()
    T = S1 + u * d
    cos_a = max(-1.0, min(1.0, (a * a + d * d - b * b) / (2 * a * d)))
    sin_a = math.sqrt(max(0.0, 1.0 - cos_a * cos_a))
    v = key.pole - u * key.pole.dot(u)
    v = v.normalized() if v.length > 1e-6 else mv((0.0, 0.3, -1.0), s).normalized()
    E = S1 + u * (a * cos_a) + v * (a * sin_a)
    up0 = Qs @ (E0 - S)
    U = up0.normalized().rotation_difference((E - S1).normalized()) @ Qs
    fo0 = U @ (W0 - E0)
    F = fo0.normalized().rotation_difference((T - E).normalized()) @ U
    a0, p0 = hand_rest(s)
    D = basis_q(key.along, key.palm) @ basis_q(a0, p0).inverted()
    Qu = Qs.inverted() @ U
    Qf = U.inverted() @ F
    Qh = F.inverted() @ D
    # the forearm turns with the hand (pronation), sharing the wrist's twist
    tw = twist_about(Qh, (W0 - E0).normalized())
    part = scale_q(tw, twist_share)
    Qf = Qf @ part
    Qh = part.inverted() @ Qh
    out = {}
    out["shoulder." + s] = {"rot": sh}
    out["upper_arm." + s] = {"rot": R(Qu)}
    out["forearm." + s] = {"rot": R(Qf)}
    out["hand." + s] = {"rot": R(Qh)}
    sg = 1.0 if s == "L" else -1.0
    c = key.curl
    out["fingers." + s] = {"rot": (0.0, c[0] * sg, 0.0)}
    out["index." + s] = {"rot": (0.0, c[1] * sg, 0.0)}
    out["thumb." + s] = {"rot": (0.0, c[2] * sg, 0.0)}
    return out


def _bezier(a, c, b, u):
    return a * ((1 - u) ** 2) + c * (2 * u * (1 - u)) + b * (u * u)


class ArmSeq:
    """Arm keys on a timeline; the wrist travels arcs between them."""

    def __init__(self, s, keys):
        self.s = s
        self.seq = Seq(keys)

    def at(self, t, drag=1.0):
        s = self.s
        a, b, u = self.seq.seg(t - ARM_LAG * drag)
        ka, kb = a[1], b[1]
        mid = (ka.w + kb.w) * 0.5
        if kb.arc is not None and ka is not kb:
            ctrl = mid + mv(kb.arc, s) * K
        else:
            ctrl = mid
        uu = u
        w = _bezier(ka.w, ctrl, kb.w, uu) if 0.0 <= uu <= 1.0 else ka.w.lerp(kb.w, uu)
        pole = ka.pole.lerp(kb.pole, clamp01(u))
        sh = lerp3(ka.sh, kb.sh, u)
        # the hand turns a beat after the wrist arrives, the fingers after that
        a2, b2, u2 = self.seq.seg(t - (ARM_LAG + HAND_LAG) * drag)
        qa = basis_q(a2[1].along, a2[1].palm)
        qb = basis_q(b2[1].along, b2[1].palm)
        if qa.dot(qb) < 0:
            qb = -qb
        qh = qa.slerp(qb, u2) if 0 <= u2 <= 1 else scale_q(qb @ qa.inverted(), u2) @ qa
        along = qh @ Vector((0, 1, 0))
        palm = qh @ Vector((0, 0, 1))
        a3, b3, u3 = self.seq.seg(t - (ARM_LAG + FINGER_LAG) * drag)
        curl = lerp3(a3[1].curl, b3[1].curl, u3)
        return arm_solve(s, ArmKey(w, pole, along, palm, curl, sh))


def arm_at(s, contact=None, along=None, palm=None, w=None, pole=None, curl=(30, 22, 10), sh=(0, 0, 0), arc=None, reach=0.45, off=0.016):
    """An ArmKey written in left-side terms and put on side s: either a wrist
    position w, or a contact point the palm rests on."""
    along = mv(along, s)
    palm = mv(palm, s)
    if w is None:
        w = place_hand(mv(contact, s), along, palm, reach, off)
    else:
        w = mv(w, s)
    pole = mv(pole if pole is not None else (0.7, 0.5, -0.4), s)
    return ArmKey(w, pole, along, palm, curl, sh, arc)


# --- legs ---------------------------------------------------------------------------

def leg_rest():
    f = FRAME
    return {s: (f.hip[s], f.knee[s], f.ankle[s]) for s in "LR"}


def legs_fk(p):
    """Where the ankles and knees are in a pose (figure axes)."""
    f = FRAME
    Qh = qof(p, "hips")
    loc = Vector(p.get("hips", {}).get("loc", (0, 0, 0))) * K
    P = f.pelvis
    out = {}
    for s in "LR":
        H, Kn, A = f.hip[s], f.knee[s], f.ankle[s]
        H1 = P + loc + Qh @ (H - P)
        T = Qh @ qof(p, "thigh." + s)
        K1 = H1 + T @ (Kn - H)
        Sh = T @ qof(p, "shin." + s)
        A1 = K1 + Sh @ (A - Kn)
        Ft = Sh @ qof(p, "foot." + s)
        out[s] = (A1, K1, Ft)
    return out


def plant(p, feet, knees=None, foot_rot=None):
    """Legs solved from where the hips are to where the feet stand: feet
    {side: ankle position}, knees {side: direction the knee points}, foot_rot
    {side: the foot's own rotation in figure axes (heel up, toe out)}."""
    f = FRAME
    Qh = qof(p, "hips")
    loc = Vector(p.get("hips", {}).get("loc", (0, 0, 0))) * K
    P = f.pelvis
    for s in "LR":
        if s not in feet:
            continue
        H, Kn0, A0 = f.hip[s], f.knee[s], f.ankle[s]
        H1 = P + loc + Qh @ (H - P)
        a = (Kn0 - H).length
        b = (A0 - Kn0).length
        T = Vector(feet[s])
        d = (T - H1).length
        d = max(min(d, a + b - 0.0008), abs(a - b) + 0.01)
        u = (T - H1).normalized()
        T = H1 + u * d
        cos_a = max(-1.0, min(1.0, (a * a + d * d - b * b) / (2 * a * d)))
        sin_a = math.sqrt(max(0.0, 1.0 - cos_a * cos_a))
        kd = Vector(knees[s]) if knees and s in knees else mv((0.08, -1.0, 0.0), s)
        v = kd - u * kd.dot(u)
        v = v.normalized() if v.length > 1e-6 else Vector((0, -1, 0))
        Kn = H1 + u * (a * cos_a) + v * (a * sin_a)
        th0 = Qh @ (Kn0 - H)
        Tq = th0.normalized().rotation_difference((Kn - H1).normalized()) @ Qh
        sh0 = Tq @ (A0 - Kn0)
        Sq = sh0.normalized().rotation_difference((T - Kn).normalized()) @ Tq
        want = Q(foot_rot[s]) if foot_rot and s in foot_rot else Quaternion()
        p["thigh." + s] = {"rot": R(Qh.inverted() @ Tq)}
        p["shin." + s] = {"rot": R(Tq.inverted() @ Sq)}
        p["foot." + s] = {"rot": R(Sq.inverted() @ want)}
    return p


# --- face ---------------------------------------------------------------------------

# Channel: rest value. jaw 0 shut..1 wide; smile/tight/worry/stern/puff/sneer/
# frown 0..1; brows -1 (down hard) .. +1 (up); lids 0 shut, 1 as they rest, 1.35
# wide; eyes_x -1 (to its right) .. +1 (to its left), eyes_y -1 down .. +1 up.
DEFAULT_FACE = {"jaw": 0.0, "smile": 0.0, "tight": 0.0, "worry": 0.0, "stern": 0.0, "brows": 0.0,
                "lids": 1.0, "puff": 0.0, "sneer": 0.0, "eyes_x": 0.0, "eyes_y": 0.0, "frown": 0.0}


def face(**kw):
    out = {}
    for k, v in kw.items():
        if k not in DEFAULT_FACE:
            raise KeyError("no face channel " + k)
        out[k] = float(v)
    return out


# --- life on top of a key pose ------------------------------------------------------

def tremble(t, amount, rate=1.0, seed=0.0):
    """Small fast shaking (fear, cold, a laugh held in): a pose to merge."""
    if amount <= 0:
        return {}
    a = amount
    n1 = math.sin(2 * math.pi * (9.1 * rate * t + seed)) * 0.6 + math.sin(2 * math.pi * (13.7 * rate * t + 0.3 + seed)) * 0.4
    n2 = math.sin(2 * math.pi * (7.3 * rate * t + 0.6 + seed)) * 0.6 + math.sin(2 * math.pi * (11.9 * rate * t + 0.1 + seed)) * 0.4
    p = {}
    add(p, "chest", rot=(0.5 * a * n1, 0, 0.4 * a * n2))
    add(p, "head", rot=(0.9 * a * n2, 0, 0.8 * a * n1))
    both(p, "shoulder", rot=(0, 1.0 * a * n1, 0))
    both(p, "hand", rot=(1.6 * a * n2, 0, 1.2 * a * n1))
    return p


def drift(t, amount, period=2.6, seed=0.0):
    """A moving hold: the body never quite stops in a held pose."""
    if amount <= 0:
        return {}
    p = {}
    add(p, "spine", rot=(0.6 * amount * wave(t, period, seed), 0, 0.5 * amount * wave(t, period * 1.37, seed + 0.2)))
    add(p, "head", rot=(1.0 * amount * wave(t, period * 0.83, seed + 0.4), 0.6 * amount * wave(t, period * 1.21, seed), 1.2 * amount * wave(t, period * 1.13, seed + 0.7)))
    return p


def breathe(t, period=3.4, amount=1.0, phase=0.0):
    """Breathing that rides on any key pose (chest, shoulders, head)."""
    b = wave(t, period, phase) * amount
    p = {}
    add(p, "spine", rot=(-0.6 * b, 0, 0))
    add(p, "chest", rot=(-1.0 * b, 0, 0))
    add(p, "neck", rot=(0.5 * b, 0, 0))
    add(p, "head", rot=(0.6 * b, 0, 0))
    both(p, "shoulder", rot=(0, -0.8 * b, 0))
    return p


def pulses(t, start, period, count, decay=0.75, shape=2.0):
    """A run of beats from `start` (a laugh's ha-ha-ha, a sob, a shiver):
    0..1, each beat a sharp rise and a softer fall, each smaller."""
    if t < start:
        return 0.0
    x = (t - start) / period
    i = int(x)
    if i >= count:
        return 0.0
    fr = x - i
    beat = math.sin(math.pi * min(1.0, fr * 1.25)) ** shape if fr < 0.8 else 0.0
    return beat * (decay ** i)

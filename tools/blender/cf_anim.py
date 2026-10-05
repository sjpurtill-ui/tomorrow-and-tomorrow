"""Court figures: the clips.

Each clip is a function of time returning a pose; it is sampled every frame
into its own action, so loops close exactly. A pose maps a bone to a dict:
  rot: (x, y, z) degrees about the figure's own axes in the bone's rest frame
       (X: its left, so +X pitches a bone that points up forward; Y: its back;
       Z: up, so +Z turns it to its left);
  loc: (x, y, z) metres in the figure's axes (hips only, mostly);
  open: scale across the figure's vertical (jaw: the mouth; eyes: the lids);
  lift: metres up (brows).
Left-side poses mirror to the right with mirror(); clips write both sides.

Clips (loop or not):
  a stance each person keeps for life, and the same stance talking (loops):
    stand, hip, folded, clasped, belt, staff, bowl, sit, crouch, and
    <stance>_talk (talking with whichever hands are free);
  talk_both (loop: pleading or insisting with both hands);
  bow, kneel, point, raise_hand (play once and hold the last frame);
  walk_in, walk_out (loops, in place: the stage moves the figure).
Where a head turns (to whoever speaks, up to the god) the game turns it.
"""
import math
import bpy
from mathutils import Euler, Quaternion, Vector

FPS = 30
STANCES = ("stand", "hip", "folded", "clasped", "belt", "staff", "bowl", "sit", "crouch")
LOOP_CLIPS = STANCES + tuple(st + "_talk" for st in STANCES) + ("talk_both", "walk_in", "walk_out")
ARM_BONES = ("shoulder", "upper_arm", "forearm", "hand", "fingers", "index", "thumb")
# The hands each stance leaves free to talk with.
FREE_HANDS = {"stand": "LR", "hip": "R", "folded": "", "clasped": "LR", "belt": "R", "staff": "L", "bowl": "", "sit": "LR", "crouch": "R"}


# --- helpers ---------------------------------------------------------------------

def sm(x):
    x = max(0.0, min(1.0, x))
    return x * x * (3.0 - 2.0 * x)


def ease(t, a, b):
    """0 before a, 1 after b, smooth between."""
    return sm((t - a) / max(b - a, 1e-6))


def env(t, a, b, c, d):
    """Rises a..b, holds, falls c..d."""
    return ease(t, a, b) * (1.0 - ease(t, c, d))


def wave(t, period, phase=0.0):
    return math.sin(2.0 * math.pi * (t / period + phase))


def blink(t, times, dur=0.16):
    """Lid opening (1 open, 0.08 shut) for blinks at the given times."""
    o = 1.0
    for b in times:
        x = (t - b) / dur
        if 0.0 <= x <= 1.0:
            o = min(o, 1.0 - 0.92 * math.sin(math.pi * x))
    return o


def add(pose, bone, rot=None, loc=None, open_=None, lift=None):
    e = pose.setdefault(bone, {})
    if rot is not None:
        r = e.get("rot", (0.0, 0.0, 0.0))
        e["rot"] = (r[0] + rot[0], r[1] + rot[1], r[2] + rot[2])
    if loc is not None:
        l = e.get("loc", (0.0, 0.0, 0.0))
        e["loc"] = (l[0] + loc[0], l[1] + loc[1], l[2] + loc[2])
    if open_ is not None:
        e["open"] = e.get("open", 1.0) * open_
    if lift is not None:
        e["lift"] = e.get("lift", 0.0) + lift
    return pose


def both(pose, bone, rot=None, loc=None, open_=None, lift=None):
    """The same on the left, mirrored on the right."""
    add(pose, bone + ".L", rot=rot, loc=loc, open_=open_, lift=lift)
    if rot is not None:
        rot = (rot[0], -rot[1], -rot[2])
    if loc is not None:
        loc = (-loc[0], loc[1], loc[2])
    add(pose, bone + ".R", rot=rot, loc=loc, open_=open_, lift=lift)
    return pose


def side(pose, bone, s, rot=None, loc=None):
    """A left-side pose on side s ('L' or 'R'), mirrored when R."""
    if s == "R":
        if rot is not None:
            rot = (rot[0], -rot[1], -rot[2])
        if loc is not None:
            loc = (-loc[0], loc[1], loc[2])
    return add(pose, bone + "." + s, rot=rot, loc=loc)


def mix(a, b, t):
    """Blend two poses (missing entries count as rest)."""
    out = {}
    for bone in set(a) | set(b):
        ea, eb = a.get(bone, {}), b.get(bone, {})
        e = {}
        ra, rb = ea.get("rot", (0, 0, 0)), eb.get("rot", (0, 0, 0))
        e["rot"] = tuple(ra[i] * (1 - t) + rb[i] * t for i in range(3))
        la, lb = ea.get("loc", (0, 0, 0)), eb.get("loc", (0, 0, 0))
        e["loc"] = tuple(la[i] * (1 - t) + lb[i] * t for i in range(3))
        e["open"] = ea.get("open", 1.0) * (1 - t) + eb.get("open", 1.0) * t
        e["lift"] = ea.get("lift", 0.0) * (1 - t) + eb.get("lift", 0.0) * t
        out[bone] = e
    return out


def merge(*poses):
    out = {}
    for p in poses:
        for bone, e in p.items():
            add(out, bone, rot=e.get("rot"), loc=e.get("loc"), open_=e.get("open"), lift=e.get("lift"))
    return out


# --- base stances ------------------------------------------------------------------

def relaxed(k=1.0):
    """Standing easy: weight on the right leg, the left knee soft, the hip
    out, shoulders tilted against it, elbows soft, hands loose."""
    p = {}
    add(p, "hips", rot=(0, 7.0, -6), loc=(-0.034, 0.0, -0.014))
    add(p, "thigh.R", rot=(0, -7.0, 4))
    add(p, "thigh.L", rot=(-9, -7.0, 8))
    add(p, "shin.L", rot=(22, 0, 0))
    add(p, "foot.L", rot=(-6, 0, 0))
    add(p, "spine", rot=(1, -3.5, 3))
    add(p, "chest", rot=(1, -4.0, 4))
    add(p, "neck", rot=(0, 1.5, -3))
    add(p, "head", rot=(2, 5.0, -6))
    both(p, "shoulder", rot=(0, 3, 0))
    both(p, "upper_arm", rot=(3, 15, -4))
    side(p, "forearm", "R", rot=(-16, 0, 0))
    side(p, "forearm", "L", rot=(-26, 2, 0))
    both(p, "hand", rot=(0, 4, 8))
    both(p, "fingers", rot=(0, 32, 0))
    both(p, "index", rot=(0, 22, 0))
    both(p, "thumb", rot=(0, 10, 0))
    add(p, "jaw", open_=1.0)
    return p


# The body the clips are being written for (set by write_actions); stances
# that put a hand on the body reach for it with two-bone IK on its own measure.
FRAME = None


def arm_ik(p, s_, wrist, pole):
    """Points the arm on side s_ so the wrist lands at `wrist` (figure axes,
    metres), the elbow bending toward `pole`; replaces that arm's rotations."""
    f = FRAME
    if f is None:
        return p
    S, E0, W0 = f.shoulder[s_], f.elbow[s_], f.wrist[s_]
    a, b = (E0 - S).length, (W0 - E0).length
    T = Vector(wrist)
    d = min((T - S).length, a + b - 0.002)
    u = (T - S).normalized()
    T = S + u * d
    cos_a = max(-1.0, min(1.0, (a * a + d * d - b * b) / (2 * a * d)))
    sin_a = math.sqrt(max(0.0, 1.0 - cos_a * cos_a))
    v = Vector(pole) - u * Vector(pole).dot(u)
    v = v.normalized() if v.length > 1e-6 else Vector((0, 0, -1))
    E = S + u * (a * cos_a) + v * (a * sin_a)
    q1 = (E0 - S).normalized().rotation_difference((E - S).normalized())
    q2 = (W0 - E0).normalized().rotation_difference(q1.inverted() @ (T - E).normalized())
    p["upper_arm." + s_] = {"rot": tuple(math.degrees(x) for x in q1.to_euler('XYZ'))}
    p["forearm." + s_] = {"rot": tuple(math.degrees(x) for x in q2.to_euler('XYZ'))}
    p["shoulder." + s_] = {"rot": (0.0, 0.0, 0.0)}
    return p


def _mirror_x(v, s_):
    return (v[0] if s_ == "L" else -v[0], v[1], v[2])


def stance_pose(name):
    """The body of a stance at rest (no breathing)."""
    p = relaxed()
    f = FRAME
    k = f.H / 1.72 if f else 1.0
    if name == "hip" and f:
        arm_ik(p, "L", (f.p["pelvis"] * 0.98, -0.020 * k, f.z_hip + 0.105 * k), (1.0, 0.8, 0.0))
        side(p, "hand", "L", rot=(-30, 30, -60))
        side(p, "fingers", "L", rot=(0, -12, 0))
        side(p, "index", "L", rot=(0, -10, 0))
    elif name == "folded":
        if f:
            front = -(f.p["chest_d"] + 0.050 * k)
            arm_ik(p, "L", (-0.075 * k, front, f.z_chest - 0.045 * k), (0.6, -0.2, -1.0))
            arm_ik(p, "R", (0.080 * k, front + 0.012, f.z_chest - 0.085 * k), (-0.6, -0.2, -1.0))
        both(p, "hand", rot=(0, 0, 22))
        both(p, "fingers", rot=(0, 12, 0))
        add(p, "chest", rot=(-2, 0, 0))
        add(p, "head", rot=(-3, 0, 0))
    elif name == "clasped":
        if f:
            for s_ in "LR":
                arm_ik(p, s_, _mirror_x((0.030 * k, -(f.p["waist"] * 0.80 + 0.050 * k), f.z_hip + 0.050 * k), s_), _mirror_x((1.0, 0.3, -0.6), s_))
        both(p, "hand", rot=(4, -4, 16))
        both(p, "fingers", rot=(0, 8, 0))
        both(p, "index", rot=(0, 12, 0))
        both(p, "thumb", rot=(0, 10, 0))
    elif name == "belt":
        if f:
            for s_ in "LR":
                arm_ik(p, s_, _mirror_x((f.p["waist"] * 0.85, -(0.070 * k), f.z_waist - 0.035 * k), s_), _mirror_x((1.0, 0.5, -0.3), s_))
        both(p, "hand", rot=(-10, 6, 24))
        both(p, "fingers", rot=(0, 13, 0))
        both(p, "thumb", rot=(0, -30, 0))
    elif name == "staff":
        if f:
            arm_ik(p, "R", (-0.215 * k, -0.150 * k, f.z_waist + 0.140 * k), (-0.8, 0.5, -0.6))
        side(p, "hand", "R", rot=(0, -18, 72))
        side(p, "fingers", "R", rot=(0, 52, 0))
        side(p, "index", "R", rot=(0, 62, 0))
        side(p, "thumb", "R", rot=(0, 30, 0))
    elif name == "bowl":
        if f:
            for s_ in "LR":
                arm_ik(p, s_, _mirror_x((0.085 * k, -(f.p["waist"] + 0.120 * k), f.z_waist + 0.020 * k), s_), _mirror_x((1.0, 0.2, -0.8), s_))
        both(p, "hand", rot=(10, 0, 70))
        both(p, "fingers", rot=(0, -10, 0))
        both(p, "index", rot=(0, -8, 0))
        both(p, "thumb", rot=(0, -12, 0))
        add(p, "head", rot=(4, 0, 0))
    elif name == "sit":
        p = {}
        add(p, "hips", rot=(-6, 0, 0), loc=(0.0, 0.050, -0.395))
        both(p, "thigh", rot=(-88, -6, 0))
        both(p, "shin", rot=(90, 0, 0))
        both(p, "foot", rot=(-4, 0, 0))
        add(p, "spine", rot=(9, 0, 0))
        add(p, "chest", rot=(5, 0, 2))
        add(p, "neck", rot=(-4, 0, 0))
        add(p, "head", rot=(-5, 2, -3))
        both(p, "shoulder", rot=(0, 3, 0))
        both(p, "upper_arm", rot=(-30, 14, -10))
        both(p, "forearm", rot=(-44, 0, 0))
        both(p, "hand", rot=(16, 0, 34))
        both(p, "fingers", rot=(0, 26, 0))
        both(p, "index", rot=(0, 20, 0))
        add(p, "jaw", open_=1.0)
    elif name == "crouch":
        p = {}
        add(p, "hips", rot=(10, 0, 0), loc=(0.0, 0.110, -0.470))
        both(p, "thigh", rot=(-124, -12, 0))
        both(p, "shin", rot=(140, 0, 0))
        both(p, "foot", rot=(-14, 0, 0))
        both(p, "toe", rot=(-20, 0, 0))
        add(p, "spine", rot=(16, 0, 0))
        add(p, "chest", rot=(10, 0, 0))
        add(p, "neck", rot=(-12, 0, 0))
        add(p, "head", rot=(-14, 0, 0))
        both(p, "shoulder", rot=(-4, 3, 0))
        both(p, "upper_arm", rot=(-54, 10, -14))
        both(p, "forearm", rot=(-34, 0, 0))
        both(p, "hand", rot=(24, 0, 10))
        both(p, "fingers", rot=(0, 30, 0))
        add(p, "jaw", open_=1.0)
    return p


def clip_stance(name, t):
    T = 6.0
    seed = STANCES.index(name) * 0.13
    p = stance_pose(name)
    parts = [p, breath(t, 3.0 + seed, 1.0), eyes(t, (1.4 + seed, 4.6 - seed)),
             {"head": {"rot": (1.2 * wave(t, T, 0.1 + seed), 0, 2.2 * wave(t, T, 0.3 + seed))}}]
    if name not in ("sit", "crouch"):
        parts.append(weight_shift(t, T, 0.45))
    else:
        parts.append({"spine": {"rot": (0.8 * wave(t, T, seed), 0, 1.0 * wave(t, T, 0.5 + seed))}})
    return merge(*parts)


def talk_upper(t, sides, amount=1.0):
    """Talking: both hands loose and open before the body, beating on the
    words out of step with each other; shoulders, chest and head in it."""
    T = 4.0
    p = {}
    for s_, ph, k in (("R", 0.0, 1.0), ("L", 0.37, 0.75)):
        if s_ not in sides:
            continue
        b = 0.5 + 0.5 * wave(t, T / 3.0, ph)
        sw = wave(t, T / 2.0, ph + 0.2)
        side(p, "shoulder", s_, rot=(-2.0 * b * k, 2.0 + 3.0 * b * k, 0))
        side(p, "upper_arm", s_, rot=(-12 - 14 * b * k * amount, 13 + 5 * sw * k, -20))
        side(p, "forearm", s_, rot=(-60 - 24 * b * k * amount, -4, 0))
        side(p, "hand", s_, rot=(10 + 12 * b, -2, 48 + 18 * sw))
        side(p, "fingers", s_, rot=(0, -20 + 12 * b, 0))
        side(p, "index", s_, rot=(0, -16 + 10 * b, 0))
        side(p, "thumb", s_, rot=(0, -14, 0))
    beat = 0.5 + 0.5 * wave(t, T / 3.0, 0.1)
    add(p, "spine", rot=(1.5 * beat * amount, 0, 2.0 * wave(t, T / 2.0, 0.3)))
    add(p, "chest", rot=(2.0 + 1.5 * beat, 0, 3.0 * wave(t, T / 2.0, 0.4)))
    nod = max(0.0, wave(t, T / 3.0, 0.15)) ** 1.5
    add(p, "neck", rot=(2.0 * nod, 0, 0))
    add(p, "head", rot=(5.0 * nod - 1.5, 3.5 * wave(t, T, 0.25), 4.0 * wave(t, T / 2.0, 0.6)))
    both(p, "brow", lift=0.0030 * beat)
    return p


def _over(base, over, sides):
    """The stance, with the talking arms taking over the free hands and the
    rest of the talking added on top."""
    out = {k: dict(v) for k, v in base.items()}
    for bone, e in over.items():
        root = bone.split(".")[0]
        if root in ARM_BONES:
            if bone.split(".")[-1] in sides:
                out[bone] = dict(e)
        else:
            add(out, bone, rot=e.get("rot"), loc=e.get("loc"), open_=e.get("open"), lift=e.get("lift"))
    return out


def clip_stance_talk(name, t):
    sides = FREE_HANDS[name]
    base = stance_pose(name)
    body = _over(base, talk_upper(t, sides if sides else "", 1.0), sides)
    parts = [body, breath(t, 4.0, 0.6), _mouth(t, 1.0, 1.15), eyes(t, (2.6,))]
    if name not in ("sit", "crouch"):
        parts.append(weight_shift(t, 4.0, 0.4))
    if not sides:
        # hands busy: the head and shoulders carry it
        parts.append({"head": {"rot": (3.0 * max(0.0, wave(t, 1.33, 0.1)), 0, 0)}, "chest": {"rot": (1.5, 0, 0)}})
    return merge(*parts)


def breath(t, period=3.2, amount=1.0):
    p = {}
    b = wave(t, period) * amount
    add(p, "spine", rot=(-0.8 * b, 0, 0))
    add(p, "chest", rot=(-1.1 * b, 0, 0))
    add(p, "neck", rot=(0.6 * b, 0, 0))
    add(p, "head", rot=(0.8 * b, 0, 0))
    both(p, "shoulder", rot=(0, -0.9 * b, 0))
    both(p, "upper_arm", rot=(0, 0.6 * b, 0))
    return p


def eyes(t, times):
    p = {}
    o = blink(t, times)
    add(p, "eye.L", open_=o)
    add(p, "eye.R", open_=o)
    return p


def weight_shift(t, period, amount=1.0):
    """Weight moving from foot to foot and back."""
    s = wave(t, period) * amount
    p = {}
    add(p, "hips", rot=(0, 1.6 * s, 1.2 * s), loc=(0.010 * s, 0, -0.004 * abs(s)))
    add(p, "spine", rot=(0, -1.0 * s, -0.5 * s))
    add(p, "chest", rot=(0, -0.8 * s, -0.4 * s))
    add(p, "head", rot=(0, 0.6 * s, 0.3 * s))
    # the legs stay planted: the thighs undo the hips' tilt
    add(p, "thigh.L", rot=(0, -1.6 * s, -1.2 * s))
    add(p, "thigh.R", rot=(0, -1.6 * s, -1.2 * s))
    add(p, "shin.L", rot=(3.0 * max(-s, 0), 0, 0))
    add(p, "thigh.L", rot=(-1.5 * max(-s, 0), 0, 0))
    add(p, "shin.R", rot=(3.0 * max(s, 0), 0, 0))
    add(p, "thigh.R", rot=(-1.5 * max(s, 0), 0, 0))
    return p


# --- clips -------------------------------------------------------------------------

def clip_idle(t):
    T = 6.0
    return merge(relaxed(), breath(t, 3.0), weight_shift(t, T, 1.0), eyes(t, (1.4, 4.6)),
                 {"head": {"rot": (1.5 * wave(t, T, 0.1), 0, 2.5 * wave(t, T, 0.3))}})


def clip_idle_clasped(t):
    """An official at rest: hands clasped before the belly."""
    T = 6.0
    p = {}
    both(p, "shoulder", rot=(-4, 4, 0))
    both(p, "upper_arm", rot=(3, 19, -44))
    both(p, "forearm", rot=(-84, 0, 0))
    both(p, "hand", rot=(4, 0, 16))
    both(p, "fingers", rot=(0, 40, 0))
    both(p, "index", rot=(0, 34, 0))
    both(p, "thumb", rot=(0, 20, 0))
    return merge(p, breath(t, 3.0), weight_shift(t, T, 0.8), eyes(t, (2.0, 5.1)),
                 {"head": {"rot": (2.0 + 1.0 * wave(t, T, 0.2), 0, 2.0 * wave(t, T, 0.45))}})


def _mouth(t, rate=1.0, amount=1.0, seed=0.0):
    """Lips moving with speech: syllables in uneven runs, with pauses."""
    a = wave(t * rate, 0.21, seed) * 0.5 + 0.5
    b = wave(t * rate, 0.33, seed + 0.3) * 0.5 + 0.5
    c = wave(t * rate, 1.7, seed + 0.1) * 0.5 + 0.5
    phrase = sm((c - 0.15) / 0.35)
    o = 0.55 + amount * phrase * (1.7 * a * (0.5 + 0.5 * b))
    return {"jaw": {"open": o}}


def clip_talk(t):
    """Speaking with the right hand: it comes up open before the chest and
    beats on the words; the head nods with them and the body leans in."""
    T = 4.0
    p = relaxed()
    beat = 0.5 + 0.5 * wave(t, T / 4.0, 0.0)
    swing = wave(t, T / 2.0, 0.15)
    side(p, "shoulder", "R", rot=(-4, 4, 0))
    side(p, "upper_arm", "R", rot=(-30 - 8 * beat, 10 + 6 * swing, -26))
    side(p, "forearm", "R", rot=(-92 - 18 * beat, -10, 0))
    side(p, "hand", "R", rot=(18 + 14 * beat, -6, 58 + 14 * swing))
    side(p, "fingers", "R", rot=(0, -30 + 10 * beat, 0))
    side(p, "index", "R", rot=(0, -26 + 8 * beat, 0))
    side(p, "thumb", "R", rot=(0, -16, 0))
    # the other hand rests, a little forward
    side(p, "forearm", "L", rot=(-14, 0, 0))
    add(p, "spine", rot=(3.0, 0, -4.0 - 2.5 * swing))
    add(p, "chest", rot=(2.5 + 1.5 * beat, 0, -3.5 - 2.0 * swing))
    nod = max(0.0, wave(t, T / 4.0, 0.12)) ** 1.5
    add(p, "neck", rot=(2.5 * nod, 0, 0))
    add(p, "head", rot=(7.0 * nod - 2.0, 3.0 * wave(t, T, 0.2), 6.0 * wave(t, T / 2.0, 0.6)))
    both(p, "brow", lift=0.0035 * beat)
    return merge(p, breath(t, 4.0, 0.6), weight_shift(t, T, 0.5), _mouth(t, 1.0, 1.15), eyes(t, (2.6,)))


def clip_talk_both(t):
    """Speaking with both hands out: pleading, insisting, explaining."""
    T = 4.0
    p = relaxed()
    beat = 0.5 + 0.5 * wave(t, T / 2.0, 0.0)
    for s, ph in (("L", 0.0), ("R", 0.08)):
        b = 0.5 + 0.5 * wave(t, T / 2.0, ph)
        side(p, "upper_arm", s, rot=(-22 - 8 * b, 10 + 6 * b, -6))
        side(p, "forearm", s, rot=(-70 - 18 * b, 8, 0))
        side(p, "hand", s, rot=(16, 0, 60))
        side(p, "fingers", s, rot=(0, -22, 0))
        side(p, "index", s, rot=(0, -18, 0))
        side(p, "thumb", s, rot=(0, -12, 0))
    add(p, "spine", rot=(3.0 * beat, 0, 0))
    add(p, "chest", rot=(2.0 * beat, 0, 0))
    nod = max(0.0, wave(t, T / 2.0, 0.05))
    add(p, "head", rot=(5.0 * nod - 1.5, 0, 3.0 * wave(t, T, 0.3)))
    both(p, "brow", lift=0.004 * beat)
    return merge(p, breath(t, 4.0, 0.5), _mouth(t, 1.1, 1.1, 0.4), eyes(t, (1.3,)))


def clip_listen(t, s):
    """Turned toward whoever speaks on side s ('l': the figure's left)."""
    T = 6.0
    d = 1.0 if s == "l" else -1.0
    p = relaxed()
    add(p, "hips", rot=(0, 0, 3.0 * d))
    add(p, "spine", rot=(0, 0, 4.0 * d))
    add(p, "chest", rot=(0, 0, 6.0 * d))
    add(p, "neck", rot=(0, 2.0 * d, 8.0 * d))
    nod = max(0.0, wave(t, T / 2.0, 0.3)) ** 2
    add(p, "head", rot=(2.0 + 4.0 * nod, 5.0 * d, 14.0 * d + 1.5 * wave(t, T, 0.1)))
    both(p, "brow", lift=0.0015 * nod)
    return merge(p, breath(t, 3.0), weight_shift(t, T, 0.7), eyes(t, (0.9, 3.9)))


def clip_look_up(t):
    """The god speaks: every face lifts toward the voice."""
    T = 6.0
    p = relaxed()
    add(p, "spine", rot=(-3, 0, 0))
    add(p, "chest", rot=(-4, 0, 0))
    add(p, "neck", rot=(-9, 0, 0))
    add(p, "head", rot=(-17 + 1.5 * wave(t, T, 0.2), 0, 2.0 * wave(t, T, 0.6)))
    both(p, "upper_arm", rot=(-6, -2, 0))
    both(p, "forearm", rot=(-14, 0, 0))
    both(p, "hand", rot=(0, 0, 18))
    both(p, "fingers", rot=(0, -10, 0))
    both(p, "brow", lift=0.004)
    add(p, "jaw", open_=1.5)
    return merge(p, breath(t, 3.4, 1.2), eyes(t, (3.0,)))


def clip_bow(t):
    """A bow from the waist, hands together before them, held, then up."""
    down = env(t, 0.15, 0.85, 1.85, 2.6)
    p = relaxed()
    b = {}
    add(b, "hips", rot=(10, 0, 0), loc=(0, 0.02, -0.01))
    add(b, "spine", rot=(18, 0, 0))
    add(b, "chest", rot=(14, 0, 0))
    add(b, "neck", rot=(8, 0, 0))
    add(b, "head", rot=(14, 0, 0))
    both(b, "thigh", rot=(-8, 0, 0))
    both(b, "shin", rot=(4, 0, 0))
    both(b, "upper_arm", rot=(-22, -8, -6))
    both(b, "forearm", rot=(-44, -10, 0))
    both(b, "hand", rot=(0, 6, 26))
    both(b, "fingers", rot=(0, 10, 0))
    both(b, "brow", lift=-0.002)
    return merge(mix(p, merge(p, b), down), eyes(t, (0.5,)), breath(t, 3.0, 0.3))


def clip_kneel(t, k=1.0):
    """Down on the right knee, head bowed; holds there."""
    d = ease(t, 0.1, 1.15)
    p = relaxed()
    q = {}
    add(q, "hips", loc=(0, 0.06, -0.415 * k), rot=(2, 0, 0))
    # left leg: thigh forward, shin down, foot flat
    add(q, "thigh.L", rot=(-84, 0, -4))
    add(q, "shin.L", rot=(86, 0, 0))
    add(q, "foot.L", rot=(-2, 0, 0))
    # right leg: knee on the ground, shin back, toes tucked
    add(q, "thigh.R", rot=(8, 0, 4))
    add(q, "shin.R", rot=(92, 0, 0))
    add(q, "foot.R", rot=(-52, 0, 0))
    add(q, "toe.R", rot=(-50, 0, 0))
    add(q, "spine", rot=(8, 0, 0))
    add(q, "chest", rot=(6, 0, 0))
    add(q, "neck", rot=(10, 0, 0))
    add(q, "head", rot=(16, 0, 0))
    # left forearm rests on the raised knee; the right hand hangs
    side(q, "upper_arm", "L", rot=(-26, -4, 0))
    side(q, "forearm", "L", rot=(-44, -8, 0))
    side(q, "hand", "L", rot=(10, 0, 20))
    side(q, "upper_arm", "R", rot=(-4, -6, 0))
    side(q, "forearm", "R", rot=(-6, 0, 0))
    both(q, "brow", lift=-0.0015)
    # going down, the body pitches forward a moment for balance
    lean = math.sin(math.pi * min(max((t - 0.1) / 1.05, 0.0), 1.0)) * 10.0
    add(q, "spine", rot=(lean * d, 0, 0))
    return merge(mix(p, merge(p, q), d), eyes(t, (0.4, 2.2)), breath(t, 3.0, 0.5))


def clip_point(t):
    """The right arm comes up and points ahead; the head looks along it."""
    u = ease(t, 0.1, 0.62)
    p = relaxed()
    q = {}
    side(q, "shoulder", "R", rot=(-6, 4, 0))
    side(q, "upper_arm", "R", rot=(-76, -10, 16))
    side(q, "forearm", "R", rot=(-6, 0, 0))
    side(q, "hand", "R", rot=(-6, 0, 10))
    side(q, "fingers", "R", rot=(0, 70, 0))
    side(q, "index", "R", rot=(0, -26, 0))
    side(q, "thumb", "R", rot=(0, 30, 0))
    add(q, "chest", rot=(0, 0, -8))
    add(q, "spine", rot=(0, 0, -3))
    add(q, "head", rot=(-3, 0, -10))
    both(q, "brow", lift=-0.0015)
    hold = 0.6 * (0.5 + 0.5 * wave(t, 2.0))
    side(q, "upper_arm", "R", rot=(hold * u, 0, 0))
    return merge(mix(p, merge(p, q), u), breath(t, 3.0, 0.6), _mouth(t, 0.9, 0.8 * ease(t, 0.5, 0.7)), eyes(t, (1.4,)))


def clip_raise_hand(t):
    """The right hand raised, palm out: a command given."""
    u = ease(t, 0.08, 0.55)
    p = relaxed()
    q = {}
    side(q, "shoulder", "R", rot=(-4, 8, 0))
    side(q, "upper_arm", "R", rot=(-58, -28, 6))
    side(q, "forearm", "R", rot=(-84, -10, 0))
    side(q, "hand", "R", rot=(-30, 0, -8))
    side(q, "fingers", "R", rot=(0, -14, 0))
    side(q, "index", "R", rot=(0, -12, 0))
    side(q, "thumb", "R", rot=(0, -16, 0))
    add(q, "chest", rot=(-3, 0, -3))
    add(q, "head", rot=(-5, 0, -4))
    both(q, "brow", lift=0.0015)
    return merge(mix(p, merge(p, q), u), breath(t, 3.0, 0.6), eyes(t, (1.6,)))


def _walk(t, T, stride, lift, bob, head_down=0.0, swing=1.0):
    # Forward is -Y. The straight, planted leg must sweep backward while
    # the bent knee recovers forward; the opposite clock reads as moonwalking.
    ph = -t / T
    p = relaxed()
    c = math.sin(2 * math.pi * ph)
    c2 = math.cos(2 * math.pi * ph)
    # legs: the left leads at ph=0
    for s, o in (("L", 0.0), ("R", 0.5)):
        a = math.sin(2 * math.pi * (ph + o))
        b = math.cos(2 * math.pi * (ph + o))
        add(p, "thigh." + s, rot=(-stride * a, 0, 0))
        # the knee folds as the leg swings through
        knee = lift * max(0.0, -b) ** 1.4 + 6.0 * max(0.0, a) * 0.6
        add(p, "shin." + s, rot=(knee + 4.0, 0, 0))
        add(p, "foot." + s, rot=(-10.0 * max(0.0, a) + 14.0 * max(0.0, -a) * max(0.0, b), 0, 0))
    # the body rises over each planted foot twice a cycle
    add(p, "hips", loc=(0.008 * c, 0, -bob * (0.5 + 0.5 * math.cos(4 * math.pi * ph))), rot=(3.0, 0, 5.0 * c))
    add(p, "spine", rot=(1.0, 0, -3.0 * c))
    add(p, "chest", rot=(1.0 + head_down * 0.3, 0, -4.0 * c))
    add(p, "neck", rot=(head_down * 0.4, 0, 1.5 * c))
    add(p, "head", rot=(head_down * 0.6 - 1.0 + 1.5 * math.cos(4 * math.pi * ph), 0, 1.5 * c))
    # the arms swing against the legs
    for s, o in (("L", 0.5), ("R", 0.0)):
        a = math.sin(2 * math.pi * (ph + o))
        side(p, "upper_arm", s, rot=(-15.0 * swing * a, 0, 0))
        side(p, "forearm", s, rot=(-8.0 * swing * max(0.0, a), 0, 0))
    return p


def clip_walk_in(t):
    T = 1.1
    return merge(_walk(t, T, 22.0, 46.0, 0.022), eyes(t, ()))


def clip_walk_out(t):
    T = 1.3
    return merge(_walk(t, T, 17.0, 38.0, 0.016, head_down=14.0, swing=0.6), eyes(t, ()))


CLIPS = {}
for _st in STANCES:
    CLIPS[_st] = (6.0, (lambda n: lambda t: clip_stance(n, t))(_st))
    CLIPS[_st + "_talk"] = (4.0, (lambda n: lambda t: clip_stance_talk(n, t))(_st))
CLIPS.update({
    "talk_both": (4.0, clip_talk_both),
    "bow": (2.8, clip_bow),
    "kneel": (2.6, clip_kneel),
    "point": (2.0, clip_point),
    "raise_hand": (1.8, clip_raise_hand),
    "walk_in": (1.1, clip_walk_in),
    "walk_out": (1.3, clip_walk_out),
})


# --- writing actions -----------------------------------------------------------------

class Poser:
    """Applies poses to a rig in the bones' own rest frames."""

    def __init__(self, rig, k=1.0):
        self.rig = rig
        self.k = k
        self.rest = {}
        self.vert_axis = {}
        for b in rig.data.bones:
            R = b.matrix_local.to_quaternion()
            self.rest[b.name] = R
            # which local axis is the figure's vertical (for open/lift)
            z_local = R.inverted() @ Vector((0, 0, 1))
            self.vert_axis[b.name] = max(range(3), key=lambda i: abs(z_local[i]))

    def apply(self, pose):
        for pb in self.rig.pose.bones:
            pb.rotation_mode = 'QUATERNION'
            pb.rotation_quaternion = Quaternion()
            pb.location = Vector()
            pb.scale = Vector((1, 1, 1))
        for name, e in pose.items():
            pb = self.rig.pose.bones.get(name)
            if pb is None:
                continue
            R = self.rest[name]
            rot = e.get("rot")
            if rot and any(abs(a) > 1e-6 for a in rot):
                Q = Euler([math.radians(a) for a in rot], 'XYZ').to_quaternion()
                pb.rotation_quaternion = R.inverted() @ Q @ R
            loc = Vector(e.get("loc", (0, 0, 0)))
            lift = e.get("lift", 0.0)
            if lift:
                loc = loc + Vector((0, 0, lift * self.k))
            if loc.length > 1e-7:
                pb.location = R.inverted() @ loc
            o = e.get("open")
            if o is not None and abs(o - 1.0) > 1e-5:
                sc = [1.0, 1.0, 1.0]
                sc[self.vert_axis[name]] = max(0.05, o)
                pb.scale = Vector(sc)

    def key(self, frame):
        for pb in self.rig.pose.bones:
            pb.keyframe_insert("rotation_quaternion", frame=frame)
            pb.keyframe_insert("location", frame=frame)
            pb.keyframe_insert("scale", frame=frame)


def write_actions(rig, k=1.0, only=None, frame=None):
    global FRAME
    FRAME = frame
    poser = Poser(rig, k)
    if rig.animation_data is None:
        rig.animation_data_create()
    made = []
    for name, (dur, fn) in CLIPS.items():
        if only and name not in only:
            continue
        act = bpy.data.actions.new(name)
        act.use_fake_user = True
        rig.animation_data.action = act
        frames = int(round(dur * FPS))
        for fr in range(frames + 1):
            t = fr / FPS
            if name in LOOP_CLIPS:
                t = t % dur if fr < frames else 0.0  # the last frame is the first again
            poser.apply(_scaled(fn(t), k))
            poser.key(fr)
        for fc in _fcurves(act):
            for kp in fc.keyframe_points:
                kp.interpolation = 'LINEAR'
        act["loop"] = name in LOOP_CLIPS
        made.append(act)
    # stash every clip on its own muted track so exporters see them all
    rig.animation_data.action = None
    for act in made:
        tr = rig.animation_data.nla_tracks.new()
        tr.name = act.name
        st = tr.strips.new(act.name, 0, act)
        tr.mute = True
    poser.apply({})
    return made


def _scaled(pose, k):
    """Clips are written for a 1.72 m figure; hip travel scales with the body."""
    if "hips" in pose and "loc" in pose["hips"]:
        e = dict(pose["hips"])
        e["loc"] = tuple(v * k for v in e["loc"])
        pose = dict(pose)
        pose["hips"] = e
    return pose


def _fcurves(act):
    """F-curves of an action (layered actions keep them in channelbags)."""
    try:
        return list(act.fcurves)
    except AttributeError:
        pass
    out = []
    for layer in getattr(act, "layers", []):
        for strip in layer.strips:
            for bag in getattr(strip, "channelbags", []):
                out.extend(bag.fcurves)
    return out

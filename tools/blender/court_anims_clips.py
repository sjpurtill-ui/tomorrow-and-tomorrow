"""Court acting (K): the clip library.

Every clip is acted: an anticipation before the action, the action reached
with the right ease (a reflex snaps, a reach slows in, a fall gathers speed),
overlap (the head after the chest, the hand after the wrist), a moving hold
(the body never freezes) and a release. Poses are pushed about 10-20% past
life so they read at court distance; the feet stay planted unless the clip
steps.

Each entry of CLIPS: name -> Clip with
  length    seconds;
  pose(t)   the body (cf_anim pose language, figure axes);
  face(t)   face channels (court_anims_lib.DEFAULT_FACE);
  meta      what the game needs to play it: loop, hold (stays on its last
            frame until told otherwise), groups (how much of each part of the
            body the clip drives: legs, torso, head, arm_L, arm_R; a sitter
            never takes the legs), hands (which hands it needs free),
            blend_in / blend_out (seconds), kind (react, talk, bow, idle,
            fidget), tags (what it shows: fear, joy, scorn, awe, deference...).
"""
import math
from mathutils import Vector

import cf_anim
from cf_anim import add, both, side, merge, wave, relaxed
import court_anims_lib as L
from court_anims_lib import (Seq, ArmSeq, ArmKey, arm_at, arm_fk, pose_seq, value_seq, plant, legs_fk,
                             face, tremble, drift, breathe, pulses, mv, landmarks)

TORSO = ("hips", "spine", "chest", "neck", "head")
FULL = {"legs": 1.0, "torso": 1.0, "head": 1.0, "arm_L": 1.0, "arm_R": 1.0}
UPPER = {"legs": 0.0, "torso": 1.0, "head": 1.0, "arm_L": 1.0, "arm_R": 1.0}


class Clip:
    def __init__(self, name, length, body, face_fn, meta):
        self.name = name
        self.length = length
        self.body = body
        self.face_fn = face_fn
        self.meta = meta

    def pose(self, t):
        return self.body(t)

    def face(self, t):
        return self.face_fn(t)


# --- the body every clip starts from --------------------------------------------------

def base():
    """Standing easy (J's relaxed stance): weight on the right leg."""
    return relaxed()


def torso_of(p, extra=None):
    out = {b: dict(p[b]) for b in TORSO if b in p}
    if extra:
        out = merge(out, extra)
    return out


def tpose(**bones):
    """A torso delta: tpose(chest=(x,y,z), hips_loc=(x,y,z), ...)."""
    p = {}
    for name, val in bones.items():
        if name.endswith("_loc"):
            add(p, name[:-4], loc=val)
        else:
            add(p, name, rot=val)
    return p


def stance_arm(name, s):
    """An arm as one of J's stances holds it (folded, clasped, hip...)."""
    return arm_fk(cf_anim.stance_pose(name), s)


class Act:
    """One clip being written: a torso timeline, an arm timeline per side,
    face keys, things merged on top (beats, trembling), and planted feet."""

    def __init__(self, length, drag=1.0, feet=True, base_pose=None):
        self.length = length
        self.drag = drag
        self.B = base_pose if base_pose is not None else base()
        self.torso_keys = []
        self.arm_keys = {"L": [], "R": []}
        self.face_keys = []
        self.extras = []
        self.feet = feet
        self.leg_keys = None
        fk = legs_fk(self.B)
        self.FEET = {s: fk[s][0].copy() for s in "LR"}
        self.KNEES = {}
        self.FOOT = {}
        for s in "LR":
            A1, K1, Ft = fk[s]
            f = L.FRAME
            H1 = f.pelvis + Vector(self.B["hips"].get("loc", (0, 0, 0))) * L.K + cf_anim_q(self.B, "hips") @ (f.hip[s] - f.pelvis)
            mid = (H1 + A1) * 0.5
            axis = (A1 - H1).normalized()
            d = (K1 - mid) - axis * (K1 - mid).dot(axis)
            self.KNEES[s] = d.normalized() if d.length > 1e-5 else mv((0.08, -1, 0), s)
            self.FOOT[s] = L.R(Ft)
        self.rest_arm = {s: arm_fk(self.B, s) for s in "LR"}
        self.lags = None
        self.foot_keys = {"L": [], "R": []}
        self.knee_fn = None
        self.loop = False

    # torso: a delta on the base stance
    def t(self, at, kind="ease", **bones):
        self.torso_keys.append((at, torso_of(self.B, tpose(**bones)), kind))
        return self

    def t_abs(self, at, pose, kind="ease"):
        self.torso_keys.append((at, pose, kind))
        return self

    def arm(self, s, at, key, kind="ease"):
        self.arm_keys[s].append((at, key, kind))
        return self

    def world(self, s, at, torso, key, kind="ease"):
        """An arm key written in the hall (left-side terms, mirrored for R)
        for the body as torso (a dict for tpose) holds it at that moment."""
        tp = torso_of(self.B, tpose(**torso))
        return self.arm(s, at, L.world_key(tp, key), kind)

    def rest(self, s, at, kind="ease", **kw):
        k = self.rest_arm[s].copy(**kw) if kw else self.rest_arm[s]
        return self.arm(s, at, k, kind)

    def f(self, at, kind="ease", **ch):
        self.face_keys.append((at, face(**ch), kind))
        return self

    def foot(self, s, at, off=(0.0, 0.0, 0.0), kind="ease", lift=0.0, rot=None):
        """A planted foot moved (metres for a 1.72 m body, figure axes), with a
        lift of the foot through the step into this key, and the foot's own
        turn (degrees, figure axes; None keeps the stance's)."""
        self.foot_keys[s].append((at, (Vector(off) * L.K, lift * L.K, rot), kind))
        return self

    def legs(self, keys):
        """Leg keys (FK, for kneeling or stepping): [(t, {bone: rot}, kind)]."""
        self.leg_keys = Seq(keys)
        return self

    def on_top(self, fn):
        self.extras.append(fn)
        return self

    def build(self):
        per = self.length if getattr(self, "loop", False) else None
        tseq = Seq(self.torso_keys if self.torso_keys else [(0.0, torso_of(self.B))], per)
        aseq = {s: ArmSeq(s, ks) for s, ks in self.arm_keys.items() if ks}
        for sq in aseq.values():
            sq.seq.period = per
        fseq = Seq(self.face_keys if self.face_keys else [(0.0, {})], per)
        fseqs = {s: (Seq(ks, per) if ks else None) for s, ks in self.foot_keys.items()}
        if self.leg_keys is not None:
            self.leg_keys.period = per
        B = self.B
        drag = self.drag

        def body(t):
            p = pose_seq(tseq, t, drag, self.lags)
            for s in "LR":
                if s in aseq:
                    p.update(aseq[s].at(t, drag))
                else:
                    for bone in cf_anim.ARM_BONES:
                        if bone + "." + s in B:
                            p[bone + "." + s] = dict(B[bone + "." + s])
            for fn in self.extras:
                p = merge(p, fn(t))
            if self.leg_keys is not None:
                p.update(pose_seq(self.leg_keys, t, drag))
            elif self.feet:
                feet = {}
                frot = dict(self.FOOT)
                for s in "LR":
                    feet[s] = self.FEET[s]
                    if fseqs.get(s) is not None:
                        a_, b_, u_ = fseqs[s].seg(t)
                        off = a_[1][0].lerp(b_[1][0], u_)
                        if a_ is not b_ and b_[1][1] > 0.0:
                            off = off + Vector((0.0, 0.0, b_[1][1] * math.sin(math.pi * L.clamp01(u_))))
                        feet[s] = feet[s] + off
                        ra = a_[1][2] if a_[1][2] is not None else self.FOOT[s]
                        rb = b_[1][2] if b_[1][2] is not None else self.FOOT[s]
                        frot[s] = L.lerp3(ra, rb, u_)
                knees = self.knee_fn(t) if self.knee_fn is not None else self.KNEES
                plant(p, feet, knees, frot)
            return p

        def face_fn(t):
            return value_seq(fseq, t, 0.0)
        return body, face_fn


def cf_anim_q(p, bone):
    return L.qof(p, bone)


def clip(name, length, act, **meta):
    body, face_fn = act.build()
    m = {"loop": False, "hold": False, "groups": dict(FULL), "hands": "LR", "blend_in": 0.16,
         "blend_out": 0.5, "kind": "react", "tags": []}
    m.update(meta)
    return Clip(name, length, body, face_fn, m)


# --- hands: where they go --------------------------------------------------------------

def hand_heart(s="R"):
    """The hand flat on the breast over the heart (the left breast)."""
    lm = landmarks()
    c = lm["heart"]
    # written in left-side terms: the right hand crosses to the left breast
    contact = Vector((-c.x, c.y, c.z)) if s == "R" else c
    return arm_at(s, contact=contact, along=(-0.55, -0.05, 0.83), palm=(0.0, 1.0, 0.0),
                  pole=(0.9, 0.3, -0.6), curl=(14, 8, 4), arc=(0.04, -0.07, 0.0))


def hand_mouth(s="L", cover=False, gap=0.05):
    lm = landmarks()
    c = lm["mouth"] + Vector((0.0, -gap * L.K, -0.024 * L.K))
    if cover:
        return arm_at(s, contact=c, along=(-0.88, -0.05, 0.47), palm=(0.0, 1.0, 0.0), pole=(0.9, 0.0, -0.5),
                      curl=(18, 10, 6), arc=(0.05, -0.10, 0.0), reach=0.42)
    return arm_at(s, contact=c + Vector((0.020 * L.K, 0, -0.020 * L.K)), along=(-0.30, -0.12, 0.95), palm=(-0.15, 1.0, 0.0),
                  pole=(0.5, -0.2, -1.0), curl=(4, -4, -6), arc=(0.06, -0.10, 0.0), reach=0.40)


def hand_belly(s="L"):
    lm = landmarks()
    c = lm["belly"] + Vector((0.035 * L.K, 0, 0))
    return arm_at(s, contact=c, along=(-0.95, -0.1, -0.20), palm=(0.0, 1.0, 0.0), pole=(0.8, 0.6, -0.3), curl=(16, 10, 6))


def hand_thigh(s="R"):
    lm = landmarks()
    return arm_at(s, contact=lm["thigh"], along=(0.05, -0.25, -0.97), palm=(0.0, 1.0, 0.1), pole=(0.6, 0.8, 0.0), curl=(14, 10, 6))


def hand_face(s="R"):
    """Palm over the eyes (a facepalm, hiding from the sight)."""
    lm = landmarks()
    c = lm["eyes"] + Vector((0.0, -0.012 * L.K, 0.010 * L.K))
    return arm_at(s, contact=c, along=(-0.30, 0.10, 0.95), palm=(0.0, 1.0, 0.0), pole=(0.8, 0.0, -0.6),
                  curl=(18, 12, 10), arc=(0.06, -0.12, 0.0), reach=0.40)


def hand_crown(s="R"):
    """Fingers in the hair at the back of the head (scratching)."""
    lm = landmarks()
    c = lm["crown"] + Vector((0.035 * L.K, 0.030 * L.K, -0.030 * L.K))
    return arm_at(s, contact=c, along=(-0.35, 0.55, 0.75), palm=(-0.25, 0.3, -0.9), pole=(0.9, -0.1, 0.4),
                  curl=(40, 34, 14), arc=(0.08, -0.06, 0.0), reach=0.55, off=0.022)


def crossed_arms():
    """Arms crossed hard over the chest: the left hand grips the right arm
    above the elbow, the right hand is tucked under the left arm."""
    f = L.FRAME
    k = L.K
    front = -(f.p["chest_d"] + 0.060 * k) + f.chest.y
    top = arm_at("L", w=Vector((-0.100 * k, front, f.z_chest - 0.040 * k)), along=(-0.70, 0.55, -0.25), palm=(0.35, 0.85, 0.15),
                 pole=(0.55, -0.35, -1.0), curl=(48, 40, 20))
    under = arm_at("R", w=Vector((-0.095 * k, front + 0.030 * k, f.z_chest - 0.095 * k)), along=(-0.70, 0.60, 0.15), palm=(0.25, 0.90, -0.2),
                   pole=(0.55, -0.30, -1.0), curl=(30, 24, 12))
    return {"L": top, "R": under}


def hand_out(s, w, along, palm, curl=(6, 0, -4), pole=(0.8, 0.5, -0.5), sh=(0, 0, 0), arc=None):
    return arm_at(s, w=w, along=along, palm=palm, curl=curl, pole=pole, sh=sh, arc=arc)


def body_pt(x, y, z):
    """A point relative to the body (left-side terms, k-scaled from 1.72 m)."""
    f = L.FRAME
    return Vector((x * L.K, y * L.K, z * L.K))


# --- the clips ---------------------------------------------------------------------------

def make_clips():
    f = L.FRAME
    k = L.K
    z_chest = f.z_chest / k
    z_waist = f.z_waist / k
    lm = landmarks()
    clips = {}

    # ---- gasp: a breath snatched in, a hand to the heart, the other to the mouth
    a = Act(1.9, drag=0.9)
    a.t(0.0).t(0.10, "out", chest=(2.5, 0, 0), head=(3, 0, 0), hips_loc=(0, 0, -0.004))
    a.t(0.27, "back", hips_loc=(0, 0.014, 0.006), spine=(-3, 0, 0), chest=(-8, 0, 0), neck=(-3, 0, 0), head=(-10, 0, 0))
    a.t(0.80, "ease", hips_loc=(0, 0.013, 0.005), spine=(-2.5, 0, 0), chest=(-7, 0, 0), neck=(-2, 0, 0), head=(-8, 0, 1.5))
    a.t(1.30, "ease", hips_loc=(0, 0.006, 0.0), spine=(0, 0, 0), chest=(-1, 0, 0), head=(-1, 0, 1))
    a.t(1.9, "ease")
    shrug = (0, -10, -4)
    a.rest("R", 0.0).rest("R", 0.10, "out", w=a.rest_arm["R"].w + Vector((0, 0.01, 0.01)))
    a.arm("R", 0.30, hand_heart("R").copy(sh=shrug), "back").arm("R", 0.85, hand_heart("R").copy(sh=(0, -7, -3)))
    a.arm("R", 1.40, hand_heart("R").copy(sh=(0, -1, 0), w=hand_heart("R").w + Vector((0, -0.02, -0.03))))
    a.rest("R", 1.9, "ease")
    a.rest("L", 0.0).rest("L", 0.12, "out")
    a.arm("L", 0.34, hand_mouth("L").copy(sh=shrug), "out").arm("L", 0.85, hand_mouth("L").copy(sh=(0, -7, -3)))
    a.arm("L", 1.35, hand_mouth("L", gap=0.12).copy(w=hand_mouth("L", gap=0.12).w + Vector((0, 0, -0.10 * k))), "ease")
    a.rest("L", 1.9, "ease")
    a.f(0.0).f(0.10, "out", jaw=0.05, brows=-0.15).f(0.26, "snap", jaw=0.78, brows=1.0, lids=1.38, worry=0.35)
    a.f(0.85, "ease", jaw=0.55, brows=0.85, lids=1.28, worry=0.45).f(1.35, "ease", jaw=0.2, brows=0.45, lids=1.12, worry=0.3)
    a.f(1.9, "ease")
    a.on_top(lambda t: tremble(t, 0.7 * L.clamp01((t - 0.3) / 0.2) * (1 - L.clamp01((t - 0.9) / 0.4)), seed=0.1))
    a.on_top(lambda t: breathe(t, 2.2, 0.5 * (1 - L.clamp01((t - 1.0) / 0.6)), 0.25))
    clips["gasp"] = clip("gasp", 1.9, a, tags=["fear", "awe", "surprise"], blend_in=0.12, blend_out=0.55)

    # ---- flinch: a reflex, all at once (the head goes first), then a peek
    a = Act(1.6, drag=0.35)
    a.lags = {"head": 0.0, "neck": 0.0, "chest": 0.02, "spine": 0.03, "hips": 0.03}
    a.t(0.0).t(0.08, "snap", hips_loc=(0.006, 0.016, -0.030), spine=(5, 0, -4), chest=(9, 0, -9), neck=(9, 0, -10), head=(14, 3, -22))
    a.t(0.22, "settle", hips_loc=(0.006, 0.014, -0.026), spine=(4, 0, -4), chest=(8, 0, -8), neck=(8, 0, -9), head=(13, 3, -20))
    a.t(0.70, "ease", hips_loc=(0.005, 0.013, -0.024), spine=(4, 0, -3), chest=(7, 0, -8), neck=(8, 0, -9), head=(12, 3, -19))
    a.t(1.05, "out", hips_loc=(0.003, 0.008, -0.014), spine=(2, 0, -2), chest=(4, 0, -5), neck=(4, 0, -5), head=(5, 1, -9))
    a.t(1.6, "ease", hips_loc=(0.0, 0.004, -0.006), chest=(2, 0, -2), head=(2, 0, -3))
    hunch = (0, -15, -9)
    guard_l = hand_out("L", body_pt(0.07, -0.33, z_chest + 0.23), along=(-0.25, -0.15, 0.96), palm=(-0.1, -1.0, 0.1),
                       curl=(10, 4, 0), pole=(0.9, 0.0, -0.5), sh=hunch, arc=(0.05, -0.05, 0.0))
    guard_r = hand_out("R", body_pt(0.03, -0.29, z_chest + 0.06), along=(-0.35, -0.20, 0.92), palm=(-0.1, -1.0, 0.0),
                       curl=(16, 8, 4), pole=(0.9, 0.2, -0.5), sh=hunch, arc=(0.04, -0.04, 0.0))
    a.rest("L", 0.0).arm("L", 0.12, guard_l, "snap").arm("L", 0.75, guard_l.copy(w=guard_l.w + Vector((0, 0, -0.01))))
    a.arm("L", 1.12, guard_l.copy(w=guard_l.w + Vector((0, -0.02, -0.12 * k)), sh=(0, -6, -4)), "ease")
    a.rest("L", 1.6, "ease")
    a.rest("R", 0.0).arm("R", 0.13, guard_r, "snap").arm("R", 0.75, guard_r).arm("R", 1.12, guard_r.copy(sh=(0, -6, -4)), "ease")
    a.rest("R", 1.6, "ease")
    a.f(0.0).f(0.07, "snap", lids=0.10, tight=0.85, worry=0.75, brows=0.55, jaw=0.18)
    a.f(0.75, "ease", lids=0.12, tight=0.8, worry=0.8, brows=0.6, jaw=0.12)
    a.f(1.05, "out", lids=0.75, tight=0.45, worry=0.85, brows=0.7, jaw=0.08, eyes_y=0.5)
    a.f(1.6, "ease", lids=1.0, worry=0.5, brows=0.4)
    a.on_top(lambda t: tremble(t, 1.0 * L.clamp01((t - 0.15) / 0.1) * (1 - L.clamp01((t - 1.0) / 0.5)), 1.2, 0.4))
    clips["flinch"] = clip("flinch", 1.6, a, tags=["fear"], blend_in=0.09, blend_out=0.6)

    # ---- stifled laugh: a snort, a hand clapped over the mouth, shoulders shaking
    a = Act(2.6, drag=0.9)
    a.t(0.0).t(0.12, "snap", spine=(2, 0, 0), chest=(4, 0, 0), head=(7, 0, 0))
    a.t(0.34, "back", hips_loc=(0, 0.006, -0.006), spine=(4, 0, -3), chest=(7, 0, -6), neck=(5, 0, -6), head=(9, -3, -16))
    a.t(1.55, "ease", hips_loc=(0, 0.006, -0.006), spine=(4, 0, -3), chest=(6, 0, -5), neck=(5, 0, -5), head=(8, -2, -13))
    a.t(2.05, "out", spine=(1, 0, -1), chest=(1, 0, -2), head=(1, 0, -4))
    a.t(2.6, "ease")
    cover = hand_mouth("R", cover=True)
    a.rest("R", 0.0).arm("R", 0.30, cover.copy(sh=(0, -6, -4)), "snap").arm("R", 1.55, cover.copy(sh=(0, -5, -4)))
    a.arm("R", 2.05, cover.copy(w=cover.w + Vector((0, -0.04, -0.16 * k)), sh=(0, 0, 0)), "ease").rest("R", 2.6, "ease")
    a.rest("L", 0.0).arm("L", 0.42, hand_belly("L"), "out").arm("L", 1.9, hand_belly("L")).rest("L", 2.6, "ease")
    shake = lambda t: pulses(t, 0.36, 0.125, 10, 0.92, 1.4)

    def shaking(t):
        b = shake(t)
        p = {}
        both(p, "shoulder", rot=(0, -5.5 * b, 0))
        add(p, "chest", rot=(2.5 * b, 0, 0))
        add(p, "head", rot=(2.0 * b, 0, 0))
        return p
    a.on_top(shaking)
    a.f(0.0).f(0.12, "snap", puff=0.7, lids=0.45, smile=0.5, tight=0.5)
    a.f(0.36, "ease", puff=0.6, lids=0.30, smile=0.6, tight=0.7, brows=0.35)
    a.f(1.55, "ease", puff=0.4, lids=0.40, smile=0.5, tight=0.75, brows=0.3)
    a.f(2.05, "ease", lids=0.8, smile=0.3, tight=0.6).f(2.6, "ease", smile=0.15, tight=0.25)
    clips["laugh_stifled"] = clip("laugh_stifled", 2.6, a, tags=["joy", "guilt"], blend_in=0.08, blend_out=0.55, hands="R")
    clips["laugh_stifled"].beats = shake

    # ---- bows ---------------------------------------------------------------------------
    def hanging(s, pitch, sh=(0, 0, 0)):
        """An arm hanging under gravity while the chest pitches forward by
        `pitch` degrees: forward of the body by as much."""
        r = a.rest_arm[s]
        f_ = L.FRAME
        piv = f_.shoulder[s]
        q = L.Q((-pitch, 0, 0))
        w = piv + q @ (r.w - piv)
        return r.copy(w=w, along=q @ r.along, palm=q @ r.palm, sh=sh, pole=q @ r.pole)

    # shallow: a nod of the body; the hands slide down the thighs
    a = Act(2.0, drag=1.1)
    a.t(0.0).t(0.18, "out", chest=(-2, 0, 0), head=(-2.5, 0, 0), hips_loc=(0, 0, 0.004))
    a.t(0.62, "out3", hips=(6, 0, 0), hips_loc=(0, 0.024, -0.004), spine=(10, 0, 0), chest=(9, 0, 0), neck=(6, 0, 0), head=(11, 0, 0))
    a.t(1.08, "ease", hips=(6, 0, 0), hips_loc=(0, 0.024, -0.004), spine=(10, 0, 0), chest=(9.5, 0, 0), neck=(6, 0, 0), head=(12, 0, 0))
    a.t(1.55, "out", hips=(0.5, 0, 0), hips_loc=(0, 0.003, 0.0), spine=(1, 0, 0), chest=(0, 0, 0), neck=(1, 0, 0), head=(3, 0, 0))
    a.t(2.0, "ease")
    for s in "LR":
        a.rest(s, 0.0).arm(s, 0.66, hanging(s, 14), "out3").arm(s, 1.08, hanging(s, 15)).arm(s, 1.6, hanging(s, 2), "out").rest(s, 2.0)
    a.f(0.0).f(0.18, "out", brows=0.2).f(0.62, "ease", lids=0.45, brows=-0.05).f(1.1, "ease", lids=0.4).f(1.6, "ease", lids=0.9).f(2.0)
    clips["bow_shallow"] = clip("bow_shallow", 2.0, a, kind="bow", tags=["deference"], blend_in=0.2, blend_out=0.45)

    # deep: hands gathered before the belly, a long bow from the hips, the head comes up last
    a = Act(3.1, drag=1.25)
    a.t(0.0).t(0.30, "ease", chest=(-2, 0, 0), head=(-2, 0, 0))
    a.t(0.98, "out3", hips=(15, 0, 0), hips_loc=(0, 0.055, -0.010), spine=(15, 0, 0), chest=(13, 0, 0), neck=(6, 0, 0), head=(12, 0, 0))
    a.t(1.95, "ease", hips=(15.5, 0, 0), hips_loc=(0, 0.056, -0.011), spine=(15, 0, 0), chest=(14, 0, 0), neck=(7, 0, 0), head=(14, 0, 0))
    a.t(2.55, "out", hips=(1, 0, 0), hips_loc=(0, 0.004, 0), spine=(1, 0, 0), chest=(0, 0, 0), neck=(1, 0, 0), head=(4, 0, 0))
    a.t(3.1, "ease")
    for s in "LR":
        cl = stance_arm("clasped", s)
        a.rest(s, 0.0).arm(s, 0.32, cl.copy(arc=(0.03, -0.05, 0.0)), "out").arm(s, 1.95, cl).arm(s, 2.6, cl).rest(s, 3.1, "ease")
    a.f(0.0).f(0.3, "ease", brows=0.15).f(0.98, "ease", lids=0.35, brows=-0.1).f(1.95, "ease", lids=0.3).f(2.6, "ease", lids=0.85).f(3.1)
    a.on_top(lambda t: drift(t, 0.4 * L.clamp01((t - 1.0) / 0.3) * (1 - L.clamp01((t - 1.9) / 0.3)), 1.9))
    clips["bow_deep"] = clip("bow_deep", 3.1, a, kind="bow", tags=["deference", "reverence"], blend_in=0.25, blend_out=0.5)

    # over-deep: eager, plunges far too far, wobbles at the bottom, peeks up,
    # pops up too fast and nearly goes over backwards
    a = Act(4.4, drag=1.0)
    a.t(0.0).t(0.16, "out", hips_loc=(0, -0.004, 0.012), chest=(-5, 0, 0), head=(-6, 0, 0))
    a.t(0.36, "ease", hips_loc=(0, -0.004, 0.014), chest=(-6, 0, 0), head=(-7, 0, 0))
    a.t(0.70, "in", hips=(30, 0, 0), hips_loc=(0, 0.10, -0.036), spine=(26, 0, 0), chest=(22, 0, 0), neck=(10, 0, 0), head=(16, 0, 0))
    a.t(0.95, "settle", hips=(28, 0, 0), hips_loc=(0, 0.095, -0.034), spine=(24, 0, 0), chest=(20, 0, 0), neck=(9, 0, 0), head=(15, 0, 0))
    a.t(2.30, "ease", hips=(28, 0, 0), hips_loc=(0, 0.095, -0.034), spine=(24, 0, 0), chest=(20, 0, 0), neck=(9, 0, 0), head=(15, 0, 0))
    a.t(2.62, "out", hips=(27, 0, 0), hips_loc=(0, 0.094, -0.033), spine=(23, 0, 0), chest=(17, 0, 0), neck=(-6, 0, 0), head=(-14, 0, 0))
    a.t(2.95, "ease", hips=(27, 0, 0), hips_loc=(0, 0.094, -0.033), spine=(23, 0, 0), chest=(17, 0, 0), neck=(-6, 0, 0), head=(-15, 0, 0))
    a.t(3.20, "back2", hips=(-3, 0, 0), hips_loc=(0, -0.012, 0.004), spine=(-6, 0, 0), chest=(-9, 0, 0), neck=(-3, 0, 0), head=(-6, 0, 0))
    a.t(3.75, "settle", hips=(1, 0, 0), hips_loc=(0, 0.004, 0), spine=(1, 0, 0), chest=(0, 0, 0), head=(1, 0, 0))
    a.t(4.4, "ease")

    def wobble(t):
        w = L.clamp01((t - 0.95) / 0.25) * (1 - L.clamp01((t - 2.2) / 0.3))
        amp = w * (0.6 + 0.4 * math.sin(math.pi * L.clamp01((t - 0.95) / 1.3)))
        s1 = math.sin(2 * math.pi * (t - 0.95) / 0.62)
        p = {}
        add(p, "hips", rot=(0, 3.5 * amp * s1, 2.0 * amp * s1), loc=(0.012 * amp * s1, 0, 0))
        add(p, "spine", rot=(0, -1.5 * amp * s1, 0))
        add(p, "chest", rot=(1.5 * amp * math.sin(2 * math.pi * (t - 0.95) / 0.31), -2.0 * amp * s1, 0))
        return p
    a.on_top(wobble)
    eager = {s: hand_out(s, body_pt(0.03, -0.25, z_chest + 0.03), along=(-0.3, -0.25, 0.9), palm=(-1.0, 0.0, 0.1),
                         curl=(6, 2, 0), pole=(0.8, 0.5, -0.4), arc=(0.04, -0.05, 0.0)) for s in "LR"}
    for s in "LR":
        dangle = hanging(s, 58)
        a.rest(s, 0.0).arm(s, 0.22, eager[s], "out").arm(s, 0.40, eager[s])
        a.arm(s, 0.78, dangle.copy(w=dangle.w + Vector((0, -0.06 * k, 0.02 * k)), curl=(20, 14, 6)), "in")
        a.arm(s, 1.00, dangle.copy(curl=(26, 18, 8)), "settle").arm(s, 2.3, dangle).arm(s, 2.95, dangle)
        a.arm(s, 3.22, hanging(s, -10, sh=(0, -6, 0)).copy(w=hanging(s, -10).w + Vector((0, 0.05 * k, 0.02 * k))), "back2")
        a.arm(s, 3.75, eager[s], "settle").arm(s, 4.0, eager[s]).rest(s, 4.4, "ease")

    def flail(t):
        w = L.clamp01((t - 1.0) / 0.2) * (1 - L.clamp01((t - 2.2) / 0.3))
        p = {}
        for s, ph in (("L", 0.0), ("R", 0.5)):
            side(p, "upper_arm", s, rot=(7 * w * math.sin(2 * math.pi * ((t - 1.0) / 0.62 + ph)), 0, 0))
            side(p, "forearm", s, rot=(-8 * w * math.sin(2 * math.pi * ((t - 1.05) / 0.62 + ph)), 0, 0))
        return p
    a.on_top(flail)
    a.f(0.0).f(0.16, "out", smile=0.8, brows=0.9, lids=1.2).f(0.7, "in", smile=0.6, brows=0.6, lids=0.9)
    a.f(1.0, "ease", smile=0.2, worry=0.4, brows=0.5, lids=1.1, jaw=0.15).f(2.3, "ease", worry=0.5, brows=0.6, lids=1.15, jaw=0.15)
    a.f(2.62, "out", brows=1.0, eyes_y=1.0, lids=1.25, worry=0.3).f(2.95, "ease", brows=1.0, eyes_y=1.0, lids=1.25)
    a.f(3.2, "snap", brows=1.0, lids=1.35, jaw=0.35, worry=0.4).f(3.75, "ease", smile=0.7, brows=0.6, lids=1.05)
    a.f(4.4, "ease", smile=0.5, brows=0.3)
    clips["bow_overdeep"] = clip("bow_overdeep", 4.4, a, kind="bow", tags=["deference", "eager", "comic"], blend_in=0.15, blend_out=0.5)

    # ---- kneel: weight to the front foot, the back foot steps back, down onto the
    # knee (gathering speed), a bump, the head bows last. Holds.
    a = Act(2.5, drag=1.0, feet=False)
    a.t(0.0).t(0.28, "out", hips_loc=(0.016, 0.0, -0.010), spine=(2, 0, 2), chest=(2, 0, 2), head=(8, 0, 0))
    a.t(0.62, "ease", hips_loc=(0.014, 0.030, -0.080), spine=(8, 0, 1), chest=(6, 0, 1), neck=(4, 0, 0), head=(10, 0, 0))
    a.t(1.02, "in", hips=(2, 0, 0), hips_loc=(0.0, 0.060, -0.415), spine=(14, 0, 0), chest=(8, 0, 0), neck=(8, 0, 0), head=(12, 0, 0))
    a.t(1.20, "settle", hips=(2, 0, 0), hips_loc=(0.0, 0.060, -0.410), spine=(9, 0, 0), chest=(6, 0, 0), neck=(9, 0, 0), head=(14, 0, 0))
    a.t(1.65, "out", hips=(2, 0, 0), hips_loc=(0.0, 0.060, -0.412), spine=(8, 0, 0), chest=(7, 0, 0), neck=(11, 0, 0), head=(20, 0, 0))
    a.t(2.5, "ease", hips=(2, 0, 0), hips_loc=(0.0, 0.060, -0.412), spine=(8, 0, 0), chest=(7, 0, 0), neck=(11, 0, 0), head=(21, 0, 0))
    B = a.B
    legs0 = {b: dict(B[b]) for b in ("thigh.L", "shin.L", "foot.L", "thigh.R", "shin.R", "foot.R") if b in B}
    legs0.setdefault("toe.R", {"rot": (0, 0, 0)})
    step = merge(legs0, {"thigh.L": {"rot": (-14, 0, 0)}, "shin.L": {"rot": (16, 0, 0)},
                         "thigh.R": {"rot": (30, 0, 0)}, "shin.R": {"rot": (42, 0, 0)}, "foot.R": {"rot": (-10, 0, 0)}})
    down = merge(legs0, {"thigh.L": {"rot": (-84, 0, -4)}, "shin.L": {"rot": (86, 0, 0)}, "foot.L": {"rot": (-2, 0, 0)},
                         "thigh.R": {"rot": (8, 0, 4)}, "shin.R": {"rot": (92, 0, 0)}, "foot.R": {"rot": (-52, 0, 0)}, "toe.R": {"rot": (-50, 0, 0)}})
    a.legs([(0.0, legs0), (0.30, legs0, "ease"), (0.62, step, "out"), (1.02, down, "in"), (2.5, down)])
    # the left forearm laid across the raised knee; the right arm hangs from the bent body
    held = torso_of(B, tpose(hips=(2, 0, 0), hips_loc=(0.0, 0.060, -0.412), spine=(8, 0, 0), chest=(7, 0, 0), neck=(11, 0, 0), head=(21, 0, 0)))
    full = dict(held)
    full.update(down)
    knee_w = legs_fk(full)["L"][1]
    on_knee = ArmKey(L.chest_space(held, knee_w + Vector((0.0, -0.07 * k, 0.045 * k))), (0.5, 0.8, -0.2),
                     L.chest_dir(held, (-0.25, -0.75, -0.6)), L.chest_dir(held, (-0.3, 0.1, -0.95)), (34, 24, 10))
    a.rest("L", 0.0).rest("L", 0.4).arm("L", 1.15, on_knee.copy(arc=(0.05, -0.08, 0.0)), "ease").arm("L", 2.5, on_knee)
    hang = hanging("R", 17)
    a.rest("R", 0.0).rest("R", 0.62).arm("R", 1.25, hang.copy(curl=(42, 32, 14)), "out").arm("R", 2.5, hang.copy(curl=(44, 34, 14)))
    a.f(0.0).f(0.28, "out", lids=0.65, worry=0.2).f(1.02, "ease", lids=0.5, worry=0.3, tight=0.3).f(1.7, "ease", lids=0.4, worry=0.35, tight=0.35)
    a.f(2.5, "ease", lids=0.42, worry=0.3, tight=0.3)
    clips["kneel"] = clip("kneel", 2.5, a, kind="bow", hold=True, tags=["deference", "dread"], blend_in=0.25, blend_out=0.6)

    # ---- defiant: a huff, arms crossed hard (with a bounce), chin up, weight back. Holds.
    a = Act(2.2, drag=1.0)
    a.t(0.0).t(0.22, "out", spine=(-1, 0, 0), chest=(-4, 0, 0), head=(-3, 0, 0), hips_loc=(0, 0, 0.004))
    a.t(0.70, "back", hips=(0, 3, 0), hips_loc=(0.004, 0.016, 0.0), spine=(-3, 0, 0), chest=(-6, 0, 0), neck=(-3, 0, 0), head=(-10, 0, 4))
    a.t(1.05, "settle", hips=(0, 3, 0), hips_loc=(0.004, 0.015, 0.0), spine=(-2.5, 0, 0), chest=(-5, 0, 0), neck=(-3, 0, 0), head=(-9, 0, 4))
    a.t(2.2, "ease", hips=(0, 3, 0), hips_loc=(0.004, 0.015, 0.0), spine=(-2.5, 0, 0), chest=(-5, 0, 0), neck=(-3, 0, 0), head=(-9, 0, 4))
    cross = crossed_arms()
    for s in "LR":
        fo = cross[s]
        a.rest(s, 0.0).rest(s, 0.22, "out", sh=(0, -9, 0)).arm(s, 0.70 + (0.06 if s == "R" else 0.0), fo.copy(arc=(0.06, -0.08, -0.02)), "back")
        a.arm(s, 2.2, fo)
    a.f(0.0).f(0.22, "out", puff=0.35, brows=-0.3).f(0.70, "ease", stern=0.85, tight=0.55, lids=0.78, brows=-0.65)
    a.f(2.2, "ease", stern=0.8, tight=0.5, lids=0.8, brows=-0.6)
    a.on_top(lambda t: drift(t, 0.6 * L.clamp01((t - 1.0) / 0.3), 2.8, 0.15))
    clips["defiant"] = clip("defiant", 2.2, a, kind="react", hold=True, tags=["defiance", "anger"], blend_in=0.18, blend_out=0.6)

    # ---- talking gestures (one hand or both; the stance's legs stay) --------------------
    up = {"legs": 0.0, "torso": 0.55, "head": 0.5, "arm_L": 0.0, "arm_R": 1.0}

    # explain: the right hand opens out, palm up, sweeps a little and lands on the word
    a = Act(1.9, drag=1.0)
    a.t(0.0).t(0.45, "out", spine=(1, 0, -2), chest=(2, 0, -4), head=(-1, 0, -3)).t(0.95, "back", spine=(2, 0, -3), chest=(3.5, 0, -6), head=(4, 0, -4))
    a.t(1.3, "ease", chest=(2, 0, -3), head=(1, 0, -2)).t(1.9, "ease")
    op1 = hand_out("R", body_pt(0.02, -0.30, z_waist + 0.10), along=(0.10, -0.85, 0.30), palm=(0.15, -0.10, 0.98), curl=(10, 4, -6),
                   pole=(0.8, 0.5, -0.5), arc=(0.03, -0.06, 0.02))
    op2 = op1.copy(w=op1.w + mv(Vector((0.10 * k, -0.04 * k, -0.02 * k)), "R"), along=mv((0.45, -0.80, 0.20), "R"), palm=mv((0.25, -0.15, 0.95), "R"))
    a.rest("R", 0.0).arm("R", 0.45, op1, "out").arm("R", 0.92, op2, "back").arm("R", 1.25, op2).rest("R", 1.9, "ease")
    a.f(0.0).f(0.45, "out", brows=0.4).f(0.92, "snap", brows=0.55, jaw=0.25).f(1.3, "ease", brows=0.2).f(1.9)
    clips["talk_explain"] = clip("talk_explain", 1.9, a, kind="talk", groups=up, hands="R", blend_in=0.2, blend_out=0.45, beat=0.92)

    # emphatic: pull back and up (anticipation), chop down on the word, a rebound
    a = Act(1.6, drag=0.8)
    a.t(0.0).t(0.28, "out", spine=(-1, 0, -2), chest=(-3, 0, -4), head=(-4, 0, -2))
    a.t(0.44, "in", spine=(3, 0, -2), chest=(6, 0, -3), head=(9, 0, -2)).t(0.6, "settle", spine=(2, 0, -2), chest=(4, 0, -3), head=(5, 0, -2))
    a.t(1.6, "ease")
    raised = hand_out("R", body_pt(0.15, -0.15, z_chest + 0.17), along=(-0.1, -0.3, 0.95), palm=(-1.0, 0.0, 0.0), curl=(34, 26, 16),
                      pole=(0.35, 0.25, -1.0), sh=(0, -6, 0), arc=(0.04, 0.0, 0.03))
    chop = hand_out("R", body_pt(0.06, -0.38, z_waist + 0.02), along=(0.05, -0.95, -0.30), palm=(-1.0, 0.0, 0.0), curl=(10, 6, 4),
                    pole=(0.45, 0.35, -1.0), arc=(0.0, -0.10, 0.05))
    a.rest("R", 0.0).arm("R", 0.28, raised, "out").arm("R", 0.44, chop, "in").arm("R", 0.58, chop.copy(w=chop.w + Vector((0, 0, 0.035 * k))), "out")
    a.arm("R", 0.85, chop).rest("R", 1.6, "ease")
    a.f(0.0).f(0.28, "out", brows=0.3, jaw=0.15).f(0.44, "snap", stern=0.65, brows=-0.55, jaw=0.45).f(0.8, "ease", stern=0.5, brows=-0.4, jaw=0.1).f(1.6)
    clips["talk_emphatic"] = clip("talk_emphatic", 1.6, a, kind="talk", groups=up, hands="R", blend_in=0.12, blend_out=0.45, beat=0.44, tags=["anger", "certainty"])

    # hesitant: a hand to the breast, the shoulders up a little, the head tilts
    a = Act(2.2, drag=1.1)
    a.t(0.0).t(0.5, "out", spine=(1, 0, 0), chest=(2, 0, 0), neck=(2, 0, 0), head=(4, -6, -3))
    a.t(1.5, "ease", spine=(1, 0, 0), chest=(2, 0, 0), neck=(2, 0, 0), head=(5, -7, -4)).t(2.2, "ease")
    hr = hand_heart("R").copy(sh=(0, -6, -3))
    a.rest("R", 0.0).arm("R", 0.5, hr, "out").arm("R", 1.55, hr).rest("R", 2.2, "ease")
    small = hand_out("L", body_pt(0.12, -0.20, z_waist), along=(0.0, -0.9, 0.1), palm=(-0.2, 0.0, 0.98), curl=(18, 10, 2), pole=(0.9, 0.4, -0.3))
    a.rest("L", 0.0).rest("L", 0.25).arm("L", 0.75, small, "out").arm("L", 1.5, small).rest("L", 2.2, "ease")
    a.f(0.0).f(0.5, "out", worry=0.65, brows=0.55, tight=0.25, lids=0.9).f(1.55, "ease", worry=0.6, brows=0.5, tight=0.3).f(2.2)
    clips["talk_hesitant"] = clip("talk_hesitant", 2.2, a, kind="talk", groups={"legs": 0.0, "torso": 0.6, "head": 0.7, "arm_L": 1.0, "arm_R": 1.0},
                                  hands="LR", blend_in=0.25, blend_out=0.5, tags=["fear", "doubt"])

    # plead: both palms up and out, the body leaning in, two beats
    a = Act(2.4, drag=1.0)
    a.t(0.0).t(0.5, "out", hips_loc=(0, -0.008, 0), spine=(3, 0, 0), chest=(5, 0, 0), neck=(2, 0, 0), head=(-2, 0, 5))
    a.t(0.95, "back", hips_loc=(0, -0.010, 0), spine=(4, 0, 0), chest=(7, 0, 0), head=(-1, 0, 6))
    a.t(1.45, "back", hips_loc=(0, -0.010, 0), spine=(4, 0, 0), chest=(6.5, 0, 0), head=(-3, 0, 6)).t(2.4, "ease")
    for s, dz in (("L", 0.0), ("R", 0.02)):
        pl = hand_out(s, body_pt(0.14, -0.30, z_waist + 0.08 + dz), along=(0.15, -0.95, 0.1), palm=(-0.1, -0.15, 0.98), curl=(12, 6, -4),
                      pole=(0.7, 0.6, -0.4), sh=(0, -4, -6), arc=(0.03, -0.05, 0.0))
        a.rest(s, 0.0).arm(s, 0.5, pl, "out").arm(s, 0.95, pl.copy(w=pl.w + Vector((0, -0.03 * k, 0.03 * k))), "back")
        a.arm(s, 1.45, pl.copy(w=pl.w + Vector((0, -0.04 * k, 0.04 * k))), "back").arm(s, 1.8, pl).rest(s, 2.4, "ease")
    a.f(0.0).f(0.5, "out", worry=0.8, brows=0.75, lids=1.08, jaw=0.15).f(1.45, "ease", worry=0.85, brows=0.8, lids=1.1, jaw=0.2).f(2.4)
    clips["talk_plead"] = clip("talk_plead", 2.4, a, kind="talk", groups={"legs": 0.0, "torso": 0.7, "head": 0.7, "arm_L": 1.0, "arm_R": 1.0},
                               hands="LR", blend_in=0.2, blend_out=0.5, tags=["fear", "need"], beat=0.95)

    # one finger up: "one thing" — raised, a little shake on the words
    a = Act(2.0, drag=0.9)
    a.t(0.0).t(0.4, "out", chest=(-2, 0, -3), head=(-3, 0, -3)).t(1.4, "ease", chest=(-1.5, 0, -3), head=(-2, 0, -3)).t(2.0, "ease")
    fu = hand_out("R", body_pt(0.12, -0.20, z_chest + 0.16), along=(0.0, -0.25, 0.97), palm=(-0.2, -0.95, 0.0), curl=(85, -12, 50),
                  pole=(0.9, 0.3, -0.4), arc=(0.04, -0.04, 0.0))
    a.rest("R", 0.0).arm("R", 0.40, fu, "back").arm("R", 1.4, fu).rest("R", 2.0, "ease")

    def finger_shake(t):
        b = pulses(t, 0.62, 0.22, 3, 0.85)
        p = {}
        side(p, "forearm", "R", rot=(-5 * b, 0, 0))
        side(p, "hand", "R", rot=(-6 * b, 0, 0))
        add(p, "head", rot=(2.5 * b, 0, 0))
        return p
    a.on_top(finger_shake)
    a.f(0.0).f(0.4, "out", brows=0.5, lids=1.05).f(1.4, "ease", brows=0.4).f(2.0)
    clips["talk_one"] = clip("talk_one", 2.0, a, kind="talk", groups=up, hands="R", blend_in=0.18, blend_out=0.45, beat=0.62)

    # dismiss: the back of the hand flicks it away; the head turns off it
    a = Act(1.6, drag=0.9)
    a.t(0.0).t(0.25, "out", chest=(0, 0, 3), head=(0, 0, 4)).t(0.45, "snap", chest=(-1, 0, -5), head=(-4, -4, -12))
    a.t(1.0, "ease", chest=(-1, 0, -4), head=(-3, -3, -10)).t(1.6, "ease")
    flick0 = hand_out("R", body_pt(-0.02, -0.18, z_chest - 0.02), along=(0.25, -0.35, 0.90), palm=(0.0, 1.0, 0.0), curl=(26, 18, 10),
                      pole=(0.9, 0.3, -0.4))
    flick1 = hand_out("R", body_pt(0.26, -0.24, z_chest - 0.06), along=(0.75, -0.40, 0.50), palm=(0.0, -1.0, 0.1), curl=(6, 0, -6),
                      pole=(0.9, 0.3, -0.4), arc=(0.0, -0.06, 0.04))
    a.rest("R", 0.0).arm("R", 0.25, flick0, "out").arm("R", 0.43, flick1, "snap").arm("R", 0.7, flick1.copy(w=flick1.w + Vector((0, 0, -0.04 * k))), "ease")
    a.rest("R", 1.6, "ease")
    a.f(0.0).f(0.25, "out", lids=0.85).f(0.45, "snap", sneer=0.55, lids=0.7, brows=-0.2, tight=0.3).f(1.0, "ease", sneer=0.4, lids=0.75).f(1.6)
    clips["talk_dismiss"] = clip("talk_dismiss", 1.6, a, kind="talk", groups=up, hands="R", blend_in=0.12, blend_out=0.45, beat=0.43, tags=["scorn"])

    # ---- a fidget: a scratch at the back of the head (puzzled, or just itchy)
    a = Act(3.0, drag=1.1)
    a.t(0.0).t(0.6, "out", spine=(0, 0, -2), chest=(2, 0, -3), neck=(2, 0, 0), head=(7, -6, -6))
    a.t(2.2, "ease", spine=(0, 0, -2), chest=(2, 0, -3), neck=(2, 0, 0), head=(8, -7, -7)).t(3.0, "ease")
    cr = hand_crown("R").copy(sh=(0, -8, 0))
    a.rest("R", 0.0).arm("R", 0.62, cr, "out").arm("R", 2.25, cr).rest("R", 3.0, "ease")

    def scratch(t):
        b = 0.0
        if 0.7 < t < 2.2:
            b = math.sin(2 * math.pi * (t - 0.7) / 0.22) * (1 - L.clamp01((t - 1.9) / 0.3))
        p = {}
        side(p, "hand", "R", rot=(9 * b, 0, 0))
        side(p, "fingers", "R", rot=(0, 18 * max(b, 0), 0))
        side(p, "index", "R", rot=(0, 18 * max(b, 0), 0))
        return p
    a.on_top(scratch)
    a.f(0.0).f(0.6, "out", worry=0.4, brows=0.3, tight=0.4, lids=0.85).f(2.2, "ease", worry=0.35, brows=0.25, tight=0.45).f(3.0)
    clips["scratch_head"] = clip("scratch_head", 3.0, a, kind="fidget", groups={"legs": 0.0, "torso": 0.5, "head": 0.8, "arm_L": 0.0, "arm_R": 1.0},
                                 hands="R", blend_in=0.3, blend_out=0.5, tags=["puzzled"])
    import court_anims_more
    import court_anims_r2
    court_anims_more.make_more(clips)
    court_anims_r2.make_r2(clips)
    return clips


def hang(a, s, pitch, sh=(0, 0, 0), curl=None):
    """An arm of Act a hanging under gravity while the chest pitches by `pitch`."""
    r = a.rest_arm[s]
    piv = L.FRAME.shoulder[s]
    q = L.Q((-pitch, 0, 0))
    k = r.copy(w=piv + q @ (r.w - piv), along=q @ r.along, palm=q @ r.palm, sh=sh, pole=q @ r.pole)
    if curl is not None:
        k.curl = curl
    return k


CLIPS = None


def all_clips():
    global CLIPS
    CLIPS = make_clips()
    return CLIPS

"""Court acting (K), round 3: the rest of the director's vocabulary
(court_director.gd ACTS), each pushed to read at court distance: big arcs,
elbows out, the head joining in, still a person.

Sided clips (_l / _r) go toward the figure's own left or right; the acting
picks the side from where args.at stands. In-place steps (edge_forward) carry
meta move_m: the stage moves the body that far while the clip plays.
"""
import math
from mathutils import Vector

import cf_anim
from cf_anim import add, both, side, merge
import court_anims_lib as L
from court_anims_lib import ArmKey, arm_at, arm_fk, arm_solve, legs_fk, plant, tremble, breathe, drift, pulses, mv, landmarks
from court_anims_clips import (Act, clip, torso_of, tpose, body_pt, hand_mouth, hand_heart, hand_belly, hand_thigh, hand_face,
                               hand_crown, hand_out, stance_arm, hang, UPPER, FULL)
from court_anims_r2 import face_plus

UP = {"legs": 0.0, "torso": 1.0, "head": 1.0, "arm_L": 1.0, "arm_R": 1.0}


def one_arm(s_):
    return {"legs": 0.0, "torso": 0.8, "head": 1.0, "arm_L": 1.0 if s_ == "L" else 0.0, "arm_R": 1.0 if s_ == "R" else 0.0}


def lips(t, start, end, rate=5.0, amount=0.16):
    """Lips moving under the breath (counting, muttering)."""
    if t < start or t > end:
        return 0.0
    return amount * max(0.0, math.sin(2 * math.pi * rate * (t - start)))


def make_r3(clips):
    f = L.FRAME
    k = L.K
    z_chest = f.z_chest / k
    z_waist = f.z_waist / k
    z_hip = f.z_hip / k
    lm = landmarks()
    z_eye = lm["eyes"].z / k
    z_mouth = lm["mouth"].z / k

    # ---- cover the eyes of the one (a child, a shorter one) beside them on side sd
    for sd, nm in ((1.0, "l"), (-1.0, "r")):
        s_ = "L" if sd > 0 else "R"
        o_ = "R" if sd > 0 else "L"
        a = Act(2.4, drag=1.0)
        lean = dict(hips_loc=(0.05 * sd, 0.0, -0.02), spine=(4, 3 * sd, 4 * sd), chest=(6, 4 * sd, 8 * sd), neck=(4, 0, 6 * sd), head=(14, 0, 12 * sd))
        a.t(0.0).t(0.35, "out", **lean).t(2.0, "ease", **lean).t(2.4, "ease")
        cover = arm_at(s_, w=body_pt(0.30, -0.24, 1.06), along=(0.90, -0.15, 0.40), palm=(0.0, 1.0, 0.1), pole=(0.6, 0.6, -0.5), curl=(12, 6, 4))
        shoulder = arm_at(o_, w=body_pt(-0.30, -0.02, 1.02), along=(-0.85, -0.2, -0.45), palm=(0.0, 0.1, -1.0), pole=(0.3, 0.8, -0.4), curl=(25, 18, 8))
        a.rest(s_, 0.0).world(s_, 0.4, lean, cover.copy(arc=(0.04, -0.08, 0.02)), "out").world(s_, 2.0, lean, cover).rest(s_, 2.4, "ease")
        a.rest(o_, 0.0).rest(o_, 0.15).world(o_, 0.55, lean, shoulder, "out").world(o_, 2.0, lean, shoulder).rest(o_, 2.4, "ease")
        a.f(0.0).f(0.35, "out", worry=0.7, brows=0.5, tight=0.4, lids=0.8).f(2.0, "ease", worry=0.7, brows=0.5, tight=0.4, lids=0.8).f(2.4, "ease")
        clips["cover_eyes_" + nm] = clip("cover_eyes_" + nm, 2.4, a, kind="react", tags=["grief", "care"], blend_in=0.15, blend_out=0.5, groups=UP)

    # ---- make room for the one coming from side sd: two shuffles away, a hand: after you
    for sd, nm in ((1.0, "l"), (-1.0, "r")):
        s_ = "L" if sd > 0 else "R"
        o_ = "R" if sd > 0 else "L"
        a = Act(1.4, drag=0.8)
        a.t(0.0).t(0.25, "out", hips_loc=(-0.03 * sd, 0, -0.01), chest=(4, 0, 6 * sd), head=(6, 0, 14 * sd))
        a.t(0.8, "ease", hips_loc=(-0.06 * sd, 0, -0.01), chest=(6, 0, 8 * sd), head=(10, 0, 16 * sd)).t(1.1, "out", chest=(2, 0, 4 * sd), head=(4, 0, 10 * sd)).t(1.4, "ease")
        a.foot(o_, 0.0).foot(o_, 0.3, (-0.10 * sd, 0, 0), "out", lift=0.04).foot(o_, 0.75, (-0.18 * sd, 0, 0), "out", lift=0.04).foot(o_, 1.4, (-0.18 * sd, 0, 0))
        a.foot(s_, 0.0).foot(s_, 0.15).foot(s_, 0.5, (-0.10 * sd, 0, 0), "out", lift=0.04).foot(s_, 0.95, (-0.18 * sd, 0, 0), "out", lift=0.04).foot(s_, 1.4, (-0.18 * sd, 0, 0))
        after = arm_at(s_, w=body_pt(0.30, -0.28, z_waist + 0.02), along=(0.7, -0.6, -0.1), palm=(0.0, -0.2, 0.98), pole=(0.8, 0.5, -0.4), curl=(8, 2, -6), sh=(0, -4, 0))
        a.rest(s_, 0.0).rest(s_, 0.3).arm(s_, 0.7, after.copy(arc=(0.0, -0.08, 0.04)), "out").arm(s_, 1.05, after).rest(s_, 1.4, "ease")
        a.f(0.0).f(0.3, "out", smile=0.4, brows=0.5, tight=0.2).f(1.1, "ease", smile=0.35, brows=0.3).f(1.4, "ease")
        clips["make_room_" + nm] = clip("make_room_" + nm, 1.4, a, kind="react", tags=["courtesy"], blend_in=0.12, blend_out=0.5, move_m=0.18)

    # ---- grab the one on side sd: a lunge, both hands seize their arm, hold on
    for sd, nm in ((1.0, "l"), (-1.0, "r")):
        s_ = "L" if sd > 0 else "R"
        o_ = "R" if sd > 0 else "L"
        a = Act(1.4, drag=0.6)
        lunge = dict(hips=(6, 0, 14 * sd), hips_loc=(0.10 * sd, -0.03, -0.06), spine=(6, 0, 8 * sd), chest=(8, 0, 10 * sd), neck=(0, 0, 4 * sd), head=(-4, 0, 10 * sd))
        a.t(0.0).t(0.10, "out", chest=(-3, 0, -3 * sd), head=(-3, 0, 4 * sd)).t(0.32, "snap", **lunge).t(0.5, "settle", **dict(lunge, hips_loc=(0.08 * sd, -0.02, -0.05)))
        a.t(1.4, "ease", **dict(lunge, hips_loc=(0.06 * sd, 0.0, -0.04), chest=(4, 0, 10 * sd)))
        a.foot(s_, 0.0).foot(s_, 0.30, (0.22 * sd, -0.08, 0), "snap", lift=0.05).foot(s_, 1.4, (0.22 * sd, -0.08, 0))
        hi = arm_at(s_, w=body_pt(0.55, -0.12, z_chest - 0.04), along=(0.7, -0.2, 0.6), palm=(-0.3, 0.9, 0.0), pole=(0.4, 0.6, -0.8), curl=(70, 60, 40))
        lo = arm_at(o_, w=body_pt(-0.40, -0.26, z_chest - 0.16), along=(-0.8, -0.2, 0.4), palm=(-0.1, 0.6, -0.8), pole=(0.3, 0.3, -1.0), curl=(75, 65, 40))
        a.rest(s_, 0.0).world(s_, 0.30, lunge, hi.copy(arc=(0.04, -0.08, 0.04)), "snap").world(s_, 1.4, lunge, hi.copy(w=hi.w + Vector((-0.04 * sd * k, 0, 0))))
        a.rest(o_, 0.0).world(o_, 0.34, lunge, lo.copy(arc=(0.0, -0.10, 0.0)), "snap").world(o_, 1.4, lunge, lo)
        a.f(0.0).f(0.1, "out", stern=0.6, brows=-0.4).f(0.3, "snap", stern=0.9, tight=0.7, brows=-0.7, lids=0.8).f(1.4, "ease", stern=0.85, tight=0.6, brows=-0.6, lids=0.85)
        clips["grab_" + nm] = clip("grab_" + nm, 1.4, a, kind="react", hold=True, tags=["force"], blend_in=0.06, blend_out=0.5)

    # ---- count it off on the fingers: the left hand up, the right index taps each finger, lips moving
    a = Act(2.0, drag=0.8)
    bent = dict(chest=(4, 0, 0), neck=(6, 0, 0), head=(16, 0, 0))
    a.t(0.0).t(0.3, "out", **bent).t(1.7, "ease", **bent).t(2.0, "ease")
    held = arm_at("L", w=body_pt(0.06, -0.30, z_chest - 0.02), along=(-0.35, -0.35, 0.87), palm=(-0.2, 0.95, 0.2), pole=(0.9, 0.3, -0.4), curl=(-8, -12, -10), sh=(0, -4, 0))
    a.rest("L", 0.0).arm("L", 0.3, held, "out").arm("L", 1.75, held).rest("L", 2.0, "ease")
    tap0 = arm_at("R", w=body_pt(0.03, -0.30, z_chest - 0.02), along=(0.6, -0.5, 0.6), palm=(0.4, 0.0, -0.9), pole=(0.9, 0.4, -0.4), curl=(80, -10, 50), sh=(0, -4, 0))
    a.rest("R", 0.0).arm("R", 0.35, tap0, "out")
    for i in range(4):
        t = 0.55 + 0.3 * i
        a.arm("R", t, tap0.copy(w=tap0.w + mv(Vector((-0.012 * i * k, -0.01 * k, 0.025 * i * k)), "R")), "out")
        a.arm("R", t + 0.12, tap0.copy(w=tap0.w + mv(Vector((-0.012 * i * k, 0.02 * k, 0.025 * i * k)), "R")), "ease")
    a.rest("R", 2.0, "ease")
    a.f(0.0).f(0.3, "out", stern=0.4, brows=-0.3, lids=0.85, eyes_y=-0.6).f(1.7, "ease", stern=0.4, brows=-0.3, lids=0.85, eyes_y=-0.6).f(2.0, "ease")
    c = clip("count_fingers", 2.0, a, kind="ambient", tags=["pedant", "comic"], groups=UP, blend_in=0.15, blend_out=0.4)
    clips["count_fingers"] = face_plus(c, lambda t: {"jaw": lips(t, 0.5, 1.75)})

    # ---- point at the one on side sd: the arm out, the index jabbing on the word, the head along it
    for sd, nm in ((1.0, "l"), (-1.0, "r")):
        s_ = "L" if sd > 0 else "R"
        a = Act(1.6, drag=0.8)
        a.t(0.0).t(0.12, "out", chest=(-2, 0, -2 * sd)).t(0.4, "back", chest=(2, 0, 8 * sd), neck=(0, 0, 4 * sd), head=(-2, 0, 14 * sd))
        a.t(1.2, "ease", chest=(2, 0, 8 * sd), neck=(0, 0, 4 * sd), head=(-2, 0, 14 * sd)).t(1.6, "ease")
        aim = arm_at(s_, w=body_pt(0.52, -0.38, z_chest + 0.02), along=(0.6, -0.78, 0.15), palm=(-0.15, 0.1, -0.98), pole=(0.6, 0.6, -0.4), curl=(85, -10, 45), sh=(0, -4, 0))
        cock = arm_at(s_, w=body_pt(0.26, -0.14, z_chest + 0.04), along=(0.4, -0.7, 0.4), palm=(-0.1, 0.2, -0.95), pole=(0.8, 0.5, -0.3), curl=(85, -10, 45))
        a.rest(s_, 0.0).arm(s_, 0.15, cock, "out").arm(s_, 0.40, aim, "back").arm(s_, 0.6, aim.copy(w=aim.w + mv(Vector((0.02 * k, -0.05 * k, 0.0)), s_)), "out")
        a.arm(s_, 0.75, aim, "ease").arm(s_, 1.2, aim).rest(s_, 1.6, "ease")
        a.f(0.0).f(0.4, "snap", brows=0.5, lids=1.1, eyes_x=sd).f(1.2, "ease", brows=0.4, lids=1.05, eyes_x=sd).f(1.6, "ease")
        clips["point_" + nm] = clip("point_" + nm, 1.6, a, kind="react", tags=["point"], groups=one_arm(s_), hands=s_, blend_in=0.1, blend_out=0.45)

    # ---- point up at the god (for the stranger who has not looked): a look at them, then up
    a = Act(1.6, drag=0.8)
    a.t(0.0).t(0.25, "out", chest=(1, 0, 6), head=(2, 0, 14)).t(0.6, "back", chest=(-6, 0, 2), neck=(-4, 0, 0), head=(-18, 0, 4))
    a.t(1.25, "ease", chest=(-6, 0, 2), neck=(-4, 0, 0), head=(-18, 0, 4)).t(1.6, "ease")
    up_ = arm_at("R", w=body_pt(0.20, -0.30, z_chest + 0.46), along=(0.2, -0.45, 0.87), palm=(-0.2, 0.0, -0.98), pole=(0.9, 0.3, -0.3), curl=(85, -10, 45), sh=(0, -10, 0))
    a.rest("R", 0.0).rest("R", 0.25).arm("R", 0.62, up_.copy(arc=(0.08, -0.06, 0.0)), "back").arm("R", 1.25, up_).rest("R", 1.6, "ease")
    a.f(0.0).f(0.25, "out", brows=0.6, eyes_x=1.0, lids=1.1).f(0.6, "ease", brows=0.8, eyes_y=1.0, lids=1.2, jaw=0.2).f(1.25, "ease", brows=0.7, eyes_y=1.0, lids=1.15).f(1.6, "ease")
    clips["point_up"] = clip("point_up", 1.6, a, kind="react", tags=["point", "awe"], groups=one_arm("R"), hands="R", blend_in=0.1, blend_out=0.45)

    # ---- a finger raised to correct someone ("ah, but"); then thought better of and lowered
    a = Act(1.2, drag=0.8)
    a.t(0.0).t(0.12, "out", chest=(-2, 0, 0), head=(-3, 0, 0)).t(0.35, "back", hips_loc=(0, -0.01, 0), chest=(3, 0, -3), head=(-6, 0, -4)).t(1.2, "ease", chest=(3, 0, -3), head=(-6, 0, -4))
    finger = arm_at("R", w=body_pt(0.16, -0.20, z_chest + 0.24), along=(-0.05, -0.25, 0.97), palm=(-0.2, -0.95, 0.1), pole=(0.9, 0.3, -0.4), curl=(85, -12, 50), sh=(0, -6, 0))
    a.rest("R", 0.0).arm("R", 0.35, finger.copy(arc=(0.04, -0.06, 0.0)), "back").arm("R", 1.2, finger)
    a.f(0.0).f(0.12, "out", lids=1.1).f(0.35, "snap", brows=0.8, jaw=0.25, lids=1.15).f(1.2, "ease", brows=0.75, jaw=0.2, lids=1.1)
    clips["raise_finger"] = clip("raise_finger", 1.2, a, kind="react", hold=True, tags=["pedant", "comic"], groups=one_arm("R"), hands="R", blend_in=0.1, blend_out=0.4)
    a = Act(1.2, drag=1.0)
    a.t(0.0, "ease", chest=(3, 0, -3), head=(-6, 0, -4)).t(0.5, "ease", chest=(3, 0, -3), head=(-4, 0, -4)).t(1.2, "ease", chest=(4, 0, 0), head=(6, 0, 0))
    a.arm("R", 0.0, finger).arm("R", 0.35, finger.copy(curl=(85, 20, 50))).arm("R", 1.0, a.rest_arm["R"], "ease").arm("R", 1.2, a.rest_arm["R"])
    a.f(0.0, "ease", brows=0.75, jaw=0.2, lids=1.1).f(0.4, "ease", brows=0.2, tight=0.6).f(1.2, "ease", tight=0.6, lids=0.8, eyes_y=-0.5)
    clips["lower_finger"] = clip("lower_finger", 1.2, a, kind="react", tags=["pedant", "comic"], groups=one_arm("R"), hands="R", blend_in=0.05, blend_out=0.5)

    # ---- the soft clap of the flatterer: two claps, a third that dies when nobody joins, a look round
    a = Act(2.0, drag=0.8)
    a.t(0.0).t(0.2, "out", chest=(-2, 0, 0), head=(-4, 0, 0)).t(1.05, "ease", chest=(-2, 0, 0), head=(-4, 0, 0))
    a.t(1.35, "out", chest=(0, 0, 3), head=(2, 0, 16)).t(1.65, "out", chest=(0, 0, -3), head=(2, 0, -14)).t(2.0, "ease")
    for s_ in "LR":
        apart = arm_at(s_, w=body_pt(0.12, -0.30, z_chest - 0.02), along=(-0.5, -0.5, 0.7), palm=(-0.95, 0.0, 0.2), pole=(0.9, 0.3, -0.4), curl=(8, 2, -4), sh=(0, -4, 0))
        hit = apart.copy(w=apart.w + mv(Vector((-0.085 * k, 0, 0)), s_))
        a.rest(s_, 0.0).arm(s_, 0.22, apart, "out")
        a.arm(s_, 0.34, hit, "in").arm(s_, 0.46, apart, "out").arm(s_, 0.58, hit, "in").arm(s_, 0.72, apart, "out")
        a.arm(s_, 0.98, hit.copy(w=hit.w + mv(Vector((0.03 * k, 0, 0)), s_)), "ease").arm(s_, 1.6, hit.copy(w=hit.w + mv(Vector((0.02 * k, 0.02 * k, -0.05 * k)), s_)))
        a.rest(s_, 2.0, "ease")
    a.f(0.0).f(0.2, "out", smile=0.8, brows=0.5, lids=0.9).f(0.9, "ease", smile=0.6, brows=0.4).f(1.3, "ease", smile=0.3, worry=0.3, brows=0.5).f(2.0, "ease", tight=0.3)
    clips["clap_soft"] = clip("clap_soft", 2.0, a, kind="react", tags=["flatterer", "comic"], groups=UP, blend_in=0.12, blend_out=0.45)

    # ---- edge forward: a sidling step nearer the front, in place (the stage carries them 0.16 m)
    a = Act(1.1, drag=0.8)
    a.t(0.0).t(0.25, "out", hips_loc=(0, -0.01, -0.012), chest=(3, 0, 0), head=(-3, 0, 0)).t(0.55, "ease", hips_loc=(0, -0.015, 0.0), chest=(2, 0, 0), head=(-4, 0, 3))
    a.t(1.1, "ease", head=(-2, 0, 0))
    a.foot("R", 0.0).foot("R", 0.35, lift=0.05).foot("R", 1.1)
    a.foot("L", 0.0).foot("L", 0.35).foot("L", 0.7, lift=0.04).foot("L", 1.1)
    a.f(0.0).f(0.3, "out", tight=0.3, eyes_x=0.6).f(0.7, "out", tight=0.3, eyes_x=-0.6).f(1.1, "ease", tight=0.2)
    clips["edge_forward"] = clip("edge_forward", 1.1, a, kind="react", tags=["jealous", "comic"], blend_in=0.12, blend_out=0.35, move_m=0.16)

    # ---- shoo the animal on side sd: a lean, the near hand flapping low, a stamp
    for sd, nm in ((1.0, "l"), (-1.0, "r")):
        s_ = "L" if sd > 0 else "R"
        a = Act(1.2, drag=0.6)
        lean = dict(hips_loc=(0.04 * sd, -0.02, -0.04), spine=(8, 2 * sd, 4 * sd), chest=(10, 2 * sd, 6 * sd), neck=(6, 0, 4 * sd), head=(14, 0, 12 * sd))
        a.t(0.0).t(0.2, "out", **lean).t(0.95, "ease", **lean).t(1.2, "ease")
        flap0 = arm_at(s_, w=body_pt(0.40, -0.30, 0.72), along=(0.5, -0.6, -0.6), palm=(0.6, -0.5, 0.0), pole=(0.8, 0.6, 0.0), curl=(4, -4, -6))
        a.rest(s_, 0.0).world(s_, 0.2, lean, flap0, "out")
        for i in range(4):
            a.world(s_, 0.32 + 0.14 * i, lean, flap0.copy(w=flap0.w + mv(Vector((0.07 * k if i % 2 == 0 else 0.0, 0, 0)), s_),
                                                         along=L.Quaternion(Vector((0, 1, 0)), math.radians(30 if i % 2 == 0 else -10) * (1 if s_ == "L" else -1)) @ flap0.along), "out")
        a.rest(s_, 1.2, "ease")
        a.foot(s_, 0.0).foot(s_, 0.45, lift=0.06, kind="in").foot(s_, 1.2)
        a.f(0.0).f(0.2, "out", stern=0.6, tight=0.6, eyes_x=sd, eyes_y=-0.6).f(1.0, "ease", stern=0.5, tight=0.5, eyes_x=sd, eyes_y=-0.6).f(1.2, "ease")
        c = clip("shoo_" + nm, 1.2, a, kind="react", tags=["animal", "comic"], hands=s_, blend_in=0.1, blend_out=0.4)
        clips["shoo_" + nm] = face_plus(c, lambda t: {"jaw": 0.25 * pulses(t, 0.3, 0.14, 4, 0.9)})

    # ---- tug the sleeve of the one on side sd (a child's way): reach, pinch, two tugs, look up
    for sd, nm in ((1.0, "l"), (-1.0, "r")):
        s_ = "L" if sd > 0 else "R"
        a = Act(1.2, drag=0.8)
        a.t(0.0).t(0.3, "out", chest=(0, 0, 6 * sd), neck=(-3, 0, 4 * sd), head=(-12, 0, 16 * sd)).t(1.0, "ease", chest=(0, 0, 6 * sd), neck=(-3, 0, 4 * sd), head=(-12, 0, 16 * sd)).t(1.2, "ease")
        pinch = arm_at(s_, w=body_pt(0.42, -0.10, z_waist + 0.10), along=(0.8, -0.3, 0.4), palm=(-0.2, 0.2, -0.95), pole=(0.6, 0.6, -0.4), curl=(60, 55, 40))
        pulled = pinch.copy(w=pinch.w + mv(Vector((-0.07 * k, 0.0, -0.02 * k)), s_))
        a.rest(s_, 0.0).arm(s_, 0.3, pinch, "out").arm(s_, 0.45, pulled, "in").arm(s_, 0.58, pinch, "out").arm(s_, 0.72, pulled, "in").arm(s_, 0.95, pinch, "out").rest(s_, 1.2, "ease")
        a.f(0.0).f(0.3, "out", brows=0.7, worry=0.3, lids=1.15, eyes_x=sd, eyes_y=0.6).f(1.0, "ease", brows=0.6, lids=1.1, eyes_x=sd, eyes_y=0.6).f(1.2, "ease")
        clips["tug_sleeve_" + nm] = clip("tug_sleeve_" + nm, 1.2, a, kind="react", tags=["child"], groups=one_arm(s_), hands=s_, blend_in=0.1, blend_out=0.4)

    # ---- over-thanking: hands pressed together, bob after bob, beaming
    a = Act(3.0, drag=0.9)
    for i in range(5):
        t0 = 0.15 + 0.55 * i
        a.t(t0, "out", hips=(6, 0, 0), hips_loc=(0, 0.02, -0.01), spine=(8, 0, 0), chest=(8, 0, 0), neck=(4, 0, 0), head=(10, 0, 0))
        a.t(t0 + 0.27, "out", hips=(1, 0, 0), chest=(0, 0, 0), head=(-2, 0, 0))
    a.torso_keys.insert(0, (0.0, torso_of(a.B, tpose()), "ease"))
    a.t(3.0, "ease")
    for s_ in "LR":
        pray = arm_at(s_, w=body_pt(0.03, -0.24, z_chest - 0.02), along=(-0.3, -0.2, 0.93), palm=(-0.98, 0.1, 0.0), pole=(0.9, 0.4, -0.3), curl=(6, 2, 0))
        a.rest(s_, 0.0).arm(s_, 0.2, pray, "out").arm(s_, 2.8, pray).rest(s_, 3.0, "ease")
    a.f(0.0).f(0.2, "out", smile=0.9, brows=0.6, lids=0.8).f(2.8, "ease", smile=0.9, brows=0.6, lids=0.8).f(3.0, "ease", smile=0.5)
    c = clip("over_thank", 3.0, a, kind="bow", tags=["deference", "comic"], blend_in=0.12, blend_out=0.4, groups=UP)
    clips["over_thank"] = face_plus(c, lambda t: {"jaw": lips(t, 0.2, 2.8, 3.5, 0.2)})

    # ---- clear the throat: a fist to the mouth, a small jerk, chin up, straightened
    a = Act(1.0, drag=0.7)
    a.t(0.0).t(0.2, "out", chest=(-2, 0, 0), head=(-2, 0, -4)).t(0.32, "snap", chest=(4, 0, 0), head=(6, 0, -6)).t(0.5, "out", chest=(-4, 0, 0), head=(-6, 0, 0)).t(1.0, "ease", chest=(-2, 0, 0), head=(-3, 0, 0))
    fist = hand_mouth("R", cover=True).copy(curl=(85, 75, 45))
    a.rest("R", 0.0).arm("R", 0.22, fist, "out").arm("R", 0.5, fist).rest("R", 1.0, "ease")
    a.f(0.0).f(0.32, "snap", lids=0.5, jaw=0.3, tight=0.3).f(0.5, "ease", lids=0.95, tight=0.5, stern=0.2).f(1.0, "ease", tight=0.3)
    clips["clear_throat"] = clip("clear_throat", 1.0, a, kind="ambient", tags=["pompous"], groups=one_arm("R"), hands="R", blend_in=0.08, blend_out=0.35)

    # ---- smooth the clothes: both hands down the front, twice; a tug of the hem
    a = Act(1.5, drag=0.9)
    a.t(0.0).t(0.3, "out", chest=(6, 0, 0), neck=(5, 0, 0), head=(16, 0, 0)).t(1.1, "ease", chest=(5, 0, 0), head=(12, 0, 0)).t(1.5, "ease", chest=(-3, 0, 0), head=(-4, 0, 0))
    for s_ in "LR":
        top = arm_at(s_, w=body_pt(0.10, -0.20, z_chest - 0.06), along=(-0.2, -0.3, -0.93), palm=(0.0, 1.0, 0.0), pole=(0.9, 0.4, 0.0), curl=(4, 0, -4))
        low = arm_at(s_, w=body_pt(0.13, -0.16, z_hip + 0.02), along=(0.0, -0.3, -0.95), palm=(0.0, 1.0, 0.0), pole=(0.9, 0.4, 0.0), curl=(4, 0, -4))
        tug = arm_at(s_, w=body_pt(0.16, -0.16, z_hip - 0.12), along=(0.1, -0.3, -0.95), palm=(-0.6, 0.6, 0.0), pole=(0.9, 0.4, 0.0), curl=(60, 50, 30))
        a.rest(s_, 0.0).arm(s_, 0.25, top, "out").arm(s_, 0.5, low, "ease").arm(s_, 0.62, top, "out").arm(s_, 0.85, low, "ease").arm(s_, 1.05, tug, "out")
        a.arm(s_, 1.18, tug.copy(w=tug.w + Vector((0, 0, -0.03 * k))), "in").rest(s_, 1.5, "ease")
    a.f(0.0).f(0.3, "out", tight=0.4, lids=0.8, eyes_y=-0.6).f(1.2, "ease", tight=0.3, lids=0.9).f(1.5, "ease", smile=0.2)
    clips["smooth_clothes"] = clip("smooth_clothes", 1.5, a, kind="ambient", tags=["vain", "nervous"], groups=UP, blend_in=0.12, blend_out=0.4)

    # ---- sit down on the floor: down through a crouch, knees up, forearms on the knees. Holds.
    a = Act(1.8, drag=1.0)
    seat = dict(hips=(-8, 0, 0), hips_loc=(0.0, 0.10, -0.74), spine=(14, 0, 0), chest=(8, 0, 0), neck=(-6, 0, 0), head=(-8, 0, 0))
    a.t(0.0).t(0.55, "in", hips=(20, 0, 0), hips_loc=(0, 0.10, -0.40), spine=(14, 0, 0), chest=(8, 0, 0), head=(-6, 0, 0)).t(1.05, "ease", **seat).t(1.8, "ease", **seat)
    for s_ in "LR":
        out_ = 1.0 if s_ == "L" else -1.0
        a.foot(s_, 0.0).foot(s_, 0.55).foot(s_, 1.05, (0.04 * out_, -0.30, 0.0), "out", rot=(-20, 0, 8 * out_)).foot(s_, 1.8, (0.04 * out_, -0.30, 0.0), rot=(-20, 0, 8 * out_))
    up_knees = {"L": Vector((0.25, -0.5, 0.83)).normalized(), "R": Vector((-0.25, -0.5, 0.83)).normalized()}

    def knees_sit(t, K0=dict(a.KNEES), S=up_knees):
        u = L.curve("ease", (t - 0.3) / 0.8)
        return {s2: K0[s2].lerp(S[s2], u).normalized() for s2 in "LR"}
    a.knee_fn = knees_sit
    full = torso_of(a.B, tpose(**seat))
    plant(full, {s2: a.FEET[s2] + Vector((0.04 * (1 if s2 == "L" else -1) * k, -0.30 * k, 0)) for s2 in "LR"}, up_knees,
          {s2: (-20, 0, 8 * (1 if s2 == "L" else -1)) for s2 in "LR"})
    knees_at = legs_fk(full)
    for s_ in "LR":
        kn = knees_at[s_][1]
        rest_on = ArmKey(kn + Vector((0.0, -0.10 * k, 0.03 * k)), mv(Vector((0.6, 0.6, -0.4)), s_), Vector((0.0, -0.9, -0.4)), Vector((0.0, 0.2, -0.98)), (40, 30, 14))
        a.rest(s_, 0.0).rest(s_, 0.5).world(s_, 1.2, seat, rest_on, "ease").world(s_, 1.8, seat, rest_on)
    a.f(0.0).f(1.0, "ease", lids=0.85).f(1.8, "ease", lids=0.8)
    clips["sit_floor"] = clip("sit_floor", 1.8, a, kind="react", hold=True, tags=["tired", "comic"], blend_in=0.15, blend_out=0.8)

    # ---- wave at the god: the arm high, the hand going side to side, up on the toes, beaming
    a = Act(1.6, drag=0.7)
    a.t(0.0).t(0.2, "out", chest=(-4, 0, 0), head=(-10, 0, 0)).t(1.3, "ease", chest=(-4, 0, 0), head=(-10, 0, 0)).t(1.6, "ease")
    hi = arm_at("R", w=body_pt(0.30, -0.10, z_chest + 0.52), along=(0.15, -0.15, 0.97), palm=(-0.1, -0.98, 0.1), pole=(0.9, 0.3, -0.2), curl=(0, -6, -8), sh=(0, -14, 0))
    a.rest("R", 0.0).arm("R", 0.22, hi.copy(arc=(0.1, -0.06, 0.0)), "out")
    for i in range(6):
        sw = 1.0 if i % 2 == 0 else -1.0
        a.arm("R", 0.34 + 0.15 * i, hi.copy(w=hi.w + mv(Vector((0.03 * k * sw, 0, 0)), "R"),
                                            along=L.Quaternion(Vector((0, 1, 0)), math.radians(-28 * sw)) @ hi.along), "ease")
    a.rest("R", 1.6, "ease")
    bounce = lambda t: pulses(t, 0.3, 0.3, 4, 0.9)
    a.on_top(lambda t: {"hips": {"loc": (0, 0, 0.014 * bounce(t))}})
    for s_ in "LR":
        a.foot(s_, 0.0).foot(s_, 0.3, (0, 0, 0.03), rot=(18, 0, 0)).foot(s_, 1.3, (0, 0, 0.03), rot=(18, 0, 0)).foot(s_, 1.6)
    a.f(0.0).f(0.2, "out", smile=1.0, brows=0.8, lids=1.1, eyes_y=0.8, jaw=0.3).f(1.3, "ease", smile=1.0, brows=0.8, lids=1.1, eyes_y=0.8, jaw=0.25).f(1.6, "ease")
    clips["wave"] = clip("wave", 1.6, a, kind="react", tags=["child", "joy", "comic"], hands="R", blend_in=0.1, blend_out=0.4)

    # ---- wipe the hands down the front of the thighs, twice
    a = Act(1.1, drag=0.8)
    a.t(0.0).t(0.25, "out", chest=(5, 0, 0), head=(12, 0, 0)).t(0.9, "ease", chest=(5, 0, 0), head=(10, 0, 0)).t(1.1, "ease")
    for s_ in "LR":
        hi_ = arm_at(s_, w=body_pt(0.15, -0.10, z_hip - 0.02), along=(0.0, -0.35, -0.94), palm=(-0.3, 0.95, 0.0), pole=(0.9, 0.5, 0.0), curl=(4, 0, -4))
        lo_ = hi_.copy(w=hi_.w + Vector((0, -0.01 * k, -0.14 * k)))
        a.rest(s_, 0.0).arm(s_, 0.2, hi_, "out").arm(s_, 0.42, lo_, "ease").arm(s_, 0.55, hi_, "out").arm(s_, 0.78, lo_, "ease").rest(s_, 1.1, "ease")
    a.f(0.0).f(0.3, "out", eyes_y=-0.8, lids=0.85, tight=0.2).f(1.1, "ease")
    clips["wipe_hands"] = clip("wipe_hands", 1.1, a, kind="ambient", tags=["work", "nervous"], groups=UP, blend_in=0.1, blend_out=0.35)

    # ---- mortified: both hands fly to the cheeks, shoulders up, the head sinking
    a = Act(1.6, drag=0.6)
    a.t(0.0).t(0.12, "snap", chest=(-4, 0, 0), head=(-6, 0, 0)).t(0.5, "out", chest=(6, 0, 0), neck=(4, 0, 0), head=(12, 0, 0))
    a.t(1.3, "ease", chest=(7, 0, 0), neck=(4, 0, 0), head=(14, 0, 0)).t(1.6, "ease")
    for s_ in "LR":
        cheek = arm_at(s_, w=None, contact=lm["cheek"] + Vector((0.01 * k, -0.02 * k, -0.01 * k)), along=(-0.25, -0.1, 0.96), palm=(-0.95, 0.2, 0.0),
                       pole=(0.6, 0.0, -0.8), curl=(10, 4, 0), sh=(0, -14, -6), reach=0.45)
        a.rest(s_, 0.0).arm(s_, 0.16, cheek.copy(arc=(0.04, -0.08, 0.0)), "snap").arm(s_, 1.3, cheek).rest(s_, 1.6, "ease")
    a.f(0.0).f(0.12, "snap", lids=1.4, brows=1.0, jaw=0.45, worry=0.6).f(0.6, "ease", lids=0.4, worry=0.9, tight=0.5, brows=0.8).f(1.3, "ease", lids=0.35, worry=0.9, tight=0.6).f(1.6, "ease")
    clips["mortified"] = clip("mortified", 1.6, a, kind="react", tags=["shame", "comic"], groups=UP, blend_in=0.06, blend_out=0.45)

    # ---- count the heads in the hall: the index finger ticking across the room, lips moving
    a = Act(2.2, drag=0.8)
    a.t(0.0)
    for i in range(6):
        yaw = -22 + 9 * i
        a.t(0.25 + 0.3 * i, "out", chest=(0, 0, yaw * 0.25), neck=(0, 0, yaw * 0.25), head=(-2, 0, yaw * 0.5))
    a.t(2.2, "ease")
    for i in range(6):
        yaw = math.radians(-22 + 9 * i)
        w_ = Vector((0.18 + 0.30 * math.sin(-yaw * 1.4), -0.42, z_chest + 0.05))
        tick = arm_at("R", w=body_pt(*w_), along=(-0.6 * math.sin(yaw), -0.8, 0.1), palm=(0.0, 0.1, -0.98), pole=(0.8, 0.5, -0.3), curl=(85, -10, 45))
        a.arm("R", 0.25 + 0.3 * i, tick, "out")
    a.arm_keys["R"].insert(0, (0.0, a.rest_arm["R"], "ease"))
    a.rest("R", 2.2, "ease")
    a.f(0.0).f(0.25, "out", lids=0.85, tight=0.2).f(2.0, "ease", lids=0.85, tight=0.2).f(2.2, "ease")
    c = clip("count_heads", 2.2, a, kind="ambient", tags=["pedant", "comic"], groups=one_arm("R"), hands="R", blend_in=0.12, blend_out=0.4)
    clips["count_heads"] = face_plus(c, lambda t: {"jaw": lips(t, 0.3, 2.0, 3.3)})

    # ---- measure the hall with a thumb held out, one eye half shut, then another spot
    a = Act(2.2, drag=1.0)
    a.t(0.0).t(0.35, "out", chest=(-4, 0, -2), neck=(-4, 0, 0), head=(-14, 6, -6)).t(1.2, "ease", chest=(-4, 0, -2), head=(-14, 6, -6))
    a.t(1.5, "out", chest=(-5, 0, 6), neck=(-4, 0, 4), head=(-16, 6, 10)).t(1.9, "ease", chest=(-5, 0, 6), head=(-16, 6, 10)).t(2.2, "ease")
    th1 = arm_at("R", w=body_pt(0.16, -0.48, z_chest + 0.30), along=(0.1, -0.6, 0.8), palm=(-0.9, 0.0, 0.4), pole=(0.9, 0.3, -0.3), curl=(80, 75, -25))
    th2 = th1.copy(w=th1.w + mv(Vector((-0.20 * k, 0.04 * k, 0.04 * k)), "R"))
    a.rest("R", 0.0).arm("R", 0.35, th1, "out").arm("R", 1.2, th1).arm("R", 1.5, th2, "out").arm("R", 1.9, th2).rest("R", 2.2, "ease")
    a.f(0.0).f(0.35, "out", lids=0.55, tight=0.4, eyes_y=0.6, brows=-0.2).f(1.9, "ease", lids=0.55, tight=0.4, eyes_y=0.6).f(2.2, "ease")
    clips["thumb_measure"] = clip("thumb_measure", 2.2, a, kind="ambient", tags=["builder", "comic"], groups=one_arm("R"), hands="R", blend_in=0.12, blend_out=0.4)

    # ---- stroke the chin, appraising: one hand at the chin, the other arm across under its elbow
    a = Act(2.2, drag=1.0)
    a.t(0.0).t(0.35, "out", chest=(2, 0, 0), head=(4, 4, 6)).t(1.1, "ease", chest=(2, 0, 0), head=(6, 4, 8)).t(1.5, "ease", head=(2, 4, -4)).t(1.9, "ease", head=(4, 4, 4)).t(2.2, "ease")
    chin = arm_at("R", w=None, contact=lm["chin"] + Vector((0.01 * k, -0.02 * k, -0.02 * k)), along=(-0.35, -0.4, 0.85), palm=(-0.4, 0.9, 0.0), pole=(0.7, 0.1, -0.8), curl=(50, 20, 30), reach=0.40)
    under = arm_at("L", w=body_pt(-0.06, -0.24, z_waist + 0.10), along=(-0.9, -0.2, 0.2), palm=(0.0, 0.3, 0.95), pole=(0.6, 0.3, -0.8), curl=(40, 30, 15))
    a.rest("R", 0.0).arm("R", 0.35, chin, "out")
    for i in range(3):
        a.arm("R", 0.6 + 0.4 * i, chin.copy(w=chin.w + Vector((0, 0, -0.025 * k))), "ease").arm("R", 0.8 + 0.4 * i, chin, "ease")
    a.arm("R", 1.9, chin).rest("R", 2.2, "ease")
    a.rest("L", 0.0).arm("L", 0.4, under, "out").arm("L", 1.9, under).rest("L", 2.2, "ease")
    a.f(0.0).f(0.35, "out", lids=0.65, tight=0.3, brows=-0.2).f(1.9, "ease", lids=0.65, tight=0.3, brows=-0.2).f(2.2, "ease")
    clips["stroke_chin"] = clip("stroke_chin", 2.2, a, kind="ambient", tags=["appraise"], groups=UP, blend_in=0.15, blend_out=0.45)

    # ---- fiddle with something small in the fingers (a pebble, a knot), head bent to it
    a = Act(2.0, drag=1.0)
    bent2 = dict(chest=(5, 0, 0), neck=(6, 0, 0), head=(18, 0, 0))
    a.t(0.0).t(0.3, "out", **bent2).t(1.7, "ease", **bent2).t(2.0, "ease")
    for i in range(8):
        t = 0.3 + 0.2 * i
        tw = 1.0 if i % 2 == 0 else -1.0
        for s_ in "LR":
            sg = 1.0 if s_ == "L" else -1.0
            along = Vector((-0.7, -0.5, 0.5)).normalized()
            palm = L.Quaternion(along, math.radians(40 * tw * sg)) @ Vector((-0.3, -0.1, 0.95))
            a.arm(s_, t, arm_at(s_, w=body_pt(0.035, -0.28, z_chest - 0.10), along=along, palm=palm, pole=(1.0, 0.3, -0.3), curl=(55, 45 + 10 * tw, 35)))
    for s_ in "LR":
        a.arm_keys[s_].insert(0, (0.0, a.rest_arm[s_], "ease"))
        a.rest(s_, 2.0, "ease")
    a.f(0.0).f(0.3, "out", lids=0.75, tight=0.35, eyes_y=-0.7).f(1.7, "ease", lids=0.75, tight=0.35, eyes_y=-0.7).f(2.0, "ease")
    clips["fiddle"] = clip("fiddle", 2.0, a, kind="ambient", tags=["nervous", "busy"], groups=UP, blend_in=0.15, blend_out=0.4)

    # ---- set things out on the floor in a line: a crouch, three placings left to right
    a = Act(2.4, drag=1.0)
    low = dict(hips=(26, 0, 0), hips_loc=(0, 0.10, -0.38), spine=(20, 0, 0), chest=(12, 0, 0), neck=(-4, 0, 0), head=(-6, 0, 0))
    a.t(0.0).t(0.5, "in", **low).t(2.0, "ease", **low).t(2.4, "ease")
    a.rest("R", 0.0)
    for i, x in enumerate((-0.12, 0.05, 0.22)):
        place = arm_at("R", w=body_pt(-x, -0.48, 0.10), along=(0.0, -0.4, -0.92), palm=(0.0, 0.2, -0.98), pole=(0.8, 0.5, -0.2), curl=(50, 40, 20))
        a.world("R", 0.65 + 0.45 * i, low, place.copy(w=place.w + Vector((0, 0, 0.08 * k))), "out").world("R", 0.85 + 0.45 * i, low, place, "in")
    a.rest("R", 2.4, "ease")
    knee_l = arm_at("L", w=body_pt(0.14, -0.30, 0.42), along=(0.0, -0.6, -0.8), palm=(0.0, 0.3, -0.95), pole=(0.8, 0.5, -0.2), curl=(35, 25, 10))
    a.rest("L", 0.0).world("L", 0.6, low, knee_l, "ease").world("L", 2.0, low, knee_l).rest("L", 2.4, "ease")
    a.f(0.0).f(0.5, "ease", tight=0.4, lids=0.8, eyes_y=-0.8).f(2.0, "ease", tight=0.4, lids=0.8, eyes_y=-0.8).f(2.4, "ease")
    clips["arrange_floor"] = clip("arrange_floor", 2.4, a, kind="ambient", tags=["pedant", "child", "comic"], blend_in=0.2, blend_out=0.5)

    # ---- sniff with disdain: hands behind the back, chin up, a slow look over the hall, a sniff
    a = Act(2.0, drag=1.1)
    a.t(0.0).t(0.35, "out", chest=(-5, 0, -2), neck=(-3, 0, -6), head=(-12, 0, -16)).t(1.2, "ease", chest=(-5, 0, 2), neck=(-3, 0, 6), head=(-12, 0, 18))
    a.t(1.6, "out", chest=(-5, 0, 0), neck=(-3, 0, 0), head=(-14, 0, 2)).t(2.0, "ease", chest=(-3, 0, 0), head=(-8, 0, 0))
    for s_ in "LR":
        behind = arm_at(s_, w=body_pt(0.0, 0.16, z_hip + 0.06), along=(-0.6, 0.3, -0.7), palm=(0.0, 1.0, 0.1), pole=(0.9, 0.6, 0.0), curl=(40, 30, 15), sh=(0, 4, 8))
        a.rest(s_, 0.0).arm(s_, 0.35, behind, "out").arm(s_, 1.8, behind).rest(s_, 2.0, "ease")
    a.f(0.0).f(0.35, "out", lids=0.7, sneer=0.3, stern=0.3).f(1.3, "ease", lids=0.65, sneer=0.35, stern=0.3).f(1.45, "snap", sneer=0.9, lids=0.5, puff=0.2)
    a.f(1.7, "ease", sneer=0.5, lids=0.65).f(2.0, "ease", sneer=0.3, lids=0.75)
    clips["sniff_disdain"] = clip("sniff_disdain", 2.0, a, kind="ambient", tags=["scorn", "envoy", "comic"], groups=UP, blend_in=0.15, blend_out=0.5)

    # ---- brush something off the sleeve: the left forearm up, the right hand flicking along it
    a = Act(1.2, drag=0.7)
    a.t(0.0).t(0.25, "out", chest=(3, 0, 2), head=(14, 0, 8)).t(1.0, "ease", chest=(3, 0, 2), head=(14, 0, 8)).t(1.2, "ease")
    arm_up = arm_at("L", w=body_pt(-0.02, -0.30, z_waist + 0.12), along=(-0.6, -0.6, 0.2), palm=(0.0, 0.3, -0.95), pole=(0.8, 0.4, -0.5), curl=(30, 20, 10))
    a.rest("L", 0.0).arm("L", 0.22, arm_up, "out").arm("L", 1.0, arm_up).rest("L", 1.2, "ease")
    br0 = arm_at("R", w=body_pt(-0.20, -0.20, z_waist + 0.22), along=(0.7, -0.3, -0.3), palm=(0.0, -0.3, -0.95), pole=(0.8, 0.4, -0.4), curl=(10, 4, 0))
    br1 = br0.copy(w=br0.w + mv(Vector((-0.12 * k, -0.08 * k, -0.02 * k)), "R"))
    a.rest("R", 0.0).arm("R", 0.3, br0, "out").arm("R", 0.42, br1, "snap").arm("R", 0.6, br0, "out").arm("R", 0.72, br1, "snap").rest("R", 1.2, "ease")
    a.f(0.0).f(0.25, "out", sneer=0.6, lids=0.75, eyes_y=-0.6).f(1.0, "ease", sneer=0.5, lids=0.75).f(1.2, "ease")
    clips["brush_sleeve"] = clip("brush_sleeve", 1.2, a, kind="ambient", tags=["scorn", "envoy"], groups=UP, blend_in=0.1, blend_out=0.4)

    # ---- rub the hands, greedy: quick, at the chest, shoulders up, a grin
    a = Act(1.3, drag=0.7)
    a.t(0.0).t(0.2, "out", chest=(4, 0, 0), neck=(4, 0, 0), head=(-2, 0, 0)).t(1.1, "ease", chest=(4, 0, 0), head=(-2, 0, 0)).t(1.3, "ease")
    for s_ in "LR":
        rub = arm_at(s_, w=body_pt(0.03, -0.28, z_chest - 0.04), along=(-0.55, -0.45, 0.7), palm=(-0.95, 0.0, 0.2), pole=(1.0, 0.3, -0.3), curl=(10, 4, 0), sh=(0, -12, -4))
        a.rest(s_, 0.0).arm(s_, 0.2, rub, "out")
        for i in range(6):
            up_ = 0.035 * (1 if (i % 2 == 0) == (s_ == "L") else -1)
            a.arm(s_, 0.3 + 0.12 * i, rub.copy(w=rub.w + Vector((0, 0, up_ * k))))
        a.rest(s_, 1.3, "ease")
    a.f(0.0).f(0.2, "out", smile=0.9, lids=0.65, brows=0.3).f(1.1, "ease", smile=0.9, lids=0.65, brows=0.3).f(1.3, "ease", smile=0.4)
    clips["rub_hands_greedy"] = clip("rub_hands_greedy", 1.3, a, kind="ambient", tags=["greed", "comic"], groups=UP, blend_in=0.1, blend_out=0.4)

    # ---- scribble on a tablet held in the left hand, fast
    a = Act(2.0, drag=0.8)
    bent3 = dict(chest=(6, 0, 0), neck=(6, 0, 0), head=(18, 0, 0))
    a.t(0.0).t(0.3, "out", **bent3).t(1.8, "ease", **bent3).t(2.0, "ease")
    tablet = arm_at("L", w=body_pt(-0.02, -0.30, z_waist + 0.10), along=(-0.7, -0.6, 0.1), palm=(0.0, 0.1, 0.99), pole=(0.8, 0.4, -0.5), curl=(10, 6, 0))
    a.rest("L", 0.0).arm("L", 0.3, tablet, "out").arm("L", 1.8, tablet).rest("L", 2.0, "ease")
    pen = arm_at("R", w=body_pt(-0.02, -0.30, z_waist + 0.18), along=(0.4, -0.6, -0.7), palm=(0.4, 0.0, -0.9), pole=(0.8, 0.5, -0.3), curl=(70, 55, 60))
    a.rest("R", 0.0).arm("R", 0.3, pen, "out")
    for i in range(12):
        a.arm("R", 0.42 + 0.11 * i, pen.copy(w=pen.w + mv(Vector(((0.04 if i % 2 == 0 else -0.01) * k, -0.008 * (i % 3) * k, 0.0)), "R")), "linear")
    a.rest("R", 2.0, "ease")
    a.f(0.0).f(0.3, "out", lids=0.7, tight=0.4, brows=-0.2, eyes_y=-0.8).f(1.8, "ease", lids=0.7, tight=0.4, eyes_y=-0.8).f(2.0, "ease")
    clips["scribble"] = clip("scribble", 2.0, a, kind="ambient", tags=["scribe", "busy"], groups=UP, blend_in=0.12, blend_out=0.4)

    # ---- shake out a cramped hand: it flaps loose at the waist, a wince
    a = Act(1.0, drag=0.6)
    a.t(0.0).t(0.2, "out", chest=(2, 0, 0), head=(8, 0, 0)).t(0.8, "ease", chest=(2, 0, 0), head=(8, 0, 0)).t(1.0, "ease")
    sh0 = arm_at("R", w=body_pt(0.18, -0.24, z_waist + 0.02), along=(0.2, -0.6, -0.7), palm=(-0.95, 0.0, 0.2), pole=(0.9, 0.4, -0.3), curl=(20, 14, 6))
    a.rest("R", 0.0).arm("R", 0.18, sh0, "out")
    for i in range(5):
        a.arm("R", 0.28 + 0.1 * i, sh0.copy(along=L.Quaternion(Vector((1, 0, 0)), math.radians(28 if i % 2 == 0 else -28)) @ sh0.along), "out")
    a.rest("R", 1.0, "ease")
    a.f(0.0).f(0.2, "out", tight=0.6, lids=0.6, worry=0.3).f(0.8, "ease", tight=0.5, lids=0.7).f(1.0, "ease")
    clips["shake_hand"] = clip("shake_hand", 1.0, a, kind="ambient", tags=["scribe"], groups=one_arm("R"), hands="R", blend_in=0.08, blend_out=0.35)

    # ---- fight down a cough: a fist at the mouth, cheeks puffed, jerks held in, eyes watering
    a = Act(1.2, drag=0.6)
    a.t(0.0).t(0.15, "out", chest=(2, 0, -2), head=(6, 0, -8)).t(1.0, "ease", chest=(2, 0, -2), head=(6, 0, -8)).t(1.2, "ease")
    fist2 = hand_mouth("R", cover=True).copy(curl=(85, 75, 45))
    a.rest("R", 0.0).arm("R", 0.16, fist2, "out").arm("R", 0.95, fist2).rest("R", 1.2, "ease")
    held_in = lambda t: pulses(t, 0.25, 0.22, 3, 0.85, 1.5)
    a.on_top(lambda t: {"chest": {"rot": (3.0 * held_in(t), 0, 0)}, "head": {"rot": (3.5 * held_in(t), 0, 0)}, "shoulder.L": {"rot": (0, -4 * held_in(t), 0)}, "shoulder.R": {"rot": (0, 4 * held_in(t), 0)}})
    a.f(0.0).f(0.15, "out", puff=0.8, lids=0.4, worry=0.5, tight=0.3).f(1.0, "ease", puff=0.7, lids=0.4, worry=0.5).f(1.2, "ease")
    clips["stifle_cough"] = clip("stifle_cough", 1.2, a, kind="ambient", tags=["sick", "comic"], groups=one_arm("R"), hands="R", blend_in=0.08, blend_out=0.35)

"""Court acting (K), round 4: the child (J's child body, 1.24 m, a big head on a
slight body), and sitting cross-legged on the floor (for anyone).

Child clips are built only on the child's body (meta bodies: ["child"]); the
acting plays them in place of the grown-up clip of the same name for a child
(court_acting.gd CHILD_MAP): hide behind a grown-up and peek, a bad copy of
the bow, fidget, wave at the god, a giggle held in, shushed and frozen, run
to a parent and cling, and the fidget as a child's lifelong stance.
"""
import math
from mathutils import Vector

import cf_anim
from cf_anim import add, both, side, merge, wave
import court_anims_lib as L
from court_anims_lib import ArmKey, arm_at, arm_fk, arm_solve, legs_fk, plant, tremble, breathe, drift, pulses, mv, landmarks
from court_anims_clips import (Act, clip, torso_of, tpose, body_pt, hand_mouth, hand_heart, hand_belly, hand_thigh, hand_face,
                               stance_arm, hang, UPPER, FULL)
from court_anims_r2 import face_plus, stance_clip

CHILD = ["child"]


def cross_seat(a):
    """Sitting cross-legged, worked out for Act a's body: the torso delta (hips
    down so the hip joints sit a hand above the floor, the back rounded, the
    head up), where each ankle goes (crossed in front: the left under the right
    shin), each knee's way (out to the side and up), each foot's turn (on its
    outer edge, toes pointing across) and the full pose with the legs solved."""
    f = L.FRAME
    k = L.K
    base_z = a.B.get("hips", {}).get("loc", (0, 0, 0))[2]
    base_y = a.B.get("hips", {}).get("loc", (0, 0, 0))[1]
    hip_z = (f.hip["L"].z + f.hip["R"].z) * 0.5
    loc_z = (0.10 * k - hip_z) / k - base_z
    seat = dict(hips=(-12, 0, 0), hips_loc=(0.0, 0.04 - base_y, loc_z), spine=(15, 0, 0), chest=(8, 0, 0), neck=(-6, 0, 0), head=(-12, 0, 0))
    ank_z = f.ankle["L"].z * 0.75
    target = {"L": Vector((-0.10 * k, -0.17 * k, ank_z)), "R": Vector((0.11 * k, -0.27 * k, ank_z + 0.012 * k))}
    off = {s_: (target[s_] - a.FEET[s_]) / k for s_ in "LR"}
    knees = {"L": Vector((0.85, -0.35, 0.40)).normalized(), "R": Vector((-0.85, -0.35, 0.40)).normalized()}
    frot = {"L": (0, 30, -70), "R": (0, -30, 70)}
    full = torso_of(a.B, tpose(**seat))
    plant(full, target, knees, frot)
    return seat, off, knees, frot, full


def knee_rest(full, s_):
    """A hand resting on the knee of a pose (an ArmKey in the hall)."""
    f = L.FRAME
    k = L.K
    kn = legs_fk(full)[s_][1]
    key = ArmKey(kn + Vector((0.0, -0.02 * k, 0.045 * k)), mv(Vector((0.6, 0.6, -0.4)), s_), Vector((0.0, -0.8, -0.6)),
                 Vector((0.0, 0.1, -0.99)), (36, 28, 12))
    key.w = key.w - key.along * (f.hand_len * 0.40)
    return key


def make_cross(clips):
    """Sitting cross-legged on the floor: sitting down into it (and staying),
    and the seat as a stance kept for a while (rocking, looking about)."""
    a = Act(1.6, drag=1.0)
    seat, off, knees, frot, full = cross_seat(a)
    squat = dict(hips=(22, 0, 0), hips_loc=(0, 0.06, seat["hips_loc"][2] * 0.5), spine=(12, 0, 0), chest=(6, 0, 0), head=(-4, 0, 0))
    a.t(0.0).t(0.45, "out", **squat).t(0.80, "in", **dict(seat, hips_loc=(seat["hips_loc"][0], seat["hips_loc"][1], seat["hips_loc"][2] - 0.01)))
    a.t(0.92, "settle", **seat).t(1.6, "ease", **seat)
    for s_ in "LR":
        a.foot(s_, 0.0).foot(s_, 0.55).foot(s_, 0.88, off[s_], "ease", lift=0.03, rot=frot[s_]).foot(s_, 1.6, off[s_], rot=frot[s_])

    def knees_cross(t, K0=dict(a.KNEES), S=knees):
        u = L.curve("ease", (t - 0.5) / 0.4)
        return {s2: K0[s2].lerp(S[s2], u).normalized() for s2 in "LR"}
    a.knee_fn = knees_cross
    for s_ in "LR":
        a.rest(s_, 0.0).rest(s_, 0.3, sh=(0, -8, 0)).world(s_, 1.0, seat, knee_rest(full, s_), "ease").world(s_, 1.6, seat, knee_rest(full, s_))
    a.f(0.0).f(0.8, "snap", lids=0.8, puff=0.3).f(1.6, "ease", lids=0.95)
    clips["sit_cross"] = clip("sit_cross", 1.6, a, kind="react", hold=True, tags=["floor", "child"], blend_in=0.15, blend_out=0.8)

    # the seat kept: a slow rock, a look about, hands on the knees (they stay on
    # the knees as the body rocks: each arm key is worked out for its torso)
    a = Act(6.0, drag=1.2)
    seat, off, knees, frot, full = cross_seat(a)
    a.knee_fn = lambda t, S=knees: S
    for s_ in "LR":
        a.foot(s_, 0.0, off[s_], rot=frot[s_]).foot(s_, 6.0, off[s_], rot=frot[s_])
    rock = [(0.0, seat), (1.5, dict(seat, chest=(11, 0, 3), head=(-12, 0, 8))), (3.0, seat),
            (4.5, dict(seat, chest=(6, 0, -3), head=(-9, 0, -10))), (6.0, seat)]
    for t, ts in rock:
        a.t(t, "ease", **ts)
        for s_ in "LR":
            a.world(s_, t, ts, knee_rest(full, s_), "ease")
    a.on_top(lambda t: breathe(t, 3.0, 0.6, 0.2))
    a.f(0.0, "ease", lids=0.95).f(2.0, "ease", lids=0.95, eyes_x=0.5).f(4.0, "ease", lids=0.95, eyes_x=-0.5).f(6.0, "ease", lids=0.95)
    clips["stance_cross"] = stance_clip("stance_cross", 6.0, a, hands="", tags=["floor", "child"], seated=True,
                                        groups={"legs": 1.0, "torso": 1.0, "head": 1.0, "arm_L": 1.0, "arm_R": 1.0})


def make_child(clips):
    f = L.FRAME
    k = L.K
    z_chest = f.z_chest / k
    z_waist = f.z_waist / k
    z_hip = f.z_hip / k
    lm = landmarks()

    # ---- hide behind a grown-up on side sd (in front of the child, to that side): a
    #      scurry in behind them, fists in the back of their clothes at the child's own
    #      chest, the face pressed to them; then the peek out round the other side, the
    #      fists staying where they hold
    for sd, nm in ((1.0, "l"), (-1.0, "r")):
        s_ = "L" if sd > 0 else "R"
        o_ = "R" if sd > 0 else "L"
        hide_t = dict(hips=(6, 8 * sd, 16 * sd), hips_loc=(0.07 * sd, 0.12, -0.06), spine=(8, 3 * sd, 6 * sd), chest=(8, 3 * sd, 6 * sd),
                      neck=(8, 0, 4 * sd), head=(12, -4 * sd, 12 * sd))
        feet_hide = {s_: (0.16 * sd, 0.18, 0.0), o_: (0.06 * sd, 0.16, 0.0)}
        a = Act(1.1, drag=0.6)
        a.t(0.0).t(0.08, "snap", chest=(-4, 0, 0), head=(-8, 0, 0)).t(0.40, "out", **hide_t).t(1.1, "ease", **hide_t)
        a.foot(s_, 0.0).foot(s_, 0.18, (0.08 * sd, 0.08, 0), "out", lift=0.06).foot(s_, 0.36, feet_hide[s_], "out", lift=0.05).foot(s_, 1.1, feet_hide[s_])
        a.foot(o_, 0.0).foot(o_, 0.12).foot(o_, 0.30, (0.03 * sd, 0.08, 0), "out", lift=0.06).foot(o_, 0.46, feet_hide[o_], "out", lift=0.05).foot(o_, 1.1, feet_hide[o_])
        grip_n = arm_at(s_, w=body_pt(0.17, -0.20, z_chest - 0.10), along=(0.15, -0.45, 0.88), palm=(0.25, -0.95, 0.1), pole=(0.7, 0.4, -0.6),
                        curl=(85, 75, 45), sh=(0, -8, -4))
        grip_f = arm_at(o_, w=body_pt(-0.03, -0.24, z_chest - 0.06), along=(-0.35, -0.45, 0.82), palm=(-0.2, -0.95, 0.1), pole=(0.7, 0.4, -0.6),
                        curl=(85, 75, 45), sh=(0, -8, -4))
        a.rest(s_, 0.0).world(s_, 0.34, hide_t, grip_n.copy(arc=(0.04, -0.06, 0.04)), "out").world(s_, 1.1, hide_t, grip_n)
        a.rest(o_, 0.0).world(o_, 0.40, hide_t, grip_f.copy(arc=(0.0, -0.08, 0.04)), "out").world(o_, 1.1, hide_t, grip_f)
        a.on_top(lambda t: tremble(t, 0.6 * L.clamp01((t - 0.4) / 0.2), 1.2, 0.2))
        a.f(0.0).f(0.08, "snap", lids=1.4, brows=1.0, jaw=0.3, worry=0.6).f(0.4, "ease", lids=1.3, worry=0.9, brows=0.8, tight=0.4, eyes_x=-sd * 0.7)
        a.f(1.1, "ease", lids=1.25, worry=0.9, brows=0.8, tight=0.4, eyes_x=-sd * 0.7)
        clips["child_hide_behind_" + nm] = clip("child_hide_behind_" + nm, 1.1, a, kind="react", hold=True, tags=["fear", "child"], bodies=CHILD,
                                                blend_in=0.06, blend_out=0.5)
        b2 = Act(1.4, drag=0.6)
        peek_t = dict(hips=(6, -4 * sd, 8 * sd), hips_loc=(0.04 * sd, 0.12, -0.05), spine=(2, -7 * sd, -4 * sd), chest=(0, -9 * sd, -8 * sd),
                      neck=(-2, -5 * sd, -8 * sd), head=(-4, -10 * sd, -16 * sd))
        b2.t(0.0, "ease", **hide_t).t(0.42, "out", **peek_t).t(0.9, "ease", **dict(peek_t, head=(-6, -12 * sd, -20 * sd))).t(1.04, "snap", **hide_t).t(1.4, "ease", **hide_t)
        for s2 in "LR":
            b2.foot(s2, 0.0, feet_hide[s2]).foot(s2, 1.4, feet_hide[s2])
        for t, ts, kind in ((0.0, hide_t, "ease"), (0.42, peek_t, "out"), (0.9, peek_t, "ease"), (1.04, hide_t, "snap"), (1.4, hide_t, "ease")):
            b2.world(s_, t, ts, grip_n, kind).world(o_, t, ts, grip_f, kind)
        b2.f(0.0, "ease", lids=1.25, worry=0.9, brows=0.8, tight=0.4).f(0.42, "out", lids=1.4, worry=0.5, brows=1.0, jaw=0.25, eyes_x=sd * 0.6, eyes_y=0.5)
        b2.f(0.9, "ease", lids=1.4, brows=1.0, jaw=0.25, eyes_y=0.5).f(1.04, "snap", lids=1.3, worry=0.9, brows=0.8, tight=0.5).f(1.4, "ease", lids=1.25, worry=0.9, brows=0.8, tight=0.4)
        clips["child_peek_out_" + nm] = clip("child_peek_out_" + nm, 1.4, b2, kind="react", hold=True, tags=["fear", "child", "comic"], bodies=CHILD,
                                             blend_in=0.06, blend_out=0.4)

    # ---- copy the bow, badly: watching, then late, too fast, far too deep, the arms
    #      dangling; a peek up still bent double; up too fast; chin up, proud of it
    a = Act(3.0, drag=0.8)
    plunge = dict(hips=(36, 0, 0), hips_loc=(0, 0.10, -0.06), spine=(32, 0, 0), chest=(22, 0, 0), neck=(10, 0, 0), head=(18, 0, 0))
    a.t(0.0).t(0.45, "ease", chest=(2, 0, 6), neck=(2, 0, 8), head=(4, 0, 18)).t(0.62, "snap", chest=(-2, 0, 0), head=(-4, 0, 0))
    a.t(0.86, "in", **plunge).t(1.0, "settle", **dict(plunge, hips=(34, 0, 0), spine=(30, 0, 0)))
    a.t(1.35, "ease", **plunge).t(1.6, "out", **dict(plunge, neck=(-12, 0, 0), head=(-26, 0, 0))).t(1.85, "ease", **dict(plunge, neck=(-12, 0, 0), head=(-28, 0, 0)))
    a.t(2.05, "back2", hips=(-4, 0, 0), hips_loc=(0, -0.02, 0.01), spine=(-6, 0, 0), chest=(-10, 0, 0), neck=(-4, 0, 0), head=(-10, 0, 0))
    a.t(2.5, "settle", chest=(-6, 0, 0), head=(-8, 0, 3)).t(3.0, "ease", chest=(-4, 0, 0), head=(-6, 0, 2))
    for s_ in "LR":
        dangle = hang(a, s_, 70, curl=(20, 14, 6))
        flap = dangle.copy(w=dangle.w + mv(Vector((0.08 * k, -0.06 * k, 0.04 * k)), s_))
        stiff = a.rest_arm[s_].copy(w=a.rest_arm[s_].w + mv(Vector((-0.04 * k, 0.03 * k, 0.0)), s_), curl=(50, 40, 20))
        a.rest(s_, 0.0).rest(s_, 0.62).arm(s_, 0.9, dangle, "in").arm(s_, 1.05, flap, "out").arm(s_, 1.2, dangle, "ease")
        a.arm(s_, 1.85, dangle).arm(s_, 2.08, stiff, "back2").arm(s_, 3.0, stiff)
    a.f(0.0).f(0.45, "ease", brows=0.4, eyes_x=0.8, tight=0.2).f(0.62, "snap", lids=1.3, brows=0.9, jaw=0.2).f(1.0, "ease", lids=0.6, smile=0.3)
    a.f(1.6, "out", lids=1.3, brows=1.0, eyes_y=1.0, smile=0.4).f(2.05, "snap", lids=1.2, smile=0.9, brows=0.7).f(3.0, "ease", smile=0.9, brows=0.5, lids=1.0)
    clips["child_copy_bow"] = clip("child_copy_bow", 3.0, a, kind="bow", tags=["child", "comic", "deference"], bodies=CHILD, blend_in=0.1, blend_out=0.5)

    # ---- fidget: swinging the arms, twisting side to side, a scuff of a foot, a pluck at
    #      the tunic, looking about (a timed one and the same kept as a stance)
    def fidget_act(length, loop):
        a = Act(length, drag=1.0)
        a.loop = loop
        tw = [0.0, 0.8, 1.6, 2.4, 3.2, 4.0, 4.8, 5.6]
        for i, t in enumerate(tw):
            if t > length:
                break
            sgn = 1.0 if i % 2 == 0 else -1.0
            a.t(t, "ease", hips=(0, 0, 10 * sgn), spine=(0, 0, 8 * sgn), chest=(-2, 3 * sgn, 12 * sgn), neck=(0, 0, 4 * sgn), head=(-4, 5 * sgn, 12 * sgn))
        a.t(length, "ease", hips=(0, 0, 10), spine=(0, 0, 8), chest=(-2, 3, 12), neck=(0, 0, 4), head=(-4, 5, 12))
        for s_ in "LR":
            sgn0 = 1.0 if s_ == "L" else -1.0
            fwd = a.rest_arm[s_].copy(w=a.rest_arm[s_].w + mv(Vector((-0.08 * k, -0.24 * k, 0.12 * k)), s_), curl=(20, 12, 6))
            back = a.rest_arm[s_].copy(w=a.rest_arm[s_].w + mv(Vector((0.03 * k, 0.18 * k, 0.06 * k)), s_), curl=(20, 12, 6))
            for i, t in enumerate(tw):
                if t > length:
                    break
                a.arm(s_, t, fwd if (i % 2 == 0) == (s_ == "L") else back, "ease")
            a.arm(s_, length, fwd if s_ == "L" else back, "ease")
        if length >= 5.0:
            pluck = arm_at("R", w=body_pt(0.04, -0.20, z_chest - 0.04), along=(-0.4, -0.5, 0.75), palm=(-0.4, 0.8, -0.3), pole=(0.8, 0.4, -0.4), curl=(70, 60, 50))
            ks = [kk for kk in a.arm_keys["R"] if not (3.0 < kk[0] < 4.6)]
            a.arm_keys["R"] = ks
            a.arm("R", 3.3, pluck, "out").arm("R", 3.6, pluck.copy(w=pluck.w + Vector((0, -0.03 * k, 0))), "out").arm("R", 3.9, pluck, "out").arm("R", 4.2, pluck.copy(w=pluck.w + Vector((0, -0.03 * k, 0))), "out")
        a.foot("L", 0.0).foot("L", 1.6).foot("L", 2.0, (0.03, -0.06, 0.0), "out", lift=0.03, rot=(15, 0, 10)).foot("L", 2.4, (0, 0, 0), "ease").foot("L", length)
        a.f(0.0, "ease", eyes_x=0.6, brows=0.2).f(1.6, "ease", eyes_x=-0.6, brows=0.1).f(3.2, "ease", eyes_y=-0.6, tight=0.2).f(4.8, "ease", eyes_x=0.6, eyes_y=0.4).f(length, "ease", eyes_x=0.6, brows=0.2)
        return a
    clips["child_fidget"] = clip("child_fidget", 3.2, fidget_act(3.2, False), kind="ambient", tags=["child", "bored"], bodies=CHILD,
                                 blend_in=0.25, blend_out=0.5)
    clips["stance_fidget"] = stance_clip("stance_fidget", 6.4, fidget_act(6.4, True), hands="", tags=["child", "bored"], bodies=CHILD)

    # ---- wave at the god: up on the toes, both arms going, bouncing, beaming
    a = Act(1.8, drag=0.6)
    a.t(0.0).t(0.2, "out", chest=(-6, 0, 0), neck=(-4, 0, 0), head=(-14, 0, 0)).t(1.5, "ease", chest=(-6, 0, 0), neck=(-4, 0, 0), head=(-14, 0, 0)).t(1.8, "ease")
    for s_, ph in (("R", 0), ("L", 1)):
        hi = arm_at(s_, w=body_pt(0.30, -0.10, z_chest + 0.50), along=(0.15, -0.15, 0.97), palm=(-0.1, -0.98, 0.1), pole=(0.9, 0.3, -0.2), curl=(0, -6, -8), sh=(0, -16, 0))
        a.rest(s_, 0.0).arm(s_, 0.22 + 0.05 * ph, hi.copy(arc=(0.1, -0.06, 0.0)), "out")
        for i in range(7):
            sw = 1.0 if (i + ph) % 2 == 0 else -1.0
            a.arm(s_, 0.34 + 0.15 * i, hi.copy(w=hi.w + mv(Vector((0.05 * k * sw, 0, 0)), s_), along=L.Quaternion(Vector((0, 1, 0)), math.radians(-32 * sw)) @ hi.along), "ease")
        a.rest(s_, 1.8, "ease")
    hop = lambda t: pulses(t, 0.25, 0.25, 6, 0.95)
    a.on_top(lambda t: {"hips": {"loc": (0, 0, 0.03 * hop(t))}})
    for s_ in "LR":
        a.foot(s_, 0.0).foot(s_, 0.25, (0, 0, 0.04), rot=(24, 0, 0)).foot(s_, 1.5, (0, 0, 0.04), rot=(24, 0, 0)).foot(s_, 1.8)
    a.f(0.0).f(0.2, "out", smile=1.0, brows=0.9, lids=1.2, eyes_y=0.9, jaw=0.4).f(1.5, "ease", smile=1.0, brows=0.9, lids=1.2, eyes_y=0.9, jaw=0.35).f(1.8, "ease")
    clips["child_wave"] = clip("child_wave", 1.8, a, kind="react", tags=["child", "joy", "comic"], bodies=CHILD, blend_in=0.1, blend_out=0.4)

    # ---- a giggle held in: both hands clapped over the mouth (the right over the left),
    #      hunched (the head goes with the chest, so the hands stay on the mouth),
    #      shaking, a guilty look round
    a = Act(2.2, drag=0.7)
    # (only a little forward: bowed further, the camera sees the hands under the face)
    curl_t = dict(hips=(3, 0, 0), hips_loc=(0, 0.01, -0.03), spine=(5, 0, 0), chest=(6, 0, 0), neck=(0, 0, 0), head=(0, 0, 0))
    a.t(0.0).t(0.08, "snap", chest=(-3, 0, 0), head=(-4, 0, 0)).t(0.35, "out", **curl_t).t(0.9, "ease", **dict(curl_t, spine=(10, 0, 6), chest=(10, 0, 6)))
    a.t(1.4, "ease", **dict(curl_t, spine=(10, 0, -6), chest=(10, 0, -6))).t(1.8, "out", chest=(2, 0, 4), head=(0, 0, 4)).t(2.2, "ease")
    for s_ in "LR":
        cover = hand_mouth(s_, cover=True).copy(curl=(20, 12, 8), sh=(0, -10, -6))
        if s_ == "R":   # the right hand over the left one, not through it
            cover = cover.copy(w=cover.w + Vector((0.0, -0.028 * k, -0.012 * k)))
        a.rest(s_, 0.0).arm(s_, 0.18 + (0.04 if s_ == "L" else 0.0), cover.copy(arc=(0.04, -0.08, 0.0)), "snap").arm(s_, 1.75, cover).rest(s_, 2.2, "ease")
    shake = lambda t: pulses(t, 0.3, 0.11, 13, 0.94, 1.3)

    def shaking(t):
        b = shake(t)
        p = {}
        both(p, "shoulder", rot=(0, -7 * b, 0))
        add(p, "spine", rot=(2 * b, 0, 0))
        add(p, "chest", rot=(3 * b, 0, 0))
        add(p, "hips", loc=(0, 0, -0.006 * b))
        return p
    a.on_top(shaking)
    a.f(0.0).f(0.08, "snap", puff=0.8, lids=0.4, smile=0.7).f(0.35, "ease", puff=0.6, lids=0.15, smile=0.8, brows=0.4)
    a.f(1.6, "ease", puff=0.5, lids=0.2, smile=0.7).f(1.8, "out", lids=1.1, eyes_x=0.8, smile=0.5, tight=0.4).f(2.2, "ease", smile=0.3)
    clips["child_giggle"] = clip("child_giggle", 2.2, a, kind="react", tags=["child", "joy", "comic"], bodies=CHILD, blend_in=0.06, blend_out=0.45)

    # ---- shushed: caught mid-fidget and frozen like a statue: the head snaps round, the
    #      shoulders go up to the ears, one arm stuck halfway up, one foot off the floor,
    #      wobbling on the other; held; the eyes slide sideways; then the foot comes down
    #      very slowly and the arm sinks, sheepish
    a = Act(3.0, drag=0.4)
    a.lags = {"head": 0.0, "neck": 0.0}
    stiff_t = dict(hips=(0, -4, 0), hips_loc=(-0.03, 0.0, 0.014), spine=(-2, 0, 0), chest=(-5, 0, 0), neck=(-4, 0, 6), head=(-6, 0, 14))
    a.t(0.0).t(0.07, "snap", head=(-6, 0, 16)).t(0.18, "snap", **stiff_t).t(2.0, "ease", **stiff_t)
    a.t(2.3, "ease", **dict(stiff_t, head=(-2, 0, 8))).t(3.0, "ease", chest=(3, 0, 0), head=(6, 0, 0))
    stuck = arm_at("R", w=body_pt(0.14, -0.26, z_chest - 0.04), along=(-0.2, -0.75, 0.6), palm=(-0.9, 0.2, 0.2), pole=(0.8, 0.3, -0.5), curl=(10, 0, -6), sh=(0, -20, -4))
    a.rest("R", 0.0).arm("R", 0.16, stuck, "snap").arm("R", 2.1, stuck).arm("R", 2.75, a.rest_arm["R"].copy(sh=(0, 4, 0)), "in").rest("R", 3.0)
    pressed = a.rest_arm["L"].copy(w=a.rest_arm["L"].w + mv(Vector((-0.03 * k, 0.02 * k, 0.03 * k)), "L"), curl=(-6, -10, -10), sh=(0, -20, -4))
    a.rest("L", 0.0).arm("L", 0.16, pressed, "snap").arm("L", 2.1, pressed).arm("L", 2.75, a.rest_arm["L"].copy(sh=(0, 4, 0)), "in").rest("L", 3.0)
    a.foot("L", 0.0).foot("L", 0.16, (0.0, 0.10, 0.10), "snap", rot=(-30, 0, 0)).foot("L", 2.1, (0.0, 0.10, 0.10), rot=(-30, 0, 0))
    a.foot("L", 2.8, (0.0, 0.0, 0.0), "in").foot("L", 3.0)
    wob = lambda t: L.clamp01((t - 0.3) / 0.3) * (1.0 - L.clamp01((t - 2.0) / 0.3))
    a.on_top(lambda t: {"hips": {"rot": (0, 2.5 * wob(t) * math.sin(t * 7.0), 0)}, "chest": {"rot": (0, -2.0 * wob(t) * math.sin(t * 7.0 + 0.6), 0)}})
    a.f(0.0).f(0.07, "snap", lids=1.45, brows=1.0, tight=0.7).f(2.0, "ease", lids=1.4, brows=0.9, tight=0.7).f(2.3, "ease", lids=1.25, eyes_x=0.9, tight=0.6, worry=0.4)
    a.f(3.0, "ease", tight=0.3, worry=0.3, smile=0.2)
    clips["child_shushed"] = clip("child_shushed", 3.0, a, kind="react", tags=["child", "comic", "fear"], bodies=CHILD, blend_in=0.05, blend_out=0.5)

    # ---- run (in place: the stage carries them to the parent): quick small steps, arms out ahead
    def run_pose(t):
        p = cf_anim._walk(t, 0.42, 30.0, 80.0, 0.03, head_down=-4.0, swing=0.8)
        add(p, "spine", rot=(6, 0, 0))
        add(p, "chest", rot=(4, 0, 0))
        both(p, "upper_arm", rot=(-40, -6, 0))
        both(p, "forearm", rot=(-30, 0, 0))
        both(p, "fingers", rot=(0, 10, 0))
        return p
    a = Act(0.42, drag=0.0, feet=False)
    a.t(0.0)
    run = clip("child_run", 0.42, a, kind="walk", loop=True, tags=["child", "fear"], bodies=CHILD, speed_mps=1.9, blend_in=0.12, blend_out=0.25)
    run.body = lambda t: run_pose(t % 0.42)
    run.face_fn = lambda t: {"lids": 1.3, "worry": 0.9, "brows": 0.8, "jaw": 0.3}
    clips["child_run"] = run

    # ---- cling to the parent on side sd: both arms round their leg, the face pressed in,
    #      a peek back at the room. Holds.
    for sd, nm in ((1.0, "l"), (-1.0, "r")):
        s_ = "L" if sd > 0 else "R"
        o_ = "R" if sd > 0 else "L"
        cling_t = dict(hips=(4, 0, 18 * sd), hips_loc=(0.10 * sd, -0.02, -0.03), spine=(6, 4 * sd, 10 * sd), chest=(6, 6 * sd, 12 * sd), neck=(6, 0, 8 * sd), head=(10, 10 * sd, 22 * sd))
        a = Act(2.4, drag=0.7)
        a.t(0.0).t(0.25, "out", **cling_t).t(1.3, "ease", **cling_t).t(1.6, "out", **dict(cling_t, neck=(0, 0, -4 * sd), head=(-4, -6 * sd, -14 * sd)))
        a.t(2.0, "ease", **dict(cling_t, neck=(0, 0, -4 * sd), head=(-4, -6 * sd, -14 * sd))).t(2.4, "out", **cling_t)
        a.foot(s_, 0.0).foot(s_, 0.2, (0.14 * sd, -0.02, 0), "out", lift=0.04).foot(s_, 2.4, (0.14 * sd, -0.02, 0))
        hug_n = arm_at(s_, w=body_pt(0.36, 0.06, z_waist - 0.04), along=(0.5, 0.6, 0.0), palm=(0.0, 0.0, -1.0), pole=(0.3, 0.6, -0.8), curl=(60, 50, 30))
        hug_f = arm_at(o_, w=body_pt(-0.36, -0.20, z_waist + 0.02), along=(-0.6, 0.5, 0.0), palm=(0.0, 0.0, -1.0), pole=(0.2, 0.2, -1.0), curl=(60, 50, 30))
        a.rest(s_, 0.0).world(s_, 0.28, cling_t, hug_n.copy(arc=(0.04, -0.04, 0.02)), "out").world(s_, 2.4, cling_t, hug_n)
        a.rest(o_, 0.0).world(o_, 0.32, cling_t, hug_f.copy(arc=(0.0, -0.08, 0.02)), "out").world(o_, 2.4, cling_t, hug_f)
        a.on_top(lambda t: tremble(t, 0.7, 1.1, 0.3))
        a.f(0.0).f(0.25, "out", lids=0.3, worry=0.9, tight=0.6).f(1.3, "ease", lids=0.3, worry=0.9, tight=0.6)
        a.f(1.6, "out", lids=1.3, worry=0.8, brows=0.8, eyes_x=-sd).f(2.0, "ease", lids=1.3, worry=0.8, brows=0.8, eyes_x=-sd).f(2.4, "out", lids=0.3, worry=0.9, tight=0.6)
        clips["child_cling_" + nm] = clip("child_cling_" + nm, 2.4, a, kind="react", hold=True, tags=["child", "fear"], bodies=CHILD, blend_in=0.1, blend_out=0.5)

"""Court acting (K): the director's priority vocabulary (court_director.gd ACTS).

Each reads within about 0.4 s with a clear silhouette and a short
anticipation, because the director's beats come 0.3-1.0 s apart. Clips that
go one way have _l / _r versions (toward the figure's own left or right): the
acting layer picks the side from where the other person stands.
"""
import math
from mathutils import Vector

import cf_anim
from cf_anim import add, both, side, merge
import court_anims_lib as L
from court_anims_lib import ArmKey, arm_at, legs_fk, tremble, breathe, mv, landmarks
from court_anims_clips import Act, clip, torso_of, tpose, body_pt, hand_mouth, hang, UPPER


def _legs0(a):
    B = a.B
    out = {b: dict(B[b]) for b in ("thigh.L", "shin.L", "foot.L", "thigh.R", "shin.R", "foot.R") if b in B}
    out.setdefault("toe.L", {"rot": (0, 0, 0)})
    out.setdefault("toe.R", {"rot": (0, 0, 0)})
    return out


def make_more(clips):
    f = L.FRAME
    k = L.K
    z_chest = f.z_chest / k
    z_waist = f.z_waist / k
    z_hip = f.z_hip / k

    # ---- faint: the eyes go, the knees buckle, down in a heap on the floor (holds)
    for sd, nm in ((1.0, "faint_l"), (-1.0, "faint_r")):
        a = Act(2.0, drag=1.3, feet=False)
        a.t(0.0).t(0.14, "out", hips_loc=(0.010 * sd, 0, 0), spine=(0, 0, 2 * sd), head=(-7, 0, 6 * sd))
        a.t(0.42, "in", hips_loc=(0.020 * sd, 0.015, -0.20), spine=(9, 0, 3 * sd), chest=(5, 0, 3 * sd), neck=(6, 0, 0), head=(16, 4 * sd, 10 * sd))
        down = dict(hips=(-16, 8 * sd, 6 * sd), hips_loc=(0.06 * sd, 0.10, -0.72), spine=(-5, 4 * sd, 6 * sd), chest=(-5, 3 * sd, 6 * sd), neck=(-3, 0, 9 * sd), head=(-8, 13 * sd, 24 * sd))
        a.t(0.80, "in", **dict(down, hips=(-18, 8 * sd, 6 * sd), hips_loc=(0.06 * sd, 0.10, -0.74)))
        a.t(0.93, "settle", **down).t(2.0, "ease", **down)
        legs0 = _legs0(a)
        buckle = merge(legs0, {"thigh.L": {"rot": (-34, 0, 0)}, "shin.L": {"rot": (62, 0, 0)}, "foot.L": {"rot": (-22, 0, 0)},
                               "thigh.R": {"rot": (-30, 0, 0)}, "shin.R": {"rot": (58, 0, 0)}, "foot.R": {"rot": (-24, 0, 0)}})
        heap = merge(legs0, {"thigh.L": {"rot": (-62, 0, 14)}, "shin.L": {"rot": (34, 0, 0)}, "foot.L": {"rot": (-10, 0, 8)},
                             "thigh.R": {"rot": (-70, 0, -10)}, "shin.R": {"rot": (52, 0, 0)}, "foot.R": {"rot": (-14, 0, -6)}})
        a.legs([(0.0, legs0), (0.14, legs0), (0.42, buckle, "in"), (0.80, heap, "in"), (2.0, heap)])
        for s_ in "LR":
            limp = hang(a, s_, -10, curl=(40, 30, 14))
            r = a.rest_arm[s_]
            flop = r.copy(w=r.w + mv((0.10 * k, -0.10 * k, 0.02 * k), s_), curl=(46, 36, 16), sh=(0, 4, 0))
            a.rest(s_, 0.0).rest(s_, 0.14).arm(s_, 0.45, limp, "in").arm(s_, 0.86, flop, "in")
            a.arm(s_, 0.98, flop.copy(w=flop.w + Vector((0, 0, 0.02 * k))), "settle").arm(s_, 2.0, flop)
        a.f(0.0).f(0.14, "out", lids=0.45, eyes_y=1.0, brows=0.5, worry=0.3).f(0.42, "ease", lids=0.08, eyes_y=0.6, jaw=0.25, brows=0.2)
        a.f(0.9, "ease", lids=0.04, jaw=0.35).f(2.0, "ease", lids=0.04, jaw=0.32)
        clips[nm] = clip(nm, 2.0, a, kind="react", hold=True, tags=["fear", "comic"], blend_in=0.12, blend_out=0.8)

    # ---- half-catch: a lunge to the side, arms under the falling one, takes the weight, sags
    for sd, nm in ((1.0, "half_catch_l"), (-1.0, "half_catch_r")):
        s_ = "L" if sd > 0 else "R"
        o_ = "R" if sd > 0 else "L"
        a = Act(1.7, drag=0.9)
        a.t(0.0).t(0.10, "snap", chest=(-3, 0, 0), head=(-5, 6 * sd, 0))
        a.t(0.36, "out", hips=(10, 16 * sd, -4 * sd), hips_loc=(0.10 * sd, 0.02, -0.07), spine=(8, 4 * sd, -6 * sd), chest=(12, 6 * sd, -6 * sd), neck=(4, 0, 0), head=(4, 10 * sd, 0))
        low = dict(hips=(14, 18 * sd, -6 * sd), hips_loc=(0.12 * sd, 0.05, -0.16), spine=(12, 4 * sd, -8 * sd), chest=(14, 6 * sd, -8 * sd), neck=(5, 0, 0), head=(-2, 12 * sd, 0))
        a.t(0.62, "in", **low).t(0.80, "settle", **dict(low, hips_loc=(0.12 * sd, 0.05, -0.15), head=(-4, 12 * sd, 0)))
        a.t(1.25, "ease", **dict(low, hips_loc=(0.12 * sd, 0.05, -0.15), head=(-6, 10 * sd, 0)))
        a.t(1.7, "ease", hips_loc=(0.03 * sd, 0.0, -0.02), chest=(2, 2 * sd, 0), head=(0, 4 * sd, 0))
        a.foot(s_, 0.0).foot(s_, 0.32, (0.20 * sd, -0.04, 0.0), "out", lift=0.06).foot(s_, 1.7, (0.20 * sd, -0.04, 0.0))
        # the near arm reaches out to its side; the far arm crosses in front toward it
        reach_n = arm_at(s_, w=body_pt(0.56, -0.26, z_chest - 0.12), along=(0.75, -0.55, 0.0), palm=(-0.3, 0.2, 0.95),
                         pole=(0.6, 0.3, -1.0), curl=(30, 22, 10), sh=(0, -4, -6))
        reach_f = arm_at(o_, w=body_pt(-0.38, -0.42, z_chest - 0.14), along=(-0.8, -0.55, 0.0), palm=(0.2, 0.3, 0.95),
                         pole=(0.3, 0.6, -1.0), curl=(30, 22, 10), sh=(0, -4, -8))
        sag_n = reach_n.copy(w=reach_n.w + Vector((0, 0, -0.10 * k)))
        sag_f = reach_f.copy(w=reach_f.w + Vector((0, 0, -0.10 * k)))
        a.rest(s_, 0.0).arm(s_, 0.34, reach_n.copy(arc=(0.04, -0.08, 0.0)), "out").arm(s_, 0.62, sag_n, "in").arm(s_, 1.25, sag_n).rest(s_, 1.7, "ease")
        a.rest(o_, 0.0).arm(o_, 0.38, reach_f.copy(arc=(0.0, -0.10, 0.02)), "out").arm(o_, 0.62, sag_f, "in").arm(o_, 1.25, sag_f).rest(o_, 1.7, "ease")
        a.f(0.0).f(0.10, "snap", lids=1.35, brows=1.0, jaw=0.4).f(0.62, "ease", puff=0.6, worry=0.7, brows=0.8, lids=1.1, jaw=0.2)
        a.f(1.25, "ease", puff=0.4, worry=0.7, brows=0.7).f(1.7, "ease", worry=0.3)
        a.on_top(lambda t: tremble(t, 0.8 * L.clamp01((t - 0.62) / 0.1) * (1 - L.clamp01((t - 1.2) / 0.3)), 1.1, 0.2))
        clips[nm] = clip(nm, 1.7, a, kind="react", tags=["comic", "care"], blend_in=0.08, blend_out=0.5)

    # ---- knees knock: knees bent and banging together, hands clutched at the breast (loops)
    a = Act(1.2, drag=0.6)
    kk = dict(hips_loc=(0.0, 0.01, -0.055), spine=(3, 0, 0), chest=(5, 0, 0), neck=(3, 0, 0), head=(7, 0, 0))
    a.t(0.0, "ease", **kk).t(1.2, "ease", **kk)

    def knock_knees(t):
        b = abs(math.sin(2 * math.pi * 2.5 * t))
        out = {}
        for s2 in "LR":
            inward = Vector((-0.95 if s2 == "L" else 0.95, -1.0, 0.0))
            ahead = Vector((0.12 if s2 == "L" else -0.12, -1.0, 0.0))
            out[s2] = (inward * b + ahead * (1 - b)).normalized()
        return out
    a.knee_fn = knock_knees
    for s_ in "LR":
        clutch = arm_at(s_, w=body_pt(0.025, -0.20, z_chest + 0.02), along=(-0.6, -0.2, 0.75), palm=(-0.9, 0.2, 0.2),
                        pole=(0.6, 0.2, -1.0), curl=(60, 50, 30), sh=(0, -10, -6))
        a.arm(s_, 0.0, clutch).arm(s_, 1.2, clutch)
    a.on_top(lambda t: tremble(t, 1.2, 1.0, 0.5))
    a.f(0.0, "ease", worry=0.9, brows=0.8, lids=1.25, jaw=0.25, tight=0.2).f(1.2, "ease", worry=0.9, brows=0.8, lids=1.25, jaw=0.25, tight=0.2)
    clips["knees_knock"] = clip("knees_knock", 1.2, a, kind="react", loop=True, tags=["fear", "comic"], blend_in=0.15, blend_out=0.4)

    # ---- hide behind someone (a child behind an elder on that side), and peek out
    for sd, nm in ((1.0, "l"), (-1.0, "r")):
        s_ = "L" if sd > 0 else "R"
        o_ = "R" if sd > 0 else "L"
        hide_t = dict(hips=(6, 24 * sd, 0), hips_loc=(0.12 * sd, 0.10, -0.10), spine=(8, 6 * sd, 4 * sd), chest=(8, 6 * sd, 4 * sd), neck=(6, 0, 0), head=(12, -10 * sd, 8 * sd))
        feet_hide = {s_: (0.22 * sd, 0.14, 0.0), o_: (0.12 * sd, 0.12, 0.0)}
        a = Act(1.4, drag=0.8)
        a.t(0.0).t(0.12, "snap", chest=(3, 0, 0), head=(6, 0, 0)).t(0.55, "out", **hide_t).t(1.4, "ease", **hide_t)
        a.foot(s_, 0.0).foot(s_, 0.40, feet_hide[s_], "out", lift=0.07).foot(s_, 1.4, feet_hide[s_])
        a.foot(o_, 0.0).foot(o_, 0.15).foot(o_, 0.55, feet_hide[o_], "out", lift=0.06).foot(o_, 1.4, feet_hide[o_])
        grip_n = arm_at(s_, w=body_pt(0.20, -0.26, z_waist + 0.10), along=(0.3, -0.6, 0.5), palm=(0.7, -0.2, 0.0), pole=(0.6, 0.3, -1.0),
                        curl=(70, 60, 30), sh=(0, -6, -6))
        grip_f = arm_at(o_, w=body_pt(-0.10, -0.28, z_waist + 0.14), along=(-0.6, -0.5, 0.4), palm=(-0.8, -0.1, 0.0), pole=(0.6, 0.3, -1.0),
                        curl=(70, 60, 30), sh=(0, -8, -6))
        a.rest(s_, 0.0).arm(s_, 0.5, grip_n.copy(arc=(0.04, -0.06, 0.0)), "out").arm(s_, 1.4, grip_n)
        a.rest(o_, 0.0).arm(o_, 0.55, grip_f.copy(arc=(0.0, -0.08, 0.0)), "out").arm(o_, 1.4, grip_f)
        a.f(0.0).f(0.12, "snap", lids=1.35, brows=0.9, worry=0.6).f(0.55, "ease", lids=1.25, worry=0.8, brows=0.7, tight=0.4, eyes_x=-sd * 0.6)
        a.f(1.4, "ease", lids=1.2, worry=0.8, brows=0.7, tight=0.4, eyes_x=-sd * 0.6)
        clips["hide_behind_" + nm] = clip("hide_behind_" + nm, 1.4, a, kind="react", hold=True, tags=["fear", "child"], blend_in=0.1, blend_out=0.5)
        # peek out: from hiding, lean out the other way, eyes wide, then duck back in
        b2 = Act(1.1, drag=0.7)
        peek_t = dict(hips=(6, 24 * sd, -4 * sd), hips_loc=(0.12 * sd, 0.10, -0.08), spine=(4, 2 * sd, -8 * sd), chest=(2, 0, -10 * sd), neck=(0, 0, -4 * sd), head=(2, -16 * sd, -16 * sd))
        b2.t(0.0, "ease", **hide_t).t(0.28, "out", **peek_t).t(0.62, "ease", **peek_t).t(0.78, "snap", **hide_t).t(1.1, "ease", **hide_t)
        for s2 in "LR":
            b2.foot(s2, 0.0, feet_hide[s2]).foot(s2, 1.1, feet_hide[s2])
        b2.arm(s_, 0.0, grip_n).arm(s_, 1.1, grip_n).arm(o_, 0.0, grip_f).arm(o_, 1.1, grip_f)
        b2.f(0.0, "ease", lids=1.2, worry=0.8, brows=0.7, tight=0.4).f(0.28, "out", lids=1.38, worry=0.6, brows=1.0, jaw=0.15, eyes_x=sd * 0.5)
        b2.f(0.62, "ease", lids=1.38, brows=1.0, jaw=0.15).f(0.78, "snap", lids=1.2, worry=0.8, brows=0.7, tight=0.5).f(1.1, "ease", lids=1.2, worry=0.8, brows=0.7, tight=0.4)
        clips["peek_out_" + nm] = clip("peek_out_" + nm, 1.1, b2, kind="react", hold=True, tags=["fear", "child", "comic"], blend_in=0.08, blend_out=0.4)

    # ---- yawn: one arm stretched up, a hand over the mouth, the jaw wide, a smack
    a = Act(2.2, drag=1.2)
    a.t(0.0).t(0.28, "out", spine=(-1, 0, 0), chest=(-3, 0, 0), head=(-4, 0, 0))
    a.t(0.75, "ease", spine=(-3, 0, -2), chest=(-8, 0, -3), neck=(-4, 0, 0), head=(-15, 0, -6))
    a.t(1.35, "ease", spine=(-3, 0, -2), chest=(-8, 0, -3), neck=(-4, 0, 0), head=(-16, 0, -7))
    a.t(1.75, "out", chest=(1, 0, 0), head=(3, 0, 2)).t(2.2, "ease")
    up_l = arm_at("L", w=body_pt(0.22, -0.02, z_chest + 0.48), along=(-0.2, 0.0, 1.0), palm=(-1.0, 0.0, 0.0), pole=(0.8, 0.2, 0.0),
                  curl=(75, 70, 40), sh=(0, -14, 0))
    a.rest("L", 0.0).rest("L", 0.2).arm("L", 0.80, up_l.copy(arc=(0.08, -0.05, 0.0)), "out").arm("L", 1.4, up_l).rest("L", 2.1, "ease")
    cov = hand_mouth("R", cover=True)
    a.rest("R", 0.0).rest("R", 0.35).arm("R", 0.85, cov.copy(w=cov.w + Vector((0, -0.04 * k, -0.02 * k))), "out").arm("R", 1.45, cov).rest("R", 2.1, "ease")
    a.f(0.0).f(0.28, "out", jaw=0.25, lids=0.7).f(0.75, "ease", jaw=1.0, lids=0.12, brows=0.4).f(1.4, "ease", jaw=1.05, lids=0.1, brows=0.5)
    a.f(1.6, "snap", jaw=0.0, lids=0.6, puff=0.3).f(1.85, "ease", jaw=0.08, lids=0.75).f(2.2, "ease", lids=0.85)
    clips["yawn"] = clip("yawn", 2.2, a, kind="fidget", tags=["tired", "comic"], blend_in=0.2, blend_out=0.5)

    # ---- doze on their feet: the head sinks, sinks, catches, sinks again (loops)
    a = Act(3.6, drag=1.6)
    d0 = dict(hips_loc=(0, 0.01, -0.012), spine=(3, 0, 0), chest=(4, 0, 0), neck=(6, 0, 0), head=(14, 0, 3))
    d1 = dict(hips_loc=(0, 0.015, -0.020), spine=(5, 0, 1), chest=(7, 0, 1), neck=(12, 0, 0), head=(28, 0, 6))
    a.t(0.0, "ease", **d0).t(2.5, "in", **d1).t(2.78, "out", **d0).t(3.6, "ease", **d0)
    for s_ in "LR":
        h8 = hang(a, s_, 8, curl=(38, 28, 12))
        a.arm(s_, 0.0, h8).arm(s_, 2.5, hang(a, s_, 14, curl=(42, 32, 14)), "in").arm(s_, 2.8, h8, "out").arm(s_, 3.6, h8)
    a.f(0.0, "ease", lids=0.05, jaw=0.18).f(2.5, "ease", lids=0.03, jaw=0.32).f(2.7, "out", lids=0.25, jaw=0.1, brows=0.3)
    a.f(3.0, "ease", lids=0.05, jaw=0.18).f(3.6, "ease", lids=0.05, jaw=0.18)
    clips["doze"] = clip("doze", 3.6, a, kind="idle", loop=True, tags=["tired", "comic"], blend_in=0.8, blend_out=0.3, groups=dict(UPPER, legs=0.5))

    # ---- jerk awake (from a doze): snap upright, a look left, a look right, pretend nothing happened
    a = Act(1.3, drag=0.5)
    a.lags = {"head": 0.0, "neck": 0.0}
    a.t(0.0, "ease", **d0).t(0.08, "snap", hips_loc=(0, -0.005, 0.012), spine=(-3, 0, 0), chest=(-6, 0, 0), neck=(-3, 0, 0), head=(-10, 0, 0))
    a.t(0.36, "out", spine=(-2, 0, 0), chest=(-4, 0, 0), head=(-4, 22, 0)).t(0.62, "out", chest=(-3, 0, 0), head=(-3, -20, 0))
    a.t(0.95, "ease", chest=(-2, 0, 0), head=(-2, 0, 0)).t(1.3, "ease")
    for s_ in "LR":
        r = a.rest_arm[s_]
        out_ = r.copy(w=r.w + mv((0.08 * k, -0.06 * k, 0.06 * k), s_), curl=(6, 0, -4), sh=(0, -10, 0))
        a.arm(s_, 0.0, hang(a, s_, 8, curl=(38, 28, 12))).arm(s_, 0.10, out_, "snap").arm(s_, 0.45, out_.copy(sh=(0, -4, 0)), "ease").rest(s_, 1.1, "ease")
    a.f(0.0, "ease", lids=0.05, jaw=0.2).f(0.07, "snap", lids=1.4, brows=1.0, jaw=0.35).f(0.6, "ease", lids=1.3, brows=0.8, jaw=0.1, eyes_x=-0.6)
    a.f(0.95, "ease", lids=1.0, tight=0.6, brows=0.2).f(1.3, "ease", tight=0.3)
    clips["jerk_awake"] = clip("jerk_awake", 1.3, a, kind="react", tags=["comic", "tired"], blend_in=0.05, blend_out=0.4)

    # ---- snap alert: to attention, chest out, chin up, arms stiff at the sides (holds)
    a = Act(1.0, drag=0.4)
    st = dict(hips=(0, -6, 5), hips_loc=(0.025, 0.0, 0.010), spine=(-3, 3, -2), chest=(-7, 3, -2), neck=(-2, 0, 0), head=(-7, -4, 5))
    a.t(0.0).t(0.09, "snap", **st).t(1.0, "ease", **dict(st, head=(-6, -4, 5)))
    for s_ in "LR":
        r = a.rest_arm[s_]
        stiff = r.copy(w=r.w + mv((-0.05 * k, 0.03 * k, -0.02 * k), s_), curl=(55, 45, 20), sh=(0, 2, 6))
        a.rest(s_, 0.0).arm(s_, 0.10, stiff, "snap").arm(s_, 1.0, stiff)
    a.on_top(lambda t: tremble(t, 0.5 * L.clamp01((t - 0.1) / 0.1), 1.4, 0.7))
    a.f(0.0).f(0.08, "snap", lids=1.38, brows=0.9, tight=0.6).f(1.0, "ease", lids=1.3, brows=0.7, tight=0.6)
    clips["snap_alert"] = clip("snap_alert", 1.0, a, kind="react", hold=True, tags=["fear", "comic"], blend_in=0.04, blend_out=0.5)

    # ---- elbow the neighbour: a sharp jab out to one side
    for sd, nm in ((1.0, "elbow_l"), (-1.0, "elbow_r")):
        s_ = "L" if sd > 0 else "R"
        a = Act(0.95, drag=0.6)
        a.t(0.0).t(0.08, "out", chest=(0, 0, -3 * sd)).t(0.20, "snap", spine=(0, 2 * sd, 3 * sd), chest=(1, 4 * sd, 8 * sd), head=(2, 0, 12 * sd))
        a.t(0.34, "out", spine=(0, 1 * sd, 2 * sd), chest=(1, 2 * sd, 5 * sd), head=(2, 0, 12 * sd)).t(0.95, "ease", head=(0, 0, 3 * sd))
        cock = arm_at(s_, w=body_pt(0.12, -0.12, z_chest - 0.02), along=(-0.5, -0.4, 0.75), palm=(-0.8, 0.3, 0.0), pole=(1.0, 0.4, -0.3), curl=(80, 70, 40))
        jab = arm_at(s_, w=body_pt(0.10, -0.06, z_chest + 0.0), along=(-0.6, -0.2, 0.75), palm=(-0.8, 0.4, 0.0), pole=(1.0, 0.25, 0.0), curl=(85, 75, 45), sh=(0, -4, 6))
        a.rest(s_, 0.0).arm(s_, 0.09, cock, "out").arm(s_, 0.20, jab, "snap").arm(s_, 0.34, cock, "out").rest(s_, 0.95, "ease")
        a.f(0.0).f(0.18, "snap", lids=0.7, tight=0.7, stern=0.4, eyes_x=sd).f(0.6, "ease", lids=0.8, tight=0.5, stern=0.3, eyes_x=sd * 0.6).f(0.95, "ease")
        clips[nm] = clip(nm, 0.95, a, kind="react", tags=["comic", "conspiracy"], hands=s_, blend_in=0.06, blend_out=0.35,
                         groups={"legs": 0.0, "torso": 0.7, "head": 0.8, "arm_L": 1.0 if sd > 0 else 0.0, "arm_R": 1.0 if sd < 0 else 0.0})

    # ---- the heavy bundle: carried low, heaved forward, set down with a grunt, lifted again
    carry_t = dict(hips=(-6, 0, 0), hips_loc=(0, 0.03, -0.06), spine=(-5, 0, 0), chest=(-4, 0, 0), neck=(2, 0, 0), head=(6, 0, 0))

    def bundle_arms(z, y, spread=0.19):
        return {s_: arm_at(s_, w=body_pt(spread, y, z), along=(-0.35, -0.55, -0.6), palm=(-0.95, 0.0, 0.2), pole=(0.8, 0.5, -0.4),
                           curl=(55, 45, 20), sh=(0, 4, -4)) for s_ in "LR"}

    def floor_grab(torso, s_):
        return ArmKey(L.chest_space(torso, mv(body_pt(0.19, -0.46, 0.26), s_)), mv((0.7, 0.4, -0.4), s_),
                      L.chest_dir(torso, mv((-0.3, -0.4, -0.85), s_)), L.chest_dir(torso, mv((-0.95, 0.0, 0.2), s_)), (50, 40, 20), (0, 4, -4))
    carry = bundle_arms(z_hip + 0.10, -0.26)
    high = bundle_arms(z_waist + 0.08, -0.36)
    low = bundle_arms(z_hip + 0.04, -0.26)
    a = Act(1.6, drag=1.0)
    a.t(0.0, "ease", **carry_t).t(0.8, "ease", **dict(carry_t, hips=(-6, 3, 2), spine=(-5, -2, -2))).t(1.6, "ease", **carry_t)
    for s_ in "LR":
        a.arm(s_, 0.0, carry[s_]).arm(s_, 1.6, carry[s_])
    a.on_top(lambda t: tremble(t, 0.8, 0.8, 0.3))
    a.f(0.0, "ease", puff=0.5, worry=0.5, lids=0.8).f(1.6, "ease", puff=0.5, worry=0.5, lids=0.8)
    clips["carry_bundle"] = clip("carry_bundle", 1.6, a, kind="idle", loop=True, tags=["gift", "strain"], blend_in=0.3, blend_out=0.4)

    heave_t = dict(hips=(-10, 0, 0), hips_loc=(0, 0.05, -0.04), spine=(-8, 0, 0), chest=(-6, 0, 0), neck=(2, 0, 0), head=(4, 0, 0))
    a = Act(1.3, drag=1.0)
    a.t(0.0, "ease", **carry_t).t(0.16, "out", **dict(carry_t, hips_loc=(0, 0.03, -0.10))).t(0.46, "back", **heave_t)
    a.t(0.8, "ease", **dict(heave_t, hips=(-10, 4, 3))).t(1.3, "ease", **carry_t)
    for s_ in "LR":
        a.arm(s_, 0.0, carry[s_]).arm(s_, 0.16, low[s_], "out").arm(s_, 0.48, high[s_].copy(arc=(0.0, -0.06, 0.02)), "back")
        a.arm(s_, 0.85, high[s_]).arm(s_, 1.3, carry[s_], "ease")
    a.foot("L", 0.0).foot("L", 0.5, (0.0, -0.16, 0.0), "out", lift=0.05).foot("L", 1.3, (0.0, -0.16, 0.0))
    a.on_top(lambda t: tremble(t, 1.0 * L.clamp01((t - 0.4) / 0.1), 0.9, 0.1))
    a.f(0.0, "ease", puff=0.5, worry=0.5).f(0.16, "out", puff=0.9, lids=0.4, worry=0.7).f(0.5, "ease", puff=0.8, lids=0.6, worry=0.8, brows=0.6)
    a.f(1.3, "ease", puff=0.5, worry=0.5)
    clips["struggle_bundle"] = clip("struggle_bundle", 1.3, a, kind="react", tags=["gift", "comic", "strain"], blend_in=0.12, blend_out=0.4)

    squat_t = dict(hips=(28, 0, 0), hips_loc=(0, 0.10, -0.22), spine=(20, 0, 0), chest=(12, 0, 0), neck=(-6, 0, 0), head=(-8, 0, 0))
    a = Act(1.4, drag=1.0)
    sq = torso_of(a.B, tpose(**squat_t))
    a.t(0.0, "ease", **carry_t).t(0.42, "in", **squat_t).t(0.62, "ease", **squat_t)
    a.t(0.95, "out", hips=(-4, 0, 0), hips_loc=(0, 0.01, 0.0), spine=(-6, 0, 0), chest=(-4, 0, 0), head=(-3, 0, 0)).t(1.4, "ease")
    back = arm_at("R", w=body_pt(0.10, 0.16, z_waist - 0.02), along=(0.6, 0.2, -0.7), palm=(0.0, 1.0, 0.0), pole=(1.0, 0.3, -0.2), curl=(20, 14, 8))
    for s_ in "LR":
        put = floor_grab(sq, s_)
        a.arm(s_, 0.0, carry[s_]).arm(s_, 0.42, put, "in").arm(s_, 0.62, put.copy(curl=(10, 4, 0)))
    a.arm("R", 1.0, back.copy(arc=(0.06, 0.04, 0.0)), "out").arm("R", 1.4, back)
    a.rest("L", 1.2, "ease")
    a.f(0.0, "ease", puff=0.5, worry=0.5).f(0.42, "ease", puff=0.9, lids=0.5, worry=0.7).f(0.62, "snap", puff=0.0, jaw=0.35, lids=0.4)
    a.f(0.95, "ease", jaw=0.0, lids=0.7, worry=0.5, tight=0.4).f(1.4, "ease", worry=0.2, tight=0.2)
    clips["set_down_bundle"] = clip("set_down_bundle", 1.4, a, kind="react", tags=["gift", "comic", "strain"], blend_in=0.12, blend_out=0.5)

    a = Act(1.4, drag=1.0)
    sq = torso_of(a.B, tpose(**squat_t))
    a.t(0.0).t(0.35, "out", **squat_t).t(0.55, "ease", **squat_t).t(0.95, "back", **heave_t).t(1.4, "ease", **carry_t)
    for s_ in "LR":
        grab = floor_grab(sq, s_)
        a.rest(s_, 0.0).arm(s_, 0.38, grab, "out").arm(s_, 0.55, grab).arm(s_, 0.98, high[s_], "back").arm(s_, 1.4, carry[s_], "ease")
    a.on_top(lambda t: tremble(t, 1.0 * L.clamp01((t - 0.6) / 0.1), 0.9, 0.6))
    a.f(0.0).f(0.35, "ease", worry=0.5).f(0.6, "out", puff=1.0, lids=0.35, worry=0.8, brows=0.6).f(1.4, "ease", puff=0.5, worry=0.5, lids=0.8)
    clips["lift_bundle"] = clip("lift_bundle", 1.4, a, kind="react", hold=True, tags=["gift", "strain"], blend_in=0.15, blend_out=0.4)

    # ---- drop the bowl: the hands fly apart, a look down at it, a wince, a guilty look up
    a = Act(1.4, drag=0.6, base_pose=cf_anim.stance_pose("bowl"))
    a.t(0.0).t(0.07, "snap", chest=(-4, 0, 0), head=(-6, 0, 0), hips_loc=(0, 0, 0.008))
    a.t(0.38, "out", spine=(4, 0, 0), chest=(4, 0, 0), neck=(8, 0, 0), head=(22, 0, 0))
    a.t(0.85, "ease", spine=(4, 0, 0), chest=(4, 0, 0), neck=(6, 0, 0), head=(14, 0, 0))
    a.t(1.4, "ease", spine=(3, 0, 0), chest=(3, 0, 0), neck=(4, 0, 0), head=(6, 0, 0))
    for s_ in "LR":
        fly = arm_at(s_, w=body_pt(0.30, -0.22, z_chest + 0.04), along=(0.4, -0.5, 0.7), palm=(0.2, -0.95, 0.0), pole=(0.8, 0.3, -0.6),
                     curl=(4, -6, -10), sh=(0, -10, 0))
        froze = fly.copy(w=fly.w + Vector((0, 0, -0.08 * k)), curl=(14, 6, 0), sh=(0, -6, 0))
        a.arm(s_, 0.0, a.rest_arm[s_]).arm(s_, 0.08, fly, "snap").arm(s_, 0.5, froze, "ease")
        a.arm(s_, 1.4, froze.copy(w=froze.w + Vector((0, 0.03 * k, -0.06 * k))), "ease")
    a.f(0.0).f(0.07, "snap", lids=1.4, brows=1.0, jaw=0.35).f(0.4, "ease", lids=1.3, jaw=0.3, worry=0.5, eyes_y=-0.8)
    a.f(0.85, "ease", tight=0.7, worry=0.8, lids=0.75, eyes_y=-0.5).f(1.4, "ease", tight=0.6, worry=0.8, lids=1.0, eyes_y=0.9, brows=0.5)
    clips["drop_bowl"] = clip("drop_bowl", 1.4, a, kind="react", tags=["comic", "fear"], blend_in=0.05, blend_out=0.6)

    # ---- forced down, bound: hands behind the back, shoved onto both knees, the chin comes up (holds)
    a = Act(2.4, drag=0.8, feet=False)
    a.t(0.0).t(0.16, "snap", hips=(8, 0, 0), hips_loc=(0, 0.02, -0.02), spine=(12, 0, 0), chest=(10, 0, 0), head=(8, 0, 0))
    a.t(0.46, "in", hips=(4, 0, 0), hips_loc=(0, 0.07, -0.42), spine=(14, 0, 0), chest=(10, 0, 0), neck=(6, 0, 0), head=(12, 0, 0))
    a.t(0.56, "settle", hips=(3, 0, 0), hips_loc=(0, 0.07, -0.41), spine=(10, 0, 0), chest=(8, 0, 0), neck=(6, 0, 0), head=(12, 0, 0))
    up_t = dict(hips=(2, 0, 0), hips_loc=(0, 0.07, -0.41), spine=(-2, 0, 0), chest=(-5, 0, 0), neck=(-4, 0, 0), head=(-12, 0, 3))
    a.t(1.0, "out", **up_t).t(2.4, "ease", **up_t)
    legs0 = _legs0(a)
    stumble = merge(legs0, {"thigh.L": {"rot": (-20, 0, 0)}, "shin.L": {"rot": (30, 0, 0)}})
    both_knees = merge(legs0, {"thigh.L": {"rot": (8, 0, -4)}, "shin.L": {"rot": (92, 0, 0)}, "foot.L": {"rot": (-52, 0, 0)}, "toe.L": {"rot": (-50, 0, 0)},
                               "thigh.R": {"rot": (8, 0, 4)}, "shin.R": {"rot": (92, 0, 0)}, "foot.R": {"rot": (-52, 0, 0)}, "toe.R": {"rot": (-50, 0, 0)}})
    a.legs([(0.0, legs0), (0.16, stumble, "snap"), (0.46, both_knees, "in"), (2.4, both_knees)])
    for s_ in "LR":
        bound = arm_at(s_, w=body_pt(-0.02, 0.15, z_hip + 0.03), along=(-0.6, 0.3, -0.7), palm=(0.0, 1.0, 0.1), pole=(0.9, 0.6, 0.0),
                       curl=(50, 40, 20), sh=(0, 2, 10))
        a.rest(s_, 0.0).arm(s_, 0.15, bound, "snap").arm(s_, 2.4, bound)
    a.on_top(lambda t: breathe(t, 1.6, 1.6 * L.clamp01((t - 0.6) / 0.4), 0.0))
    a.f(0.0).f(0.12, "snap", lids=1.3, brows=0.6, jaw=0.3).f(0.5, "ease", lids=0.6, tight=0.8, worry=0.3)
    a.f(1.0, "ease", stern=0.9, tight=0.8, lids=0.8, brows=-0.6).f(2.4, "ease", stern=0.9, tight=0.8, lids=0.8, brows=-0.6)
    clips["kneel_bound"] = clip("kneel_bound", 2.4, a, kind="react", hold=True, tags=["defiance", "dread"], blend_in=0.06, blend_out=0.7)

    # ---- bolt: a startled look to the door, a crouch and a twist, the first stride (the stage moves them)
    for sd, nm in ((1.0, "bolt_l"), (-1.0, "bolt_r")):
        s_ = "L" if sd > 0 else "R"
        o_ = "R" if sd > 0 else "L"
        a = Act(0.85, drag=0.5, feet=False)
        a.lags = {"head": 0.0, "neck": 0.0}
        a.t(0.0).t(0.08, "snap", head=(-4, 0, 34 * sd), neck=(0, 0, 10 * sd))
        a.t(0.30, "out", hips=(6, 0, 22 * sd), hips_loc=(0.02 * sd, 0.0, -0.07), spine=(10, 0, 8 * sd), chest=(12, 0, 6 * sd), neck=(0, 0, 8 * sd), head=(-6, 0, 14 * sd))
        a.t(0.85, "in", hips=(14, 0, 34 * sd), hips_loc=(0.04 * sd, -0.02, -0.04), spine=(14, 0, 6 * sd), chest=(12, 0, 4 * sd), neck=(-2, 0, 4 * sd), head=(-8, 0, 8 * sd))
        legs0 = _legs0(a)
        crouch = merge(legs0, {"thigh." + s_: {"rot": (-30, 0, 0)}, "shin." + s_: {"rot": (40, 0, 0)}, "thigh." + o_: {"rot": (-14, 0, 0)}, "shin." + o_: {"rot": (34, 0, 0)}})
        stride = merge(legs0, {"thigh." + s_: {"rot": (-55, 0, 0)}, "shin." + s_: {"rot": (60, 0, 0)}, "foot." + s_: {"rot": (-10, 0, 0)},
                               "thigh." + o_: {"rot": (24, 0, 0)}, "shin." + o_: {"rot": (40, 0, 0)}, "foot." + o_: {"rot": (30, 0, 0)}})
        a.legs([(0.0, legs0), (0.1, legs0), (0.30, crouch, "out"), (0.85, stride, "in")])
        pump_f = arm_at(o_, w=body_pt(0.10, -0.26, z_chest + 0.02), along=(-0.2, -0.5, 0.8), palm=(-0.95, 0.0, 0.2), pole=(0.6, 0.6, -0.6), curl=(70, 60, 30))
        pump_b = arm_at(s_, w=body_pt(0.20, 0.20, z_waist - 0.04), along=(0.1, 0.6, -0.75), palm=(-0.95, 0.0, 0.0), pole=(0.6, 1.0, 0.2), curl=(70, 60, 30))
        a.rest(o_, 0.0).rest(o_, 0.1, sh=(0, -8, 0)).arm(o_, 0.85, pump_f, "out")
        a.rest(s_, 0.0).rest(s_, 0.1, sh=(0, -8, 0)).arm(s_, 0.85, pump_b, "out")
        a.f(0.0).f(0.07, "snap", lids=1.38, brows=0.9, eyes_x=sd).f(0.85, "ease", lids=1.2, tight=0.6, worry=0.6, eyes_x=sd * 0.5)
        clips[nm] = clip(nm, 0.85, a, kind="react", tags=["fear", "flight"], blend_in=0.05, blend_out=0.25, hold=True)

    # ---- run (in place: the stage carries them): leaning in, arms pumping (loops)
    def run_pose(t):
        p = cf_anim._walk(t, 0.62, 36.0, 92.0, 0.035, head_down=-6.0, swing=2.0)
        add(p, "spine", rot=(8, 0, 0))
        add(p, "chest", rot=(6, 0, 0))
        both(p, "forearm", rot=(-75, 0, 0))
        both(p, "upper_arm", rot=(0, -6, 0))
        both(p, "fingers", rot=(0, 40, 0))
        return p
    a = Act(0.62, drag=0.0, feet=False)
    a.t(0.0)
    run = clip("run", 0.62, a, kind="idle", loop=True, tags=["flight"], blend_in=0.15, blend_out=0.25)
    run.body = lambda t: run_pose(t % 0.62)
    run.face_fn = lambda t: {"lids": 1.15, "tight": 0.5, "worry": 0.5, "jaw": 0.25}
    clips["run"] = run

    # ---- wobble: nearly over, arms flung out for balance, one foot up, caught
    a = Act(1.1, drag=0.6)
    a.t(0.0).t(0.18, "out", hips=(0, 0, -6), hips_loc=(-0.03, 0.0, 0.0), spine=(0, 0, -6), chest=(-2, 0, -8), head=(-4, 0, 6))
    a.t(0.42, "out", hips=(0, 0, 5), hips_loc=(0.03, 0.0, 0.0), spine=(0, 0, 6), chest=(-1, 0, 7), head=(-3, 0, -5))
    a.t(0.70, "out", hips=(0, 0, -3), hips_loc=(-0.015, 0.0, 0.0), spine=(0, 0, -3), chest=(0, 0, -3), head=(-2, 0, 3))
    a.t(1.1, "settle")
    a.foot("L", 0.0).foot("L", 0.30, (0.04, 0.0, 0.10), "out").foot("L", 0.62, (0.0, 0.0, 0.0), "in")
    for s_ in "LR":
        flung = arm_at(s_, w=body_pt(0.62, -0.06, z_chest + 0.08), along=(1.0, 0.0, 0.1), palm=(0.0, 0.0, -1.0), pole=(0.0, 0.6, 0.6),
                       curl=(6, -6, -8), sh=(0, -6, 0))
        a.rest(s_, 0.0).arm(s_, 0.16, flung, "snap").arm(s_, 0.45, flung.copy(w=flung.w + Vector((0, 0, 0.10 * k * (1 if s_ == "L" else -1)))), "out")
        a.arm(s_, 0.72, flung.copy(w=flung.w + Vector((0, 0, -0.06 * k))), "out").rest(s_, 1.1, "ease")
    a.f(0.0).f(0.16, "snap", lids=1.38, brows=1.0, jaw=0.35, worry=0.5).f(0.7, "ease", lids=1.2, brows=0.8, worry=0.6, jaw=0.15).f(1.1, "ease", tight=0.4)
    clips["wobble"] = clip("wobble", 1.1, a, kind="react", tags=["comic"], blend_in=0.08, blend_out=0.4)

    # ---- a step back: startled, the weight back, the hands up a little
    a = Act(0.9, drag=0.6)
    a.t(0.0).t(0.22, "out", hips_loc=(0.0, 0.07, -0.02), spine=(-3, 0, 0), chest=(-6, 0, 0), neck=(-2, 0, 0), head=(-6, 0, 0))
    a.t(0.9, "ease", hips_loc=(0.0, 0.06, -0.015), spine=(-2, 0, 0), chest=(-4, 0, 0), head=(-4, 0, 0))
    a.foot("R", 0.0).foot("R", 0.24, (0.0, 0.20, 0.0), "out", lift=0.05).foot("R", 0.9, (0.0, 0.20, 0.0))
    for s_ in "LR":
        up_ = arm_at(s_, w=body_pt(0.16, -0.26, z_waist + 0.10), along=(0.0, -0.4, 0.9), palm=(-0.2, -0.95, 0.0), pole=(0.7, 0.4, -0.6),
                     curl=(10, 2, -4), sh=(0, -6, 0))
        a.rest(s_, 0.0).arm(s_, 0.2, up_, "out").arm(s_, 0.9, up_)
    a.f(0.0).f(0.15, "snap", lids=1.35, brows=0.9, jaw=0.25).f(0.9, "ease", lids=1.2, worry=0.6, brows=0.6)
    clips["step_back"] = clip("step_back", 0.9, a, kind="react", tags=["fear"], blend_in=0.06, blend_out=0.5)

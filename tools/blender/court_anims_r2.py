"""Court acting (K), round 2: the big laugh and the polite one, a side-eye the
head sells, a half-catch that catches, a faint that lands on the floor,
stances kept for life, the room's idle business and the ways out of the hall.

Stances (kind "stance", loops) are played by court_acting.gd as a base
under everything else: stance_cord, stance_bundle, stance_guard (leaning on
the staff J's figure holds: the hand stays exactly where J's staff stance
holds it, so the prop stays planted), stance_log_low / stance_log_high (an
elder on a seat 0.30 m / 0.46 m high for a 1.72 m body; the acting blends
the two to the seat a set mark gives) and stance_fire (crouched, warming
their hands).

Exits are in place (the stage carries the body): back_out (bowing as they
back away), bump_post, storm_walk, storm_stop, snatch_up, walk_sober,
walk_led. court_acting.gd exit_plan() says how a stage strings them.
"""
import math
from mathutils import Vector

import cf_anim
from cf_anim import add, both, side, merge, wave
import court_anims_lib as L
from court_anims_lib import ArmKey, arm_at, arm_fk, arm_solve, legs_fk, plant, tremble, breathe, drift, pulses, mv, landmarks, Seq, value_seq
from court_anims_clips import (Act, clip, torso_of, tpose, body_pt, hand_mouth, hand_heart, hand_belly, hand_thigh, hand_face,
                               hand_crown, hand_out, stance_arm, hang, UPPER, FULL)

TORSO = ("hips", "spine", "chest", "neck", "head")


def face_plus(c, fn):
    """Adds a function of time to a clip's face channels (beats on the jaw...)."""
    base_face = c.face_fn

    def face_fn(t):
        out = dict(base_face(t))
        for ch, v in fn(t).items():
            out[ch] = out.get(ch, L.DEFAULT_FACE.get(ch, 0.0)) + v
        return out
    c.face_fn = face_fn
    return c


def staff_hand_world():
    """Where J's staff stance holds the staff, in the hall."""
    sp = cf_anim.stance_pose("staff")
    return L.key_to_world(sp, arm_fk(sp, "R"))


def make_r2(clips):
    f = L.FRAME
    k = L.K
    z_chest = f.z_chest / k
    z_waist = f.z_waist / k
    z_hip = f.z_hip / k
    lm = landmarks()

    # =================================================================================
    # The laugh: a snort held in, then it bursts out, the head thrown back, the
    # shoulders going, a hand to the belly, doubled over, a slap of the thigh,
    # a second wave, wiping an eye.
    # =================================================================================
    a = Act(3.2, drag=1.0)
    a.t(0.0).t(0.10, "out", chest=(3, 0, 0), head=(5, 0, 0), hips_loc=(0, 0, -0.004))
    a.t(0.34, "back", hips_loc=(0, 0.018, 0.004), spine=(-6, 0, 2), chest=(-12, 0, 3), neck=(-10, 0, 0), head=(-26, 4, 7))
    a.t(0.95, "ease", hips_loc=(0, 0.014, 0.0), spine=(-4, 0, 2), chest=(-9, 0, 2), neck=(-7, 0, 0), head=(-20, 3, 5))
    a.t(1.40, "in", hips=(6, 0, 0), hips_loc=(0, 0.032, -0.016), spine=(9, 0, 0), chest=(13, 0, -2), neck=(6, 0, 0), head=(6, -3, -4))
    a.t(1.58, "settle", hips=(5, 0, 0), hips_loc=(0, 0.028, -0.014), spine=(8, 0, 0), chest=(12, 0, -2), neck=(5, 0, 0), head=(4, -3, -4))
    a.t(2.10, "out", spine=(-2, 0, 1), chest=(-6, 0, 1), neck=(-3, 0, 0), head=(-10, 0, 3))
    a.t(2.60, "ease", chest=(-1, 0, 0), head=(-2, 0, 1)).t(3.2, "ease")
    a.rest("L", 0.0).rest("L", 0.10, sh=(0, -6, 0)).arm("L", 0.42, hand_belly("L"), "out").arm("L", 2.3, hand_belly("L")).rest("L", 3.1, "ease")
    oh = hand_heart("R").copy(curl=(45, 35, 18), sh=(0, -8, -3))
    slap = hand_thigh("R")
    tear = hand_face("R").copy(w=hand_face("R").w + Vector((0.04 * k, -0.02 * k, -0.02 * k)), curl=(60, 10, 40))
    a.rest("R", 0.0).rest("R", 0.12, sh=(0, -6, 0)).arm("R", 0.38, oh, "out").arm("R", 1.25, oh.copy(w=oh.w + Vector((0, -0.02, 0.02))))
    a.arm("R", 1.44, oh.copy(w=oh.w + Vector((0, 0.0, 0.10 * k))), "out")
    a.arm("R", 1.56, slap.copy(arc=(0.04, -0.10, 0.10)), "in").arm("R", 1.68, slap.copy(w=slap.w + Vector((0, -0.02, 0.05 * k))), "out")
    a.arm("R", 1.95, slap).arm("R", 2.38, tear.copy(arc=(0.04, -0.08, 0.0)), "out").arm("R", 2.7, tear).rest("R", 3.2, "ease")
    ha = lambda t: pulses(t, 0.34, 0.16, 7, 0.88) + 0.9 * pulses(t, 1.45, 0.14, 5, 0.8) + 0.5 * pulses(t, 2.15, 0.17, 3, 0.7)

    def shake(t):
        b = ha(t)
        p = {}
        add(p, "chest", rot=(4.5 * b, 0, 0))
        add(p, "spine", rot=(2.0 * b, 0, 0))
        add(p, "head", rot=(4.0 * b, 0, 0))
        add(p, "hips", loc=(0, 0, -0.006 * b))
        both(p, "shoulder", rot=(0, -9.0 * b, 0))
        return p
    a.on_top(shake)
    a.f(0.0).f(0.10, "snap", puff=0.5, lids=0.6, smile=0.5, tight=0.4)
    a.f(0.34, "back", jaw=0.85, smile=1.0, lids=0.2, brows=0.5).f(1.4, "ease", jaw=0.7, smile=1.0, lids=0.15, brows=0.3)
    a.f(2.1, "ease", jaw=0.55, smile=1.0, lids=0.35, brows=0.5).f(2.6, "ease", jaw=0.15, smile=0.8, lids=0.6).f(3.2, "ease", smile=0.35, lids=0.9)
    c = clip("laugh", 3.2, a, kind="react", tags=["joy"], blend_in=0.12, blend_out=0.6)
    clips["laugh"] = face_plus(c, lambda t: {"jaw": 0.25 * ha(t), "lids": -0.1 * ha(t)})

    # The polite laugh: a little breath of it, the head back and to one side, a
    # hand to the breast, three small bounces and a nod.
    a = Act(1.8, drag=1.0)
    a.t(0.0).t(0.12, "out", chest=(-2, 0, 0), head=(-3, 0, 2)).t(0.40, "back", chest=(-4, 0, 2), neck=(-2, 0, 0), head=(-8, 2, 7))
    a.t(1.0, "ease", chest=(-2, 0, 1), head=(-4, 1, 4)).t(1.45, "out", head=(3, 0, 1)).t(1.8, "ease")
    hh = hand_heart("R").copy(w=hand_heart("R").w + Vector((0.0, -0.03 * k, 0.0)), curl=(20, 12, 6))
    a.rest("R", 0.0).arm("R", 0.40, hh, "out").arm("R", 1.25, hh).rest("R", 1.8, "ease")
    pb = lambda t: pulses(t, 0.30, 0.20, 3, 0.7)

    def bounce(t):
        b = pb(t)
        p = {}
        both(p, "shoulder", rot=(0, -4.0 * b, 0))
        add(p, "chest", rot=(1.5 * b, 0, 0))
        add(p, "head", rot=(2.0 * b, 0, 0))
        return p
    a.on_top(bounce)
    a.f(0.0).f(0.12, "out", smile=0.6, lids=0.8).f(0.40, "ease", smile=0.9, jaw=0.3, lids=0.55, brows=0.3)
    a.f(1.0, "ease", smile=0.8, jaw=0.12, lids=0.7).f(1.8, "ease", smile=0.4)
    c = clip("laugh_polite", 1.8, a, kind="react", tags=["joy", "courtesy"], hands="R", blend_in=0.15, blend_out=0.5,
             groups={"legs": 0.0, "torso": 0.8, "head": 1.0, "arm_L": 0.0, "arm_R": 1.0})
    clips["laugh_polite"] = face_plus(c, lambda t: {"jaw": 0.15 * pb(t)})

    # =================================================================================
    # Side-eye, sold by the head: the eyes go first, then a slow turn of the head,
    # chin down, the lids narrowed, a long held look; caught, it snaps back to front.
    # =================================================================================
    for sd, nm in ((1.0, "side_eye_l"), (-1.0, "side_eye_r")):
        a = Act(2.8, drag=1.0)
        look_t = dict(spine=(0, 1.0 * sd, 2.5 * sd), chest=(-1, -3.0 * sd, 6 * sd), neck=(4, 0, 8 * sd), head=(9, 0, 18 * sd))
        a.t(0.0).t(0.22, "ease").t(0.80, "ease", **look_t)
        a.t(0.98, "settle", **dict(look_t, head=(10, 0, 20 * sd)))
        a.t(2.05, "ease", **dict(look_t, head=(10, 1 * sd, 20 * sd)))
        a.t(2.20, "snap", head=(-1, 0, 2 * sd)).t(2.8, "ease")
        a.f(0.0).f(0.22, "snap", eyes_x=sd, lids=0.85).f(0.8, "ease", eyes_x=sd, lids=0.6, tight=0.45, stern=0.35, brows=-0.25, sneer=0.15)
        a.f(2.05, "ease", eyes_x=sd, lids=0.58, tight=0.5, stern=0.35, brows=-0.3, sneer=0.2)
        a.f(2.20, "snap", eyes_x=0.0, lids=1.08, brows=0.25, tight=0.3).f(2.8, "ease")
        a.on_top(lambda t: drift(t, 0.4 * L.clamp01((t - 0.9) / 0.2) * (1 - L.clamp01((t - 2.0) / 0.1)), 2.3, 0.3))
        clips[nm] = clip(nm, 2.8, a, tags=["scorn", "doubt", "conspiracy"], kind="react", hands="", blend_in=0.2, blend_out=0.5,
                         groups={"legs": 0.0, "torso": 0.6, "head": 1.0, "arm_L": 0.0, "arm_R": 0.0})

    # =================================================================================
    # The half-catch: a stagger step toward them, hands under their armpits,
    # knees bending to take the weight, down with them, and up again with a
    # hand to the small of the back.  (The faller stands on side sd, ~0.8 m off.)
    # =================================================================================
    for sd, nm in ((1.0, "half_catch_l"), (-1.0, "half_catch_r")):
        s_ = "L" if sd > 0 else "R"
        o_ = "R" if sd > 0 else "L"
        a = Act(2.6, drag=0.9)
        reach_t = dict(hips=(6, 0, 22 * sd), hips_loc=(0.12 * sd, -0.02, -0.08), spine=(6, 0, 8 * sd), chest=(9, 0, 10 * sd), neck=(2, 0, 0), head=(-6, 0, 8 * sd))
        catch_t = dict(hips=(10, 0, 26 * sd), hips_loc=(0.16 * sd, -0.03, -0.17), spine=(8, 0, 10 * sd), chest=(8, 0, 12 * sd), neck=(4, 0, 0), head=(-8, 0, 8 * sd))
        sag_t = dict(catch_t, hips_loc=(0.14 * sd, -0.03, -0.23), chest=(12, 0, 8 * sd))
        low_t = dict(hips=(20, 0, 26 * sd), hips_loc=(0.16 * sd, -0.02, -0.24), spine=(14, 0, 8 * sd), chest=(12, 0, 10 * sd), neck=(0, 0, 0), head=(-12, 0, 6 * sd))
        up_t = dict(hips=(0, 0, 6 * sd), hips_loc=(0.10 * sd, 0.0, -0.03), spine=(-4, 0, 2 * sd), chest=(-7, 0, 3 * sd), neck=(-2, 0, 0), head=(-6, 0, 4 * sd))
        a.t(0.0).t(0.10, "snap", chest=(-2, 0, 3 * sd), head=(-4, 0, 10 * sd))
        a.t(0.38, "out", **reach_t).t(0.62, "in", **catch_t).t(0.76, "settle", **dict(catch_t, hips_loc=(0.13 * sd, -0.03, -0.15)))
        a.t(1.0, "ease", **sag_t).t(1.55, "in", **low_t).t(1.75, "ease", **low_t).t(2.15, "out", **up_t)
        a.t(2.6, "ease", hips_loc=(0.08 * sd, 0.0, -0.01), chest=(-2, 0, 2 * sd))
        a.foot(s_, 0.0).foot(s_, 0.30, (0.28 * sd, -0.08, 0.0), "out", lift=0.06, rot=(0, 0, 20 * sd)).foot(s_, 2.6, (0.28 * sd, -0.08, 0.0), rot=(0, 0, 20 * sd))
        a.foot(o_, 0.0).foot(o_, 0.42).foot(o_, 0.62, (0.10 * sd, -0.02, 0.0), "out", lift=0.04).foot(o_, 2.6, (0.10 * sd, -0.02, 0.0))

        def under(z, torso, mid):
            # z: her armpits' height; mid: her chest's middle (metres toward her).
            # The near hand goes behind her, under the far armpit; the far hand
            # crosses in front, under the near one. Palms up into the pits,
            # fingers up her sides: the hands are where they take her weight.
            near = arm_at(s_, w=body_pt(mid + 0.15, 0.07, z - 0.13), along=(0.10, 0.05, 0.99), palm=(-0.95, 0.0, 0.25), pole=(0.3, 0.8, -0.5), curl=(30, 22, 10))
            far = arm_at(o_, w=body_pt(-(mid - 0.16), -0.10, z - 0.13), along=(-0.10, -0.05, 0.99), palm=(-0.95, 0.0, 0.25), pole=(0.2, 0.1, -1.0), curl=(30, 22, 10))
            return near, far
        n1, f1 = under(1.18, reach_t, 0.66)
        a.rest(s_, 0.0).world(s_, 0.40, reach_t, n1.copy(arc=(0.04, -0.08, 0.0)), "out")
        a.rest(o_, 0.0).world(o_, 0.44, reach_t, f1.copy(arc=(0.0, -0.10, 0.03)), "out")
        n2, f2 = under(1.06, catch_t, 0.60)
        a.world(s_, 0.62, catch_t, n2, "in").world(o_, 0.62, catch_t, f2, "in")
        n3, f3 = under(0.98, sag_t, 0.56)
        a.world(s_, 1.0, sag_t, n3).world(o_, 1.0, sag_t, f3)
        n4, f4 = under(0.84, low_t, 0.58)
        a.world(s_, 1.55, low_t, n4, "in").world(o_, 1.55, low_t, f4, "in").world(s_, 1.75, low_t, n4).world(o_, 1.75, low_t, f4)
        back = arm_at(o_, w=body_pt(0.13, 0.15, z_waist - 0.06), along=(-0.5, 0.2, -0.8), palm=(0.0, -1.0, 0.0), pole=(1.0, 0.6, 0.0), curl=(20, 14, 8))
        a.world(o_, 2.15, up_t, back.copy(arc=(0.06, 0.06, 0.0)), "out").world(o_, 2.6, up_t, back)
        a.rest(s_, 2.2, "ease")
        a.f(0.0).f(0.10, "snap", lids=1.35, brows=1.0, jaw=0.35).f(0.62, "ease", puff=0.7, worry=0.75, brows=0.8, lids=1.15, jaw=0.15)
        a.f(1.0, "ease", puff=0.85, tight=0.4, lids=0.6, worry=0.8).f(1.55, "ease", puff=0.6, lids=0.5, worry=0.8)
        a.f(2.1, "ease", jaw=0.3, lids=0.7, worry=0.5, tight=0.5).f(2.6, "ease", worry=0.3, tight=0.3)
        a.on_top(lambda t: tremble(t, 0.9 * L.clamp01((t - 0.62) / 0.1) * (1 - L.clamp01((t - 1.7) / 0.2)), 1.1, 0.2))
        clips[nm] = clip(nm, 2.6, a, kind="react", tags=["comic", "care", "strain"], blend_in=0.08, blend_out=0.5)

    # =================================================================================
    # The faint: the eyes go, the knees give and they drop straight down onto
    # both knees, wobble there a moment, and keel over sideways onto the floor,
    # the legs going out straight with the body. The thighs never come up in
    # front of the hips (a skirt or a robe would leave them bare and the legs
    # would seem cut off at the knee). Holds.
    # =================================================================================
    import court_anims_more as X
    for sd, nm in ((1.0, "faint_l"), (-1.0, "faint_r")):
        a = Act(2.2, drag=1.1, feet=False, base_pose=X.square())
        legs0 = X._legs0(a)
        kneel = X.both_knees(a)
        # the knees buckle forward first (the feet stay under), then the seat drops
        buckle = merge(legs0, {"thigh.L": {"rot": (-25, 0, -2)}, "shin.L": {"rot": (50, 0, 0)}, "foot.L": {"rot": (-22, 0, 0)},
                               "thigh.R": {"rot": (-25, 0, 2)}, "shin.R": {"rot": (50, 0, 0)}, "foot.R": {"rot": (-22, 0, 0)}})
        sway = dict(hips_loc=(0.010 * sd, 0, 0), spine=(0, 0, 2 * sd), neck=(0, 0, 4 * sd), head=(-7, 0, 6 * sd))
        on_knees = dict(hips=(6, 0, 3 * sd), hips_loc=(0.0, 0.07, -0.41), spine=(10, 0, 4 * sd), chest=(8, 0, 4 * sd), neck=(12, 0, 6 * sd), head=(20, 6 * sd, 14 * sd))
        wobble = dict(on_knees, spine=(8, 0, -3 * sd), chest=(6, 0, -3 * sd), head=(16, -4 * sd, -6 * sd))
        lying = dict(hips=(0, 84 * sd, 0), hips_loc=(0.20 * sd, 0.02, -0.71), spine=(6, 0, 4 * sd), chest=(4, 0, 4 * sd), neck=(0, 0, 12 * sd), head=(-4, 8 * sd, 16 * sd))
        a.t(0.0).t(0.14, "out", **sway).t(0.30, "in", hips=(-4, 0, 2 * sd), hips_loc=(0.0, -0.02, -0.12), spine=(6, 0, 3 * sd), neck=(6, 0, 4 * sd), head=(10, 4 * sd, 10 * sd))
        a.t(0.41, "ease", hips=(2, 0, 2 * sd), hips_loc=(0.0, 0.04, -0.31), spine=(8, 0, 3 * sd), neck=(8, 0, 5 * sd), head=(14, 5 * sd, 12 * sd))
        a.t(0.48, "in", **dict(on_knees, hips_loc=(0.0, 0.07, -0.415))).t(0.58, "settle", **dict(on_knees, hips_loc=(0.0, 0.07, -0.40))).t(0.80, "ease", **dict(wobble, hips_loc=(0.0, 0.07, -0.40)))
        # the roll pivots on the downhill knee: the seat stays up until the body is half over
        a.t(0.98, "in", **dict(lying, hips=(0, 40 * sd, 0), hips_loc=(0.10 * sd, 0.05, -0.40), spine=(8, 0, 4 * sd)))
        a.t(1.12, "in", **lying).t(1.24, "settle", **dict(lying, hips_loc=(0.20 * sd, 0.02, -0.70))).t(2.2, "ease", **lying)
        # keeling over with the knees still folded: the legs turn with the hips
        # (no swing through the floor, and a skirt stays over the thighs)
        half = merge(legs0, {"thigh.L": {"rot": (-6, 0, -3)}, "shin.L": {"rot": (78, 0, 0)}, "foot.L": {"rot": (-72, 0, 0)},
                             "thigh.R": {"rot": (-6, 0, 3)}, "shin.R": {"rot": (78, 0, 0)}, "foot.R": {"rot": (-72, 0, 0)}})
        a.legs([(0.0, legs0), (0.14, legs0), (0.30, buckle, "in"), (0.41, half, "ease"), (0.48, kneel, "out"), (2.2, kneel)])
        s_dn = "L" if sd > 0 else "R"
        s_up = "R" if sd > 0 else "L"
        under_head = arm_at(s_dn, w=body_pt(0.16, -0.06, f.z_shoulder / k + 0.36), along=(0.1, -0.1, 0.99), palm=(-0.9, 0.0, 0.0), pole=(0.9, 0.3, -0.2),
                            curl=(30, 20, 10))
        draped = arm_at(s_up, w=body_pt(0.04, -0.34, z_waist + 0.04), along=(-0.2, -0.4, -0.9), palm=(0.0, 0.3, -0.95), pole=(0.9, 0.6, 0.0),
                        curl=(40, 30, 14))
        for s_ in "LR":
            limp = hang(a, s_, 10, curl=(40, 30, 14))
            a.rest(s_, 0.0).rest(s_, 0.14).arm(s_, 0.5, limp, "in").arm(s_, 0.8, limp)
        a.arm(s_dn, 1.12, under_head, "in").arm(s_dn, 2.2, under_head)
        a.arm(s_up, 1.16, draped, "in").arm(s_up, 2.2, draped)
        a.f(0.0).f(0.14, "out", lids=0.45, eyes_y=1.0, brows=0.5, worry=0.3).f(0.48, "ease", lids=0.08, eyes_y=0.6, jaw=0.25, brows=0.2)
        a.f(1.1, "ease", lids=0.04, jaw=0.35).f(2.2, "ease", lids=0.04, jaw=0.32)
        clips[nm] = clip(nm, 2.2, a, kind="react", hold=True, tags=["fear", "comic"], blend_in=0.12, blend_out=0.8)

    # caught: the knees give, the catcher's hands under the arms; down onto both
    # knees and slumped against the hands, the head lolling (holds, kneeling)
    for sd, nm in ((1.0, "faint_caught_l"), (-1.0, "faint_caught_r")):
        a = Act(2.4, drag=1.1, feet=False, base_pose=X.square())
        legs0 = X._legs0(a)
        kneel = X.both_knees(a)
        sag = dict(hips=(-4, 0, 2 * sd), hips_loc=(0.02 * sd, -0.02, -0.11), spine=(-2, 6 * sd, 4 * sd), chest=(-4, 8 * sd, 4 * sd), neck=(-4, 4 * sd, 4 * sd), head=(-12, 10 * sd, 12 * sd))
        down = dict(hips=(6, 0, 4 * sd), hips_loc=(0.03 * sd, 0.07, -0.41), spine=(4, 6 * sd, 8 * sd), chest=(2, 8 * sd, 8 * sd), neck=(6, 4 * sd, 10 * sd), head=(14, 10 * sd, 18 * sd))
        slump = dict(down, spine=(10, 6 * sd, 10 * sd), chest=(8, 8 * sd, 10 * sd), neck=(14, 4 * sd, 12 * sd), head=(24, 10 * sd, 22 * sd))
        a.t(0.0).t(0.14, "out", hips_loc=(0.010 * sd, 0, 0), spine=(0, 0, 2 * sd), head=(-7, 0, 6 * sd))
        a.t(0.60, "in", **sag).t(0.86, "ease", **dict(sag, hips=(2, 0, 3 * sd), hips_loc=(0.03 * sd, 0.04, -0.28)))
        a.t(1.0, "out", **dict(down, hips_loc=(0.03 * sd, 0.07, -0.395))).t(1.12, "settle", **dict(down, hips_loc=(0.03 * sd, 0.07, -0.40)))
        a.t(1.6, "ease", **slump).t(2.4, "ease", **slump)
        buckle = merge(legs0, {"thigh.L": {"rot": (-25, 0, -2)}, "shin.L": {"rot": (50, 0, 0)}, "foot.L": {"rot": (-22, 0, 0)},
                               "thigh.R": {"rot": (-25, 0, 2)}, "shin.R": {"rot": (50, 0, 0)}, "foot.R": {"rot": (-22, 0, 0)}})
        half = merge(legs0, {"thigh.L": {"rot": (-6, 0, -3)}, "shin.L": {"rot": (78, 0, 0)}, "foot.L": {"rot": (-72, 0, 0)},
                             "thigh.R": {"rot": (-6, 0, 3)}, "shin.R": {"rot": (78, 0, 0)}, "foot.R": {"rot": (-72, 0, 0)}})
        a.legs([(0.0, legs0), (0.14, legs0), (0.6, buckle, "in"), (0.86, half, "ease"), (1.0, kneel, "out"), (2.4, kneel)])
        for s_ in "LR":
            limp = hang(a, s_, -8, curl=(40, 30, 14))
            a.rest(s_, 0.0).rest(s_, 0.14).arm(s_, 0.6, limp.copy(sh=(0, -14, 0)), "ease").arm(s_, 1.0, limp.copy(sh=(0, -18, 0)), "ease").arm(s_, 2.4, limp.copy(sh=(0, -16, 0)))
        a.f(0.0).f(0.14, "out", lids=0.45, eyes_y=1.0, brows=0.5, worry=0.3).f(0.5, "ease", lids=0.08, eyes_y=0.6, jaw=0.25, brows=0.2)
        a.f(1.2, "ease", lids=0.04, jaw=0.35).f(2.4, "ease", lids=0.04, jaw=0.32)
        clips[nm] = clip(nm, 2.4, a, kind="react", hold=True, tags=["fear", "comic"], blend_in=0.12, blend_out=0.8)

    make_stances(clips)
    make_ambient(clips)
    make_exits(clips)


# =====================================================================================
# Stances kept for life
# =====================================================================================

def stance_clip(name, length, act, **meta):
    act.loop = True
    m = {"loop": True, "kind": "stance", "stance": True, "blend_in": 0.6, "blend_out": 0.6}
    m.update(meta)
    return clip(name, length, act, **m)


def make_stances(clips):
    f = L.FRAME
    k = L.K
    z_chest = f.z_chest / k
    z_waist = f.z_waist / k
    lm = landmarks()

    # ---- fidgeting with a cord: hands together at the waist, turning it; eyes on
    #      the hands, now and then up
    a = Act(6.0, drag=1.0)
    down_t = dict(chest=(4, 0, 0), neck=(5, 0, 0), head=(16, 0, -3))
    a.t(0.0, "ease", **down_t).t(2.0, "ease", **dict(down_t, head=(8, 0, -3))).t(3.1, "ease", chest=(0, 0, 0), head=(-2, 0, 2))
    a.t(4.2, "ease", chest=(0, 0, 0), head=(-1, 0, 3)).t(5.0, "ease", **down_t).t(6.0, "ease", **down_t)
    for i in range(13):
        t = i * 0.5
        tw = 1.0 if i % 2 == 0 else -1.0
        pull = 0.045 if i % 4 in (1, 2) else 0.0
        for s_ in "LR":
            sg = 1.0 if s_ == "L" else -1.0
            along = Vector((-0.75, -0.5, 0.45)).normalized()
            palm = L.Quaternion(along, math.radians(42 * tw * sg)) @ Vector((-0.1, -0.2, 0.97))
            key = arm_at(s_, w=body_pt(0.045 + pull, -0.25, z_waist + 0.06 + 0.012 * tw * sg), along=along, palm=palm, pole=(1.0, 0.3, -0.3),
                         curl=(60, 50 + 8 * tw, 30), sh=(0, -6, -3))
            a.arm(s_, t, key, "ease")
    a.f(0.0, "ease", lids=0.75, tight=0.2, worry=0.25).f(2.0, "ease", lids=0.78, tight=0.25, worry=0.25).f(3.1, "ease", lids=1.0, worry=0.35, brows=0.2)
    a.f(4.2, "ease", lids=1.0, worry=0.3).f(5.0, "ease", lids=0.75, tight=0.2, worry=0.25).f(6.0, "ease", lids=0.75, tight=0.2, worry=0.25)
    clips["stance_cord"] = stance_clip("stance_cord", 6.0, a, hands="", tags=["nervous"])

    # ---- holding a bundle against the chest, a hitch to shift its weight
    a = Act(6.0, drag=1.0)
    hold_t = dict(spine=(-2, 0, 0), chest=(-3, 0, 0), head=(4, 0, 0))
    a.t(0.0, "ease", **hold_t).t(1.5, "ease", **dict(hold_t, chest=(-3, 0, 2), hips_loc=(0.006, 0, 0)))
    a.t(2.9, "ease", **hold_t).t(3.05, "out", **dict(hold_t, chest=(-5, 0, 0), hips_loc=(0, 0, 0.008))).t(3.35, "in", **hold_t)
    a.t(4.5, "ease", **dict(hold_t, chest=(-3, 0, -2), hips_loc=(-0.006, 0, 0))).t(6.0, "ease", **hold_t)
    for s_ in "LR":
        held = arm_at(s_, w=body_pt(0.10, -0.27, z_chest - 0.13), along=(-0.55, -0.6, 0.2), palm=(-0.5, 0.1, 0.85), pole=(0.8, 0.4, -0.5), curl=(40, 30, 15))
        a.arm(s_, 0.0, held).arm(s_, 2.9, held).arm(s_, 3.08, held.copy(w=held.w + Vector((0, 0, 0.04 * k))), "out").arm(s_, 3.4, held, "in").arm(s_, 6.0, held)
    a.f(0.0, "ease", lids=0.9).f(3.05, "snap", puff=0.4, lids=0.8).f(3.5, "ease", lids=0.9).f(6.0, "ease", lids=0.9)
    clips["stance_bundle"] = stance_clip("stance_bundle", 6.0, a, hands="", tags=["gift"], prop="bundle")

    # ---- the guard: leaning on the staff (J's staff stays where J's staff stance
    #      plants it), weight on it, the far foot crossed over on its toes, bored
    a = Act(8.0, drag=1.2)
    lean = dict(hips=(0, -5, 0), hips_loc=(-0.075, 0.0, -0.016), spine=(0, -9, -3), chest=(1, -8, -4), neck=(2, -2, 0), head=(6, -9, -6))
    guard_keys = [(0.0, "ease", lean), (2.5, "ease", dict(lean, hips_loc=(-0.080, 0.0, -0.017), head=(8, -10, -7))),
                  (4.4, "ease", dict(lean, head=(12, -11, -8), neck=(5, -2, 0))), (5.0, "snap", dict(lean, head=(0, -5, -3))),
                  (6.2, "ease", dict(lean, head=(5, -8, -5))), (8.0, "ease", lean)]
    for t_, kind_, tt in guard_keys:
        a.t(t_, kind_, **tt)
    staff = staff_hand_world()
    # the staff slanted about the grip: its foot out to the side and a little ahead,
    # its top toward the head; the hand drops so the foot stays on the floor
    grip = staff.w + staff.along * (f.hand_len * 0.42)
    tilt = L.Quaternion(Vector((0, 1, 0)), math.radians(15)) @ L.Quaternion(Vector((1, 0, 0)), math.radians(-6))
    lower = Vector((0, 0, -(grip.z - grip.z * math.cos(math.radians(15)) * math.cos(math.radians(6)))))
    staff = ArmKey(grip + tilt @ (staff.w - grip) + lower, tilt @ staff.pole, tilt @ staff.along, tilt @ staff.palm, staff.curl, staff.sh)
    a.foot("L", 0.0, (-0.15, -0.10, 0.0), rot=(28, 0, -8)).foot("L", 8.0, (-0.15, -0.10, 0.0), rot=(28, 0, -8))
    for t_, kind_, tt in guard_keys:
        a.arm("R", t_, L.world_key(torso_of(a.B, tpose(**tt)), staff), kind_)
    hip_w = L.key_to_world(cf_anim.stance_pose("hip"), stance_arm("hip", "L"))
    hip_w = hip_w.copy(w=hip_w.w + Vector((-0.075 * k, 0.0, -0.016 * k)))
    a.world("L", 0.0, lean, hip_w).world("L", 8.0, lean, hip_w)
    a.f(0.0, "ease", lids=0.66, tight=0.15).f(4.4, "ease", lids=0.45, jaw=0.08).f(5.0, "snap", lids=1.05, brows=0.3).f(6.2, "ease", lids=0.7, tight=0.15)
    a.f(8.0, "ease", lids=0.66, tight=0.15)
    clips["stance_guard"] = stance_clip("stance_guard", 8.0, a, hands="L", tags=["bored", "guard"], prop="staff")

    # ---- an elder seated on a log (low and high seats, blended to the mark's height)
    for nm, seat in (("stance_log_low", 0.30), ("stance_log_high", 0.46)):
        B = seated_base(seat)
        a = Act(6.0, drag=1.2, base_pose=B)
        a.t(0.0).t(1.6, "ease", chest=(1, 0, 1), head=(-1, 0, 2)).t(3.0, "ease", neck=(3, 0, 0), head=(5, 0, 0))
        a.t(4.0, "ease", head=(-1, 0, -2)).t(6.0, "ease")
        a.on_top(lambda t: breathe(t, 3.0, 0.6, 0.1))
        a.f(0.0, "ease", lids=0.8).f(3.0, "ease", lids=0.6).f(4.0, "ease", lids=0.85).f(6.0, "ease", lids=0.8)
        clips[nm] = stance_clip(nm, 6.0, a, hands="LR", tags=["elder", "seated"], seat=seat, seated=True,
                                groups={"legs": 1.0, "torso": 1.0, "head": 1.0, "arm_L": 1.0, "arm_R": 1.0})

    # ---- crouched by the fire, hands out to its warmth; now and then a rub
    B = cf_anim.stance_pose("crouch")
    a = Act(6.0, drag=1.2, base_pose=B)
    a.t(0.0).t(1.5, "ease", chest=(2, 0, 0), head=(2, 0, 0)).t(3.0, "ease", chest=(-1, 0, 0), head=(-2, 0, 2)).t(4.5, "ease", chest=(1, 0, 0))
    a.t(6.0, "ease")
    crouch_t = {}
    for s_ in "LR":
        warm = arm_at(s_, w=body_pt(0.075, -0.40, 0.50), along=(0.08, -0.86, 0.50), palm=(0.0, -0.45, -0.89), pole=(0.7, 0.3, -0.7), curl=(16, 10, 4))
        together = arm_at(s_, w=body_pt(0.03, -0.38, 0.56), along=(-0.5, -0.5, 0.7), palm=(-0.95, 0.0, 0.2), pole=(0.7, 0.3, -0.7), curl=(10, 4, 0))
        a.world(s_, 0.0, crouch_t, warm).world(s_, 2.3, crouch_t, warm).world(s_, 2.6, crouch_t, together, "out")
        for i in range(5):
            up_ = 0.025 * (1 if (i % 2 == 0) == (s_ == "L") else -1)
            a.world(s_, 2.75 + 0.2 * i, crouch_t, together.copy(w=together.w + Vector((0, 0, up_ * k))))
        a.world(s_, 3.9, crouch_t, together).world(s_, 4.3, crouch_t, warm, "out").world(s_, 6.0, crouch_t, warm)
    a.f(0.0, "ease", lids=0.8, smile=0.15).f(2.7, "ease", lids=0.7, smile=0.25).f(4.3, "ease", lids=0.8, smile=0.15).f(6.0, "ease", lids=0.8, smile=0.15)
    clips["stance_fire"] = stance_clip("stance_fire", 6.0, a, hands="", tags=["warm", "crouch"], seated=True,
                                       groups={"legs": 1.0, "torso": 1.0, "head": 1.0, "arm_L": 1.0, "arm_R": 1.0})


def seated_base(seat):
    """An elder on a seat `seat` metres high (for a 1.72 m body): back rounded,
    head up to look out, feet planted apart, hands on the knees."""
    f = L.FRAME
    k = L.K
    p = {}
    loc_z = (seat * k + 0.085 * k - f.pelvis.z) / k
    add(p, "hips", rot=(-10, 0, 0), loc=(0.0, 0.035, loc_z))
    add(p, "spine", rot=(14, 0, 0))
    add(p, "chest", rot=(8, 0, 1))
    add(p, "neck", rot=(-6, 0, 0))
    add(p, "head", rot=(-12, 2, -2))
    add(p, "jaw", open_=1.0)
    reach = 0.30 + 0.12 * (0.46 - seat) / 0.16
    feet = {"L": Vector((0.15 * k, -reach * k, f.ankle["L"].z)), "R": Vector((-0.15 * k, -reach * k, f.ankle["R"].z))}
    knees = {"L": Vector((0.35, -0.9, 0.25)).normalized(), "R": Vector((-0.35, -0.9, 0.25)).normalized()}
    plant(p, feet, knees, {"L": (0, 0, 6), "R": (0, 0, -6)})
    fk = legs_fk(p)
    for s_ in "LR":
        knee = fk[s_][1]
        out_ = 1.0 if s_ == "L" else -1.0
        w_ = knee + Vector((0.0, 0.03 * k, 0.05 * k))
        key = ArmKey(w_, Vector((out_ * 0.7, 0.4, -0.2)).normalized(), Vector((0.0, -0.85, -0.5)).normalized(),
                     Vector((0.0, 0.05, -1.0)).normalized(), (36, 28, 12))
        key.w = w_ - key.along * (f.hand_len * 0.40) + Vector((0, 0, 0.012 * k))
        p.update(arm_solve(s_, L.world_key(p, key)))
    return p


# =====================================================================================
# The room's idle business (court_director.gd ambient acts)
# =====================================================================================

def make_ambient(clips):
    f = L.FRAME
    k = L.K
    z_chest = f.z_chest / k
    z_waist = f.z_waist / k
    lm = landmarks()
    upper = {"legs": 0.0, "torso": 1.0, "head": 1.0, "arm_L": 1.0, "arm_R": 1.0}

    # ---- cough: a breath, three coughs into a fist, turned away; a clearing of the throat
    a = Act(1.8, drag=0.7)
    away = dict(chest=(3, 0, -3), neck=(3, 0, -4), head=(8, 0, -12))
    a.t(0.0).t(0.12, "out", chest=(-3, 0, 0), head=(-4, 0, 0)).t(0.24, "snap", **away).t(1.25, "ease", **away).t(1.45, "out", head=(4, 0, -3)).t(1.8, "ease")
    fist = hand_mouth("R", cover=True).copy(curl=(85, 75, 45))
    a.rest("R", 0.0).arm("R", 0.20, fist.copy(arc=(0.05, -0.08, 0.0)), "out").arm("R", 1.3, fist).rest("R", 1.8, "ease")
    cb = lambda t: pulses(t, 0.24, 0.30, 3, 0.8, 1.5)

    def coughs(t):
        b = cb(t)
        p = {}
        add(p, "chest", rot=(7 * b, 0, 0))
        add(p, "spine", rot=(3 * b, 0, 0))
        add(p, "head", rot=(8 * b, 0, 0))
        add(p, "hips", loc=(0, 0, -0.004 * b))
        both(p, "shoulder", rot=(0, -6 * b, 0))
        return p
    a.on_top(coughs)
    a.f(0.0).f(0.12, "out", lids=0.8, brows=0.2).f(0.24, "snap", lids=0.4, worry=0.35, tight=0.3).f(1.3, "ease", lids=0.5, worry=0.3).f(1.8, "ease")
    c = clip("cough", 1.8, a, kind="ambient", tags=["sick"], hands="R", groups=upper, blend_in=0.12, blend_out=0.4)
    clips["cough"] = face_plus(c, lambda t: {"jaw": 0.45 * cb(t), "lids": -0.3 * cb(t)})

    # ---- keep apart: lean and step away from the cougher on side sd, a hand up,
    #      the other over the mouth, face turned away. Holds.
    for sd, nm in ((1.0, "keep_apart_l"), (-1.0, "keep_apart_r")):
        s_ = "L" if sd > 0 else "R"
        o_ = "R" if sd > 0 else "L"
        a = Act(1.4, drag=0.8)
        lean_t = dict(hips_loc=(-0.07 * sd, 0.02, 0.0), spine=(0, -3 * sd, -2 * sd), chest=(-2, -5 * sd, -4 * sd), neck=(2, 0, -5 * sd), head=(4, 0, -14 * sd))
        a.t(0.0).t(0.45, "out", **lean_t).t(1.4, "ease", **lean_t)
        a.foot(o_, 0.0).foot(o_, 0.38, (-0.16 * sd, 0.04, 0.0), "out", lift=0.05).foot(o_, 1.4, (-0.16 * sd, 0.04, 0.0))
        a.foot(s_, 0.0).foot(s_, 0.30).foot(s_, 0.55, (-0.06 * sd, 0.02, 0.0), "out", lift=0.03).foot(s_, 1.4, (-0.06 * sd, 0.02, 0.0))
        fend = arm_at(s_, w=body_pt(0.27, -0.22, z_waist + 0.06), along=(0.3, -0.5, 0.8), palm=(0.9, -0.2, 0.2), pole=(0.8, 0.4, -0.5), curl=(10, 4, 0))
        a.rest(s_, 0.0).arm(s_, 0.4, fend, "out").arm(s_, 1.4, fend)
        a.rest(o_, 0.0).arm(o_, 0.5, hand_mouth(o_, cover=True).copy(arc=(0.04, -0.06, 0.0)), "out").arm(o_, 1.4, hand_mouth(o_, cover=True))
        a.f(0.0).f(0.4, "out", tight=0.6, lids=0.7, sneer=0.3, worry=0.3, eyes_x=sd).f(1.4, "ease", tight=0.6, lids=0.7, sneer=0.3, worry=0.3, eyes_x=sd)
        a.on_top(lambda t: drift(t, 0.4 * L.clamp01((t - 0.5) / 0.3), 2.2))
        clips[nm] = clip(nm, 1.4, a, kind="ambient", hold=True, tags=["sick", "disgust"], blend_in=0.15, blend_out=0.6)

    # ---- the stomach rumbles: a start, a look down, a rub of the belly, a guilty look round
    a = Act(2.6, drag=0.9)
    look_down = dict(hips_loc=(0, 0.01, -0.01), spine=(6, 0, 0), chest=(8, 0, 2), neck=(6, 0, 0), head=(24, 0, 4))
    a.t(0.0).t(0.1, "snap", chest=(-4, 0, 0), head=(-5, 0, 0), hips_loc=(0, 0, 0.008)).t(0.42, "out", **look_down)
    a.t(1.65, "ease", **look_down).t(1.85, "out", chest=(1, 0, 0), head=(-2, 0, 18)).t(2.2, "out", chest=(1, 0, 0), head=(-2, 0, -16)).t(2.6, "ease")
    hb = hand_belly("L").copy(pole=mv((1.0, 0.2, -0.3), "L"), curl=(10, 6, 2))
    other = arm_at("R", w=None, contact=landmarks()["belly"] + Vector((0.07 * k, 0.0, 0.05 * k)), along=(-0.9, -0.1, -0.3), palm=(0.0, 1.0, 0.0),
                   pole=(1.0, 0.2, -0.3), curl=(12, 8, 4))
    a.rest("L", 0.0).world("L", 0.45, look_down, hb, "out")
    for i in range(8):
        ang = i * math.pi / 2
        a.world("L", 0.6 + 0.14 * i, look_down, hb.copy(w=hb.w + Vector((0.05 * k * math.cos(ang), 0.0, 0.045 * k * math.sin(ang)))), "ease")
    a.world("L", 1.75, look_down, hb).rest("L", 2.6, "ease")
    a.rest("R", 0.0).rest("R", 0.3).world("R", 0.6, look_down, other, "out").world("R", 1.7, look_down, other).rest("R", 2.5, "ease")
    a.f(0.0).f(0.1, "snap", lids=1.3, brows=0.6).f(0.4, "ease", worry=0.4, tight=0.3, eyes_y=-0.8).f(1.5, "ease", worry=0.4, tight=0.35, eyes_y=-0.6)
    a.f(1.7, "out", eyes_x=0.8, tight=0.5, brows=0.5, smile=0.15).f(2.05, "out", eyes_x=-0.8, tight=0.5, brows=0.5).f(2.4, "ease")
    clips["rub_belly"] = clip("rub_belly", 2.6, a, kind="ambient", tags=["hungry", "comic"], hands="LR", groups=upper, blend_in=0.12, blend_out=0.5)

    # ---- a pat of a full belly, content
    a = Act(1.4, drag=1.0)
    a.t(0.0).t(0.3, "out", chest=(-3, 0, 0), head=(-4, 0, 2)).t(1.1, "ease", chest=(-2, 0, 0), head=(-3, 0, 2)).t(1.4, "ease")
    hb2 = hand_belly("R")
    a.rest("R", 0.0).arm("R", 0.3, hb2, "out")
    for i, t in enumerate((0.48, 0.6, 0.78, 0.9)):
        a.arm("R", t, hb2.copy(w=hb2.w + Vector((0, -0.03 * k if i % 2 == 0 else 0.0, 0.0))), "out")
    a.arm("R", 1.05, hb2).rest("R", 1.4, "ease")
    a.f(0.0).f(0.3, "out", smile=0.6, lids=0.7).f(1.1, "ease", smile=0.5, lids=0.75).f(1.4, "ease", smile=0.2)
    clips["pat_belly"] = clip("pat_belly", 1.4, a, kind="ambient", tags=["fed", "content"], hands="R", groups=upper, blend_in=0.15, blend_out=0.4)

    # ---- sharpen the spear: the staff in the right hand (where J's staff stance holds
    #      it), a stone in the left worked up and down the shaft above it
    sp = cf_anim.stance_pose("staff")
    staff = L.key_to_world(sp, arm_fk(sp, "R"))
    grip = staff.w + staff.along * (f.hand_len * 0.42)
    a = Act(2.4, drag=1.0, base_pose=dict(sp))
    work_t = dict(chest=(4, 0, -4), neck=(4, 0, -4), head=(12, 0, -10))
    a.t(0.0, "ease", **work_t).t(2.4, "ease", **work_t)
    a.world("R", 0.0, work_t, staff).world("R", 2.4, work_t, staff)
    for i in range(9):
        t = i * 0.3
        z = 0.10 if i % 2 == 0 else 0.26
        contact = grip + Vector((0.035 * k, -0.02 * k, z * k))
        along = Vector((0.0, -0.3, 0.95)).normalized()
        palm = Vector((-1.0, 0.0, 0.0))
        w_ = contact - along * (f.hand_len * 0.45) - palm * (0.016 * k)
        key = ArmKey(mv(w_, "L"), Vector((0.8, 0.3, -0.5)), along, palm, (60, 50, 30))
        a.world("L", t, work_t, key, "ease")
    a.f(0.0, "ease", lids=0.75, tight=0.3, eyes_y=-0.4, eyes_x=-0.5).f(2.4, "ease", lids=0.75, tight=0.3, eyes_y=-0.4, eyes_x=-0.5)
    a.loop = True
    clips["sharpen_spear"] = clip("sharpen_spear", 2.4, a, kind="ambient", loop=True, tags=["war"], hands="", prop="staff", blend_in=0.3, blend_out=0.4)

    # ---- cold: arms wrapped round, shoulders up, stamping the feet
    a = Act(2.0, drag=0.8)
    hunch = dict(chest=(6, 0, 0), neck=(2, 0, 0), head=(4, 0, 0))
    a.t(0.0, "ease", **hunch).t(2.0, "ease", **hunch)
    a.loop = True
    hug_l = arm_at("L", w=body_pt(-0.13, -0.15, z_chest + 0.03), along=(-0.6, 0.5, 0.4), palm=(0.4, 0.85, 0.0), pole=(0.5, -0.4, -1.0), curl=(50, 40, 20), sh=(0, -12, -6))
    hug_r = arm_at("R", w=body_pt(-0.12, -0.12, z_chest - 0.04), along=(-0.6, 0.55, 0.35), palm=(0.4, 0.85, -0.1), pole=(0.5, -0.4, -1.0), curl=(50, 40, 20), sh=(0, -12, -6))
    a.world("L", 0.0, hunch, hug_l).world("L", 2.0, hunch, hug_l).world("R", 0.0, hunch, hug_r).world("R", 2.0, hunch, hug_r)
    a.foot("L", 0.0).foot("L", 0.32, lift=0.11, kind="in").foot("L", 2.0)
    a.foot("R", 0.0).foot("R", 1.0).foot("R", 1.32, lift=0.11, kind="in").foot("R", 2.0)
    stamp = lambda t: pulses(t, 0.30, 0.2, 1, 1.0) + pulses(t, 1.30, 0.2, 1, 1.0)
    a.on_top(lambda t: merge(tremble(t, 0.6, 1.2, 0.4), {"hips": {"loc": (0, 0, -0.012 * stamp(t))}}))
    a.f(0.0, "ease", tight=0.5, lids=0.75, puff=0.2, worry=0.3).f(2.0, "ease", tight=0.5, lids=0.75, puff=0.2, worry=0.3)
    clips["stamp_feet"] = clip("stamp_feet", 2.0, a, kind="ambient", loop=True, tags=["cold"], hands="", blend_in=0.3, blend_out=0.4)

    # ---- cold hands: rubbed together, then blown into
    a = Act(1.8, drag=0.9)
    a.t(0.0).t(0.3, "out", chest=(4, 0, 0), head=(4, 0, 0)).t(1.0, "ease", chest=(5, 0, 0), head=(8, 0, 0)).t(1.5, "ease", chest=(3, 0, 0), head=(2, 0, 0)).t(1.8, "ease")
    for s_ in "LR":
        rub = arm_at(s_, w=body_pt(0.03, -0.26, z_chest - 0.05), along=(-0.55, -0.45, 0.7), palm=(-0.95, 0.0, 0.2), pole=(0.8, 0.4, -0.6), curl=(10, 4, 0), sh=(0, -8, 0))
        blow = arm_at(s_, w=body_pt(0.02, -0.20, f.face(0.12) / k - 0.10), along=(-0.3, -0.3, 0.9), palm=(-0.9, 0.2, 0.2), pole=(0.8, 0.3, -0.6), curl=(30, 25, 15), sh=(0, -8, 0))
        a.rest(s_, 0.0).arm(s_, 0.3, rub, "out")
        for i in range(4):
            up_ = 0.03 * (1 if (i % 2 == 0) == (s_ == "L") else -1)
            a.arm(s_, 0.42 + 0.12 * i, rub.copy(w=rub.w + Vector((0, 0, up_ * k))))
        a.arm(s_, 0.95, blow, "out").arm(s_, 1.35, blow).rest(s_, 1.8, "ease")
    a.f(0.0).f(0.3, "out", tight=0.4, lids=0.8).f(1.0, "ease", puff=0.8, lids=0.6).f(1.35, "ease", puff=0.3, lids=0.8).f(1.8, "ease")
    clips["rub_hands"] = clip("rub_hands", 1.8, a, kind="ambient", tags=["cold"], hands="LR", groups=upper, blend_in=0.15, blend_out=0.4)

    # ---- swat a fly: the eyes follow it, the head jerks, a swat, a look at the palm, a wipe
    a = Act(1.6, drag=0.6)
    a.lags = {"head": 0.0, "neck": 0.0}
    a.t(0.0).t(0.2, "snap", head=(-2, 0, -6)).t(0.42, "snap", head=(-4, 0, 8)).t(0.6, "snap", head=(-2, 0, -3))
    a.t(0.74, "snap", chest=(-2, 0, 0), head=(-4, 0, 0)).t(1.0, "out", chest=(3, 0, 0), head=(12, 0, 2)).t(1.3, "ease", head=(4, 0, 0)).t(1.6, "ease")
    wind = arm_at("R", w=body_pt(0.24, -0.06, z_chest + 0.14), along=(0.2, 0.0, 0.98), palm=(-0.9, -0.3, 0.0), pole=(0.9, 0.3, -0.2), curl=(4, -4, -6))
    swat = arm_at("R", w=body_pt(-0.06, -0.32, z_chest + 0.24), along=(-0.6, -0.4, 0.7), palm=(-0.95, 0.2, 0.0), pole=(0.9, 0.2, -0.4), curl=(4, -4, -6))
    look = arm_at("R", w=body_pt(0.10, -0.30, z_chest + 0.06), along=(-0.2, -0.6, 0.75), palm=(0.0, 0.6, 0.8), pole=(0.8, 0.4, -0.6), curl=(16, 8, 4))
    a.rest("R", 0.0).rest("R", 0.5).arm("R", 0.64, wind, "out").arm("R", 0.74, swat, "snap").arm("R", 1.0, look, "out").arm("R", 1.3, hand_thigh("R"), "ease").rest("R", 1.6, "ease")
    a.f(0.0).f(0.2, "snap", eyes_x=-1.0, brows=0.3, tight=0.2).f(0.42, "snap", eyes_x=1.0).f(0.6, "snap", eyes_x=-0.3, eyes_y=0.3)
    a.f(0.74, "snap", lids=0.3, tight=0.6, eyes_x=0.0).f(1.0, "out", lids=1.0, brows=0.5, eyes_y=-0.6).f(1.3, "ease", sneer=0.3, eyes_y=-0.3).f(1.6, "ease")
    clips["swat_fly"] = clip("swat_fly", 1.6, a, kind="ambient", tags=["comic", "warm"], hands="R", groups=upper, blend_in=0.1, blend_out=0.4)

    # ---- a stretch: arms up, back arched, a twist each way, arms down and out, a breath out
    a = Act(2.6, drag=1.0)
    up_t = dict(hips_loc=(0, -0.03, 0.035), spine=(-8, 0, 0), chest=(-14, 0, 0), neck=(-5, 0, 0), head=(-14, 0, 0))
    for s_ in "LR":
        a.foot(s_, 0.0).foot(s_, 0.3).foot(s_, 0.9, (0, 0, 0.035), "out", rot=(25, 0, 0)).foot(s_, 1.6, (0, 0, 0.035), rot=(25, 0, 0)).foot(s_, 1.95, (0, 0, 0), "in")
    a.t(0.0).t(0.3, "out", chest=(3, 0, 0), head=(3, 0, 0)).t(0.9, "out", **up_t).t(1.3, "ease", **dict(up_t, chest=(-9, 0, 6), head=(-8, 0, 6)))
    a.t(1.6, "ease", **dict(up_t, chest=(-9, 0, -6), head=(-8, 0, -6))).t(1.95, "out", chest=(-3, 0, 0), head=(-3, 0, 0)).t(2.6, "ease")
    for s_ in "LR":
        overhead = arm_at(s_, w=body_pt(0.20, 0.04, z_chest + 0.66), along=(0.25, 0.05, 0.97), palm=(-0.3, -0.95, 0.0), pole=(0.9, 0.1, 0.2), curl=(10, 0, -6), sh=(0, -16, 0))
        wide = arm_at(s_, w=body_pt(0.62, 0.02, z_chest + 0.26), along=(0.95, 0.0, 0.3), palm=(0.0, 0.0, 1.0), pole=(0.0, 0.6, -0.8), curl=(6, 0, -6))
        a.rest(s_, 0.0).rest(s_, 0.3).arm(s_, 0.9, overhead.copy(arc=(0.06, -0.08, 0.0)), "out").arm(s_, 1.6, overhead)
        a.arm(s_, 1.95, wide, "out").rest(s_, 2.5, "ease")
    a.f(0.0).f(0.9, "out", lids=0.15, jaw=0.95, brows=0.6).f(1.6, "ease", lids=0.2, jaw=0.8, brows=0.5).f(2.0, "out", puff=0.5, lids=0.7, smile=0.4).f(2.6, "ease")
    clips["stretch"] = clip("stretch", 2.6, a, kind="ambient", tags=["tired", "content"], hands="LR", blend_in=0.2, blend_out=0.5)

    # ---- whisper to the neighbour on side sd: lean in, a hand cupped by the mouth,
    #      a dart of the eyes up to the god, lean back
    for sd, nm in ((1.0, "whisper_l"), (-1.0, "whisper_r")):
        s_ = "L" if sd > 0 else "R"
        a = Act(2.0, drag=0.9)
        lean_t = dict(hips_loc=(0.06 * sd, -0.01, -0.01), spine=(2, 4 * sd, 3 * sd), chest=(3, 5 * sd, 6 * sd), neck=(3, 0, 6 * sd), head=(6, 0, 16 * sd))
        a.t(0.0).t(0.35, "out", **lean_t).t(1.15, "ease", **lean_t).t(1.25, "snap", **dict(lean_t, head=(0, 0, 10 * sd)))
        a.t(1.45, "ease", **lean_t).t(1.65, "out", chest=(-1, 0, 0), head=(-2, 0, 2 * sd)).t(2.0, "ease")
        mouth = lm["mouth"]
        cup = arm_at(s_, w=None, contact=mouth + Vector((0.055 * k, -0.050 * k, -0.040 * k)), along=(0.05, -0.90, 0.42), palm=(0.97, -0.05, 0.05),
                     pole=(0.9, 0.2, -0.5), curl=(30, 22, 12), reach=0.30)
        a.rest(s_, 0.0).arm(s_, 0.35, cup.copy(arc=(0.04, -0.06, 0.0)), "out").arm(s_, 1.5, cup).rest(s_, 2.0, "ease")
        a.f(0.0).f(0.35, "out", tight=0.2, brows=0.3, smile=0.2, lids=0.9).f(1.15, "ease", tight=0.2, brows=0.3, smile=0.2, lids=0.9)
        a.f(1.25, "snap", eyes_x=-sd, eyes_y=0.7, brows=0.6, lids=1.15).f(1.45, "ease", eyes_x=0.0, eyes_y=0.0, tight=0.3).f(2.0, "ease")
        c = clip(nm, 2.0, a, kind="ambient", tags=["conspiracy", "comic"], hands=s_, blend_in=0.15, blend_out=0.4,
                 groups={"legs": 0.0, "torso": 1.0, "head": 1.0, "arm_L": 1.0 if sd > 0 else 0.0, "arm_R": 1.0 if sd < 0 else 0.0})
        clips[nm] = face_plus(c, lambda t: {"jaw": 0.18 * max(0.0, math.sin(2 * math.pi * 5.5 * t)) * L.clamp01((t - 0.4) / 0.1) * (1 - L.clamp01((t - 1.15) / 0.05))})

    # ---- wring the hands (dread): hands together at the waist, twisting, shoulders up
    a = Act(1.8, drag=1.0)
    a.t(0.0).t(0.3, "out", chest=(6, 0, 0), neck=(3, 0, 0), head=(8, 0, 0)).t(0.8, "ease", chest=(8, 0, 2), head=(10, 0, 4))
    a.t(1.3, "ease", chest=(6, 0, -2), head=(8, 0, -4)).t(1.8, "ease")
    for i in range(7):
        t = 0.3 + i * 0.2
        tw = 1.0 if i % 2 == 0 else -1.0
        for s_ in "LR":
            sg = 1.0 if s_ == "L" else -1.0
            along = Vector((-0.75, -0.45, 0.5)).normalized()
            palm = L.Quaternion(along, math.radians(50 * tw * sg)) @ Vector((-0.9, 0.0, 0.3))
            a.arm(s_, t, arm_at(s_, w=body_pt(0.05, -0.26, z_chest - 0.10 + 0.015 * tw * sg), along=along, palm=palm, pole=(1.0, 0.2, -0.3),
                                curl=(50, 45, 30), sh=(0, -14, -8)))
    for s_ in "LR":
        a.arm_keys[s_].insert(0, (0.0, a.rest_arm[s_], "ease"))
        a.rest(s_, 1.8, "ease")
    a.f(0.0).f(0.3, "out", worry=0.95, brows=0.8, tight=0.5, lids=1.15).f(1.5, "ease", worry=0.95, brows=0.8, tight=0.5, lids=1.15).f(1.8, "ease")
    clips["wring_hands"] = clip("wring_hands", 1.8, a, kind="ambient", tags=["dread"], hands="", groups=upper, blend_in=0.2, blend_out=0.4)

    # ---- shush the neighbour on side sd: finger to the lips, turned to them
    for sd, nm in ((1.0, "shush_l"), (-1.0, "shush_r")):
        a = Act(1.1, drag=0.7)
        a.t(0.0).t(0.2, "out", chest=(0, 0, 4 * sd), head=(2, 0, 16 * sd)).t(0.8, "ease", chest=(0, 0, 4 * sd), head=(3, 0, 15 * sd)).t(1.1, "ease")
        finger = arm_at("R", w=None, contact=lm["mouth"] + Vector((0.0, -0.02 * k, -0.02 * k)), along=(-0.15, -0.2, 0.97), palm=(-0.95, 0.2, 0.0),
                        pole=(0.9, 0.2, -0.6), curl=(85, -10, 50), reach=0.62)
        a.rest("R", 0.0).arm("R", 0.22, finger.copy(arc=(0.04, -0.08, 0.0)), "out").arm("R", 0.8, finger).rest("R", 1.1, "ease")
        a.f(0.0).f(0.2, "out", tight=0.7, lids=0.75, stern=0.4, eyes_x=sd).f(0.8, "ease", tight=0.6, lids=0.75, stern=0.4, eyes_x=sd).f(1.1, "ease")
        clips[nm] = clip(nm, 1.1, a, kind="ambient", tags=["comic"], hands="R", groups=upper, blend_in=0.1, blend_out=0.35)

    # ---- fan themselves: a hand flapping before the face, head back, eyes half shut
    a = Act(1.8, drag=0.8)
    a.t(0.0).t(0.25, "out", chest=(-4, 0, 0), neck=(-3, 0, 0), head=(-12, 4, 6)).t(1.5, "ease", chest=(-4, 0, 0), neck=(-3, 0, 0), head=(-12, 4, 6)).t(1.8, "ease")
    fan0 = arm_at("R", w=body_pt(0.16, -0.26, z_chest + 0.20), along=(-0.1, -0.2, 0.97), palm=(-0.2, 0.95, 0.0), pole=(1.0, 0.3, -0.2), curl=(6, 0, -4), sh=(0, -6, 0))
    a.rest("R", 0.0).arm("R", 0.25, fan0, "out")
    for i in range(8):
        sweep = -1.0 if i % 2 == 0 else 1.0
        a.arm("R", 0.38 + 0.14 * i, fan0.copy(w=fan0.w + Vector((0.06 * k * sweep, 0, 0)),
                                              along=(L.Quaternion(Vector((0, 1, 0)), math.radians(32 * sweep)) @ fan0.along)), "ease")
    a.rest("R", 1.8, "ease")
    hip_l = L.key_to_world(cf_anim.stance_pose("hip"), stance_arm("hip", "L"))
    a.rest("L", 0.0).world("L", 0.4, {}, hip_l, "out").world("L", 1.5, {}, hip_l).rest("L", 1.8, "ease")
    a.f(0.0).f(0.25, "out", lids=0.5, puff=0.5, worry=0.3, jaw=0.15).f(1.5, "ease", lids=0.5, puff=0.4, jaw=0.15).f(1.8, "ease")
    clips["fan_self"] = clip("fan_self", 1.8, a, kind="ambient", tags=["hot"], hands="LR", groups=upper, blend_in=0.12, blend_out=0.4)


# =====================================================================================
# The ways out (in place; the stage carries them)
# =====================================================================================

def make_exits(clips):
    f = L.FRAME
    k = L.K
    z_chest = f.z_chest / k
    z_waist = f.z_waist / k
    z_hip = f.z_hip / k
    lm = landmarks()

    def walk_clip(name, T, fn, face_fn, speed, tags):
        a = Act(T, drag=0.0, feet=False)
        a.t(0.0)
        c = clip(name, T, a, kind="walk", loop=True, tags=tags, speed_mps=speed, blend_in=0.25, blend_out=0.3)
        c.body = lambda t: fn(t % T)
        c.face_fn = face_fn
        return c

    # ---- backing out, bowing: backwards steps, a bow bobbing with each, hands clasped
    clasped = {s_: arm_solve(s_, stance_arm("clasped", s_)) for s_ in "LR"}

    def back_out(t):
        T = 1.3
        p = cf_anim._walk((T - t) % T, T, 15.0, 30.0, 0.010)
        bob = abs(math.sin(2 * math.pi * t / T))
        add(p, "hips", rot=(6 + 4 * bob, 0, 0))
        add(p, "spine", rot=(8 + 3 * bob, 0, 0))
        add(p, "chest", rot=(6 + 3 * bob, 0, 0))
        add(p, "head", rot=(6 + 4 * bob, 0, 0))
        for s_ in "LR":
            p.update(clasped[s_])
        return p
    clips["back_out"] = walk_clip("back_out", 1.3, back_out, lambda t: {"lids": 0.6, "smile": 0.3, "brows": 0.4, "worry": 0.2}, 0.42, ["exit", "deference", "comic"])

    # ---- bump into a post backing out: a jolt from behind, a whip of the head,
    #      a look back, a hand to the back, a sheepish bob of a bow
    a = Act(1.7, drag=0.6)
    bowed = dict(hips=(8, 0, 0), spine=(9, 0, 0), chest=(7, 0, 0), head=(8, 0, 0))
    a.lags = {"head": 0.03, "neck": 0.02}
    a.t(0.0, "ease", **bowed).t(0.06, "snap", hips_loc=(0, -0.04, 0.01), spine=(-3, 0, 0), chest=(-6, 0, 0), neck=(-4, 0, 0), head=(-14, 0, 0))
    a.t(0.35, "out", hips_loc=(0, -0.03, 0.0), chest=(-2, 0, 14), neck=(0, 0, 18), head=(-4, 0, 34))
    a.t(0.75, "ease", hips_loc=(0, -0.03, 0.0), chest=(-2, 0, 14), neck=(0, 0, 18), head=(-4, 0, 36))
    a.t(1.05, "out", chest=(0, 0, 2), head=(0, 0, 4)).t(1.3, "out", **dict(bowed, head=(12, 0, 0))).t(1.7, "ease")
    for s_ in "LR":
        a.arm(s_, 0.0, stance_arm("clasped", s_))
        flung = arm_at(s_, w=body_pt(0.34, -0.10, z_chest + 0.12), along=(0.4, -0.2, 0.9), palm=(0.2, -0.95, 0.1), pole=(0.8, 0.4, -0.4), curl=(6, -4, -6), sh=(0, -10, 0))
        a.arm(s_, 0.08, flung, "snap")
    back_hand = arm_at("R", w=body_pt(0.12, 0.16, z_waist - 0.04), along=(-0.5, 0.2, -0.8), palm=(0.0, -1.0, 0.0), pole=(1.0, 0.6, 0.0), curl=(20, 14, 8))
    a.arm("R", 0.40, back_hand.copy(arc=(0.08, 0.06, 0.0)), "out").arm("R", 1.05, back_hand).arm("R", 1.35, stance_arm("clasped", "R"), "ease").arm("R", 1.7, stance_arm("clasped", "R"))
    a.rest("L", 0.6, "ease").arm("L", 1.3, stance_arm("clasped", "L"), "ease").arm("L", 1.7, stance_arm("clasped", "L"))
    a.f(0.0, "ease", lids=0.6, smile=0.3).f(0.06, "snap", lids=1.4, brows=1.0, jaw=0.4).f(0.35, "ease", lids=1.2, worry=0.6, brows=0.7, jaw=0.1)
    a.f(1.05, "ease", smile=0.4, tight=0.4, brows=0.5).f(1.7, "ease", smile=0.3, lids=0.7)
    clips["bump_post"] = clip("bump_post", 1.7, a, kind="exit", tags=["comic", "exit"], blend_in=0.05, blend_out=0.3)

    # ---- storming off: a brisk stamp of a walk, fists, chin up
    def storm(t):
        T = 0.9
        p = cf_anim._walk(t, T, 26.0, 50.0, 0.028, head_down=-8.0, swing=1.6)
        add(p, "spine", rot=(3, 0, 0))
        add(p, "chest", rot=(4, 0, 0))
        both(p, "shoulder", rot=(0, -4, 0))
        both(p, "fingers", rot=(0, 55, 0))
        both(p, "index", rot=(0, 62, 0))
        both(p, "thumb", rot=(0, 30, 0))
        both(p, "forearm", rot=(-18, 0, 0))
        return p
    clips["storm_walk"] = walk_clip("storm_walk", 0.9, storm, lambda t: {"stern": 0.8, "tight": 0.6, "brows": -0.6, "lids": 0.8, "sneer": 0.2}, 1.45, ["exit", "anger"])

    # ---- storm stop: mid-stride to a halt, a frozen beat, a slap to the forehead
    #      (the thing left behind!), a look back over the shoulder. Holds.
    a = Act(1.8, drag=0.7, feet=False)
    p0 = storm(0.0)
    legs0 = {b: dict(a.B[b]) for b in ("thigh.L", "shin.L", "foot.L", "thigh.R", "shin.R", "foot.R") if b in a.B}
    mid = {b: dict(p0[b]) for b in legs0 if b in p0}
    a.legs([(0.0, mid), (0.25, legs0, "out"), (1.8, legs0)])
    a.t(0.0, "ease", spine=(3, 0, 0), chest=(4, 0, 0), head=(-8, 0, 0)).t(0.25, "out", chest=(-3, 0, 0), head=(-4, 0, 0))
    a.t(0.62, "ease", chest=(-3, 0, 0), head=(-6, 0, 0)).t(0.78, "snap", chest=(-1, 0, 0), head=(-10, 0, 0))
    a.t(1.2, "out", chest=(-1, 0, 12), neck=(0, 0, 14), head=(-2, 0, 30)).t(1.8, "ease", chest=(-1, 0, 12), neck=(0, 0, 14), head=(-2, 0, 32))
    brow = arm_at("R", w=None, contact=lm["brow"] + Vector((0.0, -0.01 * k, 0.0)), along=(-0.35, 0.1, 0.93), palm=(0.0, 1.0, 0.0), pole=(0.8, 0.0, -0.6),
                  curl=(10, 6, 4), reach=0.42)
    for s_ in "LR":
        a.rest(s_, 0.0, curl=(70, 60, 30)).rest(s_, 0.3, curl=(60, 50, 25))
    a.arm("R", 0.62, a.rest_arm["R"]).arm("R", 0.80, brow.copy(arc=(0.08, -0.10, 0.0)), "snap").arm("R", 1.05, brow).rest("R", 1.5, "ease")
    a.f(0.0, "ease", stern=0.8, tight=0.6, brows=-0.6, lids=0.8).f(0.6, "ease", lids=1.25, brows=0.8, jaw=0.2)
    a.f(0.8, "snap", lids=0.3, tight=0.7, brows=0.2).f(1.2, "ease", stern=0.6, tight=0.5, lids=0.9).f(1.8, "ease", stern=0.6, tight=0.5, lids=0.9)
    clips["storm_stop"] = clip("storm_stop", 1.8, a, kind="exit", hold=True, tags=["comic", "exit", "anger"], blend_in=0.06, blend_out=0.3)

    # ---- snatch up the forgotten thing: a quick bend, a grab, tucked under the arm, a huff
    a = Act(1.2, drag=0.7)
    bend = dict(hips=(30, 0, 0), hips_loc=(0, 0.10, -0.22), spine=(22, 0, 0), chest=(10, 0, 0), head=(-10, 0, 0))
    a.t(0.0).t(0.3, "out", **bend).t(0.45, "ease", **bend).t(0.75, "out", chest=(-3, 0, 0), head=(-5, 0, 0)).t(1.2, "ease", chest=(-2, 0, 0), head=(-4, 0, 0))
    grab = arm_at("R", w=body_pt(0.18, -0.44, 0.12), along=(0.1, -0.3, -0.95), palm=(0.0, 0.2, -0.98), pole=(0.8, 0.5, -0.2), curl=(20, 14, 8))
    tuck = arm_at("R", w=body_pt(0.12, -0.10, z_waist + 0.06), along=(-0.3, -0.8, 0.3), palm=(-0.95, 0.0, 0.2), pole=(0.9, 0.5, -0.3), curl=(80, 70, 40))
    a.rest("R", 0.0).world("R", 0.32, bend, grab, "out").world("R", 0.45, bend, grab.copy(curl=(80, 70, 40))).arm("R", 0.8, tuck, "out").arm("R", 1.2, tuck)
    a.f(0.0).f(0.3, "ease", stern=0.5, tight=0.6, eyes_y=-0.8).f(0.75, "ease", stern=0.8, lids=0.8, sneer=0.3).f(1.2, "ease", stern=0.8, lids=0.8, sneer=0.3)
    clips["snatch_up"] = clip("snatch_up", 1.2, a, kind="exit", hold=True, tags=["comic", "exit"], blend_in=0.08, blend_out=0.3)

    # ---- the sober walk (cast out): slow, head down, shoulders rounded, arms still
    def sober(t):
        T = 1.6
        p = cf_anim._walk(t, T, 14.0, 30.0, 0.012, head_down=18.0, swing=0.25)
        add(p, "chest", rot=(6, 0, 0))
        both(p, "shoulder", rot=(0, 2, -8))
        return p
    clips["walk_sober"] = walk_clip("walk_sober", 1.6, sober, lambda t: {"lids": 0.55, "worry": 0.5, "tight": 0.4, "eyes_y": -0.8}, 0.62, ["exit", "grief"])

    # ---- led away (seized, condemned): hands bound behind, head down, short steps
    bound = {s_: arm_solve(s_, arm_at(s_, w=body_pt(-0.02, 0.15, z_hip + 0.03), along=(-0.6, 0.3, -0.7), palm=(0.0, 1.0, 0.1), pole=(0.9, 0.6, 0.0),
                                      curl=(50, 40, 20), sh=(0, 2, 10))) for s_ in "LR"}

    def led(t):
        T = 1.5
        p = cf_anim._walk(t, T, 11.0, 22.0, 0.010, head_down=20.0, swing=0.0)
        add(p, "chest", rot=(4, 0, 0))
        for s_ in "LR":
            p.update(bound[s_])
        return p
    clips["walk_led"] = walk_clip("walk_led", 1.5, led, lambda t: {"lids": 0.5, "tight": 0.5, "worry": 0.6, "eyes_y": -0.7}, 0.70, ["exit", "dread"])
